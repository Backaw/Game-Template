--!strict
local CurrencyConstants = {}

local CURRENCIES = {
	Cash = "Cash",
	GamePass = "GamePass",
	DevProduct = "DevProduct",
	Free = "Free",
}

local IN_GAME_CURRENCIES: { [Currency]: true } = { ["Cash"] = true }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

CurrencyConstants.Currencies = CURRENCIES :: { [Currency]: Currency }
CurrencyConstants.IngameCurrencies = IN_GAME_CURRENCIES

CurrencyConstants.InfoType = {
	[CurrencyConstants.Currencies.GamePass] = Enum.InfoType.GamePass,
	[CurrencyConstants.Currencies.DevProduct] = Enum.InfoType.Product,
}

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type Currency = keyof<typeof(CURRENCIES)>
export type Price =
	{ Currency: "Free" }
	| { Currency: "Cash", Amount: number }
	| { Currency: "GamePass" | "DevProduct", PriceInRobux: number, Id: number }

return CurrencyConstants
