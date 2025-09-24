return {
	Name = "incrementQuestStat",
	Aliases = {},
	Description = "Increases quest progress",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Player whose stats are being incremented",
		},
		{
			Type = "questStat",
			Name = "stat",
			Description = "Stat being increment",
		},
		{
			Type = "number",
			Name = "addend",
			Description = "How much to increment stat by",
		},
	},
}
