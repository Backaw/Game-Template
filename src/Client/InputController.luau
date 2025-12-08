--!strict
local InputController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Toggle = require(ReplicatedStorage.Shared.Toggle)
local Maid = require(ReplicatedStorage.Shared.Maid)
local Signal = require(ReplicatedStorage.Shared.Signal)
local UIController = require(ReplicatedStorage.Client.UI.UIController)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local LoadingController = require(ReplicatedStorage.Client.LoadingController)
local InputConstants = require(ReplicatedStorage.Shared.Constants.InputConstants)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Input = InputUtil.Input

type Id = string
type Handler = (Enum.UserInputState) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local UI_STATE = UIConstants.States.HUD :: UIConstants.State
local OVERRIDE_JOB = "Override"

local inputMaid = Maid.new()

local enabledInputs: { [Id]: Toggle.Toggle } = {} -- These are for toggling inputs on & off.
local disableAllInputs = Toggle.new(false)

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

InputController.InputSunk = Signal.new() :: Signal.Signal<string, Enum.UserInputState>
InputController.InputRegistered = Signal.new() :: Signal.Signal<string, Input, Input, InputConstants.MobileInputButton?, Handler>
InputController.InputUnregistered = Signal.new() :: Signal.Signal<string>

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function InputController.registerInputs(inputList: {
	[Id]: { Keyboard: Input, Gamepad: Input, MobileButtonProps: InputConstants.MobileInputButton?, Handler: Handler },
})
	for id, data in inputList do
		InputController.registerInput(id, data.Keyboard, data.Gamepad, data.MobileButtonProps, data.Handler)
	end
end

function InputController.registerInput(
	id: Id,
	keyboard: Input,
	gamepad: Input,
	mobileButtonProps: InputConstants.MobileInputButton? | nil,
	handler: Handler,
	overrideGameInput: boolean?
)
	LoadingController.Loaded:andThen(function()
		local function _handler(inputState: Enum.UserInputState)
			if uiStateMachine:GetState() ~= UI_STATE then
				return
			end

			if not enabledInputs[id]:Get() then
				return
			end

			InputController.InputSunk:Fire(id, inputState)
			handler(inputState)
		end

		local toggle = Toggle.new(true)
		enabledInputs[id] = toggle

		-- Only for keyboard and gamepad inputs
		-- Mobile handling is done in the InputScreen
		if keyboard or gamepad then
			inputMaid:Add(InputUtil.listenToKeyInput(_handler, keyboard, gamepad, overrideGameInput), id)
		end
		InputController.InputRegistered:Fire(id, keyboard, gamepad, mobileButtonProps, _handler)

		if disableAllInputs:Get() then
			toggle:Set(OVERRIDE_JOB, false)
		end
	end)
end

function InputController.unregisterInput(id: Id)
	inputMaid:RemoveIfExits(id)
	InputController.InputUnregistered:Fire(id)
end

function InputController.unregisterInputs(idList: { [string]: Id })
	for _, id in idList do
		InputController.unregisterInput(id)
	end
end

function InputController.toggleInput(id: Id, job: string, toggle: boolean?)
	LoadingController.Loaded:andThen(function()
		if enabledInputs[id] then
			enabledInputs[id]:Set(job, toggle or not enabledInputs[id]:Get())
		else
			warn("INPUT NOT FOUND", id, job, toggle)
		end
	end)
end

function InputController.getInputToggledSignal(id: Id)
	return enabledInputs[id].Changed
end

function InputController.toggleAllInputs(job: string, toggle: boolean?)
	disableAllInputs:Set(job, toggle or not disableAllInputs:Get())
end

function InputController.getToggle(id: Id)
	if enabledInputs[id] then
		return enabledInputs[id]:Get()
	end
	return false
end

function InputController.Destroy(id: Id)
	InputController.unregisterInput(id)
	enabledInputs[id] = nil
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

disableAllInputs.Changed:Connect(function(isToggled)
	for _, toggle in enabledInputs do
		toggle:Set(OVERRIDE_JOB, not isToggled)
	end
end)

return InputController
