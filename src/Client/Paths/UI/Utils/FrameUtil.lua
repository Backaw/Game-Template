local FrameUtil = {}

local Players = game:GetService("Players")
local UIScaleController = require(Players.LocalPlayer.PlayerScripts.Paths.UI.UIScaleController)

function FrameUtil.scaleToVerticalGrid(frame: Frame)
	frame.AutomaticSize = Enum.AutomaticSize.None

	local topOffset = if frame:FindFirstChild("UIPadding") then frame.UIPadding.PaddingTop.Offset else 0
	frame.Size = UDim2.new(
		frame.Size.X.Scale,
		frame.Size.X.Offset,
		0,
		(topOffset * 2 + (frame:FindFirstChildOfClass("UIGridLayout") or frame:FindFirstChildOfClass("UIListLayout")).AbsoluteContentSize.Y)
			/ UIScaleController.getScale()
	)
end

function FrameUtil.scaleToHorizontalGrid(frame: Frame, reference: Frame?)
	reference = reference or frame
	frame.AutomaticSize = Enum.AutomaticSize.None

	local topOffset = if reference:FindFirstChild("UIPadding") then reference.UIPadding.PaddingTop.Offset else 0
	frame.Size = UDim2.new(
		0,
		(
			topOffset * 2
			+ (reference:FindFirstChildOfClass("UIGridLayout") or reference:FindFirstChildOfClass("UIListLayout")).AbsoluteContentSize.X
		) / UIScaleController.getScale(),
		frame.Size.Y.Scale,
		frame.Size.Y.Offset
	)
end

return FrameUtil
