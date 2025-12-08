--!strict
local SettingsController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataController = require(ReplicatedStorage.Client.DataController)
local SettingsConstants = require(ReplicatedStorage.Shared.Constants.SettingsConstants)
local Signal = require(ReplicatedStorage.Shared.Signal)
local Limiter = require(ReplicatedStorage.Shared.Limiter)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local REMOTES = SettingsConstants.Remotes

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local cache = DataController.get("Settings") :: { [string]: boolean }

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

SettingsController.OptionToggled = Signal.new() :: Signal.Signal<SettingsConstants.Option, boolean>

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

local function isOptionValid(option: SettingsConstants.Option)
	if not SettingsConstants.Options[option.Name] then
		error(("%s is an invalid setting option"):format(option.Name))
	end
end

function SettingsController.get(option: SettingsConstants.Option)
	isOptionValid(option)
	return cache[option.Name]
end

function SettingsController.set(option: SettingsConstants.Option, value: boolean)
	isOptionValid(option)

	cache[option.Name] = value
	SettingsController.OptionToggled:Fire(option, cache[option.Name])

	Limiter.indecisive("ServerSettingToggling", option.Name, 0.2, function()
		REMOTES.SettingOptionToggled:FireServer(option.Name, value)
	end)
end

function SettingsController.onOptionToggled(option: SettingsConstants.Option, handler: (boolean) -> ())
	handler(SettingsController.get(option))
	return SettingsController.OptionToggled:Connect(function(toggledOption, toggle)
		if toggledOption == option then
			handler(toggle)
		end
	end)
end

function SettingsController.flip(option: SettingsConstants.Option)
	local value = not SettingsController.get(option)
	SettingsController.set(option, value)
	return value
end

return SettingsController
