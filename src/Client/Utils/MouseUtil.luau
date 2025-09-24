--!strict
local MouseUtil = {}

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)
local RayUtil = require(ReplicatedStorage.Shared.Utils.RayUtil)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local camera = Workspace.CurrentCamera
local behavior: Enum.MouseBehavior = UserInputService.MouseBehavior

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MouseUtil.setMouseBehavior(newBehavior: Enum.MouseBehavior?)
	UserInputService.MouseBehavior = newBehavior or Enum.MouseBehavior.Default
end

function MouseUtil.getMouseScreenPosition()
	if InputUtil.isMobile() and behavior == Enum.MouseBehavior.LockCenter then
		return Workspace.CurrentCamera.ViewportSize / 2
	else
		return UserInputService:GetMouseLocation()
	end
end

function MouseUtil.getUnitRay()
	local screenPosition = MouseUtil.getMouseScreenPosition()
	return camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
end

function MouseUtil.castUnitRay(distance: number?, raycastParams: RaycastParams?)
	local ray = MouseUtil.getUnitRay()
	return RayUtil.customCast(ray.Origin, ray.Direction * (distance or 1), raycastParams)
end

function MouseUtil.getMouseWorldPosition(distance: number?, raycastParams: RaycastParams?)
	return MouseUtil.castUnitRay(distance, raycastParams).Position
end

return MouseUtil
