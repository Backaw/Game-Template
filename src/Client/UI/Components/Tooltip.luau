--!strict
local Tooltip = {}

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Maid)
local UIController = require(ReplicatedStorage.Client.UI.UIController)
local Button = require(ReplicatedStorage.Client.UI.Components.Button)
local InputUtil = require(ReplicatedStorage.Client.Utils.InputUtil)

local OFFSET = 30
local GUI_INSET_Y = GuiService:GetGuiInset().Y

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local screen: ScreenGui = Players.LocalPlayer.PlayerGui.Tooltips

local maid = Maid.new()
local opened: Button.Button?

local uiStateMachine = UIController.getStateMachine()

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function resolveOffsetAndAnchor(pos: Vector2, offset: Vector2): (Vector2, Vector2)
	local screenSize = screen.AbsoluteSize
	local fx, fy = offset.X, offset.Y
	local ax = if fx == 1 then 0 else fx
	local ay = if fy == 1 then 0 else fy

	if fx == 1 and pos.X > screenSize.X / 2 then
		fx = 0
		ax = 1
	end

	if fy == 1 and pos.Y > screenSize.Y / 2 then
		fy = 0
		ay = 1
	end

	return Vector2.new(fx, fy), Vector2.new(ax, ay)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function Tooltip.bindToButton(
	tooltip: GuiObject,
	offset: Vector2,
	locked: boolean,
	button: Button.Button<any>,
	onRendered: (Vector2?) -> (),
	uiStateDependent: true?,
	canShow: (() -> boolean)?
)
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
		if canShow and not canShow() then
			return
		end

		maid:Cleanup()
		opened = button
		tooltip.Visible = true

		if InputUtil.isGamepadInput() or locked then
			local guiObject = button:GetGui()
			task.defer(function()
				local absoluteSize = guiObject.AbsoluteSize
				local absolutePosition = guiObject.AbsolutePosition
				local finalOffset, anchor = resolveOffsetAndAnchor(absolutePosition, offset)
				onRendered(anchor)
				tooltip.AnchorPoint = anchor
				tooltip.Position = UDim2.fromOffset(
					absolutePosition.X + absoluteSize.X * finalOffset.X,
					absolutePosition.Y + absoluteSize.Y * finalOffset.Y + GUI_INSET_Y
				)
			end)
		else
			onRendered()
			maid:Add(RunService.RenderStepped:Connect(function()
				local mouseLocation = UserInputService:GetMouseLocation()
				local finalOffset, anchor = resolveOffsetAndAnchor(mouseLocation, offset)
				tooltip.AnchorPoint = anchor
				tooltip.Position = UDim2.fromOffset(mouseLocation.X + OFFSET * finalOffset.X, mouseLocation.Y + OFFSET * finalOffset.Y)
			end))
		end

		if uiStateDependent then
			maid:Add(uiStateMachine:RegisterGlobalCallback(close))
		end
	end)

	button.HoverEnded:Connect(function(disabling)
		if not disabling then -- Always keep tooltip open regardless of toggle
			close()
		end
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
