local QuestService = {}

local ServerScriptService = game:GetService("ServerScriptService")
local Paths = require(ServerScriptService.Paths)
local Signal = require(Paths.Shared.Signal)
local PlayerDataService = require(Paths.Services.Data.PlayerDataService)
local GameAnalyticsService = require(Paths.Services.GameAnalyticsService)
local TableUtil = require(Paths.Shared.Utils.TableUtil)
local QuestConstants = require(Paths.Shared.Quests.QuestConstants)
local PlayersService = require(Paths.Services.PlayersService)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------
local statToQuest: { [string]: { QuestConstants.Quest } } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------
QuestService.QuestCompleted = Signal.new() --> (player : Player, category : string, quest : QuestConstants.Quest )

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------
local function checkCompletion(player: Player, stat: string)
	local progress = PlayerDataService.get(player, ("Quests.Stats.%s"):format(stat))
	local quests = statToQuest[stat]
	if quests then
		for _, quest in  (quests) do
			local name = quest.Name

			-- CONTINUE: Quest has already been completed
			local completedAddress = ("Quests.Completed.%s"):format(name)
			if PlayerDataService.get(player, completedAddress) then
				continue
			end

			-- CONTINUE: Quest not complete yet
			local validator = quest.Validator
			local goal = quest.Goal
			if validator then
				if validator(progress) < goal then
					continue
				end
			elseif typeof(progress) == "table" then
				if TableUtil.length(progress) < goal then
					continue
				end
			else
				if progress < goal then
					continue
				end
			end

			PlayerDataService.set(player, completedAddress, true, "QuestCompleted", {
				Name = name,
			})

			QuestService.QuestCompleted:Fire(player, quest)
			GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
				eventId = ("%s:%s:%s"):format("QuestCompleted", "Persistent", name), -- Don't remove the persisitent part
			})
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------
function QuestService.incrementStat(player: Player, stat: string, addend: number | string)
	local statAddress = ("Quests.Stats.%s"):format(stat)
	local statChangedMetadata = {
		Stat = stat,
		Addend = addend,
	}

	if typeof(addend) == "number" then
		PlayerDataService.increment(player, statAddress, addend, "QuestStatChanged", statChangedMetadata)
	elseif typeof(addend) == "string" then
		PlayerDataService.increment(player, statAddress .. "." .. addend, 1, "QuestStatChanged", statChangedMetadata)
	else
		error("Stat addend  must be a number or string")
	end

	checkCompletion(player, stat)
end

QuestService.loadPlayer = PlayersService.promisifyLoader(function(player)
	for stat in  (QuestConstants.DefaultStats) do
		checkCompletion(player, stat)
	end
end, "Quests")

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------
for _, quest in  (QuestConstants.Quests) do
	local stat = quest.Stat
	statToQuest[stat] = statToQuest[stat] or {}
	table.insert(statToQuest[stat], quest)
end

return QuestService
