--!strict
local UnitTester = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameUtil = require(ReplicatedStorage.Shared.Game.GameUtil)
local StringUtil = require(ReplicatedStorage.Shared.Utils.StringUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local SUFFIX = ".spec"

function UnitTester.run(directory: Instance)
	-- RETURN: No point running unit tests in QA or Dev
	if not GameUtil.isDev() then
		return
	end

	local outputs: { [string]: { string } } = {}

	for _, descedant in (directory:GetDescendants()) do
		if
			descedant:IsA("ModuleScript")
			and StringUtil.endsWith(descedant.Name, SUFFIX)
			and not descedant:IsDescendantOf(ReplicatedStorage.Shared.Packages)
		then
			local module = require(descedant) :: any

			local success, issues
			if typeof(module) == "function" then
				success, issues = pcall(module :: any)
				if success then
					if typeof(issues) ~= "table" then
						issues = { "Test did not return an array" }
					end
				else
					issues = { issues }
				end
			else
				issues = { "Test module did not return a function" }
			end

			outputs[descedant.Name:gsub(SUFFIX, "")] = issues
		end
	end

	for source, issues in outputs do
		if TableUtil.length(issues) > 0 then
			local output = ("[%s]"):format(source)
			for _, issue in issues do
				output = output .. ("\n\t%s"):format(issue)
			end

			warn(output)
		end
	end
end

return UnitTester
