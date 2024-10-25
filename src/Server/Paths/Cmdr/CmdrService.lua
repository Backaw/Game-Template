local CmdrService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Permissions = require(Paths.Shared.Permissions)

-- Takes a while to load, so put on a separate thread
task.spawn(function()
	local Cmdr = require(Paths.Packages.Cmdr)

	-- Cmdr:RegisterDefaultCommands()
	-- Cmdr:RegisterCommand(Paths.Packages.Cmdr:WaitForChild("Server commands").help)

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
