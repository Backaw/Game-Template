--!strict
local PromoCodeConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RewardConstants = require(ReplicatedStorage.Shared.Rewards.RewardConstants)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

local codes: { [string]: { BestBy: number, Reward: RewardConstants.Reward } } =
	{ Something = { BestBy = 1733289600, Reward = { Type = "Currency", Amount = 100, Currency = "Cash" } } }

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
PromoCodeConstants.Remotes = {
	RedeemCode = Remotes.defineFunction("RedeemCode") :: Remotes.Function<(string), (string)>,
}

return PromoCodeConstants
