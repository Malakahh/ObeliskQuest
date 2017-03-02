local fontString = QuestScrollFrame:CreateFontString("ObeliskQuestQuestLogCounter", "ARTWORK", "GameFontNormalHuge")
fontString:SetPoint("BOTTOM", QuestScrollFrame, "TOP", 0, 13)

local function UpdateCount()
	local questCount = 0

	for i = 1, GetNumQuestLogEntries() do
		-- questTitle, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden = GetQuestLogTitle(index)
		local _, _, _, isHeader, _, _, _, _, _, _, _, _, _, isBounty, _, isHidden = GetQuestLogTitle(i)

		if not isHeader and not isHidden and not isBounty then
			questCount = questCount + 1
		end
	end

	fontString:SetText(questCount .. "/25")
end

local function OnWorldMapToggle()
	if WorldMapFrame:IsShown() then
		UpdateCount()
	end
end

hooksecurefunc("ToggleWorldMap", OnWorldMapToggle)

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")

function frame:QUEST_ACCEPTED()
	if WorldMapFrame:IsShown() then
		UpdateCount()
	end
end

function frame:QUEST_REMOVED()
	if WorldMapFrame:IsShown() then
		UpdateCount()
	end
end