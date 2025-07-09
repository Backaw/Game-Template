local Permissions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameUtil = require(ReplicatedStorage.Modules.Game.GameUtil)

local GROUP_ID = 32584322
local ADMIN_RANK = 253
local TESTER_RANK = 3

local function getRank(player: Player)
	local success, result = pcall(function()
		return player:GetRankInGroup(GROUP_ID)
	end)

	return success and result or 0
end
function Permissions.isAdmin(player: Player)
	return getRank(player) >= ADMIN_RANK
end

function Permissions.isTester(player: Player)
	return getRank(player) == TESTER_RANK
end

function Permissions.canRunCommands(player: Player)
	if GameUtil.isLive() then
		return Permissions.isAdmin(player)
	else
		return true
	end
end

return Permissions
