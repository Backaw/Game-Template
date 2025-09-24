--!strict
local RarityConstants = {}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local rarities = {
	Common = "Common",
	Rare = "Rare",
	Epic = "Epic",
	Legendary = "Legendary",
}

local probabilities: { [Rarity]: number } = {
	[rarities.Common] = 42,
	[rarities.Rare] = 38,
	[rarities.Epic] = 17,
	[rarities.Legendary] = 13,
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

RarityConstants.Rarities = rarities :: { [string]: Rarity }
RarityConstants.Probabilities = probabilities

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

export type Rarity = keyof<typeof(rarities)>

return RarityConstants
