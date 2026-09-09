--!strict
local ScreenGlow = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local RunServiceUtil = require(Shared.Utils.RunServiceUtil)
local Spring = require(Shared.Spring)
local ComponentUtil = require(Client.UI.Utils.ComponentUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Color = ColorSequence | Color3

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_CYCLE_LENGTH = 7

local IMAGES = {
	Default = "rbxassetid://135689270619136",
	AllAround = "rbxassetid://109603370185740",
	AllAround2 = "rbxassetid://117236675829918",
	AllAround3 = "rbxassetid://138179051314649",
	Pinched = "rbxassetid://73187085966048",
	Piched2 = "rbxassetid://138000896167358",
}

local MAX_IMAGE_SCALE = {
	[IMAGES.Default] = 0.1,
	[IMAGES.AllAround] = 0.12,
	[IMAGES.AllAround2] = 0.1,
	[IMAGES.AllAround3] = 0.1,
	[IMAGES.Pinched] = 0.12,
	[IMAGES.Piched2] = 0.25,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local screen = ComponentUtil.getPlayerGui(Players.LocalPlayer).BackgroundParticles

local template = screen.TEMP_SCREEN_GLOW
local particleConstructor = ComponentUtil.getTemplateConstructor(template)

local registerRenderJob, unregisterRenderJob = RunServiceUtil.batchUpdateJobs(RunService.RenderStepped, "ScreenGlow")

local particles: {
	[typeof(template)]: {
		Intensity: number,
		Spring: Spring.Spring?,
		UIGradient: UIGradient,
		ColorSequence: ColorSequence?,
	},
} =
	{}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

ScreenGlow.Images = IMAGES

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function getName(label: string)
	return string.format(`{label}_ScreenGlow`, label)
end

local function sampleColorSequence(colorSequence: ColorSequence, alpha: number): Color3
	local keypoints = colorSequence.Keypoints
	local clampedAlpha = math.clamp(alpha, 0, 1)

	if clampedAlpha <= keypoints[1].Time then
		return keypoints[1].Value
	end

	local lastKeypoint = keypoints[#keypoints]
	if clampedAlpha >= lastKeypoint.Time then
		return lastKeypoint.Value
	end

	for i = 1, #keypoints - 1 do
		local current = keypoints[i]
		local next = keypoints[i + 1]
		if clampedAlpha >= current.Time and clampedAlpha <= next.Time then
			local segmentAlpha = (clampedAlpha - current.Time) / (next.Time - current.Time)
			return current.Value:Lerp(next.Value, segmentAlpha)
		end
	end

	return lastKeypoint.Value
end

local function createParticle(name: string, color: Color3, image: string?, scale: number?)
	local particle = particleConstructor()
	particle.Name = name
	particle.Image = image or IMAGES.Default
	particle.ImageTransparency = 1
	particle.ImageColor3 = color
	particle.Visible = false
	particle.UIScale.Scale = scale or 1
	return particle
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ScreenGlow.springify(
	label: string,
	color: Color,
	intensity: number,
	providedSpring: Spring.Spring?,
	image: string?,
	scale: number?
)
	local screenGlow = {}

	local name = getName(label)
	if screen:FindFirstChild(name) then
		error(`ScreenGlow particle with label {label} already exists`)
	end

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------

	local spring = providedSpring or Spring.new(0, 1, 4, 5, 2)

	local colorSequence = if typeof(color) == "ColorSequence" then color else nil

	local particle = createParticle(name, if colorSequence then Color3.fromRGB(255, 255, 255) else color :: Color3, image, scale)
	local uiGradient = particle.UIGradient

	local targetPosition = 0
	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function screenGlow:SetTargetPosition(position: number)
		targetPosition = math.clamp(position, 0, 1)
	end

	function screenGlow:Toggle(toggle)
		if particle.Visible == toggle then
			return
		end

		particle.Visible = toggle

		if toggle then
			particles[particle] = {
				Spring = spring,
				Intensity = intensity,
				UIGradient = uiGradient,
				ColorSequence = if typeof(color) == "ColorSequence" then color else nil,
			}

			local et = 0
			local maxImageScale = MAX_IMAGE_SCALE[particle.Image]
			registerRenderJob(name, function(dt)
				dt += et

				local position = math.clamp(spring:Update(targetPosition, dt) :: number, 0, 1)
				particle.ImageTransparency = (1 - (position * intensity))

				local cycleLength = math.max(DEFAULT_CYCLE_LENGTH, 0.001)
				local normalizedTime = et / cycleLength

				if colorSequence then
					local cycleAlpha = (et / (cycleLength / 3)) % 1
					particle.ImageColor3 = sampleColorSequence(colorSequence, cycleAlpha)
				end

				do
					local offset = math.sin(normalizedTime * math.pi * 2) * 0.5
					uiGradient.Offset = Vector2.new(0, offset)
				end

				do
					local offset = (math.sin(normalizedTime * math.pi * 2) + 1) / 2
					offset *= maxImageScale
					particle.Size = UDim2.fromScale(1 + offset, 1 + offset)
				end
			end)
		else
			particles[particle] = nil
			unregisterRenderJob(name)
		end
	end

	function screenGlow:Impulse(magnitude)
		if not particle.Visible then
			warn("Attempting to impulse a hidden particle")
			return
		end

		spring:Impulse(magnitude)
	end

	return screenGlow
end

return ScreenGlow
