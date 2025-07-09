local CurrencyController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local DataController = require(Paths.Controllers.DataController)
local CurrencyUtil = require(Paths.Shared.Currency.CurrencyUtil)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local cache: { [string]: number } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
CurrencyController.Changed = Signal.new() -- (currency : string, newValue : number, oldValue : number)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CurrencyController.get(currency: string)
	return cache[currency]
end

function CurrencyController.transact(currency: string, transacting: number, serverInitiated: boolean?)
	if transacting > 0 and not serverInitiated then
		transacting *= DataController.get(CurrencyUtil.getMultiplierAddress(currency)) or 1
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
	cache[currency] = DataController.get(CurrencyUtil.getAddress(currency))
end

DataController.Updated:Connect(function(event, _, metadata)
	if event == "CurrencyChanged" and not metadata.ClientInitiated then
		CurrencyController.transact(metadata.Currency, metadata.Transacting, true)
	end
end)

return CurrencyController
