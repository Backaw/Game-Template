local LeaderstatService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local PlayersService = require(ServerStorage.Server.PlayersService)
local DataConstants = require(ReplicatedStorage.Shared.Data.DataConstants)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function LeaderstatService.createValue(player: Player, name: string, value: number)
	local instance = Instance.new("IntValue")
	instance.Name = name
	instance.Value = value
	instance.Parent = player.leaderstats
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

PlayersService.registerLoadHandler("Leaderstats", function(player: Player)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	for leaderstat, configs in DataConstants.Leaderstats do
		LeaderstatService.createValue(player, leaderstat, PlayerDataService.get(player, configs.Address))
	end
end)

PlayerDataService.Updated:Connect(function(event, player, value)
	for leaderstat, configs in pairs(DataConstants.Leaderstats) do
		if event == configs.Event then
			player.leaderstats[leaderstat].Value = value
			break
		end
	end
end)

return LeaderstatService
