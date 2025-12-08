--[[
    A utility for interfacing with a table(Datastores) via addresss
    A address is just a sequence of keys seperated by a delimiter that point you to a value in a dictionary (Ex: "Home/Left/Right" or "Home.Left.Right")
    Any non-alphanumeric characters are valid delimiters except for underscores
]]
--!strict

local DataFormatUtil = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataConstants = require(ReplicatedStorage.Shared.Data.DataConstants)
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Signal = require(ReplicatedStorage.Shared.Signal)
local DataTypes = require(ReplicatedStorage.Shared.Data.DataTypes)

-- export type Data = string & number & boolean & Store -- | string | number | boolean | Store
export type Data = DataTypes.Data
export type Store = DataTypes.Store

export type UpdatedEvent = Signal.Signal<string, any, { [string]: any }>

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function setFromKeys(store: Store, keys: { string }, newValue: any)
	if #keys == 1 then -- Base case
		newValue = if typeof(newValue) == "table" then TableUtil.deepClone(newValue) else newValue
		store[keys[1]] = newValue

		return newValue
	else -- Recursive case
		local key = table.remove(keys, 1)
		if key then
			return setFromKeys(store[key] :: Store, keys, newValue)
		end
	end

	return nil
end

--[[
    Generates an array of table keys(directions) from a string formatted like a address
]]
local function getKeysFromAddress(address: string): { string }
	local keys = {}

	for word in string.gmatch(address, "[%w(_)]+") do
		table.insert(keys, word)
	end

	return keys
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
--[[
    Retrieves a value stored in an array
]]
function DataFormatUtil.getFromAddress(store: Store, address: string): Data
	local keys = getKeysFromAddress(address)
	for i = 1, #keys do
		store = store[keys[i]] :: Store
	end

	return store
end

--[[
    Set a value in table using an array of keys point to it's new location in the table
]]
function DataFormatUtil.setFromAddress(store: Store, address: string, newValue: any): Data
	return setFromKeys(store, getKeysFromAddress(address), newValue)
end

function DataFormatUtil.getDataKey()
	local prefix = if GameUtil.isLive() then "Live" else (if GameUtil.isQA() then "QA" else "Dev")
	return prefix .. DataConstants.Version[prefix]
end

-- Assumes that there are no gaps
function DataFormatUtil.storeToArray(store: Store)
	local array = {}

	for k, v in store do
		array[tonumber(k)] = v
	end

	return array
end

function DataFormatUtil.arrayToStore(array: { Data })
	local store = {}

	for i, v in array do
		store[tostring(i)] = v
	end

	return store
end

return DataFormatUtil
