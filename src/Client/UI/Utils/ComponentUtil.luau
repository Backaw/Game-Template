--!strict
local ComponentUtil = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui") or StarterGui

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ComponentUtil.getPlayerGui()
	return playerGui :: typeof(StarterGui)
end

return ComponentUtil
