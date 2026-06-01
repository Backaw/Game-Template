--!strict
-- Single-value reactive state container
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type ValueConnection<T> = Signal.Connection<T, T?>
type ValueChangeHandler<T> = (new: T, old: T?) -> ()

type SubscribeMethod<T> = (self: any, handler: ValueChangeHandler<T>) -> ValueConnection<T>
type ConnectMethod<T> = (self: any, handler: ValueChangeHandler<T>) -> ValueConnection<T>
type CompareMethod<T> = (self: any, compareValue: T) -> boolean
type GetMethod<T> = (self: any) -> T

export type AtomicValue<T> = {
	_atomicState: true,
	_state: { value: T },
	_event: Signal.Signal<T, T>,
	Set: (self: AtomicValue<T>, new: T) -> (),
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
	RestrictedAccess: (self: AtomicValue<T>) -> RestrictedAtomicValue<T>,
	Destroy: (self: AtomicValue<T>) -> (),
}

export type RestrictedAtomicValue<T> = {
	_atomicState: true,
	_state: { value: T },
	_event: Signal.Signal<T, T>,
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
}

-------------------------------------------------------------------------------
-- PROTOTYPE
-------------------------------------------------------------------------------

local AtomicValue = {}
AtomicValue._atomicState = true

function AtomicValue.Set<T>(self: AtomicValue<T>, new: T)
	local old = self._state.value
	if new == old then
		return
	end
	self._state.value = new
	self._event:Fire(new, old)
end

function AtomicValue.Subscribe<T>(self: AtomicValue<T>, handler: ValueChangeHandler<T>)
	task.spawn(handler, self._state.value, nil)
	return self._event:Connect(handler)
end

function AtomicValue.Connect<T>(self: AtomicValue<T>, handler: ValueChangeHandler<T>)
	return self._event:Connect(handler)
end

function AtomicValue.Compare<T>(self: AtomicValue<T>, compareValue: T): boolean
	return self._state.value == compareValue
end

function AtomicValue.Get<T>(self: AtomicValue<T>): T
	return self._state.value
end

function AtomicValue.Destroy<T>(self: AtomicValue<T>)
	self._event:Destroy()
	self._state = nil :: any
end

-------------------------------------------------------------------------------
-- RESTRICTED PROTOTYPE
-------------------------------------------------------------------------------

local RestrictedAtomicValue = {}
RestrictedAtomicValue._atomicState = true
RestrictedAtomicValue.Subscribe = AtomicValue.Subscribe :: any
RestrictedAtomicValue.Connect = AtomicValue.Connect :: any
RestrictedAtomicValue.Compare = AtomicValue.Compare :: any
RestrictedAtomicValue.Get = AtomicValue.Get :: any

function AtomicValue.RestrictedAccess<T>(self: AtomicValue<T>): RestrictedAtomicValue<T>
	local restricted = table.clone(RestrictedAtomicValue) :: RestrictedAtomicValue<T>
	restricted._state = self._state
	restricted._event = self._event
	return restricted
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: T)
		local atom = table.clone(AtomicValue) :: AtomicValue<T>
		atom._state = { value = initial }
		atom._event = Signal.new() :: Signal.Signal<T, T>
		return atom
	end,
}
