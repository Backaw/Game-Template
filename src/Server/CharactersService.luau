--!strict
local CharactersService = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = require(ServerStorage.Server.PlayersService)

local Shared = ReplicatedStorage.Shared
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
	end
end

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CharactersService.LoadPriorities = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function loadCharacter(character: Model?): Model?
	if not character then
		return nil
	end

	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if player and humanoid then
		humanoid.WalkSpeed = CharacterConstants.WalkSpeed
		humanoid.Died:Connect(function()
			CharacterLoadingUtil.invokeUnloadCallbacks(character, player)
		end)

		for _, basePart in character:QueryDescendants("BasePart") do
			setCollision(basePart)
		end
		character.DescendantAdded:Connect(setCollision)

		task.defer(function()
			local nameTag = ServerStorage.NameTag:Clone()
			nameTag.Parent = (character :: any):FindFirstChild("Head")
			nameTag.TextLabel.Text = player.DisplayName
			nameTag.PlayerToHideFrom = player

			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end)

		repeat
			task.wait()
		until character.Parent

		local rootPart: BasePart = (character :: any).HumanoidRootPart
		-- 		rootPart.Anchored = true

		local rootAttachment = Instance.new("Attachment")
		rootAttachment.Parent = rootPart

		CharacterLoadingUtil.invokeLoadCallbacks(character, player)
	end

	return character
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

CharactersService.registerLoadCallback = registerLoadCallback
CharactersService.registerUnloadCallback = registerUnloadCallback

PlayersService.registerLoadHandler(PlayersService.LoadJobs.Character, function(player)
	local character = loadCharacter(player.Character)
	player.CharacterAdded:Connect(function(newCharacter)
		character = loadCharacter(newCharacter)
	end)

	PlayersService.registerUnloadTask(player, function()
		if character then
			CharacterLoadingUtil.invokeUnloadCallbacks(character, player)
		end
	end)
end)

return CharactersService
