--!strict
--[[
    Promise wrappers that can be resolved/cancelled externally
]]
local DeferredPromise = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Shared.Promise)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------
type Callback = (...any) -> ()

export type DeferredPromise = Promise.Promise & { invokeResolve: Callback, invokeReject: Callback }

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function DeferredPromise.new(handler: (Callback, Callback) -> ()?, executionType: Promise.ExecutionType?)
	local resolve: Callback, reject: Callback

	local promise = Promise.new(function(_resolve, _reject)
		resolve = function(...)
			_resolve(...)
		end
		reject = function(...)
			_reject(...)
		end

		if handler then
			handler(_resolve :: Callback, _reject :: Callback)
		end
	end, executionType) :: DeferredPromise

	promise.invokeResolve = resolve
	promise.invokeReject = reject

	return promise
end

--[[
    Creates a promise that waits and only runs after invoke is called.
]]
function DeferredPromise.await(executor)
	local promise = DeferredPromise.new() :: DeferredPromise & { invoke: () -> boolean }

	promise.invoke = function()
		local success, err = pcall(executor)
		if not success then
			promise.invokeReject(err)
			return false
		end

		promise.invokeResolve()
		return true
	end

	return promise
end

return DeferredPromise
