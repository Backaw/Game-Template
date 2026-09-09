--!strict
local DebugScreen = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)
local TimeUtil = require(ReplicatedStorage.Shared.Utils.TimeUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local ENABLED = DebugUtil.isDebugging(false)
local DISPLAY_META = true

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local playerGui = Players.LocalPlayer.PlayerGui
local screen = playerGui.Debug

local entryConstructor = TemplateUtil.constructor(screen.TEMP_LOG.TEMP_ENTRY)
local logConstructor = TemplateUtil.constructor(screen.TEMP_LOG)

function DebugScreen.newLog(enabled: boolean?, title: string?)
	local list = logConstructor()
	local display = DebugUtil.stateDisplay(entryConstructor, list, not ENABLED or enabled == false)

	if title then
		display.write(title, "", Color3.fromRGB(255, 202, 44))
	end

	return display
end

do
	screen.Enabled = ENABLED
	if ENABLED then
		-- Register state

		local placeLog = DebugScreen.newLog(DISPLAY_META, "Meta")
		local startTime = os.clock()
		local fpsAccum = 0
		local fpsSamples = 0
		local displayEt = 0
		local DISPLAY_INTERVAL = 0.25

		placeLog.write("PlaceVersion", game.PlaceVersion)

		RunService:BindToRenderStep("DebugFPS", Enum.RenderPriority.Camera.Value + 1, function(dt)
			fpsAccum += 1 / dt
			fpsSamples += 1
			displayEt += dt
			if displayEt < DISPLAY_INTERVAL then
				return
			end

			placeLog.writeNumber("FPS", fpsAccum / fpsSamples, nil, 0)
			placeLog.write("Time Played", TimeUtil.toMS(os.clock() - startTime))
			fpsAccum = 0
			fpsSamples = 0
			displayEt = 0
		end)
	end
end

return DebugScreen
