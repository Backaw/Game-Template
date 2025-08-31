local DataController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Modules
local Signal = require(Shared.Signal)
local Promise = require(Shared.Packages.Promise)
local Remotes = require(Shared.Remotes)
local DataFormatUtil = require(Shared.Data.DataFormatUtil)

local bank: DataFormatUtil.Store = {}
DataController.Updated = Signal.new() -- {event: string, newValue: any, eventMeta: table?}

-- We use addresses on client too only bc it's convinient to copy same addresses as client
function DataController.get(address: string)
	local value = DataFormatUtil.getFromAddress(bank, address)
	return value
end

local loader = Promise.new(function(resolve)
	local cleanup
	cleanup = Remotes.bindEventTemp("DataInitialized", function(data)
		bank = data

		cleanup()
		resolve()
	end)

	Remotes.fireServer("ClientReadyForData")
end)

Remotes.bindEvents({
	DataUpdated = function(address: string, newValue: any, event: string?, eventMeta: table?)
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
