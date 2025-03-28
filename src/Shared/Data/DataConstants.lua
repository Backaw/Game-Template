local DataConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingConstans = require(ReplicatedStorage.Modules.Constants.SettingsConstants)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)
local QuestConstants = require(ReplicatedStorage.Modules.Quests.QuestConstants)
local ItemConstants = require(ReplicatedStorage.Modules.Items.ItemConstants)
local GameConstants = require(ReplicatedStorage.Modules.Game.GameConstants)

DataConstants.Version = {
	Live = 1,
	QA = 1,
	Dev = 1,
}

local leaderstats: { [string]: string } = {}

local leaderboards: { [string]: { Stat: string, Formatter: ((number, boolean) -> string) | nil } } = {}

DataConstants.Leaderboards = leaderboards
DataConstants.Leaderstats = leaderstats

DataConstants.DefaultPlayerData = function()
	local store = {}

	store.LastLogin = {
		Time = os.time(),
		Version = GameConstants.Version,
	}

	store.Currencies = {
		Coin = 0,
	}
	store.Multipliers = {
		Coin = 1,
	}
	store.Boosts = {}

	store.OwnedBundles = {}
	store.GamePasses = {}
	store.DevProducts = {}

	store.EquippedItems = {}
	store.OwnedItems = {}
	for _, itemType in ItemConstants.Types do
		store.OwnedItems[itemType] = {}
	end

	store.Quests = {
		Stats = QuestConstants.DefaultStats,
		Completed = {},
	}

	store.UnlockedBadges = {}
	store.RedeemedCodes = {}
	store.Settings = TableUtil.getProperties(SettingConstans.Options, "Default")

	store.Banned = false

	return store
end

return DataConstants
