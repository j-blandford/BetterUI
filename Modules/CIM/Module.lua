local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "CIM")

	local optionsTable = {
		{
			type = "header",
			name = "Enhanced Interface Global Behaviour",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Enable \"Junk\" feature",
			tooltip = "Allows items to be marked as \"junk\" as a filter to de-clutter the inventory",
			getFunc = function() return BUI.settings.CIM.enableJunk end,
			setFunc = function(value) BUI.settings.CIM.enableJunk = value end,
			width = "full",
		},   
        {
            type = "editbox",
            name = "Number of lines to skip on trigger",
            tooltip = "Change how quickly the menu skips when pressing the triggers.",
            getFunc = function() return BUI.settings.CIM.triggerSpeed end,
            setFunc = function(value) BUI.settings.CIM.triggerSpeed = value end,
            width = "full",
        },  
		{
			type = "header",
			name = "Enhanced Interface Global Display",
			width = "full",
		},
        -- {
        --     type = "slider",
        --     name = "Inventory global Scale",
        --     tooltip = "Alters the inventory's scale. |cFF6600This is *independent* of the global UI scale!!|r",
        --     min = 0.25,
        --     max = 2,
        --     step = 0.25,
        --     default = 1,
        --     decimals = 2,
        --     getFunc = function() return BUI.settings.Inventory.uiScale end,
        --     setFunc = function(value) BUI.settings.Inventory.uiScale = value end,
        --     width = "full",
        -- },
		{
			type = "checkbox",
			name = "Display attribute icons next to the item name",
			tooltip = "Allows you to see enchanted, set and stolen items quickly",
			getFunc = function() return BUI.settings.CIM.attributeIcons end,
			setFunc = function(value) BUI.settings.CIM.attributeIcons = value end,
			width = "full",
		},
        {
            type = "checkbox",
            name = "Reduce the font size of the item tooltip",
            tooltip = "Allows much more item information to be displayed at once on the tooltips",
            getFunc = function() return BUI.settings.CIM.condenseLTooltip end,
            setFunc = function(value) BUI.settings.CIM.condenseLTooltip = value
                                        ReloadUI() end,
            width = "full",
            warning="Reloads the UI for the change to propagate"
        },

	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end


function BUI.Lib.CIM.Setup()
	Init("CIM", "CIM")

end