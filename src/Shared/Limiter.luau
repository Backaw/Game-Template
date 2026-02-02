--!strict
local Limiter = {}

local debounces: { [string]: { [any]: true? } } = {}
local indecisives: { [string]: { [any]: number? } } = {}
local confirmations: { [string]: { Value: any, SetTime: number } } = {}

function Limiter.debounce(scope: string, key: any, cooldown: number)
	local scopeList = debounces[scope]
	if not scopeList then
		scopeList = {}
		debounces[scope] = scopeList
	end

	if not scopeList[key] then
		scopeList[key] = true
		task.delay(cooldown, function()
			scopeList[key] = nil
		end)

		return true
	end

	return false
end

function Limiter.indecisive(scope: string, key: any, cooldown: number, callback: () -> ())
	local scopeList = indecisives[scope]
	if not scopeList then
		scopeList = {}
		indecisives[scope] = scopeList
	end

	local hash = os.clock()
	scopeList[key] = hash
	task.delay(cooldown, function()
		if scopeList[key] == hash then
			callback()
			scopeList[key] = nil
		end
	end)
end

-- Prevents code from changing mind too frequently. It'll help verify that a change is still valid rather than flipping to frequently
function Limiter.confirm(scope: string, value: any, cooldown: number)
	local confirmation = confirmations[scope]
	if confirmation and confirmation.Value == value then
		if os.clock() - confirmation.SetTime >= cooldown then
			return true
		end
	else
		confirmations[scope] = { Value = value, SetTime = os.clock() }
	end

	return false
end

-- Prevents code from changing mind too frequently. It'll help verify that a change is still valid rather than flipping to frequently to confirmation value
function Limiter.confirmToggle(scope: string, confirmationValue: any, value: any, cooldown: number)
	if value == confirmationValue then
		return Limiter.confirm(scope, value, cooldown)
	else
		confirmations[scope] = { Value = value, SetTime = os.clock() }
	end

	return false
end

return Limiter
