--!strict
-- Array-based reactive state container
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
	_atomicState: true,
	_reference: { T },
	_event: Signal.Signal<{ [number]: true? }, { T }, { T }>,
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
	_atomicState: true,
	_reference: { T },
	_event: Signal.Signal<{ [number]: true? }, { T }, { T }>,
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

local function indicesOf<T>(arr: { T }): { [number]: true? }
	local indices = {}
	for i = 1, #arr do
		indices[i] = true
	end
	return indices :: { true? }
end

local function fireChange<T>(old: { T }, new: { T }, event: Signal.Signal<{ [number]: true? }, { T }, { T }>)
	local changedIndices = {}
	local oldLen = #old
	local newLen = #new
	local minLen = math.min(oldLen, newLen)

	for i = 1, minLen do
		if old[i] ~= new[i] then
			changedIndices[i] = true
		end
	end

	if newLen > oldLen then
		for i = oldLen + 1, newLen do
			changedIndices[i] = true
		end
	elseif oldLen > newLen then
		for i = newLen + 1, oldLen do
			changedIndices[i] = true
		end
	end

	if next(changedIndices) == nil then return end
	event:Fire(changedIndices, new, old)
end

-------------------------------------------------------------------------------
-- PROTOTYPE
-------------------------------------------------------------------------------

local AtomicArray = {}
AtomicArray._atomicState = true

function AtomicArray.Set<T>(self: AtomicArray<T>, new: { T })
	assert(type(new) == "table", "Set only accepts a table for new")

	local old = table.clone(self._reference)
	table.clear(self._reference)
	table.move(new, 1, #new, 1, self._reference)
	fireChange(old, self._reference, self._event)
end

function AtomicArray.SetIndex<T>(self: AtomicArray<T>, index: number, value: T?)
	assert(type(index) == "number", "SetIndex index must be a number")
	assert(index > 0, "SetIndex index must be positive")
	assert(index == math.floor(index), "SetIndex index must be an integer")

	local oldValue = self._reference[index]
	if oldValue == value then
		return
	end

	local old = table.clone(self._reference)
	self._reference[index] = value
	fireChange(old, self._reference, self._event)
end

function AtomicArray.Insert<T>(self: AtomicArray<T>, value: T, index: number?)
	if index then
		assert(type(index) == "number", "Insert index must be a number")
		assert(index > 0, "Insert index must be positive")
		assert(index == math.floor(index), "Insert index must be an integer")
		assert(index <= #self._reference + 1, "Insert index out of bounds")
	end

	local old = self:Get()
	if index then
		table.insert(self._reference, index, value)
	else
		table.insert(self._reference, value)
	end
	fireChange(old, self._reference, self._event)
end

function AtomicArray.Remove<T>(self: AtomicArray<T>, value: T): boolean
	local index = table.find(self._reference, value)
	if not index then
		return false
	end

	return self:RemoveIndex(index) ~= nil
end

function AtomicArray.RemoveIndex<T>(self: AtomicArray<T>, index: number): T?
	assert(type(index) == "number", "RemoveIndex index must be a number")
	assert(index > 0, "RemoveIndex index must be positive")
	assert(index == math.floor(index), "RemoveIndex index must be an integer")
	assert(index <= #self._reference, "RemoveIndex index out of bounds")

	local old = self:Get()
	local removed = table.remove(self._reference, index)
	fireChange(old, self._reference, self._event)
	return removed
end

function AtomicArray.Update<T>(self: AtomicArray<T>, updater: (current: { T }) -> { T })
	local old = self:Get()
	local updated = updater(self._reference)
	table.clear(self._reference)
	for i, v in updated do
		self._reference[i] = v
	end
	fireChange(old, self._reference, self._event)
end

function AtomicArray.Subscribe<T>(self: AtomicArray<T>, handler: ArrayChangeHandler<T>)
	return self._event:Subscribe(handler, indicesOf(self._reference), self._reference, {})
end

function AtomicArray.Connect<T>(self: AtomicArray<T>, handler: ArrayChangeHandler<T>)
	return self._event:Connect(handler)
end

function AtomicArray.Compare<T>(self: AtomicArray<T>, index: number, compareValue: T): boolean
	assert(type(index) == "number", "Compare index must be a number")
	assert(index > 0, "Compare index must be positive")
	assert(index == math.floor(index), "Compare index must be an integer")

	return self._reference[index] == compareValue
end

function AtomicArray.Has<T>(self: AtomicArray<T>, value: T): boolean
	return table.find(self._reference, value) ~= nil
end

function AtomicArray.GetIndex<T>(self: AtomicArray<T>, index: number): T?
	assert(type(index) == "number", "GetIndex index must be a number")
	assert(index > 0, "GetIndex index must be positive")
	assert(index == math.floor(index), "GetIndex index must be an integer")

	local value = self._reference[index]
	if type(value) == "table" then
		return table.clone(value) :: T
	end
	return value
end

function AtomicArray.Get<T>(self: AtomicArray<T>): { T }
	return table.clone(self._reference)
end

function AtomicArray.GetLength<T>(self: AtomicArray<T>): number
	return #self._reference
end

function AtomicArray.Destroy<T>(self: AtomicArray<T>)
	self._event:Destroy()
	table.clear(self._reference)
	self._reference = nil :: any
end

-------------------------------------------------------------------------------
-- RESTRICTED PROTOTYPE
-------------------------------------------------------------------------------

local RestrictedAtomicArray = {}
RestrictedAtomicArray._atomicState = true
RestrictedAtomicArray.Subscribe = AtomicArray.Subscribe :: any
RestrictedAtomicArray.Connect = AtomicArray.Connect :: any
RestrictedAtomicArray.Compare = AtomicArray.Compare :: any
RestrictedAtomicArray.Has = AtomicArray.Has :: any
RestrictedAtomicArray.Get = AtomicArray.Get :: any
RestrictedAtomicArray.GetIndex = AtomicArray.GetIndex :: any
RestrictedAtomicArray.GetLength = AtomicArray.GetLength :: any

function AtomicArray.RestrictedAccess<T>(self: AtomicArray<T>): RestrictedAtomicArray<T>
	local restricted = table.clone(RestrictedAtomicArray) :: RestrictedAtomicArray<T>
	restricted._reference = self._reference
	restricted._event = self._event
	return restricted
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: { T })
		assert(type(initial) == "table", "Initial can only be a table.")

		local atom = table.clone(AtomicArray) :: AtomicArray<T>
		atom._reference = table.clone(initial)
		atom._event = Signal.new() :: Signal.Signal<{ [number]: true? }, { T }, { T }>
		return atom
	end,
}
