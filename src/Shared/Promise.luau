--!strict
--!optimize 2

--[=[
Promise Module
Author: Lars (SixthAtom) – 2025-09-24

Minimal Luau Promises with execution-type aware handler dispatch. Supports
synchronous chaining, async fan-out, and coroutine-based awaiting while keeping
allocation overhead low.

## Usage Overview

### Creating promises
```
Promise.new("Serial", function(resolve, reject)
	resolve("value")
end)
```

### Chaining
- `promise:andThen(success?, failure?)`
- `promise:catch(failure)`
- `promise:finally(finallyHandler)`

### Awaiting
`local ok, result = promise:await()` -- yields until settled

### Utilities
- `Promise.all(promises)`
- `Promise.race(promises)`
- `Promise.resolved(..., executionType?)`
- `Promise.rejected(reason, executionType?)`

Internally the module tracks handler queues, coroutine waiters, and disposes
handlers according to the configured execution type for predictable
performance.
]=]
local Promise = {}

local STATES = {
	Pending = "Pending",
	Resolved = "Resolved",
	Rejected = "Rejected",
	Cancelled = "Cancelled",
}

local EXECUTION_TYPES = {
	Serial = "Serial", -- Handles run one after another. Blocking until all complete. Use for dependent operations.
	Parallel = "Parallel", -- Runs all handlers in their own threads simultaneously. Use for independent operations.
	Deferred = "Deferred", -- Handlers run simultaneously on the next frame. Use for UI updates and heavy operations to avoid blocking the current frame.
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Handler = (...any) -> ...any
export type FinallyHandler = (...any) -> ()

export type Promise = {
	ClassName: "Promise",
	andThen: (self: Promise, successHandler: Handler?, failureHandler: Handler?) -> Promise,
	catch: (self: Promise, failureHandler: Handler) -> Promise,
	finally: (self: Promise, finalHandler: FinallyHandler) -> Promise,
	await: (self: Promise) -> (boolean, ...any),
	getState: (self: Promise) -> PromiseState,
	andThenCall: (self: Promise, handler: (any) -> any, ...any) -> Promise,
	cancel: (self: Promise) -> (),
}

type PackedValues = { [number]: any, n: number }

export type ExecutionType = keyof<typeof(EXECUTION_TYPES)>
export type PromiseState = keyof<typeof(STATES)>

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
Promise.States = STATES
Promise.ExecutionTypes = EXECUTION_TYPES

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function normalizeExecutionType(executionType: ExecutionType?): ExecutionType
	return executionType or "Serial"
end

local function executeHandlerSafely(handler: Handler, ...): (boolean, { any }, number)
	local packed = table.pack(pcall(handler, ...))
	return packed[1] == true, packed, packed.n
end

local function forwardHandlerResult(ok: boolean, packed: { any }, size: number, childResolve: (...any) -> (), childReject: (...any) -> ())
	if ok then
		if size >= 2 then
			local first = packed[2]
			if Promise.is(first) then
				(first :: Promise):andThen(function(...)
					childResolve(...)
				end, function(...)
					childReject(...)
				end)
				return
			end
		end

		if size >= 2 then
			childResolve(table.unpack(packed, 2, size))
		else
			childResolve()
		end
	else
		childReject(table.unpack(packed, 2, size))
	end
end

local function clearHandlers(handlers: { Handler })
	for index = 1, #handlers do
		handlers[index] = nil
	end
end

local function dispatchByExecutionType(executionType: ExecutionType, handlers: { Handler }, ...)
	if #handlers == 0 then
		return
	end

	if executionType == "Serial" then
		for index = 1, #handlers do
			executeHandlerSafely(handlers[index], ...)
		end
	elseif executionType == "Parallel" then
		for index = 1, #handlers do
			task.spawn(executeHandlerSafely, handlers[index], ...)
		end
	else -- Deferred
		for index = 1, #handlers do
			task.defer(executeHandlerSafely, handlers[index], ...)
		end
	end

	clearHandlers(handlers)
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

--[=[
Constructs a new promise.

The executor runs inside a protected call. Calling `resolve(...)` marks the
promise as resolved; `reject(...)` marks it rejected. Handler queues flush using
`"Serial"`, `"Parallel"`, or `"Deferred"`, matching the execution type.
]=]
function Promise.new(executor: (resolve: (...any) -> (), reject: (...any) -> ()) -> (), executionType: ExecutionType?): Promise
	assert(type(executor) == "function", "Promise.new expects a function executor")

	local promise = {
		ClassName = "Promise",
	} :: Promise

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------

	local executionMode = normalizeExecutionType(executionType)
	local state: PromiseState = "Pending"

	local storedValues: PackedValues = {} :: PackedValues

	local queuedResolve: { Handler } = {}
	local queuedReject: { Handler } = {}
	local queuedFinally: { Handler } = {}
	local awaitingThreads: { thread } = {}

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------

	local function flushAwaiters()
		for index = 1, #awaitingThreads do
			local thread = awaitingThreads[index]
			if thread ~= nil then
				task.spawn(thread)
				awaitingThreads[index] = nil
			end
		end
	end

	local function resolve(...)
		if state ~= "Pending" then
			return
		end

		storedValues = table.pack(...)
		state = "Resolved"

		dispatchByExecutionType(executionMode, queuedResolve, ...)
		dispatchByExecutionType(executionMode, queuedFinally, ...)
		flushAwaiters()
	end

	local function reject(...)
		if state ~= "Pending" then
			return
		end

		if select("#", ...) >= 1 then
			storedValues = table.pack(...) :: PackedValues
		else
			storedValues = table.pack(nil) :: PackedValues
		end

		state = "Rejected"

		dispatchByExecutionType(executionMode, queuedReject, table.unpack(storedValues, 1, storedValues.n))
		dispatchByExecutionType(executionMode, queuedFinally, table.unpack(storedValues, 1, storedValues.n))
		flushAwaiters()
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	--[=[
	Chains a continuation.

	Returns a promise resolved/rejected with the result of `successHandler` or
	`failureHandler`. Passing `nil` leaves the value unchanged. Handlers inherit
	the parent execution mode.
	]=]
	function promise:andThen(successHandler, failureHandler)
		return Promise.new(function(childResolve, childReject)
			local successCallback: Handler
			if successHandler then
				local handler: Handler = successHandler
				successCallback = function(...)
					local ok, packed, size = executeHandlerSafely(handler, ...)
					forwardHandlerResult(ok, packed, size, childResolve, childReject)
				end
			else
				successCallback = childResolve
			end

			local failureCallback: Handler
			if failureHandler then
				local handler: Handler = failureHandler
				failureCallback = function(...)
					local ok, packed, size = executeHandlerSafely(handler, ...)
					forwardHandlerResult(ok, packed, size, childResolve, childReject)
				end
			else
				failureCallback = childReject
			end

			if state == "Pending" then
				table.insert(queuedResolve, successCallback)
				table.insert(queuedReject, failureCallback)
			elseif state == "Resolved" then
				successCallback(table.unpack(storedValues, 1, storedValues.n))
			else
				failureCallback(table.unpack(storedValues, 1, storedValues.n))
			end
		end, executionMode)
	end

	--[=[
	Failure-only chaining shortcut.

	Equivalent to `self:andThen(nil, failureHandler)`. The returned promise mirrors
	the chained result.
	]=]
	function promise:catch(failureHandler)
		return self:andThen(nil, failureHandler)
	end

	--[=[
	Runs a handler regardless of resolve/reject.

	The returned promise mirrors `finallyHandler`; if it throws, the chain rejects
	with that error.
	]=]
	function promise:finally(finalHandler)
		assert(type(finalHandler) == "function", "Promise:finally expects a handler")

		return Promise.new(function(childResolve, childReject)
			local handler: Handler = finalHandler

			local function continueWithOriginalOutcome()
				if state == "Resolved" then
					childResolve(table.unpack(storedValues, 1, storedValues.n))
				else
					childReject(table.unpack(storedValues, 1, storedValues.n))
				end
			end

			local function finalize(...)
				local ok, packed, size = executeHandlerSafely(handler, ...)
				if ok then
					if size >= 2 then
						local first = packed[2]
						if Promise.is(first) then
							(first :: Promise):andThen(function()
								continueWithOriginalOutcome()
							end, function(...)
								childReject(...)
							end)
							return
						end
					end

					continueWithOriginalOutcome()
				else
					childReject(table.unpack(packed, 2, size))
				end
			end

			if state == "Pending" then
				table.insert(queuedFinally, finalize)
			else
				finalize(table.unpack(storedValues, 1, storedValues.n))
			end
		end, executionMode)
	end

	--[=[
	Suspends the current coroutine until settlement.

	Returns `(true, ...)` when resolved and `(false, ...)` when rejected. Errors if
	called outside a coroutine.
	]=]
	function promise:await()
		if state == "Pending" then
			local thread = coroutine.running()
			if thread == nil then
				error("Promise.await must be called inside a coroutine", 2)
			end

			table.insert(awaitingThreads, thread)
			coroutine.yield()
		end

		if state == "Resolved" then
			return true, table.unpack(storedValues, 1, storedValues.n)
		end

		return false, table.unpack(storedValues, 1, storedValues.n)
	end

	--[=[
	Returns the current state of the promise.
	]=]
	function promise:getState()
		return state
	end

	--[=[
	Attaches an andThen handler to this Promise that calls the given callback with the predefined arguments. The resolved value is discarded.
	Equivalent to `self:andThen(function() return handler(...) end)`.
	]=]
	function promise:andThenCall(handler: (any) -> any, ...)
		local args = table.pack(...)
		return promise:andThen(function()
			return handler(table.unpack(args, 1, args.n))
		end)
	end

	--[=[
	Cancels this promise, preventing the promise from resolving or rejecting.
	Does not do anything if the promise is already settled.
	]=]
	function promise:cancel()
		if state == "Pending" then
			state = "Cancelled"
			clearHandlers(queuedResolve)
			clearHandlers(queuedReject)
			clearHandlers(queuedFinally)
			flushAwaiters()
		end
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	task.spawn(function()
		local ok, err = pcall(executor, resolve, reject)
		if not ok then
			reject(err)
		end
	end)

	return promise
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

--[=[
Resolves when every promise in `promises` resolves.

Returns an array where each entry stores the packed results for the
corresponding promise. Rejects immediately if any promise rejects.
]=]
function Promise.all(promises: { Promise }): Promise
	return Promise.new(function(resolve, reject)
		local count = #promises
		if count == 0 then
			resolve({})
			return
		end

		local results = table.create(count)
		local remaining = count

		for index, promise in promises do
			promise:andThen(function(...)
				results[index] = table.pack(...)
				remaining -= 1
				if remaining == 0 then
					resolve(results)
				end
			end, function(...)
				reject(...)
			end)
		end
	end, EXECUTION_TYPES.Serial)
end

--[=[
Settles with the first promise to resolve or reject.

Remaining promises are ignored once one settles.
]=]
function Promise.race(promises: { Promise }): Promise
	return Promise.new(function(resolve, reject)
		if #promises == 0 then
			resolve()
			return
		end

		local settled = false

		local function wrap(callback: Handler)
			return function(...)
				if settled then
					return
				end
				settled = true
				callback(...)
			end
		end

		for _, promise in promises do
			promise:andThen(wrap(resolve), wrap(reject))
		end
	end, EXECUTION_TYPES.Serial)
end

--[=[
Returns an already-resolved promise.

If the final argument is an execution type string, that dispatch mode is used.
Earlier arguments become the resolved values.
]=]
function Promise.resolved(...): Promise
	local packed = table.pack(...)
	local executionType: ExecutionType = "Serial"

	if packed.n > 0 then
		local maybeType = packed[packed.n]
		if type(maybeType) == "string" and EXECUTION_TYPES[maybeType] then
			executionType = maybeType :: ExecutionType
			packed[packed.n] = nil
			packed.n = packed.n - 1
		end
	end

	return Promise.new(function(resolve)
		resolve(table.unpack(packed, 1, packed.n))
	end, executionType)
end

--[=[
Returns an already-rejected promise configured with an optional execution type.
]=]
function Promise.rejected(reason: any, executionType: ExecutionType?): Promise
	local executionMode = normalizeExecutionType(executionType)

	return Promise.new(function(_, reject)
		reject(reason)
	end, executionMode)
end

--[=[
Creates a promise that resolves when an event fires with a value satisfying the predicate.
The connection is automatically disconnected once resolved.
]=]
function Promise.fromEvent<T...>(event: RBXScriptSignal<T...>, predicate: (T...) -> boolean): Promise
	return Promise.new(function(resolve)
		local connection: RBXScriptConnection
		connection = event:Connect(function(...)
			if predicate(...) then
				resolve(...)
				connection:Disconnect()
			end
		end)
	end)
end

--[=[
Returns whether the given value is a promise-like object.

Checks for the presence of an `andThen` method or `ClassName == "Promise"`.
]=]
function Promise.is(value: any): boolean
	if type(value) ~= "table" then
		return false
	end

	local maybeAndThen = (value :: any).andThen
	if type(maybeAndThen) == "function" then
		return true
	end

	if (value :: any).ClassName == "Promise" then
		return true
	end

	return false
end

--[=[
Repeatedly calls a Promise-returning function up to times number of times, until the returned Promise resolves.
If the amount of retries is exceeded, the function will return the latest rejected Promise.

]=]
function Promise.retry(callback: (...any) -> any, times: number, ...: any): Promise
	assert(times > 0, "Promise.retry expects times > 0")

	local args = table.pack(...)

	return Promise.new(function(resolve, reject)
		local attempt = 0

		local function tryAttempt()
			attempt += 1
			local result = callback(table.unpack(args, 1, args.n))
			result
				:andThen(function(...)
					resolve(...)
				end)
				:catch(function(err)
					if attempt < times then
						tryAttempt()
					else
						reject(err)
					end
				end)
		end

		tryAttempt()
	end)
end

return Promise
