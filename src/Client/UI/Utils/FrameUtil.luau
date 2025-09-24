--!strict
local FrameUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIScaleController = require(ReplicatedStorage.Client.UI.UIScaleController)

function FrameUtil.scaleToVerticalGrid(frame: Frame)
	frame.AutomaticSize = Enum.AutomaticSize.None

	local uiPadding = frame:FindFirstChild("UIPadding") :: UIPadding?
	local grid: UIGridLayout | UIListLayout =
		assert(frame:FindFirstChildOfClass("UIGridLayout") or frame:FindFirstChildOfClass("UIListLayout"), "No grid layout found")

	local topOffset = if uiPadding then uiPadding.PaddingTop.Offset else 0
	frame.Size =
		UDim2.new(frame.Size.X.Scale, frame.Size.X.Offset, 0, (topOffset * 2 + grid.AbsoluteContentSize.Y) / UIScaleController.getScale())
end

function FrameUtil.scaleToHorizontalGrid(frame: Frame, reference: Frame?)
	reference = reference or frame
	frame.AutomaticSize = Enum.AutomaticSize.None

	local uiPadding = reference:FindFirstChild("UIPadding") :: UIPadding?
	local grid: UIGridLayout | UIListLayout =
		assert(reference:FindFirstChildOfClass("UIGridLayout") or reference:FindFirstChildOfClass("UIListLayout"), "No grid layout found")

	local topOffset = if uiPadding then uiPadding.PaddingTop.Offset else 0
	frame.Size =
		UDim2.new(0, (topOffset * 2 + grid.AbsoluteContentSize.X) / UIScaleController.getScale(), frame.Size.Y.Scale, frame.Size.Y.Offset)
end

return FrameUtil
