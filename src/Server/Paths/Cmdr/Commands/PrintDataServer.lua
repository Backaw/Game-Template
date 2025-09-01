local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PlayerDataService = require(ServerScriptService.Paths.Data.PlayerDataService)
local TableUtil = require(ReplicatedStorage.Modules.Utils.TableUtil)

return function(_, player: Player)
	TableUtil.print(PlayerDataService.get(player, ""))
end
