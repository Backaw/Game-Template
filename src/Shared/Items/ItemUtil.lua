local ItemUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemConstants = require(ReplicatedStorage.Modules.Items.ItemConstants)
local ProductConstants = require(ReplicatedStorage.Modules.Products.ProductConstants)
local InstanceUtil = require(ReplicatedStorage.Modules.Utils.InstanceUtil)
local StringUtil = require(ReplicatedStorage.Modules.Utils.StringUtil)
local RarityConstants = require(ReplicatedStorage.Modules.Rarity.RarityConstants)
local DataUtil = require(ReplicatedStorage.Modules.Data.DataUtil)

local TESTING = false

local items: { [string]: { [string]: ItemConstants.Item } } = {}

function ItemUtil.getOwnedItemsAddressFromType(itemType: string)
	-- ERROR: Invalid item type
	if not ItemConstants.Types[itemType] then
		error(("%s is an invalid item type"):format(itemType))
	end

	return "OwnedItems." .. itemType
end

function ItemUtil.getProductFromItem(item: table): ProductConstants.Product | nil
	local itemType = item.Type
	local itemName = item.Name
	local typeProducts = ProductConstants.Products[itemType]
	if typeProducts then
		local regular = typeProducts[item.Name]
		if regular then
			return regular
		else
			for _, bundle in ProductConstants.Bundles do
				for _, reward in bundle.Rewards do
					if reward.ItemType == itemType and reward.ItemName == itemName then
						return ProductConstants.Products.Bundle[bundle.Name]
					end
				end
			end
		end
	else
		return nil
	end
end

function ItemUtil.getItemsOfType(itemType)
	return items[itemType]
end

function ItemUtil.getItems()
	return items
end

function ItemUtil.hasItem(itemType: string, itemName: string, player: Player?)
	return DataUtil.get(player, ("OwnedItems.%s.%s"):format(itemType, itemName)) ~= nil
end

function ItemUtil.getItem(itemType: string, itemName: string)
	return items[itemType][itemName]
end

function ItemUtil.getOwnedItemsOfType(itemType: string, player: Player?)
	-- ERROR: Invalid item type
	if not ItemConstants.Types[itemType] then
		error(("%s is an invalid item type"):format(itemType))
	end

	return DataUtil.get(player, "OwnedItems." .. itemType)
end

function ItemUtil.getCmdrTypeName(itemType: string)
	return StringUtil.toCamelCase(itemType .. "ItemName")
end

function ItemUtil.getItemNameCmdrArgument(itemTypeArgument)
	local itemType = itemTypeArgument:GetValue()

	return {
		Type = ItemUtil.getCmdrTypeName(itemType),
		Name = "name",
		Description = itemType .. " item being given",
	}
end

function ItemUtil.getFriendlyTypeName(itemType: string)
	return ItemConstants.FriendlyTypeNames[itemType] or itemType
end

function ItemUtil.getItemRarity(itemType: string, itemName: string)
	local item = ItemUtil.getItem(itemType, itemName)
	if item then
		local source = item.Source
		if source then
			return source
		end

		return if not source then RarityConstants.Rarities.Epic else RarityConstants.Rarities.Common
	end
end

function ItemUtil.getDisplayName(itemType: string, itemName: string)
	local item = ItemUtil.getItem(itemType, itemName)
	return item.Alias or StringUtil.seperateSnakeCase(itemName)
end

for itemType in ItemConstants.Types do
	items[itemType] = require(InstanceUtil.findFirstDescendant(script.Parent, itemType .. "Items")).Items
	for key, item in items[itemType] do
		item.Name = key
		item.Type = itemType

		if TESTING then
			item.Source = {
				Currency = "Free",
			}
		end
	end
end

return ItemUtil
