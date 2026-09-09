--!strict
local ComponentUtil = {}

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local TemplateUtil = require(Shared.Utils.TemplateUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui") or StarterGui

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ComponentUtil.getPlayerGui()
	return playerGui :: typeof(StarterGui)
end

function ComponentUtil.isMountedToStory()
	return RunService:IsStudio() and not RunService:IsRunning()
end

function ComponentUtil.getTemplateConstructor<T>(template: T, templateStorageAction: TemplateUtil.TemplateStorageAction?)
	local action: TemplateUtil.TemplateStorageAction? = if ComponentUtil.isMountedToStory()
		then TemplateUtil.TemplateStorageAction.Ignore
		else templateStorageAction

	return TemplateUtil.constructor(template, action)
end

return ComponentUtil
