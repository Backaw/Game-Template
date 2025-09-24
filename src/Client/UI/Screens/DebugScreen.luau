--!strict
local DebugScreen = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local DISABLED = false

local playerGui = Players.LocalPlayer.PlayerGui
local HUD = playerGui.HUD
local screen = playerGui.Debug
local labels = screen.States
local itemConstructor = TemplateUtil.constructor(labels.TEMP_STATE)

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function DebugScreen.write(label: string, value: any, highlight: Color3?)
	if DISABLED then
		return
	end

	local textLabel = labels:FindFirstChild(label) :: TextLabel?
	if not textLabel then
		textLabel = itemConstructor()
		textLabel.Name = label
		if highlight then
			textLabel.TextColor3 = highlight
			textLabel.UIStroke.Color = Color3.new()
		end
	end

	(textLabel :: TextLabel).Text = ("%s: %s"):format(label, tostring(value))
end

function DebugScreen.writeNumber(label: string, value: number, highlight: Color3?)
	DebugScreen.write(label, ("%.3f"):format(value), highlight)
end

function DebugScreen.writeVector(label: string, value: Vector3, highlight: Color3?)
	DebugScreen.write(label, DebugUtil.printVector3(value, 2), highlight)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- Register state
do
	if not DISABLED then
		screen.Enabled = HUD.Enabled
		HUD:GetPropertyChangedSignal("Enabled"):Connect(function()
			screen.Enabled = HUD.Enabled
		end)
	else
		screen.Enabled = false
	end
end

return DebugScreen
