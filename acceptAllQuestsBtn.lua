local btn = CreateFrame("Button", "ObeliskQuestAcceptAllQuestsButton", GossipFrame, "UIPanelButtonTemplate")
btn:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
btn:RegisterEvent("GOSSIP_SHOW")
btn:RegisterEvent("QUEST_DETAIL")

btn:SetPoint("BOTTOMLEFT", GossipFrame, "BOTTOMLEFT", 2, 4)
btn:SetText("Accept Quests")
btn:SetWidth(btn:GetTextWidth() + 20)

local availableQuestsInfo = {}
local acceptQuestsCoroutine

local function GetAvailableQuestInfo()
	local temp = {}
	for i = 1, GetNumGossipAvailableQuests() do
		local title, level, isTrivial, frequency, isRepeatable, isLegendary, isIgnored = select(i * 7 - 6, GetGossipAvailableQuests())

		temp[i] = {
			title = title,
			-- level = level,
			-- isTrivial = isTrivial,
			-- frequency = frequency,
			-- isRepeatable = isRepeatable,
			-- isLegendary = isLegendary,
			isIgnored = isIgnored,
		}
	end

	return temp
end

function btn:GOSSIP_SHOW()
	if acceptQuestsCoroutine and coroutine.status(acceptQuestsCoroutine) == "suspended" then
		coroutine.resume(acceptQuestsCoroutine)
		return
	end

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

function btn:QUEST_DETAIL()
	if acceptQuestsCoroutine and coroutine.status(acceptQuestsCoroutine) == "suspended" then
		if not IsQuestIgnored() then
			AcceptQuest()
		end
	end
end

btn:SetScript("OnClick", function()
	wipe(availableQuestsInfo)
	availableQuestsInfo = GetAvailableQuestInfo()

	acceptQuestsCoroutine = coroutine.create(function()
		for i = GetNumGossipAvailableQuests(), 1, -1 do
			if availableQuestsInfo[i] and not availableQuestsInfo[i].isIgnored then
				SelectGossipAvailableQuest(i)
				coroutine.yield()
			end
		end
	end)	

	coroutine.resume(acceptQuestsCoroutine)
end)