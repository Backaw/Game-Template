local QuestUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConstants = require(ReplicatedStorage.Modules.Quests.QuestConstants)
local StringUtil = require(ReplicatedStorage.Modules.Utils.StringUtil)
local DataUtil = require(ReplicatedStorage.Modules.Data.DataUtil)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
QuestUtil.Stats = QuestConstants.Stats
QuestUtil.Quests = QuestConstants.Quests

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function QuestUtil.getStat(stat: string, player: Player?)
	if not QuestUtil.Stats[stat] then
		error(("Invalid stat: %s"):format(stat))
	end

	return DataUtil.get(player, ("Quests.Stats.%s"):format(stat))
end

function QuestUtil.isCompleted(quest: QuestConstants.Quest, player: Player?)
	return DataUtil.get(player, "Quests.Completed." .. quest.Name) ~= nil
end

function QuestUtil.getQuestProgress(quest: QuestConstants.Quest, player: Player?)
	local progress = QuestUtil.getStat(quest.Stat, player)

	local validator = quest.Validator
	if validator then
		return validator(progress)
	elseif typeof(progress) == "table" then
		return TableUtil.length(progress)
	else
		return progress
	end
end

function QuestUtil.getDescription(quest: QuestConstants.Quest)
	return quest.Description:format(StringUtil.getCompactNumber(quest.Goal))
end

return QuestUtil
