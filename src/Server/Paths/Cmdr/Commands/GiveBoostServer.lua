local ServerScriptService = game:GetService("ServerScriptService")
local BoostService = require(ServerScriptService.Paths.BoostService)

return function(_, player: Player, boost: string, lengthInMinutes: number)
	BoostService.createBoost(player, boost, if lengthInMinutes == -1 then math.huge else lengthInMinutes)
end
