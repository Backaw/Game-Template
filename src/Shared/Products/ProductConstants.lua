local ProductConstants = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Modules.Currency.CurrencyConstants)
local RewardConstants = require(ReplicatedStorage.Modules.Rewards.RewardConstants)

export type Product = {
	Name: string?,
	Alias: string?,
	Price: CurrencyConstants.Price,
	Type: string?,
	Icon: string?,
	LimitedTime: boolean?,
}

export type Bundle = {
	Name: string?,
	ExpiresAt: number?,
	Icon: string,
	Price: CurrencyConstants.Price,
	Rewards: { RewardConstants.Reward },
	Version: number?,
}

export type ProductList = { [string]: Product }
export type ProductCategories = { [string]: ProductList }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local products: { [string]: { [string]: Product } } = {
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
	Tool = "Tool",
	Eye = "Eye",
}
ProductConstants.Bundles = bundles
ProductConstants.Products = products

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------
for _, productType in pairs(ProductConstants.Types) do
	products[productType] = products[productType] or {}
end

for name, bundle in pairs(ProductConstants.Bundles) do
	bundle.Name = name
end

return ProductConstants
