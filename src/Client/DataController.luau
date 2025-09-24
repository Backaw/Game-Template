--!strict
local DataController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local Promise = require(ReplicatedStorage.Shared.Packages.Promise)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local DataFormatUtil = require(ReplicatedStorage.Shared.Data.DataFormatUtil)

-------------------------------------------------------------------------------
-- PRIVATE VARIABLES
-------------------------------------------------------------------------------

local bank: DataFormatUtil.Store = {}

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

DataController.Updated = Signal.new() :: DataFormatUtil.UpdatedEvent

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- We use addresses on client too only bc it's convinient to copy same addresses as client
function DataController.get(address: string)
	local value = DataFormatUtil.getFromAddress(bank, address)
	return value
end

local loader = Promise.new(function(resolve)
	local cleanup: () -> ()
	cleanup = Remotes.bindEventTemp("DataInitialized", function(data)
		bank = data

		cleanup()
		resolve()
	end)

	Remotes.fireServer("ClientReadyForData")
end)

Remotes.bindEvents({
	DataUpdated = function(address: string, newValue: any, event: string?, eventMeta: { [string]: any }?)
		loader:andThen(function() --- Ensures data has loaded before any changes are made, just in case
			DataFormatUtil.setFromAddress(bank, address, newValue)
			if event then
				DataController.Updated:Fire(event, newValue, eventMeta or {})
			end
		end)
	end,
})

-- Yield initialization of other modules
loader:await()

return DataController
