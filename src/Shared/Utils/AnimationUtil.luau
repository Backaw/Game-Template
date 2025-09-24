--!strict
local AnimationUtil = {}

function AnimationUtil.create(animationId: string)
	local animation = Instance.new("Animation")
	animation.AnimationId = animationId
	return animation
end

return AnimationUtil
