--!strict
local RunServiceUtil = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

function RunServiceUtil.batchUpdateJobs<A...>(event: typeof(game:GetService("RunService").Heartbeat), label: string, maxDt: number?)
	local jobs: { [string]: (number) -> () } = {}
	local connection: RBXScriptConnection?
	return function(id: string, job: (number) -> ())
		if jobs[id] then
			error(`Job with id {id} already exists`)
		end

		jobs[id] = job

		if not connection then
			connection = event:Connect(function(dt)
				local cappedDt = if maxDt then math.min(dt, maxDt) else dt

				for _, otherJob in jobs do
					local success, error = pcall(otherJob, cappedDt)
					if not success then
						warn(`Error running job {label} {id}: {error}`)
					end
				end
			end)
		end
	end, function(id: string)
		jobs[id] = nil
		if TableUtil.isEmpty(jobs) and connection then
			connection:Disconnect()
			connection = nil
		end
	end
end

-- Returns a runner that calls `callback(index)` for every index in 1..count,
-- spreading work across Heartbeats once the current frame exceeds maxExecutionTime.
-- Starts asynchronously and returns the thread (add to a Maid/session so teardown
-- cancels mid-run). Safe to call from RenderStepped.
function RunServiceUtil.budgetTasks(maxExecutionTime: number?): (count: number, callback: (index: number) -> ()) -> thread
	local executionTimeCap = maxExecutionTime or 0.002
	return function(count: number, callback: (index: number) -> ())
		return task.spawn(function()
			local index = 1
			while index <= count do
				local startedAt = os.clock()
				while index <= count and os.clock() - startedAt < executionTimeCap do
					callback(index)
					index += 1
				end
				if index <= count then
					RunService.Heartbeat:Wait()
				end
			end
		end)
	end
end

return RunServiceUtil
