local ServerScriptService = game:GetService("ServerScriptService")
local PlayerDataService = require(ServerScriptService.Paths.Data.PlayerDataService)

return function(_, player: Player)
	PlayerDataService.wipe(player)
end
