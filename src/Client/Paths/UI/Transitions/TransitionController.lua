local Transitions = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CameraController = require(Paths.Controllers.CameraController)
local Toggle = require(Paths.Shared.Toggle)
local Limiter = require(Paths.Shared.Limiter)

local isOpen = Toggle.new(false)
local handlers = {}

local currentTransition: string

local MAX_TRANSITION_TIME = 8

-------------------------------------------------------------------------------
-- PUBLC METHODS
-------------------------------------------------------------------------------
-- Yields
function Transitions.open(scope: string, transition: string)
	-- RETURN: Already opening
	if isOpen:Get() then
		return
	end

	if isOpen:Set(scope, true) then
		currentTransition = transition
		handlers[currentTransition].open()

		Limiter.indecisive("Transitions", scope, MAX_TRANSITION_TIME, function()
			Transitions.close(scope)
		end)
	end

	return true
end

-- Yields
function Transitions.close(scope: string)
	-- RETURN: Blink is already closed
	if not isOpen:Get() then
		return
	end

	if isOpen:Set(scope, false) then
		handlers[currentTransition].close()
	end

	return true
end

-- Yields
function Transitions.play(scope: string, transition: string, onHalfPoint: (...any) -> nil)
	Transitions.open(scope, transition)

	onHalfPoint()
	CameraController.lookForward()

	-- Tween Out
	Transitions.close(scope)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for _, handler in  (script.Parent:GetChildren()) do
	if handler == script then
		continue
	end

	handlers[handler.Name:gsub("Transition", "")] = require(handler)
end

return Transitions
