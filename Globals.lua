BUI = {}

BUI.name = "BetterUI"
BUI.version = "2.0"

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()

-- pseudo-Class definitions
BUI.CONST = {}
BUI.Lib = {}
BUI.CIM = {}

BUI.GenericHeader = {}
BUI.GenericFooter = {}
BUI.Interface = {}
BUI.Interface.Window = {}

BUI.Inventory = {
	List = {},
	Class = {}
}

BUI.Writs = {
	List = {}
}

BUI.GuildStore = {
	Browse = {},
	BrowseResults = {},
	Listings = {},
	Sell = {}
}

BUI.Banking = {
	Class = {}
}

BUI.Tooltips = {

}

BUI.Player = {
	ResearchTraits = {}
}

BUI.Settings = {}

BUI.DefaultSettings = {
	firstInstall = true,
	Modules = {
		["*"] = { -- Module setting template
			m_enabled = false,
			m_setup = function() end,
		}
	}
}


function ddebug(str)
	return d("|c0066ff[BUI]|r "..str)
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



BUI.Lib.stringTable = {
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
	BANKING_WITHDRAW = "Withdraw",
	BANKING_DEPOSIT = "Deposit",
	BANKING_BUYSPACE = "Buy More Space (<<1>>)",
}

function BUI.Lib.GetString(stringName)
	ddebug("Depreciated BUI.Lib.GetString called: "..stringName)
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
