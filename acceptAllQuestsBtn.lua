local btn = CreateFrame("Button", "ObeliskQuestAcceptAllQuestsButton", GossipFrame, "UIPanelButtonTemplate")
btn:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
btn:RegisterEvent("GOSSIP_SHOW")
btn:RegisterEvent("QUEST_DETAIL")

btn:SetPoint("BOTTOMLEFT", GossipFrame, "BOTTOMLEFT", 2, 4)
btn:SetText("Accept Quests")
btn:SetWidth(btn:GetTextWidth() + 20)

local availableQuestsInfo = {}

local function GetAvailableQuestInfo()
	local temp = {}
	for i = 1, GetNumGossipAvailableQuests() do
		local title, level, isTrivial, frequency, isRepeatable, isLegendary, isIgnored = select(i * 7 - 6, GetGossipAvailableQuests())

		temp[title] = {
			-- level = level,
			-- isTrivial = isTrivial,
			-- frequency = frequency,
			-- isRepeatable = isRepeatable,
			-- isLegendary = isLegendary,
			isIgnored = isIgnored,
			--index = i
		}
	end

	return temp
end

function btn:GOSSIP_SHOW()
	local shouldShow = false

	for _, v in pairs(GetAvailableQuestInfo()) do
		if not v.isIgnored and not shouldShow then
			shouldShow = true
		end
	end

	if shouldShow then
		btn:Show()
	else
		btn:Hide()
	end
end

local function CloseFrame()
	CloseQuest()
	CloseGossip()
end

function btn:QUEST_DETAIL()
	C_Timer.After(0.0001, function()
		local title = GetTitleText()
		if availableQuestsInfo[title] and type(availableQuestsInfo[title].isIgnored) ~= "nil" and not availableQuestsInfo[title].isIgnored then
			availableQuestsInfo[title] = nil
			AcceptQuest()
			C_Timer.After(0.5, CloseFrame) --Time required tested to be 0.25. Using a slower to account for lowspec PCs
		end
	end)
end

btn:SetScript("OnClick", function()
	wipe(availableQuestsInfo)
	availableQuestsInfo = GetAvailableQuestInfo()

	for i = 1, GetNumGossipAvailableQuests() do
		local title = select(i * 7 - 6, GetGossipAvailableQuests())
		if availableQuestsInfo[title] and not availableQuestsInfo[title].isIgnored then
			print("title", title)
			SelectGossipAvailableQuest(i)
		end
	end	
end)