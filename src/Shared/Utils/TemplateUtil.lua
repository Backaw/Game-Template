local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TemplateUtil = {}

--[[
    This returns a constructor for templates that are within UI, makes for quick editing
]]
function TemplateUtil.constructor(template: GuiObject, doNotRemove: boolean?)
	local parent = template.Parent

	template.Visible = false
	if not doNotRemove then
		template.Parent = nil :: Instance
	end

	return function()
		local clone = template:Clone()
		clone.Visible = true
		clone.Parent = parent

		return clone
	end
end

function TemplateUtil.cloneChildren(source: Instance, destination: Instance?)
	local instances = {}
	for _, child in  (source:GetChildren()) do
		local clone = child:Clone()
		clone.Parent = destination

		instances[clone.Name] = clone
	end

	return instances
end

function TemplateUtil.cloneFromStorage(category: string, name: string)
	return ReplicatedStorage.Assets.Templates[category][name]:Clone()
end

function TemplateUtil.getFromStorage(category: string, name: string)
	return ReplicatedStorage.Assets.Templates[category]:FindFirstChild(name)
end

return TemplateUtil
