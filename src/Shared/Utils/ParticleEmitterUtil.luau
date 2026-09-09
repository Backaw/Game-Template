--!strict
local ParticleEmitterUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ObjectPool = require(ReplicatedStorage.Shared.ObjectPool)
local ArrayUtil = require(ReplicatedStorage.Shared.Utils.ArrayUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type EmitterContainer = {
	Emit: (EmitterContainer, moveTo: CFrame?, completedCallback: () -> ()?, scale: Scale?) -> (),
	GetParent: (EmitterContainer) -> BasePart | Attachment,
	MountTo: (EmitterContainer, newParent: BasePart | Attachment) -> (),
	MountAttachmentTo: (EmitterContainer, parentsParent: BasePart) -> (),
	Destroy: (EmitterContainer, destroyParent: boolean?) -> (),
	Toggle: (EmitterContainer, toggle: boolean) -> (),
}

export type Script = { [ParticleEmitter]: (number | NumberRange)? }

export type Scale = { Size: number?, Time: number? }

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local sharedContainer: BasePart

local random = Random.new()

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

function ParticleEmitterUtil.getTemplateScript(emitters: { ParticleEmitter }, ignore: { string }?, amountOverides: { [string]: number }?)
	local script: Script = {}

	for _, emitter in pairs(emitters) do
		local name = emitter.Name
		if ignore and table.find(ignore, name) then
			continue
		end

		if amountOverides and amountOverides[name] then
			script[emitter] = amountOverides[name]
			continue
		end

		local emitCount = emitter:GetAttribute("EmitCount") :: number?
		assert(typeof(emitCount) == "number", `EmitCount is not a number: {emitter:GetFullName()}`)

		script[emitter] = emitCount or 0
	end

	return script
end

function ParticleEmitterUtil.getTemplateScriptFromDescendants(
	ancestor: Instance,
	ignore: { string }?,
	amountOverides: { [string]: number }?
)
	return ParticleEmitterUtil.getTemplateScript(
		ancestor:QueryDescendants("ParticleEmitter") :: { ParticleEmitter },
		ignore,
		amountOverides
	)
end

function ParticleEmitterUtil.scaleEmitter(emitter: ParticleEmitter, sizeScale: number?, timeScale: number?)
	if sizeScale then
		local sizeKeypoints = {}
		for _, keypoint in pairs(emitter.Size.Keypoints) do
			table.insert(
				sizeKeypoints,
				NumberSequenceKeypoint.new(keypoint.Time, math.abs(keypoint.Value * sizeScale), math.abs(keypoint.Envelope * sizeScale))
			)
		end

		local squashKeypoints = {}
		for _, keypoint in pairs(emitter.Squash.Keypoints) do
			table.insert(
				squashKeypoints,
				NumberSequenceKeypoint.new(keypoint.Time, math.abs(keypoint.Value * sizeScale), math.abs(keypoint.Envelope * sizeScale))
			)
		end

		emitter.Size = NumberSequence.new(sizeKeypoints)
		emitter.Squash = NumberSequence.new(squashKeypoints)
		local speed = emitter.Speed
		emitter.Speed = NumberRange.new(speed.Min * sizeScale, speed.Max * sizeScale)
	end

	if timeScale then
		local lifetime = emitter.Lifetime
		emitter.Lifetime = NumberRange.new(lifetime.Min / timeScale, lifetime.Max / timeScale)
	end
end

function ParticleEmitterUtil.getEmittersFromTemplateScript(script: Script, scale: Scale?)
	local emitters: Script = {}

	for template, emitCount in script do
		local emitter: ParticleEmitter = template:Clone()
		emitter.Enabled = false

		if scale then
			ParticleEmitterUtil.scaleEmitter(emitter, scale.Size, scale.Time)
		end

		emitters[emitter] = emitCount
	end

	return emitters
end

function ParticleEmitterUtil.emitDescendants(ancestor: Instance, completedCallback: () -> ()?, scale: Scale?)
	local largestLT = 0
	for _, descendant in ancestor:QueryDescendants("ParticleEmitter") do
		if scale then
			ParticleEmitterUtil.scaleEmitter(descendant, scale.Size, scale.Time)
		end

		local emitCount = assert(descendant:GetAttribute("EmitCount") :: number, `EmitCount for {descendant.Name} is not a number`)
		descendant:Emit(emitCount)

		largestLT = math.max(largestLT, descendant.Lifetime.Max)
	end

	if completedCallback then
		task.delay(largestLT * 1.1, function()
			completedCallback()
		end)
	end
end

function ParticleEmitterUtil.toggleDescendants(ancestor: Instance, toggle: boolean)
	for _, descendant in ArrayUtil.add(ancestor:QueryDescendants("ParticleEmitter"), ancestor:QueryDescendants("Beam")) do
		descendant.Enabled = toggle
	end
end

-------------------------------------------------------------------------------
-- COMMENT
-------------------------------------------------------------------------------

function ParticleEmitterUtil.createEmitterContainer(templateScript: Script, existingParent: BasePart | Attachment | nil, scale: Scale?)
	local emitterContainer = {} --  :: EmitterContainer

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------

	local emitters: Script = ParticleEmitterUtil.getEmittersFromTemplateScript(templateScript, scale)
	local parent: BasePart | Attachment

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function emitterContainer:Emit(moveTo: CFrame?, completedCallback: () -> ()?, newScale: Scale?)
		if moveTo then
			if typeof(parent) == "Attachment" then
				parent.WorldCFrame = moveTo
			else
				parent.CFrame = moveTo
			end
		end

		local largestLT = 0
		for emitter, emitCount in emitters do
			if newScale then
				ParticleEmitterUtil.scaleEmitter(emitter, newScale.Size, newScale.Time)
			end

			emitter:Emit(if typeof(emitCount) == "NumberRange" then random:NextInteger(emitCount.Min, emitCount.Max) else emitCount)
			largestLT = math.max(largestLT, emitter.Lifetime.Max)
		end

		if completedCallback then
			task.delay(largestLT * 1.1, function()
				completedCallback()
			end)
		end
	end

	function emitterContainer:GetParent()
		return parent
	end

	function emitterContainer:MountTo(newParent: BasePart | Attachment)
		parent = newParent

		for emitter in emitters do
			emitter.Parent = parent
		end
	end

	function emitterContainer:MountAttachmentTo(parentsParent: BasePart)
		assert(typeof(parent) == "Attachment" and parent.Parent == sharedContainer, "Parent is not an attachment")
		parent.Parent = parentsParent
		parent.CFrame = CFrame.new()
	end

	function emitterContainer:Destroy(destroyParent: boolean?)
		if destroyParent or parent.Parent == sharedContainer then
			parent:Destroy()
		else
			for emitter in emitters do
				emitter:Destroy()
			end
		end

		table.clear(emitterContainer)
	end

	function emitterContainer:Toggle(toggle: boolean)
		for emitter in emitters do
			emitter.Enabled = toggle
		end
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	if existingParent then
		emitterContainer:MountTo(existingParent)
	else
		local attachment = Instance.new("Attachment")
		attachment.Parent = sharedContainer

		emitterContainer:MountTo(attachment)
	end

	return emitterContainer
end

function ParticleEmitterUtil.createContainerPool(templateScript: Script, initialSize: number?)
	return ObjectPool.new(function()
		return ParticleEmitterUtil.createEmitterContainer(templateScript)
	end, nil, initialSize)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

do
	sharedContainer = Instance.new("Part")
	sharedContainer.Name = "EmitterContainer"
	sharedContainer.Anchored = true
	sharedContainer.CFrame = CFrame.new()
	sharedContainer.Transparency = 1
	sharedContainer.CanCollide = false
	sharedContainer.CanTouch = false
	sharedContainer.CanQuery = false
	sharedContainer.Parent = Workspace.Terrain
end

return ParticleEmitterUtil
