--!strict
local InputConstants = {}

export type MobileInputButton = {
	ButtonReference: GuiButton,
	InstantiationProps: {
		Size: number,
		Position: Vector2,
		Icon: string,
		AnchorPoint: AnchorPoint,
	}?,
	IsToggle: boolean?,
}
type AnchorPoint = keyof<typeof(InputConstants.MobileInputButtonAnchors)>

InputConstants.MobileInputButtonAnchors = {
	Left = "Left",
	Right = "Right",
	Jump = "Jump",
}

InputConstants.FirstClassInputs = {}

return InputConstants
