local DataUtil = {}

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local IS_SERVER = game:GetService("RunService"):IsServer()
local DataHandler = if IS_SERVER
	then require(ServerScriptService.Paths.Data.PlayerDataService)
	else require(Players.LocalPlayer.PlayerScripts.Paths.DataController)

function DataUtil.get(player: Player, address: string)
	if IS_SERVER then
		return DataHandler.get(player, address)
	else
		return (DataHandler :: typeof(require(Players.LocalPlayer.PlayerScripts.Paths.DataController))).get(address)
	end
end

return DataUtil
