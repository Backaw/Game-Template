--!strict
local QuestUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataUtil = require(ReplicatedStorage.Shared.Data.DataUtil)
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type Quest = QuestConstants.Quest
export type StatStore = number | { [string]: number }

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

QuestUtil.Stats = QuestConstants.Stats
QuestUtil.Quests = QuestConstants.Quests

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function QuestUtil.getStat(stat: QuestConstants.Stat, player: Player?)
	if not QuestUtil.Stats[stat] then
		error(("Invalid stat: %s"):format(stat))
	end

	return DataUtil.get(player :: Player, ("Quests.Stats.%s"):format(stat)) :: number | { [string]: number }
end

function QuestUtil.isCompleted(quest: QuestConstants.Quest, player: Player?)
	return DataUtil.get(player :: Player, "Quests.Completed." .. quest.Name :: string) ~= nil
end

function QuestUtil.getQuestProgress(quest: QuestConstants.Quest, player: Player?)
	local progress = QuestUtil.getStat(quest.Stat, player)

	local validator = quest.Validator
	if typeof(progress) == "table" then
		if validator then
			return validator(progress)
		else
			return TableUtil.length(progress)
		end
	else
		return progress
	end
end

function QuestUtil.getDescription(quest: QuestConstants.Quest)
	return (quest.Description :: any):format(StringUtil.getCompactNumber(quest.Goal))
end

return QuestUtil
