local BoostConstants = {}

-- Backwards compatibility
local boosts: { [string]: {
	Name: string?,
	Icon: string?,
	IconThick: string?,
	Multiplicand: string,
	MultiplierAddend: number,
} } =
	{}

BoostConstants.Boosts = boosts

for name, boost in  (boosts) do
	boost.Name = name
end

return BoostConstants
