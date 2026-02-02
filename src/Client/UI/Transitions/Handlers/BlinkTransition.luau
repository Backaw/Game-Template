--!strict
local BlinkTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_LENGTH = 0.75

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local screen = Players.LocalPlayer.PlayerGui.Transitions
local frame = screen.Blink

local tween: Tween?

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function BlinkTransition.open(length: number?)
	if tween then
		tween:Cancel()
	end

	frame.Visible = true
	frame.BackgroundTransparency = 1
	tween = TweenService:Create(
		frame,
		TweenInfo.new(length or DEFAULT_LENGTH, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 0 }
	)
	if tween then
		tween.Completed:Connect(function()
			tween = nil
		end)

		tween:Play()
		tween.Completed:Wait()
	end
end

function BlinkTransition.close(length: number?)
	if tween then
		tween:Cancel()
	end

	tween = TweenService:Create(
		frame,
		TweenInfo.new(length or DEFAULT_LENGTH, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
		{ BackgroundTransparency = 1 }
	)
	if tween then
		tween.Completed:Connect(function()
			frame.Visible = false
			tween = nil
		end)

		tween:Play()
		tween.Completed:Wait()
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

screen.Enabled = true
frame.Visible = false

return BlinkTransition
