--!strict
local DataUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local IS_GAME = RunService:IsRunning()

local DataHandler = if IS_GAME
	then (if IS_SERVER then require(ServerStorage.Server.Data.PlayerDataService) else require(ReplicatedStorage.Client.DataController)) :: any
	else nil

function DataUtil.get(player: Player, address: string)
	if IS_SERVER then
		return DataHandler.get(player, address)
	else
		return DataHandler.get(address)
	end
end

return DataUtil
