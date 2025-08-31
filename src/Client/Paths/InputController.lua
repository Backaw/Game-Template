local InputController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local Shared = ReplicatedStorage.Modules
local Toggle = require(Shared.Toggle)
local Maid = require(Shared.Maid)
local Signal = require(Shared.Signal)
local UIController = require(Controllers.UI.UIController)
local UIConstants = require(Controllers.UI.UIConstants)
local InputUtil = require(Controllers.Utils.InputUtil)
local CharacterController = require(Controllers.Character.CharacterController)
local CharacterUtil = require(Shared.Character.CharacterUtil)
local InputScreen = require(Controllers.UI.Screens.InputScreen)
local Paths = require(Controllers)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------
export type Input = InputUtil.Input
export type MobileButtonProps = InputScreen.MobileButton

type Id = string
type Handler = (Enum.UserInputState) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local UI_STATE = UIConstants.States.HUD
local OVERRIDE_JOB = "Override"

local inputMaid = Maid.new()

local enabledInputs: { [Id]: Toggle.Toggle } = {} -- These are for toggling inputs on & off.
local disableAllInputs = Toggle.new(false)

local uiStateMachine = UIController.getStateMachine()

local player = Players.LocalPlayer

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
InputController.FirstClassInputs = {}

InputController.InputSunk = Signal.new() --> (inputId : string, inputState : Enum.UserInputState)
InputController.CooldownToggled = Signal.new() --> (inputId : string, toggle : boolean, duration : number?)
InputController.InputRegistered = Signal.new() --> (inputId : string, keyboard: Input, gamepad: Input, mobileButtonProps: InputScreen.MobileButtonProps ?, handler: Handler)
InputController.InputUnregistered = Signal.new() --> (inputId : string)

InputController.MobileButtonAnchors = InputScreen.MobileButtonAnchors

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function InputController.registerInputs(inputList: {
	[Id]: { Keyboard: Input, Gamepad: Input, MobileButtonProps: InputScreen.MobileButton?, Handler: Handler },
})
	for id, data in inputList do
		InputController.registerInput(id, data.Keyboard, data.Gamepad, data.MobileButtonProps, data.Handler)
	end
end

function InputController.registerInput(
	id: Id,
	keyboard: Input,
	gamepad: Input,
	mobileButtonProps: InputScreen.MobileButton? | nil,
	handler: Handler,
	overrideGameInput: boolean?
)
	Paths.Initialized:andThen(function()
		local function _handler(inputState: Enum.UserInputState)
			if uiStateMachine:GetState() ~= UI_STATE then
				return
			end

			if not CharacterUtil.isAlive(player) then
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
	if enabledInputs[id] then
		enabledInputs[id]:Set(job, toggle or not enabledInputs[id]:Get())
	end
end

function InputController.getInputToggledSignal(id)
	return enabledInputs[id].Changed
end

function InputController.toggleAllInputs(job: string, toggle: boolean?)
	disableAllInputs:Set(job, toggle or not disableAllInputs:Get())
end

function InputController.getToggle(id: string)
	if enabledInputs[id] then
		return enabledInputs[id]:Get()
	end
end

function InputController.Destroy(id: string)
	InputController.unregisterInput(id)
	enabledInputs[id] = nil
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- CHARACTER
do
	CharacterController.registerUnloadCallback(function()
		-- idk this was empty lol
	end)
end

disableAllInputs.Changed:Connect(function(isToggled)
	for _, toggle in enabledInputs do
		toggle:Set(OVERRIDE_JOB, not isToggled)
	end
end)

return InputController
