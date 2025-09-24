--!strict
local BadgeConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)

type _Badge = { Id: number, AwardCriteria: {
	Stat: QuestConstants.Stat,
	Goal: number,
}? }
export type Badge = _Badge & { Name: string }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local badges: { [string]: Badge } = {}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
BadgeConstants.Badges = badges :: { [string]: Badge }

-------------------------------------------------------------------------------
-- COMMENT
-------------------------------------------------------------------------------

for name, badge in badges do
	badge.Name = name
end

return BadgeConstants
