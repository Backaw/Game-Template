local ProductController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local CurrencyController = require(Paths.Controllers.CurrencyController)
local CurrencyUtil = require(Paths.Shared.Currency.CurrencyUtil)
local Snackbar = require(Paths.Controllers.UI.Components.Snackbar)
local Promise = require(Paths.Shared.Packages.Promise)
local DataController = require(Paths.Controllers.DataController)
local Signal = require(Paths.Shared.Signal)
-- local Confetti = require(Paths.Controllers.UI.Particles.Confetti)
local Sounds = require(Paths.Shared.Sounds)

local DEBUGGING = false

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local debounces: { [ProductConstants.Product]: boolean? } = {}
local marketplacePromptOpen = false

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
ProductController.ProductPurchased = Signal.new()
ProductController.ProductsUpdated = Signal.new()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function onProductPurchased(product: ProductConstants.Product)
	if product.Price.Currency == CurrencyConstants.Currencies.GamePass then
		-- Confetti.play(40, Confetti.Colors.Party, 2)
		Sounds.play("Unlock")
	end

	ProductController.ProductPurchased:Fire(product)
end

-------------------------------------------------------------------------------
-- PUBLIC  METHODS
-------------------------------------------------------------------------------
function ProductController.cannotAfford(price: CurrencyConstants.Price)
	Snackbar.error(("You don't have enough %s!"):format(string.lower(price.Currency)))
end

function ProductController.hasGamePass(product: ProductConstants.Product)
	if product.Price.Currency ~= CurrencyConstants.Currencies.GamePass then
		error(("Product %s %s is not associated with a GamePass"):format(product.Type, product.Name))
	end

	return ProductUtil.hasGamePass(nil, product)
end

function ProductController.promptPurchase(product: ProductConstants.Product, source: string?, getServerVerification: boolean?)
	if debounces[product] then
		return false
	end

	local price = product.Price

	local success
	if CurrencyUtil.isInGameCurrency(price.Currency) then
		if CurrencyController.transact(price.Currency, -price.Amount) then
			success = true
		else
			-- Snackbar.error(("Not enough %s"):format(price.Currency))
			ProductController.cannotAfford(price)
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
			if DEBUGGING then
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

return ProductController
