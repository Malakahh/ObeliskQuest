local _, ns = ...

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("LOADING_SCREEN_DISABLED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("QUEST_POI_UPDATE")

local function UntrackAll()
	local numShowEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()

	for i = 1, numQuests do
		local questID = C_QuestLog.GetQuestIDForLogIndex(i)
		--if IsQuestWatched(i) then
			--print(C_QuestLog.GetQuestWatchType(questID))
		if C_QuestLog.GetQuestWatchType(questID) then
			C_QuestLog.RemoveQuestWatch(questID)
		end
	end
end

local function UntrackNonplayerTracked()
	local numShowEntries, numQuests = C_QuestLog.GetNumQuestLogEntries()

	for i = 1, numQuests do
		local questID = C_QuestLog.GetQuestIDForLogIndex(i)
		--if IsQuestWatched(i) and not OQ.userTrackedQuests[questID] then
		if C_QuestLog.GetQuestWatchType(questID) and not OQ.userTrackedQuests[questID] then
			C_QuestLog.RemoveQuestWatch(questID)
		end
	end
end

local function TrackByZone()
	if OQ.Options.ZoneTracking.Behaviour == "Fully Automatic" then
		UntrackAll()
	elseif OQ.Options.ZoneTracking.Behaviour == "Semi Automatic" then
		UntrackNonplayerTracked()
	end

	local currMapID = C_Map.GetBestMapForUnit("player")
	if currMapID then
		-- Two pronged approach. We track all quests that appear on the world map, and quests that appear under an appropriate header in the questlog.
		-- The reason for this is that some quests does not appear on the map but are still relevant for the zone, i.e. "Call to Arms: Tiragarde Sound" which objective is to kill 10 players.

		-- Track quests that appear as blobs on the map
		local data = C_QuestLog.GetQuestsOnMap(currMapID)
		for k,v in ipairs(data) do
			local info = C_Map.GetMapInfoAtPosition(currMapID, v.x, v.y)
			if info == nil or info.mapID == currMapID then
				C_QuestLog.AddQuestWatch(v.questID, 1)
			end
		end

		-- Track quests that appear under the zone header
		local uiMapDetails = C_Map.GetMapInfo(currMapID)
		if uiMapDetails then
			local currentMapName = uiMapDetails.name
			local i = 1
			local watchQuest = false

			while C_QuestLog.GetInfo(i) do
				local info = C_QuestLog.GetInfo(i)
				--local title, _, _, isHeader, _, _, _, questID = GetQuestLogTitle(i)

				if info.isHeader then
					if info.title == currentMapName or (ns.ZoneNameSubstitutions[currentMapName] and tContains(ns.ZoneNameSubstitutions[currentMapName], info.title)) then
						watchQuest = true
					elseif watchQuest then
						break
					end
				elseif watchQuest then
					C_QuestLog.AddQuestWatch(info.questID, 1)
				end

				i = i + 1
			end
		end
	end

	--Consider the following for tracking world quests
	--[[

	for k, task in pairs(C_TaskQuest.GetQuestsForPlayerByMapID(GetCurrentMapAreaID())) do
		if task.inProgress then
			-- track active world quests
			local questID = task.questId
			local questName = C_TaskQuest.GetQuestInfoByQuestID(questID)
			if questName then
				print(k, questID, questName)
			end
		end
	end

	]]
end

function frame:QUEST_ACCEPTED()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:ZONE_CHANGED_NEW_AREA()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:LOADING_SCREEN_DISABLED()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:QUEST_POI_UPDATE()
	if OQ.Options.ZoneTracking.Behaviour ~= "Blizzard Default" then
		TrackByZone()
	end
end

function frame:PLAYER_LOGIN( ... )
	OQ.userTrackedQuests = OQ.userTrackedQuests or {}
	ns.Options:RegisterForOkay(function( ... )
		if OQ.Options.ZoneTracking.Behaviour == "Blizzard Default" then
			UntrackAll()

			-- Enable blizzard automatic quest tracking
			SetCVar("autoQuestWatch", "1")
		else
			-- Disable blizzard automatic quest tracking
			SetCVar("autoQuestWatch", "0")
			TrackByZone()
		end
	end)

	hooksecurefunc("QuestMapQuestOptions_TrackQuest", function(questID)

		if not OQ.userTrackedQuests[questID] and C_QuestLog.GetQuestWatchType(questID) then
			OQ.userTrackedQuests[questID] = true
		else
			OQ.userTrackedQuests[questID] = nil	
		end
	end)
end
