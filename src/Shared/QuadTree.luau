local QuadTree = {}

export type QuadTree<T> = {
	Insert: (QuadTree: QuadTree<T>, id: T, position: Vector2) -> (),
	Remove: (QuadTree: QuadTree<T>, id: T) -> boolean,
	Update: (QuadTree: QuadTree<T>, id: T, newPosition: Vector2) -> boolean,
	Has: (QuadTree: QuadTree<T>, id: T) -> boolean,
	RadiusSearch: (QuadTree: QuadTree<T>, center: Vector2, radius: number) -> { T },
	RangeSearch: (QuadTree: QuadTree<T>, minPos: Vector2, maxPos: Vector2) -> { T },
	GetNodePosition: (QuadTree: QuadTree<T>, id: T) -> Vector2?,
	GetBounds: (QuadTree: QuadTree<T>) -> { X: NumberRange, Y: NumberRange },
	GetNodes: (QuadTree: QuadTree<T>) -> { [T]: Vector2 },
}

function QuadTree.new<T>(bounds: { X: NumberRange, Y: NumberRange }, maxCapacity: number?)
	local quadTree = {} :: QuadTree<T>

	-------------------------------------------------------------------------------
	-- PRIVATE VARIABLES
	-------------------------------------------------------------------------------
	local capacity = maxCapacity or 4
	local nodes: { [any]: Vector2 } = {}
	-- Flat id → position for O(1) Has / GetNodePosition (spatial layout stays in the tree).
	local index: { [any]: Vector2 } = {}
	local children: { any }? = nil -- private children
	local nodeCount = 0

	local midX = (bounds.X.Min + bounds.X.Max) / 2
	local midY = (bounds.Y.Min + bounds.Y.Max) / 2

	-- Mirror for external (read) access when needed by search
	quadTree.children = nil :: any -- keep field in sync with private `children`

	-------------------------------------------------------------------------------
	-- PRIVATE FUNCTIONS
	-------------------------------------------------------------------------------
	local function getQuadrant(position: Vector2): number
		if position.X < midX then
			return position.Y < midY and 1 or 3 -- nw or sw
		else
			return position.Y < midY and 2 or 4 -- ne or se
		end
	end

	local function getQuadrantBounds(quadrant: number): { X: NumberRange, Y: NumberRange }
		if quadrant == 1 then -- nw
			return { X = NumberRange.new(bounds.X.Min, midX), Y = NumberRange.new(bounds.Y.Min, midY) }
		elseif quadrant == 2 then -- ne
			return { X = NumberRange.new(midX, bounds.X.Max), Y = NumberRange.new(bounds.Y.Min, midY) }
		elseif quadrant == 3 then -- sw
			return { X = NumberRange.new(bounds.X.Min, midX), Y = NumberRange.new(midY, bounds.Y.Max) }
		else -- se
			return { X = NumberRange.new(midX, bounds.X.Max), Y = NumberRange.new(midY, bounds.Y.Max) }
		end
	end

	local function split()
		children = {
			QuadTree.new(getQuadrantBounds(1), capacity), -- nw
			QuadTree.new(getQuadrantBounds(2), capacity), -- ne
			QuadTree.new(getQuadrantBounds(3), capacity), -- sw
			QuadTree.new(getQuadrantBounds(4), capacity), -- se
		}
		-- keep the public field in sync so external walkers can see children
		quadTree.children = children

		for id, position in pairs(nodes) do
			local quadrant = getQuadrant(position)
			children[quadrant]:Insert(id, position)
		end

		nodes = {}
		nodeCount = 0
	end

	local function isInBounds(position: Vector2): boolean
		return position.X >= bounds.X.Min and position.X <= bounds.X.Max and position.Y >= bounds.Y.Min and position.Y <= bounds.Y.Max
	end

	local function distanceSquared(pos1: Vector2, pos2: Vector2): number
		local dx = pos1.X - pos2.X
		local dy = pos1.Y - pos2.Y
		return dx * dx + dy * dy
	end

	-------------------------------------------------------------------------------
	-- PUBLIC FUNCTIONS
	-------------------------------------------------------------------------------

	function quadTree:Insert(id, position)
		if not isInBounds(position) then
			error("Node position is outside the bounds of this quad tree")
		end

		if children then
			local quadrant = getQuadrant(position)
			children[quadrant]:Insert(id, position)
		elseif nodeCount < capacity then
			nodes[id] = position
			nodeCount += 1
		else
			split()
			local quadrant = getQuadrant(position)
			children[quadrant]:Insert(id, position)
		end

		index[id] = position
	end

	function quadTree:Remove(id)
		if children then
			for _, child in ipairs(children) do
				if child:Remove(id) then
					index[id] = nil
					return true
				end
			end
		else
			if nodes[id] then
				nodes[id] = nil
				nodeCount -= 1
				index[id] = nil
				return true
			end
		end
		return false
	end

	function quadTree:Update(id, newPosition)
		if not isInBounds(newPosition) then
			error("New position is outside the bounds of this quad tree")
		end
		if self:Remove(id) then
			self:Insert(id, newPosition)
			return true
		end
		return false
	end

	function quadTree:Has(id)
		return index[id] ~= nil
	end

	function quadTree:RadiusSearch(center, radius)
		local results = {}
		local radiusSquared = radius * radius

		local function searchNode(node)
			if not node then
				return
			end

			local nodeBounds = node:GetBounds()
			local closestX = math.max(nodeBounds.X.Min, math.min(center.X, nodeBounds.X.Max))
			local closestY = math.max(nodeBounds.Y.Min, math.min(center.Y, nodeBounds.Y.Max))

			if distanceSquared(center, Vector2.new(closestX, closestY)) > radiusSquared then
				return
			end

			if node:IsSplit() then
				-- use the accessor (or mirrored field) to walk children
				for _, child in ipairs(node:GetChildren()) do
					searchNode(child)
				end
			else
				for searchId, position in pairs(node:GetNodes()) do
					if distanceSquared(center, position) <= radiusSquared then
						table.insert(results, searchId)
					end
				end
			end
		end

		searchNode(quadTree)
		return results
	end

	function quadTree:RangeSearch(minPos, maxPos)
		local results = {}

		local function searchNode(node)
			if not node then
				return
			end
			local b = node:GetBounds()

			-- reject if separated (AABB vs AABB)
			if b.X.Min > maxPos.X or b.X.Max < minPos.X or b.Y.Min > maxPos.Y or b.Y.Max < minPos.Y then
				return
			end

			if node:IsSplit() then
				for _, child in ipairs(node:GetChildren()) do
					searchNode(child)
				end
			else
				for searchId, p in pairs(node:GetNodes()) do
					if p.X >= minPos.X and p.X <= maxPos.X and p.Y >= minPos.Y and p.Y <= maxPos.Y then
						table.insert(results, searchId)
					end
				end
			end
		end

		searchNode(quadTree)
		return results
	end

	function quadTree:GetNodePosition(id)
		return index[id]
	end

	function quadTree:GetBounds()
		return bounds
	end

	function quadTree:GetNodes()
		return nodes
	end

	-- NEW: child accessor for external walkers
	function quadTree:GetChildren()
		return children or {}
	end

	function quadTree:GetNodeCount()
		return nodeCount
	end

	function quadTree:GetTotalNodeCount()
		if children then
			local total = 0
			for _, child in ipairs(children) do
				total += child:GetTotalNodeCount()
			end
			return total
		else
			return nodeCount
		end
	end

	function quadTree:IsSplit()
		return children ~= nil
	end

	function quadTree:Clear()
		nodes = {}
		children = nil
		quadTree.children = nil -- keep mirrored field consistent
		nodeCount = 0
		table.clear(index)
	end

	return quadTree
end

return QuadTree
