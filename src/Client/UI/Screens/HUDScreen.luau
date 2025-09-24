--!strict
local HUDScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(ReplicatedStorage.Client.UI.UIController)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local UIUtil = require(ReplicatedStorage.Client.UI.Utils.UIUtil)

local UI_STATE = UIConstants.States.HUD

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local uiStateMachine = UIController.getStateMachine()

local screen = Players.LocalPlayer.PlayerGui.HUD

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Register state
do
	uiStateMachine:RegisterGlobalCallback(function()
		UIController.ScreenStateTransition:andThen(function()
			screen.Enabled = UIUtil.isStackHUDPermissive(uiStateMachine:GetStack())
		end)
	end)

	uiStateMachine:Push(UI_STATE)
end

return HUDScreen
