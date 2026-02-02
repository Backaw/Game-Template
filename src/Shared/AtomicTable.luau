--!strict
-- Table-based reactive state container
local AtomicTable = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type TableConnection<T> = Signal.Connection<{ [keyof<T>]: true? }, T, T>
type TableChangeHandler<T> = (changed: { [keyof<T>]: true? }, new: T, old: T) -> ()

type SubscribeMethod<T> = (self: any, handler: TableChangeHandler<T>) -> TableConnection<T>
type ConnectMethod<T> = (self: any, handler: TableChangeHandler<T>) -> TableConnection<T>
type CompareMethod<T> = (self: any, index: keyof<T>, compareValue: any) -> boolean
type GetMethod<T> = (self: any) -> T
type GetIndexMethod<T> = (self: any, index: keyof<T>) -> any

export type AtomicTable<T> = {
	Set: (self: AtomicTable<T>, new: T) -> (),
	SetIndex: (self: AtomicTable<T>, index: keyof<T>, value: any?) -> (),
	Update: (self: AtomicTable<T>, updater: (current: T) -> T) -> (),
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
	GetIndex: GetIndexMethod<T>,
	RestrictedAccess: (self: AtomicTable<T>) -> RestrictedAtomicTable<T>,
	Destroy: (self: AtomicTable<T>) -> (),
}

export type RestrictedAtomicTable<T> = {
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
	GetIndex: GetIndexMethod<T>,
}

type GenericTable = { [any]: any }

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function keysOf<T>(table: T): { [keyof<T>]: true? }
	local keys = {}
	for k in pairs(table) do
		keys[k :: keyof<T>] = true
	end
	return keys
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function AtomicTable.new<T>(initial: T)
	assert(type(initial) == "table", "Initial can only be a table.")

	local atom = {} :: AtomicTable<T>

	local reference: T = TableUtil.deepClone(initial)
	local event = Signal.new() :: Signal.Signal<{ [keyof<T>]: true? }, T, T>

	local function handleChange(old: T, new: T)
		local difference = TableUtil.difference(old, new)
		event:Fire(keysOf(difference), new, old)
	end

	function atom:Set(new)
		assert(type(new) == "table", "Set only accepts a table for new")

		local old = atom:Get()
		table.clear(reference :: GenericTable)
		for k, v in new do
			(reference :: GenericTable)[k] = v
		end
		handleChange(old, reference)
	end

	function atom:SetIndex(index, value)
		local old = atom:Get()
		local ref = reference :: GenericTable
		ref[index] = value
		handleChange(old, reference)
	end

	function atom:Update(updater)
		local old = atom:Get()
		for k, v in updater(reference) :: GenericTable do
			(reference :: GenericTable)[k] = v
		end
		handleChange(old, reference)
	end

	function atom:Subscribe(handler)
		return event:Subscribe(handler, keysOf(reference), reference, {})
	end

	function atom:Connect(handler)
		return event:Connect(handler)
	end

	function atom:Compare(index, compareValue)
		return (reference :: GenericTable)[index] == compareValue
	end

	function atom:GetIndex(index)
		local value = (reference :: GenericTable)[index] :: any
		if type(value) == "table" then
			value = TableUtil.deepClone(value)
		end
		return value
	end

	function atom:Get()
		return TableUtil.deepClone(reference)
	end

	function atom:RestrictedAccess(): RestrictedAtomicTable<T>
		local restricted = {
			Subscribe = atom.Subscribe,
			Connect = atom.Connect,
			Compare = atom.Compare,
			Get = atom.Get,
			GetIndex = atom.GetIndex,
		} :: RestrictedAtomicTable<T>

		return restricted
	end

	function atom:Destroy()
		event:Destroy()
		reference = nil :: any
	end

	return atom
end

return AtomicTable
