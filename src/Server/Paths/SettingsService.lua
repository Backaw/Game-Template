local SettingsService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local Remotes = require(Shared.Remotes)
local Signal = require(Shared.Signal)
local SettingsConstants = require(Shared.Constants.SettingsConstants)
local PlayerDataService = require(Services.Data.PlayerDataService)

SettingsService.OptionToggled = Signal.new() -->  (player: Player, option: string, toggle: boolean)

Remotes.bindEvents({
	SettingOptionToggled = function(player: Player, option: string, toggle: boolean)
		-- RETURN: Option doesn't exist
		if not SettingsConstants.Options[option] then
			return
		end

		PlayerDataService.set(player, "Settings." .. option, toggle)
		SettingsService.OptionToggled:Fire(player, option, toggle)
	end,
})

return SettingsService
