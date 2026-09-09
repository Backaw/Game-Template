--!strict
local CurrencyConstants = {}

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local CURRENCIES: { [string]: string } = {
	Coins = "Coins",
}

local IN_GAME_CURRENCIES: { [Currency]: true } = { ["Coins"] = true }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

CurrencyConstants.Currencies = CURRENCIES :: { [Currency]: Currency }
CurrencyConstants.IngameCurrencies = IN_GAME_CURRENCIES :: { [Currency]: true }

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
	| { Currency: "GamePass" | "DevProduct", PriceInRobux: number, Id: number }
	| { Currency: "Hearts", Amount: number }
	| { Currency: "Coins", Amount: number }

export type _Price = Price | { Currency: "DevProduct", Id: number }

return CurrencyConstants
