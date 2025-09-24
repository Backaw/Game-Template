--!strict
local TopbarScreen = {}

local Players = game:GetService("Players")

local screen: ScreenGui = Players.LocalPlayer.PlayerGui.TopBar
screen.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
screen.Enabled = true

return TopbarScreen
