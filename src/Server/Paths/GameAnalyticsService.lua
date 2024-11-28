local GameAnalyticsService = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local GameAnalytics = require(Paths.Shared.Packages.GameAnalytics)
local GameConstants = require(Paths.Shared.Game.GameConstants)
local ProductUtil = require(Paths.Shared.Products.ProductUtil)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local PlayersService = require(Paths.Services.PlayersService)
local CurrencyService = require(Paths.Services.CurrencyService)
local GameUtil = require(Paths.Shared.Game.GameUtil)
local CurrencyConstants = require(Paths.Shared.Currency.CurrencyConstants)

local DEBUGGING = false

local IS_LIVE = GameUtil.isLive()
local IS_TRACKING = false -- (RunService:IsStudio() or IS_LIVE)

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
