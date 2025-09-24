local ServerStorage = game:GetService("ServerStorage")
local BoostService = require(ServerStorage.Server.BoostService)

return function(_, player: Player, boost: string, lengthInMinutes: number)
	BoostService.createBoost(player, boost, if lengthInMinutes == -1 then math.huge else lengthInMinutes)
end
