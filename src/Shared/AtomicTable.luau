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
type GenericTable = { [any]: any }

type AtomicMember = {
	_atomicState: true,
	Get: (self: AtomicMember) -> any,
	Connect: (self: AtomicMember, handler: (...any) -> ()) -> Signal.Connection<any>,
}

export type AtomicTable<T> = {
	_atomicState: true,
	Set: (self: AtomicTable<T>, new: T) -> (),
	SetIndex: (self: AtomicTable<T>, index: keyof<T>, value: any?) -> (),
	Update: (self: AtomicTable<T>, updater: (current: T) -> T) -> (),
	Subscribe: (self: AtomicTable<T>, handler: TableChangeHandler<T>) -> TableConnection<T>,
	Connect: (self: AtomicTable<T>, handler: TableChangeHandler<T>) -> TableConnection<T>,
	Compare: (self: AtomicTable<T>, index: keyof<T>, compareValue: any) -> boolean,
	Get: (self: AtomicTable<T>) -> T,
	GetIndex: (self: AtomicTable<T>, index: keyof<T>) -> any,
	RestrictedAccess: (self: AtomicTable<T>) -> RestrictedAtomicTable<T>,
	Destroy: (self: AtomicTable<T>) -> (),
}

export type RestrictedAtomicTable<T> = {
	_atomicState: true,
	Subscribe: (self: RestrictedAtomicTable<T>, handler: TableChangeHandler<T>) -> TableConnection<T>,
	Connect: (self: RestrictedAtomicTable<T>, handler: TableChangeHandler<T>) -> TableConnection<T>,
	Compare: (self: RestrictedAtomicTable<T>, index: keyof<T>, compareValue: any) -> boolean,
	Get: (self: RestrictedAtomicTable<T>) -> T,
	GetIndex: (self: RestrictedAtomicTable<T>, index: keyof<T>) -> any,
}

type SharedAtomicTableStorage<T> = {
	_staticMembers: T,
	_atomicMembers: { [any]: AtomicMember },
	_event: Signal.Signal<{ [keyof<T>]: true? }, T, T>,
}

type InternalAtomicTable<T> = AtomicTable<T> & SharedAtomicTableStorage<T> & {
	_atomicConnections: { Signal.Connection<any> },
}

type InternalRestrictedAtomicTable<T> = RestrictedAtomicTable<T> & SharedAtomicTableStorage<T>

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function isAtomic(value: unknown): boolean
	return type(value) == "table" and (value :: GenericTable)._atomicState == true
end

local function keysOf<T>(t: T): { [keyof<T>]: true? }
	local keys = {}
	for k in pairs(t) do
		keys[k :: keyof<T>] = true
	end
	return keys
end

local function buildSnapshot<T>(self: SharedAtomicTableStorage<T>): T
	local snapshot = TableUtil.deepClone(self._staticMembers) :: GenericTable
	for k, member in self._atomicMembers do
		snapshot[k] = member:Get()
	end
	return snapshot :: T
end

local function buildCurrentView<T>(self: SharedAtomicTableStorage<T>): T
	local view: GenericTable = table.clone(self._staticMembers)
	for k, member in self._atomicMembers do
		view[k] = member:Get()
	end
	return view :: T
end

local function handleChange<T>(self: SharedAtomicTableStorage<T>, old: T, new: T)
	local difference = TableUtil.difference(old, new)
	if next(difference :: any) == nil then
		return
	end
	self._event:Fire(keysOf(difference), new, old)
end

-------------------------------------------------------------------------------
-- PROTOTYPE
-------------------------------------------------------------------------------

local AtomicTable = {}
AtomicTable._atomicState = true

function AtomicTable.Set<T>(self: InternalAtomicTable<T>, new: T)
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

function AtomicTable.SetIndex<T>(self: InternalAtomicTable<T>, index: keyof<T>, value: any?)
	assert(not self._atomicMembers[index], "Cannot use SetIndex on an atomic member")

	local old = buildSnapshot(self);
	(self._staticMembers :: GenericTable)[index] = value
	handleChange(self, old, buildCurrentView(self))
end

function AtomicTable.Update<T>(self: InternalAtomicTable<T>, updater: (current: T) -> T)
	local old = buildSnapshot(self)
	for k, v in updater(self._staticMembers) :: GenericTable do
		if not self._atomicMembers[k] then
			(self._staticMembers :: GenericTable)[k] = v
		end
	end
	handleChange(self, old, buildCurrentView(self))
end

function AtomicTable.Subscribe<T>(self: SharedAtomicTableStorage<T>, handler: TableChangeHandler<T>)
	local snapshot = buildSnapshot(self)
	return self._event:Subscribe(handler, keysOf(snapshot), snapshot, {})
end

function AtomicTable.Connect<T>(self: SharedAtomicTableStorage<T>, handler: TableChangeHandler<T>)
	return self._event:Connect(handler)
end

function AtomicTable.Compare<T>(self: SharedAtomicTableStorage<T>, index: keyof<T>, compareValue: any)
	if self._atomicMembers[index] then
		return self._atomicMembers[index]:Get() == compareValue
	end
	return (self._staticMembers :: GenericTable)[index] == compareValue
end

function AtomicTable.GetIndex<T>(self: SharedAtomicTableStorage<T>, index: keyof<T>)
	if self._atomicMembers[index] then
		return self._atomicMembers[index]:Get()
	end
	local value = (self._staticMembers :: GenericTable)[index] :: any
	if type(value) == "table" then
		value = TableUtil.deepClone(value)
	end
	return value
end

function AtomicTable.Get<T>(self: SharedAtomicTableStorage<T>)
	return buildSnapshot(self)
end

function AtomicTable.Destroy<T>(self: InternalAtomicTable<T>)
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
RestrictedAtomicTable.Subscribe = AtomicTable.Subscribe
RestrictedAtomicTable.Connect = AtomicTable.Connect
RestrictedAtomicTable.Compare = AtomicTable.Compare
RestrictedAtomicTable.Get = AtomicTable.Get
RestrictedAtomicTable.GetIndex = AtomicTable.GetIndex

function AtomicTable.RestrictedAccess<T>(self: InternalAtomicTable<T>): RestrictedAtomicTable<T>
	local restricted = table.clone(RestrictedAtomicTable) :: InternalRestrictedAtomicTable<T>
	restricted._staticMembers = self._staticMembers
	restricted._atomicMembers = self._atomicMembers
	restricted._event = self._event
	return restricted
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: T): AtomicTable<T>
		assert(type(initial) == "table", "Initial can only be a table.")

		local atom = table.clone(AtomicTable) :: InternalAtomicTable<T>

		atom._atomicMembers = {}
		atom._atomicConnections = {}

		local plainInitial: GenericTable = {}
		for k, v in initial :: GenericTable do
			if isAtomic(v) then
				atom._atomicMembers[k] = v :: AtomicMember
			else
				plainInitial[k] = v
			end
		end

		atom._staticMembers = TableUtil.deepClone(plainInitial) :: T
		atom._event = Signal.new() :: Signal.Signal<{ [keyof<T>]: true? }, T, T>

		for k, member in atom._atomicMembers do
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
