--!strict
local ProductController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local Promise = require(ReplicatedStorage.Shared.Promise)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Snackbar = require(ReplicatedStorage.Client.UI.Components.Snackbar)
local CurrencyController = require(ReplicatedStorage.Client.CurrencyController)
local Confetti = require(ReplicatedStorage.Client.UI.Particles.Confetti)

export type Product = ProductConstants.Product
type PriceTracker = { Price: CurrencyConstants.Price, Handler: (boolean) -> () }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)

local debounces: { [ProductConstants.Product]: boolean? } = {}
local marketplacePromptOpen = false

local priceTrackers: { PriceTracker } = {}

local orderedCashTiers = TableUtil.getKeys(ProductConstants.Products.Cash)
table.sort(orderedCashTiers, function(yield1, yield2)
	local n1 = tonumber(yield1)
	local n2 = tonumber(yield2)
	if n1 and n2 then
		return n1 < n2
	end
	return true
end)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

ProductController.ProductPurchased = Signal.new() :: Signal.Signal<ProductConstants.Product>
ProductController.ProductsUpdated = Signal.new() :: Signal.Signal<>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function onProductPurchased(product: ProductConstants.Product)
	if ProductUtil.isPremium(product) then
		Confetti.play(40, Confetti.Colors.Party, 2)
		Sounds.play("PremiumReward")
	end

	ProductController.ProductPurchased:Fire(product)
end

-------------------------------------------------------------------------------
-- PUBLIC  METHODS
-------------------------------------------------------------------------------

function ProductController.promptNeededCashTier(product: ProductConstants.Product)
	local price = product.Price

	if price.Currency == "Cash" then
		local cheapestTier = orderedCashTiers[1]
		for i = 2, #orderedCashTiers do
			local yield = orderedCashTiers[i]
			local yieldNumber = tonumber(yield)
			if yieldNumber and yieldNumber >= price.Amount - CurrencyController.get(CurrencyConstants.Currencies.Cash) then
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

function ProductController.trackAffordability(price: CurrencyConstants.Price, handler: (boolean) -> ()): (() -> ())?
	if price.Currency == "Cash" then
		handler(CurrencyController.get(price.Currency) >= price.Amount :: number)
		local tracker: PriceTracker = { Price = price, Handler = handler }

		table.insert(priceTrackers, tracker)
		return function()
			table.remove(priceTrackers, table.find(priceTrackers, tracker))
		end
	end

	return nil
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
		if CurrencyController.transact(price.Currency, -((price :: any).Amount :: number)) then
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

	return success or false
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
	ProductGiven = function(productType: string, productName: string)
		onProductPurchased(ProductUtil.getProduct(productType, productName))
	end,
})

CurrencyController.Changed:Connect(function(currency: string, amount: number, lastAmount: number)
	for _, tracker in ipairs(priceTrackers) do
		if tracker.Price.Currency == currency then
			local priceAmount = (tracker.Price :: any).Amount :: number
			local couldAfford = lastAmount >= priceAmount
			local canAfford = amount >= priceAmount
			if couldAfford ~= canAfford then
				tracker.Handler(canAfford)
			end
		end
	end
end)

return ProductController
