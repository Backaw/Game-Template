local RarityUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RarityConstants = require(ReplicatedStorage.Modules.Rarity.RarityConstants)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

local sharedRandom = Random.new()
local rankedRarities: { RarityConstants.Rarity }

export type Rarity = RarityConstants.Rarity

local function getProbability(choice: table | number)
	if typeof(choice) == "table" then
		return if choice.Rarity then choice.Rarity.Probability else choice.Probability
	else
		return choice
	end
end

function RarityUtil.isRarity(value: any)
	return typeof(value) == "table" and value.Probability ~= nil
end

-- Greatest to least
function RarityUtil.getRarityRank(rarity: RarityConstants.Rarity, reverse: boolean?)
	local index = table.find(rankedRarities, rarity)
	if reverse then
		return #rankedRarities - index + 1
	else
		return index
	end
end

function RarityUtil.draw(pool: table, luck: number?, random: Random?)
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
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
do
	rankedRarities = TableUtil.toArray(RarityConstants.Rarities)
	table.sort(rankedRarities, function(a, b)
		return a.Probability < b.Probability
	end)
end

return RarityUtil
