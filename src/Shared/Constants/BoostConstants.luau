local BoostConstants = {}

type _Boost = { Icon: string, Multiplicand: string, MultiplierAddend: number }
export type Boost = _Boost & { Name: string }

local boosts: { [string]: _Boost } = {}
BoostConstants.Boosts = boosts :: { [string]: Boost }

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for name, boost in boosts do
	boost.Name = name
end

return BoostConstants
