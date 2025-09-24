local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)

return function(_, player: Player)
	TableUtil.print(PlayerDataService.get(player, ""))
end
