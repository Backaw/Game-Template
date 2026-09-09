--!strict
local HUDScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Client
local Shared = ReplicatedStorage.Shared
local Toggle = require(Shared.Toggle)
local Signal = require(Shared.Signal)
local SquishyButton = require(Client.UI.Components.SquishyButton)
local UIScaleController = require(Client.UI.UIScaleController)
local PromptUtil = require(Client.UI.Utils.PromptUtil)
local UIController = require(Client.UI.UIController)
local InputUtil = require(Client.Utils.InputUtil)
local Badge = require(Client.UI.Components.Badge)
local UIUtil = require(Client.UI.Utils.UIUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local UI_STATE = UIController.States.HUD

local MOBILE_SCALE_MULT = 1.78
local HUD_OPEN_SPEED = 2.3

local COMPONENT_NAMES = {
	Left = "Left",
	Right = "Right",
	Top = "Top",
	Bottom = "Bottom",
	Center = "Center",
	BottomLeft = "BottomLeft",
	ScreenStates = "ScreenStates",
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type ComponentName = keyof<typeof(COMPONENT_NAMES)>

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local uiStateMachine = UIController.getStateMachine()

local screen = Players.LocalPlayer.PlayerGui.HUD

local stateButtons = screen.Left.ScreenStates

local componentToggles: { [ComponentName]: Toggle.Toggle } = {}
local badges: { [string]: { Toggle: Toggle.Toggle, SetText: (string) -> () } } = {}

local slidingAnchorFrames: { [ComponentName]: { Frame: GuiObject, Open: UDim2, Close: UDim2 } } = {
	Left = { Frame = screen.Left, Open = PromptUtil.Direction.Right, Close = PromptUtil.Direction.Left },
	Right = { Frame = screen.Right, Open = PromptUtil.Direction.Left, Close = PromptUtil.Direction.Right },
	Top = { Frame = screen.Top, Open = PromptUtil.Direction.Down, Close = PromptUtil.Direction.Up },
	Bottom = { Frame = screen.Bottom, Open = PromptUtil.Direction.Up, Close = PromptUtil.Direction.Down },
	BottomLeft = { Frame = screen.BottomLeft, Open = PromptUtil.Direction.Right, Close = PromptUtil.Direction.Left },
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

HUDScreen.Components = COMPONENT_NAMES :: { [ComponentName]: ComponentName }
HUDScreen.TycoonClicked = Signal.new() :: Signal.Signal<()>
HUDScreen.ReturnToCanvasClicked = Signal.new() :: Signal.Signal<()>

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function _initStateButton(guiObject: ImageButton, state: UIController.State?, validator: (() -> boolean)?, onPressed: (() -> ())?)
	local icon = guiObject :: any -- .Icon

	local button = SquishyButton.new(guiObject, icon)
	button:SetHoverScalable(icon)

	button.Pressed:Connect(function()
		if validator and not validator() then
			return
		end
		if onPressed then
			onPressed()
		elseif state then
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

function HUDScreen.toggleComponent(name: ComponentName, job: Toggle.Job, visible: boolean)
	componentToggles[name]:Set(job, visible)
end

function HUDScreen.toggleComponents(names: { ComponentName }, job: any, visible: boolean)
	for _, name in names do
		HUDScreen.toggleComponent(name, job, visible)
	end

	return function()
		HUDScreen.toggleComponents(names, job, not visible)
	end
end

function HUDScreen.onlyShow(names: { ComponentName }, job: Toggle.Job)
	for _, name in HUDScreen.Components do
		HUDScreen.toggleComponent(name, job, table.find(names, name) ~= nil)
	end
end

function HUDScreen.releaseComponentToggles(job: Toggle.Job)
	for _, toggle in componentToggles do
		toggle:RemoveJob(job)
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- Register state
do
	screen.Enabled = false
	uiStateMachine:RegisterGlobalCallback(function()
		UIController.ScreenStateTransition:andThen(function()
			screen.Enabled = UIUtil.isStackHUDPermissive(uiStateMachine:GetStack())
		end)
	end)

	uiStateMachine:Push(UI_STATE)
end

do
	if InputUtil.isMobile() then
		for _, child in screen:GetChildren() do
			local childScale = child:FindFirstChild("UIScale", true)
			if childScale and childScale:IsA("UIScale") then
				UIScaleController.setMultiplier(childScale, MOBILE_SCALE_MULT)
			end
		end
	end
end

do
	for componentName in HUDScreen.Components do
		local toggle = componentToggles[componentName]
		if not toggle then
			toggle = Toggle.new(true)
			componentToggles[componentName] = toggle

			local anchorFrameConfig = slidingAnchorFrames[componentName]
			if anchorFrameConfig then
				toggle.Changed:Connect(function(visible)
					if visible then
						PromptUtil.slideOpen(anchorFrameConfig.Frame, false, anchorFrameConfig.Open, HUD_OPEN_SPEED)
					else
						PromptUtil.slideClose(anchorFrameConfig.Frame, false, anchorFrameConfig.Close)
					end
				end)
			elseif componentName == COMPONENT_NAMES.Center then
				toggle.Changed:Connect(function(visible)
					if visible then
						PromptUtil.open(screen.Center)
					else
						PromptUtil.close(screen.Center)
					end
				end)
			elseif componentName == COMPONENT_NAMES.ScreenStates then
				toggle.Changed:Connect(function(visible)
					stateButtons.Visible = visible
				end)
			end
		end
	end

	for _, componentName in HUDScreen.Components do
		if not componentToggles[componentName] then
			warn(`HUD component {componentName}'s toggle not found`)
		end
	end
end

return HUDScreen
