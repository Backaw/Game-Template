--!strict
local DebugUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

function DebugUtil.isDebugging(toggle: boolean)
	return if GameUtil.isLive() then false else toggle
end

function DebugUtil.previewCFrame(cframe: CFrame, size: Vector3?, color: Color3?, shape: Enum.PartType?)
	local preview = Instance.new("Part")
	preview.Size = size or Vector3.new(1, 1, 1)
	preview.CFrame = cframe
	preview.Color = color or Color3.fromRGB(0, 0, 0)
	preview.Anchored = true
	preview.CanTouch = false
	preview.CanQuery = false
	preview.Shape = shape or Enum.PartType.Wedge
	preview.CanCollide = false
	preview.Parent = Workspace

	return preview
end

function DebugUtil.pointerGizmo(parent: BasePart, color: Color3?, length: number?)
	local gizmo = Instance.new("LineHandleAdornment") -- Points in direction of velocity
	gizmo.Adornee = parent
	gizmo.AlwaysOnTop = true
	gizmo.Color3 = color or Color3.fromRGB(0, 180, 255)
	gizmo.Parent = parent
	gizmo.Thickness = 3
	gizmo.Length = length or 5
	gizmo.Visible = true

	return gizmo
end

function DebugUtil.truncateVector3(vector: Vector3, precision: number)
	return Vector3.new(
		MathUtil.precision(vector.X, precision),
		MathUtil.precision(vector.Y, precision),
		MathUtil.precision(vector.Z, precision)
	)
end

function DebugUtil.printVector3(vector: Vector3, precision: number?)
	local p = precision or 3
	local formatStr = string.format("(%%.%df, %%.%df, %%.%df)", p, p, p)
	return (formatStr :: any):format(vector.X, vector.Y, vector.Z)
end

return DebugUtil
