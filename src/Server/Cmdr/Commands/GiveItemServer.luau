local ServerStorage = game:GetService("ServerStorage")
local ItemService = require(ServerStorage.Server.ItemService)

return function(_, player: Player, itemType: string, itemName: string)
	ItemService.giveItem(player, itemType, itemName)
end
