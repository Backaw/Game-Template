--!strict
local CurrencyUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)

function CurrencyUtil.getAddress(currency: CurrencyConstants.Currency)
	-- ERROR: Invallid currency
	if not CurrencyConstants.Currencies[currency] then
		error(("%s is an invalid valid currency"):format(currency))
	end

	return "Currencies." .. currency
end

function CurrencyUtil.isInGameCurrency(currency: string)
	return table.find(CurrencyConstants.IngameCurrencies, currency) ~= nil
end

function CurrencyUtil.getMultiplierAddress(currency: CurrencyConstants.Currency)
	-- ERROR: Invallid currency
	if not CurrencyConstants.Currencies[currency] then
		error(("%s is an invalid valid currency"):format(currency))
	end

	return "Multipliers." .. currency
end

function CurrencyUtil.isPrice(price: any): CurrencyConstants.Price?
	if typeof(price) == "table" and price.Currency then
		return price :: CurrencyConstants.Price
	end

	return nil
end

function CurrencyUtil.cashPrice(amount: number): CurrencyConstants.Price
	return {
		Currency = "Cash",
		Amount = amount,
	}
end

function CurrencyUtil.gamepassPrice(priceInRobux: number, id: number)
	return {
		Currency = "GamePass",
		PriceInRobux = priceInRobux,
		Id = id,
	}
end

function CurrencyUtil.devProductPrice(priceInRobux: number, id: number): CurrencyConstants.Price
	return {
		Currency = "DevProduct",
		PriceInRobux = priceInRobux,
		Id = id,
	}
end

function CurrencyUtil.freePrice(): CurrencyConstants.Price
	return {
		Currency = "Free",
	}
end

return CurrencyUtil
