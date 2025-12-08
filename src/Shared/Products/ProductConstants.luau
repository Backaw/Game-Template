--!strict
local ProductConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type _Product = {
	Alias: string?,
	Price: CurrencyConstants.Price,
	Icon: string?,
	LimitedTime: boolean?,
}
export type Product = _Product & {
	Name: string,
	Type: string,
}

type _Bundle = {
	ExpiresAt: number?,
	Icon: string,
	Price: CurrencyConstants.Price,
	Rewards: { RewardConstants.Reward },
	Version: number?,
}

export type Bundle = _Bundle & {
	Name: string,
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
--  PRIVATE VARIABLES
-------------------------------------------------------------------------------

local types: { [string]: string } = {
	Cash = "Cash",
}

local products: { [string]: { [string]: _Product } } = {
	-- Item products are created below
	Cash = {},
	Multiplier = {},
}

local bundles: { [string]: _Bundle } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

ProductConstants.Types = types
ProductConstants.Bundles = bundles :: { [string]: Bundle }
ProductConstants.Products = products :: { [string]: { [string]: Product } }

ProductConstants.Remotes = {
	ProductsUpdated = Remotes.defineEvent("ProductsUpdated") :: Remotes.Event<ProductCategories, ProductCategories?>,
	ProductGiven = Remotes.defineEvent("ProductGiven") :: Remotes.Event<string, string, number?>,
	PromptProductPurchase = Remotes.defineFunction("PromptProductPurchase") :: Remotes.Function<(string, string, PurchaseAttribution), (boolean)>,
	GetProducts = Remotes.defineFunction("GetProducts") :: Remotes.Function<(), (ProductCategories)>,
}

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------

for _, itemType in pairs(ItemConstants.Types) do
	ProductConstants.Types[itemType] = itemType
end

for name, bundle in pairs(ProductConstants.Bundles) do
	bundle.Name = name
end

for _, productType in pairs(ProductConstants.Types) do
	ProductConstants.Products[productType] = ProductConstants.Products[productType] or {}
end

return ProductConstants
