--!strict
local ClickIndicator = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UDim2Util = require(ReplicatedStorage.Shared.Utils.UDim2Util)
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local MIN_TRANSPARENCY = 0.2
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local screen = Players.LocalPlayer.PlayerGui.Mouse
local clickIndicator = screen.ClickIndicator

local finalSize = clickIndicator.Size
local startSize = UDim2Util.scalarMultiply(finalSize, 0.4)

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
	TweenUtil.bind(clickIndicator, "Indicate", TweenService:Create(clickIndicator, TWEEN_INFO, { Size = finalSize, Transparency = 1 }))
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

screen.Enabled = true
clickIndicator.Visible = false

return ClickIndicator
