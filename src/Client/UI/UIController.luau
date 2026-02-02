--!strict
local UIController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local DeferredPromise = require(Shared.DeferredPromise)
local StringUtil = require(Shared.Utils.StringUtil)
local UIConstants = require(Client.UI.UIConstants)
local StateMachine = require(Shared.StateMachine)
local TableUtil = require(Shared.Utils.TableUtil)
local Promise = require(Shared.Promise)
local UIUtil = require(Client.UI.Utils.UIUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type ScreenStateCallback = (({ any }?) -> ())?
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

local screenStateCallbacks: { [UIConstants.State]: ScreenStateCallbacks } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

UIController.ScreenStateTransition = Promise.resolved() :: DeferredPromise.DeferredPromise

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
	for _, parent in { ReplicatedStorage.Client.UI, ReplicatedStorage.Client.UI } do
		for _, descendant in parent:GetDescendants() do
			if descendant:IsA("ModuleScript") and StringUtil.endsWith(descendant.Name, "Screen") then
				local _ = require(descendant) :: any
			end
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

function UIController.resetToHUD(exceptions: { UIConstants.State }?)
	if exceptions and table.find(exceptions, uiStateMachine:GetState()) then
		return
	end

	if UIUtil.isStackHUDPermissive(uiStateMachine:GetStack()) then
		uiStateMachine:PopUpToExclusive(UIConstants.States.HUD)
	end
end

uiStateMachine:RegisterGlobalCallback(function(fromState, toState)
	local stack = uiStateMachine:GetStack()
	UIController.ScreenStateTransition = DeferredPromise.new()

	-- Seperate loops so that open is garuanteed to run first, helps PromptUtil background transitions not be choppy
	for state, callbacks in screenStateCallbacks do
		if state == toState then
			if not table.find(lastUiStateStack, state) and callbacks.Boot then
				local success, err = pcall(callbacks.Boot :: any)
				if not success then
					warn(err)
				end
			end

			if callbacks.Maximize then
				local success, err = pcall(callbacks.Maximize :: any)
				if not success then
					warn(err)
				end
			end
		end
	end

	for state, callbacks in screenStateCallbacks do
		if fromState == state then
			if callbacks.Minimize then
				local success, err = pcall(callbacks.Minimize :: any)
				if not success then
					warn(err)
				end
			end
		end

		if not table.find(stack, state) and table.find(lastUiStateStack, state) then -- Closed or removed
			if callbacks.Shutdown then
				local success, err = pcall(callbacks.Shutdown :: any)
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
	-- 	require(ReplicatedStorage.Client.UI.Screens.DebugScreen).write("Version", game.PlaceVersion)
	local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if playerGui then
		playerGui.Components.Enabled = false
	end
end

return UIController
