--// File: StateManager.luau
--// Created on: 9-1-2025
--// Author: SixthAtom

local StateManager = {}

local Signal = require(script.Parent.Signal)

--[[----------------------------
   TYPES
----------------------------]]

export type State = typeof(StateManager.new())
type NewState = { [any]: any }
type OldState = { [any]: any }
type Listener = (newState: NewState, oldState: OldState) -> ()

--[[----------------------------
   PRIVATE METHODS
----------------------------]]

local function deepClone(tbl)
	local rtn = {}
	for i, v in tbl do
		rtn[i] = type(v) == "table" and deepClone(v) or v
	end
	return rtn
end

--[[----------------------------
   CONSTRUCTOR
----------------------------]]

function StateManager.new(initialState: NewState)
	local state = {}

	--[[----------------------------
	   PRIVATE MEMBERS
	----------------------------]]

	local preservedInitState = initialState and deepClone(initialState) or {}
	local currentState = deepClone(preservedInitState)
	local stateChanged = Signal.new()

	--[[----------------------------
	   PUBLIC METHODS
	----------------------------]]

	function state:Set(newState: NewState | (currentState: OldState) -> NewState)
		local oldState = deepClone(currentState)

		if type(newState) == "table" then
			for i, v in newState do
				currentState[i] = v
			end
		elseif type(newState) == "function" then
			local computedState = newState(currentState)
			for i, v in computedState do
				currentState[i] = v
			end
		else
			error("State: Set only accepts a table or a function")
		end

		stateChanged:Fire(currentState, oldState)
	end

	-- Reset the state to it's initial state
	function state:Reset()
		local oldState = deepClone(currentState)
		currentState = deepClone(preservedInitState)
		stateChanged:Fire(currentState, oldState)
	end

	function state:ResetIndex(index: any)
		local oldState = deepClone(currentState)

		if preservedInitState[index] ~= nil then
			currentState[index] = deepClone(preservedInitState[index])
		else
			currentState[index] = nil
		end

		stateChanged:Fire(currentState, oldState)
	end

	function state:Subscribe(handler: (NewState | any, OldState | any) -> ())
		task.spawn(handler, currentState, {})
		return stateChanged:Connect(handler)
	end

	-- Get a deep clone of the current state (to ensure immutability)
	function state:Get(): OldState | any
		return deepClone(currentState)
	end

	return state
end

return StateManager
