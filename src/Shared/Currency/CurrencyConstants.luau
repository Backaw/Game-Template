--!strict
local CurrencyConstants = {}

local currencies = {
	Cash = "Cash",
	GamePass = "GamePass",
	DevProduct = "DevProduct",
	Free = "Free",
}

local ingameCurrencies: { Currency } = { currencies.Cash }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

CurrencyConstants.Currencies = currencies :: { [Currency]: Currency }
CurrencyConstants.IngameCurrencies = ingameCurrencies

CurrencyConstants.InfoType = {
	[CurrencyConstants.Currencies.GamePass] = Enum.InfoType.GamePass,
	[CurrencyConstants.Currencies.DevProduct] = Enum.InfoType.Product,
}

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type Currency = keyof<typeof(currencies)>
export type Price =
	{ Currency: "Free" }
	| { Currency: "Cash", Amount: number }
	| { Currency: "GamePass" | "DevProduct", PriceInRobux: number, Id: number }

return CurrencyConstants
