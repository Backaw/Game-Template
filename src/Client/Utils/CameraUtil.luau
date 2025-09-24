--!strict
local CameraUtil = {}

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full height is in view
]]
function CameraUtil.getFitDepthY(fov: number, subjectSize: Vector3): number
	return (subjectSize.Y / 2) / math.tan(math.rad(fov / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject's full width is in view
]]
function CameraUtil.getFitDepthX(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
	local aspectRatio = viewportSize.X / viewportSize.Y

	return (subjectSize.X / 2) / math.tan(math.rad(fov * aspectRatio / 2)) + (subjectSize.Z / 2)
end

--[[
    Returns how far away from it's subject a camera should be positioned so that the subject is in view
]]
function CameraUtil.getFitDepth(viewportSize: Vector2, fov: number, subjectSize: Vector3): number
	return math.max(CameraUtil.getFitDepthY(fov, subjectSize), CameraUtil.getFitDepthX(viewportSize, fov, subjectSize))
end

return CameraUtil
