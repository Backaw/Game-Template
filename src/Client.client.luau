--!strict
local Client = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LoadingController = require(ReplicatedStorage.Client.LoadingController)
local GameConstants = require(ReplicatedStorage.Shared.Game.GameConstants)
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
require(ReplicatedStorage.Shared.Remotes)

local CONTROLLERS = ReplicatedStorage.Client

local INITIALIZING = {
	-- Controllers
	CONTROLLERS.ProductController,
	CONTROLLERS.CoreGuiController,
	CONTROLLERS.Cmdr.CmdrController,
	CONTROLLERS.UnitTestingController,
	CONTROLLERS.SoundController,
	CONTROLLERS.ItemController,
	CONTROLLERS.InteractionController,
	CONTROLLERS.Character.CharacterController,
	CONTROLLERS.CameraController,

	-- UI
	CONTROLLERS.UI.UIScaleController,
	CONTROLLERS.UI.UIController,
	CONTROLLERS.UI.Utils.UIUtil,
	ReplicatedStorage.Shared.Packages.GameAnalytics,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local player = Players.LocalPlayer

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

Client.Initialized = LoadingController.Loaded

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function cloneInterfaces()
	local interfacesFolder = ReplicatedStorage:WaitForChild(UIConstants.InterfacesName)

	for _, v in interfacesFolder:GetChildren() do
		v:Clone().Parent = player.PlayerGui
	end
end

-------------------------------------------------------------------------------
-- INIT
-------------------------------------------------------------------------------

task.defer(function()
	local ping = os.clock()

	cloneInterfaces()

	require(ReplicatedStorage.Client.DataController)

	local modules: { { start: () -> (), init: () -> () } } = {}
	local moduleNames = {}
	for _, moduleScript in INITIALIZING do
		table.insert(moduleNames, moduleScript.Name)
		table.insert(modules :: any, (require(moduleScript)) :: any)
	end

	for i, module in ipairs(modules) do
		if module.init then
			local name = moduleNames[i]
			LoadingController.addTask(name .. "_Init", function()
				module.init()
			end)
		end
	end

	for i, module in ipairs(modules) do
		if module.start then
			local name = moduleNames[i]
			LoadingController.addTask(name .. "_Start", function()
				task.spawn(function()
					module.start()
				end)
			end)
		end
	end

	Client.Initialized:andThen(function()
		print(string.format("✅ Client loaded in %.6f seconds (v%s)", os.clock() - ping, GameConstants.Version))
	end)

	LoadingController.start()
end)

return Client
