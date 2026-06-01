--!strict
local Spring = {}

local IDENTITY = Vector3.one

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Spring = {
	Reset: (self: Spring, newPosition: NumVect) -> (),
	Set: (self: Spring, newPosition: NumVect) -> (),
	Update: (self: Spring, target: NumVect, dt: number) -> NumVect,
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

		-- Sub-step when the scaled step exceeds the stability limit for the integration
		if typeof(scaledDeltaTime) == "number" and scaledDeltaTime > MAX_SCALED_STEP then
			local steps = math.ceil(scaledDeltaTime / MAX_SCALED_STEP)
			local stepDt = scaledDeltaTime / steps

			for _ = 1, steps do
				local dx = target - position :: any
				local acceleration = (dx * stiffness) / mass - velocity * damping :: any
				velocity += acceleration * stepDt
				position += velocity * stepDt
			end
		else
			local dx = target - position :: any
			local acceleration = (dx * stiffness) / mass - velocity * damping :: any
			velocity += acceleration * scaledDeltaTime
			position += velocity * scaledDeltaTime
		end

		return position
	end

	function spring:Impulse(impulse)
		velocity += impulse :: any / mass * (if typeof(velocity) == "Vector3" then IDENTITY else 1)
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
