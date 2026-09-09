--!strict
-- Single-value reactive state container
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

type ValueConnection<T> = Signal.Connection<T, T?>
type ValueChangeHandler<T> = (new: T, old: T?) -> ()

export type AtomicValue<T> = {
	_atomicState: true,
	Set: (self: AtomicValue<T>, new: T) -> T,
	Subscribe: (self: AtomicValue<T>, handler: ValueChangeHandler<T>) -> ValueConnection<T>,
	Connect: (self: AtomicValue<T>, handler: ValueChangeHandler<T>) -> ValueConnection<T>,
	Wait: (self: AtomicValue<T>) -> T,
	Compare: (self: AtomicValue<T>, compareValue: T) -> boolean,
	Get: (self: AtomicValue<T>) -> T,
	RestrictedAccess: (self: AtomicValue<T>) -> RestrictedAtomicValue<T>,
	Destroy: (self: AtomicValue<T>) -> (),
}

export type RestrictedAtomicValue<T> = {
	_atomicState: true,
	Subscribe: (self: RestrictedAtomicValue<T>, handler: ValueChangeHandler<T>) -> ValueConnection<T>,
	Connect: (self: RestrictedAtomicValue<T>, handler: ValueChangeHandler<T>) -> ValueConnection<T>,
	Wait: (self: RestrictedAtomicValue<T>) -> T,
	Compare: (self: RestrictedAtomicValue<T>, compareValue: T) -> boolean,
	Get: (self: RestrictedAtomicValue<T>) -> T,
}

type SharedAtomicValueStorage<T> = {
	_state: { value: T },
	_event: Signal.Signal<T, T>,
}

type InternalAtomicValue<T> = AtomicValue<T> & SharedAtomicValueStorage<T>

type InternalRestrictedAtomicValue<T> = RestrictedAtomicValue<T> & SharedAtomicValueStorage<T>

-------------------------------------------------------------------------------
-- PROTOTYPE
-------------------------------------------------------------------------------

local AtomicValue = {}
AtomicValue._atomicState = true

function AtomicValue.Set<T>(self: InternalAtomicValue<T>, new: T)
	local old = self._state.value
	if new == old then
		return old
	end
	self._state.value = new
	self._event:Fire(new, old)

	return new
end

function AtomicValue.Subscribe<T>(self: SharedAtomicValueStorage<T>, handler: ValueChangeHandler<T>)
	task.spawn(handler, self._state.value, nil)
	return self._event:Connect(handler)
end

function AtomicValue.Connect<T>(self: SharedAtomicValueStorage<T>, handler: ValueChangeHandler<T>)
	return self._event:Connect(handler)
end

function AtomicValue.Wait<T>(self: SharedAtomicValueStorage<T>): T
	self._event:Wait()
	return self._state.value
end

function AtomicValue.Compare<T>(self: SharedAtomicValueStorage<T>, compareValue: T): boolean
	return self._state.value == compareValue
end

function AtomicValue.Get<T>(self: SharedAtomicValueStorage<T>): T
	return self._state.value
end

function AtomicValue.Destroy<T>(self: InternalAtomicValue<T>)
	self._event:Destroy()
	self._state = nil :: any
end

-------------------------------------------------------------------------------
-- RESTRICTED PROTOTYPE
-------------------------------------------------------------------------------

local RestrictedAtomicValue = {}
RestrictedAtomicValue._atomicState = true
RestrictedAtomicValue.Subscribe = AtomicValue.Subscribe
RestrictedAtomicValue.Connect = AtomicValue.Connect
RestrictedAtomicValue.Wait = AtomicValue.Wait
RestrictedAtomicValue.Compare = AtomicValue.Compare
RestrictedAtomicValue.Get = AtomicValue.Get

function AtomicValue.RestrictedAccess<T>(self: InternalAtomicValue<T>): RestrictedAtomicValue<T>
	local restricted = table.clone(RestrictedAtomicValue) :: InternalRestrictedAtomicValue<T>
	restricted._state = self._state
	restricted._event = self._event
	return restricted
end

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

return {
	new = function<T>(initial: T): AtomicValue<T>
		local atom = table.clone(AtomicValue) :: InternalAtomicValue<T>
		atom._state = { value = initial }
		atom._event = Signal.new() :: Signal.Signal<T, T>
		return atom
	end,
}
