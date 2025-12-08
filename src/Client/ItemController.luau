--!strict
local ItemController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Client.DataController)
local Signal = require(ReplicatedStorage.Shared.Signal)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

ItemController.EquippedItemChanged = Signal.new("Deferred") :: Signal.Signal<ItemConstants.ItemType, string?, string?>

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ItemController.equipItem(itemType: ItemConstants.ItemType, itemName: string)
	ItemConstants.Remotes.ItemEquipped:FireServer(itemType, itemName)
end

function ItemController.unequipItem(itemType: ItemConstants.ItemType)
	ItemConstants.Remotes.ItemUnequipped:FireServer(itemType)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

DataController.Updated:Connect(function(event: string, new: any, metadata: { Type: ItemConstants.ItemType, Previous: string? })
	if event == "EquippedItemChanged" and metadata.Type then
		ItemController.EquippedItemChanged:Fire(metadata.Type, new, metadata.Previous)
	end
end)

return ItemController
