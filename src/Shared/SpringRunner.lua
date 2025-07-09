local SpringRunner = {}

local RunService = game:GetService("RunService")
local Spring = require(script.Parent.Spring)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------
type Methods = {
	OnUpdate: ((NumVect) -> ())?,
	OnFinish: (() -> ())?,
}

type NumVect = number | Vector3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local springsToRun: { [number]: { any } } = {}

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function SpringRunner.insert(spring: Spring.Spring, target: NumVect, methods: Methods, finishTreshold: number?)
	for i = #springsToRun, 1, -1 do
		if springsToRun[i][1] == spring then
			table.remove(springsToRun, i)
		end
	end

	table.insert(springsToRun, { spring, target, methods, finishTreshold or 0.05 })
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
RunService.Heartbeat:Connect(function(deltaTime)
	for i, springData in springsToRun do
		local spring: Spring.Spring, target: NumVect, methods: Methods, finishTreshold: number = table.unpack(springData)

		local position
		if methods.OnUpdate then
			position = spring:Update(target, deltaTime)
			methods.OnUpdate(position)
		end

		local velocity = spring:GetVelocity()
		local targetOffset = (position or spring:Get()) - target

		if
			velocity <= finishTreshold
			and math.abs(if typeof(targetOffset) == "Vector3" then targetOffset.Magnitude else targetOffset) <= finishTreshold
		then
			if methods.OnFinish then
				methods.OnFinish()
			end

			local lastSpringData = springsToRun[#springsToRun]
			if springData ~= lastSpringData then
				springsToRun[i] = lastSpringData
			end
			springsToRun[#springsToRun] = nil
		end
	end
end)

return SpringRunner
