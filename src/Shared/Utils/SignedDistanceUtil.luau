--!strict
--[[
	Functions that calculate the orthogonal distance of a given point (from) to the boundary of a primitive shape
]]

local SignedDistanceUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vector3Util = require(ReplicatedStorage.Shared.Utils.Vector3Util)

-- https://www.youtube.com/watch?v=62-pRVZuS5c&t=131s
function SignedDistanceUtil.getClosestPointOnBox(box: BasePart, from: Vector3): Vector3
	local cframe = box.CFrame
	local offset = cframe:PointToObjectSpace(from)
	local halfSize = box.Size / 2

	local distance = Vector3Util.max(Vector3Util.abs(offset) - halfSize, Vector3.new()) -- Only exterior
	return cframe:PointToWorldSpace(offset - (distance * Vector3Util.sign(offset)))
end

function SignedDistanceUtil.getClosestPointOnSphere(sphere: BasePart, from: Vector3): Vector3
	local size = sphere.Size

	local cframe = sphere.CFrame
	return sphere.CFrame * (Vector3Util.getUnit(cframe:PointToObjectSpace(from)) * (math.min(size.X, size.Y, size.Z) / 2))
end

return SignedDistanceUtil
