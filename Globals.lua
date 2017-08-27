BUI = {}

BUI.name = "BetterUI"
BUI.version = "2.46"

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()

-- pseudo-Class definitions
BUI.CONST = {}
--BUI.Lib = {}
BUI.CIM = {}

BUI.GenericHeader = {}
BUI.GenericFooter = {}
BUI.Interface = {}
BUI.Interface.Window = {}

BUI.Store = {
	Class = {},
	Window = {},

	List = {},
	Buy = {}
}

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

BUI.Helper = {
	GamePadBuddy = {},
	IokaniGearChanger = {},
	AutoCategory = {},
}

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

function Init_ModulePanel(moduleName, moduleDesc)
	return {
		type = "panel",
		name = "|t24:24:/esoui/art/buttons/gamepad/xbox/nav_xbone_b.dds|t "..BUI.name.." ("..moduleName..")",
		displayName = "|c0066ffBETTERUI|r :: "..moduleDesc,
		author = "prasoc, RockingDice",
		version = BUI.version,
		slashCommand = "/bui",
		registerForRefresh = true,
		registerForDefaults = true
	}
end

ZO_Store_OnInitialize_Gamepad = function(...) end

-- Imagery, you dont need to localise these strings
ZO_CreateStringId("SI_BUI_INV_EQUIP_TEXT_HIGHLIGHT","|cFF6600<<1>>|r")
ZO_CreateStringId("SI_BUI_INV_EQUIP_TEXT_NORMAL","|cCCCCCC<<1>>|r")
