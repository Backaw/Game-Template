--!strict
local UIUtil = {}

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)

local GUI_INSET_Y = GuiService:GetGuiInset().Y

export type Input = Enum.UserInputType | Enum.KeyCode | nil

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function UIUtil.isStateInteractionPermissive(state: UIConstants.State)
	return table.find(UIConstants.InteractionPermissiveStates, state) ~= nil
end

function UIUtil.isStateHUDPermissive(state: UIConstants.State)
	return (UIUtil.isState(state, UIConstants.States.HUD) or table.find(UIConstants.HUDPermissiveStates, state) ~= nil)
end

-- Checks if a state is the state itself or a psuedoState
function UIUtil.isState(potentially: UIConstants.State, thisState: UIConstants.State)
	return potentially == thisState
		or (UIConstants.PsuedoStates[thisState] and table.find(UIConstants.PsuedoStates[thisState], potentially))
end

function UIUtil.isStackHUDPermissive(stack: { UIConstants.State })
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
	if not parent or not parent:IsA("GuiObject") then
		error("Parent not found")
	end

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
