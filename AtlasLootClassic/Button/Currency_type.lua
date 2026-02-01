local _G = getfenv(0)
local tonumber, type = tonumber, type
local GetCurrencyInfo = _G.GetCurrencyInfo
local GetCurrencyListInfo = _G.GetCurrencyListInfo
local GetCurrencyListLink = _G.GetCurrencyListLink

local function SafeGetCurrencyInfo(id)
	if GetCurrencyInfo then
		return GetCurrencyInfo(id)
	end
	-- 3.3.5a: no GetCurrencyInfo(id). Best-effort scan of currency list by link.
	if GetCurrencyListInfo and GetCurrencyListLink then
		local i = 1
		while true do
			local name, isHeader, _, _, _, _, _, _, _, icon = GetCurrencyListInfo(i)
			if not name then break end
			if not isHeader then
				local link = GetCurrencyListLink(i)
				if link and link:find("currency:"..tostring(id), 1, true) then
					return name, nil, icon
				end
			end
			i = i + 1
		end
	end
	return nil
end
local GetCurrencyLink = _G.GetCurrencyLink
local GetItemQualityColor = _G.GetItemQualityColor

local AtlasLoot = _G.AtlasLoot
local Currency = AtlasLoot.Button:AddType("Currency", "c")
local AL = AtlasLoot.Locales
local ClickHandler = AtlasLoot.ClickHandler
local GetAlTooltip = AtlasLoot.Tooltip.GetTooltip

local CurrencyClickHandler = nil

local QUALITY_COLORS = {}
local DUMMY_ITEM_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

ClickHandler:Add(
	"Currency",
	{
		ChatLink = { "LeftButton", "Shift" },
		WoWHeadLink = { "RightButton", "Shift" },

		types = {
			ChatLink = true,
			WoWHeadLink = true,
		},
	},
	{
		{ "ChatLink", 	AL["Chat Link"], 	AL["Add item into chat"] },
		{ "WoWHeadLink", 	AL["Show WowHead link"], 	AL["Shows a copyable link for WoWHead"] },
	}
)

local function OnInit()
	if not CurrencyClickHandler then
		CurrencyClickHandler = ClickHandler:GetHandler("Currency")
		for i = 0, 7 do
			local _, _, _, hex = GetItemQualityColor(i)
			QUALITY_COLORS[i] = "|c" .. (hex or "ffffffff")
		end
	end
	Currency.CurrencyClickHandler = CurrencyClickHandler
end
AtlasLoot:AddInitFunc(OnInit)

function Currency.OnSet(button, second)
	if not button then return end

	if second and button.__atlaslootinfo.secType then
		button.secButton.CurrencyID = button.__atlaslootinfo.secType[2]
		Currency.Refresh(button.secButton)
	else
		button.CurrencyID = button.__atlaslootinfo.type[2]
		Currency.Refresh(button)
	end
end

function Currency.OnMouseAction(button, mouseButton)
	if not mouseButton then return end
	mouseButton = CurrencyClickHandler:Get(mouseButton)
	if mouseButton == "WoWHeadLink" then
		AtlasLoot.Button:OpenWoWHeadLink(button, "currency", button.CurrencyID)
	elseif mouseButton == "ChatLink" then
		AtlasLoot.Button:AddChatLink((GetCurrencyLink and GetCurrencyLink(button.CurrencyID, 1)) or ("currency:" .. button.CurrencyID))
	end
end

function Currency.OnEnter(button, owner)
	if not button.CurrencyID then return end
	local tooltip = GetAlTooltip()
	tooltip:ClearLines()
	if owner and type(owner) == "table" then
		tooltip:SetOwner(owner[1], owner[2], owner[3], owner[4])
	else
		tooltip:SetOwner(button, "ANCHOR_RIGHT", -(button:GetWidth() * 0.5), 5)
	end
	local name = SafeGetCurrencyInfo(button.CurrencyID)
	if name then
		local link = GetCurrencyLink and GetCurrencyLink(button.CurrencyID, 1)
		if link then
			tooltip:SetHyperlink(link)
		else
			tooltip:AddLine(name)
		end
		tooltip:Show()
	end
end

function Currency.OnLeave()
	GetAlTooltip():Hide()
end

function Currency.OnClear(button)
	button.CurrencyID = nil
	button.secButton.CurrencyID = nil

	if button.icon then
		button.icon:SetDesaturated(false)
	end
	button.secButton.icon:SetDesaturated(false)
end

function Currency.GetStringContent(str)
	return tonumber(str)
end

function Currency.Refresh(button)
	if not button.CurrencyID then return end

	local currencyName, _, currencyTexture = SafeGetCurrencyInfo(button.CurrencyID)
	if not currencyName then
		currencyName, currencyTexture = "", DUMMY_ITEM_ICON
	end

	local currencyQuality = 1
	button.RawName = currencyName

	button.overlay:Show()
	button.overlay:SetQualityBorder(currencyQuality)

	if button.type == "secButton" then
		button:SetTexture(currencyTexture)
	else
		button.name:SetText((QUALITY_COLORS[currencyQuality] or "|cffffffff") .. currencyName)
		button.icon:SetTexture(currencyTexture)
	end

	return true
end

function Currency.ShowToolTipFrame()
end