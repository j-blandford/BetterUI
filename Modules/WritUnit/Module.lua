local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Guild Store Improvement Settings")

	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Writs.InitModule(m_options)

    return m_options
end


local function OnCraftStation(eventCode, craftId, sameStation)
	if eventCode ~= 0 then -- 0 is an invalid code
			BUI.Writs.Show(tonumber(craftId))
	end
end

local function OnCloseCraftStation(eventCode)
	BUI.Writs.Hide()
end

local function OnCraftItem(eventCode, craftId)
	if eventCode ~= 0 then -- 0 is an invalid code
			BUI.Writs.Show(tonumber(craftId))
	end
end

function BUI.Writs.Setup()
	local tlw = BUI.WindowManager:CreateTopLevelWindow("BUI_TLW")
	local BUI_WP = BUI.WindowManager:CreateControlFromVirtual("BUI_WritsPanel",tlw,"BUI_WritsPanel")

	EVENT_MANAGER:RegisterForEvent(BUI.name, EVENT_CRAFTING_STATION_INTERACT, OnCraftStation)
	EVENT_MANAGER:RegisterForEvent(BUI.name, EVENT_END_CRAFTING_STATION_INTERACT, OnCloseCraftStation)
	EVENT_MANAGER:RegisterForEvent(BUI.name, EVENT_CRAFT_COMPLETED, OnCraftItem)

	BUI_WP:SetHidden(true)
end