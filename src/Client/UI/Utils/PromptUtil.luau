--!strict
local PromptUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local Client = ReplicatedStorage.Client
local Shared = ReplicatedStorage.Shared
local UDimUtil = require(Shared.Utils.UDimUtil)
local Toggle = require(Shared.Toggle)
local Binder = require(Shared.Binder)
local CameraController = require(Client.CameraController)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local ANIMATION_LENGTH = 0.2
local PROMPT_ANIMATION_LENGTH = ANIMATION_LENGTH / 2

local OPEN_BLUR_SIZE = 0
local OPEN_FOV_MULTI = 1 -- 0.9
local DEFAULT_BACKGROUND_TRANSPARENCY = 0.95

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local blurEffect = Instance.new("BlurEffect")
blurEffect.Size = 0
blurEffect.Enabled = true
blurEffect.Parent = Lighting

local backgroundScreen = Players.LocalPlayer.PlayerGui.Background
local backgroundFrame = backgroundScreen.Frame

local cosmeticsEnabled = Toggle.new(false)

local camera = Workspace.CurrentCamera

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local getInitialSize = function(prompt: GuiObject)
	return Binder.bindFirst(prompt, "InitialSize", prompt.Size)
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

PromptUtil.Direction = {
	Up = UDim2.fromScale(0, 1),
	Down = UDim2.fromScale(0, -1),
	Left = UDim2.fromScale(1, 0),
	Right = UDim2.fromScale(-1, 0),
}

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function PromptUtil.openBackground(frame: Frame?)
	frame = frame or backgroundFrame

	local initialTransparency = Binder.bindFirst(frame, "InitialTransparency", frame.BackgroundTransparency)
	frame.BackgroundTransparency = 1
	frame.Visible = true

	local screen = frame.Parent
	if not screen then
		error("Background screen not found")
	end
	if screen:IsA("ScreenGui") then
		screen.Enabled = true
	end

	local tween = TweenService:Create(
		frame,
		TweenInfo.new(PROMPT_ANIMATION_LENGTH, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ BackgroundTransparency = initialTransparency }
	)
	tween:Play()

	return tween
end

function PromptUtil.open(prompt: GuiObject, cosmetics: boolean?)
	if cosmetics then
		cosmeticsEnabled:Set(prompt, true)
	end

	prompt.Visible = true
end

function PromptUtil.scaleOpen(prompt: GuiObject, cosmetics: boolean?, direction: UDim2?)
	direction = direction or PromptUtil.Direction.Down

	if cosmetics then
		cosmeticsEnabled:Set(prompt, true)
	end

	local initialSize = getInitialSize(prompt)
	prompt.Size = UDim2.fromScale(0, 0)

	prompt.Visible = true

	local tween = TweenService:Create(
		prompt,
		TweenInfo.new(PROMPT_ANIMATION_LENGTH, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = initialSize }
	)
	tween:Play()

	return tween
end

function PromptUtil.slideOpen(prompt: GuiObject, cosmetics: boolean?, direction: UDim2?)
	direction = direction or PromptUtil.Direction.Up

	if cosmetics then
		cosmeticsEnabled:Set(prompt, true)
	end

	local initialPosition = Binder.bindFirst(prompt, "InitialPosition", prompt.Position)
	prompt.Position = initialPosition + direction

	local initialSize = getInitialSize(prompt)
	prompt.Size = UDimUtil.scalarMultiply(initialSize, 0.8)

	prompt.Visible = true

	local tween = TweenService:Create(
		prompt,
		TweenInfo.new(PROMPT_ANIMATION_LENGTH, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out),
		{ Position = initialPosition, Size = initialSize }
	)
	tween:Play()

	return tween
end

function PromptUtil.slideClose(prompt: GuiObject, cosmetics: boolean?, direction: UDim2?)
	direction = direction or PromptUtil.Direction.Down

	if cosmetics then
		cosmeticsEnabled:Set(prompt, false)
	end

	local initialPosition = Binder.bindFirst(prompt, "InitialPosition", prompt.Position)

	prompt.Visible = true

	local tween = TweenService:Create(
		prompt,
		TweenInfo.new(PROMPT_ANIMATION_LENGTH, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = prompt.Position - direction }
	)
	tween:Play()
	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed then
			prompt.Visible = false
			prompt.Position = initialPosition
		end
	end)

	return tween
end

function PromptUtil.close(prompt: GuiObject, cosmetics: boolean?)
	if cosmetics then
		cosmeticsEnabled:Set(prompt, false)
	end
	prompt.Visible = false
end

-------------------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------------------

backgroundScreen.Enabled = false
backgroundScreen.Frame.BackgroundTransparency = DEFAULT_BACKGROUND_TRANSPARENCY

cosmeticsEnabled.Changed:Connect(function(toggle)
	if toggle then
		TweenService
			:Create(
				blurEffect,
				TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{ Size = OPEN_BLUR_SIZE }
			)
			:Play()

		TweenService:Create(
			camera,
			TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ FieldOfView = CameraController.DefaultFOV * OPEN_FOV_MULTI }
		):Play()

		PromptUtil.openBackground()
	else
		TweenService:Create(blurEffect, TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), { Size = 0 })
			:Play()

		TweenService:Create(
			camera,
			TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ FieldOfView = CameraController.DefaultFOV }
		):Play()

		backgroundScreen.Enabled = false
	end
end)

return PromptUtil
