local LeaderboardService = {}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Paths = require(ServerScriptService.Paths)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local Promise = require(Paths.Packages.Promise)
local DataConstants = require(Paths.Shared.Data.DataConstants)
local TemplateUtil = require(Paths.Shared.Utils.TemplateUtil)
local DataUtil = require(Paths.Shared.Data.DataUtil)
local PlayerService = require(Paths.Services.PlayersService)
local QuestUtil = require(Paths.Shared.Quests.QuestUtil)

local REFRESH_RATE = 5 * 60
local USERNAME_CACHE_REFRESH_RATE = 15 * 60

local LIST_SIZE = 25

local orderedStores = {}
local usernameCache = { string } -- stores usernames so as to avoid calling GetNameFromUserIdAsync which yields the thread

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local leaderboards = Workspace.Lobby.Leaderboards:GetChildren()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function safeFetch(fetcher: () -> ())
	return Promise.retry(function()
		return Promise.new(function(resolve, reject)
			local success, store = pcall(fetcher)

			if success then
				resolve(store)
			else
				reject(store)
			end
		end)
	end, 4)
end

local function refreshList()
	local stores = {}
	for leaderboardType in pairs(DataConstants.Leaderboards) do
		stores[leaderboardType] = safeFetch(function()
			return orderedStores[leaderboardType]:GetSortedAsync(false, 100):GetCurrentPage()
		end)
	end

	for _, leaderboard in ipairs(leaderboards) do
		local leaderboardType = leaderboard.Name
		local info = DataConstants.Leaderboards[leaderboardType]

		stores[leaderboardType]
			:andThen(function(store)
				local list = leaderboard.Board.SurfaceGui.List

				local psuedoRank = 0
				for rank, data in pairs(store) do
					local userId = tonumber(data.key)
					local value = info.Formatter(data.value, false)

					if userId and value then
						local username = usernameCache[userId]
						if not username then
							Promise.new(function(resolve, reject)
								local success, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
								if not success then
									reject()
								else
									resolve(name)
								end
							end)
								:andThen(function(user)
									username = user
									usernameCache[userId] = username
								end)
								:catch(warn)
								:await()
						end

						if username then
							psuedoRank += 1

							local label = list:FindFirstChild(tostring(rank))

							label.Visible = true
							label.Rank.Text = "#" .. psuedoRank
							label.Value.Text = value
							label.Username.Text = username

							if psuedoRank == LIST_SIZE then
								break
							end
						end
					end
				end

				for i = LIST_SIZE, psuedoRank + 1, -1 do
					list[tostring(i)].Visible = false
				end
			end)
			:catch(warn)
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function LeaderboardService.init()
	for _, leaderboard in ipairs(leaderboards) do
		leaderboard.Title.SurfaceGui.TextLabel.Text = ("Top %s"):format(leaderboard.Name)

		local display = leaderboard.Board.SurfaceGui
		local labelConstructor = TemplateUtil.constructor(display.List.TEMP_ITEM)
		for i = 1, LIST_SIZE do
			local label = labelConstructor()
			label.Name = tostring(i)
			label.Visible = false
		end
	end

	local fetchStorePromises = {}
	for leaderboardType in pairs(DataConstants.Leaderboards) do
		safeFetch(function()
			local orderedStore = DataStoreService:GetOrderedDataStore(("%s_%s"):format(DataUtil.getDataKey(), leaderboardType))
			orderedStores[leaderboardType] = orderedStore

			return orderedStore
		end)
	end

	Promise.all(fetchStorePromises):andThen(function()
		while true do
			for _, player in pairs(Players:GetPlayers()) do
				PlayerService.onLoad(player, function()
					for leaderboardType, info in pairs(DataConstants.Leaderboards) do
						local value = PlayerDataService.get(player, QuestUtil.getStatAddress(info.Stat))

						local success, err = pcall(function()
							orderedStores[leaderboardType]:SetAsync(player.UserId, value)
						end)
						if not success then
							warn(err)
						end
					end
				end)
			end

			refreshList()
			task.wait(REFRESH_RATE)
		end
	end)

	task.spawn(function()
		while true do
			usernameCache = {}
			task.wait(USERNAME_CACHE_REFRESH_RATE)
		end
	end)
end

return LeaderboardService
