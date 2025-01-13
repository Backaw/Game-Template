local CurrencyUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Modules.Currency.CurrencyConstants)

function CurrencyUtil.getAddress(currency: string)
	-- ERROR: Invallid currency
	if not CurrencyConstants.Currencies[currency] then
		error(("%s is an invalid valid currency"):format(currency))
	end

	return "Currencies." .. currency
end

function CurrencyUtil.isInGameCurrency(currency: string)
	return table.find(CurrencyConstants.IngameCurrencies, currency) ~= nil
end

function CurrencyUtil.getMultiplierAddress(currency: string)
	-- ERROR: Invallid currency
	if not CurrencyConstants.Currencies[currency] then
		error(("%s is an invalid valid currency"):format(currency))
	end

	return "Multipliers." .. currency
end

return CurrencyUtil
