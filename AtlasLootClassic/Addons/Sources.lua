local ALName, ALPrivate = ...

local _G = getfenv(0)
local AtlasLoot = _G.AtlasLoot
local Addons = AtlasLoot.Addons
local AL = AtlasLoot.Locales
local ALIL = AtlasLoot.IngameLocales
local Sources = Addons:RegisterNewAddon("Sources")
local Tooltip = AtlasLoot.Tooltip
local Droprate = AtlasLoot.Data.Droprate
local Profession = AtlasLoot.Data.Profession
local Recipe = AtlasLoot.Data.Recipe
local VendorPrice = AtlasLoot.Data.VendorPrice

-- lua
local type = type
local format = string.format
local str_split = string.split

-- WoW 3.3.5a API
local GetCurrencyInfo, GetItemIcon, GetSpellTexture = _G.GetCurrencyInfo, _G.GetItemIcon, _G.GetSpellTexture

-- AtlasLoot
local PRICE_INFO = VendorPrice.GetPriceInfoList()
local PRICE_ICON_REPLACE = ALPrivate.PRICE_ICON_REPLACE or {}
local DIFFICULTY = AtlasLoot.DIFFICULTY
local TOKEN_NUMBER_DUMMY = AtlasLoot.Data.Token.GetTokenDummyNumberRange()


-- locals
local TT_F = "%s |cFF00ccff%s|r"
local WHITE_TEXT = "|cffffffff%s|r"
local DUMMY_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local ICON_SIZE = ALPrivate.PRICE_ICON_SIZE or 14
local TEXTURE_ICON_F, TEXTURE_ICON_FN = "|T%s:%d|t ", "|T%s:%d|t "
local TT_F_PRICE_T, TT_F_PRICE_TN = "|T%s:%d|t|cFFffffff%s|r", "|T%s:%d|t|cFFffffff%s|r"
local RECIPE_ICON = format(TEXTURE_ICON_F, "Interface\\Icons\\Inv_scroll_03", ICON_SIZE)
local function SafeTexture(path)
	if type(path) ~= "string" or path == "" then
		return DUMMY_ICON
	end
	return path
end

local function SafeSpellTexture(spellID)
	local tex = GetSpellTexture and GetSpellTexture(spellID)
	return SafeTexture(tex)
end

local ICON_TEXTURE = {
	[0]  = format(TEXTURE_ICON_F, DUMMY_ICON, ICON_SIZE),	            -- UNKNOWN
	[1]  = format(TEXTURE_ICON_F, "Interface\\Icons\\INV_Misc_Bag_10", ICON_SIZE),     -- Loot
	[2]  = format(TEXTURE_ICON_F, "Interface\\Icons\\INV_Misc_Note_01", ICON_SIZE),    -- Quest
	[3]  = format(TEXTURE_ICON_F, "Interface\\Icons\\INV_Misc_Coin_01", ICON_SIZE),    -- Buy
    [4]  = format(TEXTURE_ICON_F, "Interface\\Icons\\spell-holy-sealofsacrifice", ICON_SIZE),   -- First Aid
    [5]  = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade_BlackSmithing", ICON_SIZE),          -- Blacksmithing
    [6]  = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade_Leatherworking", ICON_SIZE),         -- Leatherworking
	[7]  = format(TEXTURE_ICON_F, "Interface\\Icons\\trade-alchemy", ICON_SIZE),   -- Alchemy
	[8]  = format(TEXTURE_ICON_F, "Interface\\Icons\\spell-nature-naturetouchgrow", ICON_SIZE),   -- Herbalism
	[9]  = format(TEXTURE_ICON_F, "Interface\\Icons\\inv-misc-food-15", ICON_SIZE),   -- Cooking
	[10] = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade-mining", ICON_SIZE),   -- Mining
	[11] = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade_Tailoring", ICON_SIZE),   -- Tailoring
    [12] = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade_Engineering", ICON_SIZE),            -- Engineering
	[13] = format(TEXTURE_ICON_F, "Interface\\Icons\\Trade_Engraving", ICON_SIZE),   -- Enchanting
	[14] = format(TEXTURE_ICON_F, "Interface\\Icons\\Ttrade-fishing", ICON_SIZE),   -- Fishing
	[15] = format(TEXTURE_ICON_F, "Interface\\Icons\\inv-misc-pelt-wolf-01", ICON_SIZE),   -- Skinning
	-- WotLK: no retail fileIDs; use classic icons
	[17] = format(TEXTURE_ICON_F, "Interface\\Icons\\INV_Misc_Gem_01", ICON_SIZE),     -- Jewelcrafting
    [18] = format(TEXTURE_ICON_F, "Interface\\Icons\\INV_Inscription_Tradeskill01", ICON_SIZE), -- Inscription
}
local UNKNOWN = AL["Unknown"] or "Unknown"

local SOURCE_TYPES = {
	    [0]  = UNKNOWN,	                    -- UNKNOWN
    [1]  = AL["Loot"],                  -- Loot
    [2]  = AL["Quest"],                 -- Quest
    [3]  = AL["Vendor"],                -- Buy
	[4]  = ALIL["First Aid"],           -- First Aid
	[5]  = ALIL["Blacksmithing"],       -- Blacksmithing
	[6]  = ALIL["Leatherworking"],      -- Leatherworking
	[7]  = ALIL["Alchemy"],             -- Alchemy
	[8]  = ALIL["Herbalism"],           -- Herbalism
	[9]  = ALIL["Cooking"],             -- Cooking
	[10] = ALIL["Mining"],              -- Mining
	[11] = ALIL["Tailoring"],           -- Tailoring
	[12] = ALIL["Engineering"],         -- Engineering
	[13] = ALIL["Enchanting"],          -- Enchanting
	[14] = ALIL["Fishing"],             -- Fishing
    [15] = ALIL["Skinning"],            -- Skinning
    [17] = ALIL["Jewelcrafting"],       -- Jewelcrafting
    [18] = ALIL["Inscription"],         -- Inscription
    [19] = ALIL["Archaeology"],          -- Archaelogy
}

local function SanitizeInlineIcons(text)
	if not text or text == "" then return text end
	-- Remove Retail atlas tags (|A:...|a) while keeping the rest of the source text.
	text = text:gsub("|A:[^|]*|a", "")
	return text
end
local SOURCE_DATA = {}
local KEY_WEAK_MT = {__mode="k"}
local AL_MODULE = "AtlasLootClassic_DungeonsAndRaids"
local PRICE_STRING_SPLIT_OR = "-"
local PRICE_STRING_SPLIT_AND = ":"
local PRICE_DELIMITER = " |cFFffffff&|r  "
local PRICE_INFO_TT_START = format(TT_F.."  ", ICON_TEXTURE[3], AL["Vendor"]..":")
local DIFF_SPLIT_STRING = " / "

local function SanitizeMarkup(text)
	if type(text) ~= "string" then return text end
	-- Strip atlas tags (retail-only): |A:AtlasName:...|a
	return text:gsub("%|A:[^%|]*%|a", "")
end

local TooltipsHooked = false
local TooltipCache, TooltipTextCache = {}, {}

-- Addon
Sources.DbDefaults = {
    enabled = true,
    showDropRate = true,
    showProfRank = true,
    showRecipeSource = true,
    showLineBreak = true,
    showVendorPrices = true,
    ["Sources"] = {
        ["*"] = true,
        [16] = false,
    }
}

--Sources.GlobalDbDefaults = {}
local function BuildSource(ini, boss, typ, item, diffID)
    if typ and typ > 3 then
        -- Profession
        local src = ""
        --RECIPE_ICON
        if Sources.db.showRecipeSource then
            local recipe = Recipe.GetRecipeForSpell and Recipe.GetRecipeForSpell(item)
            local sourceData
            for i = #SOURCE_DATA, 1, -1 do
                if recipe and SOURCE_DATA[i].ItemData[recipe] then
                    sourceData = SOURCE_DATA[i]
                end
            end
            if recipe and sourceData then
                if type(sourceData.ItemData[item]) == "number" then
                    sourceData.ItemData[item] = sourceData.ItemData[sourceData.ItemData[item]]
                end

                local data = sourceData.ItemData[recipe]
                if type(data[1]) == "table" then
                    for i = 1, #data do
                        src = src..format(TT_F, RECIPE_ICON, BuildSource(sourceData.AtlasLootIDs[data[i][1]],data[i][2],data[i][3],data[i][4] or item))..(i==#data and "" or "\n")
                    end
                else
                    src = src..format(TT_F, RECIPE_ICON, BuildSource(sourceData.AtlasLootIDs[data[1]],data[2],data[3],data[4] or item))
                end
            end
        end
        if Sources.db.showProfRank then
            local prof = Profession.GetProfessionData(item)
            if prof and prof[3] > 1 then
                return SOURCE_TYPES[typ].." ("..prof[3]..")"..(src ~= "" and "\n"..src or src)
            else
                return SOURCE_TYPES[typ]..(src ~= "" and "\n"..src or src)
            end
        else
            return SOURCE_TYPES[typ]..src
        end
    end
    if ini then
        local iniName, bossName = AtlasLoot.ItemDB:GetNameData_UNSAFE(AL_MODULE, ini, boss)
        local dropRate
        if Sources.db.showDropRate then
            local npcID = AtlasLoot.ItemDB:GetNpcID_UNSAFE(AL_MODULE, ini, boss)
            if type(npcID) == "table" then npcID = npcID[1] end
            dropRate = Droprate:GetData(npcID, item)
        end
        if bossName and diffID then
            -- diff 0 means just heroic
            if diffID == 0 then
                bossName = bossName.." <"..DIFFICULTY.HEROIC.sourceLoc..">"
            elseif type(diffID) == "table" then
                local diffString
                for i = 1, #diffID do
                    diffString = i>1 and (diffString..DIFF_SPLIT_STRING..DIFFICULTY[diffID[i]].sourceLoc) or (DIFFICULTY[diffID[i]].sourceLoc)
                end
                if diffString then
                    bossName = bossName.." <"..diffString..">"
                end
            else
                bossName = bossName.." <"..DIFFICULTY[diffID].sourceLoc..">"
            end
        end
        if iniName and bossName then
            if dropRate then
                return iniName.." - "..bossName.." ("..dropRate.."%)"
            else
                return iniName.." - "..bossName
            end
        elseif iniName then
            if dropRate then
                return iniName.." ("..dropRate.."%)"
            else
                return iniName
            end
        end
    end
    return ""
end

local function GetPriceToolTipString(icon, value)
    if type(icon) == "number" then
        return format(TT_F_PRICE_TN, icon, ICON_SIZE, value)
    else
        return format(TT_F_PRICE_T, icon, ICON_SIZE, value)
    end
end

local function GetPriceFormatString(priceList)
    local fullString = PRICE_INFO_TT_START
    for i = 1, #priceList, 2 do
        local priceType, priceValue = priceList[i], priceList[i+1]
        if i > 1 then fullString = fullString..PRICE_DELIMITER end

        if PRICE_INFO[priceType] then
            if PRICE_INFO[priceType].func then
                fullString = fullString..PRICE_INFO[priceType].func(priceValue)
            elseif PRICE_INFO[priceType].icon then
                fullString = fullString..GetPriceToolTipString(PRICE_INFO[priceType].icon, priceValue)
			elseif PRICE_INFO[priceType].currencyID then
				-- 3.3.5a doesn't provide a stable currencyID->icon API like Retail.
				-- Keep the tooltip readable by using a predefined icon (if any) or a safe dummy icon.
				local icon = PRICE_ICON_REPLACE[priceType] or DUMMY_ICON
				fullString = fullString..GetPriceToolTipString(icon, priceValue)
            elseif PRICE_INFO[priceType].itemID then
                PRICE_INFO[priceType].icon = GetItemIcon(PRICE_INFO[priceType].itemID)
                fullString = fullString..GetPriceToolTipString(PRICE_INFO[priceType].icon, priceValue)
            end
        elseif tonumber(priceType) then
            fullString = fullString..GetPriceToolTipString(GetItemIcon(priceType), priceValue)
        end
    end

    return fullString ~= PRICE_INFO_TT_START and fullString or nil
end

local function GetTokenIcon(token)
    if token >= TOKEN_NUMBER_DUMMY then
        return ICON_TEXTURE[1]
    else
        return format(TEXTURE_ICON_FN, GetItemIcon(token) or DUMMY_ICON, ICON_SIZE)
    end
end

local function BuildSourceFromItemData(item, destTable, itemData, sourceData, iconTexture)
    if not item or not itemData[item] then return end
    if type(itemData[item][1]) == "table" then
        for i, data in ipairs(itemData[item]) do
            if data[3] and Sources.db.Sources[data[3]] then
                destTable[#destTable + 1] = format(TT_F, iconTexture or ICON_TEXTURE[data[3] or 0], BuildSource(sourceData.AtlasLootIDs[data[1]], data[2], data[3], data[4] or item, data[5]))
            end
        end
    else
        local data = itemData[item]
        if data[3] and Sources.db.Sources[data[3]] then
            destTable[#destTable + 1] = format(TT_F, iconTexture or ICON_TEXTURE[data[3] or 0], BuildSource(sourceData.AtlasLootIDs[data[1]], data[2], data[3], data[4] or item, data[5]))
        end
    end
end

local function OnTooltipSetItem_Hook(self)
    if (self.IsForbidden and self:IsForbidden()) or not SOURCE_DATA or not Sources.db.enabled then return end
    local _, item = self:GetItem()
    if not item then return end
    if not TooltipCache[item] then
        TooltipCache[item] = tonumber(strmatch(item, "item:(%d+)"))
    end

    item = TooltipCache[item]

	local vendorHasPrice = Sources.db.showVendorPrices and VendorPrice.ItemHasVendorPrice(item)
	local sourceData
    for i = #SOURCE_DATA, 1, -1 do
        if item and SOURCE_DATA[i].ItemData[item] then
            sourceData = SOURCE_DATA[i]
        end
    end

    if item then
        local newAdded
		if sourceData and not vendorHasPrice and TooltipTextCache[item] ~= false and not TooltipTextCache[item] then
            TooltipTextCache[item] = {}

            -- token data
            if type(sourceData.ItemData[item]) == "number" then
                BuildSourceFromItemData(sourceData.ItemData[item], TooltipTextCache[item], sourceData.ItemData, sourceData, GetTokenIcon(sourceData.ItemData[item]))
            else
                if sourceData.ItemData[item][6] then
                    for i, v in ipairs(sourceData.ItemData[item][6]) do
                        BuildSourceFromItemData(v, TooltipTextCache[item], sourceData.ItemData, sourceData, GetTokenIcon(v))
                    end
                end
                BuildSourceFromItemData(item, TooltipTextCache[item], sourceData.ItemData, sourceData)
            end


            if #TooltipTextCache[item] < 1 then
                TooltipTextCache[item] = false
			elseif #TooltipTextCache[item] > 25 then
				-- If we end up with an excessively large generic list, it is usually a
				-- broken/unknown source lookup. Showing it is misleading ("drops from all heroics").
				TooltipTextCache[item] = false
            end
            newAdded = true
        end

		if vendorHasPrice and (newAdded or not TooltipTextCache[item]) then
            if not TooltipTextCache[item] then
                TooltipTextCache[item] = {}
            end
            local priceString = VendorPrice.GetVendorPriceForItem(item)
            -- split the price string into parts
            local priceInfo = { str_split(PRICE_STRING_SPLIT_OR, priceString) }
            if priceInfo[2] then
                for i = 1, #priceInfo do
                    priceInfo[i] = { str_split(PRICE_STRING_SPLIT_AND, priceInfo[i]) }
                end
            else
                priceInfo = { { str_split(PRICE_STRING_SPLIT_AND, priceInfo[1]) } }
            end

            for priceSumCount = 1, #priceInfo do
                TooltipTextCache[item][ #TooltipTextCache[item] + 1 ] = GetPriceFormatString(priceInfo[priceSumCount])
            end
        end
		if not TooltipTextCache[item] and AtlasLoot.db and AtlasLoot.db.GUI and AtlasLoot.db.GUI.selected and AtlasLoot.db.GUI.selected[1] == "Collections" then
			local sub = AtlasLoot.db.GUI.selected[2]
			if sub and strmatch(sub, "WorldEpics") then
				TooltipTextCache[item] = { AL["World Epics"] }
			end
		end
		if TooltipTextCache[item] then
            if Sources.db.showLineBreak then
                self:AddLine(" ")
            end
            for i = 1, #TooltipTextCache[item] do
				self:AddLine(SanitizeMarkup(TooltipTextCache[item][i]))
            end
        end
    end
end

local function InitTooltips()
    if TooltipsHooked then return end
    Tooltip:AddHookFunction("OnTooltipSetItem", OnTooltipSetItem_Hook)
    TooltipsHooked = true
end

function Sources:UpdateDb()
    self.db = self:GetDb()

    TooltipTextCache = {}
    setmetatable(TooltipTextCache, KEY_WEAK_MT)

    if self.db.enabled then
        AtlasLoot.Loader:LoadModule("AtlasLootClassic_Data", InitTooltips)
        if self.db.showDropRate then
            AtlasLoot.Loader:LoadModule("AtlasLootClassic_DungeonsAndRaids")
        end
    end
end

function Sources.OnInitialize()
    Sources:UpdateDb()
end

function Sources:OnProfileChanged()
    Sources:UpdateDb()
end

function Sources:OnStatusChanged()
    Sources:UpdateDb()
end

function Sources:SetData(dataTable)
    SOURCE_DATA[#SOURCE_DATA+1] = dataTable
end

function Sources:GetSourceTypes()
    return SOURCE_TYPES
end

function Sources:ItemSourcesUpdated(itemID)
    if not itemID then return end
    TooltipTextCache[itemID] = nil
end

Sources:Finalize()
