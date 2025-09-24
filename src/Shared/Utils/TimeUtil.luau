--!strict
local TimeUtil = {}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local function leading0(number: number)
	return if number < 10 then 0 .. number else number
end

local function postfix(number: number | string, suffix: string)
	local returning = tostring(number)
	returning = returning:gsub("^(0+)", "")
	returning = returning:gsub("^0", "")
	return returning ~= "" and returning .. suffix or returning
end

local function getMS(timeInSeconds: number)
	timeInSeconds = math.floor(timeInSeconds)
	local minutes = leading0(math.floor(timeInSeconds / 60))

	timeInSeconds = timeInSeconds % 60
	local seconds = leading0(timeInSeconds)

	return minutes, seconds
end

local function getHMS(timeInSeconds: number)
	timeInSeconds = math.floor(timeInSeconds)
	local hours = leading0(math.floor(timeInSeconds / 3600))

	timeInSeconds = timeInSeconds % 3600
	local minutes, seconds = getMS(timeInSeconds)

	return hours, minutes, seconds
end

local function getDHMS(timeInSeconds: number)
	timeInSeconds = math.floor(timeInSeconds)
	local days = math.floor(timeInSeconds / 86400)

	timeInSeconds = timeInSeconds % 86400
	local hours, minutes, seconds = getHMS(timeInSeconds)

	return days, hours, minutes, seconds
end

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

function TimeUtil.toDHMS(timeInSeconds: number)
	local days, hours, minutes, seconds = getDHMS(timeInSeconds)
	return (days .. ":" .. hours .. ":" .. minutes .. ":" .. seconds):gsub("^0:", "")
end

function TimeUtil.toPostfixedDHMS(timeInSeconds: number)
	local days, hours, minutes, seconds = getDHMS(timeInSeconds)
	local returning = ("%s %s %s %s"):format(postfix(days, "D"), postfix(hours, "Hr"), postfix(minutes, "Min"), postfix(seconds, "Sec"))
	return returning == "" and "0" or returning
end

function TimeUtil.toPostfixedDH(timeInSeconds: number)
	local days, hours = getDHMS(timeInSeconds)
	local returning = ("%s %s"):format(postfix(days, "D"), postfix(hours, "Hr"))
	return returning == "" and "0" or returning
end

function TimeUtil.toHMS(timeInSeconds: number)
	local hours, minutes, seconds = getHMS(timeInSeconds)
	return hours .. ":" .. minutes .. ":" .. seconds
end

function TimeUtil.toPostfixedHMS(timeInSeconds: number)
	local hours, minutes, seconds = getHMS(timeInSeconds)
	local returning = ("%s %s %s"):format(postfix(hours, "Hr"), postfix(minutes, "Min"), postfix(seconds, "Sec"))
	return returning == "" and "0" or returning
end

function TimeUtil.toMS(timeInSeconds: number)
	local minutes, seconds = getMS(timeInSeconds)
	return minutes .. ":" .. seconds
end

function TimeUtil.toPostfixedMS(timeInSeconds: number)
	local minutes, seconds = getMS(timeInSeconds)
	local returning = ("%s %s"):format(postfix(minutes, "Min"), postfix(seconds, "Sec"))
	return returning == "" and "0" or returning
end

return TimeUtil
