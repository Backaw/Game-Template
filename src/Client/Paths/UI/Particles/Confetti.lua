local Confetti = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local SCALE = 0.025
local SCALES = {
	Vector2.new(1, 1.5) * SCALE,
	Vector2.new(0.5, 1.5) * SCALE,
	Vector2.new(1, 1) * SCALE,
}

local DISPLAY_DISTANCE = 1

local LENGTH_RANGE = NumberRange.new(1, 3)
local ANGULAR_VELOCITY_RANGE = NumberRange.new(math.rad(40), math.rad(150))
local LAYER_DELAY = 0.1

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local random = Random.new()
local camera = Workspace.Camera

local particleTempate: MeshPart = Paths.Assets.VFXPresets.ScreenConfetti
local particles: { [BasePart]: {
	Position: Vector3,
	Rotation: Vector3,
	LinearVelocity: Vector3,
	AngularVelocity: Vector3,
} } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
Confetti.Colors = {
	Party = {
		Color3.fromRGB(153, 102, 203),
		Color3.fromRGB(54, 146, 196),
		Color3.fromRGB(143, 189, 59),
		Color3.fromRGB(190, 56, 43),
		Color3.fromRGB(180, 166, 64),
	},
	PartyContrast = {
		Color3.fromRGB(0, 113, 193),
		Color3.fromRGB(165, 36, 0),
		Color3.fromRGB(130, 34, 167),
		Color3.fromRGB(81, 142, 13),
	},
	Gold = {
		Color3.fromRGB(253, 253, 5),
		Color3.fromRGB(255, 181, 22),
		Color3.fromRGB(252, 255, 98),
	},
	Purple = {
		Color3.fromRGB(245, 5, 253),
		Color3.fromRGB(181, 22, 255),
	},
}

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function Confetti.play(count: number, colors: { Color3 }, layers: number)
	local verticalFov = math.rad(70 / 2)
	local viewportSize = camera.ViewportSize

	local worldViewY = math.abs(math.tan(verticalFov) * DISPLAY_DISTANCE * 2) * 1.5
	local worldViewX = math.abs(math.tan((viewportSize.X / viewportSize.Y) * verticalFov) * DISPLAY_DISTANCE * 2) * 0.5

	task.spawn(function()
		local padding = worldViewX / (count - 1)
		for _ = 1, layers do
			for i = 1, count do
				local size = SCALES[random:NextInteger(1, #SCALES)] * worldViewX

				local particle: MeshPart = particleTempate:Clone()
				particle.Color = colors[i % #colors + 1]
				particle.Size = Vector3.new(size.X, size.Y, particleTempate.Size.Z * (size.X / particleTempate.Size.X))
				particle.Anchored = true
				particle.CanCollide = false
				particle.Parent = Workspace

				local x = math.clamp(-worldViewX / 2 + i * padding, -worldViewX / 2, worldViewX / 2)
					+ random:NextNumber(-worldViewX * 0.5, worldViewX * 0.5)

				-- Center ones fall slower
				local linearVelocity = worldViewY / random:NextNumber(LENGTH_RANGE.Min, LENGTH_RANGE.Max)
				linearVelocity += linearVelocity * 1 * (math.abs(x) / (worldViewX / 2))

				particles[particle] = {
					Position = Vector3.new(x, worldViewY / 2, -(DISPLAY_DISTANCE + particle.Size.Z)),
					Rotation = Vector3.new(math.random(1, math.pi), math.random(1, math.pi), 0),
					AngularVelocity = Vector3.new(
						random:NextNumber(ANGULAR_VELOCITY_RANGE.Min, ANGULAR_VELOCITY_RANGE.Max) * 5,
						0,
						random:NextNumber(ANGULAR_VELOCITY_RANGE.Min, ANGULAR_VELOCITY_RANGE.Max)
					),
					LinearVelocity = Vector3.new(0, -linearVelocity, 0),
				}

				task.delay((worldViewY + particle.Size.Y) / linearVelocity, function()
					particles[particle] = nil
					particle:Destroy()
				end)
			end
			task.wait(LAYER_DELAY)
		end
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local cameraCFrame = camera.CFrame

	for particle, info in pairs(particles) do
		info.Position += info.LinearVelocity * dt
		info.Rotation += info.AngularVelocity * dt

		particle.CFrame = cameraCFrame * CFrame.new(info.Position) * CFrame.Angles(info.Rotation.X, 0, info.Rotation.Z)
	end
end)

return Confetti
