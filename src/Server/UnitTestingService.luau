--!strict
local UnitTestingService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UnitTester = require(ReplicatedStorage.Shared.UnitTester)

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

UnitTester.run(ReplicatedStorage.Shared)
UnitTester.run(ServerScriptService.Server)

return UnitTestingService
