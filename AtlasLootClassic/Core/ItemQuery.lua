local AtlasLoot = _G.AtlasLoot
local ItemQuery = {}
AtlasLoot.ItemQuery = ItemQuery

local pairs, next = pairs, next
local CreateFrame = CreateFrame
local GetItemInfo = (_G.C_Item and _G.C_Item.GetItemInfo) or _G.GetItemInfo
local GetItemStats = (_G.C_Item and _G.C_Item.GetItemStats) or _G.GetItemStats
local GetTime = GetTime

local SPAM_PROTECT = 0.5

local Proto = {}

local tooltip
local function EnsureTooltip()
	if tooltip then return tooltip end
	tooltip = CreateFrame("GameTooltip", "AtlasLootItemQueryTooltip", UIParent, "GameTooltipTemplate")
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	return tooltip
end

local function CheckItemInfo(self)
	if not self.itemInfoList then return end
	local t = EnsureTooltip()
	local checked = 0
	for i = 1, self.NumItemInfoItems do
		local itemID = self.itemInfoList[i]
		if itemID then
			if GetItemInfo(itemID) then
				self.itemInfoList[i] = nil
				self.NumItemInfoItemsFound = self.NumItemInfoItemsFound + 1
			else
				t:ClearLines()
				t:SetHyperlink("item:"..itemID)
			end
			checked = checked + 1
			if checked >= 6 then
				break
			end
		end
	end
	if self.NumItemInfoItems == self.NumItemInfoItemsFound then
		self.itemInfoList = nil
		self.NumItemInfoItems = nil
		self.NumItemInfoItemsFound = nil
		if self.OnItemInfoFinish then
			self.OnItemInfoFinish()
			self.OnItemInfoFinish = nil
		end
	end
end

local function CheckItemStats(self)
	if not self.itemStatsList then return end
	local checked = 0
	for i = 1, self.NumItemStatsItems do
		local itemStr = self.itemStatsList[i]
		if itemStr then
			if GetItemStats(itemStr) then
				self.itemStatsList[i] = nil
				self.NumItemStatsItemsFound = self.NumItemStatsItemsFound + 1
			end
			checked = checked + 1
			if checked >= 6 then
				break
			end
		end
	end
	if self.NumItemStatsItems == self.NumItemStatsItemsFound then
		self.itemStatsList = nil
		self.NumItemStatsItems = nil
		self.NumItemStatsItemsFound = nil
		if self.OnItemStatsFinish then
			self.OnItemStatsFinish()
			self.OnItemStatsFinish = nil
		end
	end
end

function Proto.OnUpdate(frame, elapsed)
	if frame.lastUpdate and (GetTime() - frame.lastUpdate <= SPAM_PROTECT) then return end
	local self = frame.obj
	CheckItemInfo(self)
	CheckItemStats(self)
	if not self.itemInfoList and not self.itemStatsList then
		frame:SetScript("OnUpdate", nil)
	end
	frame.lastUpdate = GetTime()
end

function Proto:Wipe()
	self.itemInfoList = nil
	self.NumItemInfoItems = nil
	self.NumItemInfoItemsFound = nil
	self.OnItemInfoFinish = nil

	self.itemStatsList = nil
	self.NumItemStatsItems = nil
	self.NumItemStatsItemsFound = nil
	self.OnItemStatsFinish = nil

	self.frame:SetScript("OnUpdate", nil)
end

function Proto:AddItemInfoList(list, onFinishFunc)
	if not list then return end
	self.itemInfoList = {}
	for i = 1, #list do
		self.itemInfoList[i] = list[i]
	end
	self.NumItemInfoItems = #list
	self.NumItemInfoItemsFound = 0
	self.OnItemInfoFinish = onFinishFunc
	self.frame:SetScript("OnUpdate", self.OnUpdate)
	self.OnUpdate(self.frame, 0)
end

function Proto:AddItemStatsList(list, onFinishFunc)
	if not list then return end
	self.itemStatsList = {}
	for i = 1, #list do
		self.itemStatsList[i] = "item:" .. list[i]
	end
	self.NumItemStatsItems = #list
	self.NumItemStatsItemsFound = 0
	self.OnItemStatsFinish = onFinishFunc
	self.frame:SetScript("OnUpdate", self.OnUpdate)
	self.OnUpdate(self.frame, 0)
end

function ItemQuery:Create(tab)
	tab = tab or {}
	for k, v in pairs(Proto) do
		tab[k] = v
	end
	tab.frame = CreateFrame("FRAME")
	tab.frame.obj = tab
	tab.frame:SetScript("OnUpdate", tab.OnUpdate)
	tab.frame:SetScript("OnEvent", nil)
	return tab
end
