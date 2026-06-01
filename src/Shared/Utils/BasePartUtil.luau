--!strict
local BasePartUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SignedDistanceUtil = require(ReplicatedStorage.Shared.Utils.SignedDistanceUtil)

export type PsuedoBasePart = {
	Size: Vector3,
	CFrame: CFrame,
} | BasePart

local AXES = { X = true, Y = true, Z = true }

BasePartUtil.Corners = table.freeze({
	Vector3.new(0.5, 0.5, 0.5),
	Vector3.new(0.5, -0.5, 0.5),
	Vector3.new(-0.5, 0.5, 0.5),
	Vector3.new(-0.5, -0.5, 0.5),
	Vector3.new(0.5, 0.5, -0.5),
	Vector3.new(0.5, -0.5, -0.5),
	Vector3.new(-0.5, 0.5, -0.5),
	Vector3.new(-0.5, -0.5, -0.5),
})

-------------------------------------------------------------------------------
-- GETTERS
-------------------------------------------------------------------------------

-- Returns the size of a part's selection box
function BasePartUtil.getGlobalExtentsSize(part: PsuedoBasePart, offset: CFrame?): (Vector3, CFrame)
	offset = (if offset then offset.Rotation else CFrame.new()) :: CFrame

	local cframe = part.CFrame
	local size = part.Size

	local extentSize = {}
	for axis in pairs(AXES) do
		local min = math.huge
		local max = -math.huge

		for _, corner in BasePartUtil.Corners do
			local position = (offset:PointToObjectSpace(cframe:PointToWorldSpace(size * corner)) :: any)[axis] :: number
			if position < min then
				min = position
			end
			if position > max then
				max = position
			end
		end

		extentSize[axis] = max - min
	end

	return Vector3.new(extentSize.X, extentSize.Y, extentSize.Z), CFrame.new(cframe.Position)
end

-- Return's the center point of a basepart's face
function BasePartUtil.getSurfacePosition(part: PsuedoBasePart, surfaceDirection: Vector3)
	local size = part.Size
	return part.CFrame:PointToWorldSpace((size / 2 * surfaceDirection * Vector3.new(1, 1, -1)))
end

-- Return's the size of a basepart's face
function BasePartUtil.getGlobalSurfaceExtentSize(part: PsuedoBasePart, surfaceDirection: Vector3, offset: CFrame?)
	local size = part.Size
	return BasePartUtil.getGlobalExtentsSize({
		Size = size * Vector3.new(1 - math.abs(surfaceDirection.X), 1 - math.abs(surfaceDirection.Y), 1 - math.abs(surfaceDirection.Z)),
		CFrame = part.CFrame:ToWorldSpace(CFrame.new(size / 2 * surfaceDirection * Vector3.new(1, 1, -1))),
	}, offset)
end

function BasePartUtil.getVolume(part: BasePart)
	local size = part.Size
	return size.X * size.Y * size.Z
end

--[[
	Get's the closest point on (part0) relative to (part1)
	https://gyazo.com/bb07488c23150458759755706a451cef
]]
function BasePartUtil.closestPoint(part0: PsuedoBasePart, part1: PsuedoBasePart): Vector3
	local closestPoint: Vector3
	local minDistance: number = math.huge

	local origin: Vector3 = part0.CFrame.Position

	local part1Size: Vector3 = part1.Size
	local part1CFrame: CFrame = part1.CFrame
	for _, corner in BasePartUtil.Corners do
		local closestPointToCorner =
			SignedDistanceUtil.getClosestPointOnBox(part0 :: BasePart, part1CFrame:PointToWorldSpace(part1Size * corner))

		local distanceToCorner = (closestPointToCorner - origin).Magnitude
		if distanceToCorner < minDistance then
			minDistance = distanceToCorner
			closestPoint = closestPointToCorner
		end
	end

	return closestPoint
end

-------------------------------------------------------------------------------
-- UTIL
-------------------------------------------------------------------------------

-- Welds two baseparts together
function BasePartUtil.weldTo(part0: BasePart, part1: BasePart, weldParent: BasePart?)
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Name = ("%s>%s"):format(part0.Name, part1.Name)
	weldConstraint.Part0 = part0
	weldConstraint.Part1 = part1
	weldConstraint.Parent = weldParent or part0

	return weldConstraint
end

function BasePartUtil.weldToAutoC0(part0: BasePart, part1: BasePart, parent: Instance?)
	local weld = Instance.new("Weld")
	weld.Name = ("%s>%s"):format(part0.Name, part1.Name)
	weld.Part0 = part0
	weld.Part1 = part1
	weld.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	weld.Parent = parent or part0

	return weld
end

return BasePartUtil
