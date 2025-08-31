local Button = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local Signal = require(Shared.Signal)
local Sounds = require(Shared.Sounds)
local Component = require(Controllers.UI.Components.Component)
local ClickIndicator = require(Controllers.UI.Components.ClickIndicator)
local InputUtil = require(Controllers.Utils.InputUtil)
local UIUtil = require(Controllers.UI.Utils.UIUtil)
local UIController = require(Controllers.UI.UIController)

local CLICK_COOLDOWN = 0.05

local playerGui = Players.LocalPlayer.PlayerGui
local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function Button.new(guiObject: GuiButton, mute: boolean?)
	local button = Component.new()

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local clickIndicatorEnabled = true

	local hovering: boolean = false
	local clickDebounce = false

	local buttonSizeAtClick: Vector2
	local stateRestriction: string?

	local maid = button:GetMaid()

	-------------------------------------------------------------------------------
	-- PUBLIC VARIABLES
	-------------------------------------------------------------------------------
	button.Pressed = Signal.new()
	button.Released = Signal.new()
	button.HoverStarted = Signal.new()
	button.HoverEnded = Signal.new()
	button.Clicked = Signal.new()

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------
	function button:Mount(parent: GuiObject?, hideBackground: boolean?)
		if hideBackground and parent then
			parent.BackgroundTransparency = 1
		end

		guiObject.Parent = parent

		-- TODO: This should disconnect previous connections if you're mounting else where
		local ancestor = guiObject
		while ancestor ~= playerGui do
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

	function button:GetGuiObject()
		return guiObject
	end

	function button:IsHovering()
		return hovering
	end

	function button:EnableClickIndicator()
		clickIndicatorEnabled = true
	end

	function button:Destroy(keepButton: boolean?)
		if keepButton then
			guiObject.Active = false
			guiObject.Selectable = false
			guiObject.Selected = false
		else
			guiObject:Destroy()
		end

		maid:Destroy()
		table.clear(button)
	end
	-------------------------------------------------------------------------------
	-- Event handlers
	-------------------------------------------------------------------------------
	maid:Add(guiObject.MouseButton1Down:Connect(function()
		if not clickDebounce then
			clickDebounce = true

			buttonSizeAtClick = guiObject.AbsoluteSize

			local pressed
			if not stateRestriction or (uiStateMachine:GetState() == stateRestriction) then
				if clickIndicatorEnabled then
					ClickIndicator.play()
				end

				pressed = true
				button.Pressed:Fire()

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

	maid:Add(guiObject.MouseEnter:Connect(function()
		if not hovering then
			hovering = true
			button.HoverStarted:Fire()
		end
	end))

	maid:Add(guiObject.MouseLeave:Connect(function()
		if hovering then
			hovering = false
			button.HoverEnded:Fire()
		end
	end))

	maid:Add(button.Released:Connect(function()
		if InputUtil.isPrimaryClickInput() and not UIUtil.isMouseWithinObjectBounds(guiObject, buttonSizeAtClick) then
			return
		end

		button.Clicked:Fire()
	end))

	maid:Add(GuiService.Changed:Connect(function(changed)
		if changed ~= "SelectedObject" then
			return
		end

		local selected = GuiService.SelectedObject == guiObject
		if selected and not hovering then
			hovering = true
			button.HoverStarted:Fire()
		elseif not selected and hovering then
			hovering = false
			button.HoverEnded:Fire()
		end
	end))

	-------------------------------------------------------------------------------
	-- Initialization
	-------------------------------------------------------------------------------
	guiObject.Active = true
	guiObject.Selectable = true
	guiObject.AutoButtonColor = false

	return button
end

export type Button = typeof(Button.new(...))

return Button
