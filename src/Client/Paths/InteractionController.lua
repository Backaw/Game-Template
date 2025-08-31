local InteractionController = {}

local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local UIController = require(Controllers.UI.UIController)
local UIUtil = require(Controllers.UI.Utils.UIUtil)

function InteractionController.start()
	-- Disable interactions for certain ui states
	UIController.getStateMachine():RegisterGlobalCallback(function(_, toState)
		if UIUtil.isStateInteractionPermissive(toState) then
			ProximityPromptService.Enabled = true
		else
			ProximityPromptService.Enabled = false
		end
	end)
end

return InteractionController
