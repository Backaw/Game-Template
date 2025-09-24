--!strict
local UnitTestingController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnitTester = require(ReplicatedStorage.Shared.UnitTester)

UnitTester.run(ReplicatedStorage.Client)

return UnitTestingController
