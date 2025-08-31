local CurrencyConstants = {}

export type Currency = "Free" | "Cash" | "GamePass" | "ProductId"

CurrencyConstants.Currencies = {
	Cash = "Cash",
	GamePass = "GamePass",
	DevProduct = "DevProduct",
	Free = "Free",
}

CurrencyConstants.IngameCurrencies = { CurrencyConstants.Currencies.Cash }

CurrencyConstants.InfoType = {
	[CurrencyConstants.Currencies.GamePass] = Enum.InfoType.GamePass,
	[CurrencyConstants.Currencies.DevProduct] = Enum.InfoType.Product,
}

export type Price = {
	Currency: string,
	Amount: number?,
	PriceInRobux: number?,
	Id: number?,
}

return CurrencyConstants
