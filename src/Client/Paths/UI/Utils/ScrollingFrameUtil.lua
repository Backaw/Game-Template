local ScrollingFrameUtil = {}

local Players = game:GetService("Players")
local UIScaleController = require(Players.LocalPlayer.PlayerScripts.Paths.UI.UIScaleController)

function ScrollingFrameUtil.scaleToVerticalGrid(frame: ScrollingFrame)
	local gridLayout: UIGridStyleLayout? = frame:FindFirstChildOfClass("UIGridLayout") or frame:FindFirstChildOfClass("UIListLayout")
	local topOffset = if frame:FindFirstChild("UIPadding") then frame.UIPadding.PaddingTop.Offset else 0

	local size
	if gridLayout then
		size = (topOffset * 2 + gridLayout.AbsoluteContentSize.Y) / UIScaleController.getScale()
	else
		frame.AutomaticCanvasSize = Enum.AutomaticSize.X
		size = frame.AbsoluteCanvasSize.X
		frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	end

	frame.CanvasSize = UDim2.fromOffset(0, size)
end

function ScrollingFrameUtil.scaleToHorizontalGrid(frame: ScrollingFrame)
	local gridLayout: UIGridStyleLayout? = frame:FindFirstChildOfClass("UIGridLayout") or frame:FindFirstChildOfClass("UIListLayout")
	local leftOffset = if frame:FindFirstChild("UIPadding") then frame.UIPadding.PaddingLeft.Offset else 0

	local size
	if gridLayout then
		size = (leftOffset * 2 + gridLayout.AbsoluteContentSize.X) / UIScaleController.getScale()
	else
		frame.AutomaticCanvasSize = Enum.AutomaticSize.X
		size = frame.AbsoluteCanvasSize.X / UIScaleController.getScale()
		frame.AutomaticCanvasSize = Enum.AutomaticSize.None
	end

	frame.CanvasSize = UDim2.fromOffset(size, 0)
end

function ScrollingFrameUtil.setGridSize(grid: UIGridLayout, cellCount: number, heightScale: number?)
	grid.CellSize = UDim2.new(1 / cellCount, -math.ceil(grid.CellPadding.X.Offset * (cellCount - 1) / cellCount), 0, 0)
	task.defer(function()
		grid.CellSize += UDim2.fromOffset(0, grid.AbsoluteCellSize.X * (heightScale or 1))
	end)
end

return ScrollingFrameUtil
