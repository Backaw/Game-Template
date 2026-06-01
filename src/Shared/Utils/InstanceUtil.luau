--!strict
local InstanceUtil = {}

local CollectionService = game:GetService("CollectionService")

-------------------------------------------------------------------------------
-- CONSTRUCTORS
-------------------------------------------------------------------------------

function InstanceUtil.newNameParent<T>(instance: T, name: string, parent: Instance?)
	local x = instance :: Instance
	x.Name = name
	x.Parent = parent

	return instance
end

function InstanceUtil.newProperties(class: string, props: { [string]: any }, children: { Instance }?): Instance
	local instance = Instance.new(class)
	for property, value in props do
		(instance :: any)[property] = value
	end

	if children then
		for _, child in children do
			child.Parent = instance
		end
	end

	return instance
end

function InstanceUtil.newAnimation(animationId: string)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	return animation
end

function InstanceUtil.newRaycastParams(
	collisionGroup: string?,
	respectCanCollide: boolean?,
	filterType: Enum.RaycastFilterType?,
	filterDescendantsInstances: { Instance }?,
	ignoreWater: boolean?
)
	local raycastParams = RaycastParams.new()
	if collisionGroup then
		raycastParams.CollisionGroup = collisionGroup
		raycastParams.RespectCanCollide = respectCanCollide or false
	end

	if filterType then
		raycastParams.FilterType = filterType

		if filterDescendantsInstances then
			raycastParams.FilterDescendantsInstances = filterDescendantsInstances
		end
	end

	raycastParams.IgnoreWater = ignoreWater or false

	return raycastParams
end

function InstanceUtil.newWorldForce(attachment: Attachment, startingForce: Vector3, applyAtCenterOfMass: boolean?)
	local force = Instance.new("VectorForce")
	force.Attachment0 = attachment
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.Force = startingForce
	force.ApplyAtCenterOfMass = if applyAtCenterOfMass ~= nil then applyAtCenterOfMass else true
	force.Parent = attachment.Parent

	return force
end

function InstanceUtil.newWorldTorque(attachment: Attachment, startingTorque: Vector3)
	local torque = Instance.new("Torque")
	torque.Attachment0 = attachment
	torque.RelativeTo = Enum.ActuatorRelativeTo.World
	torque.Torque = startingTorque
	torque.Parent = attachment.Parent

	return torque
end

function InstanceUtil.newAttachment(parent: Instance, name: string, localCFrame: CFrame?, worldCFrame: CFrame?)
	local attachment = Instance.new("Attachment")
	attachment.Name = name
	attachment.Parent = parent
	if localCFrame then
		attachment.CFrame = localCFrame
	end
	if worldCFrame then
		attachment.WorldCFrame = worldCFrame
	end
	return attachment
end
-------------------------------------------------------------------------------
-- GETTERS
-------------------------------------------------------------------------------

function InstanceUtil.findFirstDescendant(instance: Instance, selector: string): Instance?
	for _, descendant in (instance:QueryDescendants(selector)) do
		return descendant
	end
	return nil :: Instance?
end

function InstanceUtil.waitForDescendant(instance, selector: string, timeout: number?): Instance?
	local et = 0
	timeout = timeout or 10

	local descendant
	repeat
		et += task.wait(0.1)
		descendant = InstanceUtil.findFirstDescendant(instance, selector)
	until descendant or et > timeout

	return descendant
end

function InstanceUtil.findLastAncestorOfClass(instance: Instance, className: string): Instance?
	local lastAncestor = nil
	local parent = instance.Parent

	while parent and parent ~= game do
		if not parent:IsA(className) then
			break
		end
		lastAncestor = parent
		parent = parent.Parent
	end

	return lastAncestor
end

-------------------------------------------------------------------------------
-- EVENT HANDLERS
-------------------------------------------------------------------------------

function InstanceUtil.onDestroyed(instance: Instance, callback: () -> ())
	local connection1: RBXScriptConnection?
	local connection2: RBXScriptConnection?

	local function disconnect()
		if connection1 and connection1.Connected then
			connection1:Disconnect()
		end
		if connection2 and connection2.Connected then
			connection2:Disconnect()
		end
	end

	local function wrappedCallback()
		callback()
		disconnect()
	end

	-- Listen to both Destroying (fires when :Destroy() is called) and AncestryChanged (fires when Parent = nil)
	connection1 = instance.Destroying:Once(wrappedCallback)
	connection2 = instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			wrappedCallback()
		end
	end)

	return disconnect
end

function InstanceUtil.connectAttributeChangedSignal(instance: Instance, attribute: string, handler: (value: any, instance: Instance) -> ())
	return instance:GetAttributeChangedSignal(attribute):Connect(function()
		handler(instance:GetAttribute(attribute), instance)
	end)
end

function InstanceUtil.connectInstanceAddedByTag<T>(tag: string, handler: (instance: T) -> ()): RBXScriptConnection
	for _, v: T in CollectionService:GetTagged(tag) do
		task.spawn(handler, v)
	end

	return CollectionService:GetInstanceAddedSignal(tag):Connect(handler)
end

function InstanceUtil.connectChildAdded(instance: Instance, handler: (child: Instance) -> ()): RBXScriptConnection
	for _, v in instance:GetChildren() do
		task.spawn(handler, v)
	end

	return instance.ChildAdded:Connect(handler)
end

function InstanceUtil.connectInstanceRemovedByTag<T>(tag: string, handler: (instance: T) -> ()): RBXScriptConnection
	return CollectionService:GetInstanceRemovedSignal(tag):Connect(handler)
end

function InstanceUtil.clearAttributes(instance: Instance, ignore: { string }?)
	for i in instance:GetAttributes() do
		if not ignore or not table.find(ignore, i) then
			instance:SetAttribute(i, nil)
		end
	end
end

function InstanceUtil.setAttributesWithPrefix(instance: Instance, attributes: { [string]: any }, prefix: string)
	for i, v in attributes do
		instance:SetAttribute(`{prefix}_{i}`, v)
	end
end

function InstanceUtil.getAttributeWithPrefix(instance: Instance, attribute: string, prefix: string)
	return instance:GetAttribute(`{prefix}_{attribute}`)
end

function InstanceUtil.getAttributeFirst<T>(instance: Instance, attribute: string, value: T)
	local initialValue = instance:GetAttribute(attribute)
	if initialValue then
		return initialValue :: T
	end

	instance:SetAttribute(attribute, value)
	return value
end

return InstanceUtil
