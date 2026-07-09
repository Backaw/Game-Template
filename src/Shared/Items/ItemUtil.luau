--!strict
local ItemUtil = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local ItemConstants = require(Shared.Items.ItemConstants)
local ProductConstants = require(Shared.Products.ProductConstants)
local StringUtil = require(Shared.Utils.StringUtil)
local RarityConstants = require(Shared.Rarity.RarityConstants)
local DataUtil = require(Shared.Data.DataUtil)
local InstanceUtil = require(Shared.Utils.InstanceUtil)
local RarityUtil = require(Shared.Rarity.RarityUtil)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local DebugUtil = require(Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local TESTING = DebugUtil.isDebugging(false)

local items: { [ItemConstants.ItemType]: { [string]: ItemConstants.Item } } = {}
local defaultItems: { [ItemConstants.ItemType]: string } = {}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

function ItemUtil.getOwnedItemsAddress(itemType: ItemConstants.ItemType)
	-- ERROR: Invalid item type
	if not ItemConstants.Types[itemType] then
		error(("%s is an invalid item type"):format(itemType))
	end

	return "OwnedItems." .. itemType
end

function ItemUtil.getOwnedItemAddress(itemType: ItemConstants.ItemType, itemName: string)
	return `{ItemUtil.getOwnedItemsAddress(itemType)}.{itemName}`
end

function ItemUtil.getOwnedItems(itemType: ItemConstants.ItemType, player: Player?): { string }
	local store = DataUtil.get(player :: Player, ItemUtil.getOwnedItemsAddress(itemType))
	return (if store then TableUtil.getKeys(store) else {}) :: { string }
end

function ItemUtil.getItemStore(itemType: ItemConstants.ItemType, itemName: string, player: Player?)
	return DataUtil.get(player :: Player, ItemUtil.getOwnedItemAddress(itemType, itemName))
end

function ItemUtil.getItemStores(itemType: ItemConstants.ItemType, player: Player?)
	return DataUtil.get(player :: Player, ItemUtil.getOwnedItemsAddress(itemType))
end

function ItemUtil.getStoreTemplate(itemType: ItemConstants.ItemType): { [string]: any } | number | boolean
	local template = (ItemConstants.StoreTemplates :: { [ItemConstants.ItemType]: { [string]: any } | number })[itemType]
	if template then
		if typeof(template) == "table" then
			return TableUtil.deepClone(template)
		else
			return template
		end
	else
		return true
	end
end

function ItemUtil.hasItem(itemType: ItemConstants.ItemType, itemName: string, player: Player?)
	return ItemUtil.getItemStore(itemType, itemName, player) ~= nil
end

function ItemUtil.getEquippedItemsAddress(itemType: ItemConstants.ItemType)
	assert(ItemConstants.Types[itemType] ~= nil, `{itemType} is an invalid item type`)
	return `EquippedItems.{itemType}`
end

function ItemUtil.getEquippedItemAddress(itemType: ItemConstants.ItemType, slot: string)
	return `{ItemUtil.getEquippedItemsAddress(itemType)}.{slot}`
end

function ItemUtil.getEquippedItems(itemType: ItemConstants.ItemType, player: Player?)
	return DataUtil.get(player :: Player, ItemUtil.getEquippedItemsAddress(itemType))
end

function ItemUtil.getEquippedItem(itemType: ItemConstants.ItemType, slot: string, player: Player?)
	return DataUtil.get(player :: Player, `{ItemUtil.getEquippedItemsAddress(itemType)}.{slot}`)
end

function ItemUtil.isItemEquipped(itemType: ItemConstants.ItemType, itemName: string, player: Player?)
	local equipped = ItemUtil.getEquippedItems(itemType, player)
	return table.find(equipped, itemName)
end

function ItemUtil.getProductFromItem(item: ItemConstants.Item): ProductConstants.Product | nil
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
					if reward.Type == "Item" and reward.ItemType == itemType and reward.ItemName == itemName then
						return ProductConstants.Products.Bundle[bundle.Name]
					end
				end
			end
		end
	end

	return nil
end

function ItemUtil.getItemsOfType(itemType: ItemConstants.ItemType)
	return items[itemType]
end

function ItemUtil.getItems()
	return items
end

function ItemUtil.getItem(itemType: ItemConstants.ItemType, itemName: string): ItemConstants.Item?
	return items[itemType][itemName]
end

function ItemUtil.getOwnedItemsOfType(itemType: ItemConstants.ItemType, player: Player?)
	-- ERROR: Invalid item type
	if not ItemConstants.Types[itemType] then
		error(("%s is an invalid item type"):format(itemType))
	end

	return DataUtil.get(player :: Player, "OwnedItems." .. itemType) :: { [string]: boolean }
end

function ItemUtil.getCmdrTypeName(itemType: ItemConstants.ItemType)
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

function ItemUtil.getFriendlyTypeName(itemType: ItemConstants.ItemType)
	return ItemConstants.FriendlyTypeNames[itemType] or itemType
end

function ItemUtil.getItemRarity(itemType: ItemConstants.ItemType, itemName: string): RarityUtil.Rarity?
	local item = ItemUtil.getItem(itemType, itemName)
	if item then
		local source = item.Source

		if source then
			local rarity = RarityUtil.isRarity(source)
			if rarity then
				return rarity
			else
				return RarityConstants.Rarities.Common
			end
		else
			return RarityConstants.Rarities.Epic
		end
	end

	return nil
end

function ItemUtil.getDisplayName(itemType: ItemConstants.ItemType, itemName: string)
	local item = ItemUtil.getItem(itemType, itemName)
	return if item and item.Alias then item.Alias else StringUtil.seperateSnakeCase(itemName)
end

function ItemUtil.getDefaultItem(itemType: ItemConstants.ItemType)
	return defaultItems[itemType]
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for itemType in pairs(ItemConstants.Types) do
	local moduleScript = InstanceUtil.findFirstDescendant(script.Parent, `#{itemType}Items`)
	if not moduleScript then
		if RunService:IsServer() then
			warn(("%s items module not found"):format(itemType))
		end
		continue
	end

	local module = require(moduleScript) :: any
	items[itemType] = module.Items

	local defaultItem = module.DefaultItem :: ItemConstants.Item?
	defaultItems[itemType] = if defaultItem then defaultItem.Name else nil

	for key, item in items[itemType] do
		item.Name = key
		item.Type = itemType

		if TESTING then
			item.Source = CurrencyUtil.freePrice()
		end
	end
end

return ItemUtil
