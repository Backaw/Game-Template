--!strict
local InputScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SquishyButton = require(ReplicatedStorage.Client.UI.Components.SquishyButton)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local Button = require(ReplicatedStorage.Client.UI.Components.Button)
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local InputUIUtil = require(ReplicatedStorage.Client.UI.Utils.InputUIUtil)
local Maid = require(ReplicatedStorage.Shared.Maid)
local UIController = require(ReplicatedStorage.Client.UI.UIController)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local Signal = require(ReplicatedStorage.Shared.Signal)
local InputController = require(ReplicatedStorage.Client.InputController)
local InputConstants = require(ReplicatedStorage.Shared.Constants.InputConstants)

type MaidList = { [string]: Maid.Maid }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local UI_STATE = UIConstants.States.HUD
local KEYBIND_TRANSPARENCY = 0.85
local KEYBIND_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ANCHOR_TYPES = InputConstants.MobileInputButtonAnchors

local screen = Players.LocalPlayer.PlayerGui.Input
local keybinds = screen.Keybinds
local mobileButtons = screen.Mobile

local constructors = {
	Keybind = TemplateUtil.constructor(keybinds.TEMP_KEYBIND),
	Button = TemplateUtil.constructor(mobileButtons.TEMP_BUTTON),
}

local registeredInputs: { [string]: { Highlights: Maid.Maid | nil, Maid: Maid.Maid, IsTool: boolean? } } = {}
local internalInputRegistered = Signal.new() :: Signal.Signal<string>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
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
		local jumpButton = (screen:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")) :: ImageButton
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

local function createMobileButton(
	id: string,
	mobileButton: InputConstants.MobileInputButton,
	handler: (Enum.UserInputState) -> ()
): Maid.Maid
	local maid = registeredInputs[id].Maid

	local button: Button.Button
	local tweens: { In: Tween?, Out: Tween? } = {}

	local function preHandler(inputState: Enum.UserInputState)
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

	if mobileButton.ButtonReference then
		button = Button.new(mobileButton.ButtonReference, true)
	elseif mobileButton.InstantiationProps then
		local props = mobileButton.InstantiationProps

		local buttonTemplate = constructors.Button() :: ImageButton
		buttonTemplate.Name = id
		buttonTemplate.Size = UDim2.fromScale(props.Size, props.Size)
		buttonTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
		-- buttonTemplate.Image = buttonProps.Icon :: typeof(buttonTemplate.Image)

		local uiCorner = assert(buttonTemplate:FindFirstChild("UICorner")) :: UICorner
		uiCorner.CornerRadius = UDim.new(0.5, 0)

		local icon = assert(buttonTemplate:FindFirstChild("TextLabel")) :: TextLabel
		icon.Text = id

		local squishyButton = SquishyButton.new(buttonTemplate, buttonTemplate)
		squishyButton:SetHoverScalable(icon)

		button = squishyButton

		maid:Add(InputUtil.onInputTypeChanged(function(inputType: string)
			if inputType == InputUtil.InputTypes.Touch then
				setAnchoredPosition(button:GetGuiObject(), props.AnchorPoint, props.Position)
			end
		end))
	end
	maid:Add(button)

	if mobileButton.IsToggle then
		local toggle = false
		maid:Add(button.Clicked:Connect(function()
			toggle = not toggle
			preHandler(if toggle then Enum.UserInputState.Begin else Enum.UserInputState.End)
		end))
	else
		maid:Add(button.Pressed:Connect(function()
			preHandler(Enum.UserInputState.Begin)
		end))

		maid:Add(button.Released:Connect(function()
			preHandler(Enum.UserInputState.End)
		end))
	end

	return maid
end

local function createKeybindLabel(id: string, keyboardInput: InputUtil.Input, gamepadInput: InputUtil.Input)
	local maid = registeredInputs[id].Maid

	local frame = constructors.Keybind()
	frame.Name = id
	frame.BackgroundTransparency = KEYBIND_TRANSPARENCY
	frame.Center.TextLabel.Text = id
	maid:Add(frame)

	local icon: ImageLabel = frame.Center.Icon
	local tweens = {
		In = TweenService:Create(icon, KEYBIND_TWEEN_INFO, { Size = icon.Size - UDim2.fromOffset(15, 15) }),
		Out = TweenService:Create(icon, KEYBIND_TWEEN_INFO, { Size = icon.Size }),
	}

	-- Icon changing
	maid:Add(InputUIUtil.applyKeybindIcon(icon, keyboardInput, gamepadInput))

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

	return frame
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function InputScreen.init()
	InputController.InputRegistered:Connect(function(id, keyboard, gamepad, modileButton, handler)
		local maid = Maid.new()
		registeredInputs[id] = {
			Maid = maid,
		}

		if modileButton then
			createMobileButton(id, modileButton, handler)
		end

		if keyboard or gamepad then
			local keybindLabel = createKeybindLabel(id, keyboard, gamepad)

			-- Only one of the inputs might be registered, so only show for that devide type
			if not keyboard or not gamepad then
				maid:Add(InputUtil.onInputTypeChanged(function(inputType: string)
					if inputType == InputUtil.InputTypes.Gamepad then
						keybindLabel.Visible = gamepad ~= nil
					elseif inputType == InputUtil.InputTypes.Keyboard then
						keybindLabel.Visible = keyboard ~= nil
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

		internalInputRegistered:Fire(id)
	end)

	InputController.InputUnregistered:Connect(function(id)
		local props = registeredInputs[id]
		if not props then
			return
		end

		props.Maid:Destroy()
		registeredInputs[id] = nil
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	UIController.registerScreenStateCallbacks(UI_STATE, {
		Maximize = function()
			screen.Enabled = true
		end,
		Minimize = function()
			screen.Enabled = false
		end,
	})

	screen.Enabled = true
	InputUtil.onInputTypeChanged(function(inputType: string)
		local isMobile = inputType == InputUtil.InputTypes.Touch
		keybinds.Visible = not isMobile
		mobileButtons.Visible = isMobile
	end)
end

return InputScreen
