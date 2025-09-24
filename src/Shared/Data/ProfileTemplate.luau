local ProfileTemplate = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SettingsConstants = require(ReplicatedStorage.Shared.Constants.SettingsConstants)
local GameConstants = require(ReplicatedStorage.Shared.Game.GameConstants)
local ItemConstants = require(ReplicatedStorage.Shared.Items.ItemConstants)
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local DataFormatUtil = require(ReplicatedStorage.Shared.Data.DataFormatUtil)
local ItemUtil

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

ProfileTemplate.get = function()
	if not ItemUtil then
		ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil) :: any
	end

	local store = {}

	store.LastLogin = {
		Time = os.time(),
		Version = GameConstants.Version,
	}

	store.Currencies = {
		Cash = 0,
	}
	store.Multipliers = {
		Cash = 1,
	}
	store.Boosts = {}

	store.OwnedBundles = {}
	store.GamePasses = {}
	store.DevProducts = {}

	store.EquippedItems = {}
	store.OwnedItems = {}
	for _, itemType in pairs(ItemConstants.Types) do
		local defaultItem = ItemUtil.getDefaultItem(itemType)
		if defaultItem then
			store.EquippedItems[itemType] = defaultItem
		end
		store.OwnedItems[itemType] = {}
	end

	store.Quests = {
		Stats = QuestConstants.DefaultStats,
		Completed = {},
	}

	store.UnlockedBadges = {}
	store.RedeemedCodes = {}
	store.Settings = TableUtil.getProperties(SettingsConstants.Options, "Default")

	return store :: DataFormatUtil.Store
end

return ProfileTemplate
