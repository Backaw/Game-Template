--!strict
local Queue = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

export type Queue<T> = {
	HeadChanged: Signal.Signal<T>,
	Push: (Queue<T>, T) -> (),
	Pop: (Queue<T>) -> T?,
	Peek: (Queue<T>) -> T,
	Remove: (Queue<T>, T) -> (),
	Contains: (Queue<T>, T) -> boolean,
	Size: (Queue<T>) -> number,
}

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------
function Queue.new<T>(head: T?)
	local queue = {} :: Queue<T>

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local list: { T } = { head }

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------

	queue.HeadChanged = Signal.new() :: Signal.Signal<T>

	-------------------------------------------------------------------------------
	-- PRIVATE METHODS
	-------------------------------------------------------------------------------

	local function getValueIndex(value)
		return table.find(list, value)
	end

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function queue:Push(value)
		local wasEmpty = #list == 0
		table.insert(list, value)

		if wasEmpty then
			queue.HeadChanged:Fire(value)
		end
	end

	function queue:Pop()
		if #list == 0 then
			return nil
		end

		local returning = table.remove(list, 1)
		queue.HeadChanged:Fire(list[1])

		return returning
	end

	function queue:Peek()
		return list[1]
	end

	function queue:Remove(value)
		local index = getValueIndex(value)
		if index then
			table.remove(list, index)
		end

		queue.HeadChanged:Fire(list[1])
	end

	function queue:Contains(value)
		return getValueIndex(value) ~= nil
	end

	function queue:Size()
		return #list
	end

	return queue
end

return Queue
