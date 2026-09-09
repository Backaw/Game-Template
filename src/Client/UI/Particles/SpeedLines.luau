--!strict
local SpeedLines = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local BasePartUtil = require(Shared.Utils.BasePartUtil)
local TemplateUtil = require(Shared.Utils.TemplateUtil)
local _DebugUtil = require(Shared.Utils.DebugUtil)
local MathUtil = require(Shared.Utils.MathUtil)
local ObjectPool = require(Shared.ObjectPool)
local Maid = require(Shared.Maid)
local CharacterController = require(Client.Character.CharacterController)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local AXES = { "X", "Y" }

local DEBUG = _DebugUtil.isDebugging(false)

local BASE_LIFETIME = 0.2

local MAX_SPAWN_DEVIATION = 0.2
local SCALE_RANGE = 0.4

local BASE_WIDTH = 0.02
local BASE_HEIGHT = 0.015
local WIDTH_VARIANCE = 0.03

local CHARACTER_BOUNDS_UPDATE_RATE = 0.3
local MIN_CHARACTER_BOUNDS_SIZE = { Y = 0.55, X = 0.8 }
local MAX_CHARACTER_BOUNDS_SIZE = { Y = 1, X = 1 }

--[[
local ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD = 0.55
local RADIUS_OFFSET_RANGE = 0.5
]]

--[[ local TEXTURES = {
	"rbxassetid://139967161055203",
	"rbxassetid://83307654246205",
	"rbxassetid://99693287487629",
} ]]

local TEXTURES = {
	-- 	"rbxassetid://106845652447574",
	"rbxassetid://85028901437611",
	"rbxassetid://76355635204474",
	"rbxassetid://123864353586234",
}

local COLORS = {
	White = Color3.fromRGB(233, 233, 233),
	Black = Color3.fromRGB(173, 157, 157),
	Grey = Color3.fromRGB(31, 31, 31),
}

local COLOR_WEIGHTS: { [Color3]: number } = {
	-- [Color3.fromRGB(255, 255, 255)] = 1,
	[COLORS.White] = 1,
	[COLORS.Black] = 1.6,
	[COLORS.Grey] = 1.6,
}

-- -- local COLOR_COUNT = TableUtil.length(COLOR_WEIGHTS)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local screenGui = player.PlayerGui.BackgroundParticles
local container = screenGui.SpeedLines
local characterBounds = container.CharacterBounds

local particleTemplate = container.TEMP_PARTICLE
local initLinePosition = (particleTemplate :: any).Line.Position :: UDim2
local particleConstructor = TemplateUtil.constructor(particleTemplate)

local particlePool = ObjectPool.new(particleConstructor, function(particle: any)
	particle.Visible = false

	local line = particle.Line
	line.Position = initLinePosition
	line.UIGradient.Offset = Vector2.new(0, 0)
	line.ImageTransparency = 1
end, 20)

local initialized: boolean
local enabled = true

local random = Random.new()

local session = Maid.new()

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

SpeedLines.Colors = COLORS

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

-- local getZoomFactor = CameraController.getThirdPersonZoomOutFactor

local function getRandomColor(forcedColor: Color3?): (Color3, number)
	if forcedColor then
		return forcedColor, COLOR_WEIGHTS[forcedColor] or 1.3
	else
		--[[ local colorIndex = random:NextInteger(1, 2)

		local i = 1
		for color, weight in pairs(COLOR_WEIGHTS) do
			if i == colorIndex then
				return color, weight
			end
			i += 1
		end ]]

		return Color3.fromRGB(255, 255, 255), 1
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function SpeedLines.play(speed: number, rate: number, ease: number?, forcedColor: Color3?, ignoreCalculations: boolean?)
	if not initialized or not enabled then
		return
	end

	if speed == 0 then
		error("Attempting to create a speed line with a speed of  0")
	end

	local boundsPosition = characterBounds.Position
	local boundsWidth = characterBounds.Size.X.Scale / 2
	local boundsLength = characterBounds.Size.Y.Scale / 2

	--[[ local radiusOffset = if ignoreCalculations
		then 0
		else RADIUS_OFFSET_RANGE * (1 - math.abs(
			0.5
				- math.max(0, CameraController.getZoomFactor() - ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD)
					/ (1 - ZOOM_RADIUS_OFFSET_EFFECT_THRESHOLD)
		) / 0.5) ]]

	local radiusOffset = 0

	for _ = 1, math.floor(rate) do
		local color, weight = getRandomColor(forcedColor)
		local spawnRadius = random:NextNumber(0, MAX_SPAWN_DEVIATION)
		local scale = (if ignoreCalculations then 1 else 1 - (spawnRadius / MAX_SPAWN_DEVIATION) * SCALE_RANGE) * (1 / weight)

		-- Ellipse formula with radius = 1, and i solve for y
		local pos_x = MathUtil.nextSign() * random:NextNumber(0, boundsWidth)
		local pos_y = MathUtil.nextSign() * (boundsLength * math.sqrt(boundsWidth ^ 2 - pos_x ^ 2)) / boundsWidth

		local size_x = scale * BASE_WIDTH + random:NextNumber(0, WIDTH_VARIANCE)
		local size_y = scale * BASE_HEIGHT

		local particle = particlePool:Get()
		particle.Visible = true
		particle.BackgroundTransparency = 1
		particle.Position = boundsPosition + UDim2.fromScale(pos_x, pos_y)

		particle.Size = UDim2.fromScale(size_x * 0, size_y)
		particle.Rotation = math.deg(math.atan2(pos_y, pos_x)) - 90

		local texture = TEXTURES[random:NextInteger(1, #TEXTURES)]
		local line = particle.Line
		line.ImageColor3 = color
		line.Image = texture
		line.Position -= UDim2.fromScale(0, line.Size.Y.Scale * (spawnRadius - radiusOffset))
		line.ImageTransparency = ease or 1

		-- Animate
		local duration = BASE_LIFETIME / speed
		local openTweenInfo = TweenInfo.new(duration * 0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

		TweenService:Create(line, openTweenInfo, {
			ImageTransparency = (if ignoreCalculations then 0 else random:NextNumber(1 - (ease or 1) * scale, 1)) * weight,
		}):Play()

		TweenService:Create(particle, openTweenInfo, {
			Size = UDim2.fromScale(size_x, size_y),
		}):Play()

		local closeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		--[[ local closeTween = TweenService:Create(line.UIGradient, closeTweenInfo, {
			Offset = Vector2.new(0, 1),
		}) ]]
		local closeTween = TweenService:Create(line, closeTweenInfo, {
			ImageTransparency = 1,
		})
		closeTween.Completed:Connect(function()
			particlePool:Return(particle)
		end)
		closeTween:Play()
		TweenService:Create(line, closeTweenInfo, {
			Position = UDim2.fromScale(0, line.Size.Y.Scale * 0.2),
		}):Play()
	end
end

function SpeedLines.clear()
	for _, frame in pairs(container:GetChildren()) do
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
	CharacterController.registerLoadCallback(function(character)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
		local characterSize = character:GetExtentsSize()

		session:Add(
			task.spawn(function()
				while true do
					task.wait(CHARACTER_BOUNDS_UPDATE_RATE)

					local characterCFrame = (humanoidRootPart :: BasePart).CFrame

					local pointsOnScreen: { Vector3 } = {}
					for _, corner in pairs(BasePartUtil.Corners) do
						local point = camera:WorldToViewportPoint((characterCFrame:PointToWorldSpace(characterSize * corner)))
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

						local axisSize = (max - min) / (viewportSize :: any)[axis]
						axisSize = math.clamp(axisSize, MIN_CHARACTER_BOUNDS_SIZE[axis], MAX_CHARACTER_BOUNDS_SIZE[axis])
						size[axis] = axisSize
					end

					characterBounds.Size = UDim2.fromScale(size.X, size.Y)

					local position = camera:WorldToViewportPoint(characterCFrame.Position)
					characterBounds.Position = UDim2.fromScale(position.X / viewportSize.X, position.Y / viewportSize.Y)

					--[[ -- The more zoomed in your are, the more centered the character bounds is for FIRST PERSON support
					local fovWeight = 0.5 * getZoomFactor()
					characterBounds.Position = UDimUtil.scalarMultiply(
						UDim2.fromScale(position.X / viewportSize.X, position.Y / viewportSize.Y),
						fovWeight
					) + UDimUtil.scalarMultiply(UDim2.fromScale(0.5, 0.5), 1 - fovWeight) ]]

					initialized = true
				end
			end),
			"SpeedLines"
		)

		--[[ task.spawn(function()
			while true do
				task.wait(0.1)
				print("HWHS")
				SpeedLines.play(0.3, 3, 0)
			end
		end) ]]
	end)

	CharacterController.registerUnloadCallback(function()
		initialized = false
		session:Cleanup()
	end)
end

do
	container.Visible = true
	characterBounds.Visible = DEBUG
	characterBounds.BackgroundTransparency = 0.8
end

return SpeedLines
