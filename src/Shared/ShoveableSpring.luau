local ShoveableSpring = {}

local ITERATIONS = 8

function ShoveableSpring.new(mass: number?, force: number?, damping: number?, speed: number?)
	local spring = {}

	local target = Vector3.new()
	local position = Vector3.new()
	local velocity = Vector3.new()

	mass = mass or 5
	force = force or 50
	damping = damping or 4
	speed = speed or 4

	function spring:Shove(impulse: Vector3)
		local x, y, z = impulse.X, impulse.Y, impulse.Z
		if x ~= x or x == math.huge or x == -math.huge then
			x = 0
		end
		if y ~= y or y == math.huge or y == -math.huge then
			y = 0
		end
		if z ~= z or z == math.huge or z == -math.huge then
			z = 0
		end
		velocity = velocity + Vector3.new(x, y, z)
	end

	function spring:Reset()
		position = Vector3.new()
		velocity = Vector3.new()
	end

	function spring:GetPosition()
		return position
	end

	function spring:Update(dt)
		local scaledDeltaTime = math.min(dt, 1) * speed / ITERATIONS

		for _ = 1, ITERATIONS do
			local iterationForce = target - position
			local acceleration = (iterationForce * force) / mass

			acceleration = acceleration - velocity * damping

			velocity = velocity + acceleration * scaledDeltaTime
			position = position + velocity * scaledDeltaTime
		end

		return position
	end

	return spring
end

return ShoveableSpring
