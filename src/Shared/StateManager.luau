--!strict
local StateManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

type State = { [any]: any }
type Listener = (newState: State, oldState: State) -> ()

export type StateManager = {
	Set: (StateManager, State | (currentState: State) -> State) -> (),
	Reset: (StateManager) -> (),
	ResetIndex: (StateManager, any) -> (),
	Subscribe: (StateManager, (newState: State, oldState: State) -> ()) -> Signal.Connection<State, State>,
	Get: (StateManager) -> State | any,
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function deepClone(tbl)
	local rtn = {}
	for i, v in tbl do
		rtn[i] = type(v) == "table" and deepClone(v) or v
	end
	return rtn
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function StateManager.new(initialState: State)
	local state = {} :: StateManager

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local preservedInitState = (initialState and deepClone(initialState) or {}) :: State
	local currentState = deepClone(preservedInitState)
	local stateChanged = Signal.new() :: Signal.Signal<State, State>

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function state:Set(newState)
		local oldState = deepClone(currentState)

		if type(newState) == "table" then
			for i, v in pairs(newState) do
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

	function state:ResetIndex(index)
		local oldState = deepClone(currentState)

		if preservedInitState[index] ~= nil then
			currentState[index] = deepClone(preservedInitState[index])
		else
			currentState[index] = nil
		end

		stateChanged:Fire(currentState, oldState)
	end

	function state:Subscribe(handler: (State, State) -> ())
		task.spawn(handler, currentState, {})
		return stateChanged:Connect(handler)
	end

	-- Get a deep clone of the current state (to ensure immutability)
	function state:Get(): State
		return deepClone(currentState)
	end

	return state
end

return StateManager
