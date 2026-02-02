--!strict
local SquishyButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Button = require(script.Parent.Button)
local UDimUtil = require(ReplicatedStorage.Shared.Utils.UDimUtil)
local Binder = require(ReplicatedStorage.Shared.Binder)

export type SquishyButton = Button.Button & {
	Anchor: (SquishyButton, parent: GuiObject, isParentAContainer: boolean?) -> GuiObject,
	GetContainer: (SquishyButton) -> GuiObject,
	SetHoverScalable: (SquishyButton, hoverScaleable: GuiObject?, hoverScale: number?) -> (),
}

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_PRESSED_SCALE = Vector2.new(0.9, 0.8)
local DEFAULT_HOVER_SCALE = 1.1
local ANIMATION_LENGTH = 0.05
local TWEEN_INFO = TweenInfo.new(ANIMATION_LENGTH, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-------------------------------------------------------------------------------
-- PUBLIC
-------------------------------------------------------------------------------

function SquishyButton.new(guiObject: GuiButton, scaleOnClick: GuiObject?, squishScale: Vector2?, anchorPoint: Vector2?)
	local squishyButton = Button.new(guiObject) :: SquishyButton

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	anchorPoint = (anchorPoint or Vector2.new(0.5, 0.5))

	local container: GuiObject

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function squishyButton:Anchor(parent, isParentAContainer)
		parent = assert(guiObject.Parent, "Parent is required") :: GuiObject

		if isParentAContainer then
			guiObject.Parent = parent
			container = parent
		else
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
		end

		guiObject.Name = "Button"
		guiObject.SizeConstraint = Enum.SizeConstraint.RelativeXY
		guiObject.Size = UDim2.fromScale(1, 1)
		guiObject.Position = UDim2.fromScale(0.5, 0.5) -- TODO: Should be multiplied by anchor point or something
		guiObject.AnchorPoint = assert(anchorPoint, "Anchor point is required") :: Vector2

		return container
	end

	function squishyButton:GetContainer()
		return container or guiObject
	end

	function squishyButton:SetHoverScalable(hoverScaleable, hoverScale)
		hoverScaleable = hoverScaleable or squishyButton:GetGuiObject()
		hoverScale = hoverScale or DEFAULT_HOVER_SCALE

		local uiScale = Instance.new("UIScale")
		uiScale.Parent = hoverScaleable

		local function tweenHoverScale(scale: number)
			TweenService:Create(uiScale, TWEEN_INFO, { Scale = scale }):Play()
		end

		squishyButton.HoverStarted:Connect(function()
			tweenHoverScale(hoverScale :: number)
		end)

		squishyButton.HoverEnded:Connect(function()
			tweenHoverScale(1)
		end)
	end

	-------------------------------------------------------------------------------
	-- Animations
	-------------------------------------------------------------------------------

	do
		local clickScaleable = scaleOnClick or guiObject
		local clickScale = (squishScale or DEFAULT_PRESSED_SCALE)

		local function tweenPressedScale(scale: Vector2)
			local initSize = Binder.bindFirst(clickScaleable, "InitSize", clickScaleable.Size)
			TweenService:Create(clickScaleable :: GuiObject, TWEEN_INFO, { Size = UDimUtil.vectorMultiply(initSize, scale) }):Play()
		end

		squishyButton.Pressed:Connect(function()
			tweenPressedScale(clickScale)
		end)

		squishyButton.Released:Connect(function()
			tweenPressedScale(Vector2.one)
		end)
	end
	return squishyButton
end

return SquishyButton
