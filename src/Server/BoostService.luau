--!strict
local BoostService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local PlayersService = require(ServerStorage.Server.PlayersService)
local BoostConstants = require(ReplicatedStorage.Shared.Constants.BoostConstants)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local countdowns: { [Player]: { [string]: { Thread: thread, StartTime: number } } } = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function getAddress(boostName: string)
	return "Boosts." .. boostName
end

local function applyMultiplier(player: Player, boostName: string, sign: number)
	local constants = BoostConstants.Boosts[boostName]
	PlayerDataService.increment(
		player,
		"Multipliers." .. constants.Multiplicand,
		sign * constants.MultiplierAddend,
		constants.Multiplicand .. "MultiplierChanged"
	)
end

local function stopCountdown(player: Player, boostName: string): number?
	local countdown = countdowns[player][boostName]
	if countdown then
		task.cancel(countdown.Thread)
		local startTime = countdown.StartTime

		return math.max(0, os.time() - startTime)
	end

	return nil
end

local function countdown(player: Player, boostName: string)
	local address = getAddress(boostName)
	local remainingTime = PlayerDataService.get(player, address) :: number?

	if remainingTime then
		countdowns[player][boostName] = {
			StartTime = os.time(),
			Thread = task.delay(remainingTime, function()
				countdowns[player][boostName] = nil
				PlayerDataService.set(player, address, nil)

				applyMultiplier(player, boostName, -1)
			end),
		}
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function BoostService.giveBoost(player: Player, name: string, lengthInMinutes: number)
	assert(lengthInMinutes > 0, "Length in minutes must be greater than 0")
	assert(lengthInMinutes ~= math.huge, "Length in minutes must not be infinite")

	local address = getAddress(name)

	local remainingTime = PlayerDataService.get(player, address) :: number
	local timeToAdd = lengthInMinutes * 60
	if remainingTime then
		local timeUsed = stopCountdown(player, name) or 0
		remainingTime += -timeUsed + timeToAdd

		PlayerDataService.set(player, address, remainingTime, "BoostExtended", {
			Name = name,
		})
	else
		PlayerDataService.set(player, address, timeToAdd, "BoostCreated", {
			Name = name,
		})

		applyMultiplier(player, name, 1)
	end

	countdown(player, name)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

PlayersService.registerLoadHandler("Boosts", function(player: Player)
	countdowns[player] = {}

	for k in (PlayerDataService.get(player, "Boosts")) :: { [string]: number } do
		countdown(player, k)
	end

	PlayersService.registerUnloadTask(player, function()
		for boostName in countdowns[player] do
			local address = getAddress(boostName)

			local timeLeft = stopCountdown(player, boostName)
			PlayerDataService.set(player, address, PlayerDataService.get(player, address) :: number - (timeLeft or 0))
		end

		countdowns[player] = nil
	end)
end)

return BoostService
