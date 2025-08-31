local RayUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Vector3Util = require(ReplicatedStorage.Modules.Utils.Vector3Util)

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

local camera = workspace.CurrentCamera
local partsToTrace = {}
local velocitiesToTrack = {}

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------
-- Always returns a result, Instance & Normal might be missing depending on if :Raycast hit something.
function RayUtil.customCast(origin: Vector3, direction: Vector3, params: RaycastParams?): RaycastResult
	local result = Workspace:Raycast(origin, direction, params) :: RaycastResult?
	if not result then
		result = {
			Distance = direction.Magnitude,
			Material = Enum.Material.Air,
			Position = origin + direction,
		}
	end
	return result
end

-- Defaults to ``UserInputService:GetMouseLocation()`` for **x** and **y**
function RayUtil.getViewportRay(mouseLocation: Vector2?, depth: number?): Ray
	mouseLocation = mouseLocation or UserInputService:GetMouseLocation()
	return camera:ViewportPointToRay(mouseLocation.X, mouseLocation.Y, depth)
end

function RayUtil.castDownwards(origin: Vector3, length: number, params: RaycastParams)
	return RayUtil.customCast(origin, Vector3.new(0, -length, 0), params)
end

function RayUtil.castRaysDistributed(origin: CFrame, xOffset: number, yOffset: number, length: number, params: RaycastParams?)
	local returns: { RaycastResult } = {}
	for x = -xOffset, xOffset, xOffset do
		for y = -yOffset, yOffset, yOffset do
			local offsettedOrigin = origin * Vector3.new(x, y, 0)
			table.insert(returns, RayUtil.customCast(offsettedOrigin, origin.LookVector * length, params))
		end
	end
	return returns
end

-- For custom tracking implementation: bullets, rockets, etc. (Tracers of projectiles / projectiles itself)
function RayUtil.trackVelocity(data: {
	position: Vector3,
	velocity: Vector3,
	params: RaycastParams,
	flags: VelocityTrackFlags,

	handlers: {
		onTrack: (deltaTime: number, currPosition: Vector3, velocity: Vector3, prevPosition: Vector3) -> (),
		onImpact: (result: RaycastResult, timeout: boolean) -> (),
		onBounce: (factor: number) -> ()?,
	}?,
})
	if not data.flags then
		data.flags = {}
	end

	data.handlers.onTrack(0, data.position, data.velocity, data.position)

	table.insert(velocitiesToTrack, {
		position = data.position,
		velocity = data.velocity,
		params = data.params,
		handlers = data.handlers,
		timeout = os.clock() + (data.flags.customTimeout or 20),
		zeroGravity = data.flags.zeroGravity or false,
		traveledDistance = 0,
		maxDistance = data.flags.maxTravelDistance or math.huge,
		bounces = data.flags.bounces or 0,
		bounceAngleLimit = data.flags.bounceAngleLimit or math.pi * 2,
		dtMultiplier = data.flags.deltaTimeMultiplier or 1,
	})
end

-- This method is used on server-side applications to just track a part. (Custom, more accurate .Touched simply put)
function RayUtil.tracePart(data: {
	part: BasePart,
	params: RaycastParams,
	flags: { bufferSize: number?, customTimeout: number? }?,
	handler: (result: RaycastResult, timedOut: boolean) -> (),
})
	if not data.flags then
		data.flags = {}
	end

	table.insert(partsToTrace, {
		part = data.part,
		params = data.params,
		handler = data.handler,
		pPosition = data.part.Position,
		bufferSize = data.flags.bufferSize or 1.5,
		timeout = os.clock() + (data.flags.customTimeout or 20),
	})
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
-- HEARTBEAT
RunService.Heartbeat:Connect(function(dt)
	dt = math.min(dt, 1)

	for i, data in velocitiesToTrack do
		local dtRelative = dt * data.dtMultiplier

		if not data.zeroGravity then
			data.velocity -= Vector3.yAxis * Workspace.Gravity * dtRelative
		end

		local pPosition = data.position
		local cPosition = pPosition + data.velocity * dtRelative

		data.position = cPosition
		data.handlers.onTrack(dt, cPosition, data.velocity, pPosition)

		local timedOut = os.clock() >= data.timeout
		if timedOut or data.traveledDistance >= data.maxDistance then
			table.remove(velocitiesToTrack, i)
			task.spawn(
				data.handlers.onImpact,
				{
					Distance = Vector3Util.squaredDistance(pPosition, cPosition),
					Position = cPosition,
					Material = Enum.Material.Air,
				} :: RaycastResult,
				timedOut
			)
			continue
		end

		local result = RayUtil.customCast(pPosition, cPosition - pPosition, data.params)
		data.traveledDistance += result.Distance

		if result.Instance then
			local normal = result.Normal
			local angle = math.acos(-data.velocity.Unit:Dot(normal))

			if data.bounces > 0 and (data.bounceAngleLimit == math.pi * 2 or angle <= data.bounceAngleLimit) then
				data.bounces -= 1

				local factor = 0.6
				local reflectedVelocity = data.velocity - 2 * data.velocity:Dot(normal) * normal
				data.velocity = reflectedVelocity * factor
				data.position = result.Position + normal * (0.1 + data.velocity.Magnitude * 0.01)

				if data.handlers.onBounce then
					data.handlers.onBounce(factor)
				end

				if data.velocity.Magnitude < 1 then
					task.spawn(data.handlers.onImpact, result)
					table.remove(velocitiesToTrack, i)
				end
			else
				task.spawn(data.handlers.onImpact, result)
				table.remove(velocitiesToTrack, i)
			end
		end
	end

	for i, data in partsToTrace do
		local root = data.part

		-- ERROR: PART IS NOT IN Workspace
		if not Workspace:IsAncestorOf(root) then
			table.remove(partsToTrace, i)
			continue
		end

		local cPosition = root.Position
		local pPosition = data.pPosition
		local diff = (cPosition - pPosition)
		local direction = diff.Unit * math.max(Vector3Util.squaredDistance(cPosition, pPosition), root.Size.Y * 1.5)

		-- TIMEOUT: PART BEEN FLYING FOR TOO LONG
		if os.clock() >= data.timeout then
			table.remove(partsToTrace, i)
			task.spawn(
				data.handler,
				{
					Distance = Vector3Util.squaredDistance(pPosition, cPosition),
					Position = cPosition,
					Material = Enum.Material.Air,
				} :: RaycastResult,
				true
			)
			continue
		end

		local rayResult = Workspace:Raycast(pPosition, direction, data.params) :: RaycastResult
		if rayResult and rayResult.Instance then
			task.spawn(data.handler, rayResult)
			table.remove(partsToTrace, i)
			table.clear(data)
			continue
		end

		data.pPosition = cPosition
	end
end)

return RayUtil
