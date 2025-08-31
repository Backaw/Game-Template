local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Signal)

local StateMachine = {}

type State = {
	Name: string,
	Run: (State) -> (),
	Stop: (State) -> (),
}
type Condition = {
	TransitionState: string,
	Evaluate: (number) -> boolean,
}

export type Handler = ((number?) -> ()) | nil

function StateMachine.new(stateNames: { string }, conditionNames: { string }, doDebug: boolean?)
	local stateMachine = {}

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local states: { [string]: State } = {}
	local conditions: { [string]: Condition } = {}

	local stateToConditions: { [string]: { string } } = {}
	local conditionsToTransitionState: { [string]: string } = {}

	local activeState: State?, onUpdate: ((number) -> ()) | nil

	-------------------------------------------------------------------------------
	-- PUBLIC VARIABLES
	-------------------------------------------------------------------------------
	stateMachine.Changed = Signal.new() --> (newState : string?, lastState : string?)

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------
	local function verifyStateValidity(name: string)
		if not table.find(stateNames, name) then
			error(("%s is not a valid state"):format(name))
		end
	end

	local function verifyConditionValidity(name: string)
		if not table.find(conditionNames, name) then
			error(("%s is not a valid condition"):format(name))
		end
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------
	function stateMachine:BindState(
		name: string,
		linkedConditions: { string },
		initHandler: Handler,
		actionHandler: Handler,
		closeHandler: Handler
	)
		verifyStateValidity(name)

		stateToConditions[name] = linkedConditions

		local function run(dt)
			--check conditions
			for _, conditionName in pairs(linkedConditions) do
				local condition = conditions[conditionName]
				--print("Checking " .. condition.Name)
				if condition.Evaluate(dt) then
					if doDebug then
						warn(("%s is true. Switching state to %s "):format(conditionName, condition.TransitionState))
					end

					stateMachine:SwitchState(condition.TransitionState)
					return
				end
			end

			--if no conditions satisfied, perform action
			if actionHandler then
				actionHandler(dt)
			end
		end

		states[name] = {
			Name = name,
			Run = function()
				if onUpdate == run then
					error("No bueno")
				end

				onUpdate = run

				if initHandler then
					initHandler()
				end
			end,
			Stop = function()
				if onUpdate ~= run then
					error("No bueno 2 ")
				end

				if closeHandler then
					closeHandler()
				end

				onUpdate = nil
			end,
		}
	end

	function stateMachine:RegisterCondition(name: string, transitionState: string, evaluate: (number) -> boolean)
		verifyConditionValidity(name)
		verifyStateValidity(transitionState)

		conditionsToTransitionState[name] = transitionState

		conditions[name] = {
			Evaluate = evaluate,
			TransitionState = transitionState,
		}
	end

	function stateMachine:SwitchState(name: string)
		local lastStateName
		if activeState then
			lastStateName = activeState.Name
			activeState:Stop()
		end

		verifyStateValidity(name)

		activeState = states[name]
		-- Ordering matters here
		stateMachine.Changed:Fire(name, lastStateName)
		activeState:Run()
	end

	function stateMachine:Start(startState: string)
		if doDebug then
			-- Prevent any loops
			for state, linkedConditions in pairs(stateToConditions) do
				for _, condition in pairs(linkedConditions) do
					if conditionsToTransitionState[condition] == state then
						warn(("Cyclic relationship between state %s and condition %s"):format(state, condition))
					end
				end
			end
		end

		stateMachine:Stop()
		stateMachine:SwitchState(startState)
	end

	function stateMachine:Stop()
		if activeState then
			activeState:Stop()
			activeState = nil
		end
	end

	function stateMachine:Update(dt)
		if onUpdate then
			onUpdate(dt)
		end
	end

	function stateMachine:GetState()
		return if activeState then activeState.Name else nil
	end

	return stateMachine
end

return StateMachine
