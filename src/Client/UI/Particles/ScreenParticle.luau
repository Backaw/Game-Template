--!strict
local ScreenParticle = {}

local RunService = game:GetService("RunService")

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type EmitConfig = {
	Parent: GuiObject,
	Create: () -> GuiObject,
	Return: ((gui: GuiObject) -> ())?,
	Count: number?,
	Position: UDim2?,
	-- Pixels / second in parent space.
	GetVelocity: (() -> Vector2)?,
	-- Pixels / second^2 downward.
	Gravity: number?,
	-- If set, used instead of Gravity once the particle is moving downward.
	FallGravity: number?,
	-- Seconds after spawn before FallGravity applies while descending.
	FallGravityDelay: number?,
	-- Velocity damping per second (0 = none). Applied after gravity.
	Drag: number?,
	Lifetime: NumberRange?,
	OnUpdate: ((gui: GuiObject, alpha: number, dt: number) -> ())?,
}

type Particle = {
	Gui: GuiObject,
	PosX: number,
	PosY: number,
	VelocityX: number,
	VelocityY: number,
	Gravity: number,
	FallGravity: number?,
	FallGravityDelay: number,
	Drag: number,
	Elapsed: number,
	Lifetime: number,
	OnUpdate: ((gui: GuiObject, alpha: number, dt: number) -> ())?,
	Return: ((gui: GuiObject) -> ())?,
}

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEFAULT_GRAVITY = 500
local DEFAULT_LIFETIME = NumberRange.new(0.7, 1.1)
local DEFAULT_BURST_SPEED = NumberRange.new(120, 280)
local DEFAULT_UPWARD_BIAS = 80

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local random = Random.new()
local particles: { Particle } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function sampleRange(value: NumberRange): number
	return random:NextNumber(value.Min, value.Max)
end

local function udim2ToScale(position: UDim2, parentSize: Vector2): (number, number)
	return position.X.Scale + position.X.Offset / math.max(parentSize.X, 1),
		position.Y.Scale + position.Y.Offset / math.max(parentSize.Y, 1)
end

local function defaultVelocity(): Vector2
	local angle = random:NextNumber(0, math.pi * 2)
	local speed = random:NextNumber(DEFAULT_BURST_SPEED.Min, DEFAULT_BURST_SPEED.Max)
	return Vector2.new(math.cos(angle) * speed, math.sin(angle) * speed - DEFAULT_UPWARD_BIAS)
end

local function finishParticle(particle: Particle)
	if particle.Gui.Parent then
		if particle.Return then
			particle.Return(particle.Gui)
		else
			particle.Gui:Destroy()
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ScreenParticle.emit(config: EmitConfig)
	local parent = config.Parent
	local parentSize = parent.AbsoluteSize
	if parentSize.X < 1 or parentSize.Y < 1 then
		return
	end

	local count = config.Count or 1
	local originX, originY = udim2ToScale(config.Position or UDim2.fromScale(0.5, 0.5), parentSize)
	local gravity = (config.Gravity or DEFAULT_GRAVITY) / parentSize.Y
	local fallGravity = if config.FallGravity then config.FallGravity / parentSize.Y else nil
	local drag = config.Drag or 0
	local lifetimeRange = config.Lifetime or DEFAULT_LIFETIME
	local getVelocity = config.GetVelocity or defaultVelocity

	for _ = 1, count do
		local gui = config.Create()
		gui.AnchorPoint = Vector2.new(0.5, 0.5)
		gui.Position = UDim2.fromScale(originX, originY)
		gui.Parent = parent

		local velocity = getVelocity()
		table.insert(particles, {
			Gui = gui,
			PosX = originX,
			PosY = originY,
			VelocityX = velocity.X / parentSize.X,
			VelocityY = velocity.Y / parentSize.Y,
			Gravity = gravity,
			FallGravity = fallGravity,
			FallGravityDelay = config.FallGravityDelay or 0,
			Drag = drag,
			Elapsed = 0,
			Lifetime = sampleRange(lifetimeRange),
			OnUpdate = config.OnUpdate,
			Return = config.Return,
		})
	end
end

function ScreenParticle.clear(parent: GuiObject)
	local i = 1
	while i <= #particles do
		local particle = particles[i]
		if particle.Gui.Parent == parent or particle.Gui:IsDescendantOf(parent) then
			finishParticle(particle)
			particles[i] = particles[#particles]
			particles[#particles] = nil
		else
			i += 1
		end
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

RunService.RenderStepped:Connect(function(dt)
	local i = 1
	while i <= #particles do
		local particle = particles[i]
		particle.Elapsed += dt

		if particle.Elapsed >= particle.Lifetime or not particle.Gui.Parent then
			finishParticle(particle)
			particles[i] = particles[#particles]
			particles[#particles] = nil
			continue
		end

		particle.PosX += particle.VelocityX * dt
		particle.PosY += particle.VelocityY * dt
		local gravity = particle.Gravity
		if particle.FallGravity and particle.VelocityY > 0 then
			if particle.Elapsed >= particle.FallGravityDelay then
				gravity = particle.FallGravity
			else
				gravity = 0
			end
		end
		particle.VelocityY += gravity * dt
		if particle.Drag > 0 then
			local dragFactor = math.max(0, 1 - particle.Drag * dt)
			particle.VelocityX *= dragFactor
			particle.VelocityY *= dragFactor
		end

		particle.Gui.Position = UDim2.fromScale(particle.PosX, particle.PosY)
		if particle.OnUpdate then
			particle.OnUpdate(particle.Gui, particle.Elapsed / particle.Lifetime, dt)
		end

		i += 1
	end
end)

return ScreenParticle
