--!strict
local UnitTestingService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local UnitTester = require(ReplicatedStorage.Shared.UnitTester)

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

UnitTester.run(ReplicatedStorage.Shared)
UnitTester.run(ServerStorage.Server)

return UnitTestingService
