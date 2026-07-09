--!strict
local ItemConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local RarityConstants = require(ReplicatedStorage.Shared.Rarity.RarityConstants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-------------------------------------------------------------------------------
-- PRIVATE  VARIABLES
-------------------------------------------------------------------------------

local types = {
	Test = "Test",
}

local friendlyTypeNames: { [ItemType]: string } = {}

local equipSlots = {
	Test = 1,
}

local equippedItemsRequirement = {
	Test = 1,
}

-------------------------------------------------------------------------------
-- PUBLIC  VARIABLES
-------------------------------------------------------------------------------

ItemConstants.Types = types :: { [ItemType]: ItemType }
ItemConstants.FriendlyTypeNames = friendlyTypeNames

ItemConstants.Remotes = {
	ItemEquipped = Remotes.defineEvent("ItemEquipped") :: Remotes.Event<ItemType, string, string>,
	ItemUnequipped = Remotes.defineEvent("ItemUnequipped") :: Remotes.Event<ItemType, string>,
}

ItemConstants.EquippedItemsRequirement = equippedItemsRequirement :: { [ItemType]: number }
ItemConstants.EquipSlots = equipSlots :: { [ItemType]: number }

ItemConstants.DataEvents = {
	ItemAcquired = "ItemAcquired",
	EquippedChanged = "EquippedItemChanged",
}

ItemConstants.StoreTemplates = {}

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type ItemSource = CurrencyConstants.Price?
export type ItemType = keyof<typeof(types)>

export type Item = {
	Name: string,
	Type: ItemType,
	Icon: string,
	Source: ItemSource,
	Alias: string?,
	Rarity: RarityConstants.Rarity,
}

return ItemConstants
