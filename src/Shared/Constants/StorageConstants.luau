--!strict

local _Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type ReplicatedAssets = typeof(_Workspace.Assets.ReplicatedStorage)
export type ServerAssets = typeof(_Workspace.Assets.ServerStorage)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

return {
	ReplicatedAssets = ((ReplicatedStorage.Assets) :: any) :: ReplicatedAssets,
	ServerAssets = ((ServerStorage) :: any) :: ServerAssets,
}
