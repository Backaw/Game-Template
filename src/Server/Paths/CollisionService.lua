local CollisionService = {}

local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local CollisionConstants = require(Paths.Shared.Constants.CollisionConstants)

local function setGroupCollideableBlacklist(group: string, blacklist: CollisionConstants.Groups)
	for _, otherGroup in CollisionConstants.Groups do
		if not table.find(blacklist, otherGroup) then
			PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
		else
			PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
		end
	end
end

local function setGroupCollideableWhitelist(group: string, whitelist: CollisionConstants.Groups)
	for _, otherGroup in CollisionConstants.Groups do
		if table.find(whitelist, otherGroup) then
			PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
		else
			PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
		end
	end
end

local function setCollision(group, collidableGroups: CollisionConstants.Groups?, nonCollidableGroups: CollisionConstants.Groups?)
	for _, otherGroup in collidableGroups or {} do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, true)
	end

	for _, otherGroup in nonCollidableGroups or {} do
		PhysicsService:CollisionGroupSetCollidable(group, otherGroup, false)
	end
end

for _, group in CollisionConstants.Groups do
	if group ~= CollisionConstants.Groups.Default then
		PhysicsService:RegisterCollisionGroup(group)
	end
end

return CollisionService
