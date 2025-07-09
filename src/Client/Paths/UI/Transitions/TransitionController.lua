local TransitionsController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraController = require(Paths.Controllers.Camera.CameraController)
local Toggle = require(Paths.Shared.Toggle)
local Limiter = require(Paths.Shared.Limiter)

local MAX_TRANSITION_TIME = 8

local isOpen = Toggle.new(false)
local handlers = {}

local currentTransition: string

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
TransitionsController.Transitions = {
	Blink = "Blink",
	BlinkEye = "BlinkEye",
	Wipe = "Wipe",
	Eye = "Eye",
}

-------------------------------------------------------------------------------
-- PUBLC METHODS
-------------------------------------------------------------------------------
-- Yields
function TransitionsController.open(scope: string, transition: string, speedUp: number?)
	-- RETURN: Already opening
	if isOpen:Get() then
		return
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
		return
	end

	if isOpen:Set(scope, false) then
		handlers[currentTransition].close(speedUp)
	end

	return true
end

-- Yields
function TransitionsController.play(scope: string, transition: string, onHalfPoint: (...any) -> nil, speedUp: number?)
	TransitionsController.open(scope, transition, speedUp)

	onHalfPoint()
	CameraController.lookForward()

	-- Tween Out
	TransitionsController.close(scope, speedUp)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for _, transition in pairs(TransitionsController.Transitions) do
	local handler = script.Parent.Handlers:FindFirstChild(transition .. "Transition")
	if not handler then
		warn("Missing transition handler: " .. transition)
		continue
	end

	handlers[transition] = require(handler)
end

do
	local screen = Paths.UI.Transitions
	screen.Enabled = true

	for _, child in screen:GetChildren() do
		if child:IsA("GuiObject") then
			child.Visible = false
		end
	end
end

return TransitionsController
