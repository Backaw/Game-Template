--!strict
local QuestService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Signal = require(ReplicatedStorage.Shared.Signal)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local QuestConstants = require(ReplicatedStorage.Shared.Quests.QuestConstants)
local QuestUtil = require(ReplicatedStorage.Shared.Quests.QuestUtil)
local PlayerDataService = require(ServerStorage.Server.Data.PlayerDataService)
local GameAnalyticsService = require(ServerStorage.Server.GameAnalyticsService)
local PlayersService = require(ServerStorage.Server.PlayersService)

-------------------------------------------------------------------------------
-- PRIVATE MEMBERS
-------------------------------------------------------------------------------

local statToQuest: { [string]: { QuestConstants.Quest } } = {}

-------------------------------------------------------------------------------
-- PUBLIC MEMBERS
-------------------------------------------------------------------------------

QuestService.QuestCompleted = Signal.new() :: Signal.Signal<Player, QuestConstants.Quest>
QuestService.Stats = QuestConstants.Stats

-------------------------------------------------------------------------------
-- PRIVATE METHODS
-------------------------------------------------------------------------------

local function checkCompletion(player: Player, stat: QuestConstants.Stat)
	local progress = QuestService.getStat(player, stat)
	local quests = statToQuest[stat]
	if quests then
		for _, quest in quests do
			local name = quest.Name

			-- CONTINUE: Quest has already been completed
			local completedAddress = ("Quests.Completed.%s"):format(name)
			if PlayerDataService.get(player, completedAddress) then
				continue
			end

			-- CONTINUE: Quest not complete yet
			local validator = quest.Validator
			local goal = quest.Goal

			if typeof(progress) == "table" then
				if validator then
					if validator(progress) < goal then
						continue
					elseif TableUtil.length(progress) < goal then
						continue
					end
				end
			else
				if progress < goal then
					continue
				end
			end

			QuestService.completeQuest(player, name)
		end
	end
end

-------------------------------------------------------------------------------
-- PUBLIC METHODS
-------------------------------------------------------------------------------

function QuestService.getStat(player: Player, stat: QuestConstants.Stat)
	return QuestUtil.getStat(stat, player)
end

function QuestService.incrementStat(player: Player, stat: QuestConstants.Stat, addend: number | string)
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

function QuestService.completeQuest(player: Player, questName: string)
	local completedAddress = ("Quests.Completed.%s"):format(questName)
	if PlayerDataService.get(player, completedAddress) then
		return
	end

	PlayerDataService.set(player, completedAddress, true, "QuestCompleted", {
		Name = questName,
	})

	QuestService.QuestCompleted:Fire(player, QuestConstants.Quests[questName])
	GameAnalyticsService.addEvent("DesignEvent", player.UserId, {
		eventId = ("%s:%s"):format("QuestCompleted", questName),
	})
end

QuestService.loadPlayer = PlayersService.promisifyLoader(function(player)
	for stat in QuestConstants.DefaultStats do
		checkCompletion(player, stat)
	end
end, "Quests")

-------------------------------------------------------------------------------
-- LOGIC
-------------------------------------------------------------------------------

for _, quest in QuestConstants.Quests do
	local stat = quest.Stat
	if stat then
		statToQuest[stat] = statToQuest[stat] or {}
		table.insert(statToQuest[stat], quest)
	end
end

return QuestService
