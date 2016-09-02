local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")


local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Store Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "|c0066FF[Enhanced Store]|r Behaviour",
			width = "full",
		},
		{
			type = "header",
			name = "|c0066FF[Enhanced Store]|r Display",
			width = "full",
		},
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Store.InitModule(m_options)
    -- m_options["savePosition"] = true
    -- m_options["enableWrapping"] = true
    -- m_options["showMarketPrice"] = false
    -- m_options["useTriggersForSkip"] = false
    -- m_options["enableJunk"] = false
	-- m_options["displayCharAttributes"] = true
    return m_options
end


function BUI.Store.Setup()
	Init("Store", "Store")

	BUI.Store.Window = BUI.Store.Class:New(BUI_StoreWindow)

    BUI.Store.Window:AddComponent(BUI.Store.Buy:New(BUI.Store.Window))

	store = STORE_WINDOW_GAMEPAD
end
