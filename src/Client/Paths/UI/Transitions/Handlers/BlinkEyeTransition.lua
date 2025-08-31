local BlinkEyeTransition = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local OPENING_LENGTH = 0.6
local CLOSING_LENGTH = OPENING_LENGTH * 0.75

local CLOSE_SIZE = UDim2.fromScale(2, 2)

local screen: ScreenGui = Players.LocalPlayer.PlayerGui.Transitions
local eye: ImageLabel = screen.BlinkEye
local allFrames: { GuiObject }

local tweens: { Tween }?

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------
local function cancelTweens()
	if tweens then
		for _, tween in tweens do
			tween:Cancel()
		end
	end

	tweens = {}
end

local function eyeTweenInfo(length: number)
	return TweenInfo.new(length, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut)
end

local function fadeFrames(length: number, start: number, finish: number)
	for _, frame in allFrames do
		local transparencyProp = if frame:IsA("ImageLabel") then "ImageTransparency" else "BackgroundTransparency"
		frame[transparencyProp] = start

		local tween = TweenService:Create(
			frame,
			TweenInfo.new(length, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
			{ [transparencyProp] = finish }
		)
		tween:Play()
		table.insert(tweens, tween)
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
	sizeTween.Completed:Connect(function()
		tweens = nil
	end)
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
		tweens = nil
	end)
	sizeTween:Play()
	sizeTween.Completed:Wait()
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
	allFrames = eye:GetChildren() :: { GuiObject }
	table.insert(allFrames, eye)
end

return BlinkEyeTransition
