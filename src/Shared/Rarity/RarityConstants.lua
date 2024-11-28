local RarityConstants = {}

export type Rarity = {
	Name: string?,
	Probability: number,
	Color: ColorSequence?,
}

local rarities: { [string]: Rarity } = {
	Common = {
		Probability = 42,
	},
	Rare = {
		Probability = 38,
	},
	Epic = {
		Probability = 17,
	},
	Legendary = {
		Probability = 13,
	},
}

RarityConstants.Rarities = rarities

for name, rarity in  (rarities) do
	rarity.Name = name
end

return RarityConstants
