--!strict
local CurrencyDeltaParticles = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local ColorUtil = require(Shared.Utils.ColorUtil)
local MathUtil = require(Shared.Utils.MathUtil)
local ObjectPool = require(Shared.ObjectPool)
local ScreenParticle = require(Client.UI.Particles.ScreenParticle)
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)
local Component = require(Client.UI.Components.Component)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local LIFETIME = NumberRange.new(0.85, 1.2)
local GRAVITY = 950
local FONT = Font.new("rbxasset://fonts/families/Nunito.json", Enum.FontWeight.ExtraBold)
local ORIGIN_VARIANCE = 0.2
local MAX_BURST = 24
local POOL_SIZE = 24

local INIT_TEXT_TRANSPARENCY = 0.2
local INIT_STROKE_TRANSPARENCY = 0 --  0.05
local STROKE_THICKNESS = 1.5
local STROKE_VALUE_DELTA = -0.45

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Emitter = Component.Component & {
	Emit: (Emitter, value: number, count: number?, textColors: { Color3 }?) -> (),
	GetParent: (Emitter) -> GuiObject,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local random = Random.new()
local particleTemplate = ComponentUtil.getPlayerGui().HUD.Left.Currencies.TEMP_COUNTER.TEMP_PARTICLE
local particleConstructor = ComponentUtil.getTemplateConstructor(particleTemplate)

local initParticleSize = particleTemplate.Size

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function CurrencyDeltaParticles.new(
	parent: GuiObject,
	textColor: Color3,
	strokeColor: Color3,
	velocityDirection: number?,
	scale: number?
): Emitter
	local emitter = Component.new() :: Emitter

	local maid = emitter:GetMaid()

	local container = Instance.new("Frame")
	container.Name = "EarnParticles"
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.fromScale(0.5, 0.5)
	container.Size = UDim2.fromScale(1, 1)
	container.ClipsDescendants = false
	container.ZIndex = 0
	container.Parent = parent

	local particlePool = ObjectPool.new(particleConstructor, nil, POOL_SIZE)
	maid:Add(function()
		ScreenParticle.clear(container)
		container:Destroy()
		particlePool:Destroy()
	end)

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function emitter:GetParent()
		return parent
	end

	function emitter:Emit(value, count, textColors)
		local burst = count or 1
		local text = `{if value >= 0 then "+" else "-"}{math.abs(value)}`
		local colorCount = if textColors then #textColors else 0

		for i = 1, math.min(MAX_BURST, burst) do
			local origin = Vector2.new(
				math.clamp(0.5 + random:NextNumber(-ORIGIN_VARIANCE, ORIGIN_VARIANCE), 0, 1),
				math.clamp(0.5 + random:NextNumber(-ORIGIN_VARIANCE, ORIGIN_VARIANCE), 0, 1)
			)
			local side = MathUtil.nextSign()

			local fillColor = textColor
			local particleStroke = strokeColor
			if colorCount > 0 and random:NextNumber() < 0.5 then
				fillColor = textColors[((i - 1) % colorCount) + 1]
				particleStroke = ColorUtil.addValue(fillColor, STROKE_VALUE_DELTA)
			end

			ScreenParticle.emit({
				Parent = container,
				Count = 1,
				Position = UDim2.fromScale(origin.X, origin.Y),
				Lifetime = LIFETIME,
				Gravity = GRAVITY,
				Create = function()
					local particle = particlePool:Get()
					particle.Text = text
					particle.FontFace = FONT
					particle.TextTransparency = INIT_TEXT_TRANSPARENCY
					particle.TextColor3 = fillColor
					particle.Rotation = random:NextNumber(-14, 14)
					particle.Size = initParticleSize
					particle.Visible = true
					particle.ZIndex = 0
					particle.Size = UDim2.fromOffset(48, 28)
					particle.TextScaled = true
					particle.AnchorPoint = Vector2.new(0.5, 0.5)

					local uiStroke = particle.UIStroke
					uiStroke.Color = particleStroke
					uiStroke.Thickness = STROKE_THICKNESS
					uiStroke.Transparency = INIT_STROKE_TRANSPARENCY
					particle.UIScale.Scale = scale or 1
					return particle
				end,
				Return = function(gui)
					particlePool:Return(gui)
				end,
				GetVelocity = function()
					return Vector2.new(
						side * random:NextNumber(90, 220),
						(if velocityDirection == -1 then -1 else 1) * -random:NextNumber(180, 340)
					)
				end,
				OnUpdate = function(gui, alpha, dt)
					local particle = gui :: TextLabel
					particle.TextTransparency = INIT_TEXT_TRANSPARENCY + alpha * (1 - INIT_TEXT_TRANSPARENCY)
					particle.Rotation += side * 40 * (1 - alpha) * dt
					particle.UIStroke.Transparency = INIT_STROKE_TRANSPARENCY + alpha * (1 - INIT_STROKE_TRANSPARENCY)
				end,
			})
		end
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	parent.ClipsDescendants = false

	return emitter
end

return CurrencyDeltaParticles
