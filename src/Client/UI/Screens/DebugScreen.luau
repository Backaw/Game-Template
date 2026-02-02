--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local DISABLED = false

local playerGui = Players.LocalPlayer.PlayerGui
local screen = playerGui.Debug
local labels = screen.States
local itemConstructor = TemplateUtil.constructor(labels.TEMP_STATE)

-- Register state
do
	if not DISABLED then
		screen.Enabled = true
	else
		screen.Enabled = false
	end
end

return DebugUtil.stateDisplay(itemConstructor, labels, DISABLED)
