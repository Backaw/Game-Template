--!strict
local ModuleUtil = {}

local IS_SERVER = game:GetService("RunService"):IsServer()

type LoadTime = { Module: ModuleScript, Length: number }

local loadTimes: { LoadTime } = {}

function ModuleUtil.initModules(initializing: { any })
	for _, module in initializing do
		local method = module.init :: () -> ()
		if method then
			method()
		end
	end

	for _, module in initializing do
		local method = module.start :: () -> ()
		if method then
			method()
		end
	end
end

function ModuleUtil.timeRequire(moduleScript: ModuleScript)
	local since = os.clock()

	local module = require(moduleScript) :: any
	table.insert(loadTimes, { Module = moduleScript, Length = os.clock() - since })

	return module
end

function ModuleUtil.printLoadTimes()
	table.sort(loadTimes, function(a: LoadTime, b: LoadTime)
		return a.Length > b.Length
	end)

	warn(("=== %s Load times ==="):format(if IS_SERVER then "Server" else "Client"))
	for _, entry in ipairs(loadTimes) do
		warn(string.format("%s: %.6f seconds", entry.Module.Name, entry.Length))
	end

	local total = 0
	for _, entry in ipairs(loadTimes) do
		total = total + entry.Length
	end
	local avg = #loadTimes > 0 and (total / #loadTimes) or 0
	warn(string.format("Average load time: %.6f seconds", avg))
	warn("===")
end

return ModuleUtil
