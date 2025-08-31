local HUDScreen = {}

local Players = game:GetService("Players")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local UIController = require(Controllers.UI.UIController)
local UIConstants = require(Controllers.UI.UIConstants)
local UIUtil = require(Controllers.UI.Utils.UIUtil)

local UI_STATE = UIConstants.States.HUD

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local uiStateMachine = UIController.getStateMachine()

local screen: ScreenGui = Players.LocalPlayer.PlayerGui.HUD

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

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
