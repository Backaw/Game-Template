local InputScreen = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local SquishyButton = require(Controllers.UI.Components.SquishyButton)
local InputUtil = require(Controllers.Utils.InputUtil)
local Button = require(Controllers.UI.Components.Button)
local TemplateUtil = require(Shared.Utils.TemplateUtil)
local InputUIUtil = require(Controllers.UI.Utils.InputUIUtil)
local Maid = require(Shared.Maid)
local UIController = require(Controllers.UI.UIController)
local UIConstants = require(Controllers.UI.UIConstants)
local Signal = require(Shared.Signal)
local InputController

type MaidList = { [string]: Maid.Maid }

export type MobileButton = {
	ButtonReference: GuiButton,
	InstantiationProps: {
		Size: number,
		Position: Vector2,
		Icon: string,
		AnchorPoint: string,
	}?,
	IsToggle: boolean?,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local UI_STATE = UIConstants.States.HUD
local KEYBIND_TRANSPARENCY = 0.85
local KEYBIND_TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screen = Players.LocalPlayer.PlayerGui.Input
local keybinds = screen.Keybinds
local mobileButtons = screen.Mobile

local constructors = {
	Keybind = TemplateUtil.constructor(keybinds.TEMP_KEYBIND),
	Button = TemplateUtil.constructor(mobileButtons.TEMP_BUTTON),
}

local registeredInputs: { [string]: { Highlights: Maid.Maid | nil, Maid: Maid.Maid, IsTool: boolean? } } = {}
local internalInputRegistered = Signal.new() --> (inputId : string)

-------------------------------------------------------------------------------
-- COMMENT
-------------------------------------------------------------------------------
InputScreen.MobileButtonAnchors = {
	Left = "Left",
	Right = "Right",
	Jump = "Jump",
}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
-- If anchorType is JumpButton, the position.X is the angle in radians while the position.Y is the offset from the jump button
local function setAnchoredPosition(label: ImageButton, anchorType: string, position: Vector2)
	anchorType = anchorType or InputScreen.MobileButtonAnchors.Right
	if anchorType == InputScreen.MobileButtonAnchors.Left then
		label.AnchorPoint = Vector2.new(0, 0.5)
		label.Position = UDim2.fromOffset(position.X, position.Y)
	elseif anchorType == InputScreen.MobileButtonAnchors.Right then
		label.AnchorPoint = Vector2.new(1, 0.5)
		label.Position = UDim2.fromScale(1, 0) + UDim2.fromOffset(-position.X, position.Y)
	elseif anchorType == InputScreen.MobileButtonAnchors.Jump then
		local jumpButton: ImageButton = screen:WaitForChild("TouchGui"):WaitForChild("TouchControlFrame"):WaitForChild("JumpButton")
		local parent = label.Parent :: ScreenGui

		local uiScale = parent.UIScale.Scale
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

local function createMobileButton(id: string, mobileButton: MobileButton, handler: (Enum.UserInputState) -> ()): Maid.Maid
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
	else
		local props = mobileButton.InstantiationProps

		local buttonTemplate = constructors.Button() :: ImageButton
		buttonTemplate.Name = id
		buttonTemplate.Size = UDim2.fromScale(props.Size, props.Size)
		buttonTemplate.UICorner.CornerRadius = UDim.new(0.5, 0)
		buttonTemplate.AnchorPoint = Vector2.new(0.5, 0.5)
		-- 	buttonTemplate.Image = buttonProps.Icon :: typeof(buttonTemplate.Image)

		local icon: TextLabel = buttonTemplate.TextLabel
		local squishyButton = SquishyButton.new(buttonTemplate, buttonTemplate)
		squishyButton:SetHoverScalable(buttonTemplate)

		icon.Text = id
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
end

local function createKeybindLabel(id: string, keyboardInput: InputUtil.Input, gamepadInput: InputUtil.Input)
	local maid = registeredInputs[id].Maid

	local frame = constructors.Keybind() :: Frame
	frame.Name = id
	frame.LayoutOrder = 50
		+ (({
			[InputController.FirstClassInputs.Ragdoll] = 1,
			[InputController.FirstClassInputs.Sprint] = 2,
		})[id] or 50)
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
	InputController = require(Controllers.InputController) :: typeof(Controllers.InputController)
	InputController.InputRegistered:Connect(function(id, keyboard, gamepad, MobileButton, handler)
		local maid = Maid.new()
		registeredInputs[id] = {
			Maid = maid,
		}

		if MobileButton then
			createMobileButton(id, MobileButton, handler)
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
				if mobileButton then
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
