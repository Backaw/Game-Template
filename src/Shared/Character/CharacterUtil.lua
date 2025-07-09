local CharacterUtil = {}

local RunService = game:GetService("RunService")
local IS_STUDIO = RunService:IsStudio()

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
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

return CharacterUtil
