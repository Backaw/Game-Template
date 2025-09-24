--!strict
local ItemConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)

export type Item = {
	Name: string,
	Type: ItemType,
	Icon: string,
	Source: ItemSource,
	Alias: string?,
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

local types = {
	Test = "Test",
}

local friendlyTypeNames: { [ItemType]: string } = {}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

ItemConstants.Types = types :: { [ItemType]: ItemType }
ItemConstants.FriendlyTypeNames = friendlyTypeNames

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type ItemSource = CurrencyConstants.Price?
export type ItemType = keyof<typeof(types)>

return ItemConstants
