--!strict
local CameraController = {}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CFrameUtil = require(Shared.Utils.CFrameUtil)
local StateMachine = require(Shared.StateMachine)
local TableUtil = require(Shared.Utils.TableUtil)
local CameraUtil = require(Client.Utils.CameraUtil)
local NumberStack = require(Shared.NumberStack)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_FOV = 70
local FOV_PRIORITIES = {
	Default = 1,
	Low = 2,
	Transition = 5,
	High = 10,
}

local DEFAULT_CAMERA_TYPE = Enum.CameraType.Follow

local FIRST_PERSON_THRESHOLD = 0.5
local STARTING_ZOOM = 25
local STARTING_PITCH = -math.rad(20)

local STATES = {
	Default = "Default",
	Driving = "Driving",
	Unboxing = "Unboxing",
	CarEditing = "CarEditing",
	Death = "Death",
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type State = keyof<typeof(STATES)>

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local playerDefaultMinZoom = 5
local playerDefaultMaxZoom = player.CameraMaxZoomDistance

local stateMachine = StateMachine.new(TableUtil.toArray(STATES), STATES.Default) :: StateMachine.StateMachine<State>
local shakeHandler = CameraUtil.getShakerRegistration(stateMachine, { STATES.Default, STATES.Unboxing, STATES.CarEditing } :: { State })

local fovJobs = NumberStack.new(NumberStack.Operand.Max, FOV_PRIORITIES.Default)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

CameraController.DefaultFOV = DEFAULT_FOV
CameraController.FOVJobPriorities = FOV_PRIORITIES
CameraController.States = STATES :: { [State]: State }

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

CameraController.registerShaker, CameraController.getShakeOffset = shakeHandler.RegisterShaker, shakeHandler.GetShakeOffset

-- Locks Follow / Classic camera distance to exactly `zoom` (min and max must match).
function CameraController.setZoom(zoom: number)
	zoom = math.clamp(zoom, playerDefaultMinZoom, playerDefaultMaxZoom)
	player.CameraMinZoomDistance = zoom
	player.CameraMaxZoomDistance = zoom

	task.defer(function()
		task.wait()
		player.CameraMinZoomDistance = playerDefaultMinZoom
		player.CameraMaxZoomDistance = playerDefaultMaxZoom
	end)
end

function CameraController.getZoom()
	return (camera.CFrame.Position - camera.Focus.Position).Magnitude
end

function CameraController.getZoomFactor()
	local span = player.CameraMaxZoomDistance - player.CameraMinZoomDistance
	if span <= 1e-3 then
		local z = CameraController.getZoom()
		if z <= FIRST_PERSON_THRESHOLD then
			return 0
		end
		return 1
	end

	return CameraController.getZoom() / span
end

function CameraController.isFirstPerson()
	return CameraController.getZoom() <= FIRST_PERSON_THRESHOLD
end

function CameraController.getThirdPersonZoomOutFactor()
	local span = player.CameraMaxZoomDistance - player.CameraMinZoomDistance
	if span <= FIRST_PERSON_THRESHOLD + 1e-3 then
		local z = CameraController.getZoom()
		if z <= FIRST_PERSON_THRESHOLD then
			return 0
		end
		return 1
	end

	return math.max(0, CameraController.getZoom() - FIRST_PERSON_THRESHOLD) / (span - FIRST_PERSON_THRESHOLD)
end

function CameraController.resetCameraType()
	camera.CameraType = DEFAULT_CAMERA_TYPE
end

function CameraController.lookForward()
	CameraController.resetCameraType()

	if player.Character then
		local focus = camera.Focus
		camera.CFrame = CFrame.new(focus.Position) * CFrame.fromEulerAnglesYXZ(STARTING_PITCH, CFrameUtil.getYComponent(focus), 0)
	end
end

-- Orients Follow camera behind a subject using a world-space travel direction (XZ yaw).
-- Uses Scriptable for one frame so placement does not depend on Focus, which may still
-- reference the previous CameraSubject right after it changes (e.g. car swap).
function CameraController.snapBehindSubject(subject: BasePart, worldLookVector: Vector3, zoom: number?)
	local distance = zoom or STARTING_ZOOM
	local flat = Vector3.new(worldLookVector.X, 0, worldLookVector.Z)
	if flat.Magnitude < 1e-4 then
		flat = Vector3.new(0, 0, -1)
	else
		flat = flat.Unit
	end
	local yaw = math.atan2(-flat.X, -flat.Z)

	CameraController.setZoom(distance)

	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = subject
	camera.CFrame = CFrame.new(subject.Position) * CFrame.fromEulerAnglesYXZ(STARTING_PITCH, yaw, 0) * CFrame.new(0, 0, -distance)
	task.defer(function()
		if camera.CameraSubject == subject then
			camera.CameraType = DEFAULT_CAMERA_TYPE
		end
	end)
end

function CameraController.getStateMachine()
	return stateMachine
end

function CameraController.registerFOVJob(job: string, priority: number)
	fovJobs:Push(job, priority)
	return function()
		return fovJobs:Get() == priority
	end
end

function CameraController.releaseFOVJob(job: string)
	fovJobs:Pop(job)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	stateMachine:RegisterStateCallbacks("Default", function()
		camera.CameraType = DEFAULT_CAMERA_TYPE
		camera.FieldOfView = CameraController.DefaultFOV

		local character = player.Character
		if character then
			camera.CameraSubject = (character :: any):FindFirstChild("Humanoid")
		end

		CameraController.lookForward()
	end)

	local preShakeUpdate = shakeHandler.PreUpdate
	local postShakeUpdate = shakeHandler.PostUpdate
	RunService:BindToRenderStep("DefaultCameraShakePreUpdate", Enum.RenderPriority.Camera.Value + -1, function(dt)
		camera.CFrame *= preShakeUpdate(dt)
	end)
	RunService:BindToRenderStep("DefaultCameraShakePostUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
		camera.CFrame *= postShakeUpdate(dt)
	end)
end

return CameraController
