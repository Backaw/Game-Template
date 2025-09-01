local ServerScriptService = game:GetService("ServerScriptService")
local QuestService = require(ServerScriptService.Paths.QuestService)

return function(_, player: Player, stat: string, amount: number)
	QuestService.incrementStat(player, stat, amount)
end
