local GameAnalyticsService = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage.Shared
local Services = ServerStorage.Server
local GameAnalytics = require(Shared.Packages.GameAnalytics)
local GameConstants = require(Shared.Game.GameConstants)
local ProductUtil = require(Shared.Products.ProductUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local GameUtil = require(Shared.Game.GameUtil)
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local PlayersService = require(Services.PlayersService)
local ProductConstants = require(Shared.Products.ProductConstants)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUGGING = false
local IS_LIVE = GameUtil.isLive()
local IS_TRACKING = false and (RunService:IsStudio() or IS_LIVE)

local RESOURCE_TYPES = {
	Reward = "Reward",
}

local mergedResources = TableUtil.shallowUnion(RESOURCE_TYPES, ProductConstants.Types)
-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type EventType =
	"ResourceEvent"
	| "DesignEvent"
	| "AdEvent"
	| "ImpressionEvent"
	| "ProgressionEvent"
	| "HealthEvent"
	| "ErrorEvent"
	| "BusinessEvent"

export type ResourceType = keyof<typeof(RESOURCE_TYPES)> | string

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local onPlayerReady: BindableEvent = game:GetService("ReplicatedStorage"):WaitForChild("OnPlayerReadyEvent") :: BindableEvent

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

GameAnalyticsService.ResourceType = RESOURCE_TYPES

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function GameAnalyticsService.isResourceType(resourceType: any)
	return mergedResources[resourceType] ~= nil
end

function GameAnalyticsService.addEvent(eventType: EventType, playerId: number, options: { [string]: string | number | boolean })
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
			availableResourceItemTypes = TableUtil.toArray(mergedResources),

			availableGamepasses = TableUtil.getKeys(ProductUtil.getRobuxProducts()[Enum.InfoType.GamePass]),
		})
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

PlayersService.registerLoadHandler(PlayersService.LoadJobs.Analytics, function(player: Player)
	if IS_TRACKING then
		GameAnalytics:PlayerJoined(player)
		PlayersService.registerUnloadTask(player, function()
			GameAnalytics:PlayerRemoved(player)
		end)
	end
end)

return GameAnalyticsService
