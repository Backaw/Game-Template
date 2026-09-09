--!strict
local Fireworks = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CharacterConstants = require(Shared.Character.CharacterConstants)
local ParticleEmitterUtil = require(Shared.Utils.ParticleEmitterUtil)
local StorageConstants = require(Shared.Constants.StorageConstants)
local RunServiceUtil = require(Shared.Utils.RunServiceUtil)
local _DebugUtil = require(Shared.Utils.DebugUtil)
local ObjectPool = require(Shared.ObjectPool)
local RayUtil = require(Shared.Utils.RayUtil)
local Shaker = require(Shared.Shaker)
local CameraController = require(Client.CameraController)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local COLOR_NAMES = { "Purple", "Green", "Blue", "Yellow", "Red" }
local COMBOS: { { ColorName } } = {
	{ "Purple", "Yellow" },
	{ "Red", "Blue" },
	{ "Green", "Purple" },
	{ "Yellow", "Red" },
	{ "Blue", "Green" },
	{ "Red", "Purple" },
	{ "Yellow", "Blue" },
	{ "Green", "Yellow" },
}

local FALL_RATIO = 0.15
local MIN_FALL_DISTANCE = 1.5
local MAX_FLIGHT_TIME = 5
local HIT_RADIUS = 2.5
local SCREEN_EMIT_DISTANCE = 30
local SCREEN_EMIT_DEPTH_MIN = 0.7
local SCREEN_EMIT_DEPTH_MAX = 1.3
local SCREEN_EMIT_DOWN_OFFSET = 40
local SCREEN_EMIT_DOWN_LENGTH = 150
local SCREEN_EMIT_HEIGHT_MIN = 8
local SCREEN_EMIT_HEIGHT_MAX = 18
local SCREEN_EMIT_BURST_GAP_MIN = 0.03
local SCREEN_EMIT_BURST_GAP_MAX = 0.08
local SCREEN_EMIT_VOLLEY_GAP_MIN = 0.4
local SCREEN_EMIT_VOLLEY_GAP_MAX = 0.9
local TARGETED_FLIGHT_SPEED = 28
local TARGETED_ARC_SAMPLES = 24

local CAMERA_ROT_IMPULSE = Vector3.new(0.08, 0.07, 0) * 0.45

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type ColorName = "Purple" | "Green" | "Blue" | "Yellow" | "Red"

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local random = Random.new()
local fireworkTemplate = StorageConstants.ReplicatedAssets.VFX.Firework
local fireworkExplosion = StorageConstants.ReplicatedAssets.VFX.FireworkExplosion

local fireworkPool = ObjectPool.new(function()
	local firework = fireworkTemplate:Clone()
	for _, descendant in firework:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
		end
	end
	return firework
end, nil, 3)

local emitterPools: { [string]: ObjectPool.ObjectPool<ParticleEmitterUtil.EmitterContainer> } = {}
for _, colorName in COLOR_NAMES do
	local template = fireworkExplosion:FindFirstChild(colorName)
	assert(template, `Missing firework explosion template: {colorName}`)
	emitterPools[colorName] = ParticleEmitterUtil.createContainerPool(ParticleEmitterUtil.getTemplateScriptFromDescendants(template), 2)
end

local cameraShaker =
	CameraController.registerShaker(Shaker.new({ Speed = 10, Stiffness = 4, Damping = 1 }, { Speed = 8, Stiffness = 10, Damping = 0.7 }))

local addFlightJob, removeFlightJob = RunServiceUtil.batchUpdateJobs(RunService.Heartbeat, "Firework")
local nextFlightId = 0

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Fireworks.emit(position: Vector3, sizeScale: number?)
	local combo = COMBOS[random:NextInteger(1, #COMBOS)]
	for _, colorName in combo do
		local pool = emitterPools[colorName]
		local emitter = pool:Get()
		emitter:Emit(CFrame.new(position), function()
			pool:Return(emitter)
		end, { Size = sizeScale })
	end
end

local function launch(
	origin: Vector3,
	velocity: Vector3,
	isDone: (Vector3, Vector3, number) -> boolean,
	onHit: ((Vector3) -> ())?,
	shakeScale: number,
	snapPosition: Vector3?,
	emit: boolean?,
	disableCameraShakes: boolean?
)
	local firework = fireworkPool:Get()
	local position = origin
	local along = Vector3.new(velocity.X, 0, velocity.Z)
	along = if along.Magnitude > 1e-3 then along.Unit else Vector3.zAxis
	local pitchAxis = (Vector3.yAxis :: Vector3):Cross(along)
	pitchAxis = if pitchAxis.Magnitude > 1e-3 then pitchAxis.Unit else Vector3.xAxis
	-- Nose is -RightVector; rest pose points it up, then we pitch in the flight plane.
	local restRotation = CFrame.fromMatrix(Vector3.zero, -Vector3.yAxis, along, -pitchAxis)

	local function pivotTo()
		local look = if velocity.Magnitude > 1e-3 then velocity.Unit else Vector3.yAxis
		firework:PivotTo(CFrame.new(position) * CFrame.fromAxisAngle(pitchAxis, math.atan2(look:Dot(along), look.Y)) * restRotation)
	end

	pivotTo()
	firework.Parent = Workspace.Terrain

	nextFlightId += 1
	local flightId = tostring(nextFlightId)
	local gravity = Workspace.Gravity
	local elapsed = 0
	addFlightJob(flightId, function(dt)
		elapsed += dt
		velocity += Vector3.new(0, -gravity * dt, 0)
		position += velocity * dt
		pivotTo()

		if isDone(position, velocity, elapsed) then
			removeFlightJob(flightId)
			fireworkPool:Return(firework)

			if not disableCameraShakes then
				cameraShaker:Impulse(CAMERA_ROT_IMPULSE * (shakeScale or 1), 0)
			end

			local hitPosition = snapPosition or position
			if emit ~= false then
				Fireworks.emit(hitPosition, shakeScale)
			end
			if onHit then
				onHit(hitPosition)
			end
		end
	end)
end

local function launchAtConstantSpeed(
	origin: Vector3,
	target: Vector3,
	arcHeight: number,
	onHit: ((Vector3) -> ())?,
	emit: boolean?,
	disableCameraShakes: boolean?
)
	local displacement = target - origin
	local horizontal = Vector3.new(displacement.X, 0, displacement.Z)
	local along = if horizontal.Magnitude > 1e-3 then horizontal.Unit else Vector3.zAxis
	local pitchAxis = (Vector3.yAxis :: Vector3):Cross(along)
	pitchAxis = if pitchAxis.Magnitude > 1e-3 then pitchAxis.Unit else Vector3.xAxis
	local restRotation = CFrame.fromMatrix(Vector3.zero, -Vector3.yAxis, along, -pitchAxis)
	local height = math.max(0, arcHeight)

	local function getPosition(alpha: number): Vector3
		return origin:Lerp(target, alpha) + Vector3.new(0, 4 * alpha * (1 - alpha) * height, 0)
	end

	local arcLengths = { 0 }
	local totalLength = 0
	local previous = origin
	for sample = 1, TARGETED_ARC_SAMPLES do
		local point = getPosition(sample / TARGETED_ARC_SAMPLES)
		totalLength += (point - previous).Magnitude
		arcLengths[sample + 1] = totalLength
		previous = point
	end

	local firework = fireworkPool:Get()
	local function pivotTo(position: Vector3, alpha: number)
		local tangent = displacement + Vector3.new(0, 4 * (1 - 2 * alpha) * height, 0)
		local look = if tangent.Magnitude > 1e-3 then tangent.Unit else along
		firework:PivotTo(CFrame.new(position) * CFrame.fromAxisAngle(pitchAxis, math.atan2(look:Dot(along), look.Y)) * restRotation)
	end

	pivotTo(origin, 0)
	firework.Parent = Workspace.Terrain
	nextFlightId += 1
	local flightId = tostring(nextFlightId)
	local traveled = 0
	addFlightJob(flightId, function(dt)
		traveled = math.min(totalLength, traveled + TARGETED_FLIGHT_SPEED * dt)
		local segment = 1
		while segment < TARGETED_ARC_SAMPLES and arcLengths[segment + 1] < traveled do
			segment += 1
		end
		local segmentStart = arcLengths[segment]
		local segmentLength = arcLengths[segment + 1] - segmentStart
		local segmentAlpha = if segmentLength > 0 then (traveled - segmentStart) / segmentLength else 1
		local alpha = ((segment - 1) + segmentAlpha) / TARGETED_ARC_SAMPLES
		pivotTo(getPosition(alpha), alpha)

		if traveled >= totalLength then
			removeFlightJob(flightId)
			fireworkPool:Return(firework)
			if not disableCameraShakes then
				cameraShaker:Impulse(CAMERA_ROT_IMPULSE, 0)
			end
			if emit ~= false then
				Fireworks.emit(target)
			end
			if onHit then
				onHit(target)
			end
		end
	end)
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Fireworks.launch(origin: Vector3, height: number, maxHeight: number, tilt: number?, yaw: number?, disableCameraShakes: boolean?)
	local peakHeight = math.clamp(height, 0, maxHeight)
	local gravity = Workspace.Gravity
	local launchCFrame = CFrame.Angles(0, yaw or random:NextNumber(0, math.pi * 2), 0) * CFrame.Angles(tilt or 0, 0, 0)
	local travelDirection = launchCFrame.UpVector
	local speed = math.sqrt(2 * gravity * peakHeight) / math.max(travelDirection.Y, 0.2)
	local fallDistance = math.max(MIN_FALL_DISTANCE, peakHeight * FALL_RATIO)
	local peakY = origin.Y
	local shakeScale = if maxHeight > 0 then peakHeight / maxHeight else 1

	launch(origin, travelDirection * speed, function(position, velocity, elapsed)
		if position.Y > peakY then
			peakY = position.Y
		end
		return (velocity.Y < 0 and peakY - position.Y >= fallDistance) or elapsed > MAX_FLIGHT_TIME
	end, nil, shakeScale, nil, nil, disableCameraShakes)
end

function Fireworks.launchAt(
	origin: Vector3,
	target: Vector3,
	onHit: ((Vector3) -> ())?,
	emit: boolean?,
	disableCameraShakes: boolean?,
	arcHeight: number?
)
	if arcHeight then
		launchAtConstantSpeed(origin, target, arcHeight, onHit, emit, disableCameraShakes)
		return
	end

	local gravity = Workspace.Gravity
	local displacement = target - origin
	local horizontal = Vector3.new(displacement.X, 0, displacement.Z)
	local extraArc = math.clamp(horizontal.Magnitude * 0.25, 6, 18)
	local flightTime = math.clamp(math.sqrt(2 * extraArc / gravity) + horizontal.Magnitude / 28, 0.45, 1.35)
	local verticalVelocity = displacement.Y / flightTime + 0.5 * gravity * flightTime
	local velocity = Vector3.new(displacement.X / flightTime, verticalVelocity, displacement.Z / flightTime)

	launch(origin, velocity, function(position, _, elapsed)
		return elapsed >= flightTime or (position - target).Magnitude <= HIT_RADIUS
	end, onHit, 1, target, emit, disableCameraShakes)
end

function Fireworks.screenOffsetEmit(count: number, _disableCameraShakes: boolean?)
	local camera = Workspace.CurrentCamera
	local viewport = camera.ViewportSize
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local character = Players.LocalPlayer.Character
	if character then
		params.FilterDescendantsInstances = { character }
	end

	local delay = 0
	local remaining = count
	while remaining > 0 do
		local roll = random:NextInteger(1, 10)
		local volley = if roll <= 5 then 1 elseif roll <= 8 then 2 else 3
		volley = math.min(volley, remaining)

		for index = 1, volley do
			local xOffset = random:NextNumber(-1, 1)
			xOffset *= math.abs(xOffset) -- pull toward center
			local screenX = 0.5 + 0.5 * xOffset
			local ray = camera:ViewportPointToRay(viewport.X * screenX, viewport.Y * 0.5)
			local depth = SCREEN_EMIT_DISTANCE * random:NextNumber(SCREEN_EMIT_DEPTH_MIN, SCREEN_EMIT_DEPTH_MAX)
			local sample = ray.Origin + ray.Direction * depth
			local ground =
				RayUtil.castDownwards(Vector3.new(sample.X, sample.Y + SCREEN_EMIT_DOWN_OFFSET, sample.Z), SCREEN_EMIT_DOWN_LENGTH, params)
			local minY = ground.Position.Y + random:NextNumber(SCREEN_EMIT_HEIGHT_MIN, SCREEN_EMIT_HEIGHT_MAX)
			local y = math.max(minY, camera.CFrame.Position.Y)
			local position = Vector3.new(sample.X, y, sample.Z)

			task.delay(delay, function()
				Fireworks.emit(position)
			end)
			if index < volley then
				delay += random:NextNumber(SCREEN_EMIT_BURST_GAP_MIN, SCREEN_EMIT_BURST_GAP_MAX)
			end
		end

		remaining -= volley
		if remaining > 0 then
			delay += random:NextNumber(SCREEN_EMIT_VOLLEY_GAP_MIN, SCREEN_EMIT_VOLLEY_GAP_MAX)
		end
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

_DebugUtil.onKeyDown(Enum.KeyCode.F, function()
	local character = Players.LocalPlayer.Character :: CharacterConstants.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end

	Fireworks.launch(root.Position - Vector3.new(0, -2, 0), 5, 10, math.rad(25))
end)

--[[ _DebugUtil.onKeyDown(Enum.KeyCode.J, function()
	Fireworks.screenOffsetEmit(6)
end) ]]

return Fireworks
