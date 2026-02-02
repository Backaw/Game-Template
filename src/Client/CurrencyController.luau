--!strict
local CurrencyController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local CurrencyConstants = require(Shared.Currency.CurrencyConstants)
local CurrencyUtil = require(Shared.Currency.CurrencyUtil)
local TableUtil = require(Shared.Utils.TableUtil)
local AtomicValue = require(Shared.AtomicValue)
local DataController = require(Client.DataController)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type Cache = AtomicValue.AtomicValue<number>

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local cache: { [CurrencyConstants.Currency]: Cache } = TableUtil.forEach(CurrencyConstants.IngameCurrencies, function(_, k)
	return AtomicValue.new(DataController.get(CurrencyUtil.getAddress(k)) :: number)
end)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

CurrencyController.Currencies = TableUtil.forEach(cache, function(v: Cache)
	return v:RestrictedAccess()
end)

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function CurrencyController.transact(currency: CurrencyConstants.Currency, transacting: number, serverInitiated: boolean?)
	if transacting > 0 and not serverInitiated then
		transacting *= DataController.get(CurrencyUtil.getMultiplierAddress(currency)) :: number or 1
	end

	local nextValue = cache[currency]:Get() + math.floor(transacting)
	if nextValue >= 0 then
		cache[currency]:Set(nextValue)
		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

DataController.Updated:Connect(function(event, _, metadata)
	if event == "CurrencyChanged" and not metadata.ClientInitiated then
		CurrencyController.transact(metadata.Currency, metadata.Transacting, true)
	end
end)

return CurrencyController
