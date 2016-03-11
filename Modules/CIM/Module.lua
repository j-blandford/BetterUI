local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

function BUI.CIM.InitModule(m_options)
	m_options["enableJunk"] = true
	m_options["attributeIcons"] = true
	m_options["triggerSpeed"] = 10
	m_options["condenseLtooltip"] = false

	return m_options
end

function BUI.CIM.Setup()

end