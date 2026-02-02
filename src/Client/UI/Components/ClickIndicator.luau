--!strict
local ClickIndicator = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UDimUtil = require(ReplicatedStorage.Shared.Utils.UDimUtil)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local ComponentUtil = require(ReplicatedStorage.Client.UI.Utils.ComponentUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local MIN_TRANSPARENCY = 0.2
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local screen = ComponentUtil.getPlayerGui().Mouse
local clickIndicator = screen.ClickIndicator

local finalSize = clickIndicator.Size
local startSize = UDimUtil.scalarMultiply(finalSize, 0.4)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function ClickIndicator.play()
	if InputUtil.isMobile() or UserInputService.GamepadEnabled then
		return
	end

	local mousePosition = UserInputService:GetMouseLocation()

	clickIndicator.Position = UDim2.fromOffset(mousePosition.X, mousePosition.Y)
	clickIndicator.Visible = true
	clickIndicator.Transparency = MIN_TRANSPARENCY
	clickIndicator.Size = startSize
	TweenService:Create(clickIndicator, TWEEN_INFO, { Size = finalSize, Transparency = 1 }):Play()
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

screen.Enabled = true
clickIndicator.Visible = false

return ClickIndicator
