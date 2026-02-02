--!strict
local MathUtil = {}

local random = Random.new()

function MathUtil.ifNanThen0(x: number): number
	return if x ~= x then 0 else x
end
--[[
    Limits the number of decimal places a number has
]]
function MathUtil.precision(x: number, decimalPlaces: number): number
	local multiplier = 10 ^ decimalPlaces
	return math.sign(x) * math.floor(math.abs(x * multiplier)) / multiplier
end

function MathUtil.absSign(x: number): number
	return math.sign(MathUtil.precision(math.abs(x), 1))
end

function MathUtil.round(x: number): number
	local ceil = math.ceil(x)
	local floor = math.floor(x)
	return if math.abs(floor - x) < math.abs(ceil - x) then floor else ceil
end

function MathUtil.minimizeAngle(x: number): number
	x = x % (2 * math.pi)
	local x2 = x - (2 * math.pi)
	return if math.abs(x) < math.abs(x2) then x else x2
end

function MathUtil.nextSign()
	return if random:NextInteger(1, 2) == 1 then 1 else -1
end

function MathUtil.lerpNumber(a: number, b: number, alpha: number)
	return a + (b - a) * alpha
end

function MathUtil.sigmoid(x: number, factor: number, clamp: boolean?)
	local y = 1 / (1 + math.exp((-x + 0.5) * factor))
	if clamp then
		return math.clamp(y, 0, 1)
	end
	return y
end

function MathUtil.positiveOrNegative(): number
	return math.random(1, 2) == 1 and 1 or -1
end

function MathUtil.randomCentered(): number
	return (math.random() - 0.5) * 2
end

function MathUtil.randomAngle()
	return math.random() * math.pi * 2
end

--[[
    Linearly map a value from one range to another. Input range must not be empty. This is the same as chaining Normalize from input range and Lerp to output range.
    Example: function(20, 10, 30, 50, 100) returns 75.
]]
function MathUtil.map(value: number, inRangeStart: number, inRangeEnd: number, outRangeStart: number, outRangeEnd: number, clamp: boolean?)
	local result = outRangeStart + (value - inRangeStart) * (outRangeEnd - outRangeStart) / (inRangeEnd - inRangeStart)
	if clamp then
		result = math.clamp(result, math.min(outRangeStart, outRangeEnd), math.max(outRangeStart, outRangeEnd))
	end
	return result
end

return MathUtil
