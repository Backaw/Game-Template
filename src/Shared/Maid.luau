--!strict
local Maid = {}
Maid.__index = Maid

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Shared.Promise)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type Mess = () -> () | thread | RBXScriptConnection | Instance | (({ Destroy: (any) -> () } & { any }) & Promise.Promise)
export type Maid = {
	Add: (self: Maid, task: any, id: string?) -> string,
	HasTask: (self: Maid, taskId: string) -> boolean,
	Remove: (self: Maid, taskId: string) -> (),
	RemoveIfExits: (self: Maid, taskId: string) -> (),
	RemoveNoClean: (self: Maid, taskId: string) -> (),
	Cleanup: (self: Maid) -> (),
	Destroy: (self: Maid) -> (),
	Reset: (self: Maid) -> (),
}

type InternalMaid = Maid & {
	_tasks: { [string]: Mess },
}

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Maid.cleanup(cleaning: Mess)
	if typeof(cleaning) == "function" then
		(cleaning :: () -> ())()
	elseif typeof(cleaning) == "thread" then
		local status = coroutine.status(cleaning :: thread)
		if status == "suspended" then
			task.cancel(cleaning :: thread)
		elseif status == "running" then
			warn("Maid: cannot clean a running thread", debug.traceback())
		end
		-- "dead" / "normal": already finished, nothing to cancel
	elseif typeof(cleaning) == "RBXScriptConnection" then
		(cleaning :: RBXScriptConnection):Disconnect()
	elseif typeof(cleaning) == "table" then
		if Promise.is(cleaning) then
			(cleaning :: Promise.Promise):cancel()
		elseif cleaning.Destroy then
			cleaning:Destroy()
		end
	elseif typeof(cleaning) == "Instance" then
		cleaning:Destroy()
	end
end

function Maid.new(): Maid
	return setmetatable({
		_tasks = {},
	}, Maid) :: InternalMaid
end

function Maid.Add(self: InternalMaid, task, id)
	if not task then
		error("Task cannot be false or nil", 2)
	end

	local tasks = self._tasks
	if id and tasks[id] then
		error(`Task id ({id}) already used` .. debug.traceback())
	end

	local taskId = id or tostring(TableUtil.maxIndex(tasks) + 1)
	tasks[taskId] = task

	return taskId
end

function Maid.HasTask(self: InternalMaid, taskId: string)
	return self._tasks[taskId] ~= nil
end

function Maid.Remove(self: InternalMaid, taskId: string)
	local tasks = self._tasks
	local task = tasks[taskId]
	if not task then
		error("Task doesn't exist", 2)
	end

	Maid.cleanup(task)
	tasks[taskId] = nil
end

function Maid.RemoveIfExits(self: InternalMaid, taskId: string)
	if self:HasTask(taskId) then
		self:Remove(taskId)
	end
end

function Maid.RemoveNoClean(self: InternalMaid, taskId: string)
	self._tasks[taskId] = nil
end

function Maid.Cleanup(self: InternalMaid)
	for _, task in self._tasks do
		Maid.cleanup(task)
	end

	table.clear(self._tasks)
end

function Maid.Destroy(self: InternalMaid)
	self:Cleanup()
	table.clear(self._tasks)
	table.clear(self)
	setmetatable(self, nil)
end

function Maid.Reset(self: InternalMaid)
	table.clear(self._tasks)
end

return Maid
