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

function CurrencyUtil.isInGameCurrency(currency: any): CurrencyConstants.Currency?
	if CurrencyConstants.IngameCurrencies[currency] :: any then
		return currency :: CurrencyConstants.Currency
	else
		return nil
	end
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

function CurrencyUtil.coinPrice(amount: number): CurrencyConstants.Price
	return {
		Currency = "Coins",
		Amount = amount,
	}
end

function CurrencyUtil.gamepassPrice(id: number): CurrencyConstants.Price
	return {
		Currency = "GamePass",
		PriceInRobux = -1,
		Id = id,
	}
end

function CurrencyUtil.devProductPrice(id: number): CurrencyConstants.Price
	return {
		Currency = "DevProduct",
		PriceInRobux = -1,
		Id = id,
	}
end

function CurrencyUtil.freePrice(): CurrencyConstants.Price
	return {
		Currency = "Free",
	}
end

return CurrencyUtil
