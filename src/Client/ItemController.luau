--!strict
local ItemController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Client = ReplicatedStorage.Client
local ItemConstants = require(Shared.Items.ItemConstants)
local AtomicTable = require(Shared.AtomicTable)
local AtomicValue = require(Shared.AtomicValue)
local Signal = require(Shared.Signal)
local DataController = require(Client.DataController)

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function getEquippedItems<T>(itemType: ItemConstants.ItemType, equipped: T): T
	local returning = {}

	for i = 1, ItemConstants.EquipSlots[itemType] do
		local id = tostring(i)
		returning[id] = (equipped :: any)[id] or false
	end

	return returning
end

-------------------------------------------------------------------------------
-- PUBLIC VARIABLES
-------------------------------------------------------------------------------

ItemController.ItemAcquired = Signal.new() :: Signal.Signal<ItemConstants.ItemType, string>

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

DataController.Updated:Connect(function(event, _, eventMeta)
	if event == ItemConstants.DataEvents.ItemAcquired then
		ItemController.ItemAcquired:Fire(eventMeta.Type, eventMeta.Name)
	end
end)

return ItemController
