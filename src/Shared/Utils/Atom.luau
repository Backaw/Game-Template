--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Shared.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

--[[
	Written by SixthAtom,
	a modern, type-checked, very lightweight and optimized reactive state listener.

	Designed to provide simple and efficient state management for (mainly UI) updates,
	data syncing and event-driven systems in Roblox projects.
]]

local Atom = {}

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Atom<T> = {
	_reference: T,
	_event: Signal.Signal<T, T>,

	Set: (self: Atom<T>, new: T) -> (),
	SetIndex: (self: Atom<T>, index: keyof<T>, value: any?) -> (),
	Update: (self: Atom<T>, updater: (current: T) -> T) -> (),
	Subscribe: (self: Atom<T>, handler: (new: T, old: T?) -> ()) -> Signal.Connection<T>,
	Compare: (self: Atom<T>, index: keyof<T>, compareValue: any) -> boolean,
	Get: (self: Atom<T>) -> T,
	GetIndex: (self: Atom<T>, index: keyof<T>) -> any,
	Destroy: (self: Atom<T>) -> (),
}

type GenericTable = { [any]: any }

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function handleChange<T>(self: Atom<T>, old: T, new: T)
	local difference = TableUtil.difference(old, new)
	local differenceOld = {}
	local differenceNew = {}

	for k, v in difference do
		differenceOld[k] = v.Old
		differenceNew[k] = v.New
	end

	self._event:Fire(differenceNew, differenceOld)
end

-------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS
-------------------------------------------------------------------------------

-- Replace the entire state with a new table
function Atom.Set<T>(self: Atom<T>, new: GenericTable)
	assert(type(new) == "table", "Set only accepts a table for new")

	local reference = self._reference :: GenericTable
	local old = self:Get()

	table.clear(reference)
	for k, v in new do
		reference[k] = v
	end
	handleChange(self, old, reference)
end

-- Update a single key in the state
function Atom.SetIndex<T>(self: Atom<T>, index: keyof<T>, value: any?)
	local reference = self._reference :: GenericTable
	local old = self:Get()

	reference[index] = value
	handleChange(self, old, reference)
end

-- Update state using a function that returns a new table
function Atom.Update<T>(self: Atom<T>, updater: (current: T) -> T)
	local reference = self._reference :: GenericTable
	local old = self:Get()

	for k, v in updater(reference) :: GenericTable do
		reference[k] = v
	end
	handleChange(self, old, reference)
end

-- Subscribe to state changes
function Atom.Subscribe<T>(self: Atom<T>, handler: (new: T, old: T?) -> ())
	task.spawn(handler, self._reference, nil)
	return self._event:Connect(handler)
end

-- Compare a key's value to a given value
function Atom.Compare<T>(self: Atom<T>, index: keyof<T>, compareValue: any)
	return (self._reference :: GenericTable)[index] == compareValue
end

-- Get a (deep) clone of a certain index in the current state
function Atom.GetIndex<T>(self: Atom<T>, index: keyof<T>)
	local value = (self._reference :: GenericTable)[index] :: any
	if type(value) == "table" then
		value = TableUtil.deepClone(value)
	end
	return value
end

-- Get a deep clone of the current state
function Atom.Get<T>(self: Atom<T>)
	return TableUtil.deepClone(self._reference)
end

-- Destroy the atom object and clean up the event
function Atom.Destroy<T>(self: Atom<T>)
	self._event:Destroy()
	self._reference = nil
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: T)
		assert(type(initial) == "table", "Initial can only be a table.")

		local atom = table.clone(Atom) :: Atom<T>

		atom._reference = TableUtil.deepClone(initial)
		atom._event = Signal.new() :: Signal.Signal<T, T>

		return atom
	end,
}
