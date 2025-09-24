--!strict
local LoginService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local PlayersService = require(ServerStorage.Server.PlayersService)
local QuestService = require(ServerStorage.Server.QuestService)
local GameConstants = require(ReplicatedStorage.Shared.Game.GameConstants)
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)

LoginService.loadPlayer = PlayersService.promisifyLoader(function(player)
	local loginTime = os.time()

	local countdown = task.spawn(function()
		while true do
			task.wait(60)
			QuestService.incrementStat(player, QuestConstants.Stats.MinutesPlayed, 1)
		end
	end)

	PlayersService.registerUnloadTask(player, function()
		PlayerDataService.set(player, "LastLogin", { Time = loginTime, Version = GameConstants.Version })
		task.cancel(countdown)
	end)
end, "Login")

return LoginService
