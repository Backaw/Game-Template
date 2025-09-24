--!strict
local UDim2Util = {}

function UDim2Util.uDim2Multiply(multiplicand: UDim2, multiplier: UDim2)
	return UDim2.new(
		multiplicand.X.Scale * multiplier.X.Scale,
		multiplicand.X.Offset * multiplier.X.Offset,
		multiplicand.Y.Scale * multiplier.Y.Scale,
		multiplicand.Y.Offset * multiplier.Y.Offset
	)
end

function UDim2Util.vectorMultiply(multiplicand: UDim2, multiplier: Vector2)
	return UDim2.new(
		multiplicand.X.Scale * multiplier.X,
		multiplicand.X.Offset * multiplier.X,
		multiplicand.Y.Scale * multiplier.Y,
		multiplicand.Y.Offset * multiplier.Y
	)
end

function UDim2Util.scalarMultiply(multiplicand: UDim2, multiplier: number)
	return UDim2.new(
		multiplicand.X.Scale * multiplier,
		multiplicand.X.Offset * multiplier,
		multiplicand.Y.Scale * multiplier,
		multiplicand.Y.Offset * multiplier
	)
end

function UDim2Util.max(u1: UDim2, u2: UDim2)
	return UDim2.new(
		math.max(u1.X.Scale, u2.X.Scale),
		math.max(u1.X.Offset, u2.X.Offset),
		math.max(u1.Y.Scale, u2.Y.Scale),
		math.max(u1.Y.Offset, u2.Y.Offset)
	)
end

function UDim2Util.abs(uDim2: UDim2)
	return UDim2.new(math.abs(uDim2.X.Scale), math.abs(uDim2.X.Offset), math.abs(uDim2.Y.Scale), math.abs(uDim2.Y.Offset))
end

return UDim2Util
