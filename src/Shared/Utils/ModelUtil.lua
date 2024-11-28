local ModelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasePartUtil = require(ReplicatedStorage.Modules.Utils.BasePartUtil)
local Vector3Util = require(ReplicatedStorage.Modules.Utils.Vector3Util)

-- Get's a list of all parts inside a model and calls a function on them(mutator : (Instance) -> ())
function ModelUtil.forEachDescendantOfClass(model: Model, class: string, mutator: (Instance) -> ())
	for _, descendant in model:GetDescendants() do
		if descendant:IsA(class) then
			mutator(descendant)
		end
	end
end

-- No rotation
function ModelUtil.getGlobalExtentsSize(model: Model | { Instance }, offset: CFrame?, descendantChecker: ((BasePart) -> boolean)?)
	offset = if offset then offset.Rotation else CFrame.new()

	local minPosition = {}
	local maxPosition = {}
	local extentSize = {}

	Vector3Util.forEveryAxis(function(axis)
		local min = math.huge
		local max = -math.huge

		for _, part in (if typeof(model) == "table" then model else model:GetDescendants()) do
			-- CONTINUE: Descendant isn't valid
			if not (part:IsA("BasePart") and (if descendantChecker then descendantChecker(part) else true)) then
				continue
			end

			local cframe = CFrame.new(part.Position) * offset
			local size = BasePartUtil.getGlobalExtentsSize(part, offset) / 2
			local negativeSide = offset:PointToObjectSpace(cframe:PointToWorldSpace(-size))[axis]
			local positiveSide = offset:PointToObjectSpace(cframe:PointToWorldSpace(size))[axis]

			if negativeSide < min then
				min = negativeSide
			end
			if positiveSide > max then
				max = positiveSide
			end
		end

		extentSize[axis] = math.abs(max - min)
		minPosition[axis] = min
		maxPosition[axis] = max
	end)

	local center = (Vector3.new(minPosition.X, minPosition.Y, minPosition.Z) + Vector3.new(maxPosition.X, maxPosition.Y, maxPosition.Z)) / 2
	return Vector3.new(extentSize.X, extentSize.Y, extentSize.Z), offset.Rotation * CFrame.new(center)
end

function ModelUtil.centerAt(model: Model, center: CFrame, sizeOffset: Vector3?)
	sizeOffset = sizeOffset or Vector3.new()

	local cframe: CFrame, size: Vector3 = model:GetBoundingBox()
	local pivotPosition = if model.PrimaryPart then model.PrimaryPart.Position else cframe.Position

	model:PivotTo(center * CFrame.new(cframe:PointToObjectSpace(pivotPosition) + size * sizeOffset))
end

function ModelUtil.setPrimaryPart(model: Model, primaryPart: BasePart, name: string?)
	model.PrimaryPart = primaryPart
	primaryPart.PivotOffset = CFrame.new()
	primaryPart.Name = name or primaryPart.Name
end

function ModelUtil.getAssemblyMass(model: Model)
	local assemblyMass = 0

	for _, basePart in model:GetChildren() do
		if basePart:IsA("BasePart") then
			assemblyMass += basePart.Mass
		end
	end

	return if assemblyMass == 0 then 1 else assemblyMass
end

function ModelUtil.anchor(model: Model)
	for _, basePart in model:GetDescendants() do
		if basePart:IsA("BasePart") then
			basePart.Anchored = true
		end
	end
end

return ModelUtil
