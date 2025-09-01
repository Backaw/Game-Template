local Paths = {}

local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local DebugUtil = require(Shared.Utils.DebugUtil)
local PathsUtil = require(Shared.Utils.PathsUtil)

local DEBUG = DebugUtil.isDebugging(false)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
Paths.Initialized = require(Shared.DeferredPromise).new()

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------
local function moveToStorage(moving: Folder, destination: Instance)
	for _, child in moving:GetChildren() do
		local existingChild = destination:FindFirstChild(child.Name)
		if existingChild then
			for _, descendant in child:GetChildren() do
				descendant.Parent = existingChild
			end
			child:Destroy()
		else
			child.Parent = destination
		end
	end
end

local function loadModule(moduleScript)
	return PathsUtil.timeRequire(moduleScript)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
moveToStorage(Workspace.Assets.ReplicatedStorage, Paths.Assets)
moveToStorage(Workspace.Assets.ServerStorage, ServerStorage)

task.delay(0, function()
	local ping = os.clock()

	local initializing = {
		-- Services
		loadModule(Services.UnitTestingService),
		loadModule(Services.Products.ItemProductsService),
		loadModule(Services.CollisionService),
		loadModule(Services.PlayersService),
		loadModule(Services.CurrencyService),
		loadModule(Services.Products.ProductService),
		loadModule(Services.SettingsService),
		loadModule(Services.Cmdr.CmdrService),
		-- loadModule(Services.GameAnalyticsService),
		loadModule(Services.PromoCodeService),
		loadModule(Services.ItemService),

		-- loadModule(Services .Data.LeaderboardService),
		loadModule(Services.RewardService),
		loadModule(Services.FriendsService),
	}

	for _, module in initializing do
		local method = module.init
		if method then
			method()
		end
	end

	for _, module in initializing do
		task.spawn(function()
			local method = module.start
			if method then
				method()
			end
		end)
	end

	Paths.Initialized:invokeResolve()

	print("Welcome to NEW GAME")
	print(string.format("✅ Server loaded in %.6f seconds", os.clock() - ping))

	if DEBUG then
		PathsUtil.printLoadTimes()
	end
end)

return Paths
