local Maid = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Modules.Packages.Promise)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

export type Maid = typeof(Maid.new())

function Maid.cleanup(cleaning)
	if type(cleaning) == "function" then
		cleaning()
	elseif type(cleaning) == "thread" then
		task.cancel(cleaning)
	elseif typeof(cleaning) == "RBXScriptConnection" then
		cleaning:Disconnect()
	elseif cleaning.Destroy then
		cleaning:Destroy()
	elseif Promise.is(cleaning) then
		cleaning:cancel()
	end
end

function Maid.new()
	local maid = {}
	local tasks = {}

	--[[
    	Gives a task to the maid for cleanup, uses an incremented number as a key.
    ]]
	function maid:Add(task, id: string?)
		if not task then
			error("Task cannot be false or nil", 2)
		end

		if id and tasks[id] then
			error("Task id already used")
		end

		local taskId = id or tostring(TableUtil.maxIndex(tasks) + 1)
		local taskType = typeof(task)

		if taskType == "table" and not Promise.is(task) and not task.Destroy then
			error("Gave table task without .Destroy")
		end

		tasks[taskId] = task
		return taskId
	end

	--[[
        Cleans up a task
    ]]
	function maid:HasTask(taskId: string)
		return tasks[taskId] ~= nil
	end

	--[[
        Cleans up a task
    ]]
	function maid:Remove(taskId: string)
		local task = tasks[taskId]
		if not task then
			error("Task doesn't exist", 2)
		end

		Maid.cleanup(task)
		tasks[taskId] = nil
	end

	function maid:RemoveIfExits(taskId: string)
		if maid:HasTask(taskId) then
			maid:Remove(taskId)
		end
	end

	function maid:RemoveNoClean(taskId: string)
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
		maid = {}
	end

	return maid
end

return Maid
