local StateMachine = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)
local Signal = require(ReplicatedStorage.Modules.Signal)

function StateMachine.new(states: { string }, initialState: string)
	local stateMachine = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local stack: { string } = {
		initialState,
	}

	local currentData: table
	local changed = Signal.new()

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------
	local function doesStateExist(state: string)
		if not table.find(states, state) then
			error(("State (%s) does not exist in the state machine"):format(state))
		end
	end

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------
	function stateMachine:RegisterGlobalCallback(callback: (fromState: string, toState: string, data: table) -> ())
		return changed:Connect(callback)
	end

	function stateMachine:RegisterStateCallbacks(state: string, onOpen: (table) -> ()?, onClose: (table) -> ()?)
		doesStateExist(state)

		return stateMachine:RegisterGlobalCallback(function(fromState: string, toState: string, data: table)
			if toState == state and onOpen then
				onOpen(data)
			elseif fromState == state and onClose then
				onClose(data)
			end
		end)
	end

	--[[
        Returns the current state
    ]]
	function stateMachine:GetState(): string
		return stack[#stack]
	end

	--[[
		Puts a state at the top of a stack
	]]
	function stateMachine:Push(state: string, data: table?)
		doesStateExist(state)

		-- ERROR: State already in stack
		if stateMachine:HasState(state) then
			error(("State (%s) cannot be pushed, it already exists in the stack, use Remove() to remove it"):format(state))
		end

		local lastState = stack[#stack]

		table.insert(stack, state)
		currentData = data or {}

		if changed then
			changed:Fire(lastState, state, currentData)
		end
	end

	--[[
		Pops up till to is reached but not popped and then pushes state in one operation; so callbacks run once
	]]
	function stateMachine:ReplaceUpTill(replacee: string, to: string, data: table?)
		doesStateExist(replacee)

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

		local newLength = table.find(stack, to) + 1
		for i = #stack, newLength, -1 do
			table.remove(stack, i)
		end

		stack[newLength] = replacee
		currentData = data or {}

		if changed then
			changed:Fire(lastState, replacee, currentData)
		end
	end

	--[[
        Removes whatever state at the top of the stack
    ]]
	function stateMachine:Pop()
		-- ERROR: Can't pop the nothing state
		if #stack == 1 then
			error("Stack is empty, can't pop the nothing state")
		end

		currentData = {}

		local fromState = stack[#stack]
		table.remove(stack, #stack)

		if changed then
			changed:Fire(fromState, stack[#stack])
		end
	end

	function stateMachine:PopIfOnTop(state: string)
		if stateMachine:GetState() == state then
			stateMachine:Pop()
		end
	end

	function stateMachine:PopIfNotOnTop(state: string)
		if stateMachine:GetState() ~= state then
			stateMachine:Pop()
		end
	end

	function stateMachine:HasState(state: string)
		return table.find(stack, state) ~= nil
	end

	--[[
		state itself is also popped
	]]
	function stateMachine:PopUpToInclusive(state: string, exceptions: { string }?)
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
	function stateMachine:PopUpToExclusive(state: string, exceptions: { string }?)
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

	function stateMachine:Remove(state: string)
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

	function stateMachine:GetData()
		return currentData
	end

	function stateMachine:GetStack()
		return TableUtil.deepClone(stack)
	end

	function stateMachine:Clear()
		stateMachine:PopUpToInclusive(initialState)
	end

	function stateMachine:Destroy()
		changed:Destroy()
		changed = nil
	end

	return stateMachine
end

return StateMachine
