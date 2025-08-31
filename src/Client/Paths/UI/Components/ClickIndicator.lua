local ClickIndicator = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local UDim2Util = require(Shared.Utils.UDim2Util)
local TweenUtil = require(Shared.Utils.TweenUtil)
local InputUtil = require(Controllers.Utils.InputUtil)

local screen = Players.LocalPlayer.PlayerGui.Mouse
local clickIndicator = screen.ClickIndicator

local MIN_TRANSPARENCY = 0.2
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local FINAL_SIZE = clickIndicator.Size
local START_SIZE = UDim2Util.scalarMultiply(FINAL_SIZE, 0.4)

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
	clickIndicator.Size = START_SIZE
	TweenUtil.bind(clickIndicator, "Indicate", TweenService:Create(clickIndicator, TWEEN_INFO, { Size = FINAL_SIZE, Transparency = 1 }))
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
screen.Enabled = true
clickIndicator.Visible = false

return ClickIndicator
