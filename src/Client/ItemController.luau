--!strict
local ItemController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Client.DataController)
local Signal = require(ReplicatedStorage.Shared.Signal)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local EVENT_NAME = "ItemHandling"
local EVENT_ACTIONS = { Equip = "Equip", Unequip = "Unequip" }

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

ItemController.EquippedItemChanged = Signal.new("Deferred") :: Signal.Signal<ItemConstants.ItemType, string?, string?>

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ItemController.equipItem(itemType: ItemConstants.ItemType, itemName: string)
	Remotes.fireServer(EVENT_NAME, EVENT_ACTIONS.Equip, itemType, itemName)
end

function ItemController.unequipItem(itemType: ItemConstants.ItemType)
	Remotes.fireServer(EVENT_NAME, EVENT_ACTIONS.Unequip, itemType)
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
