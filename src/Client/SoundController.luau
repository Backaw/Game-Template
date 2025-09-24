--!strict
local SoundController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local LoadingController = require(ReplicatedStorage.Client.LoadingController)
local Sounds = require(ReplicatedStorage.Shared.Sounds)
local SettingsController = require(ReplicatedStorage.Client.SettingsController)
local SettingsConstants = require(ReplicatedStorage.Shared.Constants.SettingsConstants)
local ArrayUtil = require(ReplicatedStorage.Shared.Utils.ArrayUtil)

LoadingController.Loaded:andThen(function()
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
