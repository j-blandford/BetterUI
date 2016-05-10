BUI = {}

BUI.name = "BetterUI"
BUI.version = "1.81"

-- pseudo-Class definitions
BUI.CONST = {}
BUI.Lib = {}
BUI.CIM = {}

BUI.GenericHeader = {}
BUI.GenericFooter = {}
BUI.Interface = {}
BUI.Interface.Window = {}

BUI.Inventory = {}
BUI.Inventory.List = {}
BUI.Inventory.Class = {}
BUI.Inventory.SlotActions = ZO_ItemSlotActionsController:Subclass()
BUI.Writs = {}

BUI.GuildStore = {}
BUI.GuildStore.Browse = {}
BUI.GuildStore.BrowseResults = {}
BUI.GuildStore.Listings = {}
BUI.GuildStore.Sell = {}

BUI.Banking = {}
BUI.Banking.Class = {}
BUI.Banking.WithdrawDepositGold = {} -- delete this!

BUI.Tooltips = {}
BUI.Player = {}

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()
BUI.Settings = {}
BUI.Writs.List = {}
BUI.Player.ResearchTraits = {}

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
	INV_ITEM_QUICKSLOT = "|cFF6600Consumable|r",
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
	BANKING_WITHDRAW = "Withdraw",
	BANKING_DEPOSIT = "Deposit",
	BANKING_BUYSPACE = "Buy More Space (<<1>>)",
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

ZO_GamepadInventory_OnInitialize = function(...) end

-- Allows us to override ZO_GamepadInventory:New, but we need to catch it early!
function BUI_GamepadInventory_OnInitialize(control)
    --GAMEPAD_INVENTORY = BUI.Inventory.Class:New(control)
end


function BUI_BankingWithdrawDepositGold_Initialize(control)
    --GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD = BUI.Banking.WithdrawDepositGold:New(control)
end
