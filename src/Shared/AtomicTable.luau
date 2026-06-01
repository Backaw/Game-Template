--!strict
-- Table-based reactive state container
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

type GenericTable = { [any]: any }

export type AtomicTable<T> = {
	_atomicState: true,
	_staticMembers: T,
	_atomicMembers: GenericTable,
	_atomicConnections: { any },
	_event: Signal.Signal<{ [keyof<T>]: true? }, T, T>,
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
	_atomicState: true,
	_staticMembers: T,
	_atomicMembers: GenericTable,
	_event: Signal.Signal<{ [keyof<T>]: true? }, T, T>,
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
	GetIndex: GetIndexMethod<T>,
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function isAtomic(value: any): boolean
	return type(value) == "table" and value._atomicState == true
end

local function keysOf<T>(t: T): { [keyof<T>]: true? }
	local keys = {}
	for k in pairs(t) do
		keys[k :: keyof<T>] = true
	end
	return keys
end

-- Deep-cloned snapshot for external consumers (Get, Subscribe, old state)
local function buildSnapshot<T>(self: AtomicTable<T>): T
	local snapshot = TableUtil.deepClone(self._staticMembers) :: GenericTable
	for k, member in self._atomicMembers do
		snapshot[k] = member:Get()
	end
	return snapshot :: T
end

-- Shallow merge for event firing (no deep clone)
local function buildCurrentView<T>(self: AtomicTable<T>): T
	local view: GenericTable = table.clone(self._staticMembers)
	for k, member in self._atomicMembers do
		view[k] = member:Get()
	end
	return view :: T
end

local function handleChange<T>(self: AtomicTable<T>, old: T, new: T)
	local difference = TableUtil.difference(old, new)
	if next(difference) == nil then return end
	self._event:Fire(keysOf(difference), new, old)
end

-------------------------------------------------------------------------------
-- PROTOTYPE
-------------------------------------------------------------------------------

local AtomicTable = {}
AtomicTable._atomicState = true

function AtomicTable.Set<T>(self: AtomicTable<T>, new: T)
	assert(type(new) == "table", "Set only accepts a table for new")

	local old = buildSnapshot(self)
	table.clear(self._staticMembers :: GenericTable)
	for k, v in new :: GenericTable do
		if not self._atomicMembers[k] then
			(self._staticMembers :: GenericTable)[k] = v
		end
	end
	handleChange(self, old, buildCurrentView(self))
end

function AtomicTable.SetIndex<T>(self: AtomicTable<T>, index: keyof<T>, value: any?)
	assert(not self._atomicMembers[index], "Cannot use SetIndex on an atomic member")

	local old = buildSnapshot(self);
	(self._staticMembers :: GenericTable)[index] = value
	handleChange(self, old, buildCurrentView(self))
end

function AtomicTable.Update<T>(self: AtomicTable<T>, updater: (current: T) -> T)
	local old = buildSnapshot(self)
	for k, v in updater(self._staticMembers) :: GenericTable do
		if not self._atomicMembers[k] then
			(self._staticMembers :: GenericTable)[k] = v
		end
	end
	handleChange(self, old, buildCurrentView(self))
end

function AtomicTable.Subscribe<T>(self: AtomicTable<T>, handler: TableChangeHandler<T>)
	local snapshot = buildSnapshot(self)
	return self._event:Subscribe(handler, keysOf(snapshot), snapshot, {})
end

function AtomicTable.Connect<T>(self: AtomicTable<T>, handler: TableChangeHandler<T>)
	return self._event:Connect(handler)
end

function AtomicTable.Compare<T>(self: AtomicTable<T>, index: keyof<T>, compareValue: any)
	if self._atomicMembers[index] then
		return self._atomicMembers[index]:Get() == compareValue
	end
	return (self._staticMembers :: GenericTable)[index] == compareValue
end

function AtomicTable.GetIndex<T>(self: AtomicTable<T>, index: keyof<T>)
	if self._atomicMembers[index] then
		return self._atomicMembers[index]:Get()
	end
	local value = (self._staticMembers :: GenericTable)[index] :: any
	if type(value) == "table" then
		value = TableUtil.deepClone(value)
	end
	return value
end

function AtomicTable.Get<T>(self: AtomicTable<T>)
	return buildSnapshot(self)
end

function AtomicTable.Destroy<T>(self: AtomicTable<T>)
	for _, conn in self._atomicConnections do
		conn:Disconnect()
	end
	self._event:Destroy()
	self._staticMembers = nil :: any
end

-------------------------------------------------------------------------------
-- RESTRICTED PROTOTYPE
-------------------------------------------------------------------------------

local RestrictedAtomicTable = {}
RestrictedAtomicTable._atomicState = true
RestrictedAtomicTable.Subscribe = AtomicTable.Subscribe :: any
RestrictedAtomicTable.Connect = AtomicTable.Connect :: any
RestrictedAtomicTable.Compare = AtomicTable.Compare :: any
RestrictedAtomicTable.Get = AtomicTable.Get :: any
RestrictedAtomicTable.GetIndex = AtomicTable.GetIndex :: any

function AtomicTable.RestrictedAccess<T>(self: AtomicTable<T>): RestrictedAtomicTable<T>
	local restricted = table.clone(RestrictedAtomicTable) :: RestrictedAtomicTable<T>
	restricted._staticMembers = self._staticMembers
	restricted._atomicMembers = self._atomicMembers
	restricted._event = self._event
	return restricted
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: T)
		assert(type(initial) == "table", "Initial can only be a table.")

		local atom = table.clone(AtomicTable) :: AtomicTable<T>

		-- Separate atomic members from plain values
		atom._atomicMembers = {}
		atom._atomicConnections = {}

		local plainInitial: GenericTable = {}
		for k, v in initial :: GenericTable do
			if isAtomic(v) then
				atom._atomicMembers[k] = v
			else
				plainInitial[k] = v
			end
		end

		atom._staticMembers = TableUtil.deepClone(plainInitial) :: T
		atom._event = Signal.new() :: Signal.Signal<{ [keyof<T>]: true? }, T, T>

		-- Track changes from each atomic member and propagate them
		for k, member in atom._atomicMembers do
			-- AtomicValue fires (new, old); AtomicTable/Array fire (changed, new, old)
			-- In all cases the last two args are the new and old member values
			local conn = member:Connect(function(...)
				local args = { ... }
				local oldMemberVal = args[#args]
				local newView = buildCurrentView(atom)
				local oldView = table.clone(newView) :: GenericTable
				oldView[k] = oldMemberVal
				atom._event:Fire({ [k] = true } :: { [keyof<T>]: true? }, newView, oldView :: T)
			end)
			table.insert(atom._atomicConnections, conn)
		end

		return atom
	end,

	isAtomic = isAtomic,
}
