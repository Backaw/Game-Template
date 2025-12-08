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

ItemService.ItemAcquired = Signal.new("Deferred") :: Signal.Signal<Player, string, string>
ItemService.ItemEquipped = Signal.new("Deferred") :: Signal.Signal<Player, string, string>
ItemService.ItemUnequipped = Signal.new("Deferred") :: Signal.Signal<Player, string>

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function ItemService.registerValidator(item: ItemConstants.Item, validator: Validator)
	validators[item] = validator
end

function ItemService.giveItem(player: Player, itemType: ItemConstants.ItemType, itemName: string, loaned: boolean?)
	-- RETURN: Item is already owned
	if ItemUtil.hasItem(itemType, itemName, player) then
		return
	end

	-- RETURN: Item doesn't exist
	local item = ItemUtil.getItem(itemType, itemName)
	if not item then
		return
	end

	-- RETURN: Cannot award item at this time
	if validators[item] and not validators[item](player) then
		return
	end

	local address = ItemUtil.getOwnedItemsAddressFromType(itemType)
	PlayerDataService.set(player, address .. "." .. itemName, loaned or false, "ItemAcquired", {
		Type = itemType,
		Name = itemName,
	})

	ItemService.ItemAcquired:Fire(player, itemType, itemName)
	if not loaned then
		GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
			eventId = ("%s:%s:%s"):format("ItemUnlocked", itemType, itemName),
		})
	end
end

function ItemService.equipItem(player: Player, itemType: ItemConstants.ItemType, itemName: string)
	if not ItemUtil.hasItem(itemType, itemName, player) then
		return false
	end

	local address = ItemUtil.getEquippedItemAddressFromType(itemType)
	PlayerDataService.set(player, address, itemName, "EquippedItemChanged", {
		Type = itemType,
		Previous = ItemUtil.getEquippedItem(itemType, player),
	})

	ItemService.ItemEquipped:Fire(player, itemType, itemName)
	return true
end

function ItemService.unequipItem(player: Player, itemType: ItemConstants.ItemType)
	-- Cannot unequip to nil
	if ItemUtil.getDefaultItem(itemType) then
		return false
	end

	local address = ItemUtil.getEquippedItemAddressFromType(itemType)
	PlayerDataService.set(player, address, nil, "EquippedItemChanged", {
		Type = itemType,
		Previous = ItemUtil.getEquippedItem(itemType, player),
	})

	ItemService.ItemUnequipped:Fire(player, itemType)
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

-- LOADNED ITEMS
PlayerDataService.registerReconciler(function(data)
	for _, items in data.OwnedItems do
		for itemName, loaned in items do
			if loaned then
				items[itemName] = nil
			end
		end
	end
end)

return ItemService
