local InputUIUtil = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local InputUtil = require(Paths.Controllers.Utils.InputUtil)
local KeybindSprites = require(Paths.Controllers.UI.KeybindSprites)
local Button = require(Paths.Controllers.UI.Components.Button)
local Maid = require(Paths.Shared.Maid)

function InputUIUtil.findNextButton(body: Frame, currentButton: ImageButton | GuiButton)
	local buttons = InstanceUtil.getChildrenOfClass(body, "ImageButton")

	table.sort(buttons, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	local function loop(a: number, b: number, c: number)
		for i = a, b, c do
			local btn = buttons[i]
			if btn.Visible then
				return btn
			end
		end
	end

	local startIndex = table.find(buttons, currentButton) + 1

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
	GuiService.SelectedObject = nil :: Instance
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

	icon = icon or button:GetGuiObject():FindFirstChild("Input")
	if icon then
		maid:Add(function()
			icon.Image = "" :: typeof(icon.Image)
		end)
		maid:Add(InputUIUtil.applyKeybindIcon(icon, keyboardInput, gamepadInput, displayMobileIcon))
	end

	maid:Add(UserInputService.InputBegan:Connect(function(input, sunk)
		if sunk then
			return
		end

		local keycode = input.KeyCode
		local inputType = input.UserInputType
		if keycode == keyboardInput or inputType == keyboardInput or keycode == gamepadInput or inputType == gamepadInput then
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
		if keycode == keyboardInput or inputType == keyboardInput or keycode == gamepadInput or inputType == gamepadInput then
			if not callback then
				button.Released:Fire()
			end
		end
	end))

	return maid
end

return InputUIUtil
