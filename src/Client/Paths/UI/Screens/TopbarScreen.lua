local TopbarScreen = {}

local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local screen: ScreenGui = Paths.UI.TopBar
screen.Enabled = true

return TopbarScreen
