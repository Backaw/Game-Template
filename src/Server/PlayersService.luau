--!strict
local PlayersService = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Shared.Promise)
local Maid = require(ReplicatedStorage.Shared.Maid)
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)

local IMPORTANT_LOAD_JOBS = {
	PlayerData = "PlayerData",
	Analytics = "Analytics",
	Items = "Items",
	Products = "Products",
	Quests = "Quests",
}

local LOAD_ORDER = {
	IMPORTANT_LOAD_JOBS.PlayerData,
	IMPORTANT_LOAD_JOBS.Analytics,
	IMPORTANT_LOAD_JOBS.Items,
	IMPORTANT_LOAD_JOBS.Products,
	IMPORTANT_LOAD_JOBS.Quests,
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Session = {
	UnloadTasks: { any },
	Loading: Promise.Promise,
	Unloading: Promise.Promise?,
}

type Loader = (player: Player) -> Promise.Promise
type LoadHandler = (player: Player) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local id = 0
local sessions: { [number]: Session? } = {}

local unsortedLoaders: { [Loader]: number } = {}
local sortedLoaders: { Loader } = {}
local loadJobNames: { [Loader]: string } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

PlayersService.LoadJobs = IMPORTANT_LOAD_JOBS

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function loadPlayer(player: Player)
	id += 1

	if DEBUG then
		warn(("(%s)(%d) started loading"):format(player.Name, id))
	end

	local existingSession = sessions[player.UserId] -- Just to be safe
	local load = (if existingSession and existingSession.Unloading then existingSession.Unloading else Promise.resolved())

	load:andThen(function()
		local session: Session = {
			UnloadTasks = {},
			Loading = load,
		}
		sessions[player.UserId] = session

		local loadingSequence = Promise.resolved()
		do
			for _, loader in ipairs(sortedLoaders) do
				loadingSequence = loadingSequence:andThenCall(loader, player)
			end
		end

		session.Loading = loadingSequence:andThen(function()
			if DEBUG then
				warn(("(%s)(%d) finished loading"):format(player.Name, id))
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
					warn(("(%s)(%d) left"):format(player.Name, id))
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
						warn(("(%s)(%d) unloaded"):format(player.Name, id))
					end
				end
			end)
	end)
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function PlayersService.isLoaded(player: Player)
	local session = sessions[player.UserId]
	return session and session.Loading:getState() == Promise.States.Resolved
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

function PlayersService.registerUnloadTask(player: Player, task: any)
	local session = sessions[player.UserId]
	if session then
		table.insert(session.UnloadTasks, task)
	end
end

function PlayersService.registerLoader(job: string, loader: Loader)
	loadJobNames[loader] = job
	unsortedLoaders[loader] = table.find(LOAD_ORDER, job) or (#LOAD_ORDER + 1)
end

function PlayersService.registerLoadHandler(job: string, loadHandler: LoadHandler)
	local loader = function(player: Player)
		return Promise.new(function(resolve, reject)
			local success, err = pcall(loadHandler :: LoadHandler, player)

			if success then
				resolve()
			else
				reject(("Couldn't load %s for player %s "):format(job, player.Name))
				warn(err)
			end
		end)
	end

	PlayersService.registerLoader(job, loader)
end

function PlayersService.start()
	-- Sort loaders by priority
	sortedLoaders = TableUtil.getKeys(unsortedLoaders)
	table.sort(sortedLoaders, function(a, b)
		return unsortedLoaders[a] < unsortedLoaders[b]
	end)

	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		loadPlayer(player)
	end

	-- Incase loading hadn't commenced yet
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
