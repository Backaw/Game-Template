--!strict
local CharactersService = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayersService = require(ServerStorage.Server.PlayersService)
local CharacterLoadingUtil = require(ReplicatedStorage.Shared.Character.CharacterLoadingUtil)
local CollisionConstants = require(ReplicatedStorage.Shared.Constants.CollisionConstants)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CharactersService.LoadPriorities = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function loadCharacter(character: Model?)
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character:FindFirstChild("Humanoid") :: Humanoid

	if player and humanoid then
		humanoid.Died:Connect(function()
			CharacterLoadingUtil.invokeUnloadCallbacks()
		end)

		for _, basePart in character:GetChildren() do
			if basePart:IsA("BasePart") then
				basePart.CollisionGroup = CollisionConstants.Groups.Character
				basePart.CanTouch = false
			end
		end

		task.spawn(function()
			local nameTag = ServerStorage.NameTag:Clone()
			nameTag.Parent = character:FindFirstChild("Head")
			nameTag.TextLabel.Text = player.DisplayName

			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end)

		repeat
			task.wait()
		until character.Parent

		local rootAttachment = Instance.new("Attachment")
		rootAttachment.Parent = character:FindFirstChild("HumanoidRootPart")

		CharacterLoadingUtil.invokeLoadCallbacks(character, player)
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
CharactersService.registerLoadCallback, CharactersService.registerUnloadCallback = CharacterLoadingUtil.getRegisteration()

PlayersService.registerLoadHandler("Character", function(player)
	loadCharacter(player.Character)
	player.CharacterAdded:Connect(loadCharacter)
end)

return CharactersService
