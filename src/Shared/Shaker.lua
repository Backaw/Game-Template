local Shaker = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Spring = require(ReplicatedStorage.Modules.Spring)

export type NumVect = number | Vector3
export type Shaker = typeof(Shaker.new())

local random = Random.new()

-------------------------------------------------------------------------------

Shaker.Defaults = {
	Speed = 10,
	Force = 4,
	Damping = 0.9,
}

local MASS = 1

function Shaker.new(
	rotationConfig: { Speed: NumVect, Force: NumVect, Damping: NumVect }?,
	positionConfig: { Speed: NumVect, Force: NumVect, Damping: NumVect }?
)
	local shaker = {}

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	positionConfig = positionConfig or {}
	rotationConfig = rotationConfig or {}

	local positionSpring: Spring.Spring
	local rotationSpring: Spring.Spring

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function shaker:Update(dt: number): CFrame
		local position = positionSpring:Update(Vector3.zero, dt)
		local rotation = rotationSpring:Update(Vector3.zero, dt)

		return CFrame.Angles(rotation.X, rotation.Y, rotation.Z) + position
	end

	function shaker:Impulse(rotImpulse: NumVect?, posImpulse: NumVect?, dontRandomize: boolean?)
		if posImpulse then
			positionSpring:Impulse(posImpulse * (dontRandomize and 1 or random:NextUnitVector()))
		end

		if rotImpulse then
			rotationSpring:Impulse(rotImpulse * (dontRandomize and 1 or random:NextUnitVector()))
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
	for key, value in Shaker.Defaults do
		for _, config in { positionConfig, rotationConfig } do
			if config[key] == nil then
				config[key] = value
			end
		end
	end

	rotationSpring = Spring.new(Vector3.zero, MASS, rotationConfig.Force, rotationConfig.Damping, rotationConfig.Speed)
	positionSpring = Spring.new(Vector3.zero, MASS, positionConfig.Force, positionConfig.Damping, positionConfig.Speed)

	return shaker
end

return Shaker
