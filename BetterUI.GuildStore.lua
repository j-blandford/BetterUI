local function BUI_GamepadMenuEntryTemplate_GetAlpha(selected, disabled)
    if not selected or disabled then
        return .24
    else
        return 1
    end
end

local function BUI_GetListRowName() 
	return BUI.settings.condensedListings and "BUI_ItemListRow_GamepadCondensed" or "BUI_ItemListRow_Gamepad"
end

local function BUI_SetMenuEntryFontFace(label, selected)
    label:SetFont(selected and "ZoFontGamepad27" or "ZoFontGamepad27")
end

local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)

    local notEnoughMoney = data.purchasePrice > GetCarriedCurrencyAmount(CURT_MONEY)
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.purchasePrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnoughMoney)

    if(BUI.settings.condensedListings) then
	    control:SetDimensions(ZO_GAMEPAD_CONTENT_WIDTH, 20)
	    control:SetAlpha(BUI_GamepadMenuEntryTemplate_GetAlpha(selected))
	    BUI_SetMenuEntryFontFace(control.label, selected)
	    control.price:SetFont("ZoFontGamepad27")
	end

    local sellerControl = control:GetNamedChild("SellerName")
    local unitPriceControl = control:GetNamedChild("UnitPrice")
    local buyingAdviceControl = control:GetNamedChild("BuyingAdvice")
    local sellerName, dealString, margin

    if(BUI.MMIntegration) then
    	sellerName, dealString, margin = zo_strsplit(';', data.sellerName)
    else
    	sellerName = data.sellerName
   	end

    if(BUI.settings.showMMPrice and BUI.MMIntegration) then
	    dealValue = tonumber(dealString)

	    local r, g, b = GetInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, dealValue)
        if dealValue == 0 then r = 0.98; g = 0.01; b = 0.01; end

        buyingAdviceControl:SetHidden(false)
        buyingAdviceControl:SetColor(r, g, b, 1)
        if(margin ~= nil) then
        	buyingAdviceControl:SetText(margin..'%')
        else
        	buyingAdviceControl:SetText("0.00%")
        end

   		sellerControl:SetText(ZO_FormatUserFacingDisplayName(sellerName))
	else
		buyingAdviceControl:SetHidden(true)
   		sellerControl:SetText(ZO_FormatUserFacingDisplayName(sellerName))
	end

    if(BUI.settings.showUnitPrice) then
	   	if(data.stackCount ~= 1) then 
	    	unitPriceControl:SetHidden(false)
	    	unitPriceControl:SetText(zo_strformat("@<<1>>|t16:16:EsoUI/Art/currency/currency_gold.dds|t",data.purchasePrice/data.stackCount))
	    else 
	    	unitPriceControl:SetHidden(true)
	    end
    else
    	unitPriceControl:SetHidden(true)
    end

    local timeRemainingControl = control:GetNamedChild("TimeLeft")
    if data.isGuildSpecificItem then
        timeRemainingControl:SetHidden(true)
    else
        timeRemainingControl:SetHidden(false)
        timeRemainingControl:SetText(zo_strformat(SI_TRADING_HOUSE_BROWSE_ITEM_REMAINING_TIME, ZO_FormatTime(data.timeRemaining, TIME_FORMAT_STYLE_SHOW_LARGEST_UNIT_DESCRIPTIVE, TIME_FORMAT_PRECISION_SECONDS, TIME_FORMAT_DIRECTION_DESCENDING)))
    end
end

function BUI.GuildStore.SetupMM() 
  	if MasterMerchant == nil then 
  		BUI.MMIntegration = false
  		return 
  	end
  	MasterMerchant.initBuyingAdvice = function(self, ...) end
  	MasterMerchant.initSellingAdvice = function(self, ...) end
  	MasterMerchant.AddBuyingAdvice = function(rowControl, result) end
  	MasterMerchant.AddSellingAdvice = function(rowControl, result)	end

  	BUI.MMIntegration = true
end

function BUI.GuildStore.HookResultsKeybinds()
	if BUI.settings.flipGSbuttons then
	    BUI.Hook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "InitializeKeybindStripDescriptors", function(self)
		    local function NotAwaitingResponse() 
		        return not self.awaitingResponse
		    end
		    local function HasNoCoolDownAndNotAwaitingResponse() 
		        return self:HasNoCooldown() and NotAwaitingResponse()
		    end
		    d("[BUI] Running new InitializeKeybindStripDescriptors()")

		    self.keybindStripDescriptor = {
		        alignment = KEYBIND_STRIP_ALIGN_LEFT,
		         {
		            name = GetString(SI_GAMEPAD_SORT_OPTION),
		            keybind = "UI_SHORTCUT_SECONDARY",
		            alignment = KEYBIND_STRIP_ALIGN_LEFT,
		            callback = function()
		                TRADING_HOUSE_GAMEPAD:SetSearchPageData(FIRST_PAGE, NO_MORE_PAGES) -- Reset pages for new sort option
		                self:SortBySelected()
		            end,
		            enabled = HasNoCoolDownAndNotAwaitingResponse
		        },
		        {
		            name = GetString(SI_GAMEPAD_SELECT_OPTION),
		            keybind = "UI_SHORTCUT_PRIMARY",
		            alignment = KEYBIND_STRIP_ALIGN_LEFT,
		            callback = function()
		                local postedItem = self:GetList():GetTargetData()
		                self:ShowPurchaseItemConfirmation(postedItem)
		            end,
		            enabled = NotAwaitingResponse
		        },
		        {
		            name = GetString(SI_TRADING_HOUSE_GUILD_LABEL),
		            keybind = "UI_SHORTCUT_TERTIARY",
		            alignment = KEYBIND_STRIP_ALIGN_LEFT,
		            callback = function()
		                self:DisplayChangeGuildDialog()
		            end,
		            visible = function()
		                return GetSelectedTradingHouseGuildId() ~= nil and GetNumTradingHouseGuilds() > 1
		            end,
		            enabled = HasNoCoolDownAndNotAwaitingResponse
		        },
		        {
		            name = function()
		                return zo_strformat(SI_GAMEPAD_TRADING_HOUSE_SORT_TIME_PRICE_TOGGLE, self:GetTextForToggleTimePriceKey())
		            end,
		            keybind = "UI_SHORTCUT_RIGHT_STICK",
		            alignment = KEYBIND_STRIP_ALIGN_LEFT,
		            callback = function()
		                TRADING_HOUSE_GAMEPAD:SetSearchPageData(FIRST_PAGE, NO_MORE_PAGES) -- Reset pages for new sort option
		                self:ToggleSortOptions()
		            end,
		            enabled = HasNoCoolDownAndNotAwaitingResponse
		        },
		        {
		            keybind = "UI_SHORTCUT_LEFT_TRIGGER",
		            ethereal = true,
		            callback = function()
		                self:PreviousPageRequest()
		            end,
		        },
		        {
		            keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
		            ethereal = true,
		            callback = function()
		                self:NextPageRequest()
		            end,
		        },
		    }
		    ZO_Gamepad_AddBackNavigationKeybindDescriptorsWithSound(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, function() self:ShowBrowseFilters() end)
	    end, true)

		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:InitializeKeybindStripDescriptors()
	end
end

function BUI.GuildStore.DisableAnimations(toggleValue)
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().animationEnabled = not toggleValue
end

function BUI.GuildStore.CondenseListings(toggleValue)

	if toggleValue then
		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().dataTypes["BUI_ItemListRow_GamepadCondensed"] = {
	            pool = ZO_ControlPool:New("BUI_ItemListRow_GamepadCondensed", GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().scrollControl, "BUI_ItemListRow_GamepadCondensed"),
	            setupFunction = SetupListing,
	            parametricFunction = ZO_GamepadMenuEntryTemplateParametricListFunction,
	            equalityFunction = function(l,r) return l == r end,
	            hasHeader = false,
	        }

		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().maxOffset=0
		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().universalPostPadding=-25
		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().headerDefaultPadding=0
		GAMEPAD_DEFAULT_POST_PADDING = 0
		GAMEPAD_HEADER_DEFAULT_PADDING=40
		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.footer.control:SetDimensions(390,0)
		ZO_TradingHouse_BrowseResults_GamepadHeaders:SetAnchor(3,ZO_TradingHouse_BrowseResults_Gamepad,3,0,260)
		ZO_TradingHouse_BrowseResults_GamepadListListScreenCenterIsAlongTopListScreenCenter:SetAnchor(128,ZO_TradingHouse_BrowseResults_GamepadListListScreenCenterIsAlongTop,9,0,-30)
	else
		GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().dataTypes["BUI_ItemListRow_Gamepad"] = {
            pool = ZO_ControlPool:New("BUI_ItemListRow_Gamepad", GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().scrollControl, "BUI_ItemListRow_Gamepad"),
            setupFunction = SetupListing,
            parametricFunction = ZO_GamepadMenuEntryTemplateParametricListFunction,
            equalityFunction = function(l,r) return l == r end,
            hasHeader = false,
        }
	end
end

function BUI.GuildStore.SetupCustomResults()

	-- overwrite old results scrolllist data type and replace
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().dataTypes["ZO_TradingHouse_ItemListRow_Gamepad"]=nil

    -- overwrite old results add entry function to use the new scrolllist datatype:
	BUI.Hook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "AddEntryToList", function(self, itemData) 
		self.footer.pageNumberLabel:SetHidden(false)
        self.footer.pageNumberLabel:SetText(zo_strformat("<<1>>", self.currentPage + 1)) -- Pages start at 0, offset by 1 for expected display number
        if(itemData) then
	        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
	        entry:InitializeTradingHouseVisualData(itemData)
	        self:GetList():AddEntry(BUI_GetListRowName(), 
	                                entry, 
	                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
	                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
	                                SCROLL_LIST_SELECTED_OFFSET_VALUE, 
	                                SCROLL_LIST_SELECTED_OFFSET_VALUE)
    	end
	end, true)

	BUI.GuildStore.HookResultsKeybinds()
	BUI.GuildStore.DisableAnimations(BUI.settings.scrollingDisable)
	BUI.GuildStore.CondenseListings(BUI.settings.condensedListings)

end
