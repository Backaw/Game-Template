--!strict

--[[
    Wrapper for a boolean variable that manages potentially conflicting value changes.
	 In order to change the value, if flipping back the value to the initial value, all jobs must agree

    Example:
        local toggle = Toggle.new(true)

        toggle:Set(false, "a")
        print(toggle:Get()) -- false
        toggle:Set(false, "b")
        print(toggle:Get()) -- false
        toggle:Set(true, "a")
        print(toggle:Get()) -- false
        toggle:Set(true, "b")
        print(toggle:Get()) -- true

]]

local Toggle = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

export type Toggle = {
	Changed: Signal.Signal<boolean>,
	JobsChanged: Signal.Signal<{ Job }>,
	Set: (Toggle, Job, boolean) -> boolean,
	RemoveJob: (Toggle, Job) -> boolean,
	ForceSet: (Toggle, boolean) -> (),
	ForceSetQuiet: (Toggle, boolean) -> (),
	HasJob: (Toggle, Job) -> boolean,
	Get: (Toggle) -> boolean,
	GetJobs: (Toggle) -> { Job },
}
export type Job = string

function Toggle.new(initialValue: boolean)
	local toggle = {} :: Toggle

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local jobs: { Job } = {}
	local value = initialValue

	-------------------------------------------------------------------------------
	-- PUBLIC MEMBERS
	-------------------------------------------------------------------------------

	toggle.Changed = Signal.new()
	toggle.JobsChanged = Signal.new()

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------
	--[[
        Change the value, if flipping back the value to the initial value, all jobs must agree
        RETURNS: Whether or not value was changed
    ]]
	function toggle:Set(job, newValue)
		local changed = false

		if newValue ~= initialValue then
			-- RETURN: Job already exists
			if table.find(jobs, job) then
				return false
			end

			if value ~= newValue then
				value = not initialValue
				changed = true

				toggle.Changed:Fire(newValue)
			end

			table.insert(jobs, job)
			toggle.JobsChanged:Fire(jobs)
		else
			local jobIndex = table.find(jobs, job)
			-- RETURN: Job doesn't exist
			if not jobIndex then
				return false
			end

			table.remove(jobs, jobIndex)
			toggle.JobsChanged:Fire(jobs)

			if #jobs == 0 then
				value = initialValue
				changed = true

				toggle.Changed:Fire(newValue)
			end
		end

		return changed
	end

	function toggle:RemoveJob(job)
		if toggle:HasJob(job) then
			toggle:Set(job, not value)
			return true
		end

		return false
	end

	function toggle:ForceSet(newValue)
		jobs = {}

		if value == newValue then
			return
		end

		value = newValue

		toggle.Changed:Fire(newValue)
		toggle.JobsChanged:Fire(jobs)
	end

	function toggle:ForceSetQuiet(newValue)
		jobs = {}
		value = newValue
	end

	function toggle:HasJob(job)
		return table.find(jobs, job) ~= nil
	end

	function toggle:Get()
		return value
	end

	function toggle:GetJobs()
		return jobs
	end

	return toggle
end

return Toggle
