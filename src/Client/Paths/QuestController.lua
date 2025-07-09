local QuestController = {}

local Players = game:GetService("Players")

local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local DataController = require(Paths.Controllers.DataController)
local QuestUtil = require(Paths.Shared.Quests.QuestUtil)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function QuestController.trackStatProgress(questStat: string, handler)
	task.spawn(handler, QuestUtil.getStat, questStat)

	return DataController.Updated:Connect(function(event: string, _newValue: any, eventMeta: table?)
		if event == "QuestStatChanged" and eventMeta.Stat == questStat then
			handler(QuestUtil.getStat(questStat))
		end
	end)
end

return QuestController
