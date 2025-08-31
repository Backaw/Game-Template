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
	for _, descendant in (instance:GetDescendants()) do
		if descendant.Name == searchingFor then
			return descendant
		end
	end
end

function InstanceUtil.findFirstDescendantWhichIsA(instance: Instance, className: string): Instance?
	for _, descendant in (instance:GetDescendants()) do
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

function InstanceUtil.getChildrenOfClass(parent: Instance, class: string, filterMethod: ((child: Instance) -> boolean)?)
	local children = {}
	for _, v in parent:GetChildren() do
		if v:IsA(class) then
			if filterMethod ~= nil and not filterMethod(v) then
				continue
			end
			table.insert(children, v)
		end
	end
	return children
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

return InstanceUtil
