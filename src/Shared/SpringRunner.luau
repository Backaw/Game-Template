--!strict
local SpringRunner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Spring = require(ReplicatedStorage.Shared.Spring)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Methods = {
	OnUpdate: ((NumVect) -> ())?,
	OnFinish: (() -> ())?,
	Reverse: boolean?,
}

type SpringData = {
	Target: NumVect,
	Origin: NumVect,
	Reversed: boolean,
	Methods: Methods,
	FinishThreshold: number,
}

export type NumVect = number | Vector3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local springsToRun: { [Spring.Spring]: SpringData } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function removeSpring(spring: Spring.Spring)
	springsToRun[spring] = nil
end

local function addSpring(spring: Spring.Spring, target: NumVect, methods: Methods, finishThreshold: number?)
	springsToRun[spring] = {
		Target = target,
		Origin = spring:Get(),
		Reversed = false,
		Methods = methods,
		FinishThreshold = finishThreshold or 0.05,
	}
end

local function stopHandle(spring: Spring.Spring)
	return function()
		removeSpring(spring)
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function SpringRunner.run(spring: Spring.Spring, target: NumVect, methods: Methods, finishThreshold: number?)
	addSpring(spring, target, methods, finishThreshold)
	return stopHandle(spring)
end

-- If the spring is already running, snap its position and retarget (methods unchanged).
-- Otherwise register it with the given methods.
function SpringRunner.impulse(spring: Spring.Spring, impulse: NumVect, target: NumVect, methods: Methods, finishThreshold: number?)
	spring:Impulse(impulse)

	local data = springsToRun[spring]
	if data then
		data.Target = target
	else
		addSpring(spring, target, methods, finishThreshold)
	end

	return stopHandle(spring)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(deltaTime)
	for spring, data in springsToRun do
		local target = data.Target :: any
		local methods = data.Methods
		local finishThreshold = data.FinishThreshold

		local position: any
		if methods.OnUpdate then
			position = spring:Update(target, deltaTime)
			methods.OnUpdate(position)
		end

		local velocity = spring:GetVelocity()
		local targetOffset = (position or (spring:Get() :: any)) - target

		if
			velocity <= finishThreshold
			and math.abs(if typeof(targetOffset) == "Vector3" then targetOffset.Magnitude else targetOffset) <= finishThreshold
		then
			if methods.Reverse and not data.Reversed then
				data.Reversed = true
				data.Target = data.Origin
			else
				-- Remove before OnFinish so a re-run inside the callback is safe.
				removeSpring(spring)

				if methods.OnFinish then
					methods.OnFinish()
				end
			end
		end
	end
end)

return SpringRunner
