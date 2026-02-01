local ALName, ALPrivate = ...

ALPrivate.PRICE_ICON_SIZE = 12

-- ##############################
-- Global
-- ##############################

-- PreSet ID's for special itemtable options

--- Ignore this item while filter is enabled
-- ATLASLOOT_IT_FILTERIGNORE = true
ATLASLOOT_IT_FILTERIGNORE = 900

--- Setup the item for a faction
-- ATLASLOOT_IT_HORDE = true		<- this is a Horde only item (shown in lootpage but with horde background you can hide the item if you set ATLASLOOT_IT_ALLIANCE = false( example { 1, 1234, [ATLASLOOT_IT_HORDE] = true } )
-- ATLASLOOT_IT_HORDE = 1234		<- the Horde version of this item is 1234 ( example { 1, [ATLASLOOT_IT_HORDE] = 1234, [ATLASLOOT_IT_ALLIANCE] = 5678 }
ATLASLOOT_IT_HORDE = 901
ATLASLOOT_IT_ALLIANCE = 902

--- Ads a item amount
ATLASLOOT_IT_AMOUNT1 = 903		-- item1
ATLASLOOT_IT_AMOUNT2 = 904		-- item2

-- Colors
ATLASLOOT_COLLECTION_COLOR 		= {0.3, 0.3, 0, 1}
ATLASLOOT_DUNGEON_COLOR 		= {0, 0, 0.3, 1}
ATLASLOOT_FACTION_COLOR 		= {0, 0.3, 0, 1}
ATLASLOOT_PERMRECEVENTS_COLOR 	= {0.2, 0, 0.4, 1}
ATLASLOOT_PRIMPROFESSION_COLOR 	= {0.35, 0.15, 0.2, 1}
ATLASLOOT_PVP_COLOR 			= {0, 0.36, 0.24, 1}
ATLASLOOT_RAID_COLOR			= {0.3, 0, 0, 1}
ATLASLOOT_RAID40_COLOR			= {0.3, 0, 0, 1}
ATLASLOOT_RAID20_COLOR			= {0.5, 0.1, 0, 1}
ATLASLOOT_REMOVED_COLOR 		= {0.4, 0.2, 0, 1}
ATLASLOOT_SEASONALEVENTS_COLOR 	= {0.36, 0, 0.24, 1}
ATLASLOOT_SECPROFESSION_COLOR 	= {0.5, 0.1, 0, 1}
ATLASLOOT_WORLD_BOSS_COLOR 		= {0.74, 0.0, 0.28, 1}
ATLASLOOT_COLLECTIONS_COLOR		= {0.64, 0.21, 0.93, 1}
ATLASLOOT_CLASSPROFESSION_COLOR = ATLASLOOT_FACTION_COLOR
ATLASLOOT_UNKNOWN_COLOR 		= {0, 0, 0, 1}
ATLASLOOT_HORDE_COLOR			= {1, 0, 0, 0.8}
ATLASLOOT_ALLIANCE_COLOR		= {0, 0, 1, 0.8}

ATLASLOOT_ITEM_BACKGROUND_ALPHA = 0.9

-- ##############################
-- AtlasLoot Private things
-- ##############################

-- GameVersion
ALPrivate.IS_CLASSIC 	= AtlasLoot:GetGameVersion() == AtlasLoot.CLASSIC_VERSION_NUM
ALPrivate.IS_BC 		= AtlasLoot:GetGameVersion() == AtlasLoot.BC_VERSION_NUM
ALPrivate.IS_WOTLK 		= AtlasLoot:GetGameVersion() == AtlasLoot.WRATH_VERSION_NUM

-- Account specific
ALPrivate.ACCOUNT_LOCALE = GetLocale()
ALPrivate.PLAYER_NAME = UnitName("player")

-- Image path
ALPrivate.IMAGE_PATH = "Interface\\AddOns\\"..ALName.."\\Images\\"
local ICONS_PATH = ALPrivate.IMAGE_PATH.."Icons\\"
ALPrivate.ICONS_PATH = ICONS_PATH

-- Mostly used in selection template
ALPrivate.COIN_TEXTURE = {
    GOLD 		= {	texture = "Interface\\MoneyFrame\\UI-GoldIcon" },
    SILVER 		= {	texture = "Interface\\MoneyFrame\\UI-SilverIcon" },
    COPPER		= {	texture = "Interface\\MoneyFrame\\UI-CopperIcon" },
    AC 			= {	texture = "Interface\\AchievementFrame\\UI-Achievement-TinyShield", texCoord = {0, 0.625, 0, 0.625} },
    REPUTATION 	= {	texture = "Interface\\Icons\\Achievement_Reputation_08" },

    CLASSIC 	= {	texture = AtlasLoot.GAME_VERSION_TEXTURES[AtlasLoot.CLASSIC_VERSION_NUM], width = 2.0 },
    BC		 	= {	texture = AtlasLoot.GAME_VERSION_TEXTURES[AtlasLoot.BC_VERSION_NUM], width = 2.0 },
    WRATH	 	= {	texture = AtlasLoot.GAME_VERSION_TEXTURES[AtlasLoot.WRATH_VERSION_NUM], width = 2.0 },

    -- 3.3.5a: use square class icons from the class sheet
    WARRIOR 	= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.00, 0.25, 0.00, 0.25} },
    MAGE 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.25, 0.50, 0.00, 0.25} },
    ROGUE 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.50, 0.75, 0.00, 0.25} },
    DRUID 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.75, 1.00, 0.00, 0.25} },
    HUNTER 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.00, 0.25, 0.25, 0.50} },
    SHAMAN 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.25, 0.50, 0.25, 0.50} },
    PRIEST 		= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.50, 0.75, 0.25, 0.50} },
    WARLOCK 	= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.75, 1.00, 0.25, 0.50} },
    PALADIN 	= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.00, 0.25, 0.50, 0.75} },
    DEATHKNIGHT	= {	texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes", texCoord = {0.25, 0.50, 0.50, 0.75} },
}

-- Simple backdrop for SetBackdrop
ALPrivate.BOX_BACKDROP = { bgFile = "Interface/Tooltips/UI-Tooltip-Background" }
-- backdrop with border
ALPrivate.BOX_BORDER_BACKDROP = {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 14,
    edgeSize = 14,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

ALPrivate.CLASS_ICON_PATH = {
    WARRIOR = "Interface\\Icons\\INV_Sword_27",
    PALADIN = "Interface\\Icons\\Ability_ThunderBolt",
    HUNTER = "Interface\\Icons\\inv_weapon_bow_07",
    ROGUE = "Interface\\Icons\\inv_throwingknife_04",
    PRIEST = "Interface\\Icons\\inv_staff_30",
    SHAMAN = "Interface\\Icons\\Spell_Nature_BloodLust",
    MAGE = "Interface\\Icons\\inv_staff_13",
    WARLOCK = "Interface\\Icons\\Spell_Nature_Drowsy",
    DRUID = "Interface\\Icons\\inv_misc_monsterclaw_04",
    DEATHKNIGHT = "Interface\\Icons\\Spell_Deathknight_ClassIcon",
}
-- CLASS_WARRIOR
ALPrivate.CLASS_ICON_PATH_ITEM_DB = {}
for k,v in pairs(ALPrivate.CLASS_ICON_PATH) do ALPrivate.CLASS_ICON_PATH_ITEM_DB[k] = "CLASS_"..k end

ALPrivate.PRICE_ICON_REPLACE = {
	["honor"] = UnitFactionGroup("player") == "Horde" and "Interface\\PVPFrame\\inv_bannerpvp_01" or
	"Interface\\PVPFrame\\inv_bannerpvp_02",
	["honorH"] = "Interface\\PVPFrame\\inv_bannerpvp_01",
	["honorA"] = "Interface\\PVPFrame\\inv_bannerpvp_02",
    ["arena"] = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon",
    ["arenaH"] = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon",
    ["arenaA"] = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon",
}


ALPrivate.CLASS_BITS = {
    --NONE 			= 0,
    WARRIOR 		= 1,
    PALADIN 		= 2,
    HUNTER 			= 4,
    ROGUE 			= 8,
    PRIEST 			= 16,
    DEATHKNIGHT 	= 32,
    SHAMAN 			= 64,
    MAGE 			= 128,
    WARLOCK 		= 256,
    DRUID 			= 1024,
    --DEMONHUNTER 	= 2048,
}
ALPrivate.CLASS_BIT_TO_CLASS = {}
for k,v in pairs(ALPrivate.CLASS_BITS) do ALPrivate.CLASS_BIT_TO_CLASS[v] = k end

if AtlasLoot:GameVersion_GE(AtlasLoot.WRATH_VERSION_NUM) then
    ALPrivate.CLASS_SORT = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
else
    ALPrivate.CLASS_SORT = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
end


ALPrivate.CLASS_NAME_TO_ID = {}
for classID = 1, #ALPrivate.CLASS_SORT do ALPrivate.CLASS_NAME_TO_ID[ALPrivate.CLASS_SORT[classID]] = classID end

ALPrivate.LOC_CLASSES = {}
FillLocalizedClassList(ALPrivate.LOC_CLASSES)

ALPrivate.INSTANCE_NAME_BY_MAPID = {
	[206] = "Utgarde Keep",
	[209] = "Shadowfang Keep",
	[491] = "Razorfen Kraul",
	[717] = "The Stockade",
	[718] = "Wailing Caverns",
	[719] = "Blackfathom Deeps",
	[721] = "Gnomeregan",
	[722] = "Razorfen Downs",
	[796] = "Scarlet Monastery",
	[1176] = "Zul'Farrak",
	[1196] = "Utgarde Pinnacle",
	[1337] = "Uldaman",
	[1477] = "The Temple of Atal'Hakkar",
	[1581] = "The Deadmines",
	[1583] = "Blackrock Spire",
	[1584] = "Blackrock Depths",
	[1977] = "Zul'Gurub",
	[2017] = "Stratholme",
	[2057] = "Scholomance",
	[2100] = "Maraudon",
	[2159] = "Onyxia's Lair",
	[2366] = "The Black Morass",
	[2367] = "Old Hillsbrad Foothills",
	[2437] = "Ragefire Chasm",
	[2557] = "Dire Maul",
	[2677] = "Blackwing Lair",
	[2717] = "Molten Core",
	[3428] = "Temple of Ahn'Qiraj",
	[3429] = "Ruins of Ahn'Qiraj",
	[3456] = "Naxxramas",
	[3457] = "Karazhan",
	[3562] = "Hellfire Ramparts",
	[3606] = "The Battle for Mount Hyjal",
	[3607] = "Serpentshrine Cavern",
	[3713] = "The Blood Furnace",
	[3714] = "The Shattered Halls",
	[3715] = "The Steamvault",
	[3716] = "The Underbog",
	[3717] = "The Slave Pens",
	[3789] = "Shadow Labyrinth",
	[3790] = "Auchenai Crypts",
	[3791] = "Sethekk Halls",
	[3792] = "Mana-Tombs",
	[3805] = "Zul'Aman",
	[3836] = "Magtheridon's Lair",
	[3845] = "Tempest Keep",
	[3847] = "The Botanica",
	[3848] = "The Arcatraz",
	[3849] = "The Mechanar",
	[3923] = "Gruul's Lair",
	[3959] = "Black Temple",
	[4075] = "Sunwell Plateau",
	[4100] = "The Culling of Stratholme",
	[4131] = "Magisters' Terrace",
	[4196] = "Drak'Tharon Keep",
	[4228] = "The Oculus",
	[4264] = "Halls of Stone",
	[4265] = "The Nexus",
	[4272] = "Halls of Lightning",
	[4273] = "Ulduar",
	[4277] = "Azjol-Nerub",
	[4415] = "The Violet Hold",
	[4416] = "Gundrak",
	[4493] = "The Obsidian Sanctum",
	[4494] = "Ahn'kahet: The Old Kingdom",
	[4500] = "The Eye of Eternity",
	[4603] = "Vault of Archavon",
	[4722] = "Trial of the Crusader",
	[4723] = "Trial of the Champion",
	[4809] = "The Forge of Souls",
	[4812] = "Icecrown Citadel",
	[4813] = "Pit of Saron",
	[4820] = "Halls of Reflection",
	[4987] = "The Ruby Sanctum",
}

ALPrivate.ADDON_MSG_PREFIX = "ATLASLOOT_MSG"
