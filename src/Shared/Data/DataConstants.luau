--!strict
local DataConstants = {}

local leaderstats: { [string]: { Address: string, Event: string } } = {}
local leaderboards: { [string]: { Stat: string, Formatter: ((number, boolean) -> string) | nil } } = {}
local versions: { [string]: number } = {
	Live = 1,
	QA = 1,
	Dev = 1,
}

DataConstants.SaveData = true
DataConstants.Version = versions
DataConstants.Leaderboards = leaderboards
DataConstants.Leaderstats = leaderstats

return DataConstants
