--!strict
local Permissions = {}

local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local GROUP_ID = 32815233
local ADMIN_RANK = 253
local TESTER_RANK = 3

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function getRank(player: Player)
	local success, result = pcall(function()
		return player:GetRankInGroupAsync(GROUP_ID)
	end)

	return success and result or 0
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

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

if RunService:IsClient() then
	local policyInfo = PolicyService:GetPolicyInfoForPlayerAsync(Players.LocalPlayer)

	function Permissions.isGachaEnabled()
		return not policyInfo.ArePaidRandomItemsRestricted
	end
end

return Permissions
