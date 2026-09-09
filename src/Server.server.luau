--!strict
local Server = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local DeferredPromise = require(ReplicatedStorage.Shared.DeferredPromise)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local ModuleUtil = require(ReplicatedStorage.Shared.Utils.ModuleUtil)
require(ReplicatedStorage.Shared.Remotes)

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
	folder.Name = UIConstants.InterfacesName

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
	return ModuleUtil.timeRequire(moduleScript)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

moveToStorage(Workspace.Assets.ReplicatedStorage, ReplicatedStorage.Assets)
moveToStorage(Workspace.Assets.ServerStorage, ServerStorage)

task.delay(0, function()
	local ping = os.clock()

	prepareInterfacesFolder()

	local initializing = {
		-- SERVICES
		loadModule(SERVICES.UnitTestingService),
		loadModule(SERVICES.Products.ItemProductsGenerator),
		loadModule(SERVICES.CollisionService),
		loadModule(SERVICES.Data.PlayerDataService),
		loadModule(SERVICES.PlayersService),
		loadModule(SERVICES.CurrencyService),
		loadModule(SERVICES.Products.ProductService),
		loadModule(SERVICES.SettingsService),
		loadModule(SERVICES.Cmdr.CmdrService),
		loadModule(SERVICES.PromoCodeService),
		loadModule(SERVICES.ItemService),
		loadModule(SERVICES.CharactersService),
	}

	for _, module in initializing do
		local method = (module :: any).init
		if method then
			(method :: any)()
		end
	end

	for _, module in initializing do
		local method = (module :: any).start
		if method then
			task.spawn(method)
		end
	end

	Server.Initialized:invokeResolve()

	print("Welcome to NEW GAME")
	print(string.format("✅ Server loaded in %.6f seconds", os.clock() - ping))

	if DEBUG then
		ModuleUtil.printLoadTimes()
	end
end)

return Server
