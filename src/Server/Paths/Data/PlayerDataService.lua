--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use addresses, no way to tell if you want to use a number as an index or a key from the address alone
    - No spaces in keys, use underscores or preferably just camel case instead
]]
local PlayerDataService = {}

local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local Signal = require(Shared.Signal)
local Remotes = require(Shared.Remotes)
local DataFormatUtil = require(Shared.Data.DataFormatUtil)
local DataConstants = require(Shared.Data.DataConstants)
local TableUtil = require(Shared.Utils.TableUtil)
local Promise = require(Shared.Packages.Promise)
local GameUtil = require(Shared.Game.GameUtil)
local ProfileStore = require(ServerStorage.Packages.ProfileStore)
local PlayersService = require(Services.PlayersService)

local RECONCILIATION_TYPES = {
	Pre = 1,
	Post = 2,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local clientsReadyForData: { [Player]: true? } = {}
local clientReadyForData = Signal.new()
local reconcilers: { [number]: { (DataFormatUtil.Store) -> () } } = {
	[RECONCILIATION_TYPES.Pre] = {},
	[RECONCILIATION_TYPES.Post] = {},
}

local playerStore = ProfileStore.New(DataFormatUtil.getDataKey(), DataConstants.DefaultPlayerData())
local profiles: { [Player]: typeof(playerStore:StartSessionAsync()) } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
PlayerDataService.Updated = Signal.new() --> (event: string, player: Player, newValue: any, eventMeta: table?)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function reconcile(data: DataFormatUtil.Store, default: DataFormatUtil.Store, recursiveCase: true?)
	if not recursiveCase then
		for _, reconciler in pairs(reconcilers[RECONCILIATION_TYPES.Pre]) do
			reconciler(data)
		end
	end

	for k, v in pairs(default) do
		if not tonumber(k) and data[k] == nil then
			data[k] = if typeof(v) == "table" then TableUtil.deepClone(v) else v
		elseif typeof(v) == "table" then
			reconcile(data[k], v, true)
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
function PlayerDataService.registerReconciler(reconciler: (DataFormatUtil.Store) -> (), runFirst: boolean?)
	table.insert(reconcilers[if runFirst then RECONCILIATION_TYPES.Pre else RECONCILIATION_TYPES.Post], reconciler)
end

function PlayerDataService.get(player: Player, address: string): DataFormatUtil.Data
	local profile = profiles[player]
	if profile then
		return DataFormatUtil.getFromAddress(profile.Data, address)
	else
		warn(("Attempting to get %s's data after release at: \n\t%s"):format(player.Name, address))
	end
end

function PlayerDataService.set(player: Player, address: string, newValue: any, event: string?, eventMeta: table?)
	local profile = profiles[player]

	if profile then
		DataFormatUtil.setFromAddress(profile.Data, address, newValue)
		Remotes.fireClient(player, "DataUpdated", address, newValue, event, eventMeta)

		if event then
			PlayerDataService.Updated:Fire(event, player, newValue, eventMeta)
		end

		return newValue
	else
		warn(("Attempting to set %s's data after release at: \n\t%s"):format(player.Name, address))
	end
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
function PlayerDataService.append(player: Player, address: string, newValue: any, event: string?, eventMeta: table?): string
	return PlayerDataService.set(player, address .. "." .. PlayerDataService.getAppendageKey(player, address), newValue, event, eventMeta)
end

--[[
	Increments a value at the address by the incrementAmount
	value at address defaults to 0, incrementAmount defaults to 1
]]
function PlayerDataService.increment(player: Player, address: string, incrementAmount: number?, event: string?, eventMeta: table?)
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
function PlayerDataService.multiply(player: Player, address: string, scalar: number, event: string?, eventMeta: table?)
	-- ERROR: Not a number
	local currentValue = PlayerDataService.get(player, address)
	if currentValue ~= nil and typeof(currentValue) ~= "number" then
		error(("Cannot increment then non-number value at: %q"):format(address))
	end

	return PlayerDataService.set(player, address, currentValue * scalar, event, eventMeta)
end

function PlayerDataService.wipe(player: Player)
	local profile = profiles[player]

	profile.Data = nil
	player:Kick("DATA WIPE " .. player.Name)
end

function PlayerDataService.loadPlayer(player: Player)
	return Promise.new(function(resolve, reject)
		local cancelled = false

		local profileKey, profileParams =
			`{player.UserId}`, {
				Cancel = function()
					return cancelled or player.Parent ~= Players
				end,
			}

		local profile
		if (not DataConstants.SaveData) and (not GameUtil.isLive()) then
			profile = playerStore.Mock:StartSessionAsync(profileKey, profileParams)
		else
			profile = playerStore:StartSessionAsync(`{player.UserId}`, profileParams)
		end

		if profile then
			profile:AddUserId(player.UserId)
			reconcile(profile.Data, DataConstants.DefaultPlayerData())

			local clientReadyConnection
			local function closeInitialization()
				if clientReadyConnection then
					clientReadyConnection:Disconnect()
				end

				clientsReadyForData[player] = nil
			end

			local function initialize()
				Remotes.fireClient(player, "DataInitialized", profile.Data)
				profiles[player] = profile

				resolve()
				closeInitialization()
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
				cancelled = true

				closeInitialization()

				profiles[player] = nil
				profile:EndSession()
			end)

			profile.OnSessionEnd:Connect(function()
				profiles[player] = nil
				player:Kick(`Profile session end - Please rejoin`)
			end)
		else
			reject("Data profile does not exist - Please rejoin")
		end
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
Remotes.declareEvent("DataUpdated")
Remotes.declareEvent("DataInitialized")

Remotes.bindEvents({
	ClientReadyForData = function(client)
		clientReadyForData:Fire(client)
		clientsReadyForData[client] = true
	end,
})

return PlayerDataService
