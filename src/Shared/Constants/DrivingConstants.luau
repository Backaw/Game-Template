local DrivingConstants = {}

export type Specs = {
	Drive: {
		TopSpeed: number,
		Acceleration: number,
	},
	Steer: {
		TopSpeed: number,
		Acceleration: number,
	},
}

DrivingConstants.Modes = {
	Car = "Car",
	HoverCar = "HoverCar",
	Sled = "Sled",
}

DrivingConstants.ModeSpecs = (function()
	local specs: {
		[string]: Specs,
	} = {
		[DrivingConstants.Modes.Car] = {
			Drive = {
				TopSpeed = 50,
				Acceleration = 30,
			},
			Steer = {
				TopSpeed = 100,
				Acceleration = 100,
			},
		},
	}

	return specs
end)()

DrivingConstants.SpeedBoost = {
	Multiplier = 1,
	Length = 1,
	MaxMultiples = 3,
}

return DrivingConstants
