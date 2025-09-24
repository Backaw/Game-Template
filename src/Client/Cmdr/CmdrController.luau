--!strict
local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Permissions = require(ReplicatedStorage.Shared.Permissions)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient")) :: any
local Button = require(ReplicatedStorage.Client.UI.Components.Button)

local ACTIVATION_KEYS = { Enum.KeyCode.Semicolon }

local toggleButton = Players.LocalPlayer.PlayerGui.TopBar.Cmdr

function CmdrController.init()
	if Permissions.canRunCommands(Players.LocalPlayer) then
		Cmdr:SetEnabled(true)
		Cmdr:SetActivationKeys(ACTIVATION_KEYS)
		Cmdr:SetHideOnLostFocus(false)

		toggleButton.Visible = true
		Button.new(toggleButton).Pressed:Connect(function()
			Cmdr:Toggle()
		end)
	else
		Cmdr:SetEnabled(false)
		toggleButton.Visible = false
	end

	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		if not Permissions.canRunCommands(context.Executor) then
			return "You do not have permission to run this command"
		end

		return ""
	end)
end

return CmdrController
