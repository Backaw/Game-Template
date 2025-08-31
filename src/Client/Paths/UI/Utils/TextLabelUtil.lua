local TextLabelUtil = {}
local TextService = game:GetService("TextService")

local Players = game:GetService("Players")
local UIScaleController = require(Players.LocalPlayer.PlayerScripts.Paths.UI.UIScaleController)

local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)

function TextLabelUtil.setScaleableText(label: TextLabel, text: string)
	label.AutomaticSize = Enum.AutomaticSize.None

	local params = Instance.new("GetTextBoundsParams")
	params.Text = text
	params.Font = FONT
	params.Size = label.TextSize

	local size = TextService:GetTextBoundsAsync(params)
	local parentSize = label.Parent.AbsoluteSize

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
