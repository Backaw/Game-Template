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

local MIN_DELTA_TIME = 1 / 50

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

	function spring:Update(target, dt)
		dt = math.min(dt, MIN_DELTA_TIME)
		local scaledDeltaTime = dt * (speed :: any)

		local dx = target - position :: any
		local acceleration = (dx * stiffness) / mass - velocity * damping :: any

		velocity += acceleration * scaledDeltaTime
		position += velocity * scaledDeltaTime

		return position
	end

	function spring:Impulse(impulse)
		velocity += impulse :: any / mass * IDENTITY
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
