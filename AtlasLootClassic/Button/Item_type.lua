local _G = _G
local ALName, ALPrivate = ...
local AtlasLoot = _G.AtlasLoot
local Item = AtlasLoot.Button:AddType("Item", "i")
local Query = {}
Item.Query = Query
local AL, ALIL = AtlasLoot.Locales, AtlasLoot.IngameLocales
local ClickHandler = AtlasLoot.ClickHandler
local Token = AtlasLoot.Data.Token
local Recipe = AtlasLoot.Data.Recipe
local Profession = AtlasLoot.Data.Profession
local Sets = AtlasLoot.Data.Sets
local ItemSet = AtlasLoot.Data.ItemSet
local Companion = AtlasLoot.Data.Companion
local ContentPhase = AtlasLoot.Data.ContentPhase
local Droprate = AtlasLoot.Data.Droprate
local Requirements = AtlasLoot.Data.Requirements
local VendorPrice = AtlasLoot.Data.VendorPrice
local ItemFrame, Favourites

-- lua
local tonumber = _G.tonumber
local assert = _G.assert
local next, wipe, tab_remove = _G.next, _G.wipe, _G.table.remove
local format, split, sfind, slower = _G.string.format, _G.string.split, _G.string.find, _G.string.lower
local str_match = string.match

-- WoW
local DEFAULT_BUTTON_SCALE = 1.0

local GetItemInfo, IsEquippableItem = _G.GetItemInfo, _G.IsEquippableItem
local GetItemQualityColor = _G.GetItemQualityColor
local LOOT_BORDER_BY_QUALITY = _G["LOOT_BORDER_BY_QUALITY"]
local MODELFRAME_DEFAULT_ROTATION = _G.MODELFRAME_DEFAULT_ROTATION or 0.61

--[[
	-- Items with suffixes format "i<itemID>suf<suffixID" e.g. "i68132suf-131"
	SuffixID will often be negative
]]

-- AL
local GetAlTooltip = AtlasLoot.Tooltip.GetTooltip
local GetItemDescInfo = AtlasLoot.ItemInfo.GetDescription
local GetItemString = AtlasLoot.ItemString.Create

local ITEM_COLORS = {}
local DUMMY_ITEM_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SET_ITEM = "|cff00ff00"..AL["Set item"]..":|r "
local WHITE_TEXT = "|cffffffff%s|r"
local ITEM_DESC_EXTRA_SEP = "%s | %s"


local function FixBrokenColor(s)
	if type(s) ~= "string" then return s end
	if s == "" then return s end
	local out, i, len = {}, 1, #s
	while i <= len do
		local c1, c2 = s:sub(i, i), s:sub(i + 1, i + 1)
		if c1 == "|" and c2 == "c" then
			local code = s:sub(i + 2, i + 9)
			if #code == 8 and code:match("^%x%x%x%x%x%x%x%x$") then
				out[#out + 1] = "|c" .. code
				i = i + 10
			else
				i = i + 2
			end
		elseif c1 == "|" and c2 == "r" then
			out[#out + 1] = "|r"
			i = i + 2
		else
			out[#out + 1] = c1
			i = i + 1
		end
	end
	s = table.concat(out)
	s = s:gsub("|c|c", "|c")
	s = s:gsub("|c$", "")
	return s
end

local itemIsOnEnter, buttonOnEnter = nil, nil

local ItemClickHandler = nil
ClickHandler:Add(
	"Item",
	{
		ChatLink = { "LeftButton", "Shift" },
		DressUp = { "LeftButton", "Ctrl" },
		SetFavourite = { "LeftButton", "Alt" },
		ShowExtraItems = { "LeftButton", "None" },
		WoWHeadLink = { "RightButton", "Shift" },
		types = {
			ChatLink = true,
			DressUp = true,
			ShowExtraItems = true,
			SetFavourite = true,
			WoWHeadLink = true,
		},
	},
	{
		{ "ChatLink", 		AL["Chat Link"], 			AL["Add item into chat"] },
		{ "DressUp", 		AL["Dress up"], 			AL["Shows the item in the Dressing room"] },
		{ "SetFavourite", 	AL["Set Favourite"], 		AL["Set/Remove the item as favourite"] },
		{ "ShowExtraItems", AL["Show extra items"], 	AL["Shows extra items (tokens,mats)"] },
		{ "WoWHeadLink", 	AL["Show WowHead link"], 	AL["Shows a copyable link for WoWHead"] },
	}
)

local function OnFavouritesAddonLoad(addon, enabled)
	Favourites = enabled and addon or nil
end

local function OnInit()
	if not ItemClickHandler then
		ItemClickHandler = ClickHandler:GetHandler("Item")
		AtlasLoot.Addons:GetAddon("Favourites", OnFavouritesAddonLoad)
		-- create item colors
		for i=0,7 do
			local _, _, _, itemQuality = GetItemQualityColor(i)
			if type(itemQuality) ~= "string" then
				itemQuality = "ffffffff"
			elseif #itemQuality == 6 then
				itemQuality = "ff"..itemQuality
			end
			ITEM_COLORS[i] = "|c"..itemQuality
		end
		ItemFrame = AtlasLoot.GUI.ItemFrame
	end
	Item.ItemClickHandler = ItemClickHandler
end
AtlasLoot:AddInitFunc(OnInit)

function Item.OnSet(button, second)
	if not button then return end
	if second and button.__atlaslootinfo.secType then
		if type(button.__atlaslootinfo.secType[2]) == "table" then
			button.secButton.ItemID = button.__atlaslootinfo.secType[2][1] or tonumber(tab_remove(button.__atlaslootinfo.secType[2], 1))
			button.secButton.SuffixID = button.__atlaslootinfo.secType[2].SuffixID or button.__atlaslootinfo.secType[2][2] or 0
			button.secButton.ItemString = button.__atlaslootinfo.secType[2].itemString or GetItemString(button.secButton.ItemID, false, button.secButton.SuffixID)
		else
			button.secButton.ItemID = button.__atlaslootinfo.secType[2]
			if button.__atlaslootinfo.preSet and button.__atlaslootinfo.preSet.Item and ( button.__atlaslootinfo.preSet.Item.item2bonus or button.__atlaslootinfo.ItemDifficulty ) then
				button.secButton.ItemString = GetItemString(button.ItemID)
			end
		end
		button.secButton.Droprate = button.__atlaslootinfo.Droprate
		button.secButton.SetID = ItemSet.GetSetIDforItemID(button.secButton.ItemID)

		Item.Refresh(button.secButton)
	else
		if type(button.__atlaslootinfo.type[2]) == "table" then
			button.ItemID = button.__atlaslootinfo.type[2].itemID or tonumber(tab_remove(button.__atlaslootinfo.type[2], 1))
			button.SuffixID = button.__atlaslootinfo.type[2].SuffixID or button.__atlaslootinfo.type[2][2] or 0
			button.ItemString = button.__atlaslootinfo.type[2].itemString or GetItemString(button.ItemID, false, button.SuffixID)
		else
			button.ItemID = button.__atlaslootinfo.type[2]
			if button.__atlaslootinfo.preSet and button.__atlaslootinfo.preSet.Item and ( button.__atlaslootinfo.preSet.Item.item1bonus or button.__atlaslootinfo.ItemDifficulty ) then
				button.ItemString = GetItemString(button.ItemID)
			end
		end
		button.Droprate = Droprate:GetData(button.__atlaslootinfo.npcID, button.ItemID)-- button.__atlaslootinfo.Droprate

		Item.Refresh(button)

		-- Set Vendor price is aviable
		if VendorPrice.ItemHasVendorPrice(button.ItemID) then
			button:SetExtraType("Price", VendorPrice.GetVendorPriceForItem(button.ItemID))
		end
	end
end

function Item.OnMouseAction(button, mouseButton)
	if not mouseButton then return end

	mouseButton = ItemClickHandler:Get(mouseButton) or mouseButton
	if mouseButton == "ChatLink" then
		local itemInfo, itemLink = GetItemInfo(button.ItemString or button.ItemID)
		itemLink = itemLink or button.ItemString
		if ChatEdit_InsertLink then
			ChatEdit_InsertLink(itemLink or ("item:"..button.ItemID))
		end
	elseif mouseButton == "WoWHeadLink" then
		AtlasLoot.Button:OpenWoWHeadLink(button, "item", button.ItemID)
	elseif mouseButton == "DressUp" then
		local itemInfo, itemLink = GetItemInfo(button.ItemString or button.ItemID)
		itemLink = itemLink or button.ItemString
		if itemLink then
			DressUpItemLink(itemLink)
		end
	elseif mouseButton == "ShowExtraItems" then
		if Token.IsToken(button.ItemID) then
			button.ExtraFrameShown = true
			AtlasLoot.Button:ExtraItemFrame_GetFrame(button, Token.GetTokenData(button.ItemID))
		elseif Recipe.IsRecipe(button.ItemID) then
			button.ExtraFrameShown = true
			AtlasLoot.Button:ExtraItemFrame_GetFrame(button, Recipe.GetRecipeDataForExtraFrame(button.ItemID))
		elseif button.type ~= "secButton" and ( button.SetData or ItemSet.GetSetIDforItemID(button.ItemID) ) then -- sec buttons should not be clickable for sets
			if not button.SetData then
				button.SetData = ItemSet.GetSetDataForExtraFrame(ItemSet.GetSetIDforItemID(button.ItemID))
			end
			button.ExtraFrameShown = true
			AtlasLoot.Button:ExtraItemFrame_GetFrame(button, button.SetData)
		end
	elseif mouseButton == "SetFavourite" then
		if Favourites then
			if Favourites:IsFavouriteItemID(button.ItemID, true) then
				Favourites:RemoveItemID(button.ItemID)
				if Favourites:IsFavouriteItemID(button.ItemID) then
					Favourites:SetFavouriteIcon(button.ItemID, button.favourite)
				else
					if button.favourite then
						button.favourite:Hide()
					end
				end
			else
				if Favourites:AddItemID(button.ItemID) then
					Favourites:SetFavouriteIcon(button.ItemID, button.favourite)
					if button.favourite then
						button.favourite:Show()
					end
				end
			end
			if Favourites:TooltipHookEnabled() then
				Item.OnLeave(button)
				Item.OnEnter(button)
			end
			AtlasLoot.Button:ExtraItemFrame_Refresh(button)
		end
	elseif mouseButton == "MouseWheelUp" and Item.previewTooltipFrame and Item.previewTooltipFrame:IsShown() then  -- ^
		local frame = Item.previewTooltipFrame.modelFrame
		if IsAltKeyDown() then -- model zoom
			frame.zoomLevelNew = frame.zoomLevelNew + 0.1 >= frame.maxZoom and frame.maxZoom or frame.zoomLevelNew + 0.1
			if frame.SetPortraitZoom then frame:SetPortraitZoom(frame.zoomLevelNew) end
		else -- model rotation
			frame.curRotation = frame.curRotation + 0.1
			frame:SetRotation(frame.curRotation)
		end
	elseif mouseButton == "MouseWheelDown" and Item.previewTooltipFrame and Item.previewTooltipFrame:IsShown() then	-- v
		local frame = Item.previewTooltipFrame.modelFrame
		if IsAltKeyDown() then -- model zoom
			frame.zoomLevelNew = frame.zoomLevelNew - 0.1 <= frame.minZoom and frame.minZoom or frame.zoomLevelNew - 0.1
			if frame.SetPortraitZoom then frame:SetPortraitZoom(frame.zoomLevelNew) end
		else -- model rotation
			frame.curRotation = frame.curRotation - 0.1
			frame:SetRotation(frame.curRotation)
		end
	end

end

function Item.OnEnter(button, owner)
	if not button.ItemID then return end
	local tooltip = GetAlTooltip()
	local db = ItemClickHandler:GetDB()
	tooltip:ClearLines()
	itemIsOnEnter = tooltip
	buttonOnEnter = button
	if owner and type(owner) == "table" then
		tooltip:SetOwner(owner[1], owner[2], owner[3], owner[4])
	else
		tooltip:SetOwner(button, "ANCHOR_RIGHT", -(button:GetWidth() * 0.5), 5)
	end
	if button.ItemString then
		tooltip:SetHyperlink(button.ItemString)
	else
		tooltip:SetHyperlink("item:"..button.ItemID)
		-- small fix for auctionatorTT as it not hooks SetItemByID
		if _G.Atr_ShowTipWithPricing then
			local itemName, itemLink = GetItemInfo(button.ItemID)
			_G.Atr_ShowTipWithPricing(tooltip, itemLink)
		end
	end
	if button.Droprate and AtlasLoot.db.showDropRate then
		tooltip:AddDoubleLine(AL["Droprate:"], format(WHITE_TEXT, button.Droprate.."%"))
	end
	if not AtlasLoot.db.showTooltipInfoGlobal then
		if AtlasLoot.db.showCompanionLearnedInfo and AtlasLoot.Data.Companion.IsCompanion(button.ItemID) then
			tooltip:AddDoubleLine(AtlasLoot.Data.Companion.GetTypeName(button.ItemID), AtlasLoot.Data.Companion.GetCollectedString(button.ItemID))
		end
		if AtlasLoot.db.showIDsInTT then
			tooltip:AddDoubleLine(AL["ItemID:"], format(WHITE_TEXT, button.ItemID or 0))
		end
		if AtlasLoot.db.showItemLvlInTT and button.ItemLvl then
			tooltip:AddDoubleLine(AL["Item level:"], format(WHITE_TEXT, button.ItemLvl or 0))
		end
	end
	if AtlasLoot.db.ContentPhases.enableTT and ContentPhase:GetForItemID(button.ItemID) then
		tooltip:AddDoubleLine(AL["Content phase:"], format(WHITE_TEXT, ContentPhase:GetForItemID(button.ItemID)))
	end
	if button.ItemID == 12784 then tooltip:AddLine("Arcanite Reaper Hoooooo!") end
	tooltip:Show()
	if IsShiftKeyDown() or db.alwaysShowCompareTT then
		GameTooltip_ShowCompareItem(tooltip)
	end
	if Companion.IsCompanion(button.ItemID) then
		Item.ShowQuickDressUp(button.ItemID, tooltip)
	elseif IsControlKeyDown() or db.alwaysShowPreviewTT then
		Item.ShowQuickDressUp(button.ItemID, tooltip)
	end
end

function Item.OnLeave(button)
	GetAlTooltip():Hide()
	itemIsOnEnter = nil
	buttonOnEnter = nil
	ShoppingTooltip1:Hide()
	ShoppingTooltip2:Hide()
	if Item.previewTooltipFrame and Item.previewTooltipFrame:IsShown() then Item.previewTooltipFrame:Hide() end
	--ShoppingTooltip3:Hide()
end

function Item.OnClear(button)
	Query:Remove(button)
	Query:Remove(button.secButton)
	button.ItemID = nil
	button.Droprate = nil
	button.ItemString = nil
	button.SetData = nil
	button.RawName = nil
	button.ItemLvl = nil
	button.SuffixID = nil
	button.secButton.ItemID = nil
	button.secButton.Droprate = nil
	button.secButton.ItemString = nil
	button.secButton.SetData = nil
	button.secButton.RawName = nil
	button.secButton.ItemLvl = nil
	button.secButton.SuffixID = nil
	button.secButton.pvp:Hide()

	itemIsOnEnter = nil
	buttonOnEnter = nil

	button.secButton.overlay:Hide()
	if button.ExtraFrameShown then
		AtlasLoot.Button:ExtraItemFrame_ClearFrame()
		button.ExtraFrameShown = false
	end
end

function Item.GetDescription(itemID, itemEquipLoc, itemType, itemSubType)
	if not itemEquipLoc then
		local _, _, _, _, _, it, st, _, el = GetItemInfo(itemID)
		itemType, itemSubType, itemEquipLoc = it, st, el
	end
	local ret
	if Token.IsToken(itemID) then
		local tokenDesc = Token.GetTokenDescription(itemID)
		if Token.TokenTypeAddDescription(itemID) then
			local base = GetItemDescInfo(itemEquipLoc, itemType, itemSubType)
			if type(base) ~= 'string' then base = '' end
			local extra = tokenDesc
			if type(extra) ~= 'string' then extra = '' end
			if extra ~= '' and base ~= '' then
				ret = base..' | '..extra
			else
				ret = (base ~= '' and base or extra)
			end
		else
			ret = tokenDesc
		end
	elseif Companion.IsCompanion(itemID) then
		ret = Companion.GetDescription(itemID, AtlasLoot:GameVersion_GE(AtlasLoot.WRATH_VERSION_NUM, true, false))
	elseif ItemSet.GetSetIDforItemID(itemID) then
		ret = AL["|cff00ff00Set item:|r "]..(GetItemDescInfo(itemEquipLoc, itemType, itemSubType) or "")
	else
		ret = Recipe.GetRecipeDescriptionWithRank(itemID) or
		Profession.GetColorSkillRankItem(itemID) or
		GetItemDescInfo(itemEquipLoc, itemType, itemSubType)
	end
	if ret and Requirements.HasRequirements(itemID) then
		ret = Requirements.GetReqString(itemID)..ret
	end
	return ret
end

function Item.Refresh(button)
	if button.secButton then
		button.secButton:SetScale(DEFAULT_BUTTON_SCALE)
	end
	if not button.ItemID then return end
	local itemID = button.ItemID
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, itemTexture = GetItemInfo(button.ItemString or itemID)
	if not itemName then
		Query:Add(button)
		return false
	end
	button.RawName = itemName

	if itemLevel and itemLevel > 0 then
		button.ItemLvl = itemLevel
	end

	button.overlay:Show()
	button.overlay:SetQualityBorder(itemQuality)

	-- check if its a heirloom
	if itemQuality == 7 then
		button.ItemString = GetItemString(button.ItemID, true)
	end

	local tex = itemTexture
	if not tex and type(GetItemIcon) == "function" then
		tex = GetItemIcon(itemID)
	end
	if type(tex) ~= "string" then
		tex = DUMMY_ITEM_ICON
	end

	if button.type == "secButton" then
		-- secButton has its own icon texture. Using SetNormalTexture here can leave the
		-- default quickslot/background texture visible (blue square) on some entries.
		if button.icon then
			button.icon:SetTexture(tex)
		end
		button:SetNormalTexture(nil)

		if Requirements.HasPvPRequirements(itemID) then
			button.pvp:SetTexture(Requirements.GetPvPRankIconForItem(itemID))
			button.pvp:Show()
		end
	else
		-- ##################
		-- icon
		-- ##################
		button.icon:SetTexture(tex)

		-- ##################
		-- name
		-- ##################
		local c = ITEM_COLORS[itemQuality or 0] or "|cffffffff"
		c = string.gsub(c, "^|c|c", "|c")
		button.name:SetText(FixBrokenColor(c..itemName))

		-- ##################
		-- description
		-- ##################
			button.extra:SetText(Item.GetDescription(itemID, itemEquipLoc, itemType, itemSubType))
		end
		if Favourites and Favourites:IsFavouriteItemID(itemID) then
			Favourites:SetFavouriteIcon(itemID, button.favourite)
			button.favourite:Show()
		else
			button.favourite:Hide()
		end
		--elseif Recipe.IsRecipe(itemID) then
		if AtlasLoot.db.ContentPhases.enableOnItems then
			local phaseT, active = ContentPhase:GetPhaseTextureForItemID(itemID)
			if phaseT and not active then
				button.phaseIndicator:SetTexture(phaseT)
				button.phaseIndicator:Show()
			end
		end
		AtlasLootScanTooltip:SetHyperlink("item:" .. itemID)
		return true
	end

	function Item.GetStringContent(str)
		if tonumber(str_match(str, "suf(%-?%d+)")) then
			return {
				tonumber(str_match(str, "(%d+)")),
				tonumber(str_match(str, "suf(%-?%d+)")),
			}
		elseif tonumber(str) then
			return tonumber(str)
		else
			return {
				split(":", str)
			}
		end
	end
--################################
-- Item dess up
--################################
local function ModelReset(self)
	if self.SetCreature then
		self:SetCreature(0)
	end
	if self.ClearModel then
		self:ClearModel()
	end
	if self.Undress then
		self:Undress()
	end
	if _G.Model_Reset then
		_G.Model_Reset(self)
	end
end

function Item.ShowQuickDressUp(itemLink, ttFrame)
	if not itemLink or not ttFrame or ( not IsEquippableItem(itemLink) and not Companion.IsCompanion(itemLink) ) then return end
	if not Item.previewTooltipFrame then
		local name = "AtlasLoot-SetToolTip"
		local frame = CreateFrame("Frame", name, nil, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
		frame:SetClampedToScreen(true)
		frame:SetSize(230, 280)
		frame:SetBackdrop(ALPrivate.BOX_BORDER_BACKDROP)
		frame:SetBackdropColor(0,0,0,1)

		frame.modelFrame = CreateFrame("DressUpModel", name.."-ModelFrame", frame)
		frame.modelFrame:ClearAllPoints()
		frame.modelFrame:SetParent(frame)
		frame.modelFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)
		frame.modelFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
		frame.modelFrame.defaultRotation = MODELFRAME_DEFAULT_ROTATION
		frame.modelFrame:SetRotation(MODELFRAME_DEFAULT_ROTATION)
		--frame.modelFrame:SetBackdrop(ALPrivate.BOX_BORDER_BACKDROP)
		--frame.modelFrame:SetBackdropColor(0,0,0,1)
		frame.modelFrame:SetUnit("player")
		frame.modelFrame.minZoom = 0
		frame.modelFrame.maxZoom = 1.0
		frame.modelFrame.curRotation = MODELFRAME_DEFAULT_ROTATION
		frame.modelFrame.zoomLevel = frame.modelFrame.minZoom
		frame.modelFrame.zoomLevelNew = frame.modelFrame.zoomLevel
		if frame.modelFrame.SetPortraitZoom then
			frame.modelFrame:SetPortraitZoom(frame.modelFrame.zoomLevel)
		end
		frame.modelFrame.Reset = ModelReset

		Item.previewTooltipFrame = frame
		frame:Hide()
	end

	local frame = Item.previewTooltipFrame

	-- calculate point for frame
	if not ttFrame.GetOwner or not ttFrame:GetOwner() then return end
	local x,y = ttFrame:GetOwner():GetCenter()
	local fPoint, oPoint = "BOTTOMLEFT", "TOPRIGHT"

	if y/GetScreenHeight() > 0.3 then
		fPoint, oPoint = "TOP", "BOTTOM"
	else
		fPoint, oPoint = "BOTTOM", "TOP"
	end
	if x/GetScreenWidth() > 0.5 then
		fPoint, oPoint = fPoint.."LEFT", oPoint.."LEFT"
	else
		fPoint, oPoint = fPoint.."RIGHT", oPoint.."RIGHT"
	end

	frame:Show()

	frame:ClearAllPoints()
	frame:SetParent(ttFrame:GetOwner():GetParent())
	frame:SetFrameStrata("TOOLTIP")
	frame:SetPoint(fPoint, ttFrame, oPoint)

	frame = Item.previewTooltipFrame.modelFrame
	frame:Reset()
	local creatureID = Companion.GetCreatureID(itemLink)
	if creatureID then
		frame:SetCreature(creatureID)
		frame:SetCamDistanceScale(AtlasLoot:GameVersion_GE(AtlasLoot.WRATH_VERSION_NUM, 1, 2))
		if frame.SetPortraitZoom then frame:SetPortraitZoom(frame.zoomLevel) end
	else
		frame:SetCamDistanceScale(1)
		frame:SetUnit("player")
		local info = {GetItemInfo(itemLink)}
		if info[9] ~= "INVTYPE_CLOAK" then
			frame:SetRotation(frame.curRotation)
		else
			frame:SetRotation(frame.curRotation + math.pi)
		end
		if frame.SetPortraitZoom then frame:SetPortraitZoom(frame.zoomLevelNew) end
		frame:TryOn(info[2])
	end
end

--################################
-- Item querys
--################################
local button_list = {}

Query.EventFrame = CreateFrame("FRAME")

local function EventFrame_OnEvent(frame, event, arg1, arg2)
	if event == "GET_ITEM_INFO_RECEIVED" then
		if arg1 and button_list[arg1] then
			for i = 1, #button_list[arg1] do
				local button = button_list[arg1][i]
				if button.type == "secButton" then
					button.obj:GetSecTypeFunctions().Refresh(button)
				else
					local typFunc = button:GetTypeFunctions()
					if typFunc then
						typFunc.Refresh(button)
					end
					if ItemFrame then
						ItemFrame.UpdateFilterItem(button)
					end
				end
			end
			button_list[arg1] = nil
		end

		if not next(button_list) then
			frame:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
		end
	elseif event == "MODIFIER_STATE_CHANGED" then
		if itemIsOnEnter then
			-- arg2: 1 for pressed, 0 (not nil!) for released
			if arg2 == 1 then
				if arg1 == "LSHIFT" or arg1 == "RSHIFT" then
					GameTooltip_ShowCompareItem(itemIsOnEnter)
				elseif arg1 == "LCTRL" or arg1 == "RCTRL" then
					if Companion.IsCompanion(buttonOnEnter.ItemID) then
						--Item.ShowQuickDressUp(buttonOnEnter.ItemID, itemIsOnEnter)
					else
						--local _, link = itemIsOnEnter:GetItem()
						Item.ShowQuickDressUp(buttonOnEnter.ItemID, itemIsOnEnter)
					end
				end
			else
				if arg1 == "LSHIFT" or arg1 == "RSHIFT" then
					ShoppingTooltip1:Hide()
					ShoppingTooltip2:Hide()
					--ShoppingTooltip3:Hide()
				elseif arg1 == "LCTRL" or arg1 == "RCTRL" then
					if Item.previewTooltipFrame and not Companion.IsCompanion(buttonOnEnter.ItemID) and Item.previewTooltipFrame:IsShown() then Item.previewTooltipFrame:Hide() end
				end
			end
		end
	end
end
Query.EventFrame:SetScript("OnEvent", EventFrame_OnEvent)
Query.EventFrame:RegisterEvent("MODIFIER_STATE_CHANGED")

do
    local pollElapsed = 0
    local pollInterval = 0.2
    local tooltip

    local function EnsureTooltip()
        if tooltip then return tooltip end
        tooltip = CreateFrame("GameTooltip", "AtlasLootClassicQueryTooltip", UIParent, "GameTooltipTemplate")
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        return tooltip
    end

    local function PollPending(self, elapsed)
        pollElapsed = pollElapsed + (elapsed or 0)
        if pollElapsed < pollInterval then return end
        pollElapsed = 0

        local t = EnsureTooltip()
        local checked = 0
        for itemID, buttons in pairs(button_list) do
            if type(itemID) == "number" then
                local name = GetItemInfo(itemID)
                if not name then
                    t:ClearLines()
                    t:SetHyperlink("item:"..itemID)
                else
                    for i = 1, #buttons do
                        local button = buttons[i]
                        if button and button:IsShown() then
                            if button.type == "secButton" then
                                button.obj:GetSecTypeFunctions().Refresh(button)
                            else
                                local typFunc = button:GetTypeFunctions()
                                if typFunc then
                                    typFunc.Refresh(button)
                                end
                                if ItemFrame then
                                    ItemFrame.UpdateFilterItem(button)
                                end
                            end
                        end
                    end
                    button_list[itemID] = nil
                end
                checked = checked + 1
                if checked >= 6 then
                    break
                end
            end
        end

        if not next(button_list) then
            self:SetScript("OnUpdate", nil)
        end
    end

    Query._PollPending = PollPending
end

function Query:Add(button)
	assert(button, "Button not found.")
    Query.EventFrame:SetScript("OnUpdate", Query._PollPending)
	if not button_list[button.ItemID] then
		button_list[button.ItemID] = { button }
	else
		button_list[button.ItemID][#button_list[button.ItemID]+1] = button
	end
end

function Query:Remove(button)
	if not button then return end
	local id = button.ItemID or button
	if id and button_list[id] then
		button_list[id] = nil
		if not next(button_list) then
            Query.EventFrame:SetScript("OnUpdate", nil)
		end
	end
end

function Query:Wipe()
	wipe(button_list)
    Query.EventFrame:SetScript("OnUpdate", nil)
end
