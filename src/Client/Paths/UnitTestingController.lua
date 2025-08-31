local UnitTestingController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UnitTester = require(ReplicatedStorage.Modules.UnitTester)

UnitTester.run(Players.LocalPlayer.PlayerScripts.Paths)

return UnitTestingController
