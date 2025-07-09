local Spring = {}

local IDENTITY = Vector3.one

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Spring = typeof(Spring.new())

type NumVect = number | Vector3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local MIN_DELTA_TIME = 1 / 50

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function Spring.new(position: NumVect, mass: NumVect, stiffness: NumVect, damping: NumVect, speed: NumVect)
	local spring = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local velocity: NumVect

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function spring:Reset(newPosition: NumVect)
		position = newPosition
		velocity = type(newPosition) == "number" and 0 or Vector3.zero
	end

	function spring:Set(newPosition: NumVect)
		position = newPosition
	end

	function spring:Update(target: NumVect, dt: number)
		dt = math.min(dt, MIN_DELTA_TIME)
		local scaledDeltaTime = dt * speed

		local dx = target - position
		local acceleration = (dx * stiffness) / mass - velocity * damping

		velocity += acceleration * scaledDeltaTime
		position += velocity * scaledDeltaTime

		return position
	end

	function spring:Impulse(impulse: NumVect)
		velocity += impulse / mass * IDENTITY
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
