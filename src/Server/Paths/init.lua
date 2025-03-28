local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Paths = {}

Paths.Services = script
Paths.Shared = ReplicatedStorage.Modules

Paths.Initialized = require(Paths.Shared.DeferredPromise).new()
Paths.Assets = ReplicatedStorage.Assets

local DEBUG = false

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
	local since = os.clock()

	local returning = require(moduleScript)

	if DEBUG then
		print(("Loaded %s (%s)"):format(moduleScript.Name, os.clock() - since))
	end

	return returning
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
		loadModule(Paths.Shared.Utils.ParticleUtil),

		-- Services
		loadModule(Paths.Services.UnitTestingService),
		loadModule(Paths.Services.Products.ItemProductsService),
		loadModule(Paths.Services.CollisionService),
		loadModule(Paths.Services.PlayersService),
		loadModule(Paths.Services.CurrencyService),
		loadModule(Paths.Services.Products.ProductService),
		loadModule(Paths.Services.SettingsService),
		loadModule(Paths.Services.Cmdr.CmdrService),
		loadModule(Paths.Services.GameAnalyticsService),
		loadModule(Paths.Services.PromoCodeService),
		loadModule(Paths.Services.ItemService),

		-- loadModule(Paths.Services.Data.LeaderboardService),
		loadModule(Paths.Services.RewardService),
		loadModule(Paths.Services.FriendsService),
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
end)

return Paths
