--!strict
local Badge = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local TemplateUtil = require(Shared.Utils.TemplateUtil)
local Toggle = require(Shared.Toggle)
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local TWEEN_LENGTH = 0.65

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local player = Players.LocalPlayer
local constructor = TemplateUtil.constructor(ComponentUtil.getPlayerGui(player).Components.Badge)

function Badge.new(parent: GuiObject, position: UDim2)
	local badge = constructor()
	badge.Parent = parent
	badge.Position = position

	local toggle = Toggle.new(false)
	do
		local ring = badge.Ring
		ring.Size = UDim2.fromScale(0.65, 0.65)
		ring.ImageTransparency = 1
		TweenService:Create(
			ring,
			TweenInfo.new(TWEEN_LENGTH, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1),
			{ Size = UDim2.fromScale(1.4, 1.5), ImageTransparency = 0 }
		):Play()
		TweenService
			:Create(
				ring,
				TweenInfo.new(TWEEN_LENGTH / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out, -1, true),
				{ ImageTransparency = 0 }
			)
			:Play()
	end

	toggle.Changed:Subscribe(function(visible)
		badge.Visible = visible
	end, toggle:Get())

	return toggle, function(text: string)
		badge.TextLabel.Text = text
	end
end

return Badge
