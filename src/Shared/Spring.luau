--!strict
local Spring = {}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Spring = {
	Reset: (self: Spring, newPosition: NumVect) -> (),
	Set: (self: Spring, newPosition: NumVect) -> (),
	Update: (self: Spring, target: NumVect, dt: number, cappedDt: number?) -> NumVect,
	Impulse: (self: Spring, impulse: NumVect) -> (),
	GetVelocity: (self: Spring) -> number,
	Get: (self: Spring) -> NumVect,
}

type NumVect = number | Vector3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local MAX_DT = 1 / 10
local MAX_SCALED_STEP = 0.45
-- Max sub-step * rate product kept well under the semi-implicit Euler stability bound (~2) for accuracy.
local STABILITY_LIMIT = 0.5
-- Guard against runaway sub-step counts for pathological stiffness/damping values.
local MAX_SUBSTEPS = 64

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function maxComponent(value: NumVect): number
	if typeof(value) == "Vector3" then
		return math.max(value.X, value.Y, value.Z)
	end
	return value
end

local function minComponent(value: NumVect): number
	if typeof(value) == "Vector3" then
		return math.min(value.X, value.Y, value.Z)
	end
	return value
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function Spring.new(position: NumVect, mass: NumVect, stiffness: NumVect, damping: NumVect, speed: NumVect)
	local spring = {} :: Spring

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local velocity: NumVect

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function spring:Reset(newPosition)
		position = newPosition
		velocity = type(newPosition) == "number" and 0 or Vector3.zero
	end

	function spring:Set(newPosition)
		position = newPosition
	end

	function spring:Update(target, dt, cappedDt)
		dt = cappedDt or math.min(dt, MAX_DT)
		local scaledDeltaTime = dt * (speed :: any)

		-- Scalar timestep used only to choose the sub-step count.
		local scaledStepScalar = dt * maxComponent(speed)
		if scaledStepScalar <= 0 then
			return position
		end

		-- Sub-step so each step stays within the stability limit of semi-implicit Euler.
		-- The limit depends on the oscillation rate (omega) and damping, not just speed * dt.
		local minMass = minComponent(mass)
		local omega = if minMass > 0 then math.sqrt(maxComponent(stiffness) / minMass) else 0
		local rate = math.max(omega, maxComponent(damping))

		local maxStep = MAX_SCALED_STEP
		if rate > 0 then
			maxStep = math.min(maxStep, STABILITY_LIMIT / rate)
		end

		local steps = math.clamp(math.ceil(scaledStepScalar / maxStep), 1, MAX_SUBSTEPS)
		local stepDt = scaledDeltaTime / steps

		for _ = 1, steps do
			local dx = target - position :: any
			local acceleration = (dx * stiffness) / mass - velocity * damping :: any
			velocity += acceleration * stepDt
			position += velocity * stepDt
		end

		return position
	end

	function spring:Impulse(impulse)
		velocity += (impulse :: any) / mass
	end

	function spring:GetVelocity()
		local returning = if typeof(velocity) == "Vector3" then velocity.Magnitude else velocity
		return math.abs(returning)
	end

	function spring:Get()
		return position
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	spring:Reset(position)

	return spring
end

return Spring
