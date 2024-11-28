local SoundController = {}

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)
local Sounds = require(Paths.Shared.Sounds)
local SettingsController = require(Paths.Controllers.SettingsController)
local SettingsConstants = require(Paths.Shared.Constants.SettingsConstants)
local ArrayUtil = require(Paths.Shared.Utils.ArrayUtil)

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
