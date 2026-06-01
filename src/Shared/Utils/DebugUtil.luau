--!strict
local DebugUtil = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local TemplateUtil = require(ReplicatedStorage.Shared.Utils.TemplateUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local DEBUG_LOW_FPS = false
local TARGET_LOW_FPS = 20

local IS_CLIENT = RunService:IsClient()
local IS_DEV = GameUtil.isDev()

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local keyBinds: { [Enum.KeyCode]: true } = {}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

function DebugUtil.canDebug()
	return IS_DEV
end

function DebugUtil.isDebugging(toggle: boolean, secondaryFactor: boolean?)
	return DebugUtil.canDebug() and (toggle and (if secondaryFactor ~= nil then secondaryFactor else true))
end

function DebugUtil.isDebuggingFlags<T>(flags: T, secondaryFactor: boolean?): { [keyof<T>]: boolean }
	for flag, value in flags :: { [string]: boolean } do
		(flags :: { [string]: boolean })[flag] = DebugUtil.isDebugging(value, secondaryFactor)
	end

	return flags
end

function DebugUtil.canThrowDebugErrors()
	return not GameUtil.isLive()
end

function DebugUtil.previewCFrame(cframe: CFrame, size: Vector3?, color: Color3?, shape: Enum.PartType?)
	local preview = Instance.new("Part")
	preview.Size = size or Vector3.one
	preview.CFrame = cframe
	preview.Color = color or Color3.fromRGB(0, 0, 0)
	preview.Anchored = true
	preview.CanTouch = false
	preview.CanQuery = false
	preview.Shape = shape or Enum.PartType.Wedge
	preview.CanCollide = false
	preview.Parent = Workspace

	return preview
end

function DebugUtil.pointerGizmo(parent: BasePart, color: Color3?, length: number?)
	local gizmo = Instance.new("LineHandleAdornment") -- Points in direction of velocity
	gizmo.Adornee = parent
	gizmo.AlwaysOnTop = true
	gizmo.Color3 = color or Color3.fromRGB(0, 180, 255)
	gizmo.Parent = parent
	gizmo.Thickness = 3
	gizmo.Length = length or 5
	gizmo.Visible = true

	return gizmo
end

function DebugUtil.debris(instance: Instance, time: number)
	Debris:AddItem(instance, time)
end

function DebugUtil.truncateVector3(vector: Vector3, precision: number)
	return Vector3.new(
		MathUtil.precision(vector.X, precision),
		MathUtil.precision(vector.Y, precision),
		MathUtil.precision(vector.Z, precision)
	)
end

function DebugUtil.writeVector(vector: Vector3 | Vector2, precision: number?)
	local p = precision or 3
	if typeof(vector) == "Vector2" then
		local formatStr = string.format("(%%.%df, %%.%df)", p, p)
		return (formatStr :: any):format(vector.X, vector.Y)
	else
		local formatStr = string.format("(%%.%df, %%.%df, %%.%df)", p, p, p)
		return (formatStr :: any):format(vector.X, vector.Y, vector.Z)
	end
end

function DebugUtil.writeNumber(value: number, precision: number?)
	local formatString = `%.{precision or 3}f`
	return (formatString :: any):format(value)
end

function DebugUtil.stateDisplay(constructor: TemplateUtil.Constructor<TextLabel>, parent: Instance, disabled: boolean?)
	local display = {} :: StateDisplay

	function display.write(label, value, highlight)
		if disabled then
			return
		end

		local textLabel = parent:FindFirstChild(label) :: TextLabel?
		if not textLabel then
			textLabel = constructor()
			textLabel.Parent = parent
			textLabel.Name = label

			if highlight then
				textLabel.TextColor3 = highlight
				local uiStroke = textLabel:FindFirstChildOfClass("UIStroke") :: UIStroke?
				if uiStroke then
					uiStroke.Color = Color3.new()
				end
			end
		end

		assert(textLabel, "TextLabel not created")
		if value == nil then
			textLabel.Visible = false
		else
			textLabel.Visible = true
			textLabel.Text = ("%s: %s"):format(label, tostring(value))
		end
	end

	function display.writeNumber(label, value, highlight, precision: number?)
		display.write(label, if value then DebugUtil.writeNumber(value, precision) else nil, highlight)
	end

	function display.writeVector(label, value, highlight)
		display.write(label, if value then DebugUtil.writeVector(value, 2) else nil, highlight)
	end

	if parent:IsA("GuiObject") then
		parent.Visible = disabled == nil or not disabled
	end

	return display
end

function DebugUtil.onKeyDown(key: Enum.KeyCode, callback: () -> ())
	if keyBinds[key] then
		warn("Key already bound: ", key, debug.traceback())
		return
	end

	keyBinds[key] = true

	if not GameUtil.isLive() then
		UserInputService.InputBegan:Connect(function(input, gameProcessed)
			if gameProcessed then
				return
			end

			if input.KeyCode == key then
				callback()
			end
		end)
	end
end

function DebugUtil.getLocalDebugScreen(enabled: boolean, title: string?)
	enabled = DebugUtil.isDebugging(enabled)

	if enabled and IS_CLIENT then
		return (require(ReplicatedStorage.Client.UI.Screens.DebugScreen) :: any).newLog(nil, title) :: StateDisplay
	else
		local emptyFunction = function() end
		return {
			write = emptyFunction,
			writeNumber = emptyFunction,
			writeVector = emptyFunction,
		}
	end
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

if DebugUtil.canDebug() and IS_CLIENT and DEBUG_LOW_FPS then
	task.spawn(function()
		local nothing = function() end
		while true do
			RunService.RenderStepped:Wait()
			local t0 = tick()
			RunService.Heartbeat:Wait()
			repeat
				nothing()
			until t0 + 1 / TARGET_LOW_FPS < tick()
		end
	end)
end

-------------------------------------------------------------------------------
-- EXPORT TYPES
-------------------------------------------------------------------------------

export type StateDisplay = {
	write: (label: string, value: any, highlight: Color3?) -> (),
	writeNumber: (label: string, value: number?, highlight: Color3?, precision: number?) -> (),
	writeVector: (label: string, value: Vector3 | Vector2 | nil, highlight: Color3?) -> (),
}

return DebugUtil
