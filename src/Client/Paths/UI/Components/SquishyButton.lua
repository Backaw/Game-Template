local SquishyButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Button = require(script.Parent.Button)
local TweenUtil = require(ReplicatedStorage.Modules.Utils.TweenUtil)
local UDim2Util = require(ReplicatedStorage.Modules.Utils.UDim2Util)

export type SquishyButton = typeof(SquishyButton.new())

local DEFAULT_PRESSED_SCALE = UDim2.fromScale(0.9, 0.8)
local DEFAULT_HOVER_SCALE = 1.1
local ANIMATION_LENGTH = 0.05
local TWEEN_INFO = TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

function SquishyButton.new(guiObject: GuiButton, objectToScale: GuiObject?, pressedScale: UDim2?, anchorPoint: Vector2?)
	local squishyButton = Button.new(guiObject)

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	objectToScale = objectToScale or guiObject
	pressedScale = pressedScale or DEFAULT_PRESSED_SCALE
	anchorPoint = anchorPoint or Vector2.new(0.5, 0.5)

	local initSize = objectToScale.Size
	local container: Frame?

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------
	local function tweenPressedScale(scale: UDim2)
		TweenUtil.bind(objectToScale, "Squish", TweenService:Create(objectToScale, TWEEN_INFO, { Size = scale }))
	end

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------
	function squishyButton:Anchor(parent: GuiObject?, isParentAContainer: boolean?)
		if not parent then
			parent = guiObject.Parent
		end

		if not isParentAContainer then
			container = Instance.new("Frame")
			container.Name = guiObject.Name
			container.ZIndex = guiObject.ZIndex
			container.LayoutOrder = guiObject.LayoutOrder
			container.Size = guiObject.Size
			container.Position = guiObject.Position
			container.AnchorPoint = guiObject.AnchorPoint
			container.SizeConstraint = guiObject.SizeConstraint
			container.Parent = parent

			squishyButton:Mount(container, true)
			squishyButton:GetMaid():Add(container)
		else
			guiObject.Parent = parent
		end

		guiObject.Name = "Button"
		guiObject.SizeConstraint = Enum.SizeConstraint.RelativeXY
		guiObject.Size = UDim2.fromScale(1, 1)
		guiObject.Position = UDim2.fromScale(0.5, 0.5) -- TODO: Should be multiplied by anchor point or something
		guiObject.AnchorPoint = anchorPoint

		if objectToScale == guiObject then
			initSize = guiObject.Size
		end

		return container
	end

	function squishyButton:GetContainer()
		return container or guiObject
	end

	function squishyButton:SetHoverScalable(scaleable: GuiObject?, hoverScale: number?)
		scaleable = scaleable or squishyButton:GetGuiObject()
		hoverScale = hoverScale or DEFAULT_HOVER_SCALE

		local uiScale = Instance.new("UIScale")
		uiScale.Parent = scaleable

		local function tweenHoverScale(scale: number)
			TweenUtil.bind(uiScale, "Squish", TweenService:Create(uiScale, TWEEN_INFO, { Scale = scale }))
		end

		squishyButton.HoverStarted:Connect(function()
			tweenHoverScale(hoverScale)
		end)

		squishyButton.HoverEnded:Connect(function()
			tweenHoverScale(1)
		end)
	end

	-------------------------------------------------------------------------------
	-- Animations
	-------------------------------------------------------------------------------
	squishyButton.Pressed:Connect(function()
		tweenPressedScale(UDim2Util.uDim2Multiply(initSize, pressedScale))
	end)

	squishyButton.Released:Connect(function()
		tweenPressedScale(initSize)
	end)

	return squishyButton
end

return SquishyButton
