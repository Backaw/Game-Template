local ProductService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local Paths = require(ServerScriptService.Paths)
local Promise = require(Paths.Packages.Promise)
local Signal = require(Paths.Shared.Signal)
local Remotes = require(Paths.Shared.Remotes)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(Paths.Shared.Currency.CurrencyUtil)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local CurrencyService = require(Paths.Services.CurrencyService)
local PlayersService = require(Paths.Services.PlayersService)
local GameAnalytics = require(Paths.Packages.GameAnalytics)
local DeferredPromise = require(Paths.Shared.DeferredPromise)
local RewardService = require(Paths.Services.RewardService)
local GameAnalyticsService = require(Paths.Services.GameAnalyticsService)

local MAX_PRICE_LOAD_ATTEMPTS = 5

type Validator = (Player, number) -> boolean

-------------------------------------------------------------------------------
--  PRIVATE MEMBERS
-------------------------------------------------------------------------------
local productsInitialized = DeferredPromise.new()
local validators: { [ProductConstants.Product]: Validator } = {}

local robuxPrices: { [number]: number } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMEBRS
-------------------------------------------------------------------------------
ProductService.ProductPurchased = Signal.new() --> (player : Player, product : ProductConstants.Product)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function updateRobuxPrices(updating: ProductConstants.ProductCategories)
	local promises = {}
	for infoType, idsToProducts in pairs(ProductUtil.getRobuxProducts()) do
		for id in pairs(idsToProducts) do
			-- Price has already been retrieved
			if robuxPrices[id] then
				continue
			end

			table.insert(
				promises,
				Promise.retry(function()
					return Promise.new(function(resolve, reject)
						local success, info = pcall(function()
							return MarketplaceService:GetProductInfo(id, infoType)
						end)
						if success then
							resolve(info)
						else
							reject(info)
						end
					end)
				end, MAX_PRICE_LOAD_ATTEMPTS):andThen(function(info)
					robuxPrices[id] = info.PriceInRobux
				end)
			)
		end
	end

	if productsInitialized:getStatus() == Promise.Status.Started then
		Promise.all(promises)
			:andThen(function()
				productsInitialized:invokeResolve()
			end)
			:await()
	else
		productsInitialized = productsInitialized:andThen(function()
			return Promise.all(promises)
		end)

		productsInitialized:await()
	end

	productsInitialized
		:andThen(function()
			for _, products in pairs(updating) do
				for _, product in pairs(products) do
					local id = product.Price.Id
					if id then
						local price = robuxPrices[id]
						product.Price.PriceInRobux = price or 0 -- Avoid bugs
					end
				end
			end
		end)
		:await()
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function ProductService.hasGamePass(player: Player, product: ProductConstants.Product)
	return PlayerDataService.get(player, ProductUtil.getGamepassAddress(product)) ~= nil
end

function ProductService.giveGamepass(player: Player, id: number, verified: boolean?)
	local address = "GamePasses." .. id
	if verified or not PlayerDataService.get(player, address) then
		PlayerDataService.set(player, address, true, "GamePassPurchased", {
			Id = id,
		})
	end
end

function ProductService.giveProduct(player: Player, product: ProductConstants.Product, count: number?)
	ProductService.ProductPurchased:Fire(player, product)
	Remotes.fireClient(player, "ProductGiven", product.Type, product.Name, count or 1)
end

function ProductService.purchaseProduct(player: Player, productType: string, productName: string, count: number?, source: string)
	local success = false

	count = count or 1

	-- RETURN: Product doesn't exist
	local product = ProductConstants.Products[productType][productName]
	if not product then
		return false
	end

	-- RETURN: Purchase isn't available atm
	local validator = validators[product]
	if validator then
		if not validator(player, count) then
			return false
		end
	end

	local price = product.Price
	if price.Currency == CurrencyConstants.Currencies.Free then
		success = true
	elseif CurrencyUtil.isInGameCurrency(price.Currency) then
		success = CurrencyService.transact(player, price.Currency, -price.Amount * count, productType, productName, true)
	else
		count = 1

		local id
		if price.Currency == CurrencyConstants.Currencies.DevProduct then
			id = price.Id

			MarketplaceService:PromptProductPurchase(player, price.Id)
			_, _, _, success = Promise.fromEvent(MarketplaceService.PromptProductPurchaseFinished, function(purchasorId, purchaseId)
				return Players:GetPlayerByUserId(purchasorId) == player and id == purchaseId
			end):await()
			if success then
				PlayerDataService.append(player, "DevProducts", {
					Timestamp = os.time(),
					Id = id,
				})
			end
		elseif price.Currency == CurrencyConstants.Currencies.GamePass then
			if ProductService.hasGamePass(player, product) then
				success = true
			else
				id = price.Id

				MarketplaceService:PromptGamePassPurchase(player, id)
				_, _, _, success = Promise.fromEvent(MarketplaceService.PromptGamePassPurchaseFinished, function(purchasor, purchaseId)
					return player == purchasor and id == purchaseId
				end):await()

				if success then
					ProductService.giveGamepass(player, id, true)
				end
			end
		end

		if source and id then
			GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
				eventId = ("%s:%s:%s:%s"):format("PremiumProductPrompted", tostring(id), tostring(source), tostring(success)),
			})
		end
	end

	if success then
		ProductService.ProductPurchased:Fire(player, product, count)
	end

	return success
end

function ProductService.registerValidator(product: ProductConstants.Product, validator: Validator)
	validators[product] = validator
end

function ProductService.updateProducts(
	registering: ProductConstants.ProductCategories,
	unregistering: ProductConstants.ProductCategories | nil
)
	ProductUtil.updateProducts(registering, unregistering)

	for productType, productList in pairs(ProductConstants.Products) do
		for name, product in pairs(productList) do
			product.Type = productType
			product.Name = name
		end
	end

	updateRobuxPrices(registering)
	Remotes.fireAllClients("ProductsUpdated", registering, unregistering)
end

-- Register items purchased outsite of the game
ProductService.loadPlayer = PlayersService.promisifyLoader(function(player: Player)
	local userId = player.UserId

	for id, products in pairs(ProductUtil.getGamepassProducts()) do
		local address = ProductUtil.getGamepassAddressFromId(id)

		if not PlayerDataService.get(player, address) then
			Promise.retry(function()
				return Promise.new(function(resolve)
					local owned = MarketplaceService:UserOwnsGamePassAsync(userId, id)
					resolve(owned)
				end)
			end, 3):andThen(function(owned)
				if owned then
					for _, product in products do
						ProductService.giveProduct(player, product)
					end

					ProductService.giveGamepass(player, id, true)
				end
			end)
		end
	end
end, "Gamepasses")

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------
do
	-- Fill in missing produt info
	for _, productType in pairs(ProductConstants.Types) do
		CurrencyService.ResourceType[productType] = productType
	end

	-- Create bundle products
	for name, bundle in pairs(ProductConstants.Bundles) do
		local product: ProductConstants.Product = {
			Name = name,
			Icon = bundle.Icon,
			Price = {
				Currency = CurrencyConstants.Currencies.GamePass,
				Id = bundle.Gamepass,
			},
		}

		ProductConstants.Products.Bundle[name] = product

		ProductService.ProductPurchased:Connect(function(player, purchasedProduct)
			if purchasedProduct == product then
				for _, reward in pairs(bundle.Rewards) do
					RewardService.award(player, reward, "Bundle" .. name, false)
				end
			end
		end)
	end

	task.spawn(function()
		updateRobuxPrices(ProductConstants.Products)
	end)
end

MarketplaceService.ProcessReceipt = function(info)
	GameAnalytics:ProcessReceiptCallback(info)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

Remotes.bindFunctions({
	PromptProductPurchase = ProductService.purchaseProduct,
	GetProducts = function()
		productsInitialized:await()
		return ProductConstants.Products
	end,
})

Remotes.declareEvent("ProductsUpdated")
Remotes.declareEvent("ProductGiven")

return ProductService
