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

	positionConfig = positionConfig or {} :: Config
	rotationConfig = rotationConfig or {} :: Config

	local positionSpring: Spring.Spring
	local rotationSpring: Spring.Spring

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function shaker:Update(dt: number): CFrame
		local position = positionSpring:Update(Vector3.zero, dt)
		local rotation = rotationSpring:Update(Vector3.zero, dt)

		return CFrame.Angles((rotation :: any).X, (rotation :: any).Y, (rotation :: any).Z) + (position :: any)
	end

	function shaker:Impulse(rotImpulse: NumVect?, posImpulse: NumVect?, dontRandomize: boolean?)
		if posImpulse then
			positionSpring:Impulse(posImpulse * (dontRandomize and 1 or random:NextUnitVector()) :: any)
		end

		if rotImpulse then
			rotationSpring:Impulse(rotImpulse * (dontRandomize and 1 or random:NextUnitVector()) :: any)
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
		for _, config in { positionConfig, rotationConfig } do
			if (config :: any)[key] == nil then
				(config :: any)[key] = value
			end
		end
	end

	rotationSpring = Spring.new(Vector3.zero, MASS, rotationConfig.Force, rotationConfig.Damping, rotationConfig.Speed)
	positionSpring = Spring.new(Vector3.zero, MASS, positionConfig.Force, positionConfig.Damping, positionConfig.Speed)

	return shaker
end

return Shaker
