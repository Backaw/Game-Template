local BoostConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CurrencyConstants = require(ReplicatedStorage.Shared.Currency.CurrencyConstants)

export type Boost = { Multiplier: number, TimeLeft: number }
export type Stack = { Boost }
export type Stacks = { [CurrencyConstants.Currency]: Stack }

BoostConstants.DataEvents = {
	Created = "BoostCreated",
	Expired = "BoostExpired",
}

-- Can do products here

return BoostConstants
