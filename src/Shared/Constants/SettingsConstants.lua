local SettingsConstants = {}

export type Option = {
	Name: string?,
	Order: number,
	Default: boolean,
}

local options: { [string]: Option } = {
	Music = { Order = 1, Default = true },
	SoundEffects = { Order = 2, Default = true },
}

SettingsConstants.Options = options

for name, option in  (SettingsConstants.Options) do
	option.Name = name
end

return SettingsConstants
