local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")
local dirtyModules = false

if BUI == nil then BUI = {} end


function BUI.InitModuleOptions()

	local panelData = Init_ModulePanel("Master", "Master Addon Settings")

	local optionsTable = {
		{
			type = "header",
			name = "Master Settings",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable Common Interface Module (CIM)",
			tooltip = "Enables the use of the completely redesigned \"Enhanced\" interfaces!",
			getFunc = function() return BUI.Settings.Modules["CIM"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["CIM"].m_enabled = value
									dirtyModules = true end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable |c0066FFEnhanced Guild Store|r",
			tooltip = "Complete overhaul of the guild store, and MaterMerchant/dataDaedra integration",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].m_enabled = value
									dirtyModules = true end,
			disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable |c0066FFEnhanced Inventory|r",
			tooltip = "Completely redesigns the gamepad's inventory interface",
			getFunc = function() return BUI.Settings.Modules["Inventory"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["Inventory"].m_enabled = value
									dirtyModules = true  end,
			disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable |c0066FFEnhanced Banking|r",
			tooltip = "Completely redesigns the gamepad's banking interface (and has \"Mobile Banking\")",
			getFunc = function() return BUI.Settings.Modules["Banking"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["Banking"].m_enabled = value
									dirtyModules = true  end,
			disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
			--disabled = function() return true end,
			width = "full",
		},
		-- {
		-- 	type = "checkbox",
		-- 	name = "Enable |c0066FFEnhanced Store|r",
		-- 	tooltip = "Completely redesigns the gamepad's store purchase interface",
		-- 	getFunc = function() return BUI.Settings.Modules["Store"].m_enabled end,
		-- 	setFunc = function(value) BUI.Settings.Modules["Store"].m_enabled = value
		-- 							dirtyModules = true  end,
		-- 	disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
		-- 	width = "full",
		-- },
		{
			type = "checkbox",
			name = "Enable Daily Writ module",
			tooltip = "Displays the daily writ, and progress, at each crafting station",
			getFunc = function() return BUI.Settings.Modules["Writs"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["Writs"].m_enabled = value
									dirtyModules = true  end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable General Interface Improvements",
			tooltip = "Vast improvements to the ingame tooltips and unit frames",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].m_enabled end,
			setFunc = function(value) BUI.Settings.Modules["Tooltips"].m_enabled = value
									dirtyModules = true  end,
			width = "full",
		},
		-- {
		-- 	type = "checkbox",
		-- 	name = "Enhance Compatibility with other Addons",
		-- 	tooltip = "BUI heavily alters the interface, breaking lots of addons. This will enhance compatibility. Be aware: things MIGHT break!",
		-- 	getFunc = function() return BUI.Settings.Modules["CIM"].enhanceCompat end,
		-- 	setFunc = function(value) BUI.Settings.Modules["CIM"].enhanceCompat = value
		-- 							dirtyModules = true  end,
		-- 	width = "full",
		-- },
		{
			type = "button",
			name = "Apply Changes",
			disabled = function() return not dirtyModules end,
			func = function() ReloadUI() end
		},

		{
			type = "header",
			name = "Enhanced Interface Global Behaviour",
			width = "full",
		},
		{
            type = "editbox",
            name = "Mouse Scrolling speed on Left Hand tooltip",
            tooltip = "Change how quickly the menu skips when pressing the triggers.",
            getFunc = function() return BUI.Settings.Modules["CIM"].rhScrollSpeed end,
            setFunc = function(value) BUI.Settings.Modules["CIM"].rhScrollSpeed = value end,
            disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
            width = "full",
        },
        {
            type = "editbox",
            name = "Number of lines to skip on trigger",
            tooltip = "Change how quickly the menu skips when pressing the triggers.",
            getFunc = function() return BUI.Settings.Modules["CIM"].triggerSpeed end,
            setFunc = function(value) BUI.Settings.Modules["CIM"].triggerSpeed = value end,
            disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
            width = "full",
        },
		{
			type = "header",
			name = "Enhanced Interface Global Display",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display attribute icons next to the item name",
			tooltip = "Allows you to see enchanted, set and stolen items quickly",
			getFunc = function() return BUI.Settings.Modules["CIM"].attributeIcons end,
			setFunc = function(value) BUI.Settings.Modules["CIM"].attributeIcons = value end,
			disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
			width = "full",
		},
        {
            type = "checkbox",
            name = "Reduce the font size of the item tooltip",
            tooltip = "Allows much more item information to be displayed at once on the tooltips",
            getFunc = function() return BUI.Settings.Modules["CIM"].condenseLTooltip end,
            setFunc = function(value) BUI.Settings.Modules["CIM"].condenseLTooltip = value
                                        ReloadUI() end,
            disabled = function() return not BUI.Settings.Modules["CIM"].m_enabled end,
            width = "full",
            warning="Reloads the UI for the change to propagate"
        },

	}

	LAM:RegisterAddonPanel("BUI_".."Modules", panelData)
	LAM:RegisterOptionControls("BUI_".."Modules", optionsTable)
end

function BUI.PostHook(control, method, fn)
	if control == nil then return end

	local originalMethod = control[method]
	control[method] = function(self, ...)
		originalMethod(self, ...)
		fn(self, ...)
	end
end

function BUI.Hook(control, method, postHookFunction, overwriteOriginal)
	if control == nil then return end
	
	local originalMethod = control[method]
	control[method] = function(self, ...)
		if(overwriteOriginal == false) then originalMethod(self, ...) end
		postHookFunction(self, ...)
	end
end

function BUI.RGBToHex(rgba)
	r,g,b,a = unpack(rgba)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function BUI.ModuleOptions(m_namespace, m_options)
	m_options = m_namespace.InitModule(m_options)
	return m_namespace
end

function BUI.LoadModules()

	if(not BUI._initialized) then
		ddebug("Initializing BUI...")
		BUI.GuildStore.FixMM() -- fix MM is independent of any module
		BUI.Player.GetResearch()
		BUI.Inventory.HookActionDialog()

		if(BUI.Settings.Modules["CIM"].m_enabled) then
			BUI.CIM.Setup()
			if(BUI.Settings.Modules["GuildStore"].m_enabled) then
				BUI.GuildStore.Setup()
			end
			-- if(BUI.Settings.Modules["Store"].m_enabled) then
			-- 	BUI.Store.Setup()
			-- end
			if(BUI.Settings.Modules["Inventory"].m_enabled) then
				BUI.Inventory.Setup()
			end
			if(BUI.Settings.Modules["Banking"].m_enabled) then
				BUI.Banking.Setup()
			end
		end
		if(BUI.Settings.Modules["Writs"].m_enabled) then
			BUI.Writs.Setup()
		end
		if(BUI.Settings.Modules["Tooltips"].m_enabled) then
			BUI.Tooltips.Setup()
		end

		ddebug("Finished! BUI is loaded")
		BUI._initialized = true
	end

end

function BUI.Initialize(event, addon)
    -- filter for just BUI addon event as EVENT_ADD_ON_LOADED is addon-blind
	if addon ~= BUI.name then return end

	-- load our saved variables
	BUI.Settings = ZO_SavedVars:New("BetterUISavedVars", 2.65, nil, BUI.DefaultSettings)

	-- Has the settings savedvars JUST been applied? then re-init the module settings
	if(BUI.Settings.firstInstall) then
		local m_CIM = BUI.ModuleOptions(BUI.CIM, BUI.Settings.Modules["CIM"])
		local m_Inventory = BUI.ModuleOptions(BUI.Inventory, BUI.Settings.Modules["Inventory"])
		local m_Banking = BUI.ModuleOptions(BUI.Banking, BUI.Settings.Modules["Banking"])
		local m_Writs = BUI.ModuleOptions(BUI.Writs, BUI.Settings.Modules["Writs"])
		local m_GuildStore = BUI.ModuleOptions(BUI.GuildStore, BUI.Settings.Modules["GuildStore"])
		local m_Store = BUI.ModuleOptions(BUI.GuildStore, BUI.Settings.Modules["Store"])
		local m_Tooltips = BUI.ModuleOptions(BUI.Tooltips, BUI.Settings.Modules["Tooltips"])

		BUI.Settings.firstInstall = false
	end

	BUI.EventManager:UnregisterForEvent("BetterUIInitialize", EVENT_ADD_ON_LOADED)

	BUI.InitModuleOptions()

	if(IsInGamepadPreferredMode()) then
		BUI.LoadModules()
	else
		BUI._initialized = false
	end

end

-- register our event handler function to be called to do initialization
BUI.EventManager:RegisterForEvent(BUI.name, EVENT_ADD_ON_LOADED, function(...) BUI.Initialize(...) end)
BUI.EventManager:RegisterForEvent(BUI.name.."_Gamepad", EVENT_GAMEPAD_PREFERRED_MODE_CHANGED, function(code, inGamepad)  BUI.LoadModules() end)
