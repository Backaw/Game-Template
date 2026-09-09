--!strict

-- Better, type-checked signal module @SixthAtom & @StaliniumDev

local Signal = {}
Signal.__index = Signal

local Connection = {}
Connection.__index = Connection

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

type InternalSignal<T...> = Signal<T...> & {
	_connections: { Connection<T...> },
	_yields: { thread },
	_behaviourType: BehaviourType,
}

type InternalConnection<T...> = Connection<T...> & {
	_signal: InternalSignal<T...>,
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function resumeAllThreads<T...>(self: InternalSignal<T...>)
	for _, yieldingThread in self._yields do
		local success, err = coroutine.resume(yieldingThread)
		if not success then
			warn(err)
		end
	end
	table.clear(self._yields)
end

local function fireEvents<T...>(self: InternalSignal<T...>, ...: T...)
	local connections = self._connections
	local behaviourType = self._behaviourType

	if behaviourType == BEHAVIOUR_TYPES.Immediate then
		local snapshot = table.clone(connections)
		for _, connection in snapshot do
			task.spawn(connection.Callback, ...)
		end
	elseif behaviourType == BEHAVIOUR_TYPES.Deferred then
		local snapshot = table.clone(connections)
		for _, connection in snapshot do
			task.defer(connection.Callback, ...)
		end
	else
		local snapshot = table.clone(connections)
		for _, connection in snapshot do
			connection.Callback(...)
		end
	end
end

local function disconnect<T...>(connection: InternalConnection<T...>)
	if not connection.Connected then
		warn("Attemping to disconnect a disconnected connection")
		return
	end

	connection.Connected = false
	local signal = connection._signal
	local swappedConnection = ArrayUtil.swapbackRemove(signal._connections, connection.Index)
	swappedConnection.Index = connection.Index
end

-------------------------------------------------------------------------------
-- CONNECTION
-------------------------------------------------------------------------------

function Connection.Disconnect<T...>(self: Connection<T...>)
	disconnect(self :: InternalConnection<T...>)
end

Connection.Destroy = Connection.Disconnect

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

--- - JustRun: Synchronous execution - blocks until all callbacks complete
--- - Immediate: Parallel execution - each callback runs in task.spawn
--- - Deferred: Queued execution - callbacks run on next frame
function Signal.new<T...>(behaviourType: BehaviourType?): Signal<T...>
	return setmetatable({
		_connections = {},
		_yields = {},
		_behaviourType = behaviourType or BEHAVIOUR_TYPES.Immediate,
	}, Signal) :: InternalSignal<T...>
end

function Signal.Fire<T...>(self: InternalSignal<T...>, ...: T...)
	resumeAllThreads(self)
	fireEvents(self, ...)
end

function Signal.Connect<T...>(self: InternalSignal<T...>, callback: (T...) -> ()): Connection<T...>
	local connection = setmetatable({
		Index = #self._connections + 1,
		Callback = callback,
		Connected = true,
		_signal = self,
	}, Connection) :: InternalConnection<T...>

	table.insert(self._connections, connection)
	return connection
end

function Signal.Once<T...>(self: InternalSignal<T...>, callback: (T...) -> ()): Connection<T...>
	local connection: Connection<T...>

	connection = self:Connect(function(...)
		(connection :: InternalConnection<T...>):Disconnect()
		callback(...)
	end)

	return connection
end

function Signal.Subscribe<T...>(self: InternalSignal<T...>, callback: (T...) -> (), ...: T...)
	task.spawn(callback, ...)
	return self:Connect(callback)
end

function Signal.Wait<T...>(self: InternalSignal<T...>)
	table.insert(self._yields, coroutine.running())
	return coroutine.yield()
end

function Signal.Destroy<T...>(self: InternalSignal<T...>)
	table.clear(self._connections)
	resumeAllThreads(self)
end

return Signal
