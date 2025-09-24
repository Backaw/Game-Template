--!strict
local ArrayUtil = {}

type Array = { any }

--[[
    Returns the of two arrays stored in the first array(tbl1: Array). Duplicates are allowed
]]
function ArrayUtil.add(tbl1: Array, tbl2: Array): Array
	table.move(tbl2, 1, #tbl2, #tbl1 + 1, tbl1)
	return tbl1
end

function ArrayUtil.subtract(tbl: Array, subtracting: Array): Array
	for i = #tbl, 1, -1 do
		if table.find(subtracting, tbl[i]) then
			table.remove(tbl, i)
		end
	end

	return tbl
end

function ArrayUtil.clone(tbl: Array): Array
	return table.move(tbl, 1, #tbl, 1, {})
end

--[[
    Returns the union of two arrays. Duplicates are allowed.
]]
function ArrayUtil.addToClone(tbl1: Array, tbl2: Array): Array
	return ArrayUtil.add(ArrayUtil.clone(tbl1), tbl2)
end

function ArrayUtil.flip(tbl: Array): Array
	local returning = {}

	for i = #tbl, 1, -1 do
		table.insert(returning, tbl[i])
	end

	return returning
end

--[[
    Populates an empty table with the returns of a function
    Essentially Table.create without identical values
]]
function ArrayUtil.create(length: number, getValue: (number?) -> ()): Array
	local returning = {}
	for i = 1, length do
		returning[i] = getValue(i)
	end

	return returning
end

function ArrayUtil.isArray(tbl: { [any]: any }): boolean
	for k, v in tbl do
		if not tostring(k) then
			return false
		elseif typeof(k) == "table" and not ArrayUtil.isArray(v) then
			return false
		end
	end

	return true
end

function ArrayUtil.shuffle(tbl: Array)
	local returning = {}

	for _ = 1, #tbl do
		local index = math.random(1, #tbl)
		table.insert(returning, tbl[index])
		table.remove(tbl, index)
	end

	return returning
end

function ArrayUtil.transpose(matrix: { { any } }): { { any } }
	local result = {}

	for rowIndex, row in matrix do
		for colIndex, value in row do
			result[colIndex] = result[colIndex] or {}
			result[colIndex][rowIndex] = value
		end
	end

	return result
end

function ArrayUtil.merge(...: Array): Array
	local returning = {}

	for _, t in ipairs((table.pack(...))) do
		if typeof(t) == "table" then
			for _, v in ipairs(t :: { any }) do
				table.insert(returning, v)
			end
		end
	end

	return returning
end

function ArrayUtil.swapbackRemove<T>(tbl: { T }, index: number): T
	local len = #tbl
	local new = tbl[len]
	tbl[index] = new
	tbl[len] = nil
	return new
end

return ArrayUtil
