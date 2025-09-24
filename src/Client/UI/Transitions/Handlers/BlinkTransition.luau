--!strict
local WipeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local screen = Players.LocalPlayer.PlayerGui.Transitions
local frame = screen.Blink

local tween: Tween?

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function WipeTransition.open()
	if tween then
		tween:Cancel()
	end

	frame.Visible = true
	frame.BackgroundTransparency = 1
	tween = TweenService:Create(frame, TWEEN_INFO, { BackgroundTransparency = 0 })
	if tween then
		tween.Completed:Connect(function()
			tween = nil
		end)

		tween:Play()
		tween.Completed:Wait()
	end
end

function WipeTransition.close()
	if tween then
		tween:Cancel()
	end

	tween = TweenService:Create(frame, TWEEN_INFO, { BackgroundTransparency = 1 })
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

return WipeTransition
