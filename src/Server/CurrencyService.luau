--!strict
local CurrencyService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local ProductConstants = require(ReplicatedStorage.Shared.Products.ProductConstants)
local GameAnalytics = require(ReplicatedStorage.Shared.Packages.GameAnalytics)
local GameAnalyticsService = require(ServerStorage.Server.GameAnalyticsService)
local QuestService = require(ServerStorage.Server.QuestService)

local ProductService

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

-- If client initiated then you can assume that the client has already updated on it's end
function CurrencyService.transact(
	player: Player,
	currency: CurrencyConstants.Currency,
	transacting: number,
	resourceType: GameAnalyticsService.ResourceType?,
	itemId: string?,
	clientInitiated: boolean?
)
	-- RETURN: Item type doesn't exist
	if resourceType and not GameAnalyticsService.isResourceType(resourceType) then
		error(("%s resource item type doesn't exist"):format(resourceType))
	end

	local address = CurrencyUtil.getAddress(currency)
	if PlayerDataService.get(player, address) :: number + transacting >= 0 then
		if transacting > 0 then
			transacting *= PlayerDataService.get(player, CurrencyUtil.getMultiplierAddress(currency)) :: number? or 1
		end

		transacting = math.floor(transacting)

		PlayerDataService.increment(player, address, transacting, "CurrencyChanged", {
			ClientInitiated = clientInitiated,
			Currency = currency,
			Transacting = transacting,
		})

		if resourceType then
			GameAnalyticsService.addEvent("ResourceEvent", player.UserId, {
				flowType = if transacting > 0 then GameAnalytics.EGAResourceFlowType.Source else GameAnalytics.EGAResourceFlowType.Sink,
				currency = currency,
				amount = math.abs(transacting),
				itemType = resourceType,
				itemId = itemId,
			})
		end

		return true, transacting
	end

	return false, 0
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
		QuestService.incrementStat(player, "CashEarned", transacted)
	end
end

function CurrencyService.init()
	ProductService = require(ServerStorage.Server.Products.ProductService) :: any

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
