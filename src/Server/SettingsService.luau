--!strict
local SettingsService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local SettingsConstants = require(ReplicatedStorage.Shared.Constants.SettingsConstants)
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)

SettingsService.OptionToggled = Signal.new() :: Signal.Signal<Player, string, boolean>

SettingsConstants.Remotes.SettingOptionToggled:OnServerEvent(function(player, option, toggle)
	-- RETURN: Option doesn't exist
	if not SettingsConstants.Options[option] then
		return
	end

	PlayerDataService.set(player, "Settings." .. option, toggle)
	SettingsService.OptionToggled:Fire(player, option, toggle)
end)

return SettingsService
