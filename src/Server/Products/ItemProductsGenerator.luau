--!strict
local ItemProductsGenerator = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local ProductService = require(ServerStorage.Server.Products.ProductService)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)

--[[
local ItemConstants = require(Shared.Items.ItemConstants)
local RotatingProductConstants = require(Shared.Products.RotatingProductConstants)
local RotatingShopUtil = require(Shared.Products.RotatingShopUtil)
local RarityUtil = require(Shared.Rarity.RarityUtil)
local RarityConstants = require(Shared.Rarity.RarityConstants)
local TableUtil = require(Shared.Utils.TableUtil)
 *]]

-- Generate items from product
do
	local products: ProductConstants.ProductCategories = {}
	for itemType, items in (ItemUtil.getItems()) do
		if not ProductConstants.Types[itemType] then
			continue
		end

		local productsOfType: ProductConstants.ProductList = {}

		for itemName, item in items do
			local source = item.Source
			if source then
				local price = CurrencyUtil.isPrice(source)
				if price then
					local product: ProductConstants.Product = {
						Icon = item.Icon,
						Price = price,
						Name = item.Name,
						Type = itemType,
					}

					productsOfType[itemName] = product
				end
			end
		end

		products[itemType] = productsOfType
	end

	-- if products ~= {} then
	ProductService.updateProducts(products)
	-- end

	for itemType in products do
		ProductService.registerValidator(itemType, function(name)
			return function(player: Player)
				return not ItemUtil.hasItem(itemType, name, player)
			end
		end)
	end
end

--[[
-- Rotating shop products
do
	local lastProducts: ProductConstants.ProductCategories
	local rotatingItems: { [string]: { ItemConstants.Item } } = {}

	for itemType, items in  (ItemUtil.getItems()) do
		-- CONTINUE: No rotating items of this type
		if not RotatingShopUtil.isItemTypeSold(itemType) then
			continue
		end

		rotatingItems[itemType] = {}

		for _, item in  (items) do
			local source = item.Source
			if source and source.Name and RarityConstants.Rarities[source.Name] then
				table.insert(rotatingItems[itemType], item)
			end
		end
	end

	task.spawn(function()
		while true do
			local newProducts: ProductConstants.ProductCategories = {}

			local timeSinceStart = RotatingShopUtil.getTimeSinceStart()
			local random = Random.new(math.floor(timeSinceStart / RotatingProductConstants.RefreshDelay))

			for itemType, items in  (rotatingItems) do
				items = table.clone(items)

				local sellThisMany = math.min(#items, RotatingProductConstants.ItemsPerType[itemType])

				newProducts[itemType] = {}

				for _ = 1, sellThisMany do
					local chosen = RarityUtil.draw(TableUtil.getProperties(items, "Source"), nil, random)
					local item = items[chosen]

					newProducts[itemType][item.Name] = {
						Name = item.Name,
						Type = itemType,
						Icon = item.Icon,
						Price = RotatingProductConstants.Prices[item.Source][itemType],
						LimitedTime = true,
					}

					table.remove(items, chosen)
				end
			end

			ProductService.updateProducts(newProducts, lastProducts)
			lastProducts = newProducts

			local cooldown = RotatingShopUtil.getRotationCooldown()
			task.wait(cooldown)
		end
	end)
end
 *]]

return ItemProductsGenerator
