local LeaderstatService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local PlayersService = require(Paths.Services.PlayersService)
local DataConstants = require(Paths.Shared.Data.DataConstants)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function LeaderstatService.createValue(player: Player, name: string, value: number)
	local instance = Instance.new("IntValue")
	instance.Name = name
	instance.Value = value
	instance.Parent = player.leaderstats
end

LeaderstatService.loadPlayer = PlayersService.promisifyLoader(function(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	for leaderstat, configs in DataConstants.Leaderstats do
		LeaderstatService.createValue(player, leaderstat, PlayerDataService.get(player, configs.Address))
	end
end, "leaderstats")

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
PlayerDataService.Updated:Connect(function(event, player, value)
	for leaderstat, configs in pairs(DataConstants.Leaderstats) do
		if event == configs.Event then
			player.leaderstats[leaderstat].Value = value
			break
		end
	end
end)

return LeaderstatService
