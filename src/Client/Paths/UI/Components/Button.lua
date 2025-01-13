local Button = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Signal = require(Paths.Shared.Signal)
local Component = require(Paths.Controllers.UI.Components.Component)
local ClickIndicator = require(Paths.Controllers.UI.Components.ClickIndicator)
local Sounds = require(Paths.Shared.Sounds)
local InputUtil = require(Paths.Controllers.Utils.InputUtil)
local UIUtil = require(Paths.Controllers.UI.Utils.UIUtil)
local UIController = require(Paths.Controllers.UI.UIController)

export type Button = typeof(Button.new())

local CLICK_COOLDOWN = 0.05

local playerGui = Players.LocalPlayer.PlayerGui
local uiStateMachine = UIController.getStateMachine()

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
	function button:Mount(parent: Instance?, hideBackground: boolean?)
		if hideBackground then
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

	function button:ToggleColor(toggle: boolean)
		if toggle then
			guiObject.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			guiObject:FindFirstChildOfClass("UIGradient").Enabled = true
		else
			guiObject.BackgroundColor3 = Color3.fromRGB(162, 162, 162)
			guiObject:FindFirstChildOfClass("UIGradient").Enabled = false
		end
	end

	-------------------------------------------------------------------------------
	-- Event handlers
	-------------------------------------------------------------------------------
	guiObject.MouseButton1Down:Connect(function()
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
					button.Released:Fire()
					connection:Disconnect()
				end
			end)

			task.wait(CLICK_COOLDOWN)
			clickDebounce = false
		end
	end)

	guiObject.MouseEnter:Connect(function()
		if not hovering then
			hovering = true
			button.HoverStarted:Fire()
		end
	end)

	guiObject.MouseLeave:Connect(function()
		if hovering then
			hovering = false
			button.HoverEnded:Fire()
		end
	end)

	button.Released:Connect(function()
		if not InputUtil.isGamepadInput() and not UIUtil.isMouseWithinObjectBounds(guiObject, buttonSizeAtClick) then
			return
		end

		button.Clicked:Fire()
	end)

	button:GetMaid():Add(GuiService.Changed:Connect(function(changed)
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

	button:GetMaid():Add(guiObject)

	return button
end

return Button
