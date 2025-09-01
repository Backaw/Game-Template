local GameAnalyticsService = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Services = ServerScriptService.Paths
local Shared = ReplicatedStorage.Modules
local GameAnalytics = require(Shared.Packages.GameAnalytics)
local GameConstants = require(Shared.Game.GameConstants)
local ProductUtil = require(Shared.Products.ProductUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local GameUtil = require(Shared.Game.GameUtil)
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local PlayersService = require(Services.PlayersService)
local CurrencyService = require(Services.CurrencyService)

local DEBUGGING = false

local IS_LIVE = GameUtil.isLive()
local IS_TRACKING = (RunService:IsStudio() or IS_LIVE)

local onPlayerReady: BindableEvent = game:GetService("ReplicatedStorage"):WaitForChild("OnPlayerReadyEvent")

function GameAnalyticsService.addEvent(eventType: string, playerId: number, options: table)
	if IS_TRACKING then
		task.spawn(function()
			if not GameAnalytics:isPlayerReady(playerId) then
				repeat
					onPlayerReady.Event:Wait()
				until GameAnalytics:isPlayerReady(playerId)
			end

			GameAnalytics["add" .. eventType](GameAnalytics, playerId, options)
		end)
	end
end

GameAnalyticsService.loadPlayer = PlayersService.promisifyLoader(function(player: Player)
	if IS_TRACKING then
		GameAnalytics:PlayerJoined(player)
		PlayersService.registerUnloadTask(player, function()
			GameAnalytics:PlayerRemoved(player)
		end)
	end
end, "GameAnalytics")

function GameAnalyticsService.init()
	if IS_TRACKING then
		GameAnalytics:initialize({
			build = GameConstants.Version,

			gameKey = "",
			secretKey = "",

			enableInfoLog = false,
			enableVerboseLog = false,

			--debug is by default enabled in studio only
			enableDebugLog = DEBUGGING,

			automaticSendBusinessEvents = true,
			reportErrors = true,

			availableResourceCurrencies = CurrencyConstants.IngameCurrencies,
			availableResourceItemTypes = CurrencyService.getResourceTypes(),
			availableGamepasses = TableUtil.getKeys(ProductUtil.getRobuxProducts()[Enum.InfoType.GamePass]),
		})
	end
end

return GameAnalyticsService
