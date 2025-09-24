local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemUtil = require(ReplicatedStorage.Shared.Items.ItemUtil)

return {
	Name = "giveItem",
	Aliases = {},
	Description = "Gives the player an item",
	Group = "Admin",
	Args = {
		{
			Type = "player",
			Name = "player",
			Description = "Player receiving the item",
		},
		{
			Type = "itemType",
			Name = "type",
			Description = "Type of item being given",
		},
		function(context)
			local itemTypeArgument = context:GetArgument(2)
			return ItemUtil.getItemNameCmdrArgument(itemTypeArgument)
		end,
	},
}
