local LoadingController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local DeferredPromise = require(ReplicatedStorage.Modules.DeferredPromise)
local MathUtil = require(ReplicatedStorage.Modules.Utils.MathUtil)
local TweenUtil = require(ReplicatedStorage.Modules.Utils.TweenUtil)
local DebugUtil = require(ReplicatedStorage.Modules.Utils.DebugUtil)

local EASE = 0.1
local FULL = 1 + EASE
local FULL_LOAD_LENGTH = 1

local LOGO_ROTATION_BOUNDS = 2

local DEBUG = DebugUtil.isDebugging(false)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local tasks: { () -> () } = {}
local taskIds: { string } = {}

local player = Players.LocalPlayer
local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

local playerGui = player.PlayerGui
local screen: ScreenGui = playerGui:WaitForChild("LoadingScreen")
local container: Frame = screen.Container
local logo: ImageLabel = container.Logo
local logoGradient: UIGradient = container.Logo.Colored.UIGradient

local tween: Tween

-------------------------------------------------------------------------------
-- PUBLIC MEMEBERS
-------------------------------------------------------------------------------
LoadingController.Loaded = DeferredPromise.new()

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function LoadingController.addTask(taskId: string, task: () -> ())
	table.insert(tasks, task)
	table.insert(taskIds, taskId)
end

function LoadingController.start()
	-- Open screen
	TweenService:Create(logo.UIScale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	logo.Rotation = MathUtil.nextSign() * LOGO_ROTATION_BOUNDS
	TweenService
		:Create(logo, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), { Rotation = -1 * logo.Rotation })
		:Play()

	task.spawn(function()
		local taskCount = #tasks
		local offsetIncrementPerTask = FULL / taskCount

		logoGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(EASE, 1),
			NumberSequenceKeypoint.new(1, 1),
		})
		logoGradient.Offset = Vector2.new(0, EASE)

		for i, task in tasks do
			if DEBUG then
				print(("Loading %s at %s"):format(taskIds[i], i))
			end

			task()

			if tween then
				tween:Cancel()
			end

			local progress = offsetIncrementPerTask * i
			tween = TweenService:Create(
				logoGradient,
				TweenInfo.new(((progress - logoGradient.Offset.Y) / FULL) * FULL_LOAD_LENGTH, Enum.EasingStyle.Linear),
				{ Offset = Vector2.new(0, -progress) }
			)
			tween.Completed:Connect(function()
				-- Close screen
				if i == taskCount then
					controls:Enable()

					TweenUtil.batch({
						TweenService:Create(
							container,
							TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
							{ BackgroundTransparency = 1, BackgroundColor3 = Color3.new(0, 0, 0) }
						),
						--[[ TweenService:Create(
							container.Overlay,
							TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{ BackgroundTransparency = 1 }
						), *]]
						TweenService:Create(
							container.StudioLogo.Logo,
							TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
							{ ImageTransparency = 1 }
						),
						TweenService:Create(
							logo.UIScale,
							TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
							{ Scale = 0 }
						),
					}):andThen(function()
						screen:Destroy()
						LoadingController.Loaded:invokeResolve()
					end)
				end
			end)

			tween:Play()
		end
	end)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- Let all UI load
do
	LoadingController.addTask("Waiting for GUI", function()
		local loaded
		while not loaded do
			loaded = true

			for _, screenGui in StarterGui:GetChildren() do
				if screenGui.Name == "Cmdr" then
					continue
				end

				local playerCounterpart = playerGui:FindFirstChild(screenGui.Name)
				if not playerCounterpart then
					loaded = false
					break
				end

				if #screenGui:GetDescendants() < #playerCounterpart:GetDescendants() then
					loaded = false
					break
				end
			end

			task.wait(0.2)
		end
	end)
end

controls:Disable()

return LoadingController
