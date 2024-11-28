local Players = game:GetService("Players")
local StateMachine = {}

type State = {
	Name: string,
	Run: (State) -> (),
	Stop: (State) -> (),
}
type Condition = {
	TransitionState: string,
	Evaluate: (Condition) -> boolean,
}

local DEFAULT_STATE_REFRESH_TIME = 0.2

local function previewState(state: string)
	for _, player in  (Players:GetPlayers()) do
		player.PlayerGui.HUD.TextLabel.Text = state
	end
end

function StateMachine.new(stateNames: { string }, conditionNames: { string }, refreshTime: number?, debg: boolean?)
	local stateMachine = {}

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local states: { [string]: State } = {}
	local conditions: { [string]: Condition } = {}

	local stateToConditions: { [string]: { string } } = {}
	local conditionsToTransitionState: { [string]: string } = {}

	local activeState: State?

	refreshTime = refreshTime or DEFAULT_STATE_REFRESH_TIME

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
		initHandler: (() -> ()) | nil,
		actionHandler: (() -> ()) | nil
	)
		verifyStateValidity(name)

		stateToConditions[name] = linkedConditions

		local running = false
		states[name] = {
			Name = name,
			Run = function()
				if running then
					error("No bueno")
				end

				running = true

				if initHandler then
					initHandler()
				end

				task.spawn(function()
					while running do
						--check conditions
						for _, conditionName in  (linkedConditions) do
							local condition = conditions[conditionName]
							--print("Checking " .. condition.Name)
							if condition:Evaluate() then
								if debg then
									warn(("%s is true. Switching state to %s "):format(conditionName, condition.TransitionState))
								end

								stateMachine:SwitchState(condition.TransitionState)
								return
							end
						end

						--if no conditions satisfied, perform action
						if actionHandler then
							actionHandler()
						end

						task.wait(refreshTime)
					end
				end)
			end,
			Stop = function()
				running = false
			end,
		}
	end

	function stateMachine:RegisterCondition(name: string, transitionState: string, evaluate: () -> boolean)
		verifyConditionValidity(name)
		verifyStateValidity(transitionState)

		conditionsToTransitionState[name] = transitionState

		conditions[name] = {
			Evaluate = evaluate,
			TransitionState = transitionState,
		}
	end

	function stateMachine:SwitchState(name: string)
		if activeState then
			activeState:Stop()
		end

		previewState(name)

		activeState = if name then states[name] else nil
		if activeState then
			activeState:Run()
		end
	end

	function stateMachine:Start(startState: string)
		if debg then
			-- Prevent any loops
			for state, linkedConditions in  (stateToConditions) do
				for _, condition in  (linkedConditions) do
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

	function stateMachine:GetState()
		return if activeState then activeState.Name else nil
	end

	return stateMachine
end

return StateMachine
