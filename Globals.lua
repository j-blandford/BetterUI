if BUI == nil then BUI = {} end

BUI.name = "BetterUI"
BUI.version = "0.25"

-- pseudo-Class definitions
BUI.Writs = {}
BUI.GuildStore = {}

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()
BUI.settings = {}
BUI.inventory = {}
BUI.Writs.List = {}

-- Default settings applied on install
BUI.defaults = {
	showUnitPrice=true,
	showMMPrice=true,
	showWritHelper=true,
	showAccountName = true,
	showCharacterColor={1,0.5,0,1}
}