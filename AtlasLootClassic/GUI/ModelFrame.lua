local AtlasLoot = _G.AtlasLoot
local GUI = AtlasLoot.GUI
local ModelFrame = {}
AtlasLoot.GUI.ModelFrame = ModelFrame
local AL = AtlasLoot.Locales

local next = next
local tonumber = tonumber
local type = type
local pcall = pcall

if not HasAlternateForm then
	function HasAlternateForm()
		return false
	end
end

local MAX_CREATURES_PER_ENCOUNTER = 9
local BUTTON_COUNT = 0

ModelFrame.SelectedCreature = nil
ModelFrame.creatureDisplayID = nil
local Creatures = {}
local cache = {}
local buttons = {}

local function GetButtonFromCache()
	local frame = next(cache)
	if frame then
		cache[frame] = nil
	end
	return frame
end

local function ClearButtonList()
	for i = 1, #buttons do
		local button = buttons[i]
		cache[button] = true
		button.info = nil
		button:Hide()
		buttons[i] = nil
	end
end

local function NormalizeModel(m)
	if m.SetModelScale then pcall(m.SetModelScale, m, 1) end
	if m.SetPosition then pcall(m.SetPosition, m, 0, 0, 0) end
	if m.SetFacing then pcall(m.SetFacing, m, 0) end
	if m.SetRotation then pcall(m.SetRotation, m, 0) end
end

local function HasGetModel(m)
	return m and type(m.GetModel) == "function"
end

local function ModelLoaded(m)
	if not HasGetModel(m) then
		return true
	end
	local ok, modelPath = pcall(m.GetModel, m)
	return ok and modelPath and modelPath ~= ""
end

function ModelFrame.ButtonOnClick(self)
	if ModelFrame.SelectedCreature then
		ModelFrame.SelectedCreature:Enable()
	end

	if self.displayInfo and (ModelFrame.creatureDisplayID ~= self.displayInfo) and ModelFrame.frame and ModelFrame.frame.model then
		local m = ModelFrame.frame.model
		if m.ClearModel then pcall(m.ClearModel, m) end

		if type(self.displayInfo) == "string" and self.displayInfo:lower():find("%.m2", 1, true) and m.SetModel then
			pcall(m.SetModel, m, self.displayInfo)
			NormalizeModel(m)
		else
			local id = tonumber(self.displayInfo)
			if id then
				local didSet = false

				if m.SetCreature then
					pcall(m.SetCreature, m, id)
					didSet = true
					if ModelLoaded(m) then
						NormalizeModel(m)
					end
				end

				if (not didSet) or (HasGetModel(m) and (not ModelLoaded(m))) then
					local ok = false
					if m.SetCreatureDisplayID then ok = pcall(m.SetCreatureDisplayID, m, id) end
					if (not ok) and m.SetDisplayInfo then ok = pcall(m.SetDisplayInfo, m, id) end
					if ok and ModelLoaded(m) then
						NormalizeModel(m)
					end
				end
			end
		end
	end

	ModelFrame.creatureDisplayID = self.displayInfo
	ModelFrame.SelectedCreature = self
	self:Disable()
end

function ModelFrame:AddButton(name, desc, displayInfo)
	local button = GetButtonFromCache()
	if not button then
		BUTTON_COUNT = BUTTON_COUNT + 1
		local frameName = "AtlasLoot-GUI-ModelFrame-Button" .. BUTTON_COUNT
		button = CreateFrame("Button", frameName, ModelFrame.frame, "AtlasLootCreatureButtonTemplate")
	end
	button:Show()
	buttons[#buttons + 1] = button
	button.displayInfo = displayInfo
	button.name = name
	button.description = desc

	if type(SetPortraitTextureFromCreatureDisplayID) == "function" then
		SetPortraitTextureFromCreatureDisplayID(button.creature, displayInfo)
	else
		button.creature:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
	end

	if #buttons == 1 then
		button:SetPoint("TOPLEFT", ModelFrame.frame, "TOPLEFT", 0, -10)
		ModelFrame.ButtonOnClick(button)
	else
		button:SetPoint("TOPLEFT", buttons[#buttons - 1], "BOTTOMLEFT")
	end

	return button
end

function ModelFrame:Create()
	if self.frame then return end
	local frameName = "AtlasLoot_GUI-ModelFrame"

	self.frame = CreateFrame("Frame", frameName, GUI.frame, _G.BackdropTemplateMixin and "BackdropTemplate" or nil)
	local model = CreateFrame("DressUpModel", nil, self.frame)
	model:SetAllPoints(self.frame)
	self.frame.model = model
	local frame = self.frame
	frame:ClearAllPoints()
	frame:SetParent(GUI.frame)
	frame:SetPoint("TOPLEFT", GUI.frame.contentFrame.itemBG)
	frame:SetSize(560, 450)
	frame.Refresh = ModelFrame.Refresh
	frame.Clear = ModelFrame.Clear
	frame:Hide()
	ModelFrame.creatureDisplayID = 0
end

function ModelFrame:Show()
	if not ModelFrame.frame then ModelFrame:Create() end
	if not ModelFrame.frame:IsShown() or GUI.frame.contentFrame.shownFrame ~= ModelFrame.frame then
		GUI:HideContentFrame()
		ModelFrame.frame:Show()
		GUI.frame.contentFrame.shownFrame = ModelFrame.frame
	end
	if self.DisplayIDs then
		self:SetDisplayID(self.DisplayIDs)
	else
		return GUI.ItemFrame:Show()
	end
end

function ModelFrame:Refresh()
	if not ModelFrame.frame then ModelFrame:Create() end
	ModelFrame:Show()
end

function ModelFrame:SetDisplayID(displayID)
	if not self.frame then ModelFrame:Create() end
	ClearButtonList()
	wipe(Creatures)
	ModelFrame.SelectedCreature = nil
	if not displayID then
		ModelFrame.frame:Hide()
		return
	end
	for k, v in ipairs(displayID) do
		ModelFrame:AddButton(v[2], v[3], v[1])
	end
end

function ModelFrame.Clear()
	ClearButtonList()
	if ModelFrame.frame and ModelFrame.frame.model then
		local m = ModelFrame.frame.model
		if m.ClearModel then
			m:ClearModel()
		elseif m.SetModel then
			m:SetModel("")
		end
	end
	ModelFrame.frame:Hide()
end
