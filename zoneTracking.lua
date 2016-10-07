local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local function LogIndexToQuestID(index)
	return select(8, GetQuestLogTitle(index))
end

local function UntrackAll()
	for i = 1, GetNumQuestLogEntries() do
		if IsQuestWatched(i) then
			RemoveQuestWatch(i)
		end
	end
end

local function TrackByZone()
	UntrackAll()

	SetMapToCurrentZone()
	local currentMapID = GetCurrentMapAreaID()

	for i = 1, GetNumQuestLogEntries() do
		if GetQuestWorldMapAreaID(LogIndexToQuestID(i)) == currentMapID then
			AddQuestWatch(i)
		end
	end
end

function frame:QUEST_ACCEPTED()
	TrackByZone()
end

function frame:ZONE_CHANGED_NEW_AREA()
	TrackByZone()
end

function frame:PLAYER_ENTERING_WORLD()
	TrackByZone()
end