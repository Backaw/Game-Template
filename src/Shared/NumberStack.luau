--!strict
local NumberStack = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local OPERANDS = {
	Add = "Add",
	Max = "Max",
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type NumberStack = {
	Changed: Signal.Signal<number>,
	Push: (NumberStack, string, number, boolean?) -> boolean,
	Pop: (NumberStack, string, boolean?) -> boolean,
	Get: (NumberStack) -> number,
	HasJob: (NumberStack, string) -> boolean,
	Clear: (NumberStack, boolean?) -> (),
}

export type Operand = keyof<typeof(OPERANDS)>

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

NumberStack.Operand = OPERANDS :: { [Operand]: Operand }

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function NumberStack.new(operand: Operand, min: number)
	local stack = {} :: NumberStack

	local jobs: { [string]: number }
	stack.Changed = Signal.new()

	function stack:Push(job, entry, quietDebugging)
		if jobs[job] then
			if not quietDebugging then
				warn(("Job %s already exists"):format(job), debug.traceback())
			end
			return false
		end

		jobs[job] = entry

		stack.Changed:Fire(stack:Get())
		return true
	end

	function stack:Pop(job, quietDebugging)
		if not jobs[job] then
			if not quietDebugging then
				warn("Job %s does not exist", job, debug.traceback())
			end
			return false
		end

		jobs[job] = nil

		stack.Changed:Fire(stack:Get())
		return true
	end

	function stack:HasJob(job)
		return jobs[job] ~= nil
	end

	function stack:Get()
		if operand == NumberStack.Operand.Add then
			local sum = min
			for _, entry in pairs(jobs) do
				sum += entry
			end
			return sum
		else
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
			stack.Changed:Fire(stack:Get())
		end
	end

	stack:Clear()

	return stack
end

return NumberStack
