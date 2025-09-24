--!strict
local EmitterContainer = {}

local Workspace = game:GetService("Workspace")

export type EmitterContainer = {
	SetAttachmentCFrame: (EmitterContainer, cframe: CFrame) -> (),
	Emit: (EmitterContainer, attachmentCFrame: CFrame?) -> (),
	GetContainer: (EmitterContainer) -> Instance,
	GetAttachment: (EmitterContainer) -> Attachment,
	Destroy: (EmitterContainer) -> (),
}
export type Emitters = { [ParticleEmitter]: (number | NumberRange)? }

type EmitterOptions = {
	DestroyAfterEmit: boolean?,
	Scale: number?,
	AttachmentCFrame: CFrame?,
	ParentToContainer: boolean?,
	Speed: number?,
}

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local sharedContainer: BasePart

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
function EmitterContainer.getEmitterTemplatesFromAttributes(ancestor: Instance, ignore: { string }?, amountOverides: { [string]: number }?)
	local emitters: Emitters = {}

	for _, emitter in pairs(ancestor:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			local name = emitter.Name
			if ignore and table.find(ignore, name) then
				continue
			end

			if amountOverides and amountOverides[name] then
				emitters[emitter] = amountOverides[name]
				continue
			end

			local emitCount = emitter:GetAttribute("EmitCount") :: number?
			assert(typeof(emitCount) == "number", "EmitCount is not a number")

			emitters[emitter] = emitCount or 0
		end
	end

	return emitters
end

function EmitterContainer.scaleEmitter(emitter: ParticleEmitter, scale: number, speedScale: number?)
	local sizeKeypoints = {}
	for _, keypoint in pairs(emitter.Size.Keypoints) do
		table.insert(
			sizeKeypoints,
			NumberSequenceKeypoint.new(keypoint.Time, math.abs(keypoint.Value * scale), math.abs(keypoint.Envelope * scale))
		)
	end

	local squashKeypoints = {}
	for _, keypoint in pairs(emitter.Squash.Keypoints) do
		table.insert(
			squashKeypoints,
			NumberSequenceKeypoint.new(keypoint.Time, math.abs(keypoint.Value * scale), math.abs(keypoint.Envelope * scale))
		)
	end

	emitter.Size = NumberSequence.new(sizeKeypoints)
	emitter.Squash = NumberSequence.new(squashKeypoints)
	local speed = emitter.Speed
	emitter.Speed = NumberRange.new(speed.Min * scale, speed.Max * scale)

	if speedScale then
		local lifetime = emitter.Lifetime
		emitter.Lifetime = NumberRange.new(lifetime.Min / speedScale, lifetime.Max / speedScale)
	end
end

function EmitterContainer.new(emitterTemplates: Emitters, container: Instance?, attachment: Attachment?, options: EmitterOptions?)
	local emitterContainer = EmitterContainer :: EmitterContainer

	-------------------------------------------------------------------------------
	-- PRIVATE MEMBERS
	-------------------------------------------------------------------------------
	local random = Random.new()

	local emitters: Emitters = {}
	local isAttachmentPassed = attachment and true or false

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function emitterContainer:SetAttachmentCFrame(cframe)
		(attachment :: Attachment).WorldCFrame = cframe
	end

	function emitterContainer:Emit(attachmentCFrame)
		local largestLT = 0

		if attachmentCFrame then
			emitterContainer:SetAttachmentCFrame(attachmentCFrame)
		end

		for emitter, emitCount in emitters do
			emitter:Emit(if typeof(emitCount) == "NumberRange" then random:NextInteger(emitCount.Min, emitCount.Max) else emitCount)
			largestLT = math.max(largestLT, emitter.Lifetime.Max)
		end

		if options and options.DestroyAfterEmit then
			task.delay(largestLT * 1.1, function()
				emitterContainer:Destroy()
			end)
		end
	end

	function emitterContainer:GetContainer()
		return container :: Instance
	end

	function emitterContainer:GetAttachment()
		return attachment :: Attachment
	end

	function emitterContainer:Destroy()
		if options and options.ParentToContainer then
			for emitter in emitters do
				emitter:Destroy()
			end
		elseif not isAttachmentPassed then
			(attachment :: Attachment):Destroy()
		end

		emitterContainer = nil
	end

	-------------------------------------------------------------------------------
	-- LOGIC
	-------------------------------------------------------------------------------

	if not container and options and options.ParentToContainer then
		error("ParentToContainer is set to true but no container was provided.")
	end

	if attachment then
		container = attachment.Parent
	end

	--[[ if not container and not options.AttachmentCFrame then
		warn("CFrame is not set. Particles will emit at (0, 0, 0)", debug.traceback())
	end
 *]]
	do
		if not attachment then
			attachment = Instance.new("Attachment")
			attachment.Parent = container or sharedContainer
			attachment.WorldCFrame = options and options.AttachmentCFrame or attachment.WorldCFrame
		end

		for emitterTemplate, emitCount in emitterTemplates do
			local emitter: ParticleEmitter = emitterTemplate:Clone()
			emitter.Enabled = false
			emitter.Parent = if options and options.ParentToContainer then container else attachment

			local scale = options and options.Scale
			if scale then
				EmitterContainer.scaleEmitter(emitter, scale, options and options.Speed)
			end

			emitters[emitter] = emitCount
		end
	end

	return emitterContainer
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

return EmitterContainer
