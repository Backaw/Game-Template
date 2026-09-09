--!strict
local TemplateUtil = {}

export type Constructor<T> = () -> T

-------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------

local TEMPLATE_STORAGE_ACTIONS = {
	Hide = "Hide",
	Orphan = "Orphan",
	Ignore = "Ignore",
	Reuse = "Reuse",
}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type TemplateStorageAction = keyof<typeof(TEMPLATE_STORAGE_ACTIONS)>

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

TemplateUtil.TemplateStorageAction = TEMPLATE_STORAGE_ACTIONS :: { [TemplateStorageAction]: TemplateStorageAction }

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- This returns a constructor for templates that are within UI, makes for quick editing
function TemplateUtil.constructor<T>(template: T, templateStorageAction: TemplateStorageAction?): Constructor<T>
	assert(typeof(template) == "Instance" and (template :: Instance):IsA("GuiObject"), "Template is not a GuiObject")

	local parent = (template :: GuiObject).Parent

	templateStorageAction = templateStorageAction or TemplateUtil.TemplateStorageAction.Orphan
	if templateStorageAction == TemplateUtil.TemplateStorageAction.Hide then
		template.Visible = false
	elseif templateStorageAction == TemplateUtil.TemplateStorageAction.Orphan then
		template.Parent = nil
	end

	if templateStorageAction == TemplateUtil.TemplateStorageAction.Reuse then
		local used = false
		return function()
			assert(not used, "Reuse constructor can only be called once")
			used = true
			return template :: T
		end
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
