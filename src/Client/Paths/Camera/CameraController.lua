local CameraController = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local TweenableValue = require(Shared.TweenableValue)
local Shaker = require(Shared.Shaker)
local CFrameUtil = require(Shared.Utils.CFrameUtil)
local StateMachine = require(Shared.StateMachine)
local TableUtil = require(Shared.Utils.TableUtil)
local CharacterController

local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value

local FIRST_PERSON_THRESHOLD = 0.5
local STARTING_ZOOM = 18

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

local fieldOfView =
	TweenableValue.new("NumberValue", camera.FieldOfView, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
fieldOfView:BindToProperty(camera, "FieldOfView")

local stateMachine = StateMachine.new(TableUtil.toArray(CAMERA_STATES), CAMERA_STATES.Default)

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
CameraController.DefaultFOV = 70
CameraController.States = CAMERA_STATES

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CameraController.setFov(value: number, animationLength: number?)
	fieldOfView:Haste(value, animationLength or 0.3)
end

function CameraController.getFov()
	return fieldOfView:GetGoal()
end

function CameraController.resetFov(animationLength: number?)
	if animationLength then
		fieldOfView:HasteReset(animationLength or 0.3)
	else
		fieldOfView:TweenReset()
	end
end

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
	camera.CameraType = Enum.CameraType.Custom

	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		camera.CFrame = CFrame.new(humanoidRootPart.Position)
			* CFrame.Angles(-math.pi / 7, CFrameUtil.getYComponent(humanoidRootPart.CFrame), 0)
			* CFrame.new(0, 0, STARTING_ZOOM)
	end
end

function CameraController.registerShaker(shaker: Shaker.Shaker)
	table.insert(shakers, shaker)
end

function CameraController.getShakeOffset()
	return lastShakeOffset
end

function CameraController.init()
	CharacterController = require(Controllers.Character.CharacterController) :: typeof(require(Controllers.Character.CharacterController))
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
