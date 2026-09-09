--!strict
local UIConstants = {}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local states = {
	HUD = "HUD",
}

local hudPermissiveStates: { State } = { "HUD" }
local psuedoStates: { [State]: { State } } = {}
local interactionPermissiveStates: { State } = {
	"HUD",
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

UIConstants.InterfacesName = "__INTERFACES"
UIConstants.InitialState = "Nothing"
UIConstants.States = states :: { [State]: State }
UIConstants.HUDPermissiveStates = hudPermissiveStates
UIConstants.PsuedoStates = psuedoStates
UIConstants.InteractionPermissiveStates = interactionPermissiveStates

-------------------------------------------------------------------------------
-- EXPORT TYPES
-------------------------------------------------------------------------------

export type State = keyof<typeof(states)>

return UIConstants
