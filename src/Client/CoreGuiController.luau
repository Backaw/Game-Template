--!strict
local CoreGuiController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CharacterUtil = require(ReplicatedStorage.Shared.Character.CharacterUtil)

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

-- Lock screen orientation
playerGui.ScreenOrientation = Enum.ScreenOrientation.LandscapeSensor

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

do
	local resetBindable = Instance.new("BindableEvent")
	resetBindable.Event:Connect(function()
		CharacterUtil.kill(player)
	end)

	-- This will remove the current behavior for when the reset button
	-- is pressed and just fire resetBindable instead.
	-- game:GetService("StarterGui"):SetCore("ResetButtonCallback", resetBindable)
end

return CoreGuiController
