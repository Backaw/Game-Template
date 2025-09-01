local UnitTestingService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local UnitTester = require(ReplicatedStorage.Modules.UnitTester)

UnitTester.run(ReplicatedStorage.Modules)
UnitTester.run(ServerScriptService.Paths)

return UnitTestingService
