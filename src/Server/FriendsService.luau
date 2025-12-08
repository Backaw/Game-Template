--!strict
local FriendsService = {}

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local PlayerService = require(ServerStorage.Server.PlayersService)
local QuestService = require(ServerStorage.Server.QuestService)

PlayerService.registerLoadHandler("Friends", function(player)
	for _, otherPlayer in (Players:GetPlayers()) do
		pcall(function()
			if player ~= otherPlayer and otherPlayer:IsFriendsWith(player.UserId) then
				QuestService.incrementStat(player, "InvitedFriends", tostring(otherPlayer.UserId))
				PlayerService.onLoad(otherPlayer, function()
					QuestService.incrementStat(otherPlayer, "InvitedFriends", tostring(player.UserId))
					return
				end)
			end
		end)
	end
end)

return FriendsService
