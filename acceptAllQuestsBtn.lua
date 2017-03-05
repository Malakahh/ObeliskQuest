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

local currentIndex = 0

function btn:QUEST_DETAIL()
	if availableQuestsInfo[currentIndex] then
		currentIndex = currentIndex - 1

		if not IsQuestIgnored() then
			AcceptQuest()
			CloseQuest()
		end

		-- If dead, delete coroutine. This makes sure we don't auto accept quests unintendedly
		if currentIndex == 0 then
			acceptQuestsCoroutine = nil
		end
	end
end

btn:SetScript("OnClick", function()
	wipe(availableQuestsInfo)
	availableQuestsInfo = GetAvailableQuestInfo()

	acceptQuestsCoroutine = coroutine.create(function()
		currentIndex = GetNumGossipAvailableQuests()

		if currentIndex <= 2 then
			SelectGossipAvailableQuest(1)
		else
			while currentIndex > 0 do
				if availableQuestsInfo[currentIndex] and not availableQuestsInfo[currentIndex].isIgnored then
					SelectGossipAvailableQuest(currentIndex)
					
					-- Don't yield on last iteration, to allow coroutine to die
					if currentIndex > 2 then
						coroutine.yield()
					end
				end
			end
		end
	end)

	-- Start coroutine
	coroutine.resume(acceptQuestsCoroutine)
end)