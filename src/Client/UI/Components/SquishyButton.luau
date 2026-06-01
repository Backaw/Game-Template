--!strict
local SquishyButton = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
local UDimUtil = require(ReplicatedStorage.Shared.Utils.UDimUtil)
local Button = require(script.Parent.Button)

export type SquishyButton<T> = Button.Button<T> & {
	Anchor: (SquishyButton<T>, parent: GuiObject, isParentAContainer: boolean?) -> GuiObject,
	GetContainer: (SquishyButton<T>) -> GuiObject,
	SetHoverScalable: (SquishyButton<T>, hoverScaleable: GuiObject?, hoverScale: number?) -> (),
}

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_PRESSED_SCALE = Vector2.new(0.9, 0.8)
local DEFAULT_HOVER_SCALE = 1.1
local HOVER_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PRESS_TWEEN_INFO = TweenInfo.new(0.05, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

-------------------------------------------------------------------------------
-- PUBLIC
-------------------------------------------------------------------------------

function SquishyButton.new<T>(buttonUI: T, scaleOnClick: GuiObject?, squishScale: Vector2?, anchorPoint: Vector2?)
	local squishyButton = Button.new(buttonUI) :: SquishyButton<T>

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local buttonGui = buttonUI :: GuiButton
	anchorPoint = (anchorPoint or Vector2.new(0.5, 0.5))

	local container: GuiObject

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function squishyButton:Anchor(parent, isParentAContainer)
		parent = assert(buttonGui.Parent, "Parent is required") :: GuiObject

		if isParentAContainer then
			buttonGui.Parent = parent
			container = parent
		else
			container = Instance.new("Frame")
			container.Name = buttonGui.Name
			container.ZIndex = buttonGui.ZIndex
			container.LayoutOrder = buttonGui.LayoutOrder
			container.Size = buttonGui.Size
			container.Position = buttonGui.Position
			container.AnchorPoint = buttonGui.AnchorPoint
			container.SizeConstraint = buttonGui.SizeConstraint
			container.Parent = parent

			squishyButton:Mount(container, true)
			squishyButton:GetMaid():Add(container)
		end

		buttonGui.Name = "Button"
		buttonGui.SizeConstraint = Enum.SizeConstraint.RelativeXY
		buttonGui.Size = UDim2.fromScale(1, 1)
		buttonGui.Position = UDim2.fromScale(0.5, 0.5) -- TODO: Should be multiplied by anchor point or something
		buttonGui.AnchorPoint = assert(anchorPoint, "Anchor point is required") :: Vector2

		return container
	end

	function squishyButton:GetContainer()
		return container or buttonUI
	end

	function squishyButton:SetHoverScalable(hoverScaleable, hoverScale)
		hoverScaleable = hoverScaleable or squishyButton:GetGuiObject()
		hoverScale = hoverScale or DEFAULT_HOVER_SCALE

		local uiScale = Instance.new("UIScale")
		uiScale.Parent = hoverScaleable

		local function tweenHoverScale(scale: number)
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = scale }):Play()
		end

		squishyButton.HoverStarted:Connect(function(disabled)
			if disabled then
				return
			end
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
		local clickScaleable = scaleOnClick or buttonGui
		local clickScale = (squishScale or DEFAULT_PRESSED_SCALE)

		local function tweenPressedScale(scale: Vector2)
			local initSize = InstanceUtil.getAttributeFirst(clickScaleable, "InitSize", clickScaleable.Size)
			TweenService:Create(clickScaleable :: GuiObject, PRESS_TWEEN_INFO, { Size = UDimUtil.vectorMultiply(initSize, scale) }):Play()
		end

		squishyButton.Pressed:Connect(function(disabled)
			if disabled then
				return
			end
			tweenPressedScale(clickScale)
		end)

		squishyButton.Released:Connect(function()
			tweenPressedScale(Vector2.one)
		end)
	end
	return squishyButton
end

return SquishyButton
