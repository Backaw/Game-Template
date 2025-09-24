--!strict
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local screen = script.Parent:WaitForChild("LoadingScreen")
screen.Enabled = true
screen.Parent = game:GetService("Players").LocalPlayer.PlayerGui

ReplicatedFirst:RemoveDefaultLoadingScreen()
screen.Container.Logo.UIScale.Scale = 0
