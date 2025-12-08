local CmdrService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Permissions = require(ReplicatedStorage.Shared.Permissions)

-- Takes a while to load, so put on a separate thread
task.spawn(function()
	-- local Cmdr = require(ServerStorage.Packages.Cmdr)
	local Cmdr = require(ServerStorage.Packages.Cmdr)
	-- Cmdr:RegisterDefaultCommands()
	-- Cmdr:RegisterCommand(Shared .Packages.Cmdr:WaitForChild("Server commands").help)

	Cmdr:RegisterCommandsIn(script.Parent.Commands)
	Cmdr:RegisterTypesIn(script.Parent.Types)

	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		local player: Player = context.Executor
		return if not Permissions.canRunCommands(player) then "You do not have permission to run this command" else nil
	end)
end)

return CmdrService
