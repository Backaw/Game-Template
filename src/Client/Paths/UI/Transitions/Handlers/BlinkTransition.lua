local WipeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local screen: ScreenGui = Paths.UI.Transitions
local frame: Frame = screen.Blink

local TWEEN_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

local tween

function WipeTransition.open()
	if tween then
		tween:Cancel()
	end

	frame.Visible = true
	frame.BackgroundTransparency = 1
	tween = TweenService:Create(frame, TWEEN_INFO, { BackgroundTransparency = 0 })
	tween.Completed:Connect(function()
		tween = nil
	end)

	tween:Play()
	tween.Completed:Wait()
end

function WipeTransition.close()
	if tween then
		tween:Cancel()
	end

	tween = TweenService:Create(frame, TWEEN_INFO, { BackgroundTransparency = 1 })
	tween.Completed:Connect(function()
		frame.Visible = false
		tween = nil
	end)

	tween:Play()
	tween.Completed:Wait()
end

screen.Enabled = true
frame.Visible = false

return WipeTransition
