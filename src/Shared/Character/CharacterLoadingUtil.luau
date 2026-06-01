--!strict
local CharacterLoadingUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local CharacterConstants = require(ReplicatedStorage.Shared.Character.CharacterConstants)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)
local IS_STUDIO = RunService:IsStudio()

local DEFAULT_PRIORITY = 0

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Handler<T...> = (newCharacter: CharacterConstants.Character, T...) -> ()
type Callback<T...> = { Handler: Handler<T...>, Priority: number, Traceback: string? }
export type Registration<T...> = (Handler<T...>, number?) -> () -> ()

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local loadCallbacks: { Callback<> } = {}
local unloadCallbacks: { Callback<> } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function sortByPriority(a: Callback<>, b: Callback<>)
	return a.Priority > b.Priority
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function CharacterLoadingUtil.safeInvokeHandler(handler: (any, any) -> any, ...)
	if IS_STUDIO then
		handler(...)
	else
		local success, err = pcall(handler, ...)
		if not success then
			warn("Character: ", err)
		end
	end
end

function CharacterLoadingUtil.getRegistration<T..., U...>(): (Registration<T...>, Registration<U...>)
	return function(handler: Handler<T...>, priority: number?)
		local callback: Callback<T...> = { Handler = handler, Priority = priority or DEFAULT_PRIORITY }

		if DEBUG then
			callback.Traceback = debug.traceback()
		end

		table.insert(loadCallbacks, callback :: Callback<>)
		table.sort(loadCallbacks, sortByPriority)

		return function()
			local index = table.find(loadCallbacks, callback :: Callback<>)
			if index then
				table.remove(loadCallbacks, index)
			end
		end
	end, function<T...>(handler: Handler<T...>, priority: number?)
		local callback: Callback<T...> = { Handler = handler, Priority = priority or DEFAULT_PRIORITY }

		if DEBUG then
			callback.Traceback = debug.traceback()
		end

		table.insert(unloadCallbacks, callback :: Callback<>)
		table.sort(unloadCallbacks, sortByPriority)

		return function()
			local index = table.find(unloadCallbacks, callback :: Callback<>)
			if index then
				table.remove(unloadCallbacks, index)
			end
		end
	end
end

function CharacterLoadingUtil.invokeLoadCallbacks(character: CharacterConstants.Character, ...)
	for _, callback in loadCallbacks do
		if DEBUG then
			print("Running character load callback:", callback)
		end
		CharacterLoadingUtil.safeInvokeHandler(callback.Handler, character, ...)
	end
end

function CharacterLoadingUtil.invokeUnloadCallbacks(...)
	for _, callback in unloadCallbacks do
		if DEBUG then
			print("Running character unload callback:", callback)
		end
		CharacterLoadingUtil.safeInvokeHandler(callback.Handler, ...)
	end
end

return CharacterLoadingUtil
