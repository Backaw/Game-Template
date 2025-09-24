local Images = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)

local currencies: { [CurrencyConstants.Currency]: string } = {
	Cash = "rbxassetid://13591829134",
	Robux = "rbxassetid://12235965856",
}

Images.Currencies = currencies

return Images
