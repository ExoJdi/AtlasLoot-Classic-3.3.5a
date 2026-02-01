-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)
local tonumber = _G.tonumber
local ipairs = _G.ipairs

-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local addonname = ...

local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or _G.GetAddOnMetadata
local addonVersion = GetAddOnMetadata(addonname, "Version")
if addonVersion == string.format("@%s@", "project-version") then addonVersion = "v99.99.9999-dev" end
local versionT = { string.match(addonVersion, "v(%d+)%.(%d+)%.(%d+)%-?(%a*)(%d*)") }
local addonRevision = ""
for k,v in ipairs(versionT) do
	if k < 4 then
		local it = k == 3 and (4 - #v) or (2 - #v)
		for i = 1, it do
			versionT[k] = "0"..versionT[k]
		end
		addonRevision = addonRevision..versionT[k]
	end
end

_G.AtlasLoot = {
	__addonrevision = tonumber(addonRevision),
	__addonversion = versionT[4] == "dev" and "dev-"..(GetServerTime() or 0) or addonVersion,
	IsDevVersion = versionT[4] == "dev" and true or nil,
	IsTestVersion = (versionT[4] == "beta" or versionT[4] == "alpha") and true or nil,
}

local AtlasLoot = _G.AtlasLoot
AtlasLoot.ItemDB = AtlasLoot.ItemDB or {}
function AtlasLoot.ItemDB:ItemHasVendorPrice(itemID)
	local vp = AtlasLoot.Data and AtlasLoot.Data.VendorPrice
	return itemID and vp and vp[itemID] ~= nil or false
end

local AddonNameVersion = string.format("%s-%d", addonname, _G.AtlasLoot.__addonrevision)
local MainMT = {
	__tostring = function(self)
		return AddonNameVersion
	end,
}
setmetatable(_G.AtlasLoot, MainMT)

-- DB
AtlasLootClassicDB = {}

-- Translations
_G.AtlasLoot.Locale = {}

-- Init functions
_G.AtlasLoot.Init = {}

-- Data table
_G.AtlasLoot.Data = {}

local ADDON_FOLDER = ...
if type(ADDON_FOLDER) ~= "string" or ADDON_FOLDER == "" then
    ADDON_FOLDER = "AtlasLootClassic"
end

local function NormalizeAddonName(n)
    if type(n) ~= "string" then return n end
    n = n:gsub("%-v%d+%.%d+%.%d+.*$", "")
    return n
end

AtlasLoot.NormalizeAddonName = NormalizeAddonName
AtlasLoot.ADDON_FOLDER = ADDON_FOLDER
AtlasLoot.ADDON_NAME = NormalizeAddonName(ADDON_FOLDER)
AtlasLoot.ADDON_PATH = "Interface\\AddOns\\"..ADDON_FOLDER.."\\"

-- Version
local WOW_PROJECT_ID = _G.WOW_PROJECT_ID or 99
local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE or 99
local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC or 1
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 2
local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC or 11

AtlasLoot.RETAIL_VERSION_NUM 	= 99
AtlasLoot.CLASSIC_VERSION_NUM 	= 1
AtlasLoot.BC_VERSION_NUM 		= 2
AtlasLoot.WRATH_VERSION_NUM 	= 3

AtlasLoot.GAME_VERSION_TEXTURES = {
	[AtlasLoot.CLASSIC_VERSION_NUM] = "Interface\\Glues\\Common\\Glues-WoW-Logo",
	[AtlasLoot.BC_VERSION_NUM] = "Interface\\Glues\\Common\\Glues-WoW-BCLogo",
	[AtlasLoot.WRATH_VERSION_NUM] = "Interface\\Glues\\Common\\Glues-WoW-WotLKLogo",
}

AtlasLoot.IS_CLASSIC = false
AtlasLoot.IS_BC = false
AtlasLoot.IS_WRATH = false
AtlasLoot.IS_RETAIL = false

local CurrentGameVersion = AtlasLoot.RETAIL_VERSION_NUM

-- Legacy clients (e.g. 3.3.5a) do not define WOW_PROJECT_ID.
if type(_G.GetBuildInfo) == "function" and tonumber(select(4, _G.GetBuildInfo())) and tonumber(select(4, _G.GetBuildInfo())) < 20000 then
	local v = _G.GetBuildInfo()
	local maj, min, pat = string.match(v or "", "(%d+)%.(%d+)%.(%d+)")
	maj = tonumber(maj)
	if maj == 3 then
		CurrentGameVersion = AtlasLoot.WRATH_VERSION_NUM
		AtlasLoot.IS_WRATH = true
	elseif maj == 2 then
		CurrentGameVersion = AtlasLoot.BC_VERSION_NUM
		AtlasLoot.IS_BC = true
	elseif maj == 1 then
		CurrentGameVersion = AtlasLoot.CLASSIC_VERSION_NUM
		AtlasLoot.IS_CLASSIC = true
	else
		CurrentGameVersion = AtlasLoot.RETAIL_VERSION_NUM
		AtlasLoot.IS_RETAIL = true
	end
else
	local WOW_PROJECT_ID = _G.WOW_PROJECT_ID or 99
	local WOW_PROJECT_MAINLINE = _G.WOW_PROJECT_MAINLINE or 99
	local WOW_PROJECT_CLASSIC = _G.WOW_PROJECT_CLASSIC or 1
	local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = _G.WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 2
	local WOW_PROJECT_WRATH_CLASSIC = _G.WOW_PROJECT_WRATH_CLASSIC or 11
	if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
		CurrentGameVersion = AtlasLoot.RETAIL_VERSION_NUM
		AtlasLoot.IS_RETAIL = true
	elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
		CurrentGameVersion = AtlasLoot.WRATH_VERSION_NUM
		AtlasLoot.IS_WRATH = true
	elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
		CurrentGameVersion = AtlasLoot.BC_VERSION_NUM
		AtlasLoot.IS_BC = true
	elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
		CurrentGameVersion = AtlasLoot.CLASSIC_VERSION_NUM
		AtlasLoot.IS_CLASSIC = true
	end
end

AtlasLoot.CURRENT_VERSION_NUM = CurrentGameVersion

function AtlasLoot:GetGameVersion()
	return CurrentGameVersion
end

-- equal
function AtlasLoot:GameVersion_EQ(gameVersion, ret, retFalse)
	if CurrentGameVersion == gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not equal
function AtlasLoot:GameVersion_NE(gameVersion, ret, retFalse)
	if CurrentGameVersion ~= gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not greater then
function AtlasLoot:GameVersion_GT(gameVersion, ret, retFalse)
	if CurrentGameVersion > gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not lesser then
function AtlasLoot:GameVersion_LT(gameVersion, ret, retFalse)
	if CurrentGameVersion < gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not greater equal
function AtlasLoot:GameVersion_GE(gameVersion, ret, retFalse)
	if CurrentGameVersion >= gameVersion then
		return ret or true
	else
		return retFalse
	end
end

-- not lesser equal
function AtlasLoot:GameVersion_LE(gameVersion, ret, retFalse)
	if CurrentGameVersion <= gameVersion then
		return ret or true
	else
		return retFalse
	end
end
