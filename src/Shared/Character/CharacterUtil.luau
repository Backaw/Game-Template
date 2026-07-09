--!strict
local CharacterUtil = {}

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function CharacterUtil.kill(character: CharacterConstants.Character)
	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 3) :: Humanoid?
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(humanoid.Health)
	end
end

function CharacterUtil.killPlayer(player: Player?)
	player = player or Players.LocalPlayer
	local character = player.Character
	if character then
		CharacterUtil.kill(character :: CharacterConstants.Character)
	end
end

function CharacterUtil.isAlive(player: Player)
	local character = player.Character

	if not (character and character.Parent) then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid?
	if humanoid then
		return humanoid.Health > 0
	else
		return false
	end
end

function CharacterUtil.getRootAttachment(humanoidRootPart: BasePart)
	return humanoidRootPart:WaitForChild("RootAttachment")
end

-- Moves a character so that they're standing above a part, usefull for spawning
function CharacterUtil.teleportTo(player: Player, spawnPoint: BasePart | CFrame)
	local character = player.Character
	if not character then
		return
	end

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	character.WorldPivot = humanoidRootPart.CFrame

	local cframe
	local characterHeight = humanoid.HipHeight + humanoidRootPart.Size.Y / 2
	if typeof(spawnPoint) == "CFrame" then
		cframe = spawnPoint * (CFrame.new(0, characterHeight, 0))
	else
		cframe = spawnPoint.CFrame * (CFrame.new(0, characterHeight + spawnPoint.Size.Y / 2, 0))
	end

	character:PivotTo(cframe)
end

return CharacterUtil
