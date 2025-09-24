local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProductUtil = require(ReplicatedStorage.Shared.Products.ProductUtil)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
	return TableUtil.getKeys(ProductUtil.getCmdrGamepasses())
end

local function stringToObject(itemType: string)
	return itemType
end

return function(registry)
	registry:RegisterType("gamepass", CmdrUtil.createTypeDefinition("gamepass", stringsGetter, stringToObject))
end
