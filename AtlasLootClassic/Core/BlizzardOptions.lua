if not InterfaceOptions_AddCategory then return end

local function SafeLoadOptionsAddon()
    if IsAddOnLoaded("AtlasLootClassic_Options") then return true end
    local ok = LoadAddOn("AtlasLootClassic_Options")
    return ok == true or ok == 1
end

local function TryOpenAtlasLootOptions()
    if SafeLoadOptionsAddon() and AtlasLoot and AtlasLoot.Options then
        if type(AtlasLoot.Options.Show) == "function" then
            AtlasLoot.Options:Show()
            return
        end
        if type(AtlasLoot.Options.Open) == "function" then
            AtlasLoot.Options:Open()
            return
        end
    end
    if AtlasLoot and AtlasLoot.GUI and type(AtlasLoot.GUI.Toggle) == "function" then
        AtlasLoot.GUI:Toggle()
    end
end

local panel = CreateFrame("Frame", "AtlasLootClassicBlizzOptionsPanel")
panel.name = "AtlasLoot"
panel:Hide()

panel:SetScript("OnShow", function(self)
    if self.__inited then return end
    self.__inited = true

    local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AtlasLoot")

    local desc = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetWidth(560)
    desc:SetJustifyH("LEFT")
    desc:SetText("Open AtlasLoot options and settings.")

    local btn = CreateFrame("Button", nil, self, "UIPanelButtonTemplate")
    btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
    btn:SetSize(220, 22)
    btn:SetText("Open AtlasLoot Options")
    btn:SetScript("OnClick", TryOpenAtlasLootOptions)
end)

InterfaceOptions_AddCategory(panel)
