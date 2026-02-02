--!strict
local UDimUtil = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function assertType<T>(value: T): T
	local actualType = typeof(value)
	if actualType ~= "UDim2" and actualType ~= "UDim" then
		error(`Expected UDim2 or UDim, but got {actualType}`)
	end
	return value
end

local function assertSameType<T>(u1: T, u2: T): T
	local type1 = typeof(u1)
	local type2 = typeof(u2)
	if type1 ~= type2 then
		error(`Both arguments must be of the same type, but got {type1} and {type2}`)
	end
	if type1 ~= "UDim2" and type1 ~= "UDim" then
		error(`Expected UDim2 or UDim, but got {type1}`)
	end
	return u1
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function UDimUtil.uDim2Multiply(multiplicand: UDim2, multiplier: UDim2)
	return UDim2.new(
		multiplicand.X.Scale * multiplier.X.Scale,
		multiplicand.X.Offset * multiplier.X.Offset,
		multiplicand.Y.Scale * multiplier.Y.Scale,
		multiplicand.Y.Offset * multiplier.Y.Offset
	)
end

function UDimUtil.vectorMultiply(multiplicand: UDim2, multiplier: Vector2)
	return UDim2.new(
		multiplicand.X.Scale * multiplier.X,
		multiplicand.X.Offset * multiplier.X,
		multiplicand.Y.Scale * multiplier.Y,
		multiplicand.Y.Offset * multiplier.Y
	)
end

function UDimUtil.scalarMultiply<T>(multiplicand: T, multiplier: number): T
	assertType(multiplicand)

	if typeof(multiplicand) == "UDim2" then
		local uDim2 = multiplicand :: UDim2
		return UDim2.new(
				uDim2.X.Scale * multiplier,
				uDim2.X.Offset * multiplier,
				uDim2.Y.Scale * multiplier,
				uDim2.Y.Offset * multiplier
			) :: T
	else
		local uDim = multiplicand :: UDim
		return UDim.new(uDim.Scale * multiplier, uDim.Offset * multiplier) :: T
	end
end

function UDimUtil.max<T>(u1: T, u2: T): T
	assertSameType(u1, u2)

	if typeof(u1) == "UDim2" then
		local dim1 = u1 :: UDim2
		local dim2 = u2 :: UDim2
		return UDim2.new(
			math.max(dim1.X.Scale, dim2.X.Scale),
			math.max(dim1.X.Offset, dim2.X.Offset),
			math.max(dim1.Y.Scale, dim2.Y.Scale),
			math.max(dim1.Y.Offset, dim2.Y.Offset)
		) :: T
	else
		local dim1 = u1 :: UDim
		local dim2 = u2 :: UDim
		return UDim.new(math.max(dim1.Scale, dim2.Scale), math.max(dim1.Offset, dim2.Offset)) :: T
	end
end

function UDimUtil.abs<T>(u: T): T
	assertType(u)

	if typeof(u) == "UDim2" then
		local uDim2 = u :: UDim2
		return UDim2.new(math.abs(uDim2.X.Scale), math.abs(uDim2.X.Offset), math.abs(uDim2.Y.Scale), math.abs(uDim2.Y.Offset)) :: T
	else
		local uDim = u :: UDim
		return UDim.new(math.abs(uDim.Scale), math.abs(uDim.Offset)) :: T
	end
end

-- UDim Operations

function UDimUtil.uDimMultiply(multiplicand: UDim, multiplier: UDim)
	return UDim.new(multiplicand.Scale * multiplier.Scale, multiplicand.Offset * multiplier.Offset)
end

return UDimUtil
