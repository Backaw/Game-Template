local BadgeConstants = {}

export type Badge = {
	Name: string?,
	Id: number,
	AwardCriteria: {
		Stat: string,
		Goal: number,
	}?,
}

local badges: { [string]: Badge } = {}

BadgeConstants.Badges = badges

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for name, badge in  (badges) do
	badge.Name = name
end

return BadgeConstants
