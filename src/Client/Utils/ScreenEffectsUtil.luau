--!strict
local ScreenEffectsUtil = {}

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local Shaker = require(Shared.Shaker)
local Spring = require(Shared.Spring)
local SpringRunner = require(Shared.SpringRunner)
local CameraController = require(Client.CameraController)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local cameraShaker = CameraController.registerShaker(
	Shaker.new({ Speed = 10, Stiffness = 3, Damping = 0.45 }, { Speed = 3.5, Stiffness = 4, Damping = 0.4 })
)
local bloomSpring = Spring.new(0, 0.7, 0.5, 1, 9)
local bloomEffect = Lighting.Bloom
local initExposureCompensation = Lighting.ExposureCompensation

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ScreenEffectsUtil.shake(rotImpulse: Vector3 | number, posImpulse: Vector3 | number?)
	cameraShaker:Impulse(rotImpulse, posImpulse or 0)
end

function ScreenEffectsUtil.bloom(factor: number)
	SpringRunner.impulse(bloomSpring, 0.3 * factor, 0, {
		OnUpdate = function(_alpha)
			local alpha = math.clamp(_alpha :: number, -0.5, 1)
			bloomEffect.Intensity = alpha * 0.5
			bloomEffect.Size = alpha * 2
			Lighting.ExposureCompensation = initExposureCompensation + (0.8 * alpha)
		end,
	})
end

return ScreenEffectsUtil
