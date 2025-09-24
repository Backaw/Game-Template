local CharacterConstants = {}

CharacterConstants.Moving = {
	Max = 60,
	Acceleration = 5,
}
CharacterConstants.Turning = {
	Max = 100,
	Acceleration = 30, --60,
}
CharacterConstants.SpeedBoost = {
	Multiplier = 1,
	Length = 1,
	MaxMultiples = 3,
}

return CharacterConstants
