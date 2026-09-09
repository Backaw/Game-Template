--!strict
local ScreenConfetti = {}

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local ScreenParticle = require(Client.UI.Particles.ScreenParticle)
local ObjectPool = require(Shared.ObjectPool)
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Config = {
	Parent: GuiObject?,
	Position: UDim2?,
	ParticleCount: number?,
	ExplosionRadius: number?,
	SizeMin: Vector2?,
	SizeMax: Vector2?,
	Colors: { Color3 }?,
	Image: string?,
}

export type WaterfallConfig = {
	Parent: Instance?,
	ParticleCount: number?,
	SizeMin: Vector2?,
	SizeMax: Vector2?,
	Colors: { Color3 }?,
	Image: string?,
	TimeScale: number?,
	LayerCount: number?,
	LayerFallDelay: number?,
}

type Particle = ImageLabel

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_PARTICLE_COUNT = 40
local DEFAULT_EXPLOSION_RADIUS = 90
local DEFAULT_SIZE_MIN = Vector2.new(6, 10)
local DEFAULT_SIZE_MAX = Vector2.new(14, 18)
local TIME_SCALE = 2.1

local GRAVITY = 500 * TIME_SCALE
local BURST_SPEED_MIN = 220
local BURST_SPEED_MAX = 420
local UPWARD_BIAS = 160

local WATERFALL_GRAVITY = 900
local WATERFALL_FALL_GRAVITY = 130
local WATERFALL_UPWARD_SPEED_MIN = 680
local WATERFALL_UPWARD_SPEED_MAX = 920
local WATERFALL_DRIFT_MAX = 70
local WATERFALL_LIFETIME = NumberRange.new(5.5, 7.5)
local WATERFALL_LAYER_COUNT = 5
local WATERFALL_LAYER_FALL_DELAY = 0.38

local LIFETIME = NumberRange.new(2 / TIME_SCALE, 3.5 / TIME_SCALE)
local FADE_DURATION = 0.6 / TIME_SCALE

local ROTATION_SPEED_MIN = 180 * TIME_SCALE
local ROTATION_SPEED_MAX = 720 * TIME_SCALE

local GUI_INSET = GuiService:GetGuiInset()

local COLORS = {
	Color3.fromRGB(184, 114, 255),
	Color3.fromRGB(51, 184, 255),
	Color3.fromRGB(196, 255, 87),
	Color3.fromRGB(220, 52, 36),
	Color3.fromRGB(238, 220, 77),
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local random = Random.new()
local screen = ComponentUtil.getPlayerGui().ForegroundParticles
local sharedContainer: Frame? = nil

local particlePool = ObjectPool.new(function()
	local particle = Instance.new("ImageLabel")
	particle.AnchorPoint = Vector2.new(0.5, 0.5)
	particle.BorderSizePixel = 0
	particle.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 2)
	corner.Parent = particle
	return particle
end)

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function createContainer(name: string, parent: Instance): Frame
	--[[ if parent:IsA("ScreenGui") then
		parent.Enabled = true
	end ]]

	local container = Instance.new("Frame")
	container.Name = name
	container.Size = UDim2.fromScale(1, 1)
	container.BackgroundTransparency = 1
	container.Parent = parent

	Instance.new("UIScale").Parent = container

	return container
end

local function resolveContainer(parent: Instance?, name: string): (Frame, (GuiObject) -> (), () -> (), () -> ())
	local owned = parent ~= nil
	local container: Frame
	if parent then
		container = createContainer(name, parent)
	elseif sharedContainer and sharedContainer.Parent then
		container = sharedContainer
	else
		container = createContainer("ScreenConfetti", screen)
		sharedContainer = container
	end

	local remaining = 0
	local function noteEmit()
		remaining += 1
	end
	local function onReturned(gui: GuiObject)
		particlePool:Return(gui :: Particle)
		remaining -= 1
		if owned and remaining == 0 and container.Parent then
			container:Destroy()
		end
	end
	local function flush()
		if owned and remaining == 0 and container.Parent then
			container:Destroy()
		end
	end
	return container, onReturned, noteEmit, flush
end

local function emitConfetti(
	container: Frame,
	position: UDim2,
	sizeMin: Vector2,
	sizeMax: Vector2,
	color: Color3,
	gravity: number,
	getVelocity: () -> Vector2,
	image: string?,
	onReturned: (GuiObject) -> (),
	noteEmit: () -> (),
	lifetimeRange: NumberRange?,
	fallGravity: number?,
	fallGravityDelay: number?
)
	local w = random:NextNumber(sizeMin.X, sizeMax.X)
	local h = random:NextNumber(sizeMin.Y, sizeMax.Y)
	local rotationSpeed = random:NextNumber(ROTATION_SPEED_MIN, ROTATION_SPEED_MAX) * (if random:NextNumber(0, 1) > 0.5 then 1 else -1)
	local range = lifetimeRange or LIFETIME
	local lifetime = random:NextNumber(range.Min, range.Max)
	local fadeStartAlpha = math.max(0, 1 - FADE_DURATION / lifetime)

	ScreenParticle.emit({
		Parent = container,
		Count = 1,
		Position = position,
		Lifetime = NumberRange.new(lifetime, lifetime),
		Gravity = gravity,
		FallGravity = fallGravity,
		FallGravityDelay = fallGravityDelay,
		Create = function()
			noteEmit()
			local particle = particlePool:Get()
			particle.Size = UDim2.fromOffset(w, h)
			particle.Rotation = random:NextNumber(0, 360)
			if image then
				particle.Image = image
				particle.ImageColor3 = color
				particle.ImageTransparency = 0
				particle.BackgroundTransparency = 1
			else
				particle.Image = ""
				particle.BackgroundColor3 = color
				particle.BackgroundTransparency = 0
			end
			return particle
		end,
		Return = onReturned,
		GetVelocity = getVelocity,
		OnUpdate = function(gui, alpha, dt)
			gui.Rotation += rotationSpeed * dt
			if alpha > fadeStartAlpha then
				local transparency = (alpha - fadeStartAlpha) / math.max(1e-3, 1 - fadeStartAlpha)
				if image then
					(gui :: Particle).ImageTransparency = transparency
				else
					gui.BackgroundTransparency = transparency
				end
			end
		end,
	})
end

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

ScreenConfetti.Colors = COLORS

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ScreenConfetti.explode(config: Config?)
	local cfg = config or {} :: Config
	local position = cfg.Position or UDim2.new(0.5, 0, 0.5, GUI_INSET.Y)
	local particleCount = cfg.ParticleCount or DEFAULT_PARTICLE_COUNT
	local explosionRadius = cfg.ExplosionRadius or DEFAULT_EXPLOSION_RADIUS
	local sizeMin = cfg.SizeMin or DEFAULT_SIZE_MIN
	local sizeMax = cfg.SizeMax or DEFAULT_SIZE_MAX
	local colors = cfg.Colors or COLORS

	local radialScale = explosionRadius / DEFAULT_EXPLOSION_RADIUS
	local container, onReturned, noteEmit, flush = resolveContainer(cfg.Parent, "ScreenConfetti")
	local image = cfg.Image

	for _ = 1, particleCount do
		local color = colors[random:NextInteger(1, #colors)]
		emitConfetti(container, position, sizeMin, sizeMax, color, GRAVITY, function()
			local angle = random:NextNumber(0, math.pi * 2)
			local radiusFactor = random:NextNumber(0.4, 1)
			local speed = random:NextNumber(BURST_SPEED_MIN, BURST_SPEED_MAX) * radiusFactor * radialScale * TIME_SCALE
			return Vector2.new(math.cos(angle) * speed, math.sin(angle) * speed - UPWARD_BIAS * TIME_SCALE)
		end, image, onReturned, noteEmit)
	end
	flush()
end

function ScreenConfetti.waterfall(config: WaterfallConfig?)
	local cfg = config or {} :: WaterfallConfig
	local particleCount = cfg.ParticleCount or DEFAULT_PARTICLE_COUNT
	local sizeMin = cfg.SizeMin or DEFAULT_SIZE_MIN
	local sizeMax = cfg.SizeMax or DEFAULT_SIZE_MAX
	local colors = cfg.Colors or COLORS
	local timeScale = cfg.TimeScale or 1
	local layerCount = cfg.LayerCount or WATERFALL_LAYER_COUNT
	local layerFallDelay = (cfg.LayerFallDelay or WATERFALL_LAYER_FALL_DELAY) / timeScale

	local container, onReturned, noteEmit, flush = resolveContainer(cfg.Parent, "ScreenConfettiWaterfall")
	local image = cfg.Image
	local gravity = WATERFALL_GRAVITY * timeScale * timeScale
	local fallGravity = WATERFALL_FALL_GRAVITY * timeScale * timeScale
	local lifetime = NumberRange.new(WATERFALL_LIFETIME.Min / timeScale, WATERFALL_LIFETIME.Max / timeScale)
	local avgUpSpeed = (WATERFALL_UPWARD_SPEED_MIN + WATERFALL_UPWARD_SPEED_MAX) * 0.5 * timeScale
	local peakTime = avgUpSpeed / gravity

	for i = 1, particleCount do
		local layer = (i - 1) % layerCount
		local color = colors[random:NextInteger(1, #colors)]
		local originX = random:NextNumber(0, 1)
		local originY = random:NextNumber(0.28, 0.34)
		local fallGravityDelay = peakTime + layer * layerFallDelay

		emitConfetti(container, UDim2.fromScale(originX, originY), sizeMin, sizeMax, color, gravity, function()
			local upSpeed = random:NextNumber(WATERFALL_UPWARD_SPEED_MIN, WATERFALL_UPWARD_SPEED_MAX) * timeScale
			local drift = random:NextNumber(-WATERFALL_DRIFT_MAX, WATERFALL_DRIFT_MAX) * timeScale
			return Vector2.new(drift, -upSpeed)
		end, image, onReturned, noteEmit, lifetime, fallGravity, fallGravityDelay)
	end
	flush()
end

return ScreenConfetti
