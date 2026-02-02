--!strict
local WipeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local ADDITIONAL_OFFSET = 0.02
local DEFAULT_LENGTH = 0.75

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local screen = Players.LocalPlayer.PlayerGui.Transitions
local frame = screen.Wipe

local tween: Tween?

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function WipeTransition.open(length: number?)
	if tween then
		tween:Cancel()
	end

	frame.Position = UDim2.fromScale(-(1 + ADDITIONAL_OFFSET), 0)
	frame.Visible = true

	tween = TweenService:Create(
		frame,
		TweenInfo.new(length or DEFAULT_LENGTH, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0, 0) }
	)
	if tween then
		tween.Completed:Connect(function()
			tween = nil
		end)

		tween:Play()
		tween.Completed:Wait()
	end
end

function WipeTransition.close(length: number?)
	if tween then
		tween:Cancel()
	end

	tween = TweenService:Create(
		frame,
		TweenInfo.new(length or DEFAULT_LENGTH, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(2 + ADDITIONAL_OFFSET, 0) }
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

return WipeTransition
