--!strict
--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use addresses to prevent any confusion between integer indexes and string keys with numbers
    - No spaces in keys, use underscores or preferably camel case
]]
local PlayerDataService = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataFormatUtil = require(ReplicatedStorage.Shared.Data.DataFormatUtil)
local Signal = require(ReplicatedStorage.Shared.Signal)
-- local Remotes = require(ReplicatedStorage.Shared.Remotes)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Promise = require(ReplicatedStorage.Shared.Promise)
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local ProfileStore = require(ServerStorage.Packages.ProfileStore)
local PlayersService = require(ServerStorage.Server.PlayersService)
local DataConstants = require(ReplicatedStorage.Shared.Data.DataConstants)
local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local DataTypes = require(ReplicatedStorage.Shared.Data.DataTypes)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local RECONCILIATION_TYPES = {
	Pre = "Pre",
	Post = "Post",
}

local clientsReadyForData: { [Player]: true? } = {}
local clientReadyForData = Signal.new() :: Signal.Signal<Player>
local reconcilers: { [keyof<typeof(RECONCILIATION_TYPES)>]: { (DataTypes.Store) -> () } } = {
	[RECONCILIATION_TYPES.Pre] = {},
	[RECONCILIATION_TYPES.Post] = {},
}

local playerStore: ProfileStore.ProfileStore<DataTypes.Store>
local profiles: { [Player]: ProfileStore.Profile<DataTypes.Store> } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

PlayerDataService.Updated = Signal.new() :: Signal.Signal<string, Player, any, DataTypes.EventMeta>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function reconcile(data: DataTypes.Store, default: DataTypes.Store, recursiveCase: true?)
	if not recursiveCase then
		for _, reconciler in pairs(reconcilers[RECONCILIATION_TYPES.Pre]) do
			reconciler(data)
		end
	end

	for k, v in pairs(default) do
		if not tonumber(k) and data[k] == nil then
			data[k] = if typeof(v) == "table" then TableUtil.deepClone(v) else v
		elseif typeof(v) == "table" then
			reconcile(data[k] :: DataTypes.Store, v, true)
		end
	end

	if not recursiveCase then
		for _, reconciler in pairs(reconcilers[RECONCILIATION_TYPES.Post]) do
			reconciler(data)
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function PlayerDataService.registerReconciler(reconciler: (DataTypes.Store) -> (), runFirst: boolean?)
	table.insert(reconcilers[if runFirst then RECONCILIATION_TYPES.Pre else RECONCILIATION_TYPES.Post], reconciler)
end

function PlayerDataService.get(player: Player, address: string): DataTypes.Data | nil
	local profile = profiles[player]
	if profile then
		return DataFormatUtil.getFromAddress(profile.Data, address)
	end

	warn(("Attempting to get %s's data after release at: \n\t%s"):format(player.Name, address))
	return nil
end

function PlayerDataService.set(player: Player, address: string, newValue: any, event: string?, eventMeta: DataTypes.EventMeta)
	local profile = profiles[player]

	if profile then
		DataFormatUtil.setFromAddress(profile.Data, address, newValue)
		DataConstants.Remotes.DataUpdated:FireClient(player, address, newValue, event, eventMeta)

		if event then
			PlayerDataService.Updated:Fire(event, player, newValue, eventMeta)
		end

		return newValue
	else
		warn(("Attempting to set %s's data after release at: \n\t%s"):format(player.Name, address))
	end

	return nil
end

--[[
	Mimicks table.length while ignoring gaps
]]

function PlayerDataService.getAppendageKey(player: Player, address: string): string
	return tostring(TableUtil.maxIndex(PlayerDataService.get(player, address)) + 1)
end

--[[
	Mimicks table.insert while ignoring gaps
]]
function PlayerDataService.append(player: Player, address: string, newValue: any, event: string?, eventMeta: DataTypes.EventMeta): string
	return PlayerDataService.set(player, address .. "." .. PlayerDataService.getAppendageKey(player, address), newValue, event, eventMeta)
end

--[[
	Increments a value at the address by the incrementAmount
	value at address defaults to 0, incrementAmount defaults to 1
]]
function PlayerDataService.increment(
	player: Player,
	address: string,
	incrementAmount: number?,
	event: string?,
	eventMeta: DataTypes.EventMeta
)
	incrementAmount = incrementAmount or 1

	-- ERROR: Not a number
	local currentValue = PlayerDataService.get(player, address)
	if currentValue ~= nil and typeof(currentValue) ~= "number" then
		error(("Cannot increment then non-number value at: %q"):format(address))
	end

	return PlayerDataService.set(player, address, (currentValue or 0) + incrementAmount, event, eventMeta)
end

--[[
	Multiplies a value at the address by the scalar
]]
function PlayerDataService.multiply(player: Player, address: string, scalar: number, event: string?, eventMeta: DataTypes.EventMeta)
	-- ERROR: Not a number
	local currentValue = PlayerDataService.get(player, address)
	if currentValue == nil or typeof(currentValue) ~= "number" then
		error(("Cannot increment then non-number value at: %q"):format(address))
	end

	return PlayerDataService.set(player, address, currentValue * scalar, event, eventMeta)
end

function PlayerDataService.wipe(player: Player)
	local profile = profiles[player]

	profile.Data = ProfileTemplate.get()
	player:Kick("DATA WIPE " .. player.Name)
end

function PlayerDataService.init()
	playerStore = ProfileStore.New(DataFormatUtil.getDataKey(), ProfileTemplate.get())
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------------

DataConstants.Remotes.ClientReadyForData:OnServerEvent(function(client)
	clientReadyForData:Fire(client)
	clientsReadyForData[client] = true
end)

PlayersService.registerLoader(PlayersService.LoadJobs.PlayerData, function(player: Player)
	return Promise.new(function(resolve, reject)
		local cancelled = false

		local profileKey, profileParams =
			`{player.UserId}`, {
				Cancel = function()
					return cancelled or player.Parent ~= Players
				end,
			} :: { Steal: boolean? }

		local profile
		if (not DataConstants.SaveData) and (not GameUtil.isLive()) then
			profile = playerStore.Mock:StartSessionAsync(profileKey, profileParams)
		else
			profile = playerStore:StartSessionAsync(`{player.UserId}`, profileParams)
		end

		if profile then
			profile:AddUserId(player.UserId)
			reconcile(profile.Data, ProfileTemplate.get())

			local clientReadyConnection
			local function closeInitialization()
				if clientReadyConnection then
					clientReadyConnection:Disconnect()
				end

				clientsReadyForData[player] = nil
			end

			local function initialize()
				if profile then
					DataConstants.Remotes.DataInitialized:FireClient(player, profile.Data)
					profiles[player] = profile

					resolve()
					closeInitialization()
				end
			end

			if clientsReadyForData[player] then
				initialize()
			else
				clientReadyConnection = clientReadyForData:Connect(function(client)
					if client == player then
						initialize()
					end
				end)
			end

			PlayersService.registerUnloadTask(player, function()
				if profile then
					cancelled = true

					closeInitialization()

					profiles[player] = nil
					profile:EndSession()
				end
			end)

			profile.OnSessionEnd:Connect(function()
				profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)
		else
			reject("Data profile does not exist - Please rejoin")
		end
	end)
end)

return PlayerDataService
