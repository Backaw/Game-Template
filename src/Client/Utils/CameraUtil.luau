--!strict
local CameraUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StateMachine = require(ReplicatedStorage.Shared.StateMachine)
local Shaker = require(ReplicatedStorage.Shared.Shaker)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- Returns how far away from it's subject a camera should be positioned so that the subject's full height is in view
function CameraUtil.getFitDepthY(fov: number, subjectSize: Vector3): number
	return (subjectSize.Y / 2) / math.tan(math.rad(fov / 2)) + (subjectSize.Z / 2)
end

-- Returns how far away from it's subject a camera should be positioned so that the subject's full width is in view
function CameraUtil.getFitDepthX(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
	local aspectRatio = viewportSize.X / viewportSize.Y

	return (subjectSize.X / 2) / math.tan(math.rad(fov * aspectRatio / 2)) + (subjectSize.Z / 2)
end

-- Returns how far away from it's subject a camera should be positioned so that the subject is in view
function CameraUtil.getFitDepth(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
	return math.max(CameraUtil.getFitDepthY(fov, subjectSize), CameraUtil.getFitDepthX(viewportSize, fov, subjectSize))
end

do
	-- local registeredStates: { any } = {}
	function CameraUtil.getShakerRegistration<T>(stateMachine: StateMachine.StateMachine<T>, permittedStates: { T })
		local toggle = table.find(permittedStates, stateMachine:GetState()) ~= nil

		local shakers: { Shaker.Shaker } = {}
		local lastShakeOffset: CFrame = CFrame.identity

		-------------------------------------------------------------------------------
		-- LOGIC
		-------------------------------------------------------------------------------

		--[[
		-- Check for reused states
		for _, state in permittedStates do
			if registeredStates[state] then
				warn("Duplicate camera states in shaker bindings", state)
				continue
			else
				registeredStates[state] = true
			end

		end ]]

		stateMachine:RegisterGlobalCallback(function(_, new)
			toggle = true
			local nextToggle = table.find(permittedStates, new) ~= nil
			if nextToggle ~= toggle and nextToggle then
				for _, shaker in shakers do
					shaker:Reset()
				end
			end

			toggle = nextToggle
		end)

		return {
			RegisterShaker = function(shaker: Shaker.Shaker)
				table.insert(shakers, shaker)
				return shaker
			end,

			GetShakeOffset = function()
				return lastShakeOffset
			end,

			PreUpdate = function()
				if lastShakeOffset then
					return lastShakeOffset:Inverse()
				end
				return CFrame.identity
			end,

			PostUpdate = function(dt: number, cappedDt: number?)
				if toggle then
					-- Cap dt so focus loss / pause doesn't make shakers accumulate or decay incorrectly
					lastShakeOffset = CFrame.new()
					for _, shaker in shakers do
						lastShakeOffset *= shaker:Update(cappedDt or dt)
					end

					return lastShakeOffset
				end

				return CFrame.identity
			end,
		}
	end
end

return CameraUtil
