local PlayersService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Promise = require(ReplicatedStorage.Shared.Packages.Promise)
local Maid = require(ReplicatedStorage.Shared.Maid)
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

local DEBUG = DebugUtil.isDebugging(false)
local SERVICES = ServerStorage.Server

local LOADERS = {
	SERVICES.Data.PlayerDataService,
	-- 	Services.GameAnalyticsService,
	SERVICES.Products.ProductService,
	SERVICES.Data.LeaderstatService,
	SERVICES.CharactersService,
	SERVICES.ItemService,
	SERVICES.BadgeUnlockingService,
	SERVICES.LoginService,
	SERVICES.FriendsService,
	SERVICES.QuestService,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local id = 0
local sessions: { [number]: { UnloadTasks: { Maid.Mess }, Loading: Promise.Promise, Unloading: Promise.Promise? }? } = {}

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

function PlayersService.registerUnloadTask(player: Player, newTask: any)
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
				reject("Couldn't load player's " .. message :: string or "")
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
			local session = {
				UnloadTasks = {},
				Loading = load,
			}
			sessions[player.UserId] = session

			local loaders = Promise.resolve()
			for _, moduleScript in LOADERS do
				local module = require(moduleScript) :: any
				local loader = module.loadPlayer

				-- ERROR: Loader doesn't have a load method
				if not loader then
					error(("%s loader doesn't have a load method"):format(moduleScript.Name))
				end

				if DEBUG then
					-- Track timing for each module
					loaders = loaders:andThenCall(function(...)
						local startTime = os.clock()
						local result = loader(...)

						print(("Player Loader (%s) took %.5f s"):format(moduleScript.Name, os.clock() - startTime))
						return result
					end, player)
				else
					loaders = loaders:andThenCall(loader, player)
				end
			end

			session.Loading = loaders:andThen(function()
				if DEBUG then
					warn(("(%s)(%s) finished loading"):format(player.Name, id))
				end
			end)

			session.Unloading = session.Loading
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

					local remainingSession = sessions[player.UserId]
					if remainingSession then
						-- Invoked in reverse order to prevent dependency conflicts
						local unloadTasks = remainingSession.UnloadTasks
						for i = #unloadTasks, 1, -1 do
							local success, err = pcall(Maid.cleanup, unloadTasks[i])
							if not success then
								warn(err)
							end
						end

						sessions[player.UserId] = nil

						if DEBUG then
							warn(("(%s)(%s) unloaded"):format(player.Name, id))
						end
					end
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
