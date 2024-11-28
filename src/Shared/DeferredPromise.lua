--[[
    Promise wrappers
]]

local DeferredPromise = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Promise = require(ReplicatedStorage.Modules.Packages.Promise)

type Callback = (any) -> ()
--[[
    Creates a promise that can be resolved/resoved from the outside
    must call resolve with : operator
    Basically an event
]]
function DeferredPromise.new(handler: (Callback, Callback) -> ()?)
	local resolve: Callback, reject: Callback

	local promise = Promise.new(function(_resolve, _reject)
		resolve = function() -- Creating a seperate function with these allows us to use : or .
			_resolve()
		end
		reject = function() -- Creating a seperate function with these allows us to use : or .
			_reject()
		end

		if handler then
			handler(_resolve, _reject)
		end
	end)

	promise.invokeResolve = resolve
	promise.invokeReject = reject

	return promise
end

--[[
    Creates a promise that waits and only runs after invoke is called.
]]
function DeferredPromise.await(executor)
	local promise = DeferredPromise.new()
	promise.invoke = function()
		local success, err = pcall(executor)
		if not success then
			promise.reject(err)
			return false
		end

		promise.resolve()
		return true
	end

	return promise
end

return DeferredPromise
