return {
	Name = "giveBoost",
	Aliases = {},
	Description = "Give's a player a boost",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "The player receiving the boost",
		},
		{
			Type = "boost",
			Name = "boost",
			Description = "Boost the player is receiving",
		},
		{
			Type = "number",
			Name = "lengthInMinutes",
			Description = "How long should the boost last",
		},
	},
}
