local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Guild Store Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "|c0066FF[Enhanced Guild Store]|r Behaviour Settings",
			width = "full",
		},
		{
			type="checkbox",
			name="Flip sort and select buttons (A+X)",
			tooltip="Switches the default A=Sort and X=Select to be A=Select and X=Sort",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].flipGSbuttons end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].flipGSbuttons = value
									ReloadUI() end,
			width="full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "Disable scrolling animation",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].scrollingDisable end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].scrollingDisable = value
									BUI.GuildStore.DisableAnimations(value) end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "MasterMerchant integration",
			tooltip = "Hooks MasterMerchant into the guild store and item tooltips",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].mmIntegration end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].mmIntegration = value
									ReloadUI() end,
			disabled = function() return MasterMerchant == nil end,
			width = "full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "dataDaedra integration",
			tooltip = "Hooks dataDaedra into the guild store and item tooltips",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].ddIntegration end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].ddIntegration = value
									ReloadUI() end,
			disabled = function() return ddDataDaedra == nil end,
			width = "full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "header",
			name = "|c0066FF[Enhanced Guild Store]|r Display Settings",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Stop guild browse filters resetting",
			tooltip = "Stops the reset of item browse filters between guilds and binds \"Reset Filters\" to Left Stick click",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].saveFilters end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].saveFilters = value
									ReloadUI() end,
			width = "full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "Short Currency Format",
			tooltip = "Automatically formats the value column to shorten large numbers and to display the currency with commas.",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].useShortFormat end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].useShortFormat = value
				ReloadUI() end,
			width = "full",
			warning="Reloads the UI for the change to propagate"
		},
		{
			type = "checkbox",
			name = "Unit Price in Guild Store",
			tooltip = "Displays a price per unit in guild store listings",
			getFunc = function() return BUI.Settings.Modules["GuildStore"].unitPrice end,
			setFunc = function(value) BUI.Settings.Modules["GuildStore"].unitPrice = value end,
			width = "full",
		},
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.GuildStore.InitModule(m_options)
	m_options["saveFilters"] = true
	m_options["ddIntegration"] = true
	m_options["mmIntegration"] = true
	m_options["unitPrice"] = true
	m_options["scrollingDisable"] = false
	m_options["flipGSbuttons"] = true
	m_options["useShortFormat"] = true

	return m_options
end

function BUI.GuildStore.Setup()

	Init("GS", "Guild Store")

	BUI.GuildStore.BrowseResults.Setup()
	BUI.GuildStore.Listings.Setup()

	if(BUI.Settings.Modules["GuildStore"].saveFilters) then

		-- Now set up the "reset filter" button, keybind to the Left Stick Click
		GAMEPAD_TRADING_HOUSE_BROWSE.keybindStripDescriptor[#GAMEPAD_TRADING_HOUSE_BROWSE.keybindStripDescriptor+1] = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = "Reset Filters",
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            callback = function()
            	GAMEPAD_TRADING_HOUSE_BROWSE:ResetFilterValuesToDefaults()
                GAMEPAD_TRADING_HOUSE_BROWSE:ResetList(nil, true)
				if (GAMEPAD_TRADING_HOUSE_BROWSE.SetLevelSlidersDisabled) then
                	GAMEPAD_TRADING_HOUSE_BROWSE:SetLevelSlidersDisabled(false)
				end
            end,
        }

        -- replace the ridiculous "OnInitialInteraction" function which resets the filters with an empty dummy
		GAMEPAD_TRADING_HOUSE_BROWSE.OnInitialInteraction = function() end
	end
	
	if (BUI.Settings.Modules["GuildStore"].mmIntegration) then
		-- Remember the listings made in MM
		local exitOnFinished = true
		ESO_Dialogs["TRADING_HOUSE_CONFIRM_SELL_ITEM"] =
		{
			gamepadInfo =
			{
				dialogType = GAMEPAD_DIALOGS.BASIC,
			},
			title =
			{
				text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TITLE,
			},
			mainText =
			{
				text = SI_GAMEPAD_TRADING_HOUSE_CONFIRM_SELL_DIALOG_TEXT,
			},
			setup = function()
				exitOnFinished = false
			end,
			finishedCallback = function(dialog)
				if exitOnFinished then
					SCENE_MANAGER:HideCurrentScene()
				end
			end,
			buttons =
			{
				[1] =
				{
					text =      SI_DIALOG_YES,
					callback =  function(dialog)
						local stackCount = dialog.data.stackCount
						local desiredPrice = dialog.data.price
						local listingIndex = dialog.data.listingIndex
						
						local newSelf = {
							m_pendingItemSlot = listingIndex,
							m_invoiceSellPrice = {
								sellPrice = desiredPrice
							}
						}
						
						if (MasterMerchant ~= nil and MasterMerchant.PostPendingItem ~= nil) then
							MasterMerchant.PostPendingItem(newSelf)
						end
						
						RequestPostItemOnTradingHouse(BAG_BACKPACK, listingIndex, stackCount, desiredPrice)
						TRADING_HOUSE_GAMEPAD:SetSearchAllowed(true) -- allow update to cached search results to find newly sold items
						exitOnFinished = true
					end
				},
				
				[2] =
				{
					text =       SI_DIALOG_NO,
				}
			}
		}
	end

end
