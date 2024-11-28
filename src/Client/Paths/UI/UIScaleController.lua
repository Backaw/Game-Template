local UIScaleController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local DescendantLooper = require(ReplicatedStorage.Modules.DescendantLooper)
local Limiter = require(ReplicatedStorage.Modules.Limiter)
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

local BASE_RESOLUTION = Vector2.new(1920, 1080)

local LIMITER_SCOPE = script.Name
local UPDATE_COOLDOWN = 0.3

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local playerGui = Players.LocalPlayer.PlayerGui

local camera = Workspace.Camera
local scale: number = 1

local registeredInitProps: { [Instance]: { [string]: any } } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
UIScaleController.IGNORE_ATTRIBUTE = "DoNotScale"

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function scaleInstance(instance: Instance)
	local initProps = registeredInitProps[instance]

	if instance:IsA("UIScale") then
		local initParentSize = initProps.ParentSize
		instance.Parent.Size =
			UDim2.new(initParentSize.X.Scale / scale, initParentSize.X.Offset, initParentSize.Y.Scale / scale, initParentSize.Y.Offset)

		instance.Scale = initProps.Scale * scale
	end
end

local function registerInstance(instance: Instance)
	local initProps

	if instance:GetAttribute(UIScaleController.IGNORE_ATTRIBUTE) then
		return
	end

	if instance:IsA("UICorner") then
		initProps = { CornerRadius = instance.CornerRadius }
	elseif instance:IsA("UIScale") and not UIScaleController.isObjectScaled(instance.Parent) then
		local parent: GuiObject = instance.Parent
		if parent:IsA("GuiObject") then
			initProps = {
				ParentSize = parent.Size,
				Scale = instance.Scale,
			}
		end
	end

	if initProps then
		registeredInitProps[instance] = initProps
		scaleInstance(instance)
	end
end

local function updateScale()
	local ratio = camera.ViewportSize / BASE_RESOLUTION
	local newScale = if math.abs(1 - ratio.X) > math.abs(1 - ratio.Y) then ratio.X else ratio.Y

	if scale ~= newScale then
		scale = newScale

		for instance in registeredInitProps do
			scaleInstance(instance)
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function UIScaleController.isObjectCustomScaled(object: GuiObject)
	if not object:IsDescendantOf(Paths.UI) then
		return false
	end

	local parent = object.Parent
	while parent ~= playerGui do
		local scaleChild = parent:FindFirstChildOfClass("UIScale")
		if scaleChild and not scaleChild:GetAttribute(UIScaleController.IGNORE_ATTRIBUTE) then
			return true
		elseif parent:IsA("GuiObject") then
			local size = parent.Size
			if not (size.X.Scale == 0 and size.Y.Scale == 0) then
				return false
			end
		end

		parent = parent.Parent
		task.wait()
	end

	return false
end

function UIScaleController.isObjectScaled(object: GuiObject)
	if not object:IsDescendantOf(Paths.UI) then
		return false
	end

	local parent = object.Parent
	while parent and parent ~= playerGui do
		local scaleChild = parent:FindFirstChildOfClass("UIScale")
		if scaleChild and not scaleChild:GetAttribute(UIScaleController.IGNORE_ATTRIBUTE) then
			return true
		end

		parent = parent.Parent
		task.wait()
	end

	return false
end

function UIScaleController.getScale()
	return scale
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
function UIScaleController.init()
	updateScale()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		Limiter.indecisive(LIMITER_SCOPE, "UpdateScale", UPDATE_COOLDOWN, updateScale)
	end)

	local screenGuis = {}
	for _, screenGui in  (StarterGui:GetChildren()) do
		if screenGui:IsA("ScreenGui") then
			table.insert(screenGuis, Paths.UI:WaitForChild(screenGui.Name))
		end
	end

	DescendantLooper.new(screenGuis, function(descendant)
		registerInstance(descendant)
	end)

	Paths.UI.DescendantRemoving:Connect(function(descendant)
		registeredInitProps[descendant] = nil
	end)
end

return UIScaleController
