--!strict
-- Single-atomi reactive state container
local AtomicValue = {}

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
	Set: (self: AtomicValue<T>, new: T) -> (),
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
	RestrictedAccess: (self: AtomicValue<T>) -> RestrictedAtomicValue<T>,
	Destroy: (self: AtomicValue<T>) -> (),
}

export type RestrictedAtomicValue<T> = {
	Subscribe: SubscribeMethod<T>,
	Connect: ConnectMethod<T>,
	Compare: CompareMethod<T>,
	Get: GetMethod<T>,
}

-------------------------------------------------------------------------------
-- CONSTRUCTOR
-------------------------------------------------------------------------------

function AtomicValue.new<T>(initial: T)
	local atom = {} :: AtomicValue<T>

	local atomi: T = initial
	local event = Signal.new() :: Signal.Signal<T, T>

	function atom:Set(new: T)
		local old = atomi
		if new == old then
			return
		end

		atomi = new
		event:Fire(new, old)
	end

	function atom:Subscribe(handler: (new: T, old: T) -> ())
		task.spawn(handler, atomi, nil)
		return event:Connect(handler)
	end

	function atom:Connect(handler: (new: T, old: T) -> ())
		return event:Connect(handler)
	end

	function atom:Compare(compareValue: T): boolean
		return atomi == compareValue
	end

	function atom:Get(): T
		return atomi
	end

	function atom:RestrictedAccess(): RestrictedAtomicValue<T>
		local restricted = {
			Subscribe = atom.Subscribe,
			Connect = atom.Connect,
			Compare = atom.Compare,
			Get = atom.Get,
		} :: RestrictedAtomicValue<T>

		return restricted
	end

	function atom:Destroy()
		event:Destroy()
		atomi = nil :: any
	end

	return atom
end

return AtomicValue
