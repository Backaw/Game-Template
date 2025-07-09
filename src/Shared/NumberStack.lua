local NumberStack = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Modules.Signal)

export type NumberStack = typeof(NumberStack.new())

NumberStack.Operand = {
	Add = "Add",
	Max = "Max",
}
function NumberStack.new(operand: string, min: number)
	local stack = {}

	local jobs: { [string]: number }

	stack.Changed = Signal.new()

	function stack:Push(job: string, entry: number, quietDebugging: boolean?)
		if jobs[job] then
			if quietDebugging then
				return
			else
				error(("Job %s already exists"):format(job))
			end
		end

		jobs[job] = entry

		stack.Changed:Fire(stack:Get())
		return true
	end

	function stack:Pop(job: string, quietDebugging: boolean?)
		if not jobs[job] then
			if quietDebugging then
				return
			else
				error(("Job %s does not exist"):format(job))
			end
		end

		jobs[job] = nil

		stack.Changed:Fire(stack:Get())
		return true
	end

	function stack:Get()
		if operand == NumberStack.Operand.Add then
			local sum = min
			for _, entry in pairs(jobs) do
				sum += entry
			end
			return sum
		elseif operand == NumberStack.Operand.Max then
			local max = min
			for _, entry in pairs(jobs) do
				max = math.max(max, entry)
			end
			return max
		end
	end

	function stack:Clear(quiet: boolean?)
		jobs = {}

		if not quiet then
			stack.Changed:Fire()
		end
	end

	stack:Clear()

	return stack
end

return NumberStack
