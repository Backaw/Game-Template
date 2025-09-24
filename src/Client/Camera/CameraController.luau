--!strict
local CameraController = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shaker = require(ReplicatedStorage.Shared.Shaker)
local CFrameUtil = require(ReplicatedStorage.Shared.Utils.CFrameUtil)
local StateMachine = require(ReplicatedStorage.Shared.StateMachine)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local CharacterController

local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value
local DEFAULT_CAMERA_TYPE = Enum.CameraType.Custom

local FIRST_PERSON_THRESHOLD = 0.5
local STARTING_ZOOM = 17

local CAMERA_STATES = {
	Default = "Default",
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local shakers: { Shaker.Shaker } = {}
local lastShakeOffset: CFrame

local stateMachine = StateMachine.new(TableUtil.toArray(CAMERA_STATES), CAMERA_STATES.Default)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
CameraController.DefaultFOV = 70
CameraController.States = CAMERA_STATES

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
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
				* CFrame.Angles(-math.rad(30), CFrameUtil.getYComponent(humanoidRootPart.CFrame), 0)
		end

		CameraController.setZoom(STARTING_ZOOM)
	end
end

function CameraController.registerShaker(shaker: Shaker.Shaker)
	table.insert(shakers, shaker)
end

function CameraController.getShakeOffset()
	return lastShakeOffset
end

function CameraController.init()
	CharacterController = require(ReplicatedStorage.Client.Character.CharacterController) :: any
	CharacterController.registerLoadCallback(CameraController.lookForward)

	-- Reset camera to default when the character is unloaded
	-- But happens after everything else, so doesn't interfere with stuff that clean themselves up
	CharacterController.registerUnloadCallback(function()
		stateMachine:PopUpToExclusive(CAMERA_STATES.Default)
	end, 0)
end

function CameraController.getStateMachine()
	return stateMachine
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	RunService:BindToRenderStep("CameraControllerBefore", RENDER_PRIORITY - 10, function()
		if lastShakeOffset then
			camera.CFrame *= lastShakeOffset:Inverse()
		end
	end)

	RunService:BindToRenderStep("CameraControllerAfter", RENDER_PRIORITY + 10, function(dt)
		dt = 0.015

		lastShakeOffset = CFrame.new()
		for _, shaker in shakers do
			lastShakeOffset *= shaker:Update(dt)
		end

		camera.CFrame *= lastShakeOffset
	end)
end

return CameraController
