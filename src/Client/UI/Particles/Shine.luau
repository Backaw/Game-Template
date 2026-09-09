-- !strict
local Shine = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Client
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)
local UDimUtil = require(ReplicatedStorage.Shared.Utils.UDimUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------
local DEFAULT_EASING_STYLE = Enum.EasingStyle.Quad
local DEFAULT_EASING_DIRECTION = Enum.EasingDirection.Out
local DEFAULT_TWEEN_INFO = TweenInfo.new(0.3, DEFAULT_EASING_STYLE, DEFAULT_EASING_DIRECTION)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local overlayTemplate = ComponentUtil.getPlayerGui().Components.Shine.Overlay

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Shine.initOverlay(overlay: GuiObject)
	local shine = overlay:FindFirstChildOfClass("UIGradient")
	if shine then
		shine.Offset = Vector2.new(-100, 0)
	end
	return overlay
end

function Shine.mount(parent: GuiObject, transparency: number?)
	local overlay = overlayTemplate:Clone()
	overlay.BackgroundTransparency = transparency or 0
	overlay.Parent = parent
	Shine.initOverlay(overlay)

	local uiCorner = parent:FindFirstChildOfClass("UICorner")
	if uiCorner then
		uiCorner:Clone().Parent = overlay
	end

	local uiPadding: UIPadding = parent:FindFirstChildOfClass("UIPadding")
	if uiPadding then
		local paddingTop = uiPadding.PaddingTop
		local paddingLeft = uiPadding.PaddingLeft
		local paddingRight = uiPadding.PaddingRight
		local paddingBottom = uiPadding.PaddingBottom
		overlay.Size += UDim2.new(
			paddingRight.Scale + paddingLeft.Scale,
			paddingRight.Offset + paddingLeft.Offset,
			paddingTop.Scale + paddingBottom.Scale,
			paddingTop.Offset + paddingBottom.Offset
		)
	end

	return overlay
end

function Shine.mountToImage(image: ImageLabel)
	local uiGradient = overlayTemplate.UIGradient:Clone()
	uiGradient.Parent = image

	return image :: typeof(overlayTemplate)
end

function Shine.applySillouette(overlay: typeof(overlayTemplate), image: string)
	overlay.BackgroundTransparency = 1
	overlay.Image = image
end

function Shine.play(overlay: GuiObject, tweenInfo: TweenInfo?, range: number?)
	local shine = overlay.UIGradient
	shine.Offset = Vector2.new(-(range or 1), 0)

	local tween = TweenService:Create(shine, tweenInfo or DEFAULT_TWEEN_INFO, {
		Offset = Vector2.new((range or 1), 0),
	})
	tween:Play()

	return tween
end

function Shine.loop(overlay: typeof(overlayTemplate), length: number?, cooldown: number?, scale: number?)
	local shine = overlay.UIGradient
	shine.Offset = Vector2.new(-1, 0)

	length = length or 0.8
	cooldown = cooldown or 3
	local tween = TweenService:Create(shine, TweenInfo.new(length, DEFAULT_EASING_STYLE, DEFAULT_EASING_DIRECTION, -1, false, cooldown), {
		Offset = Vector2.new(1, 0),
	})
	if scale then
		TweenService:Create(
			overlay,
			TweenInfo.new(length / 2, Enum.EasingStyle.Back, DEFAULT_EASING_DIRECTION, -1, true, cooldown),
			{ Size = UDimUtil.scalarMultiply(overlay.Size, scale) }
		):Play()
	end

	tween:Play()

	return tween
end

return Shine
