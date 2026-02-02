--!strict
-- Array-based reactive state container
local AtomicArray = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type ArrayConnection<T> = Signal.Connection<{ [number]: true? }, { T }, { T }>
type ArrayChangeHandler<T> = (changed: { [number]: true? }, new: { T }, old: { T }) -> ()

type SubscribeMethod<T> = (self: any, handler: ArrayChangeHandler<T>) -> ArrayConnection<T>
type ConnectMethod<T> = (self: any, handler: ArrayChangeHandler<T>) -> ArrayConnection<T>
type CompareMethod<T> = (self: any, index: number, compareValue: T) -> boolean
type HasMethod<T> = (self: any, value: T) -> boolean
type GetMethod<T> = (self: any) -> { T }
type GetIndexMethod<T> = (self: any, index: number) -> T?
type GetLengthMethod<T> = (self: any) -> number

export type AtomicArray<T> = {
	Set: (self: AtomicArray<T>, new: { T }) -> (),
	SetIndex: (self: AtomicArray<T>, index: number, value: T?) -> (),
	Insert: (self: AtomicArray<T>, value: T, index: number?) -> (),
	Remove: (self: AtomicArray<T>, value: T) -> boolean,
	RemoveIndex: (self: AtomicArray<T>, index: number) -> T?,
	Update: (self: AtomicArray<T>, updater: (current: { T }) -> { T }) -> (),
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Has: HasMethod<T>,
	Get: GetMethod<T>,
	GetIndex: GetIndexMethod<T>,
	GetLength: GetLengthMethod<T>,
	RestrictedAccess: (self: AtomicArray<T>) -> RestrictedAtomicArray<T>,
	Destroy: (self: AtomicArray<T>) -> (),
}

export type RestrictedAtomicArray<T> = {
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Has: HasMethod<T>,
	Get: GetMethod<T>,
	GetIndex: GetIndexMethod<T>,
	GetLength: GetLengthMethod<T>,
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function indicesOf<T>(atom: { T }): { [number]: true? }
	local indices = {}
	for i = 1, #atom do
		indices[i] = true
	end
	return indices
end

local function handleChange<T>(old: { T }, new: { T }, event: Signal.Signal<{ [number]: true? }, { T }, { T }>)
	local changedIndices = {}
	local oldLen = #old
	local newLen = #new
	local minLen = math.min(oldLen, newLen)

	-- Check indices that exist in both arrays
	for i = 1, minLen do
		if old[i] ~= new[i] then
			changedIndices[i] = true
		end
	end

	-- Mark indices beyond minLen as changed (removed or added)
	if newLen > oldLen then
		for i = oldLen + 1, newLen do
			changedIndices[i] = true
		end
	elseif oldLen > newLen then
		for i = newLen + 1, oldLen do
			changedIndices[i] = true
		end
	end

	event:Fire(changedIndices, new, old)
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function AtomicArray.new<T>(initial: { T })
	assert(type(initial) == "table", "Initial can only be a table.")

	local atom = {} :: AtomicArray<T>

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------

	local reference: { T } = table.clone(initial)
	local event = Signal.new() :: Signal.Signal<{ [number]: true? }, { T }, { T }>

	-------------------------------------------------------------------------------
	-- PUBLIC METHODS
	-------------------------------------------------------------------------------

	function atom:Set(new: { T })
		assert(type(new) == "table", "Set only accepts a table for new")

		local old = table.clone(reference)
		table.clear(reference)
		table.move(new, 1, #new, 1, reference)
		handleChange(old, reference, event)
	end

	function atom:SetIndex(index: number, value: T?)
		assert(type(index) == "number", "SetIndex index must be a number")
		assert(index > 0, "SetIndex index must be positive")
		assert(index == math.floor(index), "SetIndex index must be an integer")

		local oldValue = reference[index]
		if oldValue == value then
			return
		end

		local old = table.clone(reference)
		reference[index] = value
		handleChange(old, reference, event)
	end

	function atom:Insert(value: T, index: number?)
		if index then
			assert(type(index) == "number", "Insert index must be a number")
			assert(index > 0, "Insert index must be positive")
			assert(index == math.floor(index), "Insert index must be an integer")
			assert(index <= #reference + 1, "Insert index out of bounds")
		end

		local old = atom:Get()
		if index then
			table.insert(reference, index, value)
		else
			table.insert(reference, value)
		end
		handleChange(old, reference, event)
	end

	function atom:Remove(value: T): boolean
		local index = table.find(reference, value)
		if not index then
			return false
		end

		return atom:RemoveIndex(index) ~= nil
	end

	function atom:RemoveIndex(index: number): T?
		assert(type(index) == "number", "RemoveIndex index must be a number")
		assert(index > 0, "RemoveIndex index must be positive")
		assert(index == math.floor(index), "RemoveIndex index must be an integer")
		assert(index <= #reference, "RemoveIndex index out of bounds")

		local old = atom:Get()
		local removed = table.remove(reference, index)
		handleChange(old, reference, event)
		return removed
	end

	function atom:Update(updater: (current: { T }) -> { T })
		local old = atom:Get()
		local updated = updater(reference)
		table.clear(reference)
		for i, v in updated do
			reference[i] = v
		end
		handleChange(old, reference, event)
	end

	function atom:Subscribe(handler: (changed: { [number]: true? }, new: { T }, old: { T }) -> ())
		return event:Subscribe(handler, indicesOf(reference), reference, {})
	end

	function atom:Connect(handler: (changed: { [number]: true? }, new: { T }, old: { T }) -> ())
		return event:Connect(handler)
	end

	function atom:Compare(index: number, compareValue: T): boolean
		assert(type(index) == "number", "Compare index must be a number")
		assert(index > 0, "Compare index must be positive")
		assert(index == math.floor(index), "Compare index must be an integer")

		return reference[index] == compareValue
	end

	function atom:Has(value: T): boolean
		return table.find(reference, value) ~= nil
	end

	function atom:GetIndex(index: number): T?
		assert(type(index) == "number", "GetIndex index must be a number")
		assert(index > 0, "GetIndex index must be positive")
		assert(index == math.floor(index), "GetIndex index must be an integer")

		local value = reference[index]
		if type(value) == "table" then
			return table.clone(value) :: T
		end
		return value
	end

	function atom:Get(): { T }
		return table.clone(reference)
	end

	function atom:GetLength(): number
		return #reference
	end

	function atom:RestrictedAccess(): RestrictedAtomicArray<T>
		local restricted = {
			Subscribe = atom.Subscribe,
			Connect = atom.Connect,
			Compare = atom.Compare,
			Has = atom.Has,
			Get = atom.Get,
			GetIndex = atom.GetIndex,
			GetLength = atom.GetLength,
		} :: RestrictedAtomicArray<T>

		return restricted
	end

	function atom:Destroy()
		event:Destroy()
		table.clear(reference)
		reference = nil :: any
	end

	return atom
end

return AtomicArray
