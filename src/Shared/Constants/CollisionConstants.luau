local CollisionConstants = {}

local GROUPS = {
	Default = "Default",
	Character = "Character",
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CollisionConstants.Groups = GROUPS :: { [Group]: Group }

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type Group = keyof<typeof(GROUPS)>
export type Groups = { Group }

return CollisionConstants
