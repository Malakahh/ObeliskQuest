local anchorPoint = {
	"BOTTOM", -- Anchor point of text
	"TOP", -- Anchor point of parent frame
	0, -- x offset
	20 -- y offset
}

--Generic nameplate stuff
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
frame:RegisterEvent("NAME_PLATE_CREATED") --plate is created
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED") --plate is shown
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED") --plate is hidden
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

-- Enable quest information in tooltip, required for scraping
SetCVar('showQuestTrackingTooltips', '1')

local WorldQuestsAndBonusObjectives = {}

function frame:PLAYER_LOGIN()
	for _, wq in pairs(C_TaskQuest.GetQuestsForPlayerByMapID(GetCurrentMapAreaID())) do
		if wq.inProgress then
			local questId = wq.questId
			local name = C_TaskQuest.GetQuestInfoByQuestID(questId)
			if name then
				WorldQuestsAndBonusObjectives[name] = questId
			end
		end
	end
end

function frame:QUEST_ACCEPTED(logIndex, questId)
	if IsQuestTask(questId) then --bonus objectives
		local name = C_TaskQuest.GetQuestInfoByQuestID(questId)
		if name then
			WorldQuestsAndBonusObjectives[name] = questId
		end
	end
end

function frame:QUEST_REMOVED(questId)
	local name = C_TaskQuest.GetQuestInfoByQuestID(questId)
	if name and WorldQuestsAndBonusObjectives[name] then
		WorldQuestsAndBonusObjectives[name] = nil
	end
end

local sourceTooltip = CreateFrame("GameTooltip", "ObeliskSourceTooltip", nil, "GameTooltipTemplate")
local playerName = UnitName("player")

function ObeliskQuestTooltipScrape(unitId)
	sourceTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	sourceTooltip:SetUnit(unitId)

	local progressTexts = {}

	for i = 3, sourceTooltip:NumLines() do
		local str = _G["ObeliskSourceTooltipTextLeft" .. i]
		local text = str and str:GetText()

		if not text then
			print(i .. " - Return")
			return
		end

		-- Pattern explanation: Start at beginning, matches the first word, then an optional '-' separator, then whatever remains
		local characterName, questText = string.match(text, "^ ([^ ]-) ?%- (.+)$")
		
		-- Pattern explanation: Matches a number, followed by a percentage symbol and a space, followed by the word 'Threat'
		local threat = string.match(text, "(%d+)%% Threat")

		local isHeader = not string.match(text, "^ - ")

		if characterName and not threat and characterName ~= "" and characterName ~= playerName then
			progressTexts[#progressTexts] = "headerFromGroupMember" --remove previous entry, as this quest is for another player in our group
		elseif not threat then
			--If last header was from a qroup members quest, remove it
			if progressTexts[#progressTexts] == "headerFromGroupMember" then
				progressTexts[#progressTexts] = nil
			end

			--Remove playername from text if in group
			if characterName == playerName then
				text = questText
			end

			local progressBarText
			--Give special treatment if world quest or bonus objective with progress bar
			if WorldQuestsAndBonusObjectives[text] then
				local questId = WorldQuestsAndBonusObjectives[text]
				local progress = C_TaskQuest.GetQuestProgressBarInfo(questId)
				
				if progress then
					progressBarText = " - " .. progress .. "%" 
				end
			end

			--Color header
			if isHeader then
				text = "|cFFFFD100" .. text .. "|r"
			end

			--Append progressBarText (percentage for world quest, for instance)
			if progressBarText then
				text = text .. progressBarText
			end

			progressTexts[#progressTexts + 1] = text
		end
	end

	return progressTexts
end

local function UpdateProgressText(frame)
	local progressTexts = ObeliskQuestTooltipScrape(frame.unitId)
	local finalProgressText = progressTexts[1]
	for i = 2, #progressTexts do
		finalProgressText = finalProgressText .. "|n" .. progressTexts[i]
	end

	local _, fontHeight = frame.questText:GetFont()
	frame.questText:SetText(finalProgressText or "")

	frame:Show()
end

local HelperPlates = {}
local ActiveHelperPlates = {}
function frame:NAME_PLATE_CREATED(plate)
	local f = CreateFrame("Frame", nil, plate)
	f:Hide()
	f:SetAllPoints()

	local textAnchor, parentAnchor, x, y = unpack(anchorPoint)
	local questText = f:CreateFontString(nil, "BACKGROUND", "GameFontWhiteSmall")
	questText:SetPoint(textAnchor, f, parentAnchor, x, y)
	questText:SetJustifyH("LEFT")
	questText:SetJustifyV("CENTER")
	questText:SetShadowOffset(1, -1)
	f.questText = questText

	HelperPlates[plate] = f
end

function frame:NAME_PLATE_UNIT_ADDED(unitId)
	if GetUnitName(unitId) == playerName then return end

	local plate = C_NamePlate.GetNamePlateForUnit(unitId)
	local f = HelperPlates[plate]
	ActiveHelperPlates[plate] = f

	f.unitId = unitId

	UpdateProgressText(f, unitId)
end

function frame:NAME_PLATE_UNIT_REMOVED(unitId)
	local plate = C_NamePlate.GetNamePlateForUnit(unitId)
	local f = ActiveHelperPlates[plate]

	if f then
		f:Hide()
	end

	ActiveHelperPlates[plate] = nil
end

function frame:UNIT_QUEST_LOG_CHANGED(unitId)
	for _, frame in pairs(ActiveHelperPlates) do
		UpdateProgressText(frame)
	end
end