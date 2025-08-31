local SoundController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local Shared = ReplicatedStorage.Modules
local Sounds = require(Shared.Sounds)
local SettingsController = require(Controllers.SettingsController)
local SettingsConstants = require(Shared.Constants.SettingsConstants)
local ArrayUtil = require(Shared.Utils.ArrayUtil)
local Paths = require(Controllers)

Paths.Initialized:andThen(function()
	local songs = {}
	for _, song in SoundService.Music:GetChildren() do
		if song:IsA("Sound") then
			table.insert(songs, Sounds.create(song.Name))
		end
	end

	songs = ArrayUtil.shuffle(songs)

	if #songs > 0 then
		while true do
			for _, song in songs do
				-- Sounds.fadeIn(song)
				song:Play()
				-- Sounds.fadeOut(song)
				song.Ended:Wait()
			end
		end
	end
end)

SettingsController.onOptionToggled(SettingsConstants.Options.Music, function(toggle)
	Sounds.toggleGroupVolume("Music", toggle)
end)

SettingsController.onOptionToggled(SettingsConstants.Options.SoundEffects, function(toggle)
	Sounds.toggleGroupVolume("SoundEffects", toggle)
end)

return SoundController
