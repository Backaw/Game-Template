-- All values are stored in .Stats part of a player's data
local QuestConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local quests: { [string]: _Quest } = {}

local stats = {
	CashEarned = "CashEarned",
	MinutesPlayed = "MinutesPlayed",
	InvitedFriends = "InvitedFriends",
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

QuestConstants.Stats = stats :: { [Stat]: Stat }

QuestConstants.DefaultStats = {
	[QuestConstants.Stats.CashEarned] = 0,
	[QuestConstants.Stats.MinutesPlayed] = 0,
} :: { [Stat]: number }

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

QuestConstants.Quests = quests :: { [string]: Quest }

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for questName, constants in QuestConstants.Quests do
	constants.Name = questName

	local template = QuestConstants.Templates[questName:gsub("%d", "")]
	if template then
		constants.Description = constants.Description or template.Description
		constants.Stat = template.Stat
	end
end

for _, stat in QuestConstants.Stats do
	if not QuestConstants.DefaultStats[stat] then
		QuestConstants.DefaultStats[stat] = 0
	end
end

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type _Quest = {
	Validator: (({ [string]: number }) -> number) | nil,
	Goal: number,
	Reward: RewardConstants.Reward | nil,
}
export type Quest = _Quest & {
	Name: string,
	Stat: Stat,
	Description: string,
}

export type Stat = keyof<typeof(stats)>

return QuestConstants
