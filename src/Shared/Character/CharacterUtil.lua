local CharacterUtil = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local DEFAULT_TOUCH_TIMEOUT = 0.1

local IS_STUDIO = RunService:IsStudio()

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function CharacterUtil.onCharacterTouched(
	hitbox: BasePart | { BasePart },
	timeout: number?,
	callback: (Model) -> ()
): RBXScriptConnection | { RBXScriptConnection }
	timeout = timeout or DEFAULT_TOUCH_TIMEOUT
	local debounce: { [Model]: true } = {}

	local oneHitbox: boolean = typeof(hitbox) == "Instance"

	local connections: { [BasePart]: RBXScriptConnection } = {}
	local hiboxes: { BasePart } = if oneHitbox then { hitbox } else hitbox

	for _, basePart in  (hiboxes) do
		basePart.CanTouch = true

		local connection: RBXScriptConnection
		connection = basePart.Touched:Connect(function(hit)
			local character: Model = hit.Parent

			if not debounce[character] and character:FindFirstChildOfClass("Humanoid") then
				debounce[character] = true

				callback(character)

				task.wait(timeout)
				debounce[character] = nil
			end
		end)

		connections[basePart] = connection
	end

	return if oneHitbox then connections[hitbox] else connections
end

function CharacterUtil.kill(player: Player)
	if not CharacterUtil.isAlive(player) then
		return
	end

	local humanoid: Humanoid = player.Character.Humanoid
	humanoid:TakeDamage(humanoid.MaxHealth - 1)
	task.defer(function()
		humanoid:TakeDamage(1)
	end)
end

function CharacterUtil.isAlive(player: Player)
	local character = player.Character

	if not (character and character.Parent) then
		return false
	end

	return character:WaitForChild("Humanoid").Health > 0
end

-- Moves a character so that they're standing above a part, usefull for spawning
function CharacterUtil.teleportTo(player: Player, spawnPoint: BasePart | CFrame)
	local character = player.Character
	if not character then
		return
	end

	local humanoid: Humanoid = character.Humanoid
	local humanoidRootPart: BasePart = character.HumanoidRootPart
	character.WorldPivot = humanoidRootPart.CFrame
	character:PivotTo(
		spawnPoint.CFrame:ToWorldSpace(CFrame.new(0, humanoid.HipHeight + (spawnPoint.Size + humanoidRootPart.Size).Y / 2, 0))
	)
end

function CharacterUtil.safeInvokeHandler(handler: (any, any) -> any, ...)
	if IS_STUDIO then
		handler(...)
	else
		local success, err = pcall(handler, ...)
		if not success then
			warn("Character: ", err)
		end
	end
end

if RunService:IsClient() then
	local player = Players.LocalPlayer

	function CharacterUtil.onLocalCharacterTouched(hitbox: BasePart, timeout: number?, callback: () -> ())
		return CharacterUtil.onCharacterTouched(hitbox, timeout, function(character)
			if character == player.Character then
				callback()
			end
		end)
	end
end

return CharacterUtil
