--!strict
local InputConstants = {}

export type UIParams = {
	Keybind: boolean?,
	Mobile: GuiButton | {
		Size: number,
		Position: Vector2,
		Icon: string,
		AnchorPoint: AnchorPoint,
	},
	IsToggle: boolean?,
	PassThrough: boolean?,
}

type AnchorPoint = keyof<typeof(InputConstants.MobileButtonAnchorTypes)>

InputConstants.MobileButtonAnchorTypes = {
	Left = "Left",
	Right = "Right",
	Jump = "Jump",
}

InputConstants.FirstClassInputs = {}

return InputConstants
