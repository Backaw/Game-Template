--!strict
local InteractionUtil = {}

local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local MAX_PROMPTS_VISIBLE = 1
local MAX_ACTIVATION_DISTANCE = 20

type ProximityPromptDict = { [ProximityPrompt]: true? }
type InteractionHandler = (instance: PVInstance, proximityPrompt: ProximityPrompt) -> ()

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local interactions: { [string]: { Handler: InteractionHandler, ObjectText: string?, ActionText: string? } } = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function getAttachedInteraction(instance: PVInstance): string?
	for _, tag in (CollectionService:GetTags(instance)) do
		if interactions[tag] then
			return tag
		end
	end

	return nil
end

local function removePrompt(instance: Instance)
	local proximityPrompt = instance:FindFirstChildOfClass("ProximityPrompt")
	if proximityPrompt then
		proximityPrompt:Destroy()
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function InteractionUtil.attachPrompt(
	instance: Instance,
	objectText: string?,
	actionText: string?,
	overideExisting: boolean?
): ProximityPrompt?
	assert(instance:IsA("PVInstance"), "Instance must be a PVInstance")

	local proximityPrompt = instance:FindFirstChildOfClass("ProximityPrompt")
	if proximityPrompt and not overideExisting then
		return nil
	else
		proximityPrompt = Instance.new("ProximityPrompt")
		proximityPrompt.MaxActivationDistance = MAX_ACTIVATION_DISTANCE
		proximityPrompt.RequiresLineOfSight = false
		proximityPrompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
		proximityPrompt.Parent = instance
	end

	proximityPrompt.ActionText = actionText or ""
	proximityPrompt.ObjectText = objectText or ""

	return proximityPrompt
end

function InteractionUtil.logInteraction(name: string, handler: InteractionHandler, actionText: string?, objectText: string?)
	-- ERROR: Interaction has already been registered
	if interactions[name] then
		error(("Interaction %s has already been registered"):format(name))
	end

	interactions[name] = {
		Handler = handler,
		ObjectText = objectText,
		ActionText = actionText,
	}

	-- Adding
	for _, instance in (CollectionService:GetTagged(name)) do
		InteractionUtil.attachPrompt(instance, objectText, actionText)
	end
	CollectionService:GetInstanceAddedSignal(name):Connect(function(instance)
		InteractionUtil.attachPrompt(instance, objectText, objectText)
	end)

	-- Removing
	CollectionService:GetInstanceRemovedSignal(name):Connect(function(instance)
		removePrompt(instance)
	end)
end

function InteractionUtil.detachInteraction(instance: PVInstance)
	local tag = getAttachedInteraction(instance)
	if tag then
		CollectionService:RemoveTag(instance, tag)
		removePrompt(instance)
	end
end

function InteractionUtil.getAllPromptsFromInteraction(name: string)
	-- ERROR: Interaction hasn't been registered
	if not interactions[name] then
		error(("Attempt to get proximity prompts of an unregistered interaction: %s"):format(name))
	end

	local proximityPrompts = {}
	for _, instance in (CollectionService:GetTagged(name)) do
		table.insert(proximityPrompts, instance:FindFirstChildOfClass("ProximityPrompt"))
	end

	return proximityPrompts
end

function InteractionUtil.isEnabled(): boolean
	return ProximityPromptService.Enabled
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

ProximityPromptService.PromptTriggered:Connect(function(proximityPrompt)
	local instance = proximityPrompt.Parent :: PVInstance
	local tag = getAttachedInteraction(instance)
	if tag then
		local interaction = interactions[tag]
		if interaction then
			interaction.Handler(instance, proximityPrompt)
		end
	end
end)
ProximityPromptService.MaxPromptsVisible = MAX_PROMPTS_VISIBLE

return InteractionUtil
