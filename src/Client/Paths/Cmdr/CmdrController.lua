local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local Shared = ReplicatedStorage.Modules
local Permissions = require(Shared.Permissions)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Button = require(Controllers.UI.Components.Button)

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
	end)
end

return CmdrController
