local CharacterController = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local CharacterUtil = require(Paths.Shared.Character.CharacterUtil)
local TransitionController = require(Paths.Controllers.UI.Transitions.TransitionController)
local CameraController = require(Paths.Controllers.Camera.CameraController)
local UIController = require(Paths.Controllers.UI.UIController)
local InstanceUtil = require(Paths.Shared.Utils.InstanceUtil)
local UIConstants = require(Paths.Controllers.UI.UIConstants)
local DebugUtil = require(Paths.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------
type Handler = (newCharacter: Model) -> ()
type Callback = { Handler: Handler, Priority: number, Traceback: string? }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)

local RESPAWN_TIME = Players.RespawnTime
local DEFAULT_PRIORITY = 0

local player = Players.LocalPlayer

local loadCallbacks: { Callback } = {}
local unloadCallbacks: { Callback } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
-- The higher the value, the higher the priority. Higher priorities execute before lower priorities
CharacterController.Priorities = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function sortByPriority(a: Callback, b: Callback)
	return a.Priority > b.Priority
end

local function loadCharacter(character: Model?)
	if character then
		local humanoid: Humanoid = character:WaitForChild("Humanoid")
		UIController.resetToHUD({ UIConstants.States.Reward })

		for _, callback in loadCallbacks do
			if DEBUG then
				print("Running LoadChar Callback:", callback)
			end
			CharacterUtil.safeInvokeHandler(callback.Handler, character)
		end

		local alive = true
		local function onDeath()
			if not alive then
				return
			end

			alive = false

			player.Character = nil :: Model

			for _, callback in unloadCallbacks do
				if DEBUG then
					print("Running UnloadChar Callback:", callback)
				end
				CharacterUtil.safeInvokeHandler(callback.Handler, character)
			end

			task.wait(RESPAWN_TIME * 0.75)
			TransitionController.open("CharacterSpawning", "Wipe")
		end

		InstanceUtil.onDestroyed(character:WaitForChild("HumanoidRootPart"), onDeath)
		humanoid.Died:Connect(onDeath)
	end

	TransitionController.close("CharacterSpawning")
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CharacterController.registerLoadCallback(handler: Handler, priority: number?)
	if not priority then
		priority = DEFAULT_PRIORITY
	end

	local callback: Callback = { Handler = handler, Priority = priority }

	if DEBUG then
		callback.Traceback = debug.traceback()
	end

	table.insert(loadCallbacks, callback)
	table.sort(loadCallbacks, sortByPriority)
end

function CharacterController.registerUnloadCallback(handler: Handler, priority: number?)
	if not priority then
		priority = DEFAULT_PRIORITY
	end

	local callback: Callback = { Handler = handler, Priority = priority }

	if DEBUG then
		callback.Traceback = debug.traceback()
	end

	table.insert(unloadCallbacks, callback)
	table.sort(unloadCallbacks, sortByPriority)
end

-- Not for spawning standing on something
function CharacterController.teleportTo(spawnPoint: CFrame)
	TransitionController.play("Teleporting", "Eye", function()
		if CharacterUtil.isAlive(player) then
			local character: Model = player.Character
			character:PivotTo(spawnPoint)

			CameraController.lookForward()
			UIController.resetToHUD()

			local humanoid: Humanoid = character:WaitForChild("Humanoid")
			if humanoid:GetState() == Enum.HumanoidStateType.Seated then
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end)
end

function CharacterController.start()
	if DEBUG then
		print("Registered character Loaders:", loadCallbacks)
		print("Registered character Unloaders:", unloadCallbacks)
	end

	loadCharacter(player.Character)
	player.CharacterAdded:Connect(loadCharacter)
end

return CharacterController
