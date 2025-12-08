--!strict
local CollisionService = {}

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollisionConstants = require(ReplicatedStorage.Shared.Constants.CollisionConstants)

local GROUPS = CollisionConstants.Groups :: { [string]: string }

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function setGroupCollideableBlacklist(group: string, blacklist: CollisionConstants.Groups)
	for _, otherGroup in pairs(GROUPS) do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, not table.find(blacklist, otherGroup))
	end
end

local function setGroupCollideableWhitelist(group: string, whitelist: CollisionConstants.Groups)
	for _, otherGroup in pairs(GROUPS) do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, table.find(whitelist, otherGroup) ~= nil)
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for _, group in GROUPS do
	if group ~= GROUPS.Default then
		PhysicsService:RegisterCollisionGroup(group)
	end
end

return CollisionService
