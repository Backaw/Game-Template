--!strict
local Maid = {}

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

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Maid.cleanup(cleaning: Mess)
	if typeof(cleaning) == "function" then
		(cleaning :: () -> ())()
	elseif typeof(cleaning) == "thread" then
		coroutine.close(cleaning :: thread)
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

function Maid.new()
	local maid = {} :: Maid
	local tasks: { [string]: Mess } = {}

	--[[
    	Gives a task to the maid for cleanup, uses an incremented number as a key.
    ]]
	function maid:Add(task, id)
		if not task then
			error("Task cannot be false or nil", 2)
		end

		if id and tasks[id] then
			error(`Task id ({id}) already used` .. debug.traceback())
		end

		local taskId = id or tostring(TableUtil.maxIndex(tasks) + 1)
		tasks[taskId] = task

		return taskId
	end

	--[[
        Cleans up a task
    ]]
	function maid:HasTask(taskId)
		return tasks[taskId] ~= nil
	end

	--[[
        Cleans up a task
    ]]
	function maid:Remove(taskId)
		local task = tasks[taskId]
		if not task then
			error("Task doesn't exist", 2)
		end

		Maid.cleanup(task)
		tasks[taskId] = nil
	end

	function maid:RemoveIfExits(taskId)
		if maid:HasTask(taskId) then
			maid:Remove(taskId)
		end
	end

	function maid:RemoveNoClean(taskId)
		tasks[taskId] = nil
	end

	--[[
        Removes all tasks in order they were added
    ]]
	function maid:Cleanup()
		for _, task in tasks do
			Maid.cleanup(task)
		end

		tasks = {}
	end

	--[[
        Removes all tasks and ceases the addition of new ones
    ]]
	function maid:Destroy()
		maid:Cleanup()

		tasks = {}
		maid = {} :: Maid
	end

	function maid:Reset()
		tasks = {}
	end

	return maid
end

return Maid
