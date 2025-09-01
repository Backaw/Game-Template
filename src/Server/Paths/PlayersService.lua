local PlayersService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local Promise = require(Shared.Packages.Promise)
local Maid = require(Shared.Maid)
local GameUtil = require(Shared.Game.GameUtil)

type Promise = typeof(Promise.new())

local DEBUG = false
local LOADERS = {
	Services.PlaytimeRewardService,
	Services.Data.PlayerDataService,
	Services.GameAnalyticsService,
	Services.Products.ProductService,
	Services.Data.LeaderstatService,
	Services.CharactersService,
	Services.ItemService,
	Services.BadgeUnlockingService,
	Services.LoginService,
	Services.FriendsService,
	Services.QuestService,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local id = 0
local sessions: { [number]: { UnloadTasks: table, Loading: Promise, Unloading: Promise? }? } = {}

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function PlayersService.isLoaded(player: Player)
	local session = sessions[player.UserId]
	return session and session.Loading:getStatus() == Promise.Status.Resolved
end

function PlayersService.getLoadedPlayers()
	local loadedPlayers: { Player } = {}

	for _, player in Players:GetPlayers() do
		if PlayersService.isLoaded(player) then
			table.insert(loadedPlayers, player)
		end
	end

	return loadedPlayers
end

function PlayersService.onLoad(player: Player, callback)
	local session = sessions[player.UserId]
	if session then
		session.Loading:andThenCall(callback)
	end
end

function PlayersService.registerUnloadTask(player, newTask)
	if not newTask then
		error("Task cannot be false or nil", 2)
	end

	local session = sessions[player.UserId]
	if session then
		table.insert(session.UnloadTasks, newTask)
	end
end

function PlayersService.promisifyLoader(loader: (Player) -> (), message: string?)
	return function(player)
		return Promise.new(function(resolve, reject)
			local success, err = pcall(loader, player)
			if success then
				resolve()
			else
				reject("Couldn't load player's " .. message or "")
				warn(err)
			end
		end)
	end
end

function PlayersService.start()
	local function loadPlayer(player)
		id += 1

		if DEBUG then
			warn(("(%s)(%s) started loading"):format(player.Name, id))
		end

		local existingSession = sessions[player.UserId] -- Just to be safe
		local load = (if existingSession and existingSession.Unloading then existingSession.Unloading else Promise.resolve())

		load:andThen(function()
			sessions[player.UserId] = {
				UnloadTasks = {},
				Loading = load,
			}

			local loaders = Promise.resolve()
			for _, moduleScript in LOADERS do
				local module = require(moduleScript)
				local loader = module.loadPlayer

				-- ERROR: Loader doesn't have a load method
				if not loader then
					error(("%s loader doesn't have a load method"):format(moduleScript.Name))
				end

				loaders = loaders:andThenCall(loader, player)
			end

			sessions[player.UserId].Loading = loaders:andThen(function()
				if DEBUG then
					warn(("(%s)(%s) finished loading"):format(player.Name, id))
				end
			end)

			sessions[player.UserId].Unloading = sessions[player.UserId].Loading
				:andThen(function()
					return Promise.fromEvent(Players.PlayerRemoving, function(removedPlayer: Player)
						return player == removedPlayer
					end)
				end)
				:catch(function(issue)
					if GameUtil.isDev() then
						warn(issue)
					else
						if player:IsDescendantOf(Players) then
							player:Kick(issue)
						end
					end
				end)
				:finally(function()
					if DEBUG then
						warn(("(%s)(%s) left"):format(player.Name, id))
					end

					-- Invoked in reverse order to prevent dependency conflicts
					local unloadTasks = sessions[player.UserId].UnloadTasks
					for i = #unloadTasks, 1, -1 do
						local success, err = pcall(Maid.cleanup, unloadTasks[i])
						if not success then
							warn(err)
						end
					end

					if DEBUG then
						warn(("(%s)(%s) unloaded"):format(player.Name, id))
					end

					sessions[player.UserId] = nil
				end)
		end)
	end

	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		loadPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player.UserId]
		if session then
			if DEBUG then
				warn(("(%s) left"):format(player.Name))
			end

			session.Loading:cancel()
		end
	end)
end

return PlayersService
