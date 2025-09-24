return {
	Name = "giveCurrency",
	Aliases = {},
	Description = "Gives a player currency",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Player receiving the item",
		},
		{
			Type = "currency",
			Name = "currency",
			Description = "Type of currency being given",
		},
		{
			Type = "number",
			Name = "amount",
			Description = "Amount of currency being given",
		},
	},
}
