--!strict
local TemplateUtil = {}

export type Constructor<T> = () -> T

-- This returns a constructor for templates that are within UI, makes for quick editing
function TemplateUtil.constructor<T>(template: T, doNotRemove: boolean?): Constructor<T>
	assert(typeof(template) == "Instance" and (template :: Instance):IsA("GuiObject"), "Template is not a GuiObject")

	local parent = (template :: GuiObject).Parent

	template.Visible = false
	if not doNotRemove then
		template.Parent = nil
	end

	return function()
		local clone = template:Clone()
		clone.Visible = true
		clone.Parent = parent

		return clone :: T
	end
end

function TemplateUtil.cloneChildren<T>(source: T, destination: Instance?)
	assert(typeof(source) == "Instance", "Source is not an Instance")

	local instances = {}
	for _, child in ipairs((source :: Instance):GetChildren()) do
		local clone = child:Clone()
		clone.Parent = destination

		instances[clone.Name] = clone
	end

	return instances :: T
end

return TemplateUtil
