--!strict
local ItemService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local GameAnalyticsService = require(ServerStorage.Server.GameAnalyticsService)
local PlayersService = require(ServerStorage.Server.PlayersService)
local ProductService = require(ServerStorage.Server.Products.ProductService)
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local Signal = require(ReplicatedStorage.Shared.Signal)
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DATA_EVENTS = ItemConstants.DataEvents

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Validator = (Player) -> boolean

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local freeItems: { ItemConstants.Item } = {}
local gamepassItems: { [number]: { ItemConstants.Item } } = {}
local validators: { [ItemConstants.Item]: Validator } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

ItemService.ItemAcquired = Signal.new("Deferred") :: Signal.Signal<Player, ItemConstants.ItemType, string>
ItemService.ItemEquipped = Signal.new("Deferred") :: Signal.Signal<Player, ItemConstants.ItemType, string, string>
ItemService.ItemUnequipped = Signal.new("Deferred") :: Signal.Signal<Player, ItemConstants.ItemType, string>

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function ItemService.registerValidator(item: ItemConstants.Item, validator: Validator)
	validators[item] = validator
end

function ItemService.giveItem(player: Player, itemType: ItemConstants.ItemType, itemName: string): boolean
	-- RETURN: Item is already owned
	if ItemUtil.hasItem(itemType, itemName, player) then
		return false
	end

	-- RETURN: Item doesn't exist
	local item = ItemUtil.getItem(itemType, itemName)
	if not item then
		return false
	end

	-- RETURN: Cannot award item at this time
	if validators[item] and not validators[item](player) then
		return false
	end

	local address = ItemUtil.getOwnedItemsAddress(itemType)
	PlayerDataService.set(player, address .. "." .. itemName, true, DATA_EVENTS.ItemAcquired, {
		Type = itemType,
		Name = itemName,
	})

	ItemService.ItemAcquired:Fire(player, itemType, itemName)
	GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
		eventId = ("%s:%s:%s"):format("ItemUnlocked", itemType, itemName),
	})

	return true
end

function ItemService.equipItem(player: Player, itemType: ItemConstants.ItemType, itemName: string, slot: string)
	if not ItemUtil.hasItem(itemType, itemName, player) then
		return false
	end

	if slot and assert(tonumber(slot)) > ItemConstants.EquipSlots[itemType] then
		warn(`Cannot equip item of type {itemType} into slot {slot}: Not enough slots`)
		return false
	end

	local address = ItemUtil.getEquippedItemsAddress(itemType)
	PlayerDataService.set(player, `{address}.{slot}`, itemName, DATA_EVENTS.EquippedChanged, {
		Type = itemType,
		Previous = ItemUtil.getEquippedItem(itemType, slot, player),
	})

	ItemService.ItemEquipped:Fire(player, itemType, itemName, slot)
	return true
end

function ItemService.unequipItem(player: Player, itemType: ItemConstants.ItemType, slot: string)
	local equippedCount = TableUtil.length(ItemUtil.getEquippedItems(itemType, player))
	if equippedCount - 1 < ItemConstants.EquippedItemsRequirement[itemType] then
		warn(`Cannot unequip item of type {itemType} from slot {slot}: Not enough equipped items`)
		return false
	end

	if not tonumber(slot) then
		warn(`Cannot unequip item of type {itemType} from slot {slot}: Slot is not a number`)
		return false
	end

	local address = ItemUtil.getEquippedItemAddress(itemType, slot)
	PlayerDataService.set(player, address, nil, DATA_EVENTS.EquippedChanged, {
		Type = itemType,
		Previous = ItemUtil.getEquippedItem(itemType, slot, player),
	})

	ItemService.ItemUnequipped:Fire(player, itemType, slot)
	return true
end

PlayersService.registerLoadHandler(PlayersService.LoadJobs.Items, function(player)
	for _, item in freeItems do
		ItemService.giveItem(player, item.Type, item.Name)
	end

	for gamepass, items in gamepassItems do
		if ProductUtil.hasGamePass(gamepass, player) then
			for _, item in items do
				ItemService.giveItem(player, item.Type, item.Name)
			end
		end
	end
end)

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- EVENT HANDLERS
ProductService.ProductPurchased:Connect(function(player: Player, product: ProductConstants.Product)
	local itemType = ItemConstants.Types[product.Type :: ItemConstants.ItemType]
	if itemType then
		ItemService.giveItem(player, itemType, product.Name :: string)
	end
end)

ItemConstants.Remotes.ItemEquipped:OnServerEvent(ItemService.equipItem :: any)
ItemConstants.Remotes.ItemUnequipped:OnServerEvent(ItemService.unequipItem :: any)

-- FREE ITEMS
for _, items in pairs(ItemUtil.getItems()) do
	for _, item in items do
		local price = CurrencyUtil.isPrice(item.Source)
		if price then
			if price.Currency == "Free" then
				table.insert(freeItems, item)
			elseif price.Currency == "GamePass" then
				local id = price.Id
				local storeInto = gamepassItems[id]
				if not storeInto then
					storeInto = {}
					gamepassItems[id] = storeInto
				end
				table.insert(storeInto, item)
			end
		end
	end
end

return ItemService
