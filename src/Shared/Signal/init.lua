local Connection = require(script.Connection)

-- Signal
local Signal = {}
export type Connection = typeof(Connection.new(function() end, {}))

function Signal.new()
	local signal = {}

	local connections: { Connection.Handler } = {}
	local yields: { thread } = {}

	local function resumeAllThreads(...)
		for _, yieldingThread in  (yields) do
			local success, err = coroutine.resume(yieldingThread, ...)
			if not success then
				warn(err)
			end
		end
		yields = {}
	end

	--[[
		Invokes all connections handlers connected to the signal and unyields all threads waiting for the signal
	]]
	function signal:Fire(...)
		for _, connectionHandler in  (connections) do
			task.spawn(connectionHandler, ...) -- Use spawn rather than coroutine because debug trace is better
		end
		resumeAllThreads(...)
	end

	--[[
		Registers a callback to be invoked when the signal is fired
	]]
	function signal:Connect(handler: (...any) -> ())
		return Connection.new(handler, connections)
	end

	--[[
		Registeres a callback to be invoked when the signal is fired and then automatically disconnected
	]]
	function signal:Once(handler: (...any) -> ())
		local connection: Connection
		connection = signal:Connect(function(...)
			connection:Disconnect()
			handler(...)
		end)

		return connection
	end

	--[[
		Yields the thread until the signal fired
	]]
	function signal:Wait(): thread
		table.insert(yields, coroutine.running())
		return coroutine.yield()
	end

	--[[
		Disconnects all connections connected to the signal and unyields all threads waiting for the signal
	]]
	function signal:Destroy()
		signal = {}
		connections = {}
		resumeAllThreads()
	end

	return signal
end

return Signal
