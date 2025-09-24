local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
	return TableUtil.toArray(ItemConstants.Types)
end

local function stringToObject(itemType: string)
	return itemType
end

return function(registry)
	registry:RegisterType("itemType", CmdrUtil.createTypeDefinition("itemType", stringsGetter, stringToObject))
end
