local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Guild Store Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "|c0066FF[Improved Guild Store]|r Behaviour Settings",
			width = "full",
		},
		{
			type="checkbox",
			name="Flip sort and select buttons (A+X)",
			tooltip="Switches the default A=Sort and X=Select to be A=Select and X=Sort",
			getFunc = function() return BUI.settings.flipGSbuttons end,
			setFunc = function(value) BUI.settings.flipGSbuttons = value
									ReloadUI() end,
			width="full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "Disable scrolling animation",
			getFunc = function() return BUI.settings.scrollingDisable end,
			setFunc = function(value) BUI.settings.scrollingDisable = value 
									BUI.GuildStore.DisableAnimations(value) end,
			width = "full",
		},
		{
			type = "header",
			name = "|c0066FF[Improved Guild Store]|r Display Settings",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Stop guild browse filters resetting",
			tooltip = "Stops the reset of item browse filters between guilds and binds \"Reset Filters\" to Left Stick click",
			getFunc = function() return BUI.settings.GuildStore.saveFilters end,
			setFunc = function(value) BUI.settings.GuildStore.saveFilters = value 
									ReloadUI() end,
			width = "full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "Unit Price in Guild Store",
			tooltip = "Displays a price per unit in guild store listings",
			getFunc = function() return BUI.settings.showUnitPrice end,
			setFunc = function(value) BUI.settings.showUnitPrice = value end,
			width = "full",
		},
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.GuildStore.Setup()

	Init("GS", "Guild Store")
	BUI.settings.condensedListings = false -- force backward compatibility with versions < 1.0
	BUI.GuildStore.SetupCustomResults()
	BUI.GuildStore.SetupMM()

	if(BUI.settings.GuildStore.saveFilters) then

		-- Now set up the "reset filter" button, keybind to the Left Stick Click
		GAMEPAD_TRADING_HOUSE_BROWSE.keybindStripDescriptor[#GAMEPAD_TRADING_HOUSE_BROWSE.keybindStripDescriptor+1] = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = "Reset Filters",
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            callback = function()
            	GAMEPAD_TRADING_HOUSE_BROWSE:ResetFilterValuesToDefaults()
                GAMEPAD_TRADING_HOUSE_BROWSE:ResetList(nil, true)
                GAMEPAD_TRADING_HOUSE_BROWSE:SetLevelSlidersDisabled(false)
            end,
        }

        -- replace the ridiculous "OnInitialInteraction" function which resets the filters with an empty dummy
		GAMEPAD_TRADING_HOUSE_BROWSE.OnInitialInteraction = function() end 
	end
end