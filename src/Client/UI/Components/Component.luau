--!strict
local Component = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Maid)

export type Component = {
	GetMaid: (Component) -> Maid.Maid,
	Destroy: (Component) -> (),
}

function Component.new()
	local component = {}

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local maid = Maid.new()

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------
	function component:GetMaid()
		return maid
	end

	function component:Destroy()
		maid:Destroy()
		table.clear(component)
	end

	return component
end

return Component
