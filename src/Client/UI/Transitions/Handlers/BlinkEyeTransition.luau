--!strict
local BlinkEyeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local OPENING_LENGTH = 0.6
local CLOSING_LENGTH = OPENING_LENGTH * 0.75

local CLOSE_SIZE = UDim2.fromScale(2, 2)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local screen = Players.LocalPlayer.PlayerGui.Transitions
local eye = screen.BlinkEye
local tweens: { Tween } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function cancelTweens()
	for _, tween in tweens do
		tween:Cancel()
	end
	tweens = {}
end

local function eyeTweenInfo(length: number)
	return TweenInfo.new(length, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
end

local function fadeFrames(length: number, start: number, finish: number)
	local tweenInfo = TweenInfo.new(length, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	eye.UIStroke.Transparency = start
	eye.ImageTransparency = start

	local tween1 = TweenService:Create(eye, tweenInfo, { ImageTransparency = finish })
	local tween2 = TweenService:Create(eye.UIStroke, tweenInfo, { Transparency = finish })
	table.insert(tweens, tween1)
	table.insert(tweens, tween2)
	tween1:Play()
	tween2:Play()
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function BlinkEyeTransition.open(speedUp: number?)
	speedUp = speedUp or 1

	cancelTweens()

	-- Fade
	fadeFrames(OPENING_LENGTH * speedUp, 1, 0)

	-- Eye
	eye.Size = CLOSE_SIZE
	eye.Visible = true

	local sizeTween = TweenService:Create(eye, eyeTweenInfo(OPENING_LENGTH * speedUp), { Size = UDim2.fromScale(0, 0) })
	sizeTween:Play()

	sizeTween.Completed:Wait()
end

function BlinkEyeTransition.close(speedUp: number?)
	speedUp = speedUp or 1

	cancelTweens()

	fadeFrames(CLOSING_LENGTH * speedUp, 0, 1)

	local sizeTween = TweenService:Create(eye, eyeTweenInfo(CLOSING_LENGTH * speedUp), { Size = CLOSE_SIZE })
	sizeTween.Completed:Connect(function()
		eye.Visible = false
	end)
	sizeTween:Play()
	sizeTween.Completed:Wait()
end

return BlinkEyeTransition
