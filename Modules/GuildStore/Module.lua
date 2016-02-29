local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Guild Store Improvement Settings")

	local optionsTable = {
		[1] = {
			type = "header",
			name = "Module Settings",
			width = "full",
		},
		[2] = {
			type="checkbox",
			name="Flip sort and select buttons (A+X)",
			tooltip="Switches the default A=Sort and X=Select to be A=Select and X=Sort",
			getFunc = function() return BUI.settings.flipGSbuttons end,
			setFunc = function(value) BUI.settings.flipGSbuttons = value
									ReloadUI() end,
			width="full",
			warning="Reloads the UI for the change to propagate"
		},
		[3] = {
			type = "checkbox",
			name = "Unit Price in Guild Store",
			tooltip = "Displays a price per unit in guild store listings",
			getFunc = function() return BUI.settings.showUnitPrice end,
			setFunc = function(value) BUI.settings.showUnitPrice = value end,
			width = "full",
		},
		[4] = {
			type = "checkbox",
			name = "Disable scrolling animation",
			getFunc = function() return BUI.settings.scrollingDisable end,
			setFunc = function(value) BUI.settings.scrollingDisable = value 
									BUI.GuildStore.DisableAnimations(value) end,
			width = "full",
		},
		-- [5] = {
		-- 	type = "checkbox",
		-- 	name = "Condense listing view",
		-- 	tooltip = "Allows more items to be seen at once whilst browsing",
		-- 	getFunc = function() return BUI.settings.condensedListings end,
		-- 	setFunc = function(value) BUI.settings.condensedListings = value 
		-- 							ReloadUI() end,
		-- 	width = "full",
		-- 	warning="Reloads the UI for the change to propagate"
		-- },
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.GuildStore.Setup()

	Init("GS", "Guild Store")
	BUI.settings.condensedListings = false -- force backward compatibility with versions < 1.0
	BUI.GuildStore.SetupCustomResults()
	BUI.GuildStore.SetupMM()
end