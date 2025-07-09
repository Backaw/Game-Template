--[[
	A class that runs a callback filters through descedants and future descedants and runs a callback on them
	]]

local DescendantLooper = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Modules.Maid)

local THROTTLE_EVERY = 100

export type DescendantLooper = Maid.Maid

function DescendantLooper.new(
	instances: { Instance },
	callback: (Instance) -> (),
	filter: ((instance: Instance) -> boolean)?,
	onInitCompleted: () -> ()?
)
	local maid = Maid.new()

	local initialized = 0
	local function forEveryDescendant(descendant: Instance)
		if if filter then filter(descendant) else true then
			initialized += 1
			if initialized % THROTTLE_EVERY == 0 then
				task.wait()
			end

			callback(descendant)
		end
	end

	for i, instance in pairs(instances) do
		task.spawn(function()
			for _, descendant in pairs(instance:GetDescendants()) do
				forEveryDescendant(descendant)
			end
			maid:Add(instance.DescendantAdded:Connect(forEveryDescendant))

			if i == #instances and onInitCompleted then
				onInitCompleted()
			end
		end)
	end

	return maid
end

return DescendantLooper
