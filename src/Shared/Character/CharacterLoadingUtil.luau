--!strict
local CharacterLoadingUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

type Handler = (newCharacter: Model) -> ()
type Callback = { Handler: Handler, Priority: number, Traceback: string? }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)
local IS_STUDIO = RunService:IsStudio()

local DEFAULT_PRIORITY = 0

local loadCallbacks: { Callback } = {}
local unloadCallbacks: { Callback } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function sortByPriority(a: Callback, b: Callback)
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

function CharacterLoadingUtil.getRegisteration()
	return function(handler: Handler, priority: number?)
		local callback: Callback = { Handler = handler, Priority = priority or DEFAULT_PRIORITY }

		if DEBUG then
			callback.Traceback = debug.traceback()
		end

		table.insert(loadCallbacks, callback)
		table.sort(loadCallbacks, sortByPriority)

		return function()
			local index = table.find(loadCallbacks, callback)
			if index then
				table.remove(loadCallbacks, index)
			end
		end
	end, function(handler: Handler, priority: number?)
		local callback: Callback = { Handler = handler, Priority = priority or DEFAULT_PRIORITY }

		if DEBUG then
			callback.Traceback = debug.traceback()
		end

		table.insert(unloadCallbacks, callback)
		table.sort(unloadCallbacks, sortByPriority)

		return function()
			local index = table.find(unloadCallbacks, callback)
			if index then
				table.remove(unloadCallbacks, index)
			end
		end
	end
end

function CharacterLoadingUtil.invokeLoadCallbacks(character: Model, ...)
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
