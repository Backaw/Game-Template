local CmdrController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Permissions = require(ReplicatedStorage.Shared.Permissions)
local Cmdr = require(ReplicatedStorage:WaitForChild("CmdrClient")) :: any
local Button = require(ReplicatedStorage.Client.UI.Components.Button)

local ACTIVATION_KEYS = { Enum.KeyCode.Semicolon }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local toggleButton = Players.LocalPlayer.PlayerGui.TopBar.Cmdr

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

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
		return if not Permissions.canRunCommands(context.Executor) then "You do not have permission to run this command" else nil
	end)
end

return CmdrController
