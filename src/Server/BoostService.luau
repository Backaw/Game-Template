--!strict
local BoostService = {}

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Server = ServerStorage.Server
local Shared = ReplicatedStorage.Shared

local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local AbilityConstants = require(Shared.Abilities.AbilityConstants)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local BoostUtil = require(Shared.Boosts.BoostUtil)
local BoostConstants = require(Shared.Constants.BoostConstants)
local PlayerDataService = require(Server.Data.PlayerDataService)
local PlayersService = require(Server.PlayersService)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type CountdownState = {
	Thread: thread,
	StartTime: number,
	TimeLeftAtStart: number,
	Multiplier: number,
}

type PlayerCountdowns = { [CurrencyConstants.Currency]: { CountdownState } }

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local countdowns: { [Player]: PlayerCountdowns } = {}

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function applyMultiplier(player: Player, currency: CurrencyConstants.Currency, multiplier: number, remove: boolean?)
	if not CurrencyConstants.IngameCurrencies[currency] or AbilityConstants.AbilityNames[currency :: any] or multiplier <= 1 then
		return
	end

	local address = CurrencyUtil.getMultiplierAddress(currency)
	local current = (PlayerDataService.get(player, address) :: number?) or 1
	PlayerDataService.set(player, address, if remove then current / multiplier else current * multiplier, currency .. "MultiplierChanged")
end

local function getLiveStack(player: Player, currency: CurrencyConstants.Currency): BoostConstants.Stack
	local boosts = countdowns[player] and countdowns[player][currency]
	if not boosts then
		return {}
	end

	local stack: BoostConstants.Stack = {}
	local now = os.time()
	for _, state in boosts do
		table.insert(stack, {
			Multiplier = state.Multiplier,
			TimeLeft = math.max(0, state.TimeLeftAtStart - (now - state.StartTime)),
		})
	end
	return stack
end

local function saveStack(player: Player, currency: CurrencyConstants.Currency, stack: BoostConstants.Stack, event: string?)
	PlayerDataService.set(player, "Boosts." .. currency, if #stack > 0 then stack else nil, event, {
		Currency = currency,
	})
end

local function startBoost(player: Player, currency: CurrencyConstants.Currency, multiplier: number, timeLeft: number)
	local playerCountdowns = countdowns[player]
	local boosts = playerCountdowns[currency]
	if not boosts then
		boosts = {}
		playerCountdowns[currency] = boosts
	end

	local state: CountdownState
	state = {
		StartTime = os.time(),
		TimeLeftAtStart = timeLeft,
		Multiplier = multiplier,
		Thread = task.delay(timeLeft, function()
			if not countdowns[player] then
				return
			end

			local index = table.find(boosts, state)
			if not index then
				return
			end
			table.remove(boosts, index)
			if #boosts == 0 then
				playerCountdowns[currency] = nil
			end

			saveStack(player, currency, getLiveStack(player, currency), BoostConstants.DataEvents.Expired)
			applyMultiplier(player, currency, multiplier, true)
		end),
	}
	table.insert(boosts, state)
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function BoostService.hasBoost(player: Player, currency: CurrencyConstants.Currency): boolean
	local boosts = countdowns[player] and countdowns[player][currency]
	return boosts ~= nil and #boosts > 0
end

function BoostService.giveBoost(player: Player, currency: CurrencyConstants.Currency, multiplier: number, lengthInMinutes: number)
	assert(lengthInMinutes > 0, "Length in minutes must be greater than 0")
	assert(lengthInMinutes ~= math.huge, "Length in minutes must not be infinite")

	multiplier = BoostUtil.sanitizeMultiplier(currency, multiplier)

	local timeToAdd = lengthInMinutes * 60
	local stack = getLiveStack(player, currency)
	table.insert(stack, {
		Multiplier = multiplier,
		TimeLeft = timeToAdd,
	})

	saveStack(player, currency, stack, BoostConstants.DataEvents.Created)
	applyMultiplier(player, currency, multiplier)
	startBoost(player, currency, multiplier, timeToAdd)
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

PlayersService.registerLoadHandler("Boosts", function(player: Player)
	countdowns[player] = {}

	for currency, stack in (PlayerDataService.get(player, "Boosts") or {}) :: BoostConstants.Stacks do
		for _, boost in stack do
			startBoost(player, currency, boost.Multiplier, boost.TimeLeft)
		end
	end

	PlayersService.registerUnloadTask(player, function()
		for currency, boosts in countdowns[player] do
			for _, state in boosts do
				task.cancel(state.Thread)
			end
			saveStack(player, currency, getLiveStack(player, currency))
		end

		countdowns[player] = nil
	end)
end)

return BoostService
