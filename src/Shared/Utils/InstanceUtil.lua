local InstanceUtil = {}

function InstanceUtil.newNameParent(class: string, name: string, parent: Instance?): Instance
	local instance = Instance.new(class)
	instance.Name = name
	instance.Parent = parent

	return instance
end

function InstanceUtil.newProperties(class: string, props: { [string]: any }, children: { Instance }?): Instance
	local instance = Instance.new(class)
	for property, value in props do
		instance[property] = value
	end

	if children then
		for _, child in children do
			child.Parent = instance
		end
	end

	return instance
end

function InstanceUtil.onDestroyed(instance: Instance, callback: () -> ())
	return instance.AncestryChanged:Connect(function(_, parent)
		if not parent then
			callback()
		end
	end)
end

function InstanceUtil.findFirstDescendant(instance: Instance, searchingFor: string): Instance?
	for _, descendant in  (instance:GetDescendants()) do
		if descendant.Name == searchingFor then
			return descendant
		end
	end
end

function InstanceUtil.findFirstDescendantWhichIsA(instance: Instance, className: string): Instance?
	for _, descendant in  (instance:GetDescendants()) do
		if descendant:IsA(className) then
			return descendant
		end
	end
end

function InstanceUtil.waitForDescendant(instance, searchingFor: string): Instance
	local descendant
	repeat
		task.wait()
		descendant = InstanceUtil.findFirstDescendant(instance, searchingFor)
	until descendant

	return descendant
end

function InstanceUtil.waitForFirstChildOfClass(instance: Instance, className: string)
	local child = instance:FindFirstChildOfClass(className)
	if child then
		return child
	end

	repeat
		instance.ChildAdded:Wait()
		child = instance:FindFirstChildOfClass(className)
	until child
	return child
end

return InstanceUtil
