--!strict
local SpeedLines = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CharacterController = require(ReplicatedStorage.Client.Character.CharacterController)
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local CameraController = require(ReplicatedStorage.Client.Camera.CameraController)
local BasePartUtil = require(ReplicatedStorage.Shared.Utils.BasePartUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local UDim2Util = require(ReplicatedStorage.Shared.Utils.UDim2Util)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

local AXES = { "X", "Y" }

local DEBUG = DebugUtil.isDebugging(false)

local CHARACTER_BOUNDS_UPDATE_RATE = 0.3

local PARTICLE_TEMPLATE = Players.LocalPlayer.PlayerGui.SpeedLines.TEMP_PARTICLE
local PARTICLE_WIDTH = PARTICLE_TEMPLATE.Size.X.Scale
local PARTICLE_LENGTH = PARTICLE_TEMPLATE.Size.Y.Scale

local MIN_CHARACTER_BOUNDS_SIZE = { Y = 0.4, X = 0.65 }
local MAX_CHARACTER_BOUNDS_SIZE = { Y = 1, X = 1 }

local MIN_SPAWN_RADIUS = 0.2
local ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD = 0.55
local RADIUS_OFFSET_RANGE = 0.5

local SCALE_RANGE = 0.5

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()

local screen = Players.LocalPlayer.PlayerGui.SpeedLines
local characterBounds = screen.CharacterBounds
local particleConstructor = TemplateUtil.constructor(PARTICLE_TEMPLATE)

local camera = Workspace.CurrentCamera

local character: Model?
local humanoidRootPart: BasePart?
local characterSize: Vector3

local initalized: boolean
local enabled = true

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function SpeedLines.play(speed: number, rate: number, ease: number?, ignoreCalculations: boolean?)
	if not initalized or not enabled then
		return
	end

	local boundsPosition = characterBounds.Position
	local boundsWidth = characterBounds.Size.X.Scale / 2
	local boundsLength = characterBounds.Size.Y.Scale / 2

	local radiusOffset = if ignoreCalculations
		then 0
		else RADIUS_OFFSET_RANGE * (1 - math.abs(
			0.5
				- math.max(0, CameraController.getZoomFactor() - ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD)
					/ (1 - ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD)
		) / 0.5)

	for _ = 1, math.floor(rate) do
		local spawnRadius = random:NextNumber(0, MIN_SPAWN_RADIUS)
		local scale = if ignoreCalculations then 1 else 1 - (spawnRadius / MIN_SPAWN_RADIUS) * SCALE_RANGE

		-- Ellipse formula with radius = 1, and i solve for y
		local x = MathUtil.nextSign() * random:NextNumber(0, boundsWidth)
		local y = MathUtil.nextSign() * (boundsLength * math.sqrt(boundsWidth ^ 2 - x ^ 2)) / boundsWidth

		local particle = particleConstructor()
		particle.BackgroundTransparency = 1
		particle.Position = boundsPosition + UDim2.fromScale(x, y)
		particle.Size = UDim2.fromScale(scale * PARTICLE_WIDTH, scale * PARTICLE_LENGTH)
		particle.Rotation = math.deg(math.atan2(y, x)) - 90

		local line = particle.Line
		local lineLength = line.Size.Y.Scale
		line.Position -= UDim2.fromScale(0, lineLength * (spawnRadius - radiusOffset))
		line.ImageTransparency = if ignoreCalculations then 0 else random:NextNumber(1 - (ease or 1) * scale, 1)

		local tween = TweenService:Create(
			line.UIGradient,
			TweenInfo.new(MathUtil.ifNanThen0(1 / speed), Enum.EasingStyle.Sine, Enum.EasingDirection.In),
			{
				Offset = Vector2.new(0, 1),
			}
		)

		tween.Completed:Connect(function()
			particle:Destroy()
		end)

		tween:Play()
	end
end

function SpeedLines.clear()
	for _, frame in pairs(screen:GetChildren()) do
		if frame:IsA("Frame") and frame ~= characterBounds then
			frame.Visible = false
		end
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- CHARACTER
do
	CharacterController.registerLoadCallback(function(newCharacter)
		character = newCharacter

		humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		characterSize = character:GetExtentsSize()
	end)

	CharacterController.registerUnloadCallback(function()
		humanoidRootPart = nil
		character = nil
	end)
end

task.spawn(function()
	while true do
		if humanoidRootPart and enabled then
			local characterCFrame = (humanoidRootPart :: BasePart).CFrame

			local pointsOnScreen: { Vector3 } = {}
			for _, corner in pairs(BasePartUtil.CORNERS) do
				local point = camera:WorldToViewportPoint(characterCFrame:PointToWorldSpace(characterSize * corner))
				table.insert(pointsOnScreen, point)
			end

			local viewportSize = camera.ViewportSize
			local size = {}

			for _, axis in pairs(AXES) do
				local min = math.huge
				local max = -math.huge

				for _, point in pairs(pointsOnScreen) do
					local coord = (point :: any)[axis] :: number
					if coord < min then
						min = coord
					end
					if coord > max then
						max = coord
					end
				end

				size[axis] =
					math.clamp((max - min) / (viewportSize :: any)[axis], MIN_CHARACTER_BOUNDS_SIZE[axis], MAX_CHARACTER_BOUNDS_SIZE[axis])
			end

			characterBounds.Size = UDim2.fromScale(size.X, size.Y)

			-- The more zoomed in your are, the more centered the character bounds is
			local position = camera:WorldToViewportPoint(characterCFrame.Position)
			local fovWeight = 0.5 * CameraController.getThirdPersonZoomOutFactor()
			characterBounds.Position = UDim2Util.scalarMultiply(
				UDim2.fromScale(position.X / viewportSize.X, position.Y / viewportSize.Y),
				fovWeight
			) + UDim2Util.scalarMultiply(UDim2.fromScale(0.5, 0.5), 1 - fovWeight)

			initalized = true
		end

		task.wait(CHARACTER_BOUNDS_UPDATE_RATE)
	end
end)

screen.Enabled = true
characterBounds.Visible = DEBUG

return SpeedLines
