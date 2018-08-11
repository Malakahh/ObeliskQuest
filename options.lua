local addonName, ns = ...

local libOptions = ObeliskFrameworkManager:GetLibrary("ObeliskOptions", 0)
if not libOptions then
	print("libOptions not gotten")
end

------
-- Settings
------

local defaultSettings = {
	ZoneTracking = {
		Behaviour = "Semi Automatic"
	}
}

------
-- Menu
------

local function onRefresh(self, ... )
	-- Zone Tracking
	UIDropDownMenu_SetText(self.zoneTrackingDropdown, OQ.Options.ZoneTracking.Behaviour)
	panel:ZoneTrackingDropdownDescriptionSwapText()
end

local function onOkay(self,  ... )
	-- Zone Tracking
	OQ.Options.ZoneTracking.Behaviour = UIDropDownMenu_GetText(self.zoneTrackingDropdown)
end

local function onCancel(self, ... )
	-- body
end

local function onDefault(self,  ... )
	wipe(OQ.Options)
	ns.Util.CopyTable(defaultSettings, OQ.Options)
end

local panel = libOptions(addonName, nil, onRefresh, onOkay, onCancel, onDefault)
ns.Options = panel

panel:SetScript("OnEvent", function(self, event, ... ) self[event](self, ...) end)
panel:RegisterEvent("ADDON_LOADED")
function panel:ADDON_LOADED( name )
	if name == addonName then
		OQ = OQ or {}
		OQ.Options = OQ.Options or {}
		ns.Util.CopyTable(defaultSettings, OQ.Options)

		if OQ.Options.ZoneTracking.Behaviour == "Blizzard Default" then
			SetCVar("autoQuestWatch", "1")
		else
			SetCVar("autoQuestWatch", "0")
		end
	end
end

-- Page setup
local margin = 16
local itemSpacing = 16
local endOfSectionSpacing = 32
local belowTextSpacing = 5
local editBoxIndent = 8

-- Title
panel.title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panel.title:SetPoint("TOPLEFT", margin, -margin)
panel.title:SetText(addonName)

-- Zone Tracking title
panel.zoneTrackingTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.zoneTrackingTitle:SetPoint("TOPLEFT", panel.title, "BOTTOMLEFT", 0, -endOfSectionSpacing)
panel.zoneTrackingTitle:SetText("Zone Tracking")

-- Zone Tracking Dropdown
panel.zoneTrackingDropdown = CreateFrame("FRAME", addonName .. "ZoneTrackingDropdown", panel, "UIDropDownMenuTemplate")
panel.zoneTrackingDropdown:SetPoint("TOPLEFT", panel.zoneTrackingTitle, "BOTTOMLEFT", 0, -itemSpacing)

-- Zone Tracking Dropdown Description
panel.zoneTrackingDropdownDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
panel.zoneTrackingDropdownDescription:SetPoint("LEFT", panel.zoneTrackingDropdown, "RIGHT", 100 + itemSpacing, 0)
panel.zoneTrackingDropdownDescription:SetPoint("RIGHT", panel, "RIGHT", -margin, 0)
panel.zoneTrackingDropdownDescription:SetJustifyH("LEFT")

function panel:ZoneTrackingDropdownDescriptionSwapText()
	local dropdownText = UIDropDownMenu_GetText(self.zoneTrackingDropdown)
	if dropdownText == "Fully Automatic" then
		self.zoneTrackingDropdownDescription:SetText("Automatically tracks quests based on the zone you are in.")
	elseif dropdownText == "Semi Automatic" then
		self.zoneTrackingDropdownDescription:SetText("Automatically tracks quests based on the zone you are in, keeping manually tracked quests tracked.")
	elseif dropdownText == "Blizzard Default" then
		self.zoneTrackingDropdownDescription:SetText("Regular blizzard tracking behaviour. Effectively disables zone tracking.")
	end
end

local function zoneTrackingDropdownOnClick(self, selected, arg2, checked)
	UIDropDownMenu_SetText(panel.zoneTrackingDropdown, selected)
	panel:ZoneTrackingDropdownDescriptionSwapText()
	CloseDropDownMenus()
end

local function zoneTrackingDropdownInitialization(self, level, menuList)
	local info = UIDropDownMenu_CreateInfo()
	local t = {
		"Fully Automatic",
		"Semi Automatic",
		"Blizzard Default"
	}

	for k,v in pairs(t) do
		info.text = v
		info.arg1 = v
		info.func = zoneTrackingDropdownOnClick
		info.checked = UIDropDownMenu_GetText(panel.zoneTrackingDropdown) == v
		UIDropDownMenu_AddButton(info)
	end
end

UIDropDownMenu_Initialize(panel.zoneTrackingDropdown, zoneTrackingDropdownInitialization)
