--!strict
local TransitionsController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Toggle = require(ReplicatedStorage.Shared.Toggle)
local Limiter = require(ReplicatedStorage.Shared.Limiter)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local TRANSITIONS = {
	Blink = "Blink",
	BlinkEye = "BlinkEye",
	Wipe = "Wipe",
	Eye = "Eye",
}
local MAX_TRANSITION_TIME = 8

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Transition = keyof<typeof(TRANSITIONS)>

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local handlers: { [Transition]: {
	open: (number?) -> (),
	close: (number?) -> (),
} } = {}

local isOpen = Toggle.new(false)
local currentTransition: Transition

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

TransitionsController.Transitions = TRANSITIONS :: { [Transition]: Transition }

-------------------------------------------------------------------------------
-- PUBLC METHODS
-------------------------------------------------------------------------------

-- Yields
function TransitionsController.open(scope: string, transition: Transition, speedUp: number?)
	-- RETURN: Already opening
	if isOpen:Get() then
		return false
	end

	if isOpen:Set(scope, true) then
		currentTransition = transition
		handlers[currentTransition].open(speedUp)

		Limiter.indecisive("TransitionsController", scope, MAX_TRANSITION_TIME, function()
			TransitionsController.close(scope, speedUp)
		end)
	end

	return true
end

-- Yields
function TransitionsController.close(scope: string, speedUp: number?)
	-- RETURN: Blink is already closed
	if not isOpen:Get() then
		return false
	end

	if isOpen:Set(scope, false) then
		handlers[currentTransition].close(speedUp)
	end

	return true
end

-- Yields
function TransitionsController.play(scope: string, transition: Transition, onHalfPoint: () -> (), speedUp: number?)
	TransitionsController.open(scope, transition, speedUp)

	onHalfPoint()

	-- Tween Out
	TransitionsController.close(scope, speedUp)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for transition in pairs(TransitionsController.Transitions) do
	local handler = script.Parent.Handlers:FindFirstChild(transition :: string .. "Transition")
	if not handler then
		warn("Missing transition handler: " .. transition :: string)
		continue
	end

	handlers[transition] = require(handler) :: any
end

do
	local screen = Players.LocalPlayer.PlayerGui.Transitions
	screen.Enabled = true

	for _, child in screen:GetChildren() do
		if child:IsA("GuiObject") then
			child.Visible = false
		end
	end
end

return TransitionsController
