local InputUtil = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Remotes = require(Paths.Shared.Remotes)
local Signal = require(Paths.Shared.Signal)
local Maid = require(Paths.Shared.Maid)

export type Input = Enum.KeyCode | Enum.UserInputType | nil

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------
local currentInputType: string

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
InputUtil.DEVICES = {
	Console = "Console",
	Mobile = "Mobile",
	Desktop = "Desktop",
}

InputUtil.InputTypes = {
	Keyboard = "Keyboard",
	Gamepad = "Gamepad",
	Touch = "Touch",
	Unknown = "Unknown",
}

InputUtil.InputTypeChanged = Signal.new() --> (new: string, old : string )

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------
-- Return an InputCategory based on the UserInputType
local function getCategoryOfInputType(inputType: Enum.UserInputType)
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
		return InputUtil.DEVICES.Console
	elseif UserInputService.TouchEnabled and UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return InputUtil.DEVICES.Mobile
	else
		return InputUtil.DEVICES.Desktop
	end
end

function InputUtil.isMobile()
	return InputUtil.getDeviceType() == InputUtil.DEVICES.Mobile
end

function InputUtil.isConsole()
	return InputUtil.getDeviceType() == InputUtil.DEVICES.Console
end

function InputUtil.isDesktop()
	return InputUtil.getDeviceType() == InputUtil.DEVICES.Desktop
end

function InputUtil.isGamepadInput()
	return UserInputService:GetLastInputType().Name:find("Gamepad") ~= nil
end

function InputUtil.isPrimaryClickInput()
	local lastInputType = UserInputService:GetLastInputType()
	return lastInputType == Enum.UserInputType.MouseButton1 or lastInputType == Enum.UserInputType.Touch
end

function InputUtil.getInputType()
	return currentInputType
end

function InputUtil.onInputTypeChanged(handler: (string) -> ())
	handler(currentInputType)
	return InputUtil.InputTypeChanged:Connect(handler)
end

function InputUtil.listenToKeyInput(
	handler: (Enum.UserInputState) -> (),
	keyboardMouseInput: Input,
	gamepadInput: Input,
	overrideGameInput: boolean?
): Maid.Maid
	if not (keyboardMouseInput or gamepadInput) then
		return
	end

	local maid = Maid.new()
	local lastInput: InputObject?

	maid:Add(UserInputService.InputBegan:Connect(function(input, sunk)
		if sunk and not overrideGameInput then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType

		local valid = keycode == keyboardMouseInput
			or inputType == keyboardMouseInput
			or keycode == gamepadInput
			or inputType == gamepadInput

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

		local valid = keycode == keyboardMouseInput
			or inputType == keyboardMouseInput
			or keycode == gamepadInput
			or inputType == gamepadInput

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
	UserInputService.LastInputTypeChanged:Connect(function(inputType: Enum.UserInputType)
		local inputCategory = getCategoryOfInputType(inputType)
		if inputCategory ~= InputUtil.InputTypes.Unknown and inputCategory ~= currentInputType then
			local lastInputType = currentInputType
			currentInputType = inputCategory
			InputUtil.InputTypeChanged:Fire(currentInputType, lastInputType)
		end
	end)

	-- Determine a default input category based on the current peripherals
	local lastInputType = UserInputService:GetLastInputType()
	local lastInputCategory = getCategoryOfInputType(lastInputType)

	if lastInputCategory ~= InputUtil.InputTypes.Unknown then
		currentInputType = lastInputCategory
	else
		if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
			currentInputType = InputUtil.InputTypes.Keyboard
		elseif UserInputService.TouchEnabled then
			currentInputType = InputUtil.InputTypes.Touch
		elseif UserInputService.GamepadEnabled then
			currentInputType = InputUtil.InputTypes.Gamepad
		else
			warn("No input devices detected!")
			currentInputType = InputUtil.InputTypes.Unknown
		end
	end
end

local screenSize = (Paths.UI.HUD :: ScreenGui).AbsoluteSize
Remotes.fireServer("DeviceDetermined", ("%s (%sx%s)"):format(InputUtil.getDeviceType(), screenSize.X, screenSize.Y))

return InputUtil
