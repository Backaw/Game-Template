--!strict
local RewardUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Images = require(ReplicatedStorage.Shared.Images)
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)
local BoostConstants = require(ReplicatedStorage.Shared.Constants.BoostConstants)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)

function RewardUtil.getIcon(reward: RewardConstants.Reward)
	if reward.Type == "Currency" then
		return Images.Currencies[reward.Currency]
	elseif reward.Type == "Item" then
		return ItemUtil.getItem(reward.ItemType, reward.ItemName).Icon
	end

	return ""
end

function RewardUtil.getDescription(reward: RewardConstants.Reward)
	if reward.Type == "Currency" then
		return StringUtil.commafiedNumber(reward.Amount) .. " cash"
	elseif reward.Type == "Item" then
		return ("%s %s"):format(StringUtil.seperateSnakeCase(reward.ItemName), reward.ItemType)
	elseif reward.Type == "Boost" then
		local boost = BoostConstants.Boosts[reward.Name]
		return ("x%d %s"):format(boost.MultiplierAddend + 1, boost.Multiplicand)
	else
		return ""
	end
end

return RewardUtil
