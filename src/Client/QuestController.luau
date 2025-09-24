--!strict
local QuestController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Client.DataController)
local QuestUtil = require(ReplicatedStorage.Shared.Quests.QuestUtil)
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function QuestController.trackStatProgress(questStat: QuestConstants.Stat, handler)
	task.spawn(handler, QuestUtil.getStat, questStat)

	return DataController.Updated:Connect(function(event, _newValue, eventMeta)
		if event == "QuestStatChanged" and eventMeta.Stat == questStat then
			handler(QuestUtil.getStat(questStat))
		end
	end)
end

return QuestController
