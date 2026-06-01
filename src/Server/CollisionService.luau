--!strict
local CollisionService = {}

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollisionConstants = require(ReplicatedStorage.Shared.Constants.CollisionConstants)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUG = DebugUtil.isDebugging(false)

local GROUPS = CollisionConstants.Groups

local BLACKLISTS: { [CollisionConstants.Group]: CollisionConstants.Groups } = {
	[GROUPS.Character] = { GROUPS.Character },
}

local WHITELISTS: typeof(BLACKLISTS) = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function setGroupCollideableWhitelist(group: CollisionConstants.Group, whitelist: CollisionConstants.Groups)
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

-- Check for conflicts between blacklists and whitelists
-- We check all pairs (groupA, groupB) once and check both directions
do
	local checkedPairs: { [string]: boolean } = {}

	for _, groupA in pairs(GROUPS) do
		if groupA == GROUPS.Default then
			continue
		end

		for _, groupB in pairs(GROUPS) do
			if groupB == GROUPS.Default or groupA == groupB then
				continue
			end

			-- Check each pair only once (A, B) = (B, A)
			local pairKey = if groupA < groupB then `${groupA}-${groupB}` else `${groupB}-${groupA}`
			if checkedPairs[pairKey] then
				continue
			end
			checkedPairs[pairKey] = true

			local blacklistA = BLACKLISTS[groupA] or {}
			local whitelistA = WHITELISTS[groupA] or {}
			local blacklistB = BLACKLISTS[groupB] or {}
			local whitelistB = WHITELISTS[groupB] or {}

			-- Check both directions in one pass:
			-- If A blacklists B and B whitelists A -> conflict
			-- If A whitelists B and B blacklists A -> conflict
			if table.find(blacklistA, groupB) and table.find(whitelistB, groupA) then
				warn(`Collision conflict: {groupA} has {groupB} in blacklist, but {groupB} has {groupA} in whitelist`)
			elseif table.find(whitelistA, groupB) and table.find(blacklistB, groupA) then
				warn(`Collision conflict: {groupA} has {groupB} in whitelist, but {groupB} has {groupA} in blacklist`)
			end
		end
	end
end

-- Set collision groups intelligently
do
	for _, group in pairs(GROUPS) do
		if group == GROUPS.Default then
			continue
		end

		local groupBlacklist = BLACKLISTS[group] or {}
		local groupWhitelist = WHITELISTS[group] or {}
		local collidableGroups: { CollisionConstants.Group } = {}

		-- If this group has a whitelist, it can ONLY collide with groups in the whitelist
		local hasWhitelist = WHITELISTS[group] ~= nil

		-- Determine which groups this group can collide with
		for _, otherGroup in pairs(GROUPS) do
			-- This group's blacklist takes precedence
			if table.find(groupBlacklist, otherGroup) then
				continue
			end

			-- If this group has a whitelist, check if otherGroup is in it
			if hasWhitelist and not table.find(groupWhitelist, otherGroup) then
				continue
			end

			-- Now check if otherGroup allows collision with this group:
			-- If otherGroup has a whitelist, it can ONLY collide with groups in its whitelist
			-- If otherGroup has no whitelist, it can collide with groups not in its blacklist
			local otherGroupBlacklist = BLACKLISTS[otherGroup] or {}
			local otherGroupWhitelist = WHITELISTS[otherGroup] or {}
			local otherHasWhitelist = WHITELISTS[otherGroup] ~= nil

			local otherAllowsCollision: boolean
			if otherHasWhitelist then
				-- Other group has a whitelist - can only collide if this group is in the whitelist
				otherAllowsCollision = table.find(otherGroupWhitelist, group) ~= nil
			else
				-- Other group has no whitelist - can collide if this group is not in its blacklist
				otherAllowsCollision = not table.find(otherGroupBlacklist, group)
			end

			if otherAllowsCollision then
				table.insert(collidableGroups, otherGroup)
			end
		end

		if DEBUG then
			print(`Group {group} can collide with:`, collidableGroups)
		end
		setGroupCollideableWhitelist(group, collidableGroups)
	end
end

return CollisionService
