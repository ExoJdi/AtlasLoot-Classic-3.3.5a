local function StripAtlasTags(text)
    if not text then return text end
    text = text:gsub("|A:.-|a", "")
    return text
end

local ALName, ALPrivate = ...

local _G = _G
local AtlasLoot = _G.AtlasLoot
local ItemDB = {}
AtlasLoot.ItemDB = ItemDB
local AL = AtlasLoot.Locales
local ALIL = AtlasLoot.IngameLocales
local ContentPhase = AtlasLoot.Data.ContentPhase

if not ALPrivate.INSTANCE_NAME_BY_MAPID then
	ALPrivate.INSTANCE_NAME_BY_MAPID = {
		[206] = AL["Utgarde Keep"],
		[1196] = AL["Utgarde Pinnacle"],
		[4100] = AL["The Culling of Stratholme"],
		[4196] = AL["Drak'Tharon Keep"],
		[4228] = AL["The Oculus"],
		[4264] = AL["Halls of Stone"],
		[4265] = AL["The Nexus"],
		[4272] = AL["Halls of Lightning"],
		[4273] = AL["Ulduar"],
		[4277] = AL["Azjol-Nerub"],
		[4415] = AL["The Violet Hold"],
		[4416] = AL["Gundrak"],
		[4493] = AL["The Obsidian Sanctum"],
		[4494] = AL["Ahn'kahet: The Old Kingdom"],
		[4500] = AL["The Eye of Eternity"],
		[4603] = AL["Vault of Archavon"],
		[4722] = AL["Trial of the Crusader"],
		[4723] = AL["Trial of the Champion"],
		[4809] = AL["The Forge of Souls"],
		[4812] = AL["Icecrown Citadel"],
		[4813] = AL["Pit of Saron"],
		[4820] = AL["Halls of Reflection"],
		[4987] = AL["The Ruby Sanctum"],
		[3456] = AL["Naxxramas"],
		[2159] = AL["Onyxia's Lair"],
		[2437] = ALIL["Ragefire Chasm"],
		[718] = ALIL["Wailing Caverns"],
		[1581] = ALIL["The Deadmines"],
		[209] = ALIL["Shadowfang Keep"],
		[719] = ALIL["Blackfathom Deeps"],
		[717] = ALIL["The Stockade"],
		[721] = ALIL["Gnomeregan"],
		[491] = ALIL["Razorfen Kraul"],
		[722] = ALIL["Razorfen Downs"],
		[796] = ALIL["Scarlet Monastery"],
		[1337] = ALIL["Uldaman"],
		[1176] = ALIL["Zul'Farrak"],
		[2100] = ALIL["Maraudon"],
		[1477] = ALIL["The Temple of Atal'Hakkar"],
		[1584] = ALIL["Blackrock Depths"],
		[1583] = ALIL["Blackrock Spire"],
		[2557] = ALIL["Dire Maul"],
		[2017] = ALIL["Stratholme"],
		[2057] = ALIL["Scholomance"],
		[2717] = ALIL["Molten Core"],
		[2677] = ALIL["Blackwing Lair"],
		[1977] = ALIL["Zul'Gurub"],
		[3428] = ALIL["Ruins of Ahn'Qiraj"],
		[3429] = ALIL["Temple of Ahn'Qiraj"],
	}
end

-- lua
local assert, setmetatable, rawset = _G.assert, _G.setmetatable, _G.rawset
local type = _G.type
local select = _G.select
local pairs, unpack = _G.pairs, _G.unpack
local match, str_split, format = _G.string.match, _G.string.split, _G.string.format

local STRING_TYPE = "string"
local BOSS_LINK_FORMAT = "%s:%s:%s"
local LEVEL_RANGE_FORMAT = "  (|cffff0000%d|r: |cffff8040%d|r - |cff40bf40%d|r)"--"  <|cffff0000%d|r |cffff8040%d|r |cffffff00%d|r |cff40bf40%d|r>"
local LEVEL_RANGE_FORMAT2 = "  (|cffff8040%d|r - |cff40bf40%d|r)"
local CONTENT_PHASE_FORMAT = "|cff00FF96".."<P: %g>".."|r"

-- Saves all the items ;)
ItemDB.Storage = {}

-- Functions for a item database
ItemDB.Proto = {}
ItemDB.ContentProto = {}

-- List of content from addons
local contentList = {}

-- NpcListTable /run print(string.split("-", UnitGUID"target"))
-- ItemDB.NpcList = {}

-- the metatable
ItemDB.contentMt = {
    __index = ItemDB.ContentProto
}
-- clean nil boss entrys from DB
-- WARNING: This breaks Sources addon
local function CleanNilBossEntrys(oldTab)
    local newItemTab = {}
    for i = 1, #oldTab.items do
        if oldTab.items[i] ~= nil then
            newItemTab[#newItemTab + 1] = oldTab.items[i]
        end
    end
    oldTab.items = newItemTab
    return oldTab
end

ItemDB.mt = {
    __newindex = function(t, k, v)
        t.__atlaslootdata.contentCount = t.__atlaslootdata.contentCount + 1
        v = CleanNilBossEntrys(v) -- debug, re-added to test clearing invalid bosses in vanilla
        setmetatable(v, ItemDB.contentMt)
        contentList[t.__atlaslootdata.addonName][t.__atlaslootdata.contentCount] = k
        contentList[t.__atlaslootdata.addonName][k] = t.__atlaslootdata.contentCount
        v.__atlaslootdata = t.__atlaslootdata
        AtlasLoot.Data.AutoSelect:AddInstanceTable(t.__atlaslootdata.addonName, k, v)
        v.gameVersion = v.gameVersion or t.__atlaslootdata.__gameVersion
        if not t.__atlaslootdata.gameVersions[v.gameVersion] then
            t.__atlaslootdata.gameVersions[v.gameVersion] = true
        end
        rawset(t, k, v)
    end
}

local function GetContentPhaseFromTable(tab)
    if ALPrivate.IS_WOTLK then
        return tab.ContentPhaseWrath
    elseif ALPrivate.IS_BC then
        return tab.ContentPhaseBC
    elseif ALPrivate.IS_CLASSIC then
        return tab.ContentPhase
    end
end

--- Adds/Gets the table for a item database
-- @param	addonName		<string> full name of the addon folder (eg "AtlasLoot_MistsofPandaria")
-- @param	tierID			<number> the tier id of the EJ
function ItemDB:Add(addonName, tierID, gameVersion)
    gameVersion = gameVersion or 0
    if not ItemDB.Storage[addonName] then
        ItemDB.Storage[addonName] = {}
        for k,v in pairs(ItemDB.Proto) do
            ItemDB.Storage[addonName][k] = v
        end
        ItemDB.Storage[addonName].__atlaslootdata = {
            addonName = addonName,
            contentCount = 0,
            tierID = tierID,
            gameVersions = {}
        }
        setmetatable(ItemDB.Storage[addonName], ItemDB.mt)
        contentList[addonName] = {}
    end
    ItemDB.Storage[addonName].__atlaslootdata.gameVersions[gameVersion] = true
    ItemDB.Storage[addonName].__atlaslootdata.__gameVersion = gameVersion
    return ItemDB.Storage[addonName]
end

function ItemDB:Get(addonName)
    --assert(ItemDB.Storage[addonName], addonName.." not found!")
    return ItemDB.Storage[addonName]
end

function ItemDB:GetBossTable(addonName, contentName, boss)
    if ItemDB.Storage[addonName] and ItemDB.Storage[addonName][contentName] and ItemDB.Storage[addonName][contentName].items[boss] then
        return ItemDB.Storage[addonName][contentName].items[boss]
    end
end

function ItemDB:GetDifficulty(addonName, contentName, boss, dif)
    dif = dif or 1
    local diffs = ItemDB.Storage[addonName]:GetDifficultys()
    -- first try to get the next lower difficulty
    -- if nothing found get higher one or try again with lowest difficulty
    local count = dif
    local numDiffs = #diffs
    while true do
        if count == 0 then
            count = dif + 1
        elseif count > numDiffs then
            --error(dif.." (dif) not found! -> "..boss)
            return ItemDB:GetDifficulty(addonName, contentName, boss, 1)
        end
        if ItemDB.Storage[addonName][contentName].items[boss][count] then
            return count
        end
        if count > dif then
            count = count + 1
        else
            count = count - 1
        end
    end
end

local function getItemTableType(addonName, contentName, boss, dif)
    local tab = ItemDB.Storage[addonName]
    local typ = nil

    if tab[contentName].items[boss][dif].__linkedInfo then
        local newData = tab[contentName].items[boss][dif].__linkedInfo
        addonName, contentName, boss, dif = newData[1], newData[2], newData[3], newData[4]
        tab = ItemDB.Storage[addonName]
    end

    if tab[contentName].items[boss][dif].TableType then
        typ = tab:GetItemTableType(tab[contentName].items[boss][dif].TableType)
    elseif tab[contentName].items[boss].TableType then
        typ = tab:GetItemTableType(tab[contentName].items[boss].TableType)
    elseif tab[contentName].items.TableType then
        typ = tab:GetItemTableType(tab[contentName].items.TableType)
    elseif tab[contentName].TableType then
        typ = tab:GetItemTableType(tab[contentName].TableType)
    else
        typ = tab:GetItemTableType(1)
    end

    typ.extra = ItemDB.Storage[addonName]:GetAllExtraItemTableType()

    return typ
end

local function getItemsFromDiff(curBossTab, iniTab)
    -- first cache all positions that allready set
    local tmp = {}
    for i = 1, #curBossTab do
        tmp[ curBossTab[i][1] ] = true
    end
    -- now copy all items from the other difficulty
    local bossTab = iniTab[ curBossTab.GetItemsFromDiff ]
    assert(bossTab, "Diff '"..curBossTab.GetItemsFromDiff.."' not found" )
    if bossTab.GetItemsFromDiff then
        getItemsFromDiff(bossTab, iniTab)
    end
    for i = 1, #bossTab do
        if not tmp[ bossTab[i][1] ] then
            curBossTab[ #curBossTab+1 ] = bossTab[i]
        end
    end
    curBossTab.GetItemsFromDiff = nil
end

local currentModuleLoadingInfo = nil
local function loadItemsFromOtherModule(moduleLoader, loadString, contentTable, curContentName, curBossID, curAddonName, curDiff)
    if loadString then
        currentModuleLoadingInfo = {loadString, contentTable, curContentName, curBossID, curAddonName, curDiff}
    elseif currentModuleLoadingInfo then
        loadString, contentTable, curContentName, curBossID, curAddonName, curDiff = currentModuleLoadingInfo[1], currentModuleLoadingInfo[2], currentModuleLoadingInfo[3], currentModuleLoadingInfo[4], currentModuleLoadingInfo[5], currentModuleLoadingInfo[6]
    else
        return
    end

    local addonName, contentName, bossID, shortDiff = str_split(":", loadString)
    if (moduleLoader and moduleLoader ~= addonName) then
        return
    end
    bossID = tonumber(bossID)

    local loadState = AtlasLoot.Loader:LoadModule(addonName, nil, "itemDB")
    if loadState == "InCombat" or loadState == "DISABLED" or loadState == "MISSING" then
        AtlasLoot.Loader:LoadModule(addonName, loadItemsFromOtherModule, "itemDB")
        return addonName, loadState
    elseif contentName and ItemDB.Storage[addonName] then
        -- get name of diff
        local newDif = ItemDB.Storage[curAddonName]:GetDifficultyUName(curDiff)
        -- get new diff ID
        if newDif or shortDiff then
            newDif = ItemDB.Storage[addonName]:GetDifficultyByName(shortDiff or newDif)
        else
            newDif = ItemDB.Storage[curAddonName]:GetDifficultyUName(curDiff) or ItemDB.Storage[curAddonName]:GetDifficultyName(curDiff)
            newDif = ItemDB.Storage[addonName]:GetDifficultyByName(newDif)
        end
        --contentTable[curDiff] = setmetatable({__linkedInfo = {addonName, contentName, bossID, newDif}}, { __index =ItemDB.Storage[addonName][contentName].items[bossID][newDif]})
        contentTable[curContentName].items[curBossID][curDiff] = ItemDB.Storage[addonName][contentName].items[bossID][newDif]
        if not contentTable[curContentName].items[curBossID][curDiff] then
            error("Linked Loottable not found contentName:"..(curContentName or "nil").." bossID:"..(curBossID or "nil").." dif:"..(curDiff or "nil"))
        end
        contentTable[curContentName].items[curBossID][curDiff].__linkedInfo = {addonName, contentName, bossID, newDif}
        currentModuleLoadingInfo = nil
    elseif ItemDB.Storage[addonName] then
        -- getBossID by name
        local bossID = contentTable[curContentName]:GetNameForItemTable(curBossID)
        for i=1, #ItemDB.Storage[addonName][curContentName].items do
            --print(ItemDB.Storage[addonName][curContentName]:GetNameForItemTable(i), bossID)
            if ItemDB.Storage[addonName][curContentName]:GetNameForItemTable(i) == bossID then
                bossID = i
                break
            end
        end
        if type(bossID) ~= "number" then
            error("No boss found for ID:"..curBossID.." name:"..bossID.." module:"..addonName.." contentName:"..curContentName)
        end
        loadString = format(BOSS_LINK_FORMAT, addonName, curContentName, bossID)
        currentModuleLoadingInfo = { loadString, contentTable, curContentName, curBossID, curAddonName, curDiff }
        loadItemsFromOtherModule()
    end
end

function ItemDB:GetItemTable(addonName, contentName, boss, dif)
    assert(addonName and ItemDB.Storage[addonName], tostring(addonName).." (addonName) not found!")
    assert(contentName and ItemDB.Storage[addonName][contentName], tostring(contentName).." (contentName) not found!")
    if not (boss and ItemDB.Storage[addonName][contentName].items[boss]) then
        return {}
    end
    local addonNameRETVALUE, addon
    if ItemDB.Storage[addonName][contentName].items[boss].link then
        return ItemDB:GetItemTable(ItemDB.Storage[addonName][contentName].items[boss].link[1], ItemDB.Storage[addonName][contentName].items[boss].link[2], ItemDB.Storage[addonName][contentName].items[boss].link[3], dif)
    end
    if type(dif) == STRING_TYPE then
        dif = ItemDB.Storage[addonName]:GetDifficultyByName(dif)
    end
    if not ItemDB.Storage[addonName][contentName].items[boss][dif] then
        dif = ItemDB:GetDifficulty(addonName, contentName, boss, dif)
    end
    currentModuleLoadingInfo = nil

    if ItemDB.Storage[addonName][contentName].items[boss][dif] then
        local bossDiff = ItemDB.Storage[addonName][contentName].items[boss][dif]
        -- get the items table from a string
        if type(bossDiff) == STRING_TYPE then
            local notLoadedAddonName, reason = loadItemsFromOtherModule(nil, bossDiff, ItemDB.Storage[addonName], contentName, boss, addonName, dif)
            if notLoadedAddonName then
                return notLoadedAddonName, reason, ItemDB.Storage[addonName]:GetDifficultyData(dif)
            end
        -- get the items table from a other difficulty
        elseif type(bossDiff) == "number" then
            ItemDB.Storage[addonName][contentName].items[boss][dif] = ItemDB.Storage[addonName][contentName].items[boss][ bossDiff ]
        -- get items from another difficulty
        elseif bossDiff.GetItemsFromDiff then
            getItemsFromDiff(bossDiff, ItemDB.Storage[addonName][contentName].items[boss])
        end
    end

    --assert(dif and ItemDB.Storage[addonName][contentName].items[boss][dif], dif.." (dif) not found!")
    return ItemDB.Storage[addonName][contentName].items[boss][dif], getItemTableType(addonName, contentName, boss, dif), ItemDB.Storage[addonName]:GetDifficultyData(dif)
end

function ItemDB:GetModuleList(addonName)
    if not addonName then return {} end
    if not contentList[addonName] then return {} end
    return contentList[addonName]
end

-- iniName, bossName
function ItemDB:GetNameData_UNSAFE(addonName, contentName, boss, diff)
    if not ItemDB.Storage[addonName] or not ItemDB.Storage[addonName][contentName] then return end
    return ItemDB.Storage[addonName][contentName]:GetName(true), ItemDB.Storage[addonName][contentName]:GetNameForItemTable(boss, true), ItemDB.Storage[addonName]:GetDifficultyName(diff)
end

function ItemDB:GetNpcID_UNSAFE(addonName, contentName, boss)
    if not ItemDB.Storage[addonName] or not ItemDB.Storage[addonName][contentName] or not ItemDB.Storage[addonName][contentName].items[boss] then return end
    return ItemDB.Storage[addonName][contentName].items[boss].npcID
end

function ItemDB:GetCorrespondingField(addonName, contentName, newGameVersion)
    if not addonName or not contentName or not newGameVersion then return end
    if ItemDB.Storage[addonName] and ItemDB.Storage[addonName][contentName] and ItemDB.Storage[addonName][contentName].CorrespondingFields then
        return ItemDB.Storage[addonName][contentName].CorrespondingFields[newGameVersion]
    end
end

-- ##################################################
--	TableProto
-- ##################################################

--[[
    like Heroic, Normal, 25Man
]]
local difficultys = {}

function ItemDB.Proto:AddDifficulty(dif, uniqueName, difficultyID, tierID, textIsHiddenInHeader)
    assert(dif, "No 'dif' given.")

    if dif and AtlasLoot.DIFFICULTY[dif] then
        local difTab = AtlasLoot.DIFFICULTY[dif]
        dif = difTab.loc
        uniqueName = difTab.short
        difficultyID = difTab.id
    end

    if not difficultys[self.__atlaslootdata.addonName] then
        difficultys[self.__atlaslootdata.addonName] = {
            counter = 0,
            names = {},
            uniqueNames = {},
            data = {}
        }
    end
    local diffTab = difficultys[self.__atlaslootdata.addonName]

    if not diffTab.uniqueNames[uniqueName] or not diffTab.names[dif] then
        diffTab.counter = diffTab.counter + 1
        diffTab.names[dif] = diffTab.counter
        if uniqueName then
            diffTab.uniqueNames[uniqueName] = diffTab.counter
        end
        diffTab.data[diffTab.counter] = {
            name = dif,
            uniqueName = uniqueName,
            difficultyID = difficultyID,
            tierID = tierID or ItemDB.Storage[self.__atlaslootdata.addonName].__atlaslootdata.tierID,
            textIsHidden = textIsHiddenInHeader,
        }
    end
    return diffTab.uniqueNames[uniqueName] or diffTab.names[dif]
end

function ItemDB.Proto:GetTierID(dif)
    return (dif and difficultys[self.__atlaslootdata.addonName].data[dif]) and difficultys[self.__atlaslootdata.addonName].data[dif].tierID or nil
end

function ItemDB.Proto:GetDifficultyByName(dif)
    return dif and ( difficultys[self.__atlaslootdata.addonName].uniqueNames[dif] or difficultys[self.__atlaslootdata.addonName].names[dif] ) or nil
end

function ItemDB.Proto:GetDifficultyName(dif)
    return (dif and difficultys[self.__atlaslootdata.addonName].data[dif]) and difficultys[self.__atlaslootdata.addonName].data[dif].name or nil
end

function ItemDB.Proto:GetDifficultyByID(id)
    for i = 1, #difficultys[self.__atlaslootdata.addonName].data do
        if difficultys[self.__atlaslootdata.addonName].data[i].difficultyID == id then
            return i
        end
    end
end

function ItemDB.Proto:GetDifficultyUName(dif)
    return (dif and difficultys[self.__atlaslootdata.addonName].data[dif]) and difficultys[self.__atlaslootdata.addonName].data[dif].uniqueName or nil
end

function ItemDB.Proto:GetDifficultyID(dif)
    return (dif and difficultys[self.__atlaslootdata.addonName].data[dif]) and difficultys[self.__atlaslootdata.addonName].data[dif].difficultyID or nil
end

function ItemDB.Proto:GetDifficultyData(difID)
    return difficultys[self.__atlaslootdata.addonName].data[difID]
end

function ItemDB.Proto:GetDifficultys()
    return difficultys[self.__atlaslootdata.addonName].data
end

--[[
    New box for the dropdown menus
]]
local content_types = {}

function ItemDB.Proto:AddContentType(typ, color)
    assert(typ, "No 'typ' given.")
    if not content_types[self.__atlaslootdata.addonName] then content_types[self.__atlaslootdata.addonName] = {} end
    if not content_types[self.__atlaslootdata.addonName][typ] then
        content_types[self.__atlaslootdata.addonName][ #content_types[self.__atlaslootdata.addonName] + 1 ] = {typ, color or ATLASLOOT_UNKNOWN_COLOR}
        --table.insert(content_types[self.__atlaslootdata.addonName], {typ, color or ATLASLOOT_UNKNOWN_COLOR})
        content_types[self.__atlaslootdata.addonName][typ] = #content_types[self.__atlaslootdata.addonName]
    end
    return content_types[self.__atlaslootdata.addonName][typ]
end

function ItemDB.Proto:GetContentTypes()
    return content_types[self.__atlaslootdata.addonName]
end

local iTable_types = {}

function ItemDB.Proto:AddItemTableType(...)
    local tab = AtlasLoot.Button:CreateFormatTable({...})
    if not iTable_types[self.__atlaslootdata.addonName] then iTable_types[self.__atlaslootdata.addonName] = {} end
    iTable_types[self.__atlaslootdata.addonName][#iTable_types[self.__atlaslootdata.addonName]+1] = tab
    return #iTable_types[self.__atlaslootdata.addonName]
end

function ItemDB.Proto:GetItemTableType(index)
    return iTable_types[self.__atlaslootdata.addonName] and iTable_types[self.__atlaslootdata.addonName][index] or nil
end

local extra_iTable_types = {}

function ItemDB.Proto:AddExtraItemTableType(typ)
    if not extra_iTable_types[self.__atlaslootdata.addonName] then extra_iTable_types[self.__atlaslootdata.addonName] = {} end
    for i = 1, #extra_iTable_types[self.__atlaslootdata.addonName] do
        if extra_iTable_types[self.__atlaslootdata.addonName][i] == type then
            return i + 100
        end
    end
    extra_iTable_types[self.__atlaslootdata.addonName][#extra_iTable_types[self.__atlaslootdata.addonName]+1] = typ
    return #extra_iTable_types[self.__atlaslootdata.addonName] + 100
end

function ItemDB.Proto:GetExtraItemTableType(index)
    return extra_iTable_types[self.__atlaslootdata.addonName] and ( extra_iTable_types[self.__atlaslootdata.addonName][index] or extra_iTable_types[self.__atlaslootdata.addonName][index+100] ) or nil
end

function ItemDB.Proto:GetAllExtraItemTableType(index)
    return extra_iTable_types[self.__atlaslootdata.addonName]
end

function ItemDB.Proto:CheckForLink(dataID, boss, load)
    assert(dataID, self[dataID], "dataID not found - "..dataID)
    assert(boss, self[dataID].items[boss], "boss not found - "..boss)
    if self[dataID].items[boss] and self[dataID].items[boss].link then
        local link = self[dataID].items[boss].link
        if AtlasLoot.Loader:IsModuleLoaded(link[1]) then
            assert(ItemDB.Storage[link[1]], "module "..link[1].." not found")
            assert(ItemDB.Storage[link[1]][link[2]], "dataID "..link[2].." not found in module "..link[1])
            assert(ItemDB.Storage[link[1]][link[2]].items[link[3]], "boss "..link[3].." not found in dataID "..link[2]..", module "..link[1])
            self[dataID].items[boss] = ItemDB.Storage[link[1]][link[2]].items[link[3]]
        elseif load then
            local combat = AtlasLoot.Loader:LoadModule(self[dataID].items[boss].link[1], function() self:CheckForLink(dataID, boss) end, true)
            if combat then
                print"InCombat :("
            end
        end
    end
end

function ItemDB.Proto:GetDifficulty(dataID, boss, dif)
    return ItemDB:GetDifficulty(self.__atlaslootdata.addonName, dataID, boss, dif)
end

function ItemDB.Proto:IsGameVersionAviable(version)
    return self.__atlaslootdata.gameVersions[version] and true or false
end

function ItemDB.Proto:GetAviableGameVersion(version)
    if self.__atlaslootdata.gameVersions[version] then
        return version
    elseif self.__atlaslootdata.gameVersions[AtlasLoot:GetGameVersion()] then
        return AtlasLoot:GetGameVersion()
    else
        return self.__atlaslootdata.__gameVersion
    end
end
-- ##################################################
--	ContentProto
-- ##################################################
local SpecialMobList = {
    elite           = "|TInterface\\AddOns\\AtlasLootClassic\\Images\\Icons\\EliteI:12:12:0:0|t",
    rare            = "|TInterface\\AddOns\\AtlasLootClassic\\Images\\Icons\\RareI:12:12:0:0|t",
    quest           = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12|t",
    questTurnIn     = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12|t",
    boss            = "|TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:12:12|t",
    vendor          = "|TInterface\\GossipFrame\\VendorGossipIcon:12:12|t",
    summon          = "|TInterface\\Icons\\Spell_Arcane_TeleportDalaran:12:12|t",
    scourgeInvasion = "|TInterface\\Icons\\Inv_jewelry_talisman_13:12:12|t",
}

--- Get the content Type
-- @return ContentName, ContentIndex
function ItemDB.ContentProto:GetContentType()
    if not self.ContentType then
        error("ContentType not set for <"..self.__atlaslootdata.addonName.." / "..self.name..">")
        return nil
    end
    assert(content_types[self.__atlaslootdata.addonName][self.ContentType], self.ContentType.." not found!")
    return content_types[self.__atlaslootdata.addonName][self.ContentType][1], self.ContentType, content_types[self.__atlaslootdata.addonName][self.ContentType][2]
end

function ItemDB.ContentProto:GetName(raw)
    if self.AreaID and not self.MapID then
        self.MapID = self.AreaID
    end
    local name
    local addEnd = ""
    if not raw then
        if AtlasLoot.db.showLvlRange and self.LevelRange then
            if AtlasLoot.db.showMinEnterLvl then
                addEnd = format(LEVEL_RANGE_FORMAT, self.LevelRange[1] or 0, self.LevelRange[2] or 0, self.LevelRange[3] or 0 )
            else
                addEnd = format(LEVEL_RANGE_FORMAT2, self.LevelRange[2] or 0, self.LevelRange[3] or 0 )
            end
        end
        if AtlasLoot.db.ContentPhases.enableOnLootTable and not ContentPhase:IsActive(GetContentPhaseFromTable(self), self.gameVersion) then
            addEnd = addEnd.."  "..format(CONTENT_PHASE_FORMAT, GetContentPhaseFromTable(self))
        end
    end
    if self.name then
        name = self.name..addEnd
    elseif self.MapID then
        local instName = ALPrivate.INSTANCE_NAME_BY_MAPID and ALPrivate.INSTANCE_NAME_BY_MAPID[self.MapID]
        if instName then
            name = instName..addEnd
        elseif C_Map and C_Map.GetAreaInfo then
            local areaName = C_Map.GetAreaInfo(self.MapID)
            name = (areaName and (areaName..addEnd)) or ("MapID:"..self.MapID..addEnd)
        else
            name = "MapID:"..self.MapID..addEnd
        end
    elseif self.EncounterJournalID and EJ_GetInstanceInfo then
        local instName = EJ_GetInstanceInfo(self.EncounterJournalID)
        if instName then
            name = instName..addEnd
        else
            name = "EncounterJournalID:"..self.EncounterJournalID..addEnd
        end
elseif self.FactionID then
        name = AtlasLoot:Faction_GetFactionName(self.FactionID)..addEnd
    elseif self.AchievementID then
        name = select(2, GetAchievementInfo(self.AchievementID))
    else
        name = UNKNOWN
    end
    if self.nameFormat then
        name = format(self.nameFormat, name)
    end
    if self.NameColor and not raw and AtlasLoot.db.enableColorsInNames then
        name = format(self.NameColor, name)
    end
    return StripAtlasTags(name)
end

function ItemDB.ContentProto:GetInfo()
    if self.info then
        return self.info
	elseif self.EncounterJournalID and EJ_GetInstanceInfo then
		return select(2, EJ_GetInstanceInfo(self.EncounterJournalID))
    elseif self.FactionID then
        return select(2, GetFactionInfoByID(self.FactionID))
    end
end

function ItemDB.ContentProto:GetNameForItemTable(index, raw)
    assert(self.items, "items table not found.")
    if raw and not self.items[index] then return end
    assert(index and self.items[index], "index not found.")
    index = self.items[index]
    local name
    local addStart, addEnd = "", ""
    if not raw then
        if AtlasLoot.db.ContentPhases.enableOnLootTable and not ContentPhase:IsActive(GetContentPhaseFromTable(index), index.gameVersion or self.gameVersion) then
            addEnd = addEnd.." "..format(CONTENT_PHASE_FORMAT, GetContentPhaseFromTable(index))
        end
        if AtlasLoot.db.enableBossLevel and index.Level then
            if type(index.Level) == "table" then
                addStart = addStart.."|cff808080<"..index.Level[1].." - "..index.Level[2]..">|r "
            elseif index.Level == 999 then
                addStart = addStart..SpecialMobList.boss
            else
                addStart = addStart.."|cff808080<"..(index.Level == 999 and SpecialMobList.boss or index.Level)..">|r "
            end
        end
        if index.specialType and SpecialMobList[index.specialType] then
            addStart = addStart..SpecialMobList[index.specialType]
        end
    end
    if index.name then
        name = addStart..index.name..addEnd
    elseif index.MapID then
		local instName = ALPrivate.INSTANCE_NAME_BY_MAPID and ALPrivate.INSTANCE_NAME_BY_MAPID[index.MapID]
		if instName then
			name = instName..addEnd
		elseif C_Map and C_Map.GetAreaInfo then
			local areaName = C_Map.GetAreaInfo(index.MapID)
			name = (areaName and (areaName..addEnd)) or ("MapID:"..index.MapID..addEnd)
		else
			name = "MapID:"..index.MapID..addEnd
		end
	elseif index.EncounterJournalID and EJ_GetEncounterInfo then
		local encName = EJ_GetEncounterInfo(index.EncounterJournalID)
		name = (encName and (addStart..encName..addEnd)) or ("EncounterJournalID:"..index.EncounterJournalID)
    elseif index.FactionID then
        name = addStart..GetFactionInfoByID(index.FactionID)..addEnd
    elseif index.AchievementID then
        name = select(2, GetAchievementInfo(index.AchievementID))
    else
        name = UNKNOWN
    end
    if index.nameFormat then
        name = format(index.nameFormat, name)
    end
    if index.NameColor and not raw and AtlasLoot.db.enableColorsInNames then
        name = format(index.NameColor, name)
    end
    return StripAtlasTags(name)
end

function ItemDB:ItemHasVendorPrice(itemID)
	if not itemID then return false end
	local vp = AtlasLoot.Data and AtlasLoot.Data.VendorPrice
	return vp and vp[itemID] ~= nil or false
end
