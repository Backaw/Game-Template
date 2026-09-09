--!strict
local CharactersService = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Server = ServerStorage.Server
local Shared = ReplicatedStorage.Shared
local PlayersService = require(Server.PlayersService)
local CharacterLoadingUtil = require(Shared.Character.CharacterLoadingUtil)
local CollisionConstants = require(Shared.Constants.CollisionConstants)
local CharacterConstants = require(Shared.Character.CharacterConstants)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local registerLoadCallback: CharacterLoadingUtil.Registration<Player>, registerUnloadCallback: CharacterLoadingUtil.Registration<Player> =
	CharacterLoadingUtil.getRegistration()

local function setCollision(basePart: Instance)
	if basePart:IsA("BasePart") then
		basePart.CollisionGroup = CollisionConstants.Groups.Character
		basePart.CanQuery = false
		basePart.CastShadow = false
	end
end

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CharactersService.LoadPriorities = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function loadCharacter(character: CharacterConstants.Character, player: Player): CharacterConstants.Character?
	if not character then
		return nil
	end

	local humanoid = character.Humanoid

	humanoid.WalkSpeed = CharacterConstants.WalkSpeed
	humanoid.Died:Connect(function()
		CharacterLoadingUtil.invokeUnloadCallbacks(character, player)
	end)

	for _, basePart in character:QueryDescendants("BasePart") do
		setCollision(basePart)
	end
	character.DescendantAdded:Connect(setCollision)

	--[[
	task.defer(function()
		local nameTag = ServerStorage.NameTag:Clone()
		nameTag.Parent = (character :: any):FindFirstChild("Head")
		nameTag.TextLabel.Text = player.DisplayName
		nameTag.PlayerToHideFrom = player

		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end)
	]]

	repeat
		task.wait()
	until character.Parent

	CharacterLoadingUtil.invokeLoadCallbacks(character, player)

	return character
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

CharactersService.registerLoadCallback = registerLoadCallback
CharactersService.registerUnloadCallback = registerUnloadCallback

PlayersService.registerLoadHandler(PlayersService.LoadJobs.Character, function(player)
	local character = loadCharacter(player.Character :: CharacterConstants.Character, player)
	player.CharacterAdded:Connect(function(newCharacter)
		character = loadCharacter(newCharacter :: CharacterConstants.Character, player)
	end)

	PlayersService.registerUnloadTask(player, function()
		if character then
			CharacterLoadingUtil.invokeUnloadCallbacks(character, player)
		end
	end)
end)

return CharactersService
