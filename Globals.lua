BUI = {}

BUI.name = "BetterUI"
BUI.version = "1.5"

-- pseudo-Class definitions
BUI.CONST = {}
BUI.Lib = {}
BUI.Lib.CIM = {}
BUI.GenericHeader = {}
BUI.GenericFooter = {}
BUI.Interface = {}
BUI.Interface.Window = {}
BUI.Inventory = {}
BUI.Writs = {}
BUI.GuildStore = {}
BUI.GuildStore.BrowseResults = {}
BUI.GuildStore.Listings = {}
BUI.GuildStore.Sell = {}
BUI.Tooltips = {}
BUI.Player = {}

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()
BUI.settings = {}
BUI.Writs.List = {}
BUI.Player.ResearchTraits = {}

-- Default settings applied on install
BUI.defaults = {
	moduleUnitFrame = false,
	moduleWrit = false,
	moduleInterface= false,
	moduleTooltips=false,
	moduleGS = false,
	moduleQuickslot = false,
	showUnitPrice=true,
	showMMPrice=true,
	showAccountName = true,
	showHealthText=true,
	flipGSbuttons=true,
	scrollingDisable = false,
	attributeLabels=true,
	showStyleTrait=true,
	showCharacterColor={1,0.5,0,1},
	Inventory = { savePosition = true, enableJunk = true, attributeIcons = true, enableWrapping = true, triggerSpeed = 10, condenseLTooltip = true },
	GuildStore = { saveFilters = true, },
	Tooltips = { chatHistory = 200, },
}

function ddebug(str)
	return d("|c0066ff[BUI]|r "..str)
end

function BUI.Lib.Checkbox(checkName, checkDesc, checkValue)
return 	{
			type = "checkbox",
			name = checkName,
			tooltip = checkDesc,
			getFunc = function() return checkValue end,
			setFunc = function(value) checkValue = value end,
			width = "full",
		}
end

-- Thanks to Bart Kiers for this function :)
function BUI.DisplayNumber(number)
	  local i, j, minus, int, fraction = tostring(number):find('([-]?)(%d+)([.]?%d*)')
	  -- reverse the int-string and append a comma to all blocks of 3 digits
	  int = int:reverse():gsub("(%d%d%d)", "%1,")
	  -- reverse the int-string back remove an optional comma and put the 
	  -- optional minus and fractional part back
	  return minus .. int:reverse():gsub("^,", "") .. fraction
end


-- 

BUI.Lib.stringTable = { 
	INV_ITEM_ALL = "|cFF6600All|r",
	INV_ITEM_MATERIALS = "Materials",
	INV_ITEM_QUICKSLOT = "|cFF6600Quickslot|r",
	INV_ITEM_WEAPONS = "Weapons",
	INV_ITEM_APPAREL = "Apparel",
	INV_ITEM_CONSUMABLE = "Consumable",
	INV_ITEM_MISC = "Miscellaneous",
	INV_ITEM_JUNK = "Junk",
	TEXTURE_EQUIP_ICON = "BetterUI/Modules/Inventory/Images/inv_equip.dds",
	TEXTURE_EQUIP_BACKUP_ICON = "BetterUI/Modules/Inventory/Images/inv_equip_backup.dds",
	TEXTURE_EQUIP_SLOT_ICON = "BetterUI/Modules/Inventory/Images/inv_equip_quickslot.dds",
	SI_INV_EQUIPSLOT_TITLE = "Equipping item...",
	SI_INV_EQUIPSLOT_PROMPT = "Which <<1>> hand slot should the weapon go into?",
	SI_INV_EQUIPSLOT_MAIN = "Main",
	SI_INV_EQUIPSLOT_OFFHAND = "Off",
	INV_EQUIP_PROMPT_MAIN = "Main Hand",
	INV_EQUIP_PROMPT_BACKUP = "Off Hand",
	INV_EQUIP_PROMPT_CANCEL = "Cancel",
	SI_INV_SWITCH_EQUIPSLOT = "Switch Slot",
	SI_INV_EQUIPSLOT = "|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_weapons.dds|t |c0066FF<<1>>|r",
	SI_INV_EQUIPSLOT_MAIN = "Main",
	SI_INV_EQUIPSLOT_BACKUP = "Backup",
}

function BUI.Lib.GetString(stringName)
	return BUI.Lib.stringTable[stringName]
end

function Init_ModulePanel(moduleName, moduleDesc)
	return {
		type = "panel",
		name = "|t24:24:/esoui/art/buttons/gamepad/xbox/nav_xbone_b.dds|t "..BUI.name.." ("..moduleName..")",
		displayName = "|c0066ffBETTERUI|r :: "..moduleDesc,
		author = "prasoc",
		version = BUI.version,
		slashCommand = "/bui",
		registerForRefresh = true,	
		registerForDefaults = true
	}
end

-- Allows us to override ZO_GamepadInventory:New, but we need to catch it early!
function BUI_GamepadInventory_OnInitialize(control)
    BUI_GAMEPAD_INVENTORY = ZO_GamepadInventory:New(control)
end