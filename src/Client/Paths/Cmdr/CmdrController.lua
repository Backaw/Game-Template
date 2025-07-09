local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Permissions = require(Paths.Shared.Permissions)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient"))
local Button = require(Paths.Controllers.UI.Components.Button)

local ACTIVATION_KEYS = { Enum.KeyCode.Semicolon }

local toggleButton = Paths.UI.TopBar.Cmdr

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
