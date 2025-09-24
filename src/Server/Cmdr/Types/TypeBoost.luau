local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BoostConstants = require(ReplicatedStorage.Shared.Constants.BoostConstants)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
	return TableUtil.getKeys(BoostConstants.Boosts)
end

local function stringToObject(itemType: string)
	return itemType
end

return function(registry)
	registry:RegisterType("boost", CmdrUtil.createTypeDefinition("boost", stringsGetter, stringToObject))
end
