local CurrencyService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local ProductConstants = require(Shared.Products.ProductConstants)
local GameAnalytics = require(Shared.Packages.GameAnalytics)
local TableUtil = require(Shared.Utils.TableUtil)
local QuestConstants = require(Shared.Quests.QuestConstants)
local PlayerDataService = require(Services.Data.PlayerDataService)
local QuestService, ProductService, GameAnalyticsService

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
CurrencyService.ResourceType = {
	Reward = "Reward",
	-- Product types are added here too
}

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
-- If client initiated then you can assume that the client has already updated on it's end
function CurrencyService.transact(
	player: Player,
	currency: string,
	transacting: number,
	resourceType: string?,
	itemId: string?,
	clientInitiated: boolean?
)
	-- RETURN: Item type doesn't exist
	if resourceType and not CurrencyService.ResourceType[resourceType] then
		error(("%s resource item type doesn't exist"):format(resourceType))
	end

	local address = CurrencyUtil.getAddress(currency)
	if PlayerDataService.get(player, address) + transacting >= 0 then
		if transacting > 0 then
			transacting *= PlayerDataService.get(player, CurrencyUtil.getMultiplierAddress(currency)) or 1
		end

		transacting = math.floor(transacting)

		PlayerDataService.increment(player, address, transacting, "CurrencyChanged", {
			ClientInitiated = clientInitiated,
			Currency = currency,
			Transacting = transacting,
		})

		if resourceType then
			GameAnalyticsService.addEvent("ResourceEvent", player.UserId, {
				flowType = GameAnalytics.EGAResourceFlowType[if transacting > 1 then "Source" else "Sink"],
				currency = currency,
				amount = math.abs(transacting),
				itemType = resourceType,
				itemId = itemId,
			})
		end

		return true, transacting
	end

	return false
end

function CurrencyService.transactCash(
	player: Player,
	transacting: number,
	resourceType: string?,
	itemId: string?,
	clientInitiated: boolean?
)
	local success, transacted =
		CurrencyService.transact(player, CurrencyConstants.Currencies.Cash, transacting, resourceType, itemId, clientInitiated)

	if success and transacted > 0 then
		QuestService.incrementStat(player, QuestConstants.Stats.CashEarned, transacted)
	end
end

function CurrencyService.getResourceTypes()
	return TableUtil.toArray(CurrencyService.ResourceType)
end

function CurrencyService.init()
	ProductService = require(Services.Products.ProductService)
	GameAnalyticsService = require(Services.GameAnalyticsService)
	QuestService = require(Services.QuestService)

	for _, currency in CurrencyConstants.IngameCurrencies do
		-- CONTINUE: Currency isn't purchaseable
		if not ProductConstants.Types[currency] then
			continue
		end

		ProductService.ProductPurchased:Connect(function(player: Player, productType: string, productName: string)
			local amount = tonumber(productName)
			if productType == currency and amount then
				CurrencyService.transact(player, currency, amount, nil, nil, true)
			elseif productType == "Multiplier" and productName == "X2_" .. currency then
				PlayerDataService.increment(player, "Multipliers." .. currency, 1, currency .. "MultiplierChanged")
			end
		end)
	end
end

return CurrencyService
