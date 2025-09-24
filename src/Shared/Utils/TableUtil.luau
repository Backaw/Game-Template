local TableUtil = {}

type Dict = { [any]: any }
export type Parent = { [any]: { [any]: any } }

function TableUtil.deepClone<T>(tbl: T): T
	local clone = {}

	for i, v in tbl do
		clone[i] = typeof(v) == "table" and TableUtil.deepClone(v) or v
	end

	return clone
end

function TableUtil.shallowClone<T>(tbl: T): T
	local clone = {} :: T

	for i, v in pairs(tbl) do
		clone[i] = v
	end

	return clone
end

function TableUtil.deepUnion<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			if typeof(v) == "table" and tbl1[i] then
				if typeof(tbl1[i]) == "table" then
					TableUtil.deepUnion(tbl1[i], v)
				else
					tbl1[i] = v
				end
			else
				tbl1[i] = v
			end
		end
	end

	return tbl1
end

function TableUtil.shallowUnion<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			tbl1[i] = v
		end
	end

	return tbl1
end

function TableUtil.equals(tbl1: Dict, tbl2: Dict?)
	if not tbl2 then
		return false
	end

	for k, v in tbl1 do
		if typeof(v) == "table" then
			if not TableUtil.equals(v, tbl2[k]) then
				return false
			end
		else
			if v ~= tbl2[k] then
				return false
			end
		end
	end

	for k, v in tbl2 do
		if typeof(v) == "table" then
			if not TableUtil.equals(v, tbl1[k]) then
				return false
			end
		else
			if v ~= tbl1[k] then
				return false
			end
		end
	end

	return true
end

-- Only keeps the differences
function TableUtil.deepNegate<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			if typeof(v) == "table" then
				if typeof(tbl1[i]) == "table" then
					if TableUtil.length(TableUtil.deepNegate(tbl1[i], v)) == 0 then
						tbl1[i] = nil
					end
				else
					tbl1[i] = v
				end
			elseif tbl1[i] == v then
				-- print("TO NIL", i)
				tbl1[i] = nil
			else
				tbl1[i] = v
			end
		end
	end

	return tbl1
end

-- Only keeps the differences
function TableUtil.deepSubtract<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			if typeof(v) == "table" then
				if typeof(tbl1[i]) == "table" then
					if TableUtil.length(TableUtil.deepNegate(tbl1[i], v)) == 0 then
						tbl1[i] = nil
					end
				else
					tbl1[i] = v
				end
			elseif tbl1[i] == v then
				-- print("TO NIL", i)
				tbl1[i] = nil
			else
				tbl1[i] = v
			end
		end
	end

	return tbl1
end

function TableUtil.shallowNegate<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			if tbl1[i] == v then
				tbl1[i] = nil
			else
				tbl1[i] = v
			end
		end
	end

	return tbl1
end

function TableUtil.shallowSubtract<T>(tbl1: T, tbl2: T?)
	if tbl2 then
		for i, v in tbl2 do
			if tbl1[i] == v then
				tbl1[i] = nil
			end
		end
	end

	return tbl1
end

--[[
    Returns how many key value   are in a table
]]
function TableUtil.length(tbl: Dict): number
	local length = 0
	for _, _ in tbl do
		length += 1
	end

	return length
end

--[[
    Returns a random value in a table
]]
function TableUtil.getRandom<K, V>(tbl: { [K]: V }): (K, V)
	local selection = math.random(1, TableUtil.length(tbl))
	local index = 1

	for k, v in tbl do
		if index == selection then
			return k, v
		end
		index += 1
	end

	return nil, nil
end

--[[
    Returns an array of dictionary keys
]]
function TableUtil.getKeys<T>(tbl: T): { keyof<T> }
	local returning = {}

	for k in pairs(tbl) do
		table.insert(returning :: { typeof(k) }, k)
	end

	return returning
end

--[[
    Fips key, value
]]
function TableUtil.flipKeyValue<Dict>(tbl: Dict): Dict
	local returning = {}

	for k, v in tbl do
		returning[v] = k
	end

	return returning
end

--[[
    Returns the corresponding key of the first instance of a value(searchingFor: any) found in a table
]]
function TableUtil.find<T>(tbl: T, searchingFor: any): keyof<T>?
	for k, value in pairs(tbl) do
		if searchingFor == value then
			return k :: keyof<T>
		end
	end

	return nil
end

--[[
    Returns the corresponding key of the first instance of a value (searchingFor: any) found in a table,
    including deep/nested tables.
]]
function TableUtil.deepFind<T>(tbl: T, searchingFor: any): keyof<T>
	for k, value in tbl do
		if searchingFor == value then
			return k
		elseif type(value) == "table" then
			local result = TableUtil.deepFind(value, searchingFor)
			if result then
				return result
			end
		end
	end
end

--[[
    Returns the number instances of a value found in a table
]]
function TableUtil.tally(tbl: Dict, searchingFor: any): number
	local count = 0
	for _, value in tbl do
		if searchingFor == value then
			count += 1
		end
	end
	return count
end

--[[
    Returns an array of keys corresponsing to instances of a value(searchingFor: any) found in a table
]]
function TableUtil.findAll<T>(tbl: T, needle: any): { keyof<T> }
	local returning = {}

	for k, value in tbl do
		if needle == value then
			table.insert(returning, k)
		end
	end

	return returning
end

function TableUtil.findFromChildProperty<T>(tbl: { [any]: T }, property: keyof<T>, identifier: any): keyof<T>
	for i, v in tbl do
		if v[property] == identifier then
			return i
		end
	end

	return nil
end

function TableUtil.getProperties<K, V, P>(tbl: { [K]: any }, property: V): { [K]: P }
	local returning = {}

	for k, v in tbl do
		returning[k] = v[property]
	end

	return returning
end

function TableUtil.toArray(tbl: Dict): { any }
	local returning = {}

	for _, v in pairs(tbl) do
		table.insert(returning, v)
	end

	return returning
end

function TableUtil.isEmpty(tbl: Dict)
	for _ in tbl do
		return false
	end

	return true
end

-- Checks that two tables share the same values
function TableUtil.shallowEquals<T>(tbl1: T, tbl2: T?)
	if not tbl1 or not tbl2 then
		return false
	end

	for _, v in pairs(tbl1) do
		if not TableUtil.find(tbl2, v) then
			return false
		end
	end

	for _, v in pairs(tbl2) do
		if not TableUtil.find(tbl1, v) then
			return false
		end
	end

	return true
end

function TableUtil.maxIndex(tbl)
	local max = 0
	for k in tbl do
		local i = tonumber(k)
		if i then
			max = math.max(i, max)
		end
	end

	return max
end

function TableUtil.print(tbl, indent: number?)
	indent = indent or 0
	local spaces = string.rep(" ", indent)

	for key, value in tbl do
		if type(value) == "table" then
			print(spaces .. tostring(key) .. ":")
			TableUtil.print(value, indent + 4)
		else
			print(spaces .. tostring(key) .. ": " .. tostring(value))
		end
	end
end

function TableUtil.removeIfFound(tbl, value: any)
	local index = table.find(tbl, value)
	if index then
		table.remove(tbl, value)
	end
end

return TableUtil
