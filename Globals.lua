if BUI == nil then BUI = {} end

BUI.name = "BetterUI"
BUI.version = "0.51"

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
BUI.Player.CraftingSkillTypes = { CRAFTING_TYPE_BLACKSMITHING, CRAFTING_TYPE_CLOTHIER, CRAFTING_TYPE_WOODWORKING }

-- Default settings applied on install
BUI.defaults = {
	showUnitPrice=true,
	showMMPrice=true,
	showWritHelper=true,
	showAccountName = true,
	showHealthText=true,
	flipGSbuttons=true,
	scrollingDisable = false,
	attributeLabels=true,
	showCharacterColor={1,0.5,0,1}
}