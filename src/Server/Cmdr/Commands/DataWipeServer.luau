local ServerStorage = game:GetService("ServerStorage")

local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)

return function(_, player: Player)
	PlayerDataService.wipe(player)
end
