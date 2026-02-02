local SpringRunner = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Spring = require(ReplicatedStorage.Shared.Spring)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------
type Methods = {
	OnUpdate: ((NumVect) -> ())?,
	OnFinish: (() -> ())?,
}

export type NumVect = number | Vector3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------'

local springsToRun: { [number]: { any } } = {}

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function SpringRunner.run(spring: Spring.Spring, target: NumVect, methods: Methods, finishTreshold: number?)
	for i = #springsToRun, 1, -1 do
		if springsToRun[i][1] == spring then
			table.remove(springsToRun, i)
		end
	end

	local springData = { spring, target, methods, finishTreshold or 0.05 }
	table.insert(springsToRun, springData)

	return function()
		local index = table.find(springsToRun, springData)
		if index then
			table.remove(springsToRun, index)
		end
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

RunService.Heartbeat:Connect(function(deltaTime)
	for i = #springsToRun, 1, -1 do
		local springData = springsToRun[i]
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
			-- Remove from table BEFORE calling OnFinish to prevent multiple calls
			table.remove(springsToRun, i)

			if methods.OnFinish then
				methods.OnFinish()
			end
		end
	end
end)

return SpringRunner
