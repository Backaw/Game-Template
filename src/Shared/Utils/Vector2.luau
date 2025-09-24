local Vector2Util = {}

function Vector2Util.getUnit(vector: Vector2)
	if vector.Magnitude > 0 then
		return vector.Unit
	else
		return Vector2.zero
	end
end

return Vector2Util
