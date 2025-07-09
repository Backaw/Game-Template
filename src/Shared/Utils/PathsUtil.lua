local PathsUtil = {}

local RunService = game:GetService("RunService")

local loadTimes: { { Module: ModuleScript, Length: number } } = {}

function PathsUtil.initModules(initializing: { table })
	for _, module in initializing do
		local method = module.init
		if method then
			method()
		end
	end

	for _, module in initializing do
		local method = module.start
		if method then
			method()
		end
	end
end

function PathsUtil.timeRequire(moduleScript: ModuleScript)
	local since = os.clock()

	local module = require(moduleScript)
	table.insert(loadTimes, { Module = moduleScript, Length = os.clock() - since })

	return module
end

function PathsUtil.printLoadTimes()
	table.sort(loadTimes, function(a, b)
		return a.Length > b.Length
	end)

	warn(("=== %s Load times ==="):format(if RunService:IsServer() then "Server" else "Client"))
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

return PathsUtil
