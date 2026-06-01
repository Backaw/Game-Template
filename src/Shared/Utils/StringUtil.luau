--!strict
local StringUtil = {}

function StringUtil.charAt(str: string, position: number)
	return str:sub(position, position)
end

function StringUtil.getChars(str: string)
	local chars = {}
	for i = 1, #str do
		local char = str:sub(i, i)
		table.insert(chars, char)
	end

	return chars
end

function StringUtil.endsWith(str: string, ending: string)
	return string.find(str, ending .. "$") ~= nil
end

function StringUtil.toCamelCase(str: string)
	str = str:gsub("[%-_]+([^%-_])", function(s)
		return string.upper(s)
	end)
	return str:sub(1, 1):lower() .. (str:sub(2))
end

function StringUtil.toPascalCase(str: string)
	str = str:gsub("(%l)(%u)", "%1 %2")
	str = str:gsub("[^%w]+", " ")
	local result = ""
	for word in str:gmatch("%w+") do
		result = result .. word:sub(1, 1):upper() .. word:sub(2):lower()
	end
	return result
end

function StringUtil.toSnakeCase(str: string)
	local result = ""
	str = str:gsub("_", " "):gsub("%p", "")
	for word in string.gmatch(str, "[%w]+") do
		result = result .. (if #result == 0 then "" else "_") .. word:sub(1, 1):upper() .. word:sub(2, #word):lower()
	end

	return result
end

function StringUtil.seperateSnakeCase(str: string)
	local result = ""
	for word in string.gmatch(str, "[%u%d]+[%l%d]*") do
		result = result .. (if #result == 0 then "" else " ") .. word:sub(1, 1):upper() .. word:sub(2):lower()
	end

	return result
end

function StringUtil.splitOnCaps(string: string)
	local parts = {}
	for word in string.gmatch(string, "%u[^%u]*") do
		table.insert(parts, word)
	end
	return table.concat(parts)
end

function StringUtil.levenshteinDistance(str1: string, str2: string)
	if str1 == str2 then
		return 0
	end
	if string.len(str1) == 0 then
		return string.len(str2)
	end
	if string.len(str2) == 0 then
		return string.len(str1)
	end
	if string.len(str1) < string.len(str2) then
		str1, str2 = str2, str1
	end

	local d = {}

	for i = 1, #str1 + 1 do
		d[i] = { i - 1 }
	end

	for j = 1, #str2 + 1 do
		d[1][j] = j - 1
	end

	local cost = 0
	for i = 2, #str1 + 1 do
		for j = 2, #str2 + 1 do
			if string.sub(string.lower(str1), i - 1, i - 1) == string.sub(string.lower(str2), j - 1, j - 1) then
				cost = 0
			else
				cost = 2
			end

			d[i][j] = math.min(d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost)
		end
	end

	return d[#str1 + 1][#str2 + 1]
end

function StringUtil.commafiedNumber(number: string | number)
	local _, _, minus, int, fraction = tostring(number):find("([-]?)(%d+)([.]?%d*)")

	-- reverse the int-string and append a comma to all blocks of 3 digits
	int = (int or ""):reverse():gsub("(%d%d%d)", "%1,")

	-- reverse the int-string back remove an optional comma and put the
	-- optional minus and fractional part back
	return (minus or "") .. int:reverse():gsub("^,", "") .. (fraction or "")
end

function StringUtil.getCompactNumber(number: number)
	local suffixes = { "K", "M", "B", "T", "Q", "Qu", "S", "Se", "O", "N", "D" }

	for i = #suffixes, 1, -1 do
		local v = math.pow(10, i * 3)
		if number >= v then
			local returning = ("%.3f"):format(number / v)
			returning = returning:sub(1, #returning - 1):gsub("%.", ".")
			return returning:gsub("0+$", "", 2):gsub("%.$", "") .. suffixes[i]
		end
	end
	return tostring(number)
end

function StringUtil.startsWith(str: string, starting: string)
	return string.sub(str, 1, string.len(starting)) == starting
end

function StringUtil.getOrdinalNumeral(number: number)
	if number == 1 then
		return "1st"
	elseif number == 2 then
		return "2nd"
	elseif number == 3 then
		return "3rd"
	else
		return number .. "th"
	end
end

function StringUtil.byte(str: string)
	local score = 0

	-- Loop through each character in the string
	for i = 1, #str do
		local char = str:sub(i, i) -- Get the current character

		-- Add a score based on the letter's position in the alphabet (A = 1, B = 2, etc.)
		local letterScore = string.byte(char) -- - string.byte("A") + 1
		score = score + letterScore
	end

	return score
end

function StringUtil.capLength(str: string, maxLength: number)
	return str:sub(1, maxLength)
end

return StringUtil
