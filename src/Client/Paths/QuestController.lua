local QuestController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(Players.LocalPlayer.PlayerScripts.Paths.DataController)
local QuestUtil = require(ReplicatedStorage.Modules.Quests.QuestUtil)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function QuestController.trackStatProgress(questStat: string, handler)
	task.spawn(handler, QuestUtil.getStat, questStat)

	return DataController.Updated:Connect(function(event: string, _newValue, eventMeta)
		if event == "QuestStatChanged" and eventMeta.Stat == questStat then
			handler(QuestUtil.getStat(questStat))
		end
	end)
end

return QuestController
