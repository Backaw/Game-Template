--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIConstants = require(ReplicatedStorage.Client.UI.UIConstants)

return function()
	local issues = {}

	for _, screenGui: ScreenGui in ((ReplicatedStorage :: any)[UIConstants.InterfacesName]):GetChildren() do
		if screenGui:IsA("ScreenGui") then
			local name = screenGui.Name
			if name == "Cmdr" then
				continue
			end

			if screenGui.ResetOnSpawn then
				table.insert(issues, ("%s screen has ResetOnSpawn enabled"):format(name))
			end

			if not screenGui.IgnoreGuiInset and screenGui.Name ~= "Debug" then
				table.insert(issues, ("%s screen has IgnoreGuiInset disabled"):format(name))
			end
		end
	end

	return issues
end
