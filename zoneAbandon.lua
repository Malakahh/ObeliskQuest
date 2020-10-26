local frame = CreateFrame("Frame", "ObeliskQuestZoneAbandonConfirmPopup", UIParent, "BackdropTemplate")

frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")



local function AbandonQuestByZone(zone)
	local startAbandoning = false
	local i = 1

	while C_QuestLog.GetInfo(i) do
		local info = C_QuestLog.GetInfo(i)

		if info.isHeader then
			if info.title == zone then
				startAbandoning = true
			elseif startAbandoning then
				break
			end
		elseif startAbandoning then
			C_QuestLog.SetSelectedQuest(info.questID)
			--SetAbandonQuest()
			C_QuestLog.SetAbandonQuest()
			--AbandonQuest()
			C_QuestLog.AbandonQuest()
		end

		i = i + 1
	end
end

local function OnClick(self, button)
	if button == "RightButton" then
		frame:SetZoneAndShow(self.ButtonText:GetText())
	else
	 	QuestLogHeaderCodeMixin.OnClick(self, button)
	end
end

local function CheckFrameIsQuestHeader(f)
	return type(f) == "table" and f.ButtonText ~= nil and f.questID == nil
end

local function RegisterHeaderClicks()
	for _, child in pairs(QuestScrollFrame.Contents:GetLayoutChildren()) do
		if CheckFrameIsQuestHeader(child) then
			child:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			child:SetScript("OnClick", OnClick)
		end
	end
end

local function OnWorldMapToggle()
	if WorldMapFrame:IsShown() then
		RegisterHeaderClicks()
	end
end

function frame:PLAYER_ENTERING_WORLD()
	hooksecurefunc("ToggleWorldMap", OnWorldMapToggle)
end

---------------------
--- Confirm popup ---
---------------------

local function SetTilingArtwork(frame, bgFile, edgeFile, edgeSize, insets)
	if type(bgFile) == "table" and edgeFile == nil then --It's a wrapped table. Unwrap it!
		if bgFile.bgFile == nil and bgFile.edgeFile == nil then
			bgFile, edgeFile, edgeSize, insets = unpack(bgFile)
		else
			edgeFile = bgFile.edgeFile
			edgeSize = bgFile.edgeSize
			insets = bgFile.insets
			bgFile = bgFile.bgFile
		end
	end

	local tex = frame:CreateTexture(nil, "BACKGROUND")
	tex:SetTexture(bgFile, true, true)
	tex:SetVertTile(true)
	tex:SetHorizTile(true)
	tex:SetPoint("TOPLEFT", insets.left, -insets.top)
	tex:SetPoint("BOTTOMRIGHT", -insets.right, insets.bottom)
	frame.bgTex = tex

	frame:SetBackdrop({
		edgeFile = edgeFile,
		edgeSize = edgeSize,
		insets = insets
	})
end

function frame:SetZoneAndShow(zone)
	PlaySound(SOUNDKIT.IG_MAINMENU_OPEN);
	frame.zoneToAbandon = zone
	frame.text:SetText("Abandon quests in \"" .. zone .. "\"?")
	frame:ClearAllPoints()
	frame:SetPoint("TOP", 0, -130)
	frame:Show()
end

tinsert(UISpecialFrames, frame:GetName())
frame:SetSize(380, 80)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("DIALOG")
frame:RegisterForDrag("LeftButton")
frame:Hide()

frame:SetScript("OnMouseDown", frame.StartMoving)
frame:SetScript("OnMouseUp", frame.StopMovingOrSizing)

frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
frame.text:SetPoint("TOP", 0, -18)
frame.text:SetJustifyH("CENTER")

SetTilingArtwork(frame, {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true,
	tileSize = 64,
	edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 }})

frame.btnYes = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.btnYes:SetText("Yes")
frame.btnYes:SetWidth(120)
frame.btnYes:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -5, 20)
frame.btnYes:SetScript("OnClick", function(self)
	AbandonQuestByZone(frame.zoneToAbandon)
	PlaySound(SOUNDKIT.IG_QUEST_LOG_ABANDON_QUEST);
	frame:Hide()
end)

frame.btnNo = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
frame.btnNo:SetText("No")
frame.btnNo:SetWidth(120)
frame.btnNo:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 5, 20)
frame.btnNo:SetScript("OnClick", function(self)
	PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE);
	frame:Hide()
end)
