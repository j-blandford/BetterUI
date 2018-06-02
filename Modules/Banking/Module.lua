local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local changed = false
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
		{
			type = "header",
			name = "|c0066FF[Enhanced Inventory]|r Icon",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Item Icon - Unbound Items",
			tooltip = "Show an icon after unbound items.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconUnboundItem end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconUnboundItem = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI."
		},
		{
			type = "checkbox",
			name = "Item Icon - Enchantment",
			tooltip = "Show an icon after enchanted item.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconEnchantment end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconEnchantment = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI."
		},
		{
			type = "checkbox",
			name = "Item Icon - Set Gear",
			tooltip = "Show an icon after set gears.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconSetGear end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconSetGear = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI."
		},
		{
			type = "checkbox",
			name = "Item Icon - Iakoni's Gear Changer",
			tooltip = "Show the first set number in Iakoni's settings.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconIakoniGearChanger end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconIakoniGearChanger = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI."
		},
		{
			type = "checkbox",
			name = "            Show all sets instead",
			tooltip = "Show all sets if in multiple Iakoni's settings.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconIakoniGearChangerAllSets end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconIakoniGearChangerAllSets = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI.",
			disabled = function() return not BUI.Settings.Modules["Banking"].showIconIakoniGearChanger end,  
		},		
		{
			type = "checkbox",
			name = "Item Icon - GamePadBuddy's Status Indicator",
			tooltip = "Show an icon to indicate gear's researchable/known/duplicated/researching/ornate/intricate status.",
			getFunc = function () return BUI.Settings.Modules["Banking"].showIconGamePadBuddyStatusIcon end,
			setFunc = function (value) BUI.Settings.Modules["Banking"].showIconGamePadBuddyStatusIcon = value
				changed = true end,
			width = "full",
			warning="Needs to reload UI."
		},
		{ 			
			type = "header", 		
		},		         
		{             
			type = "button",             
			name = "Apply Changes",             
			func = function() ReloadUI() end, 			
			disabled = function() return not changed end,         
		},	
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Banking.InitModule(m_options)
	m_options["showIconEnchantment"] = true
	m_options["showIconSetGear"] = true
	m_options["showIconUnboundItem"] = true
	m_options["showIconIakoniGearChanger"] = true
	m_options["showIconIakoniGearChangerAllSets"] = false
	m_options["showIconGamePadBuddyStatusIcon"] = true
	return m_options
end

function BUI.Banking.Setup()

	Init("Bank", "Banking")

	BUI.Banking.Init()

end
