--!strict
local RayUtil = {}

local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

export type VelocityTrackFlags = {
	zeroGravity: boolean?,
	customTimeout: number?,
	deltaTimeMultiplier: number?,
	bounces: number?,
	bounceAngleLimit: number?,
	maxTravelDistance: number?,
}?

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local camera = Workspace.CurrentCamera

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
-- Always returns a result, Instance & Normal might be missing depending on if :Raycast hit something.
function RayUtil.customCast(origin: Vector3, direction: Vector3, params: RaycastParams?): RaycastResult<BasePart>
	local result = Workspace:Raycast(origin, direction, params) :: RaycastResult?
	if not result then
		result = {
			Distance = direction.Magnitude,
			Material = Enum.Material.Air,
			Position = origin + direction,
		} :: RaycastResult<BasePart>
	end

	return result :: RaycastResult<BasePart>
end

-- Defaults to UserInputService:GetMouseLocation()
function RayUtil.getViewportRay(mouseLocation: Vector2?, depth: number?): Ray
	mouseLocation = mouseLocation or UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, depth)
end

function RayUtil.castDownwards(origin: Vector3, length: number, params: RaycastParams)
	return RayUtil.customCast(origin, Vector3.new(0, -length, 0), params)
end

function RayUtil.castRaysDistributed(origin: CFrame, xOffset: number, yOffset: number, length: number, params: RaycastParams?)
	local returns: { RaycastResult<BasePart> } = {}
	for x = -xOffset, xOffset, xOffset do
		for y = -yOffset, yOffset, yOffset do
			local offsettedOrigin = origin * Vector3.new(x, y, 0)
			table.insert(returns, RayUtil.customCast(offsettedOrigin, origin.LookVector * length, params))
		end
	end
	return returns
end

return RayUtil
