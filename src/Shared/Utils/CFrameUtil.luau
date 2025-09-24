local CFrameUtil = {}

function CFrameUtil.ifNanThen0(cframe: CFrame): CFrame
	return if cframe ~= cframe then CFrame.new() else cframe
end

function CFrameUtil.getYComponent(cframe: CFrame, method: string?): number
	local _, y = cframe[method or "ToEulerAnglesYXZ"](cframe)
	return y :: number
end

function CFrameUtil.getZComponent(cframe: CFrame, method: string?): number
	local _, _, z = cframe[method or "ToEulerAnglesYXZ"](cframe)
	return z :: number
end

function CFrameUtil.getXComponent(cframe: CFrame, method: string?): number
	return cframe[method or "ToEulerAnglesYXZ"](cframe) :: number
end

function CFrameUtil.pivotFrom(cframe: CFrame, pivot: CFrame, transformation: CFrame)
	return pivot * transformation * pivot:ToObjectSpace(cframe)
end

return CFrameUtil
