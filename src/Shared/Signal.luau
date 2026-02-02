--!strict

-- Better, type-checked signal module @SixthAtom & @StaliniumDev

local Signal = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArrayUtil = require(ReplicatedStorage.Shared.Utils.ArrayUtil)

local BEHAVIOUR_TYPES = {
	JustRun = "JustRun",
	Immediate = "Immediate",
	Deferred = "Deferred",
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Signal<T...> = {
	Fire: (self: Signal<T...>, T...) -> (),
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection<T...>,
	Subscribe: (self: Signal<T...>, callback: (T...) -> (), T...) -> Connection<T...>,
	Wait: (self: Signal<T...>) -> thread,
	Destroy: (self: Signal<T...>) -> (),
}

export type Connection<T...> = {
	Index: number,
	Callback: (T...) -> (),
	Disconnect: (connection: Connection<T...>) -> (),
	Destroy: (connection: Connection<T...>) -> (),
	Connected: boolean,
}

type BehaviourType = keyof<typeof(BEHAVIOUR_TYPES)>

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

--- - JustRun: Synchronous execution - blocks until all callbacks complete
--- - Immediate: Parallel execution - each callback runs in task.spawn
--- - Deferred: Queued execution - callbacks run on next frame
function Signal.new<T...>(behaviourType: BehaviourType?): Signal<T...>
	local signal = {} :: Signal<T...>

	behaviourType = behaviourType or BEHAVIOUR_TYPES.Immediate

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------

	local connections: { Connection<T...> } = {}
	local yields: { thread } = {}

	local fireEvents = (
		behaviourType == BEHAVIOUR_TYPES.Immediate
			and function(...: T...)
				for _, v in connections do
					task.spawn(v.Callback, ...)
				end
			end
		or behaviourType == BEHAVIOUR_TYPES.Deferred and function(...: T...)
			for _, v in connections do
				task.defer(v.Callback, ...)
			end
		end
		or function(...: T...)
			for _, v in connections do
				v.Callback(...)
			end
		end
	) :: (T...) -> ()

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------

	local function resumeAllThreads(...)
		for _, yieldingThread in yields do
			local success, err = coroutine.resume(yieldingThread, ...)
			if not success then
				warn(err)
			end
		end
		table.clear(yields)
	end

	local function disconnect(connection: Connection<T...>)
		if not connection.Connected then
			warn("Attemping to disconnect a disconnected connection")
			return
		end

		connection.Connected = false
		local swappedConnection = ArrayUtil.swapbackRemove(connections, connection.Index)
		swappedConnection.Index = connection.Index
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function signal:Fire(...: T...)
		resumeAllThreads()
		fireEvents(...)
	end

	function signal:Connect(callback: (T...) -> ())
		local connection: Connection<T...> = {
			Index = #connections + 1,
			Callback = callback,
			Disconnect = disconnect,
			Destroy = disconnect,
			Connected = true,
		}

		table.insert(connections, connection)
		return connection
	end

	function signal:Once(callback: (T...) -> ())
		local connection: Connection<T...>

		connection = signal:Connect(function(...)
			connection:Disconnect()
			callback(...)
		end)

		return connection
	end

	function signal:Subscribe(callback: (T...) -> (), ...: T...)
		task.spawn(callback, ...)
		return signal:Connect(callback)
	end

	function signal:Wait()
		table.insert(yields, coroutine.running())
		return coroutine.yield()
	end

	function signal:Destroy()
		table.clear(connections)
		resumeAllThreads()
	end

	return signal
end

return Signal
