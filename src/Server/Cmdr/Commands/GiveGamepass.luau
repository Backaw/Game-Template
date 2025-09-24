return {
	Name = "giveGamepass",
	Aliases = {},
	Description = "Gives the player an gamepass",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Player receiving the gamepass",
		},
		{
			Type = "gamepass",
			Name = "gamepass",
			Description = "Gamepass being given",
		},
	},
}
