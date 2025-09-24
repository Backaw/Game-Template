--!strict
local WipeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local ADDITIONAL_OFFSET = 0.02
local TWEEN_INFO_IN = TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_INFO_OUT = TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local screen = Players.LocalPlayer.PlayerGui.Transitions
local frame = screen.Wipe

local tween: Tween?

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function WipeTransition.open()
	if tween then
		tween:Cancel()
	end

	frame.Position = UDim2.fromScale(-(1 + ADDITIONAL_OFFSET), 0)
	frame.Visible = true

	tween = TweenService:Create(frame, TWEEN_INFO_IN, { Position = UDim2.fromScale(0, 0) })
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

	tween = TweenService:Create(frame, TWEEN_INFO_OUT, { Position = UDim2.fromScale(2 + ADDITIONAL_OFFSET, 0) })
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
