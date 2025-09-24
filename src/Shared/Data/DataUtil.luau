--!strict
local DataUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local IS_SERVER = game:GetService("RunService"):IsServer()

local DataHandler = (
	if IS_SERVER then require(ServerStorage.Server.Data.PlayerDataService) else require(ReplicatedStorage.Client.DataController)
) :: any

function DataUtil.get(player: Player, address: string)
	if IS_SERVER then
		return DataHandler.get(player, address)
	else
		return DataHandler.get(address)
	end
end

return DataUtil
