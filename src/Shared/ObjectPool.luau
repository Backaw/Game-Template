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

		local obj = pool:Get() -- borrows from pool, or creates if empty
		-- ... use obj ...
		pool:Return(obj)         -- resets and returns to pool for reuse
		local active = pool:GetActive() -- objects currently borrowed
]]

local ObjectPool = {}
ObjectPool.__index = ObjectPool

-------------------------------------------------------------------------------
-- TYPES
-------------------------------------------------------------------------------

export type ObjectPool<T> = {
	Get: (self: ObjectPool<T>) -> T,
	Return: (self: ObjectPool<T>, object: T) -> (),
	GetActive: (self: ObjectPool<T>) -> { T },
	GetLimited: (self: ObjectPool<T>) -> T?,
	ReturnAll: (self: ObjectPool<T>) -> (),
	Destroy: (self: ObjectPool<T>, destructor: ((object: T) -> ())?) -> (),
}

type InternalClass<T> = ObjectPool<T> & {
	_constructor: () -> T,
	_reset: (object: T) -> (),
	_pool: { T },
	_all: { T },
}

-------------------------------------------------------------------------------
-- PRIVATE FUNCTIONS
-------------------------------------------------------------------------------

local function defaultReset(object: Instance)
	object.Parent = nil
end

local function createObject<T>(self: InternalClass<T>): T
	local obj = self._constructor()
	table.insert(self._all, obj)
	return obj
end

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

function ObjectPool.new<T>(constructor: () -> T, reset: ((object: T) -> ())?, initialSize: number?): ObjectPool<T>
	local self = setmetatable({
		_constructor = constructor,
		_reset = reset or defaultReset,
		_pool = {} :: { T },
		_all = {} :: { T },
	}, ObjectPool) :: InternalClass<T>

	if initialSize then
		task.spawn(function()
			for _ = 1, initialSize do
				local obj = createObject(self)
				-- Same as Return: entering the free list, not handed out yet.
				self._reset(obj)
				table.insert(self._pool, obj)
			end
		end)
	end

	return self
end

function ObjectPool.Get<T>(self: InternalClass<T>): T
	local pool = self._pool
	if #pool > 0 then
		return table.remove(pool) :: T
	end
	-- Fresh objects are for immediate use; reset only when stashed (warm-up / Return).
	return createObject(self)
end

function ObjectPool.GetLimited<T>(self: InternalClass<T>): T?
	local pool = self._pool
	if #pool == 0 then
		return nil
	end

	return table.remove(pool)
end

function ObjectPool.Return<T>(self: InternalClass<T>, object: T)
	self._reset(object)
	table.insert(self._pool, object)
end

function ObjectPool.ReturnAll<T>(self: InternalClass<T>)
	for _, object in self:GetActive() do
		self._reset(object)
		table.insert(self._pool, object)
	end
end

function ObjectPool.GetActive<T>(self: InternalClass<T>): { T }
	local pooled: { [T]: boolean } = {}
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

function ObjectPool.Destroy<T>(self: InternalClass<T>, destructor: ((object: T) -> ())?)
	for _, obj in self._all do
		if destructor then
			destructor(obj)
		else
			(obj :: Instance):Destroy()
		end
	end
	table.clear(self._all)
	table.clear(self._pool)
end

return ObjectPool
