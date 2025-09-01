local ServerScriptService = game:GetService("ServerScriptService")
local ItemService = require(ServerScriptService.Paths.ItemService)

return function(_, player: Player, itemType: string, itemName: string)
	ItemService.giveItem(player, itemType, itemName)
end
