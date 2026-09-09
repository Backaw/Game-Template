--!strict
local Sparkles = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ComponentUtil = require(ReplicatedStorage.Client.UI.Utils.ComponentUtil)
local ScreenParticle = require(ReplicatedStorage.Client.UI.Particles.ScreenParticle)
local ColorUtil = require(ReplicatedStorage.Shared.Utils.ColorUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type BurstConfig = {
	Parent: GuiObject?,
	Position: UDim2?,
	Count: number?,
	Color: (Color3 | { Color3 })?,
	Size: NumberRange?,
	Velocity: NumberRange?,
	Lifetime: NumberRange?,
	FadeOut: NumberRange?,
	ZIndex: number?,
}

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local SPARKLE_IMAGES = {
	-- "rbxassetid://72276002116852",
	"rbxassetid://12386386944",
	"rbxassetid://81476801210365",
	-- 	"rbxassetid://14198353638",
	"rbxassetid://17068400400",
	"rbxassetid://17062454806",
}

local DEFAULT_COUNT = 6
local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)
local DEFAULT_SIZE = NumberRange.new(16, 28)
local DEFAULT_VELOCITY = NumberRange.new(50, 120)
local DEFAULT_LIFETIME = NumberRange.new(0.55, 0.9)
local DEFAULT_SHRINK = NumberRange.new(0.2, 0.4)
local DEFAULT_SPIN = NumberRange.new(-220, 220)
local DEFAULT_TWINKLE = NumberRange.new(0.2, 0.4)
local DEFAULT_TWINKLE_SPEED = NumberRange.new(10, 16)
local DEFAULT_FADE_IN = NumberRange.new(0.05, 0.12)
local DEFAULT_FADE_OUT = NumberRange.new(0.45, 0.8)
local PEAK_TRANSPARENCY = 0.1
local BLINK_BRIGHTNESS = 0.28

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local random = Random.new()
local sharedContainer: Frame? = nil

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function Sparkles.burst(config: BurstConfig)
	local parent = config.Parent
	if not parent then
		local container = sharedContainer
		local foreground = ComponentUtil.getPlayerGui().ForegroundParticles
		if foreground:IsA("ScreenGui") then
			foreground.Enabled = true
		end
		if not container or not container.Parent then
			container = Instance.new("Frame")
			container.Name = "ScreenParticles"
			container.Size = UDim2.fromScale(1, 1)
			container.BackgroundTransparency = 1
			container.BorderSizePixel = 0
			container.ZIndex = 50
			container.Parent = foreground
			sharedContainer = container
		end
		if container.AbsoluteSize.X < 1 then
			local viewport = workspace.CurrentCamera.ViewportSize
			container.Size = UDim2.fromOffset(viewport.X, viewport.Y)
		end
		parent = container
	end
	assert(parent)

	local colorConfig = config.Color
	local palette: { Color3 }
	if typeof(colorConfig) == "Color3" then
		palette = { colorConfig }
	elseif type(colorConfig) == "table" and #(colorConfig :: { Color3 }) > 0 then
		palette = colorConfig :: { Color3 }
	else
		palette = { DEFAULT_COLOR }
	end
	local sizeRange = config.Size or DEFAULT_SIZE
	local velocityRange = config.Velocity or DEFAULT_VELOCITY
	local lifetimeRange = config.Lifetime or DEFAULT_LIFETIME
	local fadeOutRange = config.FadeOut or DEFAULT_FADE_OUT
	local count = config.Count or DEFAULT_COUNT
	local particleZIndex = config.ZIndex or 20

	for _ = 1, count do
		local color = palette[random:NextInteger(1, #palette)]
		local brightColor = ColorUtil.addValue(color, BLINK_BRIGHTNESS)
		local lifetime = random:NextNumber(lifetimeRange.Min, lifetimeRange.Max)
		local startSize = random:NextNumber(sizeRange.Min, sizeRange.Max)
		local endSize = startSize * random:NextNumber(DEFAULT_SHRINK.Min, DEFAULT_SHRINK.Max)
		local fadeIn = math.min(random:NextNumber(DEFAULT_FADE_IN.Min, DEFAULT_FADE_IN.Max), lifetime * 0.45)
		local fadeOut = math.min(random:NextNumber(fadeOutRange.Min, fadeOutRange.Max), lifetime - fadeIn)
		local angularVelocity = random:NextNumber(DEFAULT_SPIN.Min, DEFAULT_SPIN.Max)
		local twinkleAmp = random:NextNumber(DEFAULT_TWINKLE.Min, DEFAULT_TWINKLE.Max)
		local twinkleSpeed = random:NextNumber(DEFAULT_TWINKLE_SPEED.Min, DEFAULT_TWINKLE_SPEED.Max)
		local twinklePhase = random:NextNumber(0, math.pi * 2)

		ScreenParticle.emit({
			Parent = parent,
			Count = 1,
			Position = config.Position,
			Gravity = 0,
			Lifetime = NumberRange.new(lifetime, lifetime),
			GetVelocity = function()
				local speed = random:NextNumber(velocityRange.Min, velocityRange.Max)
				local angle = random:NextNumber(0, math.pi * 2)
				return Vector2.new(math.cos(angle) * speed, math.sin(angle) * speed)
			end,
			Create = function()
				local label = Instance.new("ImageLabel")
				label.Name = "Sparkle"
				label.BackgroundTransparency = 1
				label.BorderSizePixel = 0
				label.AnchorPoint = Vector2.new(0.5, 0.5)
				label.ScaleType = Enum.ScaleType.Fit
				label.Image = SPARKLE_IMAGES[random:NextInteger(1, #SPARKLE_IMAGES)]
				label.ImageColor3 = color
				label.Rotation = random:NextNumber(0, 360)
				label.Size = UDim2.fromOffset(startSize, startSize)
				label.ImageTransparency = if fadeIn > 0 then 1 else PEAK_TRANSPARENCY
				label.ZIndex = particleZIndex
				label.Visible = true
				return label
			end,
			OnUpdate = function(gui, alpha, dt)
				local label = gui :: ImageLabel
				local elapsed = alpha * lifetime
				local size = startSize + (endSize - startSize) * alpha
				local transparency = PEAK_TRANSPARENCY
				local fadeOutStart = lifetime - fadeOut
				if fadeIn > 0 and elapsed < fadeIn then
					transparency = 1 + (PEAK_TRANSPARENCY - 1) * (elapsed / fadeIn)
				elseif fadeOut > 0 and elapsed > fadeOutStart then
					local t = math.clamp((elapsed - fadeOutStart) / fadeOut, 0, 1)
					t = 1 - (1 - t) * (1 - t)
					transparency = PEAK_TRANSPARENCY + (1 - PEAK_TRANSPARENCY) * t
				end
				if twinkleAmp > 0 then
					transparency = math.clamp(transparency + twinkleAmp * math.sin(elapsed * twinkleSpeed + twinklePhase), 0, 1)
				end
				local blink = 0.5 + 0.5 * math.sin(elapsed * twinkleSpeed + twinklePhase)
				label.Rotation += angularVelocity * dt
				label.Size = UDim2.fromOffset(size, size)
				label.ImageTransparency = transparency
				label.ImageColor3 = color:Lerp(brightColor, blink)
			end,
		})
	end
end

return Sparkles
