--!strict
local RewardService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)
local CurrencyService = require(ServerStorage.Server.CurrencyService)
local BoostService = require(ServerStorage.Server.BoostService)
local GameAnalyticsService = require(ServerStorage.Server.GameAnalyticsService)
local ItemService = require(ServerStorage.Server.ItemService)

function RewardService.award(player: Player, reward: RewardConstants.Reward, source: string, clientInitiated: boolean?)
	if reward.Type == "Currency" then
		CurrencyService.transact(player, reward.Currency, reward.Amount, GameAnalyticsService.ResourceType.Reward, source, clientInitiated)
	elseif reward.Type == "Item" then
		ItemService.giveItem(player, reward.ItemType, reward.ItemName, reward.Loan)
	elseif reward.Type == "Boost" then
		BoostService.createBoost(player, reward.Name, reward.LengthInMinutes)
	end
end

return RewardService
