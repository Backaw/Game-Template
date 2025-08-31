local ProductController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local Shared = ReplicatedStorage.Modules
local Remotes = require(Shared.Remotes)
local ProductUtil = require(Shared.Products.ProductUtil)
local ProductConstants = require(Shared.Products.ProductConstants)
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local Promise = require(Shared.Packages.Promise)
local Signal = require(Shared.Signal)
local Sounds = require(Shared.Sounds)
local DebugUtil = require(Shared.Utils.DebugUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local Snackbar = require(Controllers.UI.Components.Snackbar)
local CurrencyController = require(Controllers.CurrencyController)
-- local Confetti = require(Controllers .UI.Particles.Confetti)

export type Product = ProductConstants.Product

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local DEBUG = DebugUtil.isDebugging(false)

local debounces: { [ProductConstants.Product]: boolean? } = {}
local marketplacePromptOpen = false

local priceTrackers: { { Price: CurrencyConstants.Price, Handler: (boolean) -> () } } = {}

local orderedCashTiers = TableUtil.getKeys(ProductConstants.Products.Cash)
table.sort(orderedCashTiers, function(yield1, yield2)
	return tonumber(yield1) < tonumber(yield2)
end)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
ProductController.ProductPurchased = Signal.new()
ProductController.ProductsUpdated = Signal.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function onProductPurchased(product: ProductConstants.Product)
	if ProductUtil.isPremium(product) then
		-- Confetti.play(40, Confetti.Colors.Party, 2)
		Sounds.play("PremiumReward")
	end

	ProductController.ProductPurchased:Fire(product)
end

-------------------------------------------------------------------------------
-- PUBLIC  METHODS
-------------------------------------------------------------------------------
function ProductController.promptNeededCashTier(product: ProductConstants.Product)
	local price = product.Price
	assert(price.Currency == CurrencyConstants.Currencies.Cash, "Can't prompt for coin tier for non-coin product")

	local cheapestTier
	for _, yield in pairs(orderedCashTiers) do
		if tonumber(yield) >= price.Amount - CurrencyController.get(CurrencyConstants.Currencies.Cash) then
			cheapestTier = yield
			break
		end
	end

	ProductController.cannotAfford(price)
	ProductController.promptPurchase(
		ProductConstants.Products.Cash[cheapestTier] or ProductConstants.Products.Cash[orderedCashTiers[#orderedCashTiers]],
		{ Source = "UnaffordableItem", Item = {
			Type = product.Type,
			Name = product.Name,
		} }
	)
end

function ProductController.cannotAfford(price: CurrencyConstants.Price)
	Snackbar.error(("You don't have enough %s!"):format(string.lower(price.Currency)))
end

function ProductController.hasGamePass(product: ProductConstants.Product)
	if product.Price.Currency ~= CurrencyConstants.Currencies.GamePass then
		error(("Product %s %s is not associated with a GamePass"):format(product.Type, product.Name))
	end

	return ProductUtil.hasGamePass(product)
end

function ProductController.trackAffordability(price: CurrencyConstants.Price, handler: (boolean) -> ())
	if not CurrencyUtil.isInGameCurrency(price.Currency) then
		return false
	end

	handler(CurrencyController.get(price.Currency) >= price.Amount :: number)
	local tracker = { Price = price, Handler = handler }

	table.insert(priceTrackers, tracker)
	return function()
		table.remove(priceTrackers, table.find(priceTrackers, tracker))
	end
end

function ProductController.promptPurchase(
	product: ProductConstants.Product,
	source: ProductConstants.PurchaseAttribution,
	getServerVerification: boolean?
)
	if debounces[product] then
		return false
	end

	local price = product.Price

	local success
	if CurrencyUtil.isInGameCurrency(price.Currency) then
		if CurrencyController.transact(price.Currency, -price.Amount) then
			success = true
			Sounds.play("Purchase")
		else
			ProductController.promptNeededCashTier(product)
			return false
		end
	elseif ProductUtil.isPremium(product) then
		if marketplacePromptOpen then
			return false
		end

		marketplacePromptOpen = true
		if price.Currency == CurrencyConstants.Currencies.GamePass then
			success = if ProductController.hasGamePass(product) then true else nil
		end
	end

	debounces[product] = true

	local serverValidation = Promise.new(function(resolve)
		success = Remotes.invokeServer("PromptProductPurchase", product.Type, product.Name, 1, source)

		if not success then
			if DEBUG then
				warn(("Product purchase failed for %s product %s"):format(product.Type, product.Name))
			end

			-- TODO: Reverse handler?
		end
		resolve()
	end)

	if getServerVerification or not success then
		serverValidation:await()
	end

	if success then
		onProductPurchased(product)
	end

	if ProductUtil.isPremium(product) then
		marketplacePromptOpen = false
	end

	debounces[product] = nil
	return success
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------------
ProductConstants.Products = Remotes.invokeServer("GetProducts")

Remotes.bindEvents({
	ProductsUpdated = function(registering, unregistering)
		ProductUtil.updateProducts(registering, unregistering)
		ProductController.ProductsUpdated:Fire()
	end,
	ProductGiven = function(productType, productName)
		onProductPurchased(ProductConstants.Products[productType][productName])
	end,
})

CurrencyController.Changed:Connect(function(currency: string, amount: number, lastAmount: number)
	for _, tracker in ipairs(priceTrackers) do
		if tracker.Price.Currency == currency then
			local priceAmount = tracker.Price.Amount
			local couldAfford = lastAmount >= priceAmount
			local canAfford = amount >= priceAmount
			if couldAfford ~= canAfford then
				tracker.Handler(canAfford)
			end
		end
	end
end)

return ProductController
