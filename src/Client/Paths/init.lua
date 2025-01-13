local Paths = {}
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LoadingController = require(script.LoadingController)
local GameConstants = require(ReplicatedStorage.Modules.Game.GameConstants)

local INITIALIZING = {
	-- Controllers
	script.ProductController,
	script.CoreGuiController,
	script.Cmdr.CmdrController,
	script.UnitTestingController,
	script.SoundController,
	script.ItemController,
	script.LeaderboardController,
	script.InteractionController,
	script.Character.CharacterController,

	-- UI
	script.UI.UIScaleController,
	script.UI.UIController,
	script.UI.Utils.UIUtil,

	-- Analytics
	script.Parent:WaitForChild("GameAnalyticsClient"),
}

Paths.Controllers = script
Paths.Shared = ReplicatedStorage.Modules
Paths.Assets = ReplicatedStorage.Assets
Paths.UI = Players.LocalPlayer.PlayerGui
Paths.Initialized = LoadingController.Loaded

task.defer(function()
	local ping = os.clock()

	require(script.DataController)

	for _, moduleScript in INITIALIZING do
		LoadingController.addTask(moduleScript.Name .. "_Init", function()
			local module = require(moduleScript)

			if module.init then
				module.init()
			end
		end)
	end

	for _, moduleScript in INITIALIZING do
		LoadingController.addTask(moduleScript.Name .. "_Start", function()
			task.spawn(function()
				local module = require(moduleScript)
				if module.start then
					module.start()
				end
			end)
		end)
	end

	Paths.Initialized:andThen(function()
		print(string.format("✅ Client loaded in %.6f seconds (v%s)", os.clock() - ping, GameConstants.Version))
	end)

	LoadingController.start()
end)
return Paths
