local CameraController = {}

local RunService = game:GetService("RunService")

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local TweenableValue = require(Paths.Shared.TweenableValue)
local Shaker = require(Paths.Shared.Shaker)

local FIRST_PERSON_THRESHOLD = 0.5

local RENDER_PRIORITY = Enum.RenderPriority.Camera.Value

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local lastShakeOffset: CFrame
local shakers: { Shaker.Shaker } = {}

local fieldOfView =
	TweenableValue.new("NumberValue", camera.FieldOfView, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out))
fieldOfView:BindToProperty(camera, "FieldOfView")

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
	if character then
		camera.CFrame = CFrame.new(camera.CFrame.Position) * character:WaitForChild("HumanoidRootPart").CFrame.Rotation
	end
end

function CameraController.registerShaker(shaker: Shaker.Shaker)
	table.insert(shakers, shaker)
end

function CameraController.getShakeOffset()
	return lastShakeOffset
end

function CameraController.loadCharacter(character)
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = character:WaitForChild("Humanoid")
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
RunService:BindToRenderStep("CameraShake", RENDER_PRIORITY, function(dt)
	lastShakeOffset = CFrame.new()
	for _, shaker in  (shakers) do
		lastShakeOffset *= shaker:Update(dt)
	end
	camera.CFrame *= lastShakeOffset
end)

return CameraController
