local RewardService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local RewardConstants = require(Shared.Rewards.RewardConstants)
local CurrencyService = require(Services.CurrencyService)
local BoostService = require(Services.BoostService)
local ItemService

function RewardService.award(player: Player, reward: RewardConstants.Reward, source: string, clientInitiated: boolean?)
	if reward.Type == RewardConstants.Types.Currency then
		CurrencyService.transact(player, reward.Currency, reward.Amount, CurrencyService.ResourceType.Reward, source, clientInitiated)
	elseif reward.Type == RewardConstants.Types.Item then
		ItemService.giveItem(player, reward.ItemType, reward.ItemName, reward.Loan)
	elseif reward.Type == RewardConstants.Types.Boost then
		BoostService.createBoost(player, reward.Name, reward.LengthInMinutes)
	end
end

function RewardService.init()
	ItemService = require(Services.ItemService)
end

return RewardService
