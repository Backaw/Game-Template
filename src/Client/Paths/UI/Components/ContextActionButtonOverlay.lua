local ContextActionButtonOverlay = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local SquishyButton = require(Paths.Controllers.UI.Components.SquishyButton)
local DeviceUtil = require(Paths.Controllers.Utils.DeviceUtil)

local BASE_JUMP_BUTTON_OFFSET = Vector2.new(95, 90)
local BASE_JUMP_BUTTON_SIZE = Vector2.new(70, 70)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local screen: ScreenGui = Paths.UI.MobileButtons

-------------------------------------------------------------------------------
-- PRIVATE MEHODS
-------------------------------------------------------------------------------
local function getScaleFromRatio(ratio: Vector2)
	return math.min(ratio.X, ratio.Y)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function ContextActionButtonOverlay.new(name: string, mobileButton: ImageButton)
	local template: Frame = screen[name]

	local position: Vector2 = template.AbsolutePosition - mobileButton.Parent.AbsolutePosition
	mobileButton.ActionIcon.Visible = false
	mobileButton.Position = UDim2.fromOffset(position.X, position.Y)
	mobileButton.Size = template.Size
	mobileButton.ImageTransparency = 1

	local overlay = template:Clone()
	overlay.Visible = true
	overlay.Parent = mobileButton
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Position = UDim2.fromScale(0.5, 0.5)
	overlay.AnchorPoint = Vector2.new(0.5, 0.5)
	overlay.Parent = mobileButton

	overlay:FindFirstChildOfClass("UIScale").Parent = mobileButton

	SquishyButton.new(mobileButton, overlay)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
if DeviceUtil.isMobile() then
	screen.Enabled = true

	local jumpButton = Paths.UI.TouchGui.TouchControlFrame.JumpButton
	local offsetScale = getScaleFromRatio(jumpButton.AbsoluteSize / BASE_JUMP_BUTTON_SIZE)
	local sizeScale = getScaleFromRatio(
		Vector2.new(math.abs(jumpButton.Position.X.Offset), math.abs(jumpButton.Position.Y.Offset)) / BASE_JUMP_BUTTON_OFFSET
	)

	for _, child: GuiObject in  (screen:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Position = UDim2.new(1, child.Position.X.Offset * offsetScale, 1, child.Position.Y.Offset * offsetScale)

			local scale = Instance.new("UIScale")
			scale.Scale = sizeScale
			scale.Parent = child
			scale:SetAttribute("DoNotScale", true)

			child.Visible = false
		end
	end
else
	screen.Enabled = false
end

return ContextActionButtonOverlay
