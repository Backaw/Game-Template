--!strict
local Tooltip = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Button = require(ReplicatedStorage.Client.UI.Components.Button)
local Maid = require(ReplicatedStorage.Shared.Maid)
local UIController = require(ReplicatedStorage.Client.UI.UIController)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)

local OFFSET = 20
local GUI_INSET_Y = GuiService:GetGuiInset().Y

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local screen: ScreenGui = Players.LocalPlayer.PlayerGui.Tooltips

local maid = Maid.new()
local opened: Button.Button?

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function Tooltip.bindToButton(tooltip: GuiObject, button: Button.Button, onRendered: () -> (), uiStateDependent: true?)
	local function close()
		-- RETURN: New tooltip has opened
		if opened ~= button then
			return
		end

		maid:Cleanup()
		tooltip.Visible = false

		opened = nil
	end

	-- TODO: Add some sort of limiter
	button.HoverStarted:Connect(function()
		maid:Cleanup()
		opened = button

		onRendered()
		tooltip.Visible = true

		if InputUtil.isGamepadInput() then
			local guiObject = button:GetGuiObject()
			task.defer(function()
				local selectionLocation = guiObject.AbsolutePosition + guiObject.AbsoluteSize / 2
				tooltip.Position = UDim2.fromOffset(selectionLocation.X, selectionLocation.Y + GUI_INSET_Y)
			end)
		else
			-- 0.02 * screen.AbsoluteSize.Y
			maid:Add(RunService.RenderStepped:Connect(function()
				local mouseLocation = UserInputService:GetMouseLocation()
				tooltip.Position = UDim2.fromOffset(mouseLocation.X + OFFSET, mouseLocation.Y + OFFSET)
			end))
		end

		if uiStateDependent then
			maid:Add(uiStateMachine:RegisterGlobalCallback(close))
		end
	end)

	button.HoverEnded:Connect(function()
		close()
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	screen.Enabled = true

	for _, tooltip in pairs(screen:GetChildren()) do
		if tooltip:IsA("GuiObject") then
			tooltip.AnchorPoint = Vector2.new(0, 0)
			tooltip.Visible = false
		end
	end
end

return Tooltip
