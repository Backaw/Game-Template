local ItemController = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(Players.LocalPlayer.PlayerScripts.Paths.DataController)
local ItemUtil = require(ReplicatedStorage.Modules.Items.ItemUtil)

function ItemController.hasItem(itemType: string, itemName: string)
	return DataController.get(ItemUtil.getOwnedItemsAddressFromType(itemType))[itemName] ~= nil
end

function ItemController.isItemEquipped(itemType: string, itemName: string)
	return DataController.get(ItemUtil.getEquippedItemAddressFromType(itemType)) == itemName
end

return ItemController
