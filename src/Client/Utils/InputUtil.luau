--!strict
local InputUtil = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Maid)
local AtomicValue = require(ReplicatedStorage.Shared.AtomicValue)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEVICES = {
	Console = "Console",
	Mobile = "Mobile",
	Desktop = "Desktop",
}

local INPUT_TYPES = {
	Keyboard = "Keyboard",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

-------------------------------------------------------------------------------
-- TYPE EXPORTS
-------------------------------------------------------------------------------

export type Input = Enum.KeyCode | Enum.UserInputType | nil
export type InputType = keyof<typeof(INPUT_TYPES)>
export type Device = keyof<typeof(DEVICES)>

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local currentInputType = AtomicValue.new(INPUT_TYPES.Unknown)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

InputUtil.Devices = DEVICES :: { [Device]: Device }
InputUtil.InputTypes = INPUT_TYPES :: { [InputType]: InputType }

InputUtil.CurrentInputType = currentInputType:RestrictedAccess()

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

-- Return an InputCategory based on the UserInputType
local function getCategoryOfInputType(inputType: Enum.UserInputType): InputType
	if string.find(inputType.Name, "Gamepad") then
		return InputUtil.InputTypes.Gamepad
	elseif inputType == Enum.UserInputType.Keyboard or string.find(inputType.Name, "Mouse") then
		return InputUtil.InputTypes.Keyboard
	elseif inputType == Enum.UserInputType.Touch then
		return InputUtil.InputTypes.Touch
	else
		return InputUtil.InputTypes.Unknown
	end
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function InputUtil.getDeviceType(): string
	if GuiService:IsTenFootInterface() then
		return InputUtil.Devices.Console
	elseif UserInputService.TouchEnabled and UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return InputUtil.Devices.Mobile
	else
		return InputUtil.Devices.Desktop
	end
end

function InputUtil.isMobile()
	return InputUtil.getDeviceType() == InputUtil.Devices.Mobile
end

function InputUtil.isConsole()
	return InputUtil.getDeviceType() == InputUtil.Devices.Console
end

function InputUtil.isDesktop()
	return InputUtil.getDeviceType() == InputUtil.Devices.Desktop
end

function InputUtil.isGamepadInput()
	return UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
end

function InputUtil.isPrimaryClickInput()
	local lastInputType = UserInputService:GetLastInputType()
	return lastInputType == Enum.UserInputType.MouseButton1 or lastInputType == Enum.UserInputType.Touch
end

function InputUtil.listenToKeyInput(
	handler: (Enum.UserInputState) -> (),
	keyboardMouseInput: Input,
	gamepadInput: Input,
	overrideGameInput: boolean?
): Maid.Maid?
	if not (keyboardMouseInput or gamepadInput) then
		return nil
	end

	local maid = Maid.new()
	local lastInput: InputObject?

	maid:Add(UserInputService.InputBegan:Connect(function(input, sunk)
		if sunk and not overrideGameInput then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType

		local valid = keycode == keyboardMouseInput :: Enum.KeyCode
			or inputType == keyboardMouseInput :: Enum.UserInputType
			or keycode == gamepadInput :: Enum.KeyCode
			or inputType == gamepadInput :: Enum.UserInputType

		if valid then
			if lastInput == input then
				handler(Enum.UserInputState.End)
			end

			lastInput = input
			handler(Enum.UserInputState.Begin)
		end
	end))

	maid:Add(UserInputService.InputEnded:Connect(function(input, sunk)
		if sunk and not overrideGameInput then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType

		local valid = keycode == keyboardMouseInput :: Enum.KeyCode
			or inputType == keyboardMouseInput :: Enum.UserInputType
			or keycode == gamepadInput :: Enum.KeyCode
			or inputType == gamepadInput :: Enum.UserInputType

		if input == lastInput and valid then
			lastInput = nil
			handler(Enum.UserInputState.End)
		end
	end))

	-- Fixes issue with pressing button, opening roblox menu, ending press and then closing
	maid:Add(GuiService.MenuOpened:Connect(function()
		if lastInput then
			lastInput = nil
			handler(Enum.UserInputState.End)
		end
	end))

	return maid
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
	do
		-- Determine a default input category based on the current peripherals
		local lastInputType = UserInputService:GetLastInputType()
		local lastInputCategory = getCategoryOfInputType(lastInputType)
		local newInputType: InputType
		if lastInputCategory ~= InputUtil.InputTypes.Unknown then
			newInputType = lastInputCategory
		else
			if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
				newInputType = InputUtil.InputTypes.Keyboard
			elseif UserInputService.TouchEnabled then
				newInputType = InputUtil.InputTypes.Touch
			elseif UserInputService.GamepadEnabled then
				newInputType = InputUtil.InputTypes.Gamepad
			else
				warn("No input devices detected!")
				newInputType = "Unknown"
			end
		end

		currentInputType:Set(newInputType)
	end

	UserInputService.LastInputTypeChanged:Connect(function(inputType: Enum.UserInputType)
		local inputCategory = getCategoryOfInputType(inputType)
		if inputCategory ~= InputUtil.InputTypes.Unknown then
			currentInputType:Set(inputCategory)
		end
	end)
end

return InputUtil
