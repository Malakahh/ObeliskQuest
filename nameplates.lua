local anchorPoint = {
	"BOTTOM", -- Anchor point of text
	"TOP", -- Anchor point of parent frame
	0, -- x offset
	20 -- y offset
}

--Generic nameplate stuff
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORD")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_REMOVED")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
frame:RegisterEvent("NAME_PLATE_CREATED") --plate is created
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED") --plate is shown
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED") --plate is hidden
frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

-- Enable quest information in tooltip, required for scraping
SetCVar('showQuestTrackingTooltips', '1')

local WorldQuestsAndBonusObjectives = {
	-- [questName] = questId
}

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

local function DetachObjectiveText(objectiveText)
	--Matches a potential character name (if in group), and whatever remains
	local name, remainder = string.match(objectiveText, "^ ?([^ ]-) %- (.+)$")

	--Matches x/y style objective text
	local progress, text = string.match(objectiveText, "(%d+/%d+) (.+)$")

	--print("text: ", text, "remainder:", remainder, "objectiveText", objectiveText)

	return text or remainder or objectiveText, progress, name
end

local QuestCache = {
	-- [questName] = {
	-- 		["questId"] = questId,
	--		["isComplete"] = bool
	-- 		[objectiveText] = finished
	-- }	
}

local function BuildQuestCache()
	wipe(QuestCache)

	for i = 1, GetNumQuestLogEntries() do
		local title, _, _, isHeader, _, isComplete, _, questId = GetQuestLogTitle(i)
		if not isHeader then
			QuestCache[title] = {
				questId = questId,
				isComplete = isComplete
			}

			for objectiveId = 1, GetNumQuestLeaderBoards(i) do
				objectiveText, _, finished = GetQuestObjectiveInfo(questId, objectiveId, false)

				QuestCache[title][DetachObjectiveText(objectiveText)] = finished
			end
		end
	end
end

local questTitleCache
local function ValidateQuestText(text)
	if WorldQuestsAndBonusObjectives[text] then
		questTitleCache = text
		return "worldQuestTitle", false
	elseif QuestCache[text] then
		questTitleCache = text
		return "questTitle", QuestCache[text].isComplete
	elseif QuestCache[questTitleCache] then
		for _, finished in pairs(QuestCache[questTitleCache]) do
			local _, _, characterName = DetachObjectiveText(text)

			local dash = string.match(text, "^%s?(%-)")

			if dash and dash ~= "" or characterName	and characterName ~= "" then --Objective texts start with a dash
				if characterName ~= nil and characterName ~= "" and characterName ~= playerName then
					return "questObjectiveParty"
				end

				return "questObjective", finished
			end
		end
	end
end

local function QuestTooltipScrape(unitId)
	sourceTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	sourceTooltip:SetUnit(unitId)

	local progressTexts = {}
	questTitleCache = nil

	for i = 3, sourceTooltip:NumLines() do
		local str = _G["ObeliskSourceTooltipTextLeft" .. i]
		local text = str and str:GetText()
		if not text then return end

		local textType, completed = ValidateQuestText(text)

		if textType then
			progressTexts[#progressTexts + 1] = {text, textType, completed}
		end


		-- -- Pattern explanation: Start at beginning, matches the first word, then an optional '-' separator, then whatever remains
		-- local characterName, questText = string.match(text, "^ ([^ ]-) ?%- (.+)$")
		
		-- -- Pattern explanation: Matches a number, followed by a percentage symbol and a space, followed by the word 'Threat'
		-- local threat = string.match(text, "(%d+)%% Threat")

		-- local isHeader = not string.match(text, "^ - ")

		-- if characterName and not threat and characterName ~= "" and characterName ~= playerName then
		-- 	progressTexts[#progressTexts] = "headerFromGroupMember" --remove previous entry, as this quest is for another player in our group
		-- elseif not threat then
		-- 	--If last header was from a qroup members quest, remove it
		-- 	if progressTexts[#progressTexts] == "headerFromGroupMember" then
		-- 		progressTexts[#progressTexts] = nil
		-- 	end

		-- 	--Remove playername from text if in group
		-- 	if characterName == playerName then
		-- 		text = questText
		-- 	end

		-- 	local progressBarText
		-- 	--Give special treatment if world quest or bonus objective with progress bar
		-- 	if WorldQuestsAndBonusObjectives[text] then
		-- 		local questId = WorldQuestsAndBonusObjectives[text]
		-- 		local progress = C_TaskQuest.GetQuestProgressBarInfo(questId)
				
		-- 		if progress then
		-- 			progressBarText = " - " .. progress .. "%" 
		-- 		end
		-- 	end

		-- 	--Color header
		-- 	if isHeader then
		-- 		text = "|cFFFFD100" .. text .. "|r"
		-- 	end

		-- 	--Append progressBarText (percentage for world quest, for instance)
		-- 	if progressBarText then
		-- 		text = text .. progressBarText
		-- 	end

		-- 	progressTexts[#progressTexts + 1] = text
		-- end
	end

	return progressTexts
end

local function FilterQuestTexts(scrapedTexts)
	local addedWorldQuests = {}
	local temp = {}
	local currentQuestIndex = -1

	for i = 1, #scrapedTexts do
		local originalText, textType = unpack(scrapedTexts[i])

		if textType == "worldQuestTitle" or textType == "questTitle" then
			currentQuestIndex = i

			--Don't added repeated world quests.
			--The idea is to remove world quests from party members.
			--This relies on the first one being ours
			if not addedWorldQuests[originalText] then
				temp[i] = scrapedTexts[i]
				addedWorldQuests[originalText] = true
			end
		elseif textType == "questObjectiveParty" then
			--Don't add quests from partymembers
			if currentQuestIndex ~= -1 then --remove title
				temp[currentQuestIndex] = nil
				currentQuestIndex = -1
			end
		elseif textType == "questObjective" then
			temp[i] = scrapedTexts[i]
		end
	end

	--fix table
	local filteredTexts = {}
	for _, v in pairs(temp) do
		filteredTexts[#filteredTexts + 1] = v
	end

	return filteredTexts
end

local function FormatQuestText(scrapedTexts)
	local filteredTexts = FilterQuestTexts(scrapedTexts)
	local formattedText = ""
	local titleColor = "|cFFFFD100"
	local partyQuestRemoved = false

	for i = 1, #filteredTexts do
		local originalText, textType, completed = unpack(filteredTexts[i])
		local detachedText, detachedProgress = DetachObjectiveText(originalText)
		
		if formattedText ~= "" then
			formattedText = formattedText .. "|n"
		end

		if textType == "worldQuestTitle" then
			local questId = WorldQuestsAndBonusObjectives[detachedText]
			local progress = C_TaskQuest.GetQuestProgressBarInfo(questId)

			formattedText = formattedText .. titleColor .. detachedText .. "|r"

			if progress then
				formattedText = formattedText .. " - " .. progress .. "%"
			end
		elseif textType == "questTitle" then
			formattedText = formattedText .. titleColor .. detachedText .. "|r"
		elseif textType == "questObjective" then
			if detachedProgress then
				formattedText = formattedText .. " - " .. detachedProgress .. " " .. detachedText
			else
				formattedText = formattedText .. " - " .. detachedText
			end
		end
	end

	return formattedText
end

local function UpdateProgressText(frame)
	local progressTexts = QuestTooltipScrape(frame.unitId)
	local formattedText = FormatQuestText(progressTexts)

	local _, fontHeight = frame.questText:GetFont()
	frame.questText:SetText(formattedText)

	frame:Show()
end

local HelperPlates = {
	-- [plate] = frame
}

local ActiveHelperPlates = {
	-- [plate] = frame
}

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
	if unitId == "player" then
		BuildQuestCache()
	end

	for _, frame in pairs(ActiveHelperPlates) do
		UpdateProgressText(frame)
	end
end

function frame:QUEST_LOG_UPDATE()
	BuildQuestCache()
end

function frame:PLAYER_LEAVING_WORD()
	frame:UnregisterEvent("QUEST_LOG_UPDATE")
end

function frame:PLAYER_ENTERING_WORLD()
	frame:RegisterEvent("QUEST_LOG_UPDATE")
end