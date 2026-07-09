--!strict
local HUDScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Client
local Shared = ReplicatedStorage.Shared

local Toggle = require(Shared.Toggle)
local SquishyButton = require(Client.UI.Components.SquishyButton)
local UIController = require(Client.UI.UIController)
local Badge = require(Client.UI.Components.Badge)
local UIUtil = require(Client.UI.Utils.UIUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local UI_STATE = UIController.States.HUD

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local uiStateMachine = UIController.getStateMachine()

local playerGui = Players.LocalPlayer.PlayerGui
local screen = playerGui.HUD
--local stateButtons = screen.Left.ScreenStates

local badges: { [string]: { Toggle: Toggle.Toggle, SetText: (string) -> () } } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function initStateButton(guiObject: ImageButton, state: UIController.State, validator: (() -> boolean)?)
	local icon = (guiObject :: any).Icon

	local button = SquishyButton.new(guiObject, icon)
	button:SetHoverScalable(icon)

	button.Pressed:Connect(function()
		if not validator or (validator and validator()) then
			UIController.toggleScreenState(state)
		end
	end)
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function HUDScreen.getBadge(uiState: string): Toggle.Toggle
	if not badges[uiState] then
		local button = (screen.Left.ScreenStates :: any)[uiState] :: ImageButton
		-- local button = (stateButtons :: any)[uiState] :: ImageButton
		local toggle, setText = Badge.new(button, UDim2.fromScale(1, 0))

		badges[uiState] = { Toggle = toggle, SetText = setText }
	end
	return badges[uiState].Toggle
end

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
