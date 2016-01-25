if BUI == nil then BUI = {} end

BUI.name = "BetterUI"
BUI.version = "0.3"

-- pseudo-Class definitions
BUI.Writs = {}
BUI.GuildStore = {}
BUI.Tooltips = {}
BUI.Player = {}

-- Program Global (scope of BUI, though) variable initialization
BUI.WindowManager = GetWindowManager()
BUI.EventManager = GetEventManager()
BUI.settings = {}
--BUI.inventory = {}
BUI.Writs.List = {}
BUI.Player.ResearchTraits = {}

-- Default settings applied on install
BUI.defaults = {
	showUnitPrice=true,
	showMMPrice=true,
	showWritHelper=true,
	showAccountName = true,
	showCharacterColor={1,0.5,0,1}
}