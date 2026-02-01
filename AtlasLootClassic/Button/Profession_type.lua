
-- Spell icon overrides for 3.3.5a
local PROF_SPELL_ICON_OVERRIDES = {
    [44636] = "Interface\\Icons\\Trade_Engraving",
    [44645] = "Interface\\Icons\\Trade_Engraving",
    [27920] = "Interface\\Icons\\Trade_Engraving",
    [27924] = "Interface\\Icons\\Trade_Engraving",
    [27926] = "Interface\\Icons\\Trade_Engraving",
    [27927] = "Interface\\Icons\\Trade_Engraving",
    [54736] = "Interface\\Icons\\Trade_Engineering",
    [54793] = "Interface\\Icons\\Trade_Engineering",
    [54998] = "Interface\\Icons\\Trade_Engineering",
    [54999] = "Interface\\Icons\\Trade_Engineering",
    [55002] = "Interface\\Icons\\Trade_Engineering",
    [55016] = "Interface\\Icons\\Trade_Engineering",
    [55628] = "Interface\\Icons\\Trade_BlackSmithing",
    [55641] = "Interface\\Icons\\Trade_BlackSmithing",
    [55642] = "Interface\\Icons\\Trade_Tailoring",
    [55769] = "Interface\\Icons\\Trade_Tailoring",
    [55777] = "Interface\\Icons\\Trade_Tailoring",
    [57683] = "Interface\\Icons\\Trade_Leatherworking",
    [57690] = "Interface\\Icons\\Trade_Leatherworking",
    [57691] = "Interface\\Icons\\Trade_Leatherworking",
    [57692] = "Interface\\Icons\\Trade_Leatherworking",
    [57694] = "Interface\\Icons\\Trade_Leatherworking",
    [57696] = "Interface\\Icons\\Trade_Leatherworking",
    [57699] = "Interface\\Icons\\Trade_Leatherworking",
    [57701] = "Interface\\Icons\\Trade_Leatherworking",
    [59636] = "Interface\\Icons\\Trade_Engraving",
    [56001] = "Interface\\Icons\\Trade_Tailoring",
    [56002] = "Interface\\Icons\\Trade_Tailoring",
    [56003] = "Interface\\Icons\\Trade_Tailoring",
    [56034] = "Interface\\Icons\\Trade_Tailoring",
    [56039] = "Interface\\Icons\\Trade_Tailoring",
    [60583] = "Interface\\Icons\\Trade_Leatherworking",
    [60584] = "Interface\\Icons\\Trade_Leatherworking",
    [60581] = "Interface\\Icons\\Trade_Leatherworking",
    [60582] = "Interface\\Icons\\Trade_Leatherworking",
    [61117] = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    [61118] = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    [61119] = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    [61120] = "Interface\\Icons\\INV_Inscription_Tradeskill01",
	[63765] = "Interface\\Icons\\Trade_Engineering",
    [63770] = "Interface\\Icons\\Trade_Engineering",
    [67839] = "Interface\\Icons\\Trade_Engineering"
}

local AtlasLoot = _G.AtlasLoot
local Prof = AtlasLoot.Button:AddType("Profession", "prof")
local ok, Item_ButtonType = pcall(AtlasLoot.Button.GetType, AtlasLoot.Button, "Item")
if not ok then return end
local ItemQuery = Item_ButtonType.Query
local AL = AtlasLoot.Locales
local GetAlTooltip = AtlasLoot.Tooltip.GetTooltip
local Profession = AtlasLoot.Data.Profession

--lua
local str_match = string.match
local GetSpellInfo, GetItemInfo = _G.GetSpellInfo, _G.GetItemInfo
local function GetSpellTexture(spellID)
    local _, _, icon = GetSpellInfo(spellID)
    if not icon or icon == "Interface\\Icons\\INV_Misc_QuestionMark" then
        icon = PROF_SPELL_ICON_OVERRIDES[spellID]
    end
    return icon
end
local GetItemQualityColor = _G.GetItemQualityColor
local GetTradeskillLink = AtlasLoot.TooltipScan.GetTradeskillLink

local ProfClickHandler = nil

local PROF_COLOR = "|cffffff00"
local WHITE_TEXT = "|cffffffff%s|r"
local ITEM_COLORS = {}

AtlasLoot.ClickHandler:Add(
	"Profession",
	{
		ChatLink = { "LeftButton", "Shift" },
		ShowExtraItems = { "LeftButton", "None" },
		DressUp = { "LeftButton", "Ctrl" },
		WoWHeadLink = { "RightButton", "Shift" },
		types = {
			ChatLink = true,
			ShowExtraItems = true,
			DressUp = true,
			WoWHeadLink = true,
		},
	},
	{
		{ "ChatLink", 		AL["Chat Link"], 			AL["Add profession link into chat"] },
		{ "DressUp", 		AL["Dress up"], 			AL["Shows the item in the Dressing room"] },
		{ "ShowExtraItems", AL["Show extra items"], 	AL["Shows extra items (tokens,mats)"] },
		{ "WoWHeadLink", 	AL["Show WowHead link"], 	AL["Shows a copyable link for WoWHead"] },
	}
)

function Prof.OnSet(button, second)
	if not ProfClickHandler then
		ProfClickHandler = AtlasLoot.ClickHandler:GetHandler("Profession")

		-- create item colors
		for i=0,7 do
			local _, _, _, itemQuality = GetItemQualityColor(i)
			ITEM_COLORS[i] = itemQuality
		end
	end
	if not button then return end
	if second and button.__atlaslootinfo.secType then
		button.secButton.Profession = button.__atlaslootinfo.secType[2]
		button.secButton.SpellID = button.__atlaslootinfo.secType[2]
		Prof.Refresh(button.secButton)
	else
		button.Profession = button.__atlaslootinfo.type[2]
		button.SpellID = button.__atlaslootinfo.type[2]
		Prof.Refresh(button)
	end
end

function Prof.OnClear(button)
	ItemQuery:Remove(button)
	ItemQuery:Remove(button.secButton)
	button.Profession = nil
	button.SpellID = nil
	button.ItemID = nil
	button.filterItemID = nil
	button.secButton.Profession = nil
	button.secButton.SpellID = nil
	button.secButton.ItemID = nil
	button.secButton.filterItemID = nil

	if button.ExtraFrameShown then
		AtlasLoot.Button:ExtraItemFrame_ClearFrame()
		button.ExtraFrameShown = false
	end
end

function Prof.OnEnter(button)
	local tooltip = GetAlTooltip()
	tooltip:ClearLines()
	tooltip:SetOwner(button, "ANCHOR_RIGHT", -(button:GetWidth() * 0.5), 5)
	-- Some client builds may not have spell data available for every craft spell.
	-- Fallback to the created item tooltip.
	local spellName = button.SpellID and GetSpellInfo(button.SpellID)
	if spellName then
		tooltip:SetSpellByID(button.SpellID)
	elseif button.ItemID then
		local _, itemLink = GetItemInfo(button.ItemID)
		if itemLink then
			tooltip:SetHyperlink(itemLink)
		else
			tooltip:SetHyperlink("item:"..button.ItemID)
		end
	end
	if AtlasLoot.db.showIDsInTT then
		tooltip:AddDoubleLine("SpellID:", format(WHITE_TEXT, button.SpellID))
	end
	tooltip:Show()
end

function Prof.OnLeave(button)
	GetAlTooltip():Hide()
end

function Prof.OnMouseAction(button, mouseButton)
	if not mouseButton then return end
	mouseButton = ProfClickHandler:Get(mouseButton)
	if mouseButton == "ChatLink" then
		if button.SpellID then
			AtlasLoot.Button:AddChatLink(Profession.GetChatLink(button.SpellID))
		elseif button.ItemID and button.type ~= "secButton" then
			local itemInfo, itemLink = GetItemInfo(button.ItemID)
			AtlasLoot.Button:AddChatLink(itemLink)
		end
	elseif mouseButton == "WoWHeadLink" then
		AtlasLoot.Button:OpenWoWHeadLink(button, "spell", button.SpellID)
	elseif mouseButton == "DressUp" then
		if button.ItemID then
			local itemInfo, itemLink = GetItemInfo(button.ItemID)
			if itemLink then
				DressUpItemLink(itemLink)
			end
		end
	elseif mouseButton == "ShowExtraItems" then
		if Profession.IsProfessionSpell(button.SpellID) then
			button.ExtraFrameShown = true
			AtlasLoot.Button:ExtraItemFrame_GetFrame(button, Profession.GetDataForExtraFrame(button.SpellID))
		end
	end
end

-- TODO: Add Query?
function Prof.Refresh(button)
	local spellName, _, spellTexture = GetSpellInfo(button.SpellID)

	if Profession.IsProfessionSpell(button.SpellID) then
		local _, itemName, itemQuality, itemTexture, itemCount
		button.ItemID = Profession.GetCreatedItemID(button.SpellID)
		button.filterItemID = button.ItemID
		if button.ItemID then
			itemName, _, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(button.ItemID)
			if not itemName then
				ItemQuery:Add(button)
				return false
			end
			itemCount = Profession.GetNumCreatedItems(button.SpellID)
		end
		itemQuality = itemQuality or 0

		button.overlay:Show()
		-- enchanting border
		if not button.ItemID or button.type == "secButton" then
			itemQuality = "gold"
		end
		button.overlay:SetQualityBorder(itemQuality)

		if button.type == "secButton" then
			itemTexture = nil
			itemCount = nil
		else
			if itemName then
				button.name:SetText("|c"..ITEM_COLORS[itemQuality or 0]..(spellName or itemName))
			elseif spellName then
				button.name:SetText(PROF_COLOR..spellName)
			else
				-- No spell name and no created item name (should be rare) – show spellID.
				button.name:SetText(PROF_COLOR..tostring(button.SpellID or ""))
			end
			button.extra:SetText(Profession.GetSpellDescriptionWithRank(button.SpellID, true))
		end
		if itemCount and itemCount > 1 then
			button.count:SetText(itemCount)
			button.count:Show()
		end
		if AtlasLoot.db.ContentPhases.enableOnCrafting then
			local phaseT, active = Profession.GetPhaseTextureForSpellID(button.SpellID)
			if phaseT and not active then
				button.phaseIndicator:SetTexture(phaseT)
				button.phaseIndicator:Show()
			end
		end
		--Profession.GetPhaseTextureForSpellID(spellID)
		button.icon:SetTexture(itemTexture or Profession.GetIcon(button.SpellID) or spellTexture)
	end

end

--[[
function Prof.GetStringContent(str)
	return {str_match(str, "(%w+):(%d+)")}
end
]]--
