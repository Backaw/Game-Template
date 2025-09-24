--!strict
local RarityUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConstants = require(ReplicatedStorage.Shared.Rarity.RarityConstants)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

export type Rarity = RarityConstants.Rarity

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local sharedRandom = Random.new()
local rankedRarities: { RarityConstants.Rarity } = {}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

local function getProbability(choice: { [any]: any } | number)
	if typeof(choice) == "table" then
		local rarity = choice.Rarity
		if choice.Rarity then
			return RarityConstants.Probabilities[choice.Rarity]
		end
		return assert(rarity, `{choice} is not a valid rarity`)
	else
		return choice
	end
end

-- Greatest to least
function RarityUtil.getRarityRank(rarity: RarityConstants.Rarity, reverse: boolean?)
	local index = assert(table.find(rankedRarities, rarity), `{rarity} is not a valid rarity`)

	if reverse then
		return #rankedRarities - index + 1
	else
		return index
	end
end

function RarityUtil.draw(pool: { [any]: any }, luck: number?, random: Random?)
	random = random or sharedRandom
	luck = luck or 0

	local perfectSplit = 100
	local sum = 0

	for _, choice in pool do
		local probability = getProbability(choice)
		sum += probability + (perfectSplit - probability) * luck
	end

	local chosen = random:NextNumber(0, sum)
	for k, choice in pool do
		local probability = getProbability(choice)
		probability += (perfectSplit - probability) * luck

		if chosen <= probability then
			return k
		else
			chosen -= probability
		end
	end

	return nil
end

function RarityUtil.isRarity(value: any): RarityConstants.Rarity?
	local rarity = RarityConstants.Rarities[value]
	if rarity then
		return rarity
	else
		return nil
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	local rankedProbabilities = TableUtil.toArray(RarityConstants.Probabilities)
	table.sort(rankedRarities, function(a, b)
		return a < b
	end)

	for _, value in rankedProbabilities do
		table.insert(rankedRarities, TableUtil.find(RarityConstants.Probabilities, value) :: RarityConstants.Rarity)
	end
end

return RarityUtil
