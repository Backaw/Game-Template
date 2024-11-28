local LeaderboardController = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local DataConstants = require(Paths.Shared.Data.DataConstants)
local DataController = require(Paths.Controllers.DataController)
local QuestUtil = require(Paths.Shared.Quests.QuestUtil)

local player = Players.LocalPlayer

--[[
for _, leaderboard in  (Workspace.Lobby.Leaderboards:GetChildren()) do
	local info = DataConstants.Leaderboards[leaderboard.Name]
	local stat = info.Stat

	local personalLabel = leaderboard.Board.SurfaceGui.Personal
	personalLabel.Username.Text = player.Name
	personalLabel.Value.Text = info.Formatter(DataController.get(QuestUtil.getStatAddress(stat)), true)

	DataController.Updated:Connect(function(event, value, metadata)
		if event == "QuestStatChanged" and metadata.Stat == stat then
			personalLabel.Value.Text = info.Formatter(value, true)
		end
	end)
end
*]]

return LeaderboardController
