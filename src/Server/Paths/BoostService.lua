local BoostService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local PlayersService = require(Paths.Services.PlayersService)
local BoostConstants = require(Paths.Shared.Constants.BoostConstants)

type Store = {
	CountdownStartTime: number,
	TimeRemaining: number,
}

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local countdowns: { [Player]: { [string]: { Thread: thread, StartTime: number }? } } = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function applyMultiplier(player: Player, boostName: string, sign: number)
	local constants = BoostConstants.Boosts[boostName]
	PlayerDataService.increment(
		player,
		"Multipliers." .. constants.Multiplicand,
		sign * constants.MultiplierAddend,
		constants.Multiplicand .. "MultiplierChanged"
	)
end

local function countdown(player: Player, boostName: string)
	local existingCountdown = countdowns[player][boostName]
	if existingCountdown then
		task.cancel(existingCountdown.Thread)
	end

	local path = "Boosts." .. boostName
	local timeRemaining = PlayerDataService.get(player, path)

	-- RETURN: Infinite boost
	if timeRemaining == true then
		return
	end

	countdowns[player][boostName] = {
		StartTime = os.time(),
		Thread = task.delay(timeRemaining, function()
			PlayerDataService.set(player, path, nil)
			countdowns[player][boostName] = nil

			applyMultiplier(player, boostName, -1)
		end),
	}
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function BoostService.createBoost(player: Player, name: string, lengthInMinutes: number)
	local path = "Boosts." .. name

	local timeRemaining = PlayerDataService.get(player, path)
	if timeRemaining then
		if timeRemaining == true then
			return
		end

		PlayerDataService.set(
			player,
			path,
			timeRemaining - (os.time() - countdowns[player][name].StartTime) + lengthInMinutes * 60,
			"BoostExtended",
			{
				Name = name,
			}
		)
	else
		PlayerDataService.set(player, path, if lengthInMinutes == math.huge then true else lengthInMinutes * 60, "BoostCreated", {
			Name = name,
		})

		applyMultiplier(player, name, 1)
	end

	countdown(player, name)
end

BoostService.loadPlayer = PlayersService.promisifyLoader(function(player: Player)
	countdowns[player] = {}

	for k in  (PlayerDataService.get(player, "Boosts")) do
		countdown(player, k)
	end

	PlayersService.registerUnloadTask(player, function()
		for boostName, info in  (countdowns[player]) do
			local path = "Boosts." .. boostName

			task.cancel(info.Thread)
			PlayerDataService.set(player, path, PlayerDataService.get(player, path) - (os.time() - info.StartTime))
		end

		countdowns[player] = nil
	end)
end, "Boosts")

PlayerDataService.registerReconciler(function(data)
	if data.Boosts.X5Cash == true and data.Multipliers.Cash < 5 then
		data.Multipliers.Cash += 4
	end
end)

return BoostService
