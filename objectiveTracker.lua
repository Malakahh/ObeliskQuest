local tracker = ObjectiveTrackerFrame
tracker:SetMovable(true)
tracker:SetResizable(true)
tracker:SetClampedToScreen(true)
tracker:SetMinResize(235, 140)

tracker.tex = tracker:CreateTexture(nil, "BACKGROUND")
tracker.tex:SetColorTexture(0, 0, 0, 0.75)
tracker.tex:SetAllPoints()
tracker.tex:Hide()

local trackerBlocks = ObjectiveTrackerBlocksFrame
trackerBlocks:ClearAllPoints()
trackerBlocks:SetPoint("TOPLEFT", tracker, "TOPLEFT")
trackerBlocks:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT")

--trackerBlocks.tex = trackerBlocks:CreateTexture(nil, "BACKGROUND")
--trackerBlocks.tex:SetColorTexture(1, 0, 1, 0.75)
--trackerBlocks.tex:SetAllPoints()

--Resizing
tracker.ResizeButton = CreateFrame("Button", nil, tracker)
local resizeBtn = tracker.ResizeButton
resizeBtn:SetSize(16, 16)
resizeBtn:SetPoint("BOTTOMRIGHT")

resizeBtn.nTex = resizeBtn:CreateTexture(nil, "BACKGROUND")
resizeBtn.nTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
resizeBtn.nTex:SetAllPoints()
resizeBtn:SetNormalTexture(resizeBtn.nTex)

resizeBtn.hTex = resizeBtn:CreateTexture(nil, "BACKGROUND")
resizeBtn.hTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeBtn.hTex:SetAllPoints()
resizeBtn:SetNormalTexture(resizeBtn.hTex)

resizeBtn.pTex = resizeBtn:CreateTexture(nil, "BACKGROUND")
resizeBtn.pTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeBtn.pTex:SetAllPoints()
resizeBtn:SetNormalTexture(resizeBtn.pTex)

resizeBtn:SetScript("OnMouseDown", function(self)
	self:GetParent():StartSizing("BOTTOM")
	tracker.tex:Show()
end)

resizeBtn:SetScript("OnMouseUp", function(self)
	self:GetParent():StopMovingOrSizing()
	ObjectiveTracker_Update()

	tracker.tex:Hide()
end)

--Moving
trackerBlocks.QuestHeader:SetScript("OnMouseDown", function()
	tracker:ClearAllPoints()
	tracker:StartMoving()

	tracker.tex:Show()
end)
trackerBlocks.QuestHeader:SetScript("OnMouseUp", function()
	tracker:StopMovingOrSizing()

	tracker.tex:Hide()
end)
