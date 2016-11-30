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

    return m_options
end


function BUI.Store.Setup()
	Init("Store", "Store")

	BUI_GAMEPAD_VENDOR_FRAGMENT = ZO_SimpleSceneFragment:New(BUI_StoreWindow)

	STORE_WINDOW_GAMEPAD = BUI.Store.Class:New(BUI_StoreWindow)
    STORE_WINDOW_GAMEPAD:AddComponent(BUI.Store.Buy:New(STORE_WINDOW_GAMEPAD))

	GAMEPAD_VENDOR_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
	GAMEPAD_VENDOR_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
	GAMEPAD_VENDOR_SCENE:AddFragment(BUI_GAMEPAD_VENDOR_FRAGMENT)
	GAMEPAD_VENDOR_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
	GAMEPAD_VENDOR_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
	GAMEPAD_VENDOR_SCENE:AddFragment(GAMEPAD_GENERIC_FOOTER_FRAGMENT)

	store = STORE_WINDOW_GAMEPAD

end
