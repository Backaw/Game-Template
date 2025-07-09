local Queue = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Modules.Signal)

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function Queue.new()
	local queue = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local list = {}

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------

	queue.FirstChanged = Signal.new() -- (newValue: any | nil) -- Nil if queue got empty'd

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------

	local function getValueIndex(value: any): number | nil
		return table.find(list, value)
	end

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function queue:Push(value: any)
		local wasEmpty = #list == 0
		table.insert(list, value)

		if wasEmpty then
			queue.FirstChanged:Fire(value)
		end
	end

	function queue:Pop()
		if #list == 0 then
			return
		end

		table.remove(list, 1)
		queue.FirstChanged:Fire(list[1])
	end

	function queue:Peek()
		return list[1]
	end

	function queue:Remove(value: any)
		local index = getValueIndex(value)
		if index then
			table.remove(list, index)
		end

		queue.FirstChanged:Fire(list[1])
	end

	function queue:Contains(value: any): boolean
		return getValueIndex(value) ~= nil
	end

	function queue:Size()
		return #list
	end

	return queue
end

return Queue
