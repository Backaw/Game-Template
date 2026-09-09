--!strict
local RewardUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images)
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

function RewardUtil.getIcon(reward: RewardConstants.Reward)
	if reward.Type == "Currency" then
		return if reward.Currency == "Coins" then "rbxassetid://112777636039839" else Images.Currencies[reward.Currency]
	elseif reward.Type == "Item" then
		return assert(ItemUtil.getItem(reward.ItemType, reward.ItemName), `Item {reward.ItemType} {reward.ItemName} not found`).Icon
	elseif reward.Type == "Boost" then
		return Images.Currencies[reward.Currency]
	end

	return ""
end

function RewardUtil.getDescription(reward: RewardConstants.Reward)
	if reward.Type == "Currency" then
		return StringUtil.commafiedNumber(reward.Amount) .. " coins"
	elseif reward.Type == "Item" then
		return ("%s %s"):format(StringUtil.seperateSnakeCase(reward.ItemName), reward.ItemType)
	elseif reward.Type == "Boost" then
		if reward.Multiplier <= 0 then
			return ("Infinite %s uses"):format(reward.Currency)
		end
		return ("x%d %s"):format(reward.Multiplier, reward.Currency)
	else
		return ""
	end
end

return RewardUtil
