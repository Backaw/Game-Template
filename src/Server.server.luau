local Server = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")

local DeferredPromise = require(ReplicatedStorage.Shared.DeferredPromise)
local GameConstants = require(ReplicatedStorage.Shared.Game.GameConstants)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local PathsUtil = require(ReplicatedStorage.Shared.Utils.PathsUtil)

local SERVICES = ServerStorage.Server
local DEBUG = DebugUtil.isDebugging(false)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------
Server.Initialized = DeferredPromise.new()

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function prepareInterfacesFolder()
	local folder = Instance.new("Folder")
	folder.Name = GameConstants.InterfacesName

	for _, v in StarterGui:GetChildren() do
		v.Parent = folder
	end

	folder.Parent = ReplicatedStorage
end

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
moveToStorage(workspace.Assets.ReplicatedStorage, ReplicatedStorage)
moveToStorage(workspace.Assets.ServerStorage, ServerStorage)

task.delay(0, function()
	local ping = os.clock()

	prepareInterfacesFolder()

	local initializing = {
		-- SERVICES
		loadModule(SERVICES.UnitTestingService),
		loadModule(SERVICES.Products.ItemProductsService),
		loadModule(SERVICES.CollisionService),
		loadModule(SERVICES.Data.PlayerDataService),
		loadModule(SERVICES.PlayersService),
		loadModule(SERVICES.CurrencyService),
		loadModule(SERVICES.Products.ProductService),
		loadModule(SERVICES.SettingsService),
		loadModule(SERVICES.Cmdr.CmdrService),
		loadModule(SERVICES.PromoCodeService),
		loadModule(SERVICES.ItemService),

		loadModule(SERVICES.RewardService),
		loadModule(SERVICES.FriendsService),
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

	Server.Initialized:invokeResolve()

	print("Welcome to NEW_GAME")
	print(string.format("✅ Server loaded in %.6f seconds", os.clock() - ping))

	if DEBUG then
		PathsUtil.printLoadTimes()
	end
end)

return Server
