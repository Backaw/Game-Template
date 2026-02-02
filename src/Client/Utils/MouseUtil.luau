--!strict
local MouseUtil = {}

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RayUtil = require(ReplicatedStorage.Shared.Utils.RayUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local LOCK_CENTER_POSITION = Vector2.new(0.5, 0.35)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local camera = Workspace.CurrentCamera
local behavior: Enum.MouseBehavior = UserInputService.MouseBehavior

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function MouseUtil.setMouseBehavior(newBehavior: Enum.MouseBehavior?)
	newBehavior = newBehavior or Enum.MouseBehavior.Default
	UserInputService.MouseBehavior = newBehavior
	behavior = newBehavior
end

function MouseUtil.getMouseScreenPosition()
	if behavior == Enum.MouseBehavior.LockCenter then
		return Workspace.CurrentCamera.ViewportSize * LOCK_CENTER_POSITION
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
	local raycastResult = MouseUtil.castUnitRay(distance, raycastParams)
	return raycastResult.Position, raycastResult.Instance
end

return MouseUtil
