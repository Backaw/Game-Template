local FriendsService = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlayerService = require(Paths.Services.PlayersService)
local QuestService = require(Paths.Services.QuestService)

FriendsService.loadPlayer = PlayerService.promisifyLoader(function(player)
	for _, otherPlayer in  (Players:GetPlayers()) do
		pcall(function()
			if player ~= otherPlayer and otherPlayer:IsFriendsWith(player.UserId) then
				QuestService.incrementStat(player, "InvitedFriends", tostring(otherPlayer.UserId))
				PlayerService.onLoad(otherPlayer, function()
					QuestService.incrementStat(otherPlayer, "InvitedFriends", tostring(player.UserId))
				end)
			end
		end)
	end
end, "Friends")

return FriendsService
