--!strict
local InputUIUtil = {}

local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)
local Maid = require(ReplicatedStorage.Shared.Maid)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local KeybindSprites = require(ReplicatedStorage.Client.UI.Components.KeybindSprites)
local Button = require(ReplicatedStorage.Client.UI.Components.Button)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function InputUIUtil.findNextButton(body: Frame, currentButton: ImageButton | GuiButton): ImageButton?
	local buttons = InstanceUtil.getChildrenOfClass(body, "ImageButton") :: { ImageButton }

	table.sort(buttons, function(a: ImageButton, b: ImageButton)
		return a.LayoutOrder < b.LayoutOrder
	end)

	local function loop(a: number, b: number, c: number): ImageButton?
		for i = a, b, c do
			local button = buttons[i]
			if button.Visible then
				return button
			end
		end

		return nil
	end

	local foundIndex = table.find(buttons, currentButton)
	if not foundIndex then
		error("Current button not found in list")
	end
	local startIndex = foundIndex + 1

	-- Go forward in list
	local forwardResult = loop(startIndex, #buttons, 1)
	if forwardResult then
		return forwardResult
	end

	-- Finally go backwards -2 indexes because "startIndex" is + 1
	-- and we want to start on the first index under currentIndex which is 2 below
	return loop(startIndex - 2, 1, -1)
end

function InputUIUtil.closeGamepadSelect()
	GuiService.SelectedObject = nil
end

function InputUIUtil.gamepadSelect(guiObject: GuiObject)
	if InputUtil.isGamepadInput() then
		GuiService.SelectedObject = guiObject
	end
end

function InputUIUtil.applyKeybindIcon(
	label: ImageLabel,
	keyboardInput: InputUtil.Input,
	gamepadInput: InputUtil.Input,
	displayMobileIcon: boolean?
)
	return InputUtil.onInputTypeChanged(function(inputType)
		if inputType == InputUtil.InputTypes.Gamepad then
			KeybindSprites.Gamepad:ApplySprite(gamepadInput, label)
		elseif InputUtil.isDesktop() then
			KeybindSprites.Keyboard:ApplySprite(keyboardInput, label)
		else
			if displayMobileIcon then
				KeybindSprites.Gestures:ApplySprite("Tap", label)
			else
				KeybindSprites.Gamepad:ApplySprite(nil, label)
			end
		end
	end)
end

function InputUIUtil.bindInputToButton(
	button: Button.Button,
	keyboardInput: InputUtil.Input,
	gamepadInput: InputUtil.Input,
	callback: () -> () | nil,
	icon: ImageLabel?,
	displayMobileIcon: boolean?
)
	local maid = Maid.new()

	icon = icon or button:GetGui():FindFirstChild("Input") :: ImageLabel?
	if icon then
		maid:Add(function()
			if icon then
				icon.Image = ""
			end
		end)
		maid:Add(InputUIUtil.applyKeybindIcon(icon, keyboardInput, gamepadInput, displayMobileIcon))
	end

	maid:Add(UserInputService.InputBegan:Connect(function(input, sunk)
		if sunk then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType
		if
			keycode == keyboardInput :: Enum.KeyCode
			or inputType == keyboardInput :: Enum.UserInputType
			or keycode == gamepadInput :: Enum.KeyCode
			or inputType == gamepadInput :: Enum.UserInputType
		then
			if callback then
				callback()
			else
				button.Pressed:Fire()
			end
		end
	end))

	maid:Add(UserInputService.InputEnded:Connect(function(input, sunk)
		if sunk then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType
		if
			keycode == keyboardInput :: Enum.KeyCode
			or inputType == keyboardInput :: Enum.UserInputType
			or keycode == gamepadInput :: Enum.KeyCode
			or inputType == gamepadInput :: Enum.UserInputType
		then
			if not callback then
				button.Released:Fire()
			end
		end
	end))

	return maid
end

return InputUIUtil
