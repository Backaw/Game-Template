local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)

local function stringsGetter()
	return CurrencyConstants.IngameCurrencies
end

local function stringToObject(itemType: string)
	return itemType
end

return function(registry)
	registry:RegisterType("currency", CmdrUtil.createTypeDefinition("currency", stringsGetter, stringToObject))
end
