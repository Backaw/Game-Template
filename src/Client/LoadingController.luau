--!strict
local LoadingController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)
local DeferredPromise = require(ReplicatedStorage.Shared.DeferredPromise)
local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local TweenUtil = require(ReplicatedStorage.Shared.Utils.TweenUtil)
local DebugUtil = require(ReplicatedStorage.Shared.Utils.DebugUtil)

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local EASE = 0.1
local FULL = 1 + EASE
local FULL_LOAD_LENGTH = 1

local LOGO_ROTATION_BOUNDS = 2

local DEBUG = DebugUtil.isDebugging(false)
local DEBUG_FLAGS = DebugUtil.isDebuggingFlags({
	PrintInitiatedTasks = false,
	PrintGUI = true,
	PrintCompletedTasks = false,
}, DEBUG)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local tasks: { () -> () } = {}
local taskIds: { string } = {}

local player = Players.LocalPlayer

local playerGui = player.PlayerGui
local screen = playerGui:WaitForChild("LoadingScreen") :: typeof(game:GetService("ReplicatedFirst").LoadingScreen)
local container = screen.Container
local logo = container.Logo
local logoGradient = container.Logo.Colored.UIGradient

local tween: Tween

-------------------------------------------------------------------------------
-- PUBLIC MEMEBERS
-------------------------------------------------------------------------------

LoadingController.Loaded = DeferredPromise.new(nil, "Parallel")

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
			if DEBUG_FLAGS.PrintInitiatedTasks then
				print(("Loading %s at %s"):format(taskIds[i], i))
			end

			task()

			if DEBUG_FLAGS.PrintCompletedTasks then
				print(("Loaded %s"):format(taskIds[i]))
			end

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
						LoadingController.Loaded.invokeResolve()
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
	local interfaces = ReplicatedStorage:WaitForChild(UIConstants.InterfacesName)

	LoadingController.addTask("Waiting for GUI", function()
		local loaded
		while not loaded do
			loaded = true

			for _, screenGui in interfaces:GetChildren() do
				if screenGui.Name == "Cmdr" then
					continue
				end

				local playerCounterpart = playerGui:FindFirstChild(screenGui.Name)
				if not playerCounterpart then
					if DEBUG_FLAGS.PrintGUI then
						print("Missing ScreenGui: " .. screenGui.Name)
					end

					loaded = false
					break
				end

				--[[
				if #screenGui:GetDescendants() > #playerCounterpart:GetDescendants() then
					if DEBUG_FLAGS.PrintGUI then
						print("ScreenGui has less descendants than expected: " .. screenGui.Name)
					end

					loaded = false
					break
				end
				]]
			end

			task.wait(0.2)
		end
	end)
end

return LoadingController
