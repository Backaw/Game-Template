--!strict
local PromoCodeConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

local codes: { [string]: { BestBy: number, Reward: RewardConstants.Reward } } = {}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

PromoCodeConstants.State = {
	DoesNotExist = "Invalid Code",
	UsedAlready = "Code already redeemed",
	Success = "Successfuly redeemed",
	Expired = "Code has expired",
}

PromoCodeConstants.Codes = codes

return PromoCodeConstants
