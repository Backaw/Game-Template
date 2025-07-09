local CharactersService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Paths = require(ServerScriptService.Paths)
local PlayersService = require(Paths.Services.PlayersService)
local Permissions = require(Paths.Shared.Permissions)
local CharacterConstants = require(Paths.Shared.Character.CharacterConstants)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function loadCharacter(character: Model)
	if not character then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)

	local humanoid: Humanoid = character.Humanoid
	humanoid.WalkSpeed = CharacterConstants.WalkSpeed
	humanoid.Died:Connect(function()
		-- Unload handlers
	end)

	task.spawn(function()
		local prefix = ""
		if Permissions.isTester(player) then
			prefix = "🧪 "
		elseif Permissions.isAdmin(player) then
			prefix = "⚒️ "
		end

		local nameTag: BillboardGui = ServerStorage.NameTag:Clone()
		nameTag.Parent = character.Head
		nameTag.TextLabel.Text = prefix .. player.DisplayName

		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end)

	repeat
		task.wait()
	until character.Parent

	-- Handlers
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
CharactersService.loadPlayer = PlayersService.promisifyLoader(function(player)
	loadCharacter(player.Character)
	player.CharacterAdded:Connect(loadCharacter)
end, "character")

return CharactersService
