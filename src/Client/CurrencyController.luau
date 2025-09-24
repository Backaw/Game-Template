--!strict
local CurrencyController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Client.DataController)
local CurrencyUtil = require(ReplicatedStorage.Shared.Currency.CurrencyUtil)
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local Signal = require(ReplicatedStorage.Shared.Signal)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local cache: { [string]: number } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
CurrencyController.Changed = Signal.new() :: Signal.Signal<CurrencyConstants.Currency, number, number>

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CurrencyController.get(currency: string)
	return cache[currency]
end

function CurrencyController.transact(currency: CurrencyConstants.Currency, transacting: number, serverInitiated: boolean?)
	if transacting > 0 and not serverInitiated then
		transacting *= DataController.get(CurrencyUtil.getMultiplierAddress(currency)) :: number or 1
	end

	local nextValue = cache[currency] + math.floor(transacting)
	if nextValue >= 0 then
		local previousValue = cache[currency]
		cache[currency] = nextValue
		CurrencyController.Changed:Fire(currency, nextValue, previousValue)

		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for _, currency in CurrencyConstants.IngameCurrencies do
	cache[currency] = DataController.get(CurrencyUtil.getAddress(currency)) :: number
end

DataController.Updated:Connect(function(event, _, metadata)
	if event == "CurrencyChanged" and not metadata.ClientInitiated then
		CurrencyController.transact(metadata.Currency, metadata.Transacting, true)
	end
end)

return CurrencyController
