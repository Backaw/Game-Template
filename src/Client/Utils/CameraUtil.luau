--!strict
local CameraUtil = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shaker = require(ReplicatedStorage.Shared.Shaker)
local StateMachine = require(ReplicatedStorage.Shared.StateMachine)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local playerCamera = Workspace.CurrentCamera

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

function CameraUtil.getShakerRegistration<T>(stateMachine: StateMachine.StateMachine<T>, permittedStates: { T })
	local toggle = table.find(permittedStates, stateMachine:GetState()) ~= nil

	local shakers: { Shaker.Shaker } = {}
	local lastShakeOffset: CFrame = CFrame.identity

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

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

	do
		local jobAppendix = ""
		for _, state in permittedStates do
			jobAppendix ..= state :: string
		end

		RunService:BindToRenderStep("CameraControllerBefore" .. jobAppendix, Enum.RenderPriority.Camera.Value - 1, function()
			if lastShakeOffset then
				playerCamera.CFrame *= lastShakeOffset:Inverse()
			end
		end)

		RunService:BindToRenderStep("CameraControllerAfter" .. jobAppendix, Enum.RenderPriority.Camera.Value + 1, function()
			if toggle then
				local dt = 0.015

				lastShakeOffset = CFrame.new()
				for _, shaker in shakers do
					lastShakeOffset *= shaker:Update(dt)
				end

				playerCamera.CFrame *= lastShakeOffset
			end
		end)
	end

	return function(shaker: Shaker.Shaker)
		table.insert(shakers, shaker)
	end, function()
		return lastShakeOffset
	end
end

return CameraUtil
