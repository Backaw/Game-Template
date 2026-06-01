local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
	return TableUtil.getKeys(CurrencyConstants.IngameCurrencies)
end

local function stringToObject(currency: string)
	return currency
end

return function(registry)
	registry:RegisterType("currency", CmdrUtil.createTypeDefinition("currency", stringsGetter, stringToObject))
end
