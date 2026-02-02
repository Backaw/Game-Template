--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

local StateMachine = {}

type State<S> = {
	Name: S,
	Run: (State<S>, string?) -> (),
	Stop: (State<S>) -> (),
}
type Condition<S> = {
	TransitionState: S,
	Evaluate: (number) -> boolean,
}

export type StateMachine<S, C> = {
	Changed: Signal.Signal<S?, S?>,
	BindState: (StateMachine<S, C>, S, { C }, (S?) -> ()?, (number) -> ()?, Handler) -> (),
	RegisterCondition: (StateMachine<S, C>, C, S, (number) -> boolean) -> (),
	SwitchState: (StateMachine<S, C>, S) -> (),
	Start: (StateMachine<S, C>, S) -> (),
	Stop: (StateMachine<S, C>) -> (),
	Update: (StateMachine<S, C>, number) -> S?,
	GetState: (StateMachine<S, C>) -> S?,
}

export type Handler = ((number?) -> ()) | nil

function StateMachine.new<S, C>(stateNames: { S }, conditionNames: { C }, doDebug: boolean?)
	local stateMachine = {} :: StateMachine<S, C>

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local states: { [S]: State<S> } = {}
	local conditions: { [C]: Condition<S> } = {}

	local stateToConditions: { [S]: { C } } = {}
	local conditionsToTransitionState: { [C]: S } = {}

	local activeState: State<S>?, onUpdate: ((number) -> ()) | nil

	-------------------------------------------------------------------------------
	-- PUBLIC VARIABLES
	-------------------------------------------------------------------------------
	stateMachine.Changed = Signal.new() :: Signal.Signal<S?, S?>

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------

	local function verifyStateValidity(name: S)
		if not table.find(stateNames, name) then
			error(("%s is not a valid state"):format(tostring(name)))
		end
	end

	local function verifyConditionValidity(name: C)
		if not table.find(conditionNames, name) then
			error(("%s is not a valid condition"):format(tostring(name)))
		end
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function stateMachine:BindState(name, linkedConditions, initHandler, actionHandler, closeHandler)
		verifyStateValidity(name)

		stateToConditions[name] = linkedConditions

		local function run(dt)
			--check conditions
			for _, conditionName in pairs(linkedConditions) do
				local condition = conditions[conditionName]
				-- ("Checking " .. tostring(conditionName))

				if condition.Evaluate(dt) then
					if doDebug then
						warn(("%s is true. Switching state to %s "):format(tostring(conditionName), tostring(condition.TransitionState)))
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
			Run = function(_, lastStateName: string?)
				if onUpdate == run then
					error("No bueno")
				end

				onUpdate = run

				if initHandler then
					initHandler(lastStateName)
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

	function stateMachine:RegisterCondition(name: C, transitionState: S, evaluate: (number) -> boolean)
		verifyConditionValidity(name)
		verifyStateValidity(transitionState)

		conditionsToTransitionState[name] = transitionState

		conditions[name] = {
			Evaluate = evaluate,
			TransitionState = transitionState,
		}
	end

	function stateMachine:SwitchState(name)
		local lastStateName
		if activeState then
			lastStateName = activeState.Name
			activeState:Stop()
		end

		verifyStateValidity(name)

		local newState = states[name]
		activeState = newState

		-- Ordering matters here
		stateMachine.Changed:Fire(name, lastStateName)
		newState:Run(lastStateName)
	end

	function stateMachine:Start(startState)
		verifyStateValidity(startState)

		if doDebug then
			-- Prevent any loops
			for state, linkedConditions in pairs(stateToConditions) do
				for _, condition in pairs(linkedConditions) do
					if conditionsToTransitionState[condition] == state then
						warn(("Cyclic relationship between state %s and condition %s"):format(tostring(state), tostring(condition)))
					end
				end
			end

			-- Ensure every state's linked conditions are registered
			for state, linkedConditions in pairs(stateToConditions) do
				for _, condition in pairs(linkedConditions) do
					if not conditions[condition] then
						error(
							("Condition %s (used by state %s) is not registered; call RegisterCondition before Start"):format(
								tostring(condition),
								tostring(state)
							)
						)
					end
				end
			end

			-- Ensure every condition's transition target state is bound
			for condition, transitionState in pairs(conditionsToTransitionState) do
				if not states[transitionState] then
					error(
						("Condition %s transitions to state %s which is not bound; call BindState before Start"):format(
							tostring(condition),
							tostring(transitionState)
						)
					)
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

		return if activeState then activeState.Name else nil
	end

	function stateMachine:GetState()
		return if activeState then activeState.Name else nil
	end

	return stateMachine
end

return StateMachine
