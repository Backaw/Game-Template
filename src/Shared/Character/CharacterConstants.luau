local CharacterConstants = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CharacterConstants.RespawnTime = 6
CharacterConstants.WalkSpeed = 30

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Character = typeof(require(ReplicatedStorage.Shared.Constants.StorageConstants).ReplicatedAssets.Character)

return CharacterConstants
