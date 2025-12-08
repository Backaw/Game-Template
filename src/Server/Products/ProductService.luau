--!strict
local ProductService = {}

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Promise = require(ReplicatedStorage.Shared.Promise)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local GameAnalytics = require(ReplicatedStorage.Shared.Packages.GameAnalytics)
local DeferredPromise = require(ReplicatedStorage.Shared.DeferredPromise)
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local PlayersService = require(ServerStorage.Server.PlayersService)
local GameAnalyticsService = require(ServerStorage.Server.GameAnalyticsService)
local CurrencyService = require(ServerStorage.Server.CurrencyService)
local RewardService

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local MAX_PRICE_LOAD_ATTEMPTS = 5

local REMOTES = ProductConstants.Remotes

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Validator = (Player) -> boolean

-------------------------------------------------------------------------------
--  PRIVATE MEMBERS
-------------------------------------------------------------------------------

local productsInitialized = DeferredPromise.new()
local validators: { [ProductConstants.Product]: Validator } = {}

local robuxPrices: { [number]: number } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMEBRS
-------------------------------------------------------------------------------

ProductService.ProductPurchased = Signal.new() :: Signal.Signal<Player, ProductConstants.Product>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function updateRobuxPrices(updating: ProductConstants.ProductCategories)
	local promises = {}

	for infoType, idsToProducts in (ProductUtil.getRobuxProducts()) do
		for id in idsToProducts do
			-- Price has already been retrieved
			if robuxPrices[id] then
				continue
			end

			local promise = Promise.retry(function()
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
				robuxPrices[id] = (info :: any).PriceInRobux
			end)

			table.insert(promises, promise)
		end
	end

	if productsInitialized:getState() == Promise.States.Pending then
		Promise.all(promises)
			:andThen(function()
				productsInitialized.invokeResolve()
			end)
			:await()
	else
		productsInitialized = productsInitialized:andThen(function()
			return Promise.all(promises)
		end) :: DeferredPromise.DeferredPromise

		productsInitialized:await()
	end

	productsInitialized
		:andThen(function()
			for _, products in updating do
				for _, product in products do
					local id = (product.Price :: any).Id
					if id then
						assert(
							product.Price.Currency == "DevProduct" or product.Price.Currency == "GamePass",
							("Invalid product price: %s"):format(product.Name)
						)

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

function ProductService.giveGamepass(player: Player, id: number, verified: boolean?)
	local address = "GamePasses." .. id
	if verified or not PlayerDataService.get(player, address) then
		PlayerDataService.set(player, address, true, "GamePassPurchased", {
			Id = id,
		})
	end
end

function ProductService.giveProduct(player: Player, product: ProductConstants.Product)
	ProductService.ProductPurchased:Fire(player, product)
	REMOTES.ProductGiven:FireClient(player, product.Type, product.Name)
end

function ProductService.purchaseProduct(
	player: Player,
	productType: string,
	productName: string,
	attribution: ProductConstants.PurchaseAttribution
)
	local success = false

	-- RETURN: Product doesn't exist
	local product = ProductConstants.Products[productType][productName]
	if not product then
		return false
	end

	-- RETURN: Purchase isn't available atm
	local validator = validators[product]
	if validator then
		if not validator(player) then
			return false
		end
	end

	local price = product.Price
	if price.Currency == "Free" then
		success = true
	elseif CurrencyUtil.isInGameCurrency(price.Currency) then
		success = CurrencyService.transact(player, price.Currency, -(price :: any).Amount, productType, productName, true)
	else
		local id = (price :: any).Id :: number
		if price.Currency == "DevProduct" then
			MarketplaceService:PromptProductPurchase(player, id)
			success =
				table.pack(Promise.fromEvent(MarketplaceService.PromptProductPurchaseFinished, function(purchasorId, purchaseId: number)
					return Players:GetPlayerByUserId(purchasorId) == player and id == purchaseId
				end):await())[4] -- resolved, purchasesorId, purchaseId, wasPurchased

			if success then
				PlayerDataService.append(player, "DevProducts", {
					Timestamp = os.time(),
					Id = id,
				})
			end
		elseif price.Currency == "GamePass" then
			if ProductUtil.hasGamePass(product, player) then
				success = true
			else
				id = price.Id

				MarketplaceService:PromptGamePassPurchase(player, id)
				success = table.pack(
					Promise.fromEvent(MarketplaceService.PromptGamePassPurchaseFinished, function(purchasor: Player, purchaseId: number)
						return player == purchasor and id == purchaseId
					end):await()
				)[4]

				if success then
					ProductService.giveGamepass(player, id, true)
				end
			end
		end

		if attribution and id then
			local source
			local itemId
			if typeof(attribution) == "table" then
				source = attribution.Source
				local item = assert(attribution.Item, "Item is required")
				itemId = item.Type .. item.Name
			else
				source = attribution
				itemId = "None"
			end

			GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
				eventId = ("%s:%s:%s:%s:%s "):format("PremiumProductPrompted", tostring(id), tostring(source), tostring(success), itemId),
			})
		end
	end

	if success then
		ProductService.ProductPurchased:Fire(player, product)
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

	for productType, productList in ProductConstants.Products do
		for name, product in productList do
			product.Type = productType
			product.Name = name
		end
	end

	updateRobuxPrices(registering)
	Remotes.fireAllClients(REMOTES.ProductsUpdated, registering, unregistering)
end

function ProductService.init()
	RewardService = require(ServerStorage.Server.RewardService) :: any

	-- Create bundle products
	for name, bundle in ProductConstants.Bundles do
		local product: ProductConstants.Product = {
			Name = name,
			Type = ProductConstants.Types.Bundle,
			Icon = bundle.Icon,
			Price = bundle.Price,
		}

		ProductConstants.Products.Bundle[name] = product

		local version = bundle.Version or 1
		ProductService.registerValidator(product, function(player)
			return not ProductUtil.hasBundle(name, player)
		end)

		ProductService.ProductPurchased:Connect(function(player, purchasedProduct)
			if purchasedProduct == product then
				for _, reward in bundle.Rewards do
					(RewardService :: any).award(player, reward, "Bundle" .. name, false)
				end

				local ownedVersions = PlayerDataService.get(player, "OwnedBundles." .. name)
				if not ownedVersions then
					PlayerDataService.set(player, "OwnedBundles." .. name, { [tostring(version)] = true })
				else
					PlayerDataService.set(player, ("OwnedBundles.%s.%d"):format(name, version), true)
				end
			end
		end)
	end

	task.spawn(function()
		updateRobuxPrices(ProductConstants.Products)
	end)
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

-- Register items purchased outsite of the game
PlayersService.registerLoadHandler(PlayersService.LoadJobs.Products, function(player: Player)
	local userId = player.UserId

	for id, products in pairs(ProductUtil.getGamepassProducts()) do
		if not ProductUtil.hasGamePass(id, player) then
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
			-- :await()
		end
	end
end)

MarketplaceService.ProcessReceipt = function(info)
	GameAnalytics:ProcessReceiptCallback(info)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

REMOTES.PromptProductPurchase:OnServerInvoked(ProductService.purchaseProduct)
REMOTES.GetProducts:OnServerInvoked(function(_player: Player)
	productsInitialized:await()
	return ProductConstants.Products
end)

return ProductService
