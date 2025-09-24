--!strict
local UIController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StateMachine = require(ReplicatedStorage.Shared.StateMachine)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local DeferredPromise = require(ReplicatedStorage.Shared.DeferredPromise)
local Promise = require(ReplicatedStorage.Shared.Packages.Promise)
local UIUtil = require(ReplicatedStorage.Client.UI.Utils.UIUtil)

type ScreenStateCallback = (({ any }?) -> any)?
type ScreenStateCallbacks = {
	Boot: ScreenStateCallback,
	Shutdown: ScreenStateCallback,
	Minimize: ScreenStateCallback,
	Maximize: ScreenStateCallback,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local uiStateMachine =
	StateMachine.new(TableUtil.toArray(UIConstants.States), UIConstants.InitialState :: UIConstants.State) :: StateMachine.StateMachine<UIConstants.State>
local lastUiStateStack = uiStateMachine:GetStack()

local screenStateCallbacks: { [string]: ScreenStateCallbacks } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
UIController.ScreenStateTransition = Promise.resolve() :: DeferredPromise.DeferredPromise

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function UIController.getStateMachine()
	return uiStateMachine
end

function UIController.registerScreenStateCallbacks(state: UIConstants.State, callbacks: ScreenStateCallbacks)
	if not UIConstants.States[state] then
		warn(("%s is an invalid screen state"):format(state))
	end
	screenStateCallbacks[state] = callbacks
end

function UIController.init()
	for _, descendant in (ReplicatedStorage.Client.UI:GetDescendants()) do
		if descendant:IsA("ModuleScript") and StringUtil.endsWith(descendant.Name, "Screen") then
			local _ = require(descendant) :: any
		end
	end
end

function UIController.toggleScreenState(state: UIConstants.State)
	local currentState = uiStateMachine:GetState()

	if currentState == state then
		uiStateMachine:Pop()
	elseif UIUtil.isState(currentState, "HUD") then
		uiStateMachine:Push(state)
	elseif uiStateMachine:HasState(state) then
		uiStateMachine:PopUpToExclusive(state)
	else
		uiStateMachine:ReplaceUpTill(state, "HUD")
	end
end

function UIController.openScreenState(state: UIConstants.State)
	if uiStateMachine:GetState() ~= state then
		UIController.toggleScreenState(state)
	end
end

function UIController.resetToHUD()
	if UIUtil.isStackHUDPermissive(uiStateMachine:GetStack()) then
		uiStateMachine:PopUpToExclusive(UIConstants.States.HUD)
	end
end

uiStateMachine:RegisterGlobalCallback(function(fromState, toState, data)
	local stack = uiStateMachine:GetStack()
	UIController.ScreenStateTransition = DeferredPromise.new()

	-- Seperate loops so that open is garuanteed to run first, helps PromptUtil background transitions not be choppy
	for state, callbacks in screenStateCallbacks do
		if state == toState then
			if not table.find(lastUiStateStack, state) and callbacks.Boot then
				local success, err = pcall(callbacks.Boot, data)
				if not success then
					warn(err)
				end
			end

			if callbacks.Maximize then
				local success, err = pcall(callbacks.Maximize, data)
				if not success then
					warn(err)
				end
			end
		end
	end

	for state, callbacks in screenStateCallbacks do
		if fromState == state then
			if callbacks.Minimize then
				local success, err = pcall(callbacks.Minimize)
				if not success then
					warn(err)
				end
			end
		end

		if not table.find(stack, state) and table.find(lastUiStateStack, state) then -- Closed or removed
			if callbacks.Shutdown then
				local success, err = pcall(callbacks.Shutdown)
				if not success then
					warn(err)
				end
			end
		end
	end

	lastUiStateStack = stack
	UIController.ScreenStateTransition.invokeResolve()
end)

do
	Players.LocalPlayer.PlayerGui.Components.Enabled = false
end

return UIController
