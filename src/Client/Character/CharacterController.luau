--!strict
local CharacterController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CharacterLoadingUtil = require(Shared.Character.CharacterLoadingUtil)
local CharacterUtil = require(Shared.Character.CharacterUtil)
local Maid = require(Shared.Maid)
local TransitionController = require(Client.UI.Transitions.TransitionController)
local CameraController = require(Client.CameraController)
local UIController = require(Client.UI.UIController)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local RESPAWN_TIME = Players.RespawnTime

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Handler = (newCharacter: Model) -> ()
type Callback = { Handler: Handler, Priority: number, Traceback: string? }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local player = Players.LocalPlayer
local session = Maid.new()

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CharacterController.LoadPriorities = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function loadCharacter(character: Model?)
	if character then
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid

		UIController.resetToHUD({})

		CharacterLoadingUtil.invokeLoadCallbacks(character)

		local alive = true
		local function onDeath()
			if not alive then
				return
			end

			session:Cleanup()

			alive = false
			player.Character = nil

			CharacterLoadingUtil.invokeUnloadCallbacks(character)

			task.wait(RESPAWN_TIME * 0.75)
			TransitionController.open("CharacterSpawning", "Wipe")
		end

		-- InstanceUtil.onDestroyed(character:WaitForChild("HumanoidRootPart"), onDeath)
		humanoid.Died:Connect(onDeath)
	end

	TransitionController.close("CharacterSpawning")
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

CharacterController.registerLoadCallback, CharacterController.registerUnloadCallback = CharacterLoadingUtil.getRegistration()

function CharacterController.getMaid()
	return session
end

-- Not for spawning standing on something
function CharacterController.teleportTo(spawnPoint: CFrame)
	TransitionController.play("Teleporting", "Eye", function()
		if CharacterUtil.isAlive(player) then
			local character = player.Character
			if character then
				character:PivotTo(spawnPoint)

				CameraController.lookForward()
				UIController.resetToHUD()

				local humanoid = character:WaitForChild("Humanoid") :: Humanoid
				if humanoid:GetState() == Enum.HumanoidStateType.Seated then
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end
		end
	end)
end

function CharacterController.start()
	loadCharacter(player.Character)
	player.CharacterAdded:Connect(loadCharacter)
end

return CharacterController
