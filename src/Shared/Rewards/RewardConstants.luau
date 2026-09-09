local RewardConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)

export type RewardType = keyof<typeof(RewardConstants.Types)>
export type Reward =
	{ Type: "Currency", Currency: CurrencyConstants.Currency, Amount: number }
	| { Type: "Item", ItemType: ItemConstants.ItemType, ItemName: string, Loan: boolean? }
	| { Type: "Boost", Currency: CurrencyConstants.Currency, Multiplier: number, LengthInMinutes: number }

RewardConstants.Types = {
	Item = "Item",
	Currency = "Currency",
	Boost = "Boost",
}

return RewardConstants
