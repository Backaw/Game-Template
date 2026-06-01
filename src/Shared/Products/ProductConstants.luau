--!strict
local ProductConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)

-------------------------------------------------------------------------------
--  PRIVATE VARIABLES
-------------------------------------------------------------------------------

local TYPES = {
	Coins = "Coins",
	Boost = "Boost",
	Bundle = "Bundle",
	Upgrade = "Upgrade",
	ConsumeableAbility = "ConsumeableAbility",
}

local PRODUCTS: { [string]: { [string]: _Product } } = {
	-- Item products are created below
	Cash = {},
	Multiplier = {},
}

local BUNDLES: { [string]: _Bundle } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

ProductConstants.Types = TYPES :: { [ProductType]: ProductType }
ProductConstants.Bundles = BUNDLES :: { [string]: Bundle }
ProductConstants.Products = PRODUCTS :: ProductCategories

ProductConstants.Remotes = {
	ProductsUpdated = Remotes.defineEvent("ProductsUpdated") :: Remotes.Event<ProductCategories, ProductCategories?>,
	ProductGiven = Remotes.defineEvent("ProductGiven") :: Remotes.Event<ProductType, string>,
	PromptProductPurchase = Remotes.defineFunction("PromptProductPurchase") :: Remotes.Function<(ProductType, string, PurchaseAttribution), (boolean)>,
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
	Type: ProductType,
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
export type ProductCategories = { [ProductType]: ProductList }
export type PurchaseAttribution = string | {
	Source: string,
	Item: {
		Type: string,
		Name: string,
	}?,
}

export type ProductType = keyof<typeof(TYPES)> | ItemConstants.ItemType

return ProductConstants
