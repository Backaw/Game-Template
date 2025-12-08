--!strict
local ItemConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-------------------------------------------------------------------------------
-- PRIVATE  VARIABLES
-------------------------------------------------------------------------------

local types = {
	Test = "Test",
}

local friendlyTypeNames: { [ItemType]: string } = {}

-------------------------------------------------------------------------------
-- PUBLIC  VARIABLES
-------------------------------------------------------------------------------

ItemConstants.Types = types :: { [ItemType]: ItemType }
ItemConstants.FriendlyTypeNames = friendlyTypeNames

ItemConstants.Remotes = {
	ItemEquipped = Remotes.defineEvent("ItemEquippedToggled") :: Remotes.Event<ItemType, string>,
	ItemUnequipped = Remotes.defineEvent("ItemEquippedToggled") :: Remotes.Event<ItemType>,
}

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
}

return ItemConstants
