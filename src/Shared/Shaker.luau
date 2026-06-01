--!strict
local Shaker = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spring = require(ReplicatedStorage.Shared.Spring)

export type NumVect = number | Vector3
export type Shaker = typeof(Shaker.new())
type Config = {
	Speed: NumVect,
	Stiffness: NumVect,
	Damping: NumVect,
}

-- Slight per-axis frequency offsets so axes drift out of phase over time
local AXIS_SPEED_OFFSETS = { 1, 1.1, 1.2 }

local MASS = 1

Shaker.Defaults = {
	Speed = 10,
	Stiffness = 4,
	Damping = 0.9,
} :: Config

local random = Random.new()

local function makeSprings(config: Config): { Spring.Spring }
	local stiffness = config.Stiffness :: number
	local damping = config.Damping
	local speed = config.Speed :: number
	return {
		Spring.new(0, MASS, stiffness, damping, speed * AXIS_SPEED_OFFSETS[1]),
		Spring.new(0, MASS, stiffness, damping, speed * AXIS_SPEED_OFFSETS[2]),
		Spring.new(0, MASS, stiffness, damping, speed * AXIS_SPEED_OFFSETS[3]),
	}
end

local function updateSprings(springs: { Spring.Spring }, dt: number): Vector3
	return Vector3.new(springs[1]:Update(0, dt) :: number, springs[2]:Update(0, dt) :: number, springs[3]:Update(0, dt) :: number)
end

local function impulseSprings(springs: { Spring.Spring }, impulse: Vector3, stiffness: number)
	local scale = math.sqrt(stiffness)
	springs[1]:Impulse(impulse.X * scale)
	springs[2]:Impulse(impulse.Y * scale)
	springs[3]:Impulse(impulse.Z * scale)
end

local function resetSprings(springs: { Spring.Spring })
	springs[1]:Reset(0)
	springs[2]:Reset(0)
	springs[3]:Reset(0)
end

function Shaker.new(rotationConfig: Config?, positionConfig: Config?)
	local shaker = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local finalPositionConfig: Config = positionConfig or {} :: Config
	local finalRotationConfig: Config = rotationConfig or {} :: Config

	local positionSprings: { Spring.Spring }
	local rotationSprings: { Spring.Spring }

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function shaker:Update(dt: number, cappedDt: number?): CFrame
		dt = cappedDt or dt

		local position = updateSprings(positionSprings, dt)
		local rotation = updateSprings(rotationSprings, dt)

		return CFrame.Angles(rotation.X, rotation.Y, rotation.Z) + position
	end

	function shaker:Impulse(rotImpulse: NumVect?, posImpulse: NumVect?, dontRandomize: boolean?)
		if posImpulse then
			local impulse: Vector3
			if typeof(posImpulse) == "Vector3" then
				local magnitude = posImpulse.Magnitude
				impulse = if dontRandomize then posImpulse else random:NextUnitVector() * magnitude
			else
				impulse = if dontRandomize then Vector3.new(posImpulse, posImpulse, posImpulse) else random:NextUnitVector() * posImpulse
			end
			impulseSprings(positionSprings, impulse, finalPositionConfig.Stiffness :: number)
		end

		if rotImpulse then
			local impulse: Vector3
			if typeof(rotImpulse) == "Vector3" then
				local magnitude = rotImpulse.Magnitude
				impulse = if dontRandomize then rotImpulse else random:NextUnitVector() * magnitude
			else
				impulse = if dontRandomize then Vector3.new(rotImpulse, rotImpulse, rotImpulse) else random:NextUnitVector() * rotImpulse
			end
			impulseSprings(rotationSprings, impulse, finalRotationConfig.Stiffness :: number)
		end
	end

	function shaker:Reset()
		resetSprings(positionSprings)
		resetSprings(rotationSprings)
	end

	function shaker:SetPosition(position: Vector3)
		positionSprings[1]:Set(position.X)
		positionSprings[2]:Set(position.Y)
		positionSprings[3]:Set(position.Z)
	end

	function shaker:SetRotation(rotation: Vector3)
		rotationSprings[1]:Set(rotation.X)
		rotationSprings[2]:Set(rotation.Y)
		rotationSprings[3]:Set(rotation.Z)
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	for key, value in pairs(Shaker.Defaults :: { [string]: any }) do
		for _, config in { finalPositionConfig, finalRotationConfig } do
			if (config :: any)[key] == nil then
				(config :: any)[key] = value
			end
		end
	end

	rotationSprings = makeSprings(finalRotationConfig)
	positionSprings = makeSprings(finalPositionConfig)

	return shaker
end

return Shaker
