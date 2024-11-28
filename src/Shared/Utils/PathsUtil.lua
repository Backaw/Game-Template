local PathsUtil = {}

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

return PathsUtil
