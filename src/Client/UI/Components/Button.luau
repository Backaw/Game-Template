--!strict
local Button = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local Component = require(ReplicatedStorage.Client.UI.Components.Component)
local ClickIndicator = require(ReplicatedStorage.Client.UI.Components.ClickIndicator)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local UIUtil = require(ReplicatedStorage.Client.UI.Utils.UIUtil)
local UIController = require(ReplicatedStorage.Client.UI.UIController)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local CLICK_COOLDOWN = 0.05

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Button<T> = Component.Component & {
	Pressed: Signal.Signal<boolean>,
	Released: Signal.Signal<>,
	HoverStarted: Signal.Signal<boolean>,
	HoverEnded: Signal.Signal<boolean?>,
	Clicked: Signal.Signal<boolean>,
	Mount: (Button<T>, parent: GuiObject?, hideBackground: boolean?) -> (),
	RestrictToState: (Button<T>, state: string) -> (),
	GetGui: (Button<T>) -> T,
	Toggle: (Button<T>, toggle: boolean) -> (),
	IsHovering: (Button<T>) -> boolean,
	EnableClickIndicator: (Button<T>) -> (),
	Destroy: (Button<T>, keepButton: boolean?) -> (),
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function Button.new<T>(buttonUI: T, mute: boolean?)
	local button = Component.new() :: Button<T>

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------

	local guiButton = buttonUI :: GuiButton

	local clickIndicatorEnabled = true

	local hovering: boolean = false
	local clickDebounce = false

	local buttonSizeAtClick: Vector2
	local stateRestriction: string?

	local maid = button:GetMaid()
	local isEnabled = true

	-------------------------------------------------------------------------------
	-- PUBLIC VARIABLES
	-------------------------------------------------------------------------------
	button.Pressed = Signal.new()
	button.Released = Signal.new()
	button.HoverStarted = Signal.new()
	button.HoverEnded = Signal.new() :: Signal.Signal<boolean?>
	button.Clicked = Signal.new()

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------

	local function closeHover(disabling: boolean?)
		if hovering then
			hovering = false

			button.HoverEnded:Fire(disabling)
		end
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function button:Mount(parent, hideBackground)
		if hideBackground and parent then
			parent.BackgroundTransparency = 1
		end

		guiButton.Parent = parent

		-- TODO: This should disconnect previous connections if you're mounting else where
		local ancestor = guiButton
		while ancestor :: Instance ~= playerGui :: Instance do
			if ancestor:IsA("GuiObject") then
				local instance = ancestor
				instance:GetPropertyChangedSignal("Visible"):Connect(function()
					if instance.Visible == false and hovering then
						hovering = false
						button.HoverEnded:Fire()
					end
				end)
			end

			ancestor = ancestor.Parent
		end
	end

	function button:RestrictToState(state: string)
		stateRestriction = state
	end

	function button:GetGui()
		return guiButton
	end

	function button:IsHovering()
		return hovering
	end

	function button:EnableClickIndicator()
		clickIndicatorEnabled = true
	end

	function button:Toggle(toggle: boolean)
		if isEnabled == toggle then
			return
		end

		isEnabled = toggle
		if not toggle then
			closeHover(true)
		end
	end

	function button:Destroy(keepButton: boolean?)
		if keepButton then
			guiButton.Active = false
			guiButton.Selectable = false
			guiButton.Selected = false
		else
			guiButton:Destroy()
		end

		maid:Destroy()
		button = nil
	end

	-------------------------------------------------------------------------------
	-- Event handlers
	-------------------------------------------------------------------------------
	maid:Add(guiButton.MouseButton1Down:Connect(function()
		if not clickDebounce then
			clickDebounce = true

			buttonSizeAtClick = guiButton.AbsoluteSize

			local pressed
			if not stateRestriction or (uiStateMachine:GetState() == stateRestriction) then
				if clickIndicatorEnabled then
					ClickIndicator.play()
				end

				pressed = true
				button.Pressed:Fire(not isEnabled)

				if not mute then
					Sounds.play("ButtonClick")
				end
			end

			local connection: RBXScriptConnection
			connection = UserInputService.InputEnded:Connect(function(input)
				local userInputType = input.UserInputType
				if
					(
						userInputType == Enum.UserInputType.MouseButton1
						or userInputType == Enum.UserInputType.Touch
						or userInputType == Enum.UserInputType.Gamepad1
					) and pressed
				then
					connection:Disconnect()
					if button.Released then
						button.Released:Fire()
					end
				end
			end)

			task.wait(CLICK_COOLDOWN)
			clickDebounce = false
		end
	end))

	maid:Add(guiButton.MouseEnter:Connect(function()
		if not hovering then
			hovering = true
			button.HoverStarted:Fire(not isEnabled)
		end
	end))

	maid:Add(guiButton.MouseLeave:Connect(function()
		closeHover()
	end))

	maid:Add(button.Released:Connect(function()
		if InputUtil.isPrimaryClickInput() and not UIUtil.isMouseWithinObjectBounds(guiButton, buttonSizeAtClick) then
			return
		end

		button.Clicked:Fire(not isEnabled)
	end))

	maid:Add(GuiService.Changed:Connect(function(changed)
		if changed ~= "SelectedObject" then
			return
		end

		local selected = GuiService.SelectedObject == guiButton
		if selected and not hovering then
			hovering = true
			button.HoverStarted:Fire(not isEnabled)
		elseif not selected and hovering then
			hovering = false
			button.HoverEnded:Fire()
		end
	end))

	-------------------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------------------
	guiButton.Active = true
	guiButton.Selectable = true
	guiButton.AutoButtonColor = false

	return button
end

return Button
