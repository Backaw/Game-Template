--!strict
local StateMachine = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type StateMachine<T> = {
	RegisterGlobalCallback: (StateMachine<T>, callback: (fromState: T, toState: T) -> ()) -> Signal.Connection<T, T>,
	RegisterStateCallbacks: (StateMachine<T>, state: T, onOpen: (() -> ())?, onClose: (() -> ())?) -> Signal.Connection<T, T>,
	GetState: (StateMachine<T>) -> T,
	Push: (StateMachine<T>, state: T) -> (),
	ReplaceUpTill: (StateMachine<T>, replacee: T, to: T) -> (),
	Pop: (StateMachine<T>) -> (),
	PopIfOnTop: (StateMachine<T>, state: T) -> (),
	PopIfNotOnTop: (StateMachine<T>, state: T) -> (),
	HasState: (StateMachine<T>, state: T) -> boolean,
	PopUpToInclusive: (StateMachine<T>, state: T, exceptions: { T }?) -> (),
	PopUpToExclusive: (StateMachine<T>, state: T, exceptions: { T }?) -> (),
	Remove: (StateMachine<T>, state: T) -> (),
	GetStack: (StateMachine<T>) -> { T },
	Clear: (StateMachine<T>) -> (),
	Destroy: (StateMachine<T>) -> (),
	ToggleLock: (StateMachine<T>, toggle: boolean) -> (),
}

function StateMachine.new<T>(states: { T }, initialState: T)
	local stateMachine = {} :: StateMachine<T>

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local stack: { T } = {
		initialState,
	}

	local changed = Signal.new() :: Signal.Signal<T, T>
	local locked = false

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------

	local function doesStateExist(state: string)
		if not table.find(states, state) then
			error(("State (%s) does not exist in the state machine"):format(state))
		end
	end

	local function canChangeState()
		if locked then
			warn("State machine is locked")
			return false
		end
		return true
	end

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------

	function stateMachine:RegisterGlobalCallback(callback)
		return changed:Connect(callback)
	end

	function stateMachine:RegisterStateCallbacks(state, onOpen, onClose)
		doesStateExist(state)

		return stateMachine:RegisterGlobalCallback(function(fromState: string, toState: string)
			if toState == state and onOpen then
				onOpen()
			elseif fromState == state and onClose then
				onClose()
			end
		end)
	end

	--[[
        Returns the current state
    ]]
	function stateMachine:GetState()
		return stack[#stack]
	end

	function stateMachine:ToggleLock(toggle: boolean)
		locked = toggle
	end

	--[[
		Puts a state at the top of a stack
	]]
	function stateMachine:Push(state)
		doesStateExist(state)
		if not canChangeState() then
			return
		end

		-- ERROR: State already in stack
		if stateMachine:HasState(state) then
			error(("State (%s) cannot be pushed, it already exists in the stack, use Remove() to remove it"):format(state))
		end

		local lastState = stack[#stack]

		table.insert(stack, state)

		if changed then
			changed:Fire(lastState, state)
		end
	end

	--[[
		Pops up till to is reached but not popped and then pushes state in one operation; so callbacks run once
	]]
	function stateMachine:ReplaceUpTill(replacee, to)
		doesStateExist(replacee)
		if not canChangeState() then
			return
		end

		-- ERROR: State already in stack
		if stateMachine:HasState(replacee) then
			error(("State (%s) cannot be pushed, it already exists in the stack, use Remove() to remove it"):format(replacee))
		end

		-- ERROR: State isn't in the stack
		if not stateMachine:HasState(to) then
			error(("Can't pop to (%s) because it isn't in the stack"):format(replacee))
		end

		while stateMachine:HasState(replacee) do
			stateMachine:Pop()
		end

		local lastState = stack[#stack]

		local newLength = (table.find(stack, to) :: number) + 1
		for i = #stack, newLength, -1 do
			table.remove(stack, i)
		end

		stack[newLength] = replacee

		if changed then
			changed:Fire(lastState, replacee)
		end
	end

	--[[
        Removes whatever state at the top of the stack
    ]]
	function stateMachine:Pop()
		if not canChangeState() then
			return
		end

		-- ERROR: Can't pop the nothing state
		if #stack == 1 then
			error("Stack is empty, can't pop the nothing state")
		end

		local fromState = stack[#stack]
		table.remove(stack, #stack)

		if changed then
			changed:Fire(fromState, stack[#stack])
		end
	end

	function stateMachine:PopIfOnTop(state)
		if stateMachine:GetState() == state then
			stateMachine:Pop()
		end
	end

	function stateMachine:PopIfNotOnTop(state)
		if stateMachine:GetState() ~= state then
			stateMachine:Pop()
		end
	end

	function stateMachine:HasState(state)
		return table.find(stack, state) ~= nil
	end

	--[[
		state itself is also popped
	]]
	function stateMachine:PopUpToInclusive(state, exceptions)
		if not canChangeState() then
			return
		end

		-- ERROR: State isn't in the stack
		if not stateMachine:HasState(state) then
			error(("Can't pop to (%s) because it isn't in the stack"):format(state))
		end

		local currentStack = stateMachine:GetStack()
		for i = #currentStack, 1, -1 do
			local removing = currentStack[i]

			if not exceptions or not table.find(exceptions, removing) then
				stateMachine:Remove(removing)
			end

			if removing == state then
				return
			end
		end
	end

	--[[
		state itself is not popped
	]]
	function stateMachine:PopUpToExclusive(state, exceptions)
		if not canChangeState() then
			return
		end

		-- ERROR: State isn't in the stack
		if not stateMachine:HasState(state) then
			error(("Can't pop to (%s) because it isn't in the stack"):format(state))
		end

		local currentStack = stateMachine:GetStack()
		for i = #currentStack, 1, -1 do
			local removing = currentStack[i]
			if removing == state then
				return
			end

			if not exceptions or not table.find(exceptions, removing) then
				stateMachine:Remove(removing)
			end
		end
		--[[
			while stateMachine:GetState() ~= state do
				stateMachine:Pop()
			end
		*]]
	end

	function stateMachine:Remove(state)
		if not canChangeState() then
			return
		end

		doesStateExist(state)

		-- RETURN: State isn't in stack
		local index = table.find(stack, state)
		if not index then
			return
		end

		if stateMachine:GetState() == state then
			stateMachine:Pop()
		else
			table.remove(stack, index)
		end
	end

	function stateMachine:GetStack()
		return TableUtil.deepClone(stack)
	end

	function stateMachine:Clear()
		if not canChangeState() then
			return
		end

		stateMachine:PopUpToInclusive(initialState)
	end

	function stateMachine:Destroy()
		changed:Destroy()
	end

	return stateMachine
end

return StateMachine
