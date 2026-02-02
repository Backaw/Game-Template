--!strict
local CameraController = {}

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CFrameUtil = require(Shared.Utils.CFrameUtil)
local StateMachine = require(Shared.StateMachine)
local TableUtil = require(Shared.Utils.TableUtil)
local CameraUtil = require(Client.Utils.CameraUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_CAMERA_TYPE = Enum.CameraType.Custom

local FIRST_PERSON_THRESHOLD = 0.5
local STARTING_ZOOM = 17

local STATES = {
	Default = "Default",
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

local stateMachine = StateMachine.new(TableUtil.toArray(STATES), STATES.Default) :: StateMachine.StateMachine<State>

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

CameraController.DefaultFOV = 70
CameraController.States = STATES :: { [State]: State }

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

CameraController.registerShaker, CameraController.getShakeOffset =
	CameraUtil.getShakerRegistration(stateMachine, { STATES.Default, STATES.Driving, STATES.Unboxing, STATES.CarEditing } :: { State })

function CameraController.setZoom(zoom: number)
	local minZoom = player.CameraMinZoomDistance
	player.CameraMinZoomDistance = zoom
	player.CameraMinZoomDistance = minZoom
end

function CameraController.getZoom()
	return (camera.CFrame.Position - camera.Focus.Position).Magnitude
end

function CameraController.getZoomFactor()
	return CameraController.getZoom() / (player.CameraMaxZoomDistance - player.CameraMinZoomDistance)
end

function CameraController.isFirstPerson()
	return CameraController.getZoom() <= FIRST_PERSON_THRESHOLD
end

function CameraController.getThirdPersonZoomOutFactor()
	return math.max(0, CameraController.getZoom() - FIRST_PERSON_THRESHOLD)
		/ ((player.CameraMaxZoomDistance - player.CameraMinZoomDistance) - FIRST_PERSON_THRESHOLD)
end

function CameraController.lookForward()
	local character = player.Character
	camera.CameraType = DEFAULT_CAMERA_TYPE

	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if humanoidRootPart then
			camera.CFrame = CFrame.new(humanoidRootPart.Position)
				* CFrame.fromEulerAnglesYXZ(-math.rad(30), CFrameUtil.getYComponent(humanoidRootPart.CFrame), 0)
		end

		CameraController.setZoom(STARTING_ZOOM)
	end
end

function CameraController.getStateMachine()
	return stateMachine
end

function CameraController.init()
	local CharacterController = require(Client.Character.CharacterController) :: any
	CharacterController.registerLoadCallback(function()
		if stateMachine:GetState() == STATES.Default then
			camera.FieldOfView = CameraController.DefaultFOV
			CameraController.lookForward()
		end
	end)
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
end

return CameraController
