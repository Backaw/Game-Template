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

local screen = Players.LocalPlayer.PlayerGui.Transitions
local eye = screen.BlinkEye
local allFrames: { GuiObject } = {}
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
	for _, frame in allFrames do
		local transparencyProp = if frame:IsA("ImageLabel") then "ImageTransparency" else "BackgroundTransparency"
		(frame :: any)[transparencyProp] = start

		local tween = TweenService:Create(
			frame,
			TweenInfo.new(length, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ [transparencyProp] = finish }
		)

		local i = #tweens + 1
		table.insert(tweens, tween)

		tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				tweens[i] = nil
			end
		end)

		tween:Play()
	end
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

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
	for _, frame in ipairs(eye:GetChildren()) do
		if frame:IsA("GuiObject") then
			table.insert(allFrames, frame)
		end
	end
	table.insert(allFrames, eye)
end

return BlinkEyeTransition
