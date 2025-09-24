--!strict
local TextLabelUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local UIScaleController = require(ReplicatedStorage.Client.UI.UIScaleController)

local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)

function TextLabelUtil.setScaleableText(label: TextLabel, text: string)
	local parent = label.Parent
	if not parent or not parent:IsA("GuiObject") then
		error("Parent not found")
	end

	label.AutomaticSize = Enum.AutomaticSize.None

	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = FONT
	params.Size = label.TextSize

	local size = TextService:GetTextBoundsAsync(params)
	local parentSize = parent.AbsoluteSize

	label.Size = UDim2.fromScale(size.X / parentSize.X * UIScaleController.getScale(), size.Y / parentSize.Y * UIScaleController.getScale())
	label.Text = text
	label.TextScaled = true
end

function TextLabelUtil.getContainerSize(text: string, textSize: number)
	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = FONT
	params.Size = textSize

	return TextService:GetTextBoundsAsync(params)
end

return TextLabelUtil
