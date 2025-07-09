local ProductUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductConstants = require(ReplicatedStorage.Modules.Products.ProductConstants)
local CurrencyConstants = require(ReplicatedStorage.Modules.Currency.CurrencyConstants)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)
local StringUtil = require(ReplicatedStorage.Modules.Utils.StringUtil)
local DataUtil = require(ReplicatedStorage.Modules.Data.DataUtil)

function ProductUtil.getGamepassProducts()
	return ProductUtil.getRobuxProducts()[Enum.InfoType.GamePass]
end

function ProductUtil.getRobuxProducts()
	local robuxProducts: { [Enum.InfoType]: { [number]: { ProductConstants.Product } } } =
		{ [Enum.InfoType.Product] = {}, [Enum.InfoType.GamePass] = {} }

	for _, products in ProductConstants.Products do
		for _, product in products do
			local price = product.Price
			local currency = price.Currency

			if currency == CurrencyConstants.Currencies.GamePass or currency == CurrencyConstants.Currencies.DevProduct then
				local id = price.Id

				local productOfCurrency = robuxProducts[CurrencyConstants.InfoType[currency]]
				local otherProductsWithGamepass = productOfCurrency[id] or {}
				table.insert(otherProductsWithGamepass, product)

				productOfCurrency[id] = otherProductsWithGamepass
			end
		end
	end

	return robuxProducts
end

function ProductUtil.hasGamePass(product: ProductConstants.Product | number, player: Player?)
	local id = if typeof(product) == "number" then product else product.Price.Id
	return DataUtil.get(player, "GamePasses." .. id) ~= nil
end

function ProductUtil.hasBundle(name: string, player: Player?)
	local bundle = ProductConstants.Bundles[name]

	local ownedVersions = DataUtil.get(player, "OwnedBundles." .. name)
	if ownedVersions then
		if ownedVersions[tostring(bundle.Version or 1)] then
			return true
		end
	end
	return false
end

function ProductUtil.getProduct(type: string, name: string)
	-- ERROR: Invalid product type
	if not ProductConstants.Types[type] then
		error(("%s is an invalid product type"):format(type))
	end

	return ProductConstants.Products[type][name]
end

function ProductUtil.isPremium(product: table)
	local currency = product.Price.Currency
	return currency == CurrencyConstants.Currencies.DevProduct or currency == CurrencyConstants.Currencies.GamePass
end

function ProductUtil.getCmdrGamepasses()
	local passes: { [string]: number } = {}

	for gamepass, products in ProductUtil.getRobuxProducts()[Enum.InfoType.GamePass] do
		for _, product in products do
			passes[product.Name] = gamepass
		end
	end

	return passes
end

function ProductUtil.updateProducts(registering: ProductConstants.ProductCategories, unregistering: ProductConstants.ProductCategories)
	if unregistering then
		for productType, removing in unregistering do
			local products = ProductConstants.Products[productType]
			if not products then
				warn(("%s is an invalid product type"):format(productType))
				unregistering[productType] = nil

				continue
			end

			-- Don't use TableUtil.shallowSubtract cause elements won't be same on server->client
			for name in removing do
				products[name] = nil :: ProductConstants.Product
			end
		end
	end

	for productType, newProducts in registering do
		local existingProducts = ProductConstants.Products[productType]
		if not existingProducts then
			warn(("%s is an invalid product type"):format(productType))
			continue
		end

		TableUtil.shallowUnion(existingProducts, newProducts)
	end

	return registering, unregistering
end

function ProductUtil.getDisplayName(product: ProductConstants.Product)
	return product.Alias or StringUtil.seperateSnakeCase(product.Name)
end

return ProductUtil
