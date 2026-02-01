
if not _G.C_Map then _G.C_Map = {} end
local MAPID_FALLBACK = {
    [2597] = "Alterac Valley",
    [3277] = "Warsong Gulch",
    [3358] = "Arathi Basin",
    [3483] = "Hellfire Peninsula",
    [3518] = "Nagrand",
    [3519] = "Terokkar Forest",
    [3521] = "Zangarmarsh",
    [4197] = "Wintergrasp",
}
function _G.C_Map.GetAreaInfo(mapID)
    return MAPID_FALLBACK[mapID]
end

local _G = _G

if not _G.WOW_PROJECT_MAINLINE then _G.WOW_PROJECT_MAINLINE = 1 end
if not _G.WOW_PROJECT_CLASSIC then _G.WOW_PROJECT_CLASSIC = 2 end
if not _G.WOW_PROJECT_ID then _G.WOW_PROJECT_ID = _G.WOW_PROJECT_CLASSIC end

if not _G.GetCurrentRegion then
  _G.GetCurrentRegion = function() return 1 end
end

if not _G.GetCurrentRegionName then
  _G.GetCurrentRegionName = function() return "TR" end
end

if not _G.GetMapNameByID then
  _G.GetMapNameByID = function(id)
    if not id then return "" end
    return tostring(id)
  end
end


if not _G.Ambiguate then _G.Ambiguate = function(name) return name end end
if not _G.GetDifficultyInfo then _G.GetDifficultyInfo = function() return "" end end
if not _G.GetAddOnEnableState then _G.GetAddOnEnableState = function() return 2 end end

if not _G.TRANSMOGRIFY then _G.TRANSMOGRIFY = "Transmogrify" end

if not _G.Enum then _G.Enum = {} end

if not _G.securecallfunction then
  _G.securecallfunction = function(func, ...)
    return func(...)
  end
end

if not _G.RegisterAddonMessagePrefix then
  _G.RegisterAddonMessagePrefix = function() return true end
end

if not _G.GetItemClassInfo then
  _G.GetItemClassInfo = function(classID)
    if not _G.GetAuctionItemClasses then return "" end
    local classes = { _G.GetAuctionItemClasses() }
    return classes[(tonumber(classID) or 0) + 1] or ""
  end
end

if not _G.GetItemSubClassInfo then
  _G.GetItemSubClassInfo = function(classID, subClassID)
    if not _G.GetAuctionItemClasses or not _G.GetAuctionItemSubClasses then return "" end
    local className = _G.GetItemClassInfo and _G.GetItemClassInfo(classID) or ""
    if not className or className == "" then return "" end
    local classes = { _G.GetAuctionItemClasses() }
    local idx
    for i = 1, #classes do
      if classes[i] == className then idx = i break end
    end
    if not idx then return "" end
    local ok, a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p = pcall(_G.GetAuctionItemSubClasses, idx)
    if not ok then return "" end
    local subs = { a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p }
    local sidx = (tonumber(subClassID) or 0) + 1
    return subs[sidx] or ""
  end
end

if not _G.C_AddOns then
  _G.C_AddOns = {}
  local C = _G.C_AddOns
  C.GetAddOnMetadata = _G.GetAddOnMetadata
  C.GetNumAddOns = _G.GetNumAddOns
  C.GetAddOnInfo = _G.GetAddOnInfo
  C.IsAddOnLoaded = _G.IsAddOnLoaded
  C.GetAddOnEnableState = _G.GetAddOnEnableState
  C.LoadAddOn = _G.LoadAddOn
end

if not _G.C_ChatInfo then
  _G.C_ChatInfo = {}
  local C = _G.C_ChatInfo
  C.SendAddonMessage = _G.SendAddonMessage
  C.RegisterAddonMessagePrefix = _G.RegisterAddonMessagePrefix
end

if not _G.C_Timer then
  _G.C_Timer = {}
  local tasks = {}
  local f = _G.CreateFrame("Frame")
  f:SetScript("OnUpdate", function(_, elapsed)
    for i = #tasks, 1, -1 do
      local t = tasks[i]
      t.delay = t.delay - elapsed
      if t.delay <= 0 then
        local fn = t.fn
        tasks[i] = tasks[#tasks]
        tasks[#tasks] = nil
        if fn then
          pcall(fn)
        end
      end
    end
  end)
  _G.C_Timer.After = function(delay, fn)
    if type(delay) ~= "number" or type(fn) ~= "function" then
      return
    end
    tasks[#tasks + 1] = { delay = delay, fn = fn }
  end
end

do
  if not _G.C_Item then
    _G.C_Item = {}
  end
  local C = _G.C_Item
  if not C.GetItemInfo then C.GetItemInfo = _G.GetItemInfo end
  if not C.GetItemStats then C.GetItemStats = _G.GetItemStats end
  if not C.GetItemCount then C.GetItemCount = _G.GetItemCount end
  if not C.IsEquippableItem then C.IsEquippableItem = _G.IsEquippableItem end
  if not C.GetItemQualityColor then C.GetItemQualityColor = _G.GetItemQualityColor end
  if not C.GetItemClassInfo then C.GetItemClassInfo = _G.GetItemClassInfo end
  if not C.GetItemSubClassInfo then C.GetItemSubClassInfo = _G.GetItemSubClassInfo end
  if not C.GetItemQualityByID then
    C.GetItemQualityByID = function(itemID)
      local _, _, q = _G.GetItemInfo(itemID)
      return q
    end
  end
  if not C.DoesItemExistByID then
    C.DoesItemExistByID = function(itemID)
      local name = _G.GetItemInfo(itemID)
      return name ~= nil
    end
  end
  if not C.GetItemIconByID then
    C.GetItemIconByID = function(itemID)
      -- Prefer GetItemIcon (works even when full item info isn't cached yet).
      local tex = _G.GetItemIcon and _G.GetItemIcon(itemID)
      if tex then return tex end
      local _, _, _, _, _, _, _, _, _, tex2 = _G.GetItemInfo(itemID)
      return tex2
    end
  end
  if not C.GetItemInfoInstant then
		C.GetItemInfoInstant = function(item)
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
  if not C.GetItemSetInfo then
    -- 3.3.5a: Use the global GetItemSetInfo API when available.
    if type(_G.GetItemSetInfo) == "function" then
      C.GetItemSetInfo = _G.GetItemSetInfo
    else
      C.GetItemSetInfo = function()
        return nil
      end
    end
  end
end

if not _G.C_Spell then
  _G.C_Spell = {}
  local C = _G.C_Spell
  C.GetSpellInfo = _G.GetSpellInfo
  C.GetSpellName = function(spellID)
    local name = _G.GetSpellInfo(spellID)
    return name
  end
  C.GetSpellTexture = function(spellID)
    local _, _, tex = _G.GetSpellInfo(spellID)
    return tex
  end
end

if not _G.C_Map then
  _G.C_Map = {}
  local C = _G.C_Map
  C.GetAreaInfo = function()
    return nil
  end
  C.GetMapInfo = function()
    return nil
  end
end

if not _G.C_TransmogCollection then
  _G.C_TransmogCollection = {}
  local C = _G.C_TransmogCollection
  C.GetItemInfo = function()
    return nil
  end
  C.GetSourceInfo = function()
    return nil
  end
  C.PlayerHasTransmogItemModifiedAppearance = function()
    return false
  end
end

if not _G.C_MountJournal then
  _G.C_MountJournal = {}
  local C = _G.C_MountJournal
  C.GetMountIDs = function()
    return {}
  end
  C.GetMountInfoByID = function()
    return nil
  end
end

if not _G.C_PetJournal then
  _G.C_PetJournal = {}
  local C = _G.C_PetJournal
  C.GetNumPets = function()
    return 0
  end
  C.GetPetInfoByIndex = function()
    return nil
  end
end

if not _G.C_EquipmentSet then
  _G.C_EquipmentSet = {}
  local C = _G.C_EquipmentSet
  C.GetEquipmentSetIDs = function()
    return {}
  end
  C.GetItemIDs = function()
    return nil
  end
end

if not _G.Ambiguate then
  _G.Ambiguate = function(name)
    return name
  end
end

if not _G.RegisterAddonMessagePrefix then
  _G.RegisterAddonMessagePrefix = function()
    return true
  end
end

if not _G.GetAddOnEnableState then
  _G.GetAddOnEnableState = function()
    return 2
  end
end

if not _G.SetPortraitTextureFromCreatureDisplayID then
	_G.SetPortraitTextureFromCreatureDisplayID = function(tex)
		if tex and tex.SetTexture then
			tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
		end
	end
end

if not _G.GetAreaInfo then
	_G.GetAreaInfo = function()
		return nil
	end
end
