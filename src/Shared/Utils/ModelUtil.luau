--!strict
local ModelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BasePartUtil = require(ReplicatedStorage.Shared.Utils.BasePartUtil)

local AXES = { X = true, Y = true, Z = true }

-- Get's a list of all parts inside a model and calls a function on them(mutator : (Instance) -> ())
function ModelUtil.forEachDescendantOfClass(model: Model, class: string, mutator: (Instance) -> ())
	for _, descendant in model:GetDescendants() do
		if descendant:IsA(class) then
			mutator(descendant)
		end
	end
end

function ModelUtil.createHitbox(model: Model)
	local cf, size = model:GetBoundingBox()

	local hitbox = Instance.new("Part")
	hitbox.Transparency = 1
	hitbox.Size = size
	hitbox.CanCollide = false
	hitbox.Massless = true
	hitbox.Anchored = true
	hitbox.CFrame = cf
	hitbox.Name = "Hitbox"

	return hitbox
end

function ModelUtil.sizeToPart(model: Model, part: BasePart)
	local modelCFrame = model:GetBoundingBox()
	local scale = part.Size / model:GetExtentsSize()
	local offsets: { [BasePart]: CFrame } = {}

	for _, v in model:GetDescendants() do
		if v:IsA("BasePart") then
			offsets[v] = modelCFrame:ToObjectSpace(v.CFrame)
			v.Size *= scale
		end
	end

	for desc, offset in offsets do
		desc.CFrame = modelCFrame:ToWorldSpace(offset)
	end
end

-- No rotation
function ModelUtil.getGlobalExtentsSize(model: Model | { BasePart }, offset: CFrame?, descendantChecker: ((BasePart) -> boolean)?)
	offset = if offset then offset.Rotation else CFrame.new()

	local minPosition = {}
	local maxPosition = {}
	local extentSize = {}

	for axis in pairs(AXES) do
		local min = math.huge
		local max = -math.huge

		for _, part in pairs(if typeof(model) == "table" then model else model:GetDescendants()) do
			if part:IsA("BasePart") then
				-- CONTINUE: Descendant isn't valid
				if descendantChecker and not descendantChecker(part) then
					continue
				end

				local cframe = CFrame.new(part.Position) * offset
				local size = BasePartUtil.getGlobalExtentsSize(part, offset) / 2
				local negativeSide = (offset:PointToObjectSpace(cframe:PointToWorldSpace(-size)) :: any)[axis] :: number
				local positiveSide = (offset:PointToObjectSpace(cframe:PointToWorldSpace(size)) :: any)[axis] :: number

				if negativeSide < min then
					min = negativeSide
				end
				if positiveSide > max then
					max = positiveSide
				end
			end
		end

		extentSize[axis] = math.abs(max - min)
		minPosition[axis] = min
		maxPosition[axis] = max
	end

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

	for _, basePart in next, model:QueryDescendants("BasePart") :: { BasePart } do
		assemblyMass += basePart:GetMass()
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

function ModelUtil.groupChildren(replacing: Instance)
	local group = Instance.new("Model")
	group.Name = replacing.Name
	group.Parent = replacing.Parent

	for _, child in pairs(replacing:GetChildren()) do
		child.Parent = group
	end

	replacing:Destroy()

	return group
end

return ModelUtil
