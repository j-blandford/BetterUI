local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Banking Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "|c0066FF[Enhanced Banking]|r Behaviour Settings",
			width = "full",
		},

		{
			type = "header",
			name = "|c0066FF[Enhanced Banking]|r Display Settings",
			width = "full",
		},

	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Banking.InitModule(m_options)

	return m_options
end

function BUI.Banking.Setup()

	Init("Bank", "Banking")

	BUI.Banking.Init()

end
