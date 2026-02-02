--!strict
local InputScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Client = ReplicatedStorage.Client
local Shared = ReplicatedStorage.Shared
local TemplateUtil = require(Shared.Utils.TemplateUtil)
local DebugUtil = require(Shared.Utils.DebugUtil)
local Maid = require(Shared.Maid)
local SquishyButton = require(Client.UI.Components.SquishyButton)
local InputController = require(Client.Input.InputController)
local InputConstants = require(Client.Input.InputConstants)
local InputUIUtil = require(Client.UI.Utils.InputUIUtil)
local UIController = require(Client.UI.UIController)
local Button = require(Client.UI.Components.Button)
local UIConstants = require(Client.UI.UIConstants)
local InputUtil = require(Client.Utils.InputUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local UI_STATES = {
	UIConstants.States.HUD,
	UIConstants.States.Battle,
}

local KEYBIND_TRANSPARENCY = 0.85
local KEYBIND_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ANCHOR_TYPES = InputConstants.MobileButtonAnchorTypes

local DEBUG = DebugUtil.isDebugging(false)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local playerGui = Players.LocalPlayer.PlayerGui

local screen = playerGui.Input
local keybinds = screen.Keybinds
local mobileButtons = screen.Mobile
local placeholderJumpButton = screen.JumpButton

local keybindContructor = TemplateUtil.constructor(keybinds.TEMP_KEYBIND)
local mobileButtonContructor = TemplateUtil.constructor(mobileButtons.TEMP_BUTTON)

local registeredInputs: { [string]: Maid.Maid } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

-- If anchorType is JumpButton, the position.X is the angle in radians while the position.Y is the offset from the jump button
local function setAnchoredPosition(label: GuiButton, anchorType: string, position: Vector2)
	anchorType = anchorType or ANCHOR_TYPES.Right
	if anchorType == ANCHOR_TYPES.Left then
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.fromOffset(position.X, position.Y)
	elseif anchorType == ANCHOR_TYPES.Right then
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.fromScale(1, 0) + UDim2.fromOffset(-position.X, position.Y)
	elseif anchorType == ANCHOR_TYPES.Jump then
		--[[
	l   ocal success, roblox = pcall(function()
			return (playerGui:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")) :: ImageButton
		end)
		jumpButton = if success then jumpButton else placeholderJumpButton ]]
		local jumpButton = placeholderJumpButton

		local parent = label.Parent :: ScreenGui

		local uiScale = assert(parent:FindFirstChild("UIScale") :: UIScale, "UIScale not found").Scale
		local theta = position.X
		local offset = position.Y
		local jumpRadius = jumpButton.AbsoluteSize.X / 2 / uiScale
		local labelRadius = label.AbsoluteSize.X / 2 / uiScale
		local anchorPoint = (-parent.AbsolutePosition + jumpButton.AbsolutePosition) / uiScale + Vector2.new(jumpRadius, jumpRadius)

		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromOffset(anchorPoint.X, anchorPoint.Y)
			+ UDim2.fromOffset(
				(jumpRadius + labelRadius + offset) * math.cos(theta),
				-(jumpRadius + labelRadius + offset) * math.sin(theta)
			)
	end
end

local function createMobileButton(id: string, handler: (Enum.UserInputState) -> (), params: InputController.UIParams): Maid.Maid
	local maid = registeredInputs[id]

	local button: Button.Button
	local tweens: { In: Tween?, Out: Tween? } = {}

	local function handlerWrapper(inputState: Enum.UserInputState)
		if tweens.In then
			tweens.In:Play()
			tweens.In.Completed:Connect(function(playbackState)
				if playbackState == Enum.PlaybackState.Completed and tweens.Out then
					tweens.Out:Play()
				end
			end)
		end

		handler(inputState)
	end

	-- Create the button
	if typeof(params.Mobile) == "GuiButton" then
		button = Button.new(params.Mobile, true)
	elseif typeof(params.Mobile) == "table" then
		local props = params.Mobile

		local buttonGuiObject = mobileButtonContructor()
		buttonGuiObject.Name = id
		buttonGuiObject.Size = UDim2.fromScale(props.Size, props.Size)
		buttonGuiObject.AnchorPoint = Vector2.new(0.5, 0.5)
		buttonGuiObject.UICorner.CornerRadius = UDim.new(0.5, 0)

		local icon = buttonGuiObject.TextLabel
		-- icon.Image = buttonProps.Icon
		icon.Text = id

		button = SquishyButton.new(buttonGuiObject, icon)
		button:SetHoverScalable(icon)

		maid:Add(InputUtil.CurrentInputType:Subscribe(function(inputType: string)
			if inputType == InputUtil.InputTypes.Touch then
				setAnchoredPosition(button:GetGuiObject(), props.AnchorPoint, props.Position)
			end
		end))
	end
	button:GetGuiObject().Active = not params.PassThrough
	maid:Add(button)

	-- Make functional
	if params.IsToggle then
		local toggle = false
		maid:Add(button.Clicked:Connect(function()
			toggle = not toggle
			handlerWrapper(if toggle then Enum.UserInputState.Begin else Enum.UserInputState.End)
		end))
	else
		maid:Add(button.Pressed:Connect(function()
			handlerWrapper(Enum.UserInputState.Begin)
		end))

		maid:Add(button.Released:Connect(function()
			handlerWrapper(Enum.UserInputState.End)
		end))
	end

	return maid
end

local function createKeybindLabel(id: string, keyboardInput: InputUtil.Input, gamepadInput: InputUtil.Input)
	local maid = registeredInputs[id]

	local label = keybindContructor()
	label.Name = id
	label.BackgroundTransparency = KEYBIND_TRANSPARENCY
	label.Center.TextLabel.Text = id
	maid:Add(label)

	local keybindIcon: ImageLabel = label.Center.Icon
	local tweens = {
		In = TweenService:Create(keybindIcon, KEYBIND_TWEEN_INFO, { Size = keybindIcon.Size - UDim2.fromOffset(15, 15) }),
		Out = TweenService:Create(keybindIcon, KEYBIND_TWEEN_INFO, { Size = keybindIcon.Size }),
	}

	-- Icon changing
	maid:Add(InputUIUtil.applyKeybindIcon(keybindIcon, keyboardInput, gamepadInput))

	-- Size increase/decrease on press/release
	maid:Add(InputController.InputSunk:Connect(function(inputId, inputState)
		if inputId == id and keybinds.Visible then -- TODO: This will cause problems later when canceling and frame is still open
			if inputState == Enum.UserInputState.Begin then
				tweens.In:Play()
			elseif inputState == Enum.UserInputState.End then
				tweens.Out:Play()
			end
		end
	end))

	return label
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

do
	InputController.InputRegistered:Connect(function(id, keyboardInput, gamepadInput, handler, params)
		if not params then
			return
		end

		local maid = Maid.new()
		registeredInputs[id] = maid

		if params.Mobile then
			createMobileButton(id, handler, params)
		end

		if params.Keybind and (keyboardInput or gamepadInput) then
			local keybindLabel = createKeybindLabel(id, keyboardInput, gamepadInput)

			-- Only one of the inputs might be registered, so only show for that devide type
			if not keyboardInput or not gamepadInput then
				maid:Add(InputUtil.CurrentInputType:Subscribe(function(inputType: string)
					if inputType == InputUtil.InputTypes.Gamepad then
						keybindLabel.Visible = gamepadInput ~= nil
					elseif inputType == InputUtil.InputTypes.Keyboard then
						keybindLabel.Visible = keyboardInput ~= nil
					end
				end))
			end

			maid:Add(InputController.getInputToggledSignal(id):Connect(function(toggle)
				keybindLabel.Visible = toggle

				local mobileButton = mobileButtons:FindFirstChild(id)
				if mobileButton and mobileButton:IsA("ImageButton") then
					mobileButton.Visible = toggle
				end
			end))
		end
	end)

	InputController.InputUnregistered:Connect(function(id)
		local maid = registeredInputs[id]
		if maid then
			maid:Destroy()
		end
		registeredInputs[id] = nil
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	placeholderJumpButton.Visible = DEBUG

	UIController.getStateMachine():RegisterGlobalCallback(function(_, toState)
		screen.Enabled = table.find(UI_STATES :: { string }, toState :: string) ~= nil
	end)

	InputUtil.CurrentInputType:Subscribe(function(inputType: string)
		local isMobile = inputType == InputUtil.InputTypes.Touch
		keybinds.Visible = not isMobile
		mobileButtons.Visible = isMobile
	end)
end

return InputScreen
