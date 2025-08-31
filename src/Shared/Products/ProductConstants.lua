local ProductConstants = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Modules.Currency.CurrencyConstants)
local RewardConstants = require(ReplicatedStorage.Modules.Rewards.RewardConstants)
local ItemConstants = require(ReplicatedStorage.Modules.Items.ItemConstants)

export type Product = {
	Name: string,
	Type: string,
	Alias: string?,
	Icon: string,
	Price: CurrencyConstants.Price,
	LimitedTime: boolean?,
}

export type Bundle = {
	Name: string,
	ExpiresAt: number?,
	Icon: string,
	Price: CurrencyConstants.Price,
	Rewards: { RewardConstants.Reward },
	Version: number?,
}

export type ProductList = { [string]: Product }
export type ProductCategories = { [string]: ProductList }

export type PurchaseAttribution = string | {
	Source: string,
	Item: {
		Type: string,
		Name: string,
	}?,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local products: { [string]: { [string]: {
	Price: CurrencyConstants.Price,
	Icon: string,
	LimitedTime: boolean?,
	Alias: string?,
} } } =
	{
		-- Item products are created below
		Cash = {},
		Multiplier = {},
	}
local bundles: { [string]: Bundle } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
ProductConstants.Types = {
	Cash = "Cash",
}
ProductConstants.Bundles = bundles
ProductConstants.Products = products

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------
for _, itemType in pairs(ItemConstants.Types) do
	ProductConstants.Types[itemType] = itemType
end
for _, productType in pairs(ProductConstants.Types) do
	products[productType] = products[productType] or {}
end

for name, bundle in pairs(ProductConstants.Bundles) do
	bundle.Name = name
end

return ProductConstants
