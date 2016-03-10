local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")
local dirtyModules = false

if BUI == nil then BUI = {} end


function BUI.InitModuleOptions()

	local panelData = Init_ModulePanel("Modules", "Interface Modules")

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
			getFunc = function() return BUI.settings.moduleCIM end,
			setFunc = function(value) BUI.settings.moduleCIM = value 
									dirtyModules = true end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable |c0066FFEnhanced Guild Store|r",
			tooltip = "Complete overhaul of the guild store, and MaterMerchant/dataDaedra integration",
			getFunc = function() return BUI.settings.moduleGS end,
			setFunc = function(value) BUI.settings.moduleGS = value 
									dirtyModules = true end,
			disabled = function() return not BUI.settings.moduleCIM end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable |c0066FFEnhanced Inventory|r",
			tooltip = "Completely redesigns the gamepad's inventory interface",
			getFunc = function() return BUI.settings.moduleInterface end,
			setFunc = function(value) BUI.settings.moduleInterface = value 
									dirtyModules = true  end,
			disabled = function() return not BUI.settings.moduleCIM end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable Daily Writ module",
			tooltip = "Displays the daily writ, and progress, at each crafting station",
			getFunc = function() return BUI.settings.moduleWrit end,
			setFunc = function(value) BUI.settings.moduleWrit = value 
									dirtyModules = true  end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable General Interface Improvements",
			tooltip = "Vast improvements to the ingame tooltips and unit frames",
			getFunc = function() return BUI.settings.moduleTooltips end,
			setFunc = function(value) BUI.settings.moduleTooltips = value 
									dirtyModules = true  end,
			width = "full",
		},
		{
			type = "button",
			name = "Apply Changes",
			disabled = function() return not dirtyModules end,
			func = function() ReloadUI() end
		}
	}

	LAM:RegisterAddonPanel("BUI_".."Modules", panelData)
	LAM:RegisterOptionControls("BUI_".."Modules", optionsTable)
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

function BUI.Initialize(event, addon)
    -- filter for just BUI addon event
	if addon ~= BUI.name then return end

	-- load our saved variables
	BUI.settings = ZO_SavedVars:New("BetterUISavedVars", 1, nil, BUI.defaults)
	BUI.EventManager:UnregisterForEvent("BetterUIInitialize", EVENT_ADD_ON_LOADED)

	if(IsInGamepadPreferredMode()) then
		if(BUI.settings.moduleCIM) then
			BUI.Lib.CIM.Setup()
			if(BUI.settings.moduleGS) then 
				BUI.GuildStore.Setup()
			end
			if(BUI.settings.moduleInterface) then 
				BUI.Inventory.Setup() 
			end
		end
		if(BUI.settings.moduleWrit) then 
			BUI.Writs.Setup()
		end
		if(BUI.settings.moduleTooltips) then
			BUI.Tooltips.Setup()
		end
		BUI.Player.GetResearch()
	else
		d("[BUI] Not Loaded: gamepad mode disabled.")
	end

	BUI.InitModuleOptions()
end

-- register our event handler function to be called to do initialization
BUI.EventManager:RegisterForEvent(BUI.name, EVENT_ADD_ON_LOADED, function(...) BUI.Initialize(...) end)