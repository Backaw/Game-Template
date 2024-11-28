local Players = game:GetService("Players")
local Paths = require(Players.LocalPlayer.PlayerScripts.Paths)

return function()
	local issues = {}

	for _, screenGui in  (Paths.UI:GetChildren()) do
		if screenGui:IsA("ScreenGui") then
			if screenGui.ResetOnSpawn then
				table.insert(issues, ("%s screen has reset on spawn enabled"):format(screenGui.Name))
			end
		end
	end

	return issues
end
