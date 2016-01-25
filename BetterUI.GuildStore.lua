local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    local notEnoughMoney = data.purchasePrice > GetCarriedCurrencyAmount(CURT_MONEY)
    ZO_CurrencyControl_SetSimpleCurrency(control.price, CURT_MONEY, data.purchasePrice, ZO_GAMEPAD_CURRENCY_OPTIONS, CURRENCY_SHOW_ALL, notEnoughMoney)
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
        buyingAdviceControl:SetText(margin..'%')

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

function BUI.GuildStore.SetupCustomResults()

	-- overwrite old results scrolllist data type and replace:
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().dataTypes["ZO_TradingHouse_ItemListRow_Gamepad"]=nil
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().dataTypes["NewUI_ItemListRow_Gamepad"] = {
            pool = ZO_ControlPool:New("NewUI_ItemListRow_Gamepad", GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:GetList().scrollControl, "NewUI_ItemListRow_Gamepad"),
            setupFunction = SetupListing,
            parametricFunction = ZO_GamepadMenuEntryTemplateParametricListFunction,
            equalityFunction = function(l,r) return l == r end,
            hasHeader = false,
        }

    -- overwrite old results add entry function to use the new scrolllist datatype:
	BUI.Hook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "AddEntryToList", function(self, itemData) 
		self.footer.pageNumberLabel:SetHidden(false)
        self.footer.pageNumberLabel:SetText(zo_strformat("<<1>>", self.currentPage + 1)) -- Pages start at 0, offset by 1 for expected display number
        if(itemData) then
	        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
	        entry:InitializeTradingHouseVisualData(itemData)
	        self:GetList():AddEntry("NewUI_ItemListRow_Gamepad", 
	                                entry, 
	                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
	                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
	                                SCROLL_LIST_SELECTED_OFFSET_VALUE, 
	                                SCROLL_LIST_SELECTED_OFFSET_VALUE)
    	end
	end, true)
end
