local GameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConstants = require(ReplicatedStorage.Shared.Game.GameConstants)

local PLACE_ID = game.PlaceId

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function GameUtil.isLive()
	return PLACE_ID == GameConstants.Places.Live
end

function GameUtil.isQA()
	return PLACE_ID == GameConstants.Places.QA
end

function GameUtil.isDev()
	return not (GameUtil.isLive() or GameUtil.isQA())
end

return GameUtil
