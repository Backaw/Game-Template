--!strict
local ColorUtil = {}

function ColorUtil.addValue(color: Color3, addend: number)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + addend, 0, 1))
end

function ColorUtil.addHue(color: Color3, addend: number)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(math.clamp(h + addend, 0, 1), s, v)
end

function ColorUtil.addSaturation(color: Color3, addend: number)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(s + addend, 0, 1), v)
end

function ColorUtil.clampSaturation(color: Color3, min: number, max: number)
	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, math.clamp(math.clamp(s * 255, min, max) / 255, 0, 1), v)
end

function ColorUtil.setValue(color: Color3, value: number)
	local h, s = color:ToHSV()
	return Color3.fromHSV(h, s, value / 255)
end

return ColorUtil
