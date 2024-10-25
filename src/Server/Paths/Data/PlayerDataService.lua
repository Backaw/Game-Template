--[[
    RULES
    - Everything is a dictionary, no integer indexes.
        Why: We use addresses, no way to tell if you want to use a number as an index or a key from the address alone
    - No spaces in keys, use underscores or preferably just camel case instead
]]
local PlayerDataService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Signal = require(Paths.Shared.Signal)
local DataUtil = require(Paths.Shared.Data.DataUtil)
local DataConstants = require(Paths.Shared.Data.DataConstants)
local ProfileService = require(ServerScriptService.ProfileService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PlayersService = require(Paths.Services.PlayersService)
local Promise = require(Paths.Packages.Promise)
local GameUtil = require(Paths.Shared.Game.GameUtil)

local DONT_SAVE_DATA = false

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local clientsReadyForData: { [Player]: boolean? } = {}
local clientReadyForData = Signal.new()
local reconcilers: { Pre: { (DataUtil.Store) -> () }, Post: { (DataUtil.Store) -> () } } = { Pre = {}, Post = {} }

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
PlayerDataService.Profiles = {}
PlayerDataService.Updated = Signal.new() --> (event: string, player: Player, newValue: any, eventMeta: table?)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function reconcile(data: DataUtil.Store, default: DataUtil.Store, recursiveCase: boolean?)
	if not recursiveCase then
		for _, reconciler in pairs(reconcilers.Pre) do
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
		for _, reconciler in pairs(reconcilers.Post) do
			reconciler(data)
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function PlayerDataService.registerReconciler(reconciler: (DataUtil.Store) -> (), isPreDefaultRecociliation: boolean?)
	table.insert(reconcilers[if isPreDefaultRecociliation then "Pre" else "Post"], reconciler)
end

function PlayerDataService.get(player: Player, address: string): DataUtil.Data
	local profile = PlayerDataService.Profiles[player]
	if profile then
		return DataUtil.getFromAddress(profile.Data, address)
	else
		warn(("Attempting to get %s's data after release at: \n\t%s"):format(player.Name, address))
	end
end

function PlayerDataService.set(player: Player, address: string, newValue: any, event: string?, eventMeta: table?)
	local profile = PlayerDataService.Profiles[player]

	if profile then
		DataUtil.setFromAddress(profile.Data, address, newValue)
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
	local profile = PlayerDataService.Profiles[player]

	profile.Data = nil
	player:Kick("DATA WIPE " .. player.Name)
end

function PlayerDataService.loadPlayer(player: Player)
	return Promise.new(function(resolve, reject, onCancel)
		local profile
		PlayersService.registerUnloadTask(player, function()
			repeat
				task.wait()
			until profile

			-- Data was wiped, reconcile so that stuff unloads properly
			if not profile.Data then
				profile.Data = {}
				profile:Reconcile()
			end

			profile:Release()
		end)

		task.spawn(function()
			local defaultData = DataConstants.DefaultPlayerData()
			profile = ProfileService.GetProfileStore(DataUtil.getDataKey(), defaultData)
				:LoadProfileAsync(tostring(player.UserId), "ForceLoad")

			-- RETURN: Couldn't retrieve a profile
			if not profile then
				reject("Data profile does not exist ")
				return
			end

			-- RETURN: Player left
			if not player.Parent then
				return
			end

			if DONT_SAVE_DATA and not GameUtil.isLive() then
				profile.Data = {}
			end

			reconcile(profile.Data, defaultData :: DataUtil.Store)
			profile:ListenToRelease(function()
				PlayerDataService.Profiles[player] = nil
				player:Kick("Data profile released " .. player.Name)
			end)

			local clientReadyConnection
			local function cancelDataInitialization()
				if clientReadyConnection then
					clientReadyConnection:Disconnect()
				end

				clientsReadyForData[player] = nil
			end

			local function load()
				Remotes.fireClient(player, "DataInitialized", profile.Data)
				PlayerDataService.Profiles[player] = profile

				resolve()
				cancelDataInitialization()
			end

			if profile.Data.Banned then
				reject("Banned")
			end

			if clientsReadyForData[player] then
				load()
			else
				clientReadyConnection = clientReadyForData:Connect(function(client)
					if client == player then
						load()
						cancelDataInitialization()
					end
				end)
			end

			onCancel(function()
				if cancelDataInitialization then
					cancelDataInitialization()
				end
			end)
		end)

		repeat
			task.wait()
		until profile
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
