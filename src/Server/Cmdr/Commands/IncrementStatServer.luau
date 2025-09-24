local ServerStorage = game:GetService("ServerStorage")
local QuestService = require(ServerStorage.Server.QuestService)

return function(_, player: Player, stat: string, amount: number)
	QuestService.incrementStat(player, stat, amount)
end
