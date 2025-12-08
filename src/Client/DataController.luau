--!strict
local DataController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Signal)
local Promise = require(ReplicatedStorage.Shared.Promise)
local DataFormatUtil = require(ReplicatedStorage.Shared.Data.DataFormatUtil)
local DataConstants = require(ReplicatedStorage.Shared.Data.DataConstants)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local bank: DataFormatUtil.Store = {}

local loader = Promise.new(function(resolve)
	DataConstants.Remotes.DataInitialized:OnClientEvent(function(data)
		bank = data
		resolve()
	end)

	DataConstants.Remotes.ClientReadyForData:FireServer()
end)

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

DataController.Updated = Signal.new() :: DataFormatUtil.UpdatedEvent
DataController.Ready = loader -- Promise that resolves when data is initialized

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- We use addresses on client too only bc it's convinient to copy same addresses as client
function DataController.get(address: string)
	local value = DataFormatUtil.getFromAddress(bank, address)
	return value
end

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

DataConstants.Remotes.DataUpdated:OnClientEvent(function(address, newValue, event, eventMeta)
	loader:andThen(function() --- Ensures data has loaded before any changes are made, just in case
		DataFormatUtil.setFromAddress(bank, address, newValue)
		if event then
			DataController.Updated:Fire(event, newValue, eventMeta or {})
		end
	end)
end)

loader:await()

return DataController
