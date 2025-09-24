-- PID
-- August 11, 2020

--[[
	PID stands for Proportional-Integral-Derivative. One example of PID controllers in
	real-life is to control the input to each motor of a drone to keep it stabilized.
	Another example is cruise-control on a car.
	-----------------------------------------------
	Constructor:
		pid = PID.new(min, max, kP, kD, kI)
	Methods:
		pid:Calculate(dt, setpoint, pv)
> Calculates and returns the new value
> dt: DeltaTime
> setpoint: The current point
> pv: The process variable (i.e. goal)
		pid:Reset()
> Resets the PID
	-----------------------------------------------
--]]

local PID = {}

function PID.new(min: number, max: number, kp: number, kd: number, ki: number)
	local pid = setmetatable({}, PID)

	local preError = 0
	local integral = 0

	-- Gets controller output to reach process variable
	function pid:Calculate(dt: number, setpoint: number, pv: number): number
		local err = (setpoint - pv)
		local pOut = (kp * err)
		integral += (err * dt)
		local iOut = (ki * integral)
		local deriv = ((err - preError) / dt)
		local dOut = (kd * deriv)
		local output = math.clamp((pOut + iOut + dOut), min, max)
		preError = err

		return output
	end

	function pid:Reset()
		preError = 0
		integral = 0
	end

	function pid:SetMinMax(newMin: number, newMax: number)
		min = newMin
		max = newMax
	end

	return pid
end

return PID
