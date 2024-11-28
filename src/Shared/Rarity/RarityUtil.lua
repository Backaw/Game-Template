local RarityUtil = {}

local random = Random.new()

local function getProbability(choice: table)
	return if choice.Rarity then choice.Rarity.Probability else choice.Probability
end

function RarityUtil.draw(pool: table, luck: number?, _random: Random?)
	_random = _random or random
	luck = luck or 0

	local perfectSplit = 100
	local sum = 0

	for _, choice in  (pool) do
		local probability = getProbability(choice)
		sum += probability + (perfectSplit - probability) * luck
	end

	local chosen = _random:NextNumber(0, sum)
	for k, choice in  (pool) do
		local probability = getProbability(choice)
		probability += (perfectSplit - probability) * luck

		if chosen <= probability then
			return k
		else
			chosen -= probability
		end
	end
end

return RarityUtil
