local UIUtil = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Controllers = Players.LocalPlayer.PlayerScripts.Paths
local UIConstants = require(Controllers.UI.UIConstants)
local UIController = require(Controllers.UI.UIController)

local GUI_INSET_Y = GuiService:GetGuiInset().Y

export type Input = Enum.UserInputType | Enum.KeyCode | nil

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function UIUtil.isStateInteractionPermissive(state: string)
	return table.find(UIConstants.InteractionPermissiveStates, state) ~= nil
end

function UIUtil.isStateHUDPermissive(state: string)
	return (UIUtil.isState(state, UIConstants.States.HUD) or table.find(UIConstants.HUDPermissiveStates, state) ~= nil)
end

-- Checks if a state is the state itself or a psuedoState
function UIUtil.isState(potentially: string, thisState: string)
	return potentially == thisState
		or (UIConstants.PsuedoStates[thisState] and table.find(UIConstants.PsuedoStates[thisState], potentially))
end

function UIUtil.isStackHUDPermissive()
	local stack = uiStateMachine:GetStack()
	-- Every state between HUD and new state should permit HUD inorder to show HUD
	local hudIndex = table.find(stack, UIConstants.States.HUD)
	if not hudIndex then
		return false
	end

	for i = #stack, hudIndex, -1 do
		if not UIUtil.isStateHUDPermissive(stack[i]) then
			return false
		end
	end

	return true
end

function UIUtil.isMouseWithinObjectBounds(guiObject: GuiObject, size: Vector2?)
	local buttonPosition = guiObject.AbsolutePosition
	local buttonSize = size or guiObject.AbsoluteSize
	local mouseLocation = UserInputService:GetMouseLocation() + Vector2.new(0, -GUI_INSET_Y)

	return mouseLocation.X > buttonPosition.X
		and mouseLocation.X < buttonPosition.X + buttonSize.X
		and mouseLocation.Y > buttonPosition.Y
		and mouseLocation.Y < buttonPosition.Y + buttonSize.Y
end

function UIUtil.mountZIndex(guiObject: GuiObject, ignoreGuiObject: boolean?)
	local parent = guiObject.Parent
	local baseZIndex = if parent then parent.ZIndex else 9

	if not ignoreGuiObject then
		guiObject.ZIndex += baseZIndex
	end

	for _, child in (guiObject:GetChildren()) do
		if child:IsA("GuiObject") then
			child.ZIndex += baseZIndex
		end
	end
end

return UIUtil
