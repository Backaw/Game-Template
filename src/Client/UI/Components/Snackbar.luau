--!strict
local Snackbar = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
local Toggle = require(ReplicatedStorage.Shared.Toggle)
local Signal = require(ReplicatedStorage.Shared.Signal)

local HEIGHT = 0.15
local BUMP_LENGTH = 0.5
local PADDING = 0.025
local LIFETIME = 5
local FADE_OUT_TWEEN_INFO = TweenInfo.new(LIFETIME * 0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, LIFETIME * 0.75)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local screen = Players.LocalPlayer.PlayerGui.Snackbars
local container = screen.Container
local constructor = TemplateUtil.constructor(container.TEMP_SNACKBAR)

local delayEnded = Signal.new()
local isDelayed = Toggle.new(false)

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function move(item: GuiObject, position: UDim2)
	item:TweenPosition(position, Enum.EasingDirection.Out, Enum.EasingStyle.Quart, BUMP_LENGTH, true)
end

local function createSnackbar(message: string, color: Color3, ignoreDelay: true?)
	if not ignoreDelay and isDelayed:Get() then
		delayEnded:Once(function()
			createSnackbar(message, color)
		end)
		return
	end

	-- Bump Others
	for _, otherSnackbar in pairs(container:GetChildren()) do
		-- RETURN: Not another createSnackbar
		if not otherSnackbar:IsA("GuiObject") or not otherSnackbar.Visible then
			continue
		end

		local order = otherSnackbar.LayoutOrder + 1
		move(otherSnackbar, UDim2.fromScale(0.5, 1 - order * (HEIGHT + PADDING)))
		otherSnackbar.LayoutOrder = order
	end

	local label = constructor()
	label.Position = UDim2.fromScale(0.5, 1)
	label.Size = UDim2.fromScale(0, 0)
	label.Name = message
	label.Text = message
	label.TextColor3 = color
	label.LayoutOrder = 0
	label.Visible = true
	label.Parent = container

	local popIn = TweenService:Create(
		label,
		TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ Size = UDim2.fromScale(1, HEIGHT) }
	)

	popIn.Completed:Connect(function()
		TweenUtil.batch({
			TweenService:Create(label, FADE_OUT_TWEEN_INFO, { TextTransparency = 1 }),
			TweenService:Create(label.UIStroke, FADE_OUT_TWEEN_INFO, { Transparency = 1 }),
		}):andThen(function()
			label:Destroy()
		end)
	end)

	popIn:Play()
end

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
function Snackbar.toggleDelay(scope: string, toggle: boolean)
	isDelayed:Set(scope, toggle)
end

function Snackbar.info(message: string, ignoreDelay: true?)
	createSnackbar(message, Color3.fromRGB(255, 255, 255), ignoreDelay)
end

function Snackbar.error(message: string, ignoreDelay: true?)
	createSnackbar(message, Color3.fromRGB(255, 34, 0), ignoreDelay)
end

function Snackbar.notification(message: string, ignoreDelay: true?)
	createSnackbar(message, Color3.fromRGB(43, 135, 255), ignoreDelay)
end

function Snackbar.reward(message: string, ignoreDelay: true?)
	createSnackbar(message, Color3.fromRGB(255, 209, 43), ignoreDelay)
end

function Snackbar.warning(message: string, ignoreDelay: true?)
	createSnackbar(message, Color3.fromRGB(255, 128, 43), ignoreDelay)
end

function Snackbar.clear()
	for _, snackbar: TextLabel in container:GetChildren() do
		if snackbar:IsA("TextLabel") then
			snackbar.Visible = false
		end
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

screen.Enabled = true

isDelayed.Changed:Connect(function(toggle)
	if not toggle then
		delayEnded:Fire()
	end
end)

return Snackbar
