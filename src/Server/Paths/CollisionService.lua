local CollisionService = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CollisionConstants = require(Paths.Shared.Constants.CollisionConstants)

local GROUPS = CollisionConstants.Groups

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function setGroupCollideableBlacklist(group: string, blacklist: CollisionConstants.Groups)
	for _, otherGroup in CollisionConstants.Groups do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, not table.find(blacklist, otherGroup))
	end
end

local function setGroupCollideableWhitelist(group: string, whitelist: CollisionConstants.Groups)
	for _, otherGroup in CollisionConstants.Groups do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, table.find(whitelist, otherGroup) ~= nil)
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for _, group in GROUPS do
	if group ~= CollisionConstants.Groups.Default then
		PhysicsService:RegisterCollisionGroup(group)
	end
end

return CollisionService
