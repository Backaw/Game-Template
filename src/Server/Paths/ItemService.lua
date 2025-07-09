local ItemService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Signal = require(Paths.Shared.Signal)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local ItemUtil = require(Paths.Shared.Items.ItemUtil)
local ItemConstants = require(Paths.Shared.Items.ItemConstants)
local ProductConstants = require(Paths.Shared.Products.ProductConstants)
local ProductService = require(Paths.Services.Products.ProductService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PlayersService = require(Paths.Services.PlayersService)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)
local GameAnalyticsService = require(Paths.Services.GameAnalyticsService)
local QuestService: typeof(require(Paths.Services.QuestService))
local ProductUtil = require(Paths.Shared.Products.ProductUtil)

type Validator = (Player) -> boolean

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local freeItems: { ItemConstants.Item } = {}
local questItems: { ItemConstants.Item } = {}
local gamepassItems: { [number]: { ItemConstants.Item } } = {}
local validators: { [table]: Validator } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
ItemService.ItemAcquired = Signal.new() -- (player : Player, itemType : String, itemName : string)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function ItemService.registerValidator(item: table, validator: Validator)
	validators[item] = validator
end

function ItemService.hasItem(player: Player, itemType: string, itemName: string)
	return PlayerDataService.get(player, ItemUtil.getOwnedItemsAddressFromType(itemType))[itemName] ~= nil
end

function ItemService.getOwnedItems(player: Player, itemType: string)
	return TableUtil.getKeys(PlayerDataService.get(player, ItemUtil.getOwnedItemsAddressFromType(itemType)))
end

function ItemService.giveItem(player: Player, itemType: string, itemName: string, loaned: boolean?)
	-- RETURN: Item is already owned
	if ItemService.hasItem(player, itemType, itemName) then
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

ItemService.loadPlayer = PlayersService.promisifyLoader(function(player)
	for _, item in freeItems do
		ItemService.giveItem(player, item.Type, item.Name)
	end

	for _, item in questItems do
		if QuestService.isCompleted(player, item.Source.Name) then
			ItemService.giveItem(player, item.Type, item.Name)
		end
	end

	for gamepass, items in gamepassItems do
		if ProductUtil.hasGamePass(gamepass, player) then
			for _, item in items do
				ItemService.giveItem(player, item.Type, item.Name)
			end
		end
	end
end, "Items")

function ItemService.init()
	QuestService = require(Paths.Services.QuestService)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- EVENT HANDLERS
ProductService.ProductPurchased:Connect(function(player: Player, product: ProductConstants.Product)
	local itemType = product.Type
	if ItemConstants.Types[itemType] then
		ItemService.giveItem(player, itemType, product.Name)
	end
end)

-- FREE ITEMS
for _, items in (ItemUtil.getItems()) do
	for _, item in items do
		local source = item.Source
		if source then
			if source.Currency == CurrencyConstants.Currencies.Free then
				table.insert(freeItems, item)
			elseif source.Goal then
				table.insert(questItems, item)
			elseif source.Currency == CurrencyConstants.Currencies.GamePass then
				local id = source.Id
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
