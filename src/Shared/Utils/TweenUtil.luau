--!strict
local TweenUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Binder = require(ReplicatedStorage.Shared.Binder)
local Promise = require(ReplicatedStorage.Shared.Packages.Promise)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function promise(tween: Tween): Promise.Promise
	return Promise.new(function(resolve, _, onCancel)
		if onCancel(function()
			tween:Cancel()
		end) then
			return
		end

		tween.Completed:Connect(resolve)
		tween:Play()
	end)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

-- Creates a tween, and automatically plays it
function TweenUtil.tween(instance: Instance, tweenInfo: TweenInfo, propertyTable: { [string]: any })
	local tween = TweenService:Create(instance, tweenInfo, propertyTable)
	tween:Play()

	return tween
end

-- Cancels any existing tweens binded to an instance, creates a new one, plays it and then binds it to said instance
function TweenUtil.bind(instance: Instance, bindKey: string, tween: Tween, onCompleted: (Enum.PlaybackState) -> ()?)
	TweenUtil.cancelBinding(instance, bindKey)

	Binder.bind(instance, bindKey, tween)
	Binder.unbindOnBindedEvent(instance, bindKey, "Completed")

	tween.Completed:Connect(function(playbackState)
		Binder.bind(instance, bindKey)
		if onCompleted then
			onCompleted(playbackState)
		end
	end)

	tween:Play()

	return tween
end

function TweenUtil.cancelBinding(instance: Instance, bindKey: string)
	Binder.invokeBindedMethod(instance, bindKey, "Cancel")
end

-- Returns a promise that resolves when a tween is completed
function TweenUtil.promisify(instance: Instance, tweenInfo: TweenInfo, goal: { [string]: any })
	local tween = TweenService:Create(instance, tweenInfo, goal)
	return promise(tween)
end

function TweenUtil.batch(tweens: { Tween })
	local promises: { Promise.Promise } = {}
	for _, tween in tweens do
		table.insert(promises, promise(tween))
	end

	return Promise.all(promises)
end

return TweenUtil
