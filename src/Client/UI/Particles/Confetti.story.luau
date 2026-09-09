--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Confetti = require(ReplicatedStorage.Client.UI.Particles.Confetti)
local Maid = require(ReplicatedStorage.Shared.Maid)

local maid = Maid.new()

return function(target)
	local success, err = pcall(function()
		local root = Instance.new("Frame")
		root.Size = UDim2.fromScale(1, 1)
		root.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
		root.BorderSizePixel = 0
		root.ClipsDescendants = false
		root.Parent = target
		maid:Add(root)

		local listLayout = Instance.new("UIListLayout")
		listLayout.Padding = UDim.new(0, 12)
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		listLayout.Parent = root

		local padding = Instance.new("UIPadding")
		padding.PaddingBottom = UDim.new(0, 24)
		padding.Parent = root

		local function makeButton(name: string, text: string, color: Color3, onActivated: () -> ())
			local button = Instance.new("TextButton")
			button.Name = name
			button.Size = UDim2.fromOffset(160, 40)
			button.BackgroundColor3 = color
			button.BorderSizePixel = 0
			button.Font = Enum.Font.GothamBold
			button.TextSize = 16
			button.TextColor3 = Color3.fromRGB(30, 30, 30)
			button.Text = text
			button.ZIndex = 2
			button.Parent = root
			maid:Add(button)

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = button

			maid:Add(button.Activated:Connect(onActivated :: any))
		end

		makeButton("Explode", "Explode", Color3.fromRGB(255, 201, 75), function()
			Confetti.explode({
				Parent = root,
				Position = UDim2.fromScale(0.5, 0.5),
			})
		end)

		makeButton("Waterfall", "Waterfall", Color3.fromRGB(120, 210, 255), function()
			Confetti.waterfall({
				Parent = root,
			})
		end)

		task.defer(function()
			if root.Parent then
				Confetti.explode({
					Parent = root,
					Position = UDim2.fromScale(0.5, 0.5),
				})
			end
		end)

		return nil
	end)

	if not success then
		warn(err)
	end

	return function()
		maid:Cleanup()
	end
end
