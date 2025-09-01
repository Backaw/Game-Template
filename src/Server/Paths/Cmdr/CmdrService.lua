local CmdrService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Permissions = require(Shared.Permissions)

-- Takes a while to load, so put on a separate thread
task.spawn(function()
	local Cmdr = require(Shared.Packages.Cmdr)

	-- Cmdr:RegisterDefaultCommands()
	-- Cmdr:RegisterCommand(Shared .Packages.Cmdr:WaitForChild("Server commands").help)

	Cmdr:RegisterCommandsIn(script.Parent.Commands)
	Cmdr:RegisterTypesIn(script.Parent.Types)

	Cmdr.Registry:RegisterHook("BeforeRun", function(context)
		local player: Player = context.Executor
		if not Permissions.canRunCommands(player) then
			return "You do not have permission to run this command"
		end
	end)
end)

return CmdrService
