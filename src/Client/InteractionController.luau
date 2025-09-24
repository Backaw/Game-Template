--!strict
local InteractionController = {}

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = require(ReplicatedStorage.Client.UI.UIController)
local UIUtil = require(ReplicatedStorage.Client.UI.Utils.UIUtil)

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
