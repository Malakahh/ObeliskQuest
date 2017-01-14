local frame = CreateFrame("Frame", nil, QuestFrame)
frame:SetSize(48, 24)
frame:SetFrameStrata("HIGH")

frame.tex = frame:CreateTexture(nil, "OVERLAY")
frame.tex:SetTexture("Interface\\AddOns\\ObeliskQuest\\Assets\\GoldCoinCheck.tga")
frame.tex:SetAllPoints()

frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
frame:RegisterEvent("QUEST_COMPLETE")
--frame:RegisterEvent("QUEST_FINISHED")
frame:RegisterEvent("QUEST_DETAIL")
frame:RegisterEvent("QUEST_TURNED_IN")

local function GetMax(t, comparer)
	if #t == 0 then return nil, nil end

	local key, value = 1, t[1]

	for i = 2, #t do
		if t[i] > value then
			key, value = i, t[i]
		end
	end

	return key, value
end

function frame:QUEST_COMPLETE()
	local numRewards = GetNumQuestChoices()
	local itemValues = {}

	if numRewards > 0 then
		for i = 1, numRewards do
			local itemLink = GetQuestItemLink("choice", i)
			local rewardValue = select(11, GetItemInfo(tostring(itemLink)))

			table.insert(itemValues, rewardValue)
		end

		local key = GetMax(itemValues)
		self:SetPoint("CENTER", "QuestInfoRewardsFrameQuestInfoItem" .. key, "BOTTOMRIGHT", -6, 6)
		self:Show()
	end
end

--function frame:QUEST_FINISHED()
--	self:Hide()
--end

function frame:QUEST_TURNED_IN()
	self:Hide()
end

function frame:QUEST_DETAIL()
	self:Hide()
end