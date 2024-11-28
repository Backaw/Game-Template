local RagdollUtil = {}

function RagdollUtil.toggle(character: Model, toggle: boolean)
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart then
		humanoidRootPart.CanCollide = not toggle
	end

	for _, bodyPart: BasePart in  (character:GetChildren()) do
		if bodyPart:IsA("BasePart") then
			for _, motor: Motor6D in  (bodyPart:GetChildren()) do
				if motor:IsA("Motor6D") then
					motor.Enabled = not toggle
				end
			end
		end
	end
end

return RagdollUtil
