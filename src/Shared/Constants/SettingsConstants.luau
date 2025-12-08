--!strict
local SettingsConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local options: { [string]: Option } = {
	Music = { Name = "Music", Order = 1, Default = true },
	SoundEffects = { Name = "SoundEffects", Order = 2, Default = true },
}

SettingsConstants.Options = options
SettingsConstants.Remotes = {
	SettingOptionToggled = Remotes.defineEvent("SettingOptionToggled") :: Remotes.Event<string, boolean>,
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Option = {
	Name: string,
	Order: number,
	Default: boolean,
}

return SettingsConstants
