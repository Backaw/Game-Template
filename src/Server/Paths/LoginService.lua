local LoginService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local PlayersService = require(Services.PlayersService)
local PlayerDataService = require(Services.Data.PlayerDataService)
local QuestService = require(Services.QuestService)
local GameConstants = require(Shared.Game.GameConstants)
local QuestConstants = require(Shared.Quests.QuestConstants)

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
