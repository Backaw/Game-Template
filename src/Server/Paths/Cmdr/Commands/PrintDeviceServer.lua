local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage.Modules.Remotes)

local devices: { [Player]: string } = {}

Players.PlayerRemoving:Connect(function(player)
	devices[player] = nil
end)

Remotes.bindEvents({
	DeviceDetermined = function(player, device)
		devices[player] = device
	end,
})

return function(_, player: Player)
	print(("(%s)%s's device: %s"):format(player.UserId, player.Name, devices[player] or "nil"))
end
