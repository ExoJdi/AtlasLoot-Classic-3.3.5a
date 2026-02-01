-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)
local string = string
local type, tonumber, pairs = type, tonumber, pairs
local math = math
local str_split = string.split
-- WoW
local GetItemInfo, GetItemCount, GetItemIcon = _G.GetItemInfo, _G.GetItemCount, _G.GetItemIcon
-- ----------------------------------------------------------------------------
-- AddOn namespace.
-- ----------------------------------------------------------------------------
local ALName, ALPrivate = ...
local AtlasLoot = _G.AtlasLoot
local Price = AtlasLoot.Button:AddExtraType("Price")
local AL = AtlasLoot.Locales

local ok, ItemButtonType = pcall(AtlasLoot.Button.GetType, AtlasLoot.Button, "Item")
if not ok then ItemButtonType = nil end

local FIRST_RUN = true
local ITEMS_NOT_FOUND = true

local STRING_SPLIT_OR = "-"
local STRING_DELIMITER_OR = "|r; "
local STRING_DELIMITER_TT_OR = "|cff999999"..AL["--- or ---"]
local STRING_SPLIT_AND = ":"
local STRING_DELIMITER_AND = "|r & "
local STRING_DELIMITER_END = ""
local STRING_TABLE = "table"
local STRING_RED = "|cffff0000"
local STRING_GREEN = "|cff1eff00"

local PRICE_INFO = AtlasLoot.Data.VendorPrice.GetPriceInfoList()

local ICON_REPLACE = ALPrivate.PRICE_ICON_REPLACE
local PRICE_ICON_SIZE = ALPrivate.PRICE_ICON_SIZE or 14



local LEGACY_DIV10 = {
	JusticePoints = true,
	ValorPoints = true,
	EmblemOfHeroism = true,
	EmblemOfValor = true,
	EmblemOfConquest = true,
	EmblemOfTriumph = true,
	EmblemOfFrost = true,
}

local function NormalizeLegacyCurrency(typ, value)
	-- MoP/Cata points aliases removed; map to Wrath equivalents
	if typ == "JusticePoints" then typ = "EmblemOfHeroism" end
	if typ == "ValorPoints" then typ = "EmblemOfValor" end
	if LEGACY_DIV10[typ] then
		local num = tonumber(value) or 0
		if num > 200 then
			num = math.floor(num / 10)
		end
		if num < 1 and (tonumber(value) or 0) > 0 then num = 1 end
		return typ, num
	end
	return typ, value
end

local Cache = {}
setmetatable(Cache, {__mode = "kv"})

local GetCurrencyListSize = _G.GetCurrencyListSize
local GetCurrencyListInfo = _G.GetCurrencyListInfo
local GetCurrencyListLink = _G.GetCurrencyListLink
local ExpandCurrencyList = _G.ExpandCurrencyList

local function GetCurrencyInfoByItemID(itemID)
	if not itemID then return end
	local size = GetCurrencyListSize and GetCurrencyListSize() or 0
	if size <= 0 or not GetCurrencyListInfo or not GetCurrencyListLink then return end
	for i=1,size do
		local name, isHeader, isExpanded, _, count, icon = GetCurrencyListInfo(i)
		if isHeader then
			if not isExpanded then ExpandCurrencyList(i, true) end
		else
			local link = GetCurrencyListLink(i)
			if link then
				local id = tonumber(string.match(link, "item:(%d+):"))
				if id == itemID then
					return { name = name, quantity = count or 0, iconFileID = icon }
				end
			end
		end
	end
end

local function SetContentInfo(frame, typ, value, delimiter)
	typ, value = NormalizeLegacyCurrency(typ, value)
	value = value or 0
	delimiter = delimiter or STRING_DELIMITER_END

	if PRICE_INFO[typ] then
		if PRICE_INFO[typ].func then
			frame:AddText(PRICE_INFO[typ].func(value)..delimiter)
		elseif PRICE_INFO[typ].icon then
			frame:AddIcon(PRICE_INFO[typ].icon, PRICE_ICON_SIZE)
			frame:AddText(value..delimiter)
	elseif PRICE_INFO[typ].currencyID then
		local info = GetCurrencyInfoByItemID(PRICE_INFO[typ].currencyID)
		if info then
			frame:AddIcon(ICON_REPLACE[typ] or info.iconFileID, PRICE_ICON_SIZE)
			frame:AddText(info.quantity >= tonumber(value) and STRING_GREEN..value..delimiter or STRING_RED..value..delimiter)
		else
			frame:AddIcon(ICON_REPLACE[typ] or "Interface\\Icons\\INV_Misc_QuestionMark", PRICE_ICON_SIZE)
			frame:AddText(value..delimiter)
		end
	elseif PRICE_INFO[typ].itemID then
		local icon = GetItemIcon(PRICE_INFO[typ].itemID)
		PRICE_INFO[typ].icon = icon or "Interface\\Icons\\INV_Misc_QuestionMark"
			SetContentInfo(frame, typ, value, delimiter)
		end
	elseif tonumber(typ) then
		frame:AddIcon(GetItemIcon(typ), PRICE_ICON_SIZE)
		frame:AddText(value..delimiter)
	end
end

function Price.OnSet(mainButton, descFrame)
	if FIRST_RUN then
		for k,v in pairs(PRICE_INFO) do
			if v.itemID then
				local itemName = GetItemInfo(v.itemID)
				v.icon = GetItemIcon(v.itemID)
				v.name = itemName
			end
		end
		FIRST_RUN = false
	end
	local typeVal = mainButton.__atlaslootinfo.extraType[2]
	local info
	if Cache[typeVal] then
		info = Cache[typeVal]
	else
		info = { str_split(STRING_SPLIT_OR, typeVal) }
		if info[2] then
			for i = 1, #info do
				info[i] = { str_split(STRING_SPLIT_AND, info[i]) }
			end
		else
			info = { str_split(STRING_SPLIT_AND, info[1]) }
		end
		Cache[typeVal] = info
	end

	if type(info[1]) == STRING_TABLE then
		for i = 1, #info do
			for j = 1, #info[i], 2 do
				SetContentInfo(descFrame, info[i][j], info[i][j+1], j+1 == #info[i] and (#info == i and STRING_DELIMITER_END or STRING_DELIMITER_OR) or STRING_DELIMITER_AND)
			end
		end
	else
		for i = 1, #info, 2 do
			SetContentInfo(descFrame, info[i], info[i+1], i+1 == #info and STRING_DELIMITER_END or STRING_DELIMITER_AND)
		end
	end

	descFrame.info = info
end

-- ##########
-- OnEnter
-- ##########

local TT_ICON_AND_NAME = "|T%s:14|t %s"
local TT_HAVE_AND_NEED_GREEN = STRING_GREEN.."%d / %d"
local TT_HAVE_AND_NEED_RED = STRING_RED.."%d / %d"

local function SetTooltip(tooltip, typ, value)
	typ, value = NormalizeLegacyCurrency(typ, value)
	value = tonumber(value) or 0

	if PRICE_INFO[typ] then
		if PRICE_INFO[typ].func then
			tooltip:AddLine(PRICE_INFO[typ].func(value))
		--elseif PRICE_INFO[typ].icon then
		--	tooltip:AddLine(TT_ICON_AND_NAME:format(PRICE_INFO[typ].icon, PRICE_INFO[typ].name or ""))
		--	tooltip:AddLine(TT_HAVE_AND_NEED_GREEN:format(value))
	elseif PRICE_INFO[typ].currencyID then
		local info = GetCurrencyInfoByItemID(PRICE_INFO[typ].currencyID)
		if info then
			if info.iconFileID then
				tooltip:AddLine(TT_ICON_AND_NAME:format(ICON_REPLACE[typ] or info.iconFileID, info.name or ""))
			end
			tooltip:AddLine(info.quantity >= value and TT_HAVE_AND_NEED_GREEN:format(info.quantity, value) or  TT_HAVE_AND_NEED_RED:format(info.quantity, value))
		else
			local icon = ICON_REPLACE[typ] or "Interface\\Icons\\INV_Misc_QuestionMark"
			tooltip:AddLine(TT_ICON_AND_NAME:format(icon, PRICE_INFO[typ].name or ""))
			tooltip:AddLine(TT_HAVE_AND_NEED_GREEN:format(value, value))
		end
		elseif PRICE_INFO[typ].itemID then
			local itemName = GetItemInfo(PRICE_INFO[typ].itemID)
			tooltip:AddLine(TT_ICON_AND_NAME:format(GetItemIcon(PRICE_INFO[typ].itemID), GetItemInfo(PRICE_INFO[typ].itemID) or ""))
			local count = GetItemCount(PRICE_INFO[typ].itemID, true)
			tooltip:AddLine(count >= value and TT_HAVE_AND_NEED_GREEN:format(count, value) or  TT_HAVE_AND_NEED_RED:format(count, value))
		end
	elseif tonumber(typ) then
		local itemName = GetItemInfo(typ)
		tooltip:AddLine(TT_ICON_AND_NAME:format(GetItemIcon(typ), GetItemInfo(typ) or ""))
		local count = GetItemCount(typ, true)
		tooltip:AddLine(count >= value and TT_HAVE_AND_NEED_GREEN:format(count, value) or  TT_HAVE_AND_NEED_RED:format(count, value))
	end
end

function Price.OnEnter(descFrame, tooltip)
	if not descFrame.info then return end
	local info = descFrame.info
	if type(info[1]) == STRING_TABLE then
		for i = 1, #info do
			if i > 1 then
				tooltip:AddLine(STRING_DELIMITER_TT_OR)
			end
			for j = 1, #info[i], 2 do
				SetTooltip(tooltip, info[i][j], info[i][j+1])
			end
		end
	else
		for i = 1, #info, 2 do
			SetTooltip(tooltip, info[i], info[i+1])
		end
	end
end
