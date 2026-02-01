-- Compatibility shims for WoW 3.3.5a (Wrath)
-- Loaded early (before embedded libs) via AtlasLootClassic.toc.

if not GetCurrentRegion then
    function GetCurrentRegion() return 1 end
end

-- Ambiguate was added later (used by newer AceComm / chat libs)
if not Ambiguate then
    function Ambiguate(name, context)
        if type(name) ~= "string" then return name end
        if context == "short" or context == "none" or context == "chat" then
            local short = name:match("^([^%-]+)%-.*$")
            return short or name
        end
        return name
    end
end

-- Some addons wrap SendAddonMessage for logging; keep it available
if not SendAddonMessageLogged then
    function SendAddonMessageLogged(prefix, msg, chatType, target)
        return SendAddonMessage(prefix, msg, chatType, target)
    end
end

-- Some private servers strip this; AtlasLoot uses it to detect enabled modules
if not GetAddOnEnableState then
    function GetAddOnEnableState() return 2 end
end

-- Modern libs sometimes use table.wipe; 3.3.5 provides global wipe()
if not table.wipe and wipe then
    table.wipe = wipe
end

if not string.split and _G.strsplit then
    string.split = _G.strsplit
end

if not string.trim then
    if _G.strtrim then
        string.trim = _G.strtrim
    else
        function string.trim(s)
            if type(s) ~= "string" then return s end
            s = s:gsub("^%s+", "")
            s = s:gsub("%s+$", "")
            return s
        end
    end
end

-- FontString:GetUnboundedStringWidth was added later
do
    local fs = UIParent and UIParent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    if fs then
        local mt = getmetatable(fs)
        local idx = mt and mt.__index
        if idx and not idx.GetUnboundedStringWidth and idx.GetStringWidth then
            idx.GetUnboundedStringWidth = idx.GetStringWidth
        end
    end
end

-- Model methods added later; keep calls harmless on 3.3.5a
do
    local m = CreateFrame("DressUpModel", nil, UIParent)
    if m then
        local mt = getmetatable(m)
        local idx = mt and mt.__index
        if idx then
            if not idx.SetPortraitZoom then
                idx.SetPortraitZoom = function() end
            end
            if not idx.SetRotation then
                idx.SetRotation = function() end
            end
        end
    end
end

-- UnitPosition was added later; AutoSelect uses it
if not UnitPosition then
    local function _UnitPositionPlayer()
        if SetMapToCurrentZone then pcall(SetMapToCurrentZone) end
        local x, y = 0, 0
        if GetPlayerMapPosition then
            x, y = GetPlayerMapPosition("player")
        end
        local mapID = (GetCurrentMapAreaID and GetCurrentMapAreaID()) or 0
        return x or 0, y or 0, 0, mapID
    end

    function UnitPosition(unit)
        if unit == "player" then
            return _UnitPositionPlayer()
        end
        return 0, 0, 0, 0
    end
end

-- Retail API helpers used for locale / filters
if not GetItemClassInfo then
    local classes = { GetAuctionItemClasses() }
    function GetItemClassInfo(classID)
        return classes[classID]
    end
end

if not GetDifficultyInfo then
    local names = {
        [1] = "Normal",
        [2] = "Heroic",
        [3] = "10 Player",
        [4] = "25 Player",
        [5] = "10 Player (Heroic)",
        [6] = "25 Player (Heroic)",
    }
    function GetDifficultyInfo(id)
        return names[id] or ("Difficulty " .. tostring(id))
    end
end

-- C_* namespace shims (Wrath has the legacy global APIs)
if not C_AddOns then
    C_AddOns = {
        GetNumAddOns = _G.GetNumAddOns,
        GetAddOnInfo = _G.GetAddOnInfo,
        IsAddOnLoaded = _G.IsAddOnLoaded,
        LoadAddOn = _G.LoadAddOn,
        GetAddOnEnableState = _G.GetAddOnEnableState,
        GetAddOnMetadata = _G.GetAddOnMetadata,
    }
end

if not C_Item then
    C_Item = {}
    C_Item.GetItemInfo = _G.GetItemInfo
	if _G.GetItemInfoInstant then
		C_Item.GetItemInfoInstant = _G.GetItemInfoInstant
	else
		C_Item.GetItemInfoInstant = function(item)
			local itemID
			if type(item) == "number" then
				itemID = item
			elseif type(item) == "string" then
				itemID = tonumber(item:match("item:(%d+)") or item)
			end
			if not itemID then return nil end
			local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc, itemTexture = _G.GetItemInfo(itemID)
			return itemID, itemType, itemSubType, itemEquipLoc, itemTexture
		end
	end
    C_Item.GetItemStats = _G.GetItemStats
    C_Item.IsEquippableItem = _G.IsEquippableItem
    C_Item.GetItemCount = _G.GetItemCount
    C_Item.GetItemQualityColor = _G.GetItemQualityColor
    function C_Item.GetItemIconByID(itemID)
        local tex = _G.GetItemIcon and _G.GetItemIcon(itemID) or nil
        if not tex then
            tex = select(10, _G.GetItemInfo(itemID))
        end
        return tex
    end
    function C_Item.GetItemQualityByID(itemID)
        return select(3, _G.GetItemInfo(itemID))
    end
    function C_Item.DoesItemExistByID(itemID)
        return itemID ~= nil
    end
    -- Optional APIs
    function C_Item.GetItemSetInfo(setID)
        if type(_G.GetItemSetInfo) == "function" then
            return _G.GetItemSetInfo(setID)
        end
        return nil
    end
    function C_Item.GetItemClassInfo() return nil end
    function C_Item.GetItemSubClassInfo() return nil end
end

if not C_Spell then
    C_Spell = {
        GetSpellInfo = _G.GetSpellInfo,
        GetSpellTexture = _G.GetSpellTexture,
    }
end

if not C_Map then
    C_Map = {}
    function C_Map.GetAreaInfo(mapID)
        if not mapID then return nil end
        if _G.GetMapNameByID then
            return _G.GetMapNameByID(mapID)
        end
        return nil
    end
end

if not C_Timer then
    C_Timer = {}
    do
        local f
        local queue = {}
        local function OnUpdate(self, elapsed)
            for i = #queue, 1, -1 do
                local t = queue[i]
                t[1] = t[1] - elapsed
                if t[1] <= 0 then
                    table.remove(queue, i)
                    pcall(t[2])
                end
            end
            if #queue == 0 and f then
                f:SetScript("OnUpdate", nil)
            end
        end
        function C_Timer.After(delay, func)
            if type(func) ~= "function" then return end
            delay = tonumber(delay) or 0
            queue[#queue+1] = { delay, func }
            if not f then
                f = CreateFrame("Frame")
            end
            f:SetScript("OnUpdate", OnUpdate)
        end
    end
end

if not C_Map then
    C_Map = {}
end

if not C_Map.GetAreaInfo then
    function C_Map.GetAreaInfo(mapID)
        if not mapID then return nil end
        if _G.GetMapNameByID then
            return _G.GetMapNameByID(mapID)
        end
        return nil
    end
end
