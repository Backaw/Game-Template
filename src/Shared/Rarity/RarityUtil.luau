--!strict
local RarityUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConstants = require(ReplicatedStorage.Shared.Rarity.RarityConstants)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Rarity = RarityConstants.Rarity

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local RANKED_RARITIES: { RarityConstants.Rarity } = {
	RarityConstants.Rarities.Common,
	RarityConstants.Rarities.Rare,
	RarityConstants.Rarities.Epic,
	RarityConstants.Rarities.Legendary,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local sharedRandom = Random.new()

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function getProbability(choice: { [any]: any } | number)
	if typeof(choice) == "table" then
		if choice.Probability then
			return choice.Probability
		end
		-- return assert(rarity, `{choice} is not a valid rarity`)
		error(`{choice} is not a valid choice`)
	else
		return choice
	end
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- Greatest to least
function RarityUtil.getRarityRank(rarity: RarityConstants.Rarity, reverse: boolean?)
	local index = assert(table.find(RANKED_RARITIES, rarity), `{rarity} is not a valid rarity`)

	if reverse then
		return #RANKED_RARITIES - index + 1
	else
		return index
	end
end

function RarityUtil.draw<T>(pool: { [T]: any }, random: Random?, ignore: { T }?, luck: number?): T
	ignore = ignore or {}
	random = random or sharedRandom
	luck = luck or 0

	local perfectSplit = 100
	local sum = 0

	for option, choice in pool do
		if not table.find(ignore, option) then
			local probability = getProbability(choice)
			sum += probability + (perfectSplit - probability) * luck
		end
	end

	local chosen = random:NextNumber(0, sum)
	for k, choice in pool do
		if table.find(ignore, k) then
			continue
		end

		local probability = getProbability(choice)
		probability += (perfectSplit - probability) * luck

		if chosen <= probability then
			return k
		else
			chosen -= probability
		end
	end

	error("No choice was drawn from the pool")
end

function RarityUtil.isRarity(value: any): RarityConstants.Rarity?
	local rarity = RarityConstants.Rarities[value]
	if rarity then
		return rarity
	else
		return nil
	end
end

return RarityUtil
