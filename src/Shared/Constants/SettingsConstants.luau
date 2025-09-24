--!strict
local SettingsConstants = {}

export type Option = {
	Name: string,
	Order: number,
	Default: boolean,
}

local options: { [string]: Option } = {
	Music = { Name = "Music", Order = 1, Default = true },
	SoundEffects = { Name = "SoundEffects", Order = 2, Default = true },
}

SettingsConstants.Options = options

return SettingsConstants
