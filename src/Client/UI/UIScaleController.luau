--!strict
local UIScaleController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local DescendantLooper = require(ReplicatedStorage.Shared.DescendantLooper)
local Limiter = require(ReplicatedStorage.Shared.Limiter)
local Signal = require(ReplicatedStorage.Shared.Signal)
local ComponentUtil = require(ReplicatedStorage.Client.UI.Utils.ComponentUtil)
local InstanceUtil = require(ReplicatedStorage.Shared.Utils.InstanceUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local BASE_RESOLUTION = Vector2.new(1920, 1080)

local LIMITER_SCOPE = script.Name
local UPDATE_COOLDOWN = 0.3

local SCALE_MULT = 1
local SCALE_MAX = 1.1

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local playerGui = ComponentUtil.getPlayerGui()

local camera = Workspace.Camera
local scale: number = 1

local initialized = false
local registeredInitProps: { [Instance]: { [string]: any } } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

UIScaleController.IGNORE_TAG = "IgnoredUIScale"
UIScaleController.MULTIPLIER_ATTRIBUTE = "Multiplier"
UIScaleController.ScaleChanged = Signal.new() :: Signal.Signal<number>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function canScale(instance: Instance)
	return not instance:HasTag(UIScaleController.IGNORE_TAG)
end

local function scaleInstance(instance: Instance)
	local initProps = registeredInitProps[instance]

	if instance:IsA("UIScale") then
		local initParentSize = initProps.ParentSize
		local multiplier = instance:GetAttribute(UIScaleController.MULTIPLIER_ATTRIBUTE)
		if typeof(multiplier) ~= "number" then
			multiplier = 1
		end

		local parent = instance.Parent :: GuiObject
		if parent then
			local size =
				UDim2.new(initParentSize.X.Scale / scale, initParentSize.X.Offset, initParentSize.Y.Scale / scale, initParentSize.Y.Offset)
			parent.Size = size

			parent:SetAttribute(InstanceUtil.CommonAttributes.InitSize, size)
		end

		instance.Scale = initProps.Scale * scale * multiplier
	end
end

local function registerInstance(instance: Instance)
	local initProps

	if not canScale(instance) then
		return
	end

	local parent = instance.Parent :: GuiObject
	if not parent then
		return
	end

	if instance:IsA("UICorner") then
		initProps = { CornerRadius = instance.CornerRadius }
	elseif instance:IsA("UIScale") and not UIScaleController.isObjectScaled(parent) then
		if parent:IsA("GuiObject") then
			initProps = {
				ParentSize = (parent :: GuiObject).Size,
				Scale = instance.Scale,
			}
		end
	end

	if initProps then
		registeredInitProps[instance] = initProps :: any
		scaleInstance(instance)
	end
end

local function updateScale()
	local ratio = camera.ViewportSize / BASE_RESOLUTION
	local newScale = if math.abs(1 - ratio.X) > math.abs(1 - ratio.Y) then ratio.X else ratio.Y
	newScale = math.min(newScale * SCALE_MULT, SCALE_MAX * SCALE_MULT)
	if scale ~= newScale then
		scale = newScale
		for instance in registeredInitProps do
			scaleInstance(instance)
		end
		UIScaleController.ScaleChanged:Fire(scale)
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function UIScaleController.isObjectCustomScaled(object: GuiObject)
	if not object:IsDescendantOf(playerGui) then
		return false
	end

	local parent = object.Parent
	while parent and parent ~= playerGui do
		local scaleChild = parent:FindFirstChildOfClass("UIScale")
		if scaleChild and canScale(scaleChild) then
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
	if not object:IsDescendantOf(playerGui) then
		return false
	end

	local parent = object.Parent
	while parent and parent ~= playerGui do
		local scaleChild = parent:FindFirstChildOfClass("UIScale")
		if scaleChild and canScale(scaleChild) then
			return true
		end

		parent = parent.Parent
		task.wait()
	end

	return false
end

function UIScaleController.getScale()
	return if initialized then scale else 1
end

function UIScaleController.setMultiplier(instance: UIScale, multiplier: number)
	instance:SetAttribute(UIScaleController.MULTIPLIER_ATTRIBUTE, multiplier)
	if registeredInitProps[instance] then
		scaleInstance(instance)
	end
end

function UIScaleController.onScaleChanged(callback: (number) -> ())
	callback(UIScaleController.getScale())
	return UIScaleController.ScaleChanged:Connect(callback)
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
	for _, screenGui in playerGui:GetChildren() do
		if screenGui:IsA("ScreenGui") then
			table.insert(screenGuis, screenGui)
		end
	end

	DescendantLooper.new(
		screenGuis,
		function(descendant)
			registerInstance(descendant)
		end,
		nil,
		function()
			initialized = true
		end
	)

	playerGui.DescendantRemoving:Connect(function(descendant)
		registeredInitProps[descendant] = nil
	end)
end

return UIScaleController
