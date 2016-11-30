local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

function BUI.CIM.InitModule(m_options)

	m_options["attributeIcons"] = true
	m_options["triggerSpeed"] = 10
	m_options["condenseLtooltip"] = false
	m_options["enhanceCompat"] = false
	
	m_options["rhScrollSpeed"] = 50

	return m_options
end

function BUI.CIM.Setup()
	-- Apply compatibility patches to enhance compatibility between BUI and other addons which hook the interfaces
	-- Warning: this is HIGHLY likely to break some addons' functionality, but this is unavoidable.

	-- Developer's Note: if you have an addon that is breaking (or non-functional) with BetterUI, send a message to
	-- me (@prasoc) and I will do as much as I can to patch BetterUI
	if BUI.Settings.Modules["CIM"].enhanceCompat then

		-- only apply compat patches if the module is enabled!
		if BUI.Settings.Modules["Inventory"].m_enabled then
			-- Replace the default interface class with the shrinkwrapped version. This means that any hooks applied by other addons
			-- get hooked into BUI.Inventory.Class instead
			--ZO_GamepadInventory = ZOS_GamepadInventory
			--zo_calllater(function() ddebug("Compatibility patch for ZO_GamepadInventory enabled.") end, 1000)
		end
	end
end
