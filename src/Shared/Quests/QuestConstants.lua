-- All values are stored in .Stats part of a player's data

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConstants = {}
local RewardConstants = require(ReplicatedStorage.Modules.Rewards.RewardConstants)

export type Quest = {
	Name: string?,
	Stat: string?,
	Validator: ((table) -> number) | nil,
	Goal: number,
	Description: string?,
	Reward: RewardConstants.Reward | nil,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local quests: { [string]: Quest } = {}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
QuestConstants.Stats = {
	CashEarned = "CashEarned",
	MinutesPlayed = "MinutesPlayed",
}

QuestConstants.DefaultStats = {
	[QuestConstants.Stats.CashEarned] = 0,
	[QuestConstants.Stats.MinutesPlayed] = 0,
}

QuestConstants.Templates = {
	CashEarned = {
		Description = "Earn %s coins",
		Stat = QuestConstants.Stats.Wins,
	},
	MinutesPlayed = {
		Description = "Play for %s mins",
		Stat = QuestConstants.Stats.MinutesPlayed,
	},
}

QuestConstants.Quests = quests

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
	for questName, constants in quests do
		constants.Name = questName

		local template = QuestConstants.Templates[questName:gsub("%d", "")]
		if template then
			-- constants.Description = constants.Description or template.Description
			constants.Stat = template.Stat
		end
	end

	for _, stat in QuestConstants.Stats do
		if not QuestConstants.DefaultStats[stat] then
			QuestConstants.DefaultStats[stat] = 0
		end
	end
end

return QuestConstants
