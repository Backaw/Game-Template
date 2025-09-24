local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)
local CmdrUtil = require(ReplicatedStorage.Shared.Utils.CmdrUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local function stringsGetter()
	return TableUtil.getKeys(QuestConstants.DefaultStats)
end

local function stringToObject(itemType: string)
	return itemType
end

return function(registry)
	registry:RegisterType("questStat", CmdrUtil.createTypeDefinition("questStat", stringsGetter, stringToObject))
end
