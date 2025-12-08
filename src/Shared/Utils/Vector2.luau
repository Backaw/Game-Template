local Vector2Util = {}

function Vector2Util.getUnit(vector: Vector2)
	if vector.Magnitude > 0 then
		return vector.Unit
	else
		return Vector2.zero
	end
end

function Vector2Util.average(vectors: { Vector2 })
	local sum = Vector2.zero
	for _, vector in vectors do
		sum += vector
	end
	return sum / #vectors
end

--- @return A normalized & rotated Vector2
function Vector2Util.pivot(vector: Vector2, yaw: number)
	local cosA, sinA = math.cos(yaw), math.sin(yaw)
	return Vector2.new(vector.X * cosA - vector.Y * sinA, vector.X * sinA + vector.Y * cosA).Unit
end

return Vector2Util
