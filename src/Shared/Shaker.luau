--!strict
local Shaker = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Spring = require(ReplicatedStorage.Shared.Spring)

export type NumVect = number | Vector3
export type Shaker = typeof(Shaker.new())
type Config = {
	Speed: NumVect,
	Force: NumVect,
	Damping: NumVect,
}

local MASS = 1

Shaker.Defaults = {
	Speed = 10,
	Force = 4,
	Damping = 0.9,
} :: Config

local random = Random.new()

function Shaker.new(rotationConfig: Config?, positionConfig: Config?)
	local shaker = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local finalPositionConfig: Config = positionConfig or {} :: Config
	local finalRotationConfig: Config = rotationConfig or {} :: Config

	local positionSpring: Spring.Spring
	local rotationSpring: Spring.Spring

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function shaker:Update(dt: number): CFrame
		-- If force is zero, immediately reset and return identity
		local posForce = if typeof(finalPositionConfig.Force) == "Vector3"
			then finalPositionConfig.Force.Magnitude
			else finalPositionConfig.Force
		local rotForce = if typeof(finalRotationConfig.Force) == "Vector3"
			then finalRotationConfig.Force.Magnitude
			else finalRotationConfig.Force

		if posForce == 0 and rotForce == 0 then
			positionSpring:Reset(Vector3.zero)
			rotationSpring:Reset(Vector3.zero)
			return CFrame.identity
		end

		local position = if posForce == 0 then Vector3.zero else positionSpring:Update(Vector3.zero, dt)
		local rotation = if rotForce == 0 then Vector3.zero else rotationSpring:Update(Vector3.zero, dt)

		return CFrame.Angles((rotation :: any).X, (rotation :: any).Y, (rotation :: any).Z) + (position :: any)
	end

	function shaker:Impulse(rotImpulse: NumVect?, posImpulse: NumVect?, dontRandomize: boolean?)
		if posImpulse then
			local impulse: Vector3
			if typeof(posImpulse) == "Vector3" then
				-- Preserve magnitude but randomize direction
				local magnitude = posImpulse.Magnitude
				impulse = if dontRandomize then posImpulse else random:NextUnitVector() * magnitude
			else
				-- Number: scale by random unit vector
				impulse = if dontRandomize then Vector3.new(posImpulse, posImpulse, posImpulse) else random:NextUnitVector() * posImpulse
			end
			positionSpring:Impulse(impulse)
		end

		if rotImpulse then
			local impulse: Vector3
			if typeof(rotImpulse) == "Vector3" then
				-- Preserve magnitude but randomize direction
				local magnitude = rotImpulse.Magnitude
				impulse = if dontRandomize then rotImpulse else random:NextUnitVector() * magnitude
			else
				-- Number: scale by random unit vector
				impulse = if dontRandomize then Vector3.new(rotImpulse, rotImpulse, rotImpulse) else random:NextUnitVector() * rotImpulse
			end
			rotationSpring:Impulse(impulse)
		end
	end

	function shaker:Reset()
		positionSpring:Reset(Vector3.zero)
		rotationSpring:Reset(Vector3.zero)
	end

	function shaker:SetPosition(position: NumVect)
		positionSpring:Set(position)
	end

	function shaker:SetRotation(rotation: NumVect)
		rotationSpring:Set(rotation)
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

	rotationSpring = Spring.new(Vector3.zero, MASS, finalRotationConfig.Force, finalRotationConfig.Damping, finalRotationConfig.Speed)
	positionSpring = Spring.new(Vector3.zero, MASS, finalPositionConfig.Force, finalPositionConfig.Damping, finalPositionConfig.Speed)

	return shaker
end

return Shaker
