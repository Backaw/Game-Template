--!strict
local ProductController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local ProductConstants = require(Shared.Products.ProductConstants)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local ProductUtil = require(Shared.Products.ProductUtil)
local DebugUtil = require(Shared.Utils.DebugUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local Promise = require(Shared.Promise)
local Signal = require(Shared.Signal)
local Sounds = require(Shared.Sounds)
local CurrencyController = require(Client.CurrencyController)
local Snackbar = require(Client.UI.Components.Snackbar)
local Fireworks = require(Client.Utils.Fireworks)
-- local Confetti = require(Client.UI.Particles.Confetti)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)

local REMOTES = ProductConstants.Remotes

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Product = ProductConstants.Product
type PriceTracker = { Price: CurrencyConstants.Price, Handler: (boolean) -> () }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local debounces: { [ProductConstants.Product]: boolean? } = {}
local marketplacePromptOpen = false

local orderedCurrencyTiers: { [CurrencyConstants.Currency]: { string } } = {}

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
		-- Confetti.play(40, Confetti.Colors.Party, 2)
		Fireworks.screenOffsetEmit(6)
		Sounds.play("PremiumReward")
	end

	ProductController.ProductPurchased:Fire(product)
end

-------------------------------------------------------------------------------
-- PUBLIC  METHODS
-------------------------------------------------------------------------------

function ProductController.promptNeededCurrencyTier(product: ProductConstants.Product)
	local price = product.Price
	local currency =
		assert(CurrencyUtil.isInGameCurrency(price.Currency), "Can't prompt needed currency tier for premium currency: " .. price.Currency)

	ProductController.cannotAfford(price)

	local orderedTiers = assert(orderedCurrencyTiers[currency], "No ordered tiers found for currency: " .. currency)

	local cheapestTier = orderedTiers[1]
	if not cheapestTier then
		warn(`No products found for currency {currency}, cannot prompt purchase from additional currency`)
		return
	end

	for i = 2, #orderedTiers do
		local yield = orderedTiers[i]
		local yieldNumber = tonumber(yield)
		if yieldNumber and yieldNumber >= (price :: any).Amount - CurrencyController.Currencies[currency]:Get() then
			cheapestTier = yield
			break
		end
	end

	ProductController.promptPurchase(
		ProductConstants.Products[currency :: any][cheapestTier] or ProductConstants.Products[currency :: any][orderedTiers[#orderedTiers]],
		{ Source = "UnaffordableProduct", Item = {
			Type = product.Type,
			Name = product.Name,
		} }
	)
end

function ProductController.cannotAfford(price: CurrencyConstants.Price)
	Snackbar.error(("You don't have enough %ss!"):format(string.lower(price.Currency)))
end

function ProductController.hasGamePass(product: ProductConstants.Product)
	if product.Price.Currency ~= CurrencyConstants.Currencies.GamePass then
		error(("Product %s %s is not associated with a GamePass"):format(product.Type, product.Name))
	end

	return ProductUtil.hasGamePass(product)
end

-- Returns: Purchase valid, purchase validated
function ProductController.purchaseClientValidation(product: ProductConstants.Product)
	local price = product.Price

	if price.Currency == CurrencyConstants.Currencies.Free then
		warn("Purchase valid for free product")
		return true, true
	elseif CurrencyUtil.isInGameCurrency(price.Currency) then
		if CurrencyController.transact(price.Currency :: any, -((price :: any).Amount :: number)) then
			-- Sounds.play("Purchase")
			return true, true
		else
			ProductController.promptNeededCurrencyTier(product)
			return false, true
		end
	elseif ProductUtil.isPremium(product) then
		if marketplacePromptOpen then
			return false, true
		end

		marketplacePromptOpen = true
		if price.Currency == CurrencyConstants.Currencies.GamePass then
			local hasGamePass = ProductController.hasGamePass(product)
			return hasGamePass == true, hasGamePass
		else
			return false, false
		end
	end

	return false, true
end

function ProductController.promptPurchase(
	product: ProductConstants.Product,
	source: ProductConstants.PurchaseAttribution,
	getServerVerification: boolean?
)
	if debounces[product] then
		return false
	end

	local purchaseValid, purchaseValidated = ProductController.purchaseClientValidation(product)
	if not purchaseValid and purchaseValidated then
		return false
	end

	debounces[product] = true

	local success
	local serverValidation = Promise.new(function(resolve)
		success = REMOTES.PromptProductPurchase:InvokeServer(product.Type, product.Name, source)

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

function ProductController.trackAffordability(price: CurrencyConstants.Price, handler: (boolean) -> ())
	local currency = CurrencyUtil.isInGameCurrency(price.Currency)
	if not currency then
		return nil :: any
	end

	local priceAmount = (price :: any).Amount

	local lastValue: number?
	return CurrencyController.Currencies[currency]:Subscribe(function(amount)
		if lastValue and (math.sign(lastValue - priceAmount) == math.sign(amount - priceAmount)) then
			return
		end

		handler(amount >= priceAmount)
		lastValue = amount
	end)
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------------
do
	for currency in CurrencyConstants.IngameCurrencies do
		local products = ProductConstants.Products[currency :: any]
		if not products then
			continue
		end

		local orderedTiers = TableUtil.getKeys(products)
		table.sort(orderedTiers, function(yield1, yield2)
			local n1 = tonumber(yield1)
			local n2 = tonumber(yield2)
			if n1 and n2 then
				return n1 < n2
			end
			return true
		end)

		orderedCurrencyTiers[currency] = orderedTiers
	end
end

do
	ProductConstants.Products = REMOTES.GetProducts:InvokeServer()

	REMOTES.ProductsUpdated:OnClientEvent(function(registering, unregistering)
		ProductUtil.updateProducts(registering, unregistering)
		ProductController.ProductsUpdated:Fire()
	end)

	REMOTES.ProductGiven:OnClientEvent(function(productType, productName)
		onProductPurchased(ProductUtil.getProduct(productType, productName))
	end)
end

return ProductController
