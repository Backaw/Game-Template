--!strict

--[[
	ObjectPool

	Reuses objects instead of creating/destroying them on every use,
	reducing GC pressure in hot code paths like particle systems.

	Usage:
		local pool = ObjectPool.new(
			function() return Instance.new("Frame") end,  -- creates a new object
			function(obj) obj.Visible = false end,        -- resets & hides when returned
			20                                            -- optional: pre-warm count
		)

		local obj = pool:Get()   -- borrows from pool, or creates if empty
		-- ... use obj ...
		pool:Return(obj)         -- resets and returns to pool for reuse
		local active = pool:GetActive() -- objects currently borrowed
]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type Class<T> = {
	Get: (self: Class<T>) -> T,
	Return: (self: Class<T>, object: T) -> (),
	GetActive: (self: Class<T>) -> { T },
	Destroy: (self: Class<T>, destructor: ((object: T) -> ())?) -> (),
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function defaultReset(object: any)
	object.Parent = nil
end

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

function ObjectPool.new<T>(constructor: () -> T, reset: ((object: T) -> ())?, initialSize: number?): Class<T>
	local self = setmetatable({
		_constructor = constructor,
		_reset = reset or defaultReset,
		_pool = {} :: { T },
		_all = {} :: { T },
	}, ObjectPool)

	if initialSize then
		for _ = 1, initialSize do
			local obj = constructor()
			table.insert(self._all, obj)
			self._reset(obj)
			table.insert(self._pool, obj)
		end
	end

	return self :: any
end

function ObjectPool.Get(self: any)
	local pool = self._pool
	if #pool > 0 then
		return table.remove(pool)
	end
	local obj = self._constructor()
	table.insert(self._all, obj)
	return obj
end

function ObjectPool.Return(self: any, object: any)
	self._reset(object)
	table.insert(self._pool, object)
end

function ObjectPool.GetActive(self: any)
	local pooled: { [any]: boolean } = {}
	for _, object in self._pool do
		pooled[object] = true
	end

	local active = {}
	for _, object in self._all do
		if not pooled[object] then
			table.insert(active, object)
		end
	end

	return active
end

function ObjectPool.Destroy(self: any, destructor: ((object: any) -> ())?)
	for _, obj in self._all do
		if destructor then
			destructor(obj)
		else
			obj:Destroy()
		end
	end
	table.clear(self._all)
	table.clear(self._pool)
end

return ObjectPool
