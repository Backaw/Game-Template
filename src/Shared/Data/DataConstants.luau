--!strict
local DataConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataTypes = require(ReplicatedStorage.Shared.Data.DataTypes)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local leaderstats: { [string]: { Address: string, Event: string } } = {}
local leaderboards: { [string]: { Stat: string, Formatter: ((number, boolean) -> string) | nil } } = {}
local versions: { [string]: number } = {
	Live = 1,
	QA = 1,
	Dev = 1,
}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

DataConstants.Remotes = {
	DataUpdated = Remotes.defineEvent("DataUpdated") :: Remotes.Event<string, any, string?, DataTypes.EventMeta>,
	DataInitialized = Remotes.defineEvent("DataInitialized") :: Remotes.Event<DataTypes.Store>,
	ClientReadyForData = Remotes.defineEvent("ClientReadyForData"),
}

DataConstants.SaveData = true
DataConstants.Version = versions
DataConstants.Leaderboards = leaderboards
DataConstants.Leaderstats = leaderstats

return DataConstants
