-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Local variable definitions; de-clutters the global namespace!
--
-------------------------------------------------------------------------------------------------------------------------------------------------------
local CATEGORY_DROP_DOWN_MODE = 1
local QUALITY_DROP_DOWN_MODE = 2
local FILTER_DROP_DOWN_MODE = 3
local LEVEL_DROP_DOWN_MODE = 4

local MIN_PRICE_SELECTOR_MODE = 1
local MAX_PRICE_SELECTOR_MODE = 2

local MIN_LEVEL_SLIDER_MODE = 1
local MAX_LEVEL_SLIDER_MODE = 2

local MINIMUM_PLAYER_LEVEL = 0
local MINIMUM_VETERAN_RANK = 1
local LEVEL_TYPES = 
{
    { TRADING_HOUSE_FILTER_TYPE_LEVEL, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_PLAYER_LEVEL },
    { TRADING_HOUSE_FILTER_TYPE_VETERAN_LEVEL, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_VETEAN_LEVEL },
    { TRADING_HOUSE_FILTER_TYPE_ALL_LEVEL, nil, SI_GAMEPAD_TRADING_HOUSE_BROWSE_ALL_LEVEL },
}

local QUALITY_COLOR_INDEX = 1
local LIST_ITEM_HEIGHT = 120
local DONT_SELECT_ITEM = false
local IGNORE_CALL_BACK = true
local MIN_POSTING_AMOUNT = 1
local CLAMP_VALUES = true
local SEARCH_CRITERIA_CHANGED = true

local SCROLL_LIST_HEADER_OFFSET_VALUE = 0
local SCROLL_LIST_SELECTED_OFFSET_VALUE = 0
local HALF_ALPHA = 0.5
local FULL_ALPHA = 1
local FIRST_PAGE = 0
local NO_MORE_PAGES = false
local NO_ITEMS_ON_PAGE = 0
local SORT_OPTIONS = {
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_TIME] = TRADING_HOUSE_SORT_EXPIRY_TIME,
    [ZO_GamepadTradingHouse_SortableItemList.SORT_KEY_PRICE] = TRADING_HOUSE_SORT_SALE_PRICE,
}


-- We need to take a subclass of ZO_GamepadInventoryList to alter the "Sell" page's gradient fade background
BUI_GamepadInventoryList = ZO_GamepadInventoryList:Subclass()

function BUI_GamepadInventoryList:RefreshList()

    self.list.scrollControl:SetFadeGradient(1, 0, 1, 5)
    self.list.scrollControl:SetFadeGradient(2, 0, -1, 5)

    if self.control:IsHidden() then
        self.isDirty = true
        return
    end
    self.isDirty = false
    self.list:Clear()
    self.dataBySlotIndex = {}
    local slots = self:GenerateSlotTable()
    local currentBestCategoryName = nil
    for i, itemData in ipairs(slots) do
        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        self:SetupItemEntry(entry, itemData)
        self.list:AddEntry(self.template, entry)
        self.dataBySlotIndex[itemData.slotIndex] = entry
    end
    self.list:Commit()
end


-- Pretty much identical to whats in [Enhanced Inventory], just without the stolen icons
local function BUI_SharedGamepadEntryLabelSetup(label, stackLabel, data, selected)
    if label then
        label:SetFont("$(GAMEPAD_MEDIUM_FONT)|28|soft-shadow-thick")

        local labelTxt = data.text

        if(BUI.Settings.Modules["CIM"].attributeIcons) then
            local itemData = data.dataSource.itemLink

            local setItem, _, _, _, _ = GetItemLinkSetInfo(itemData, false)
            local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemData)
            
            if(hasEnchantment) then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
            if(setItem) then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
        end

        label:SetText(labelTxt)

        local labelColor = data:GetNameColor(selected)
        if type(labelColor) == "function" then
            labelColor = labelColor(data)
        end
        label:SetColor(labelColor:UnpackRGBA())
        if ZO_ItemSlot_SetupTextUsableAndLockedColor then
            ZO_ItemSlot_SetupTextUsableAndLockedColor(label, data.meetsUsageRequirements)
        end
    end
end



-- Templated from ZOS, local functions (in gamepadinventory.lua) need to be defined within this scope to be called! --------------------------------------
local function BUI_SharedGamepadEntryIconSetup(icon, stackCountLabel, data, selected)
    if icon then
        if data.iconUpdateFn then
            data.iconUpdateFn()
        end
    
        local numIcons = data:GetNumIcons()
        icon:SetMaxAlpha(data.maxIconAlpha)
        icon:ClearIcons()
        if numIcons > 0 then
            for i = 1, numIcons do
                local iconTexture = data:GetIcon(i, selected)
                icon:AddIcon(iconTexture)
            end
            icon:Show()
            if data.iconDesaturation then
                icon:SetDesaturation(data.iconDesaturation)
            end
            local r, g, b = 1, 1, 1
            if data.enabled then
                if selected and data.selectedIconTint then
                    r, g, b = data.selectedIconTint:UnpackRGBA()
                elseif (not selected) and data.unselectedIconTint then
                    r, g, b = data.unselectedIconTint:UnpackRGBA()
                end
            else
                if selected and data.selectedIconDisabledTint then
                    r, g, b = data.selectedIconDisabledTint:UnpackRGBA()
                elseif (not selected) and data.unselectedIconDisabledTint then
                    r, g, b = data.unselectedIconDisabledTint:UnpackRGBA()
                end
            end
            if data.meetsUsageRequirement == false then
                icon:SetColor(r, 0, 0, icon:GetControlAlpha())
            else 
                icon:SetColor(r, g, b, icon:GetControlAlpha())
            end
        end
    end
end

-- Called for each listing row being added. We have to get lots of information here!
local function SetupListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    BUI_SharedGamepadEntryLabelSetup(control.label, control:GetNamedChild("NumStack"), data, selected)
    BUI_SharedGamepadEntryIconSetup(control.icon, control.stackCountLabel, data, selected)
    if control.highlight then
        if selected and data.highlight then
            control.highlight:SetTexture(data.highlight)
        end
        control.highlight:SetHidden(not selected or not data.highlight)
    end

    if(data.stackCount > 1) then
	    local labelTxt = control.label:GetText()
	    control.label:SetText(zo_strformat("<<1>> |cFFFFFF(<<2>>)|r",labelTxt,data.stackCount))
	end

    local notEnoughMoney = data.purchasePrice > GetCarriedCurrencyAmount(CURT_MONEY)
   

    control:GetNamedChild("Price"):SetText(data.purchasePrice)
    if(notEnoughMoney) then control:GetNamedChild("Price"):SetColor(1,0,0,1) else control:GetNamedChild("Price"):SetColor(1,1,1,1) end 

    local sellerControl = control:GetNamedChild("SellerName")
    local unitPriceControl = control:GetNamedChild("UnitPrice")
    local buyingAdviceControl = control:GetNamedChild("BuyingAdvice")
    local sellerName, dealString, margin

    if(BUI.MMIntegration) then
    	sellerName, dealString, margin = zo_strsplit(';', data.sellerName)
    else
    	sellerName = data.sellerName
   	end

    -- MM integration
    if(BUI.Settings.Modules["GuildStore"].mmIntegration and MasterMerchant ~= nil) then
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
	end

    -- DD integration
	if(ddDataDaedra ~= nil and BUI.Settings.Modules["GuildStore"].ddIntegration) then
		local wAvg
		if(data.dataSource.itemLink ~= nil) then wAvg = ddDataDaedra:GetKeyedItem(data.dataSource.itemLink) else wAvg = ddDataDaedra:GetKeyedItem(GetTradingHouseListingItemLink(data.dataSource.slotIndex)) end
		local unitPrice = data.purchasePrice/data.stackCount
		if(wAvg ~= nil) then
			if(wAvg.wAvg ~= nil) then
				local dealPercent = (wAvg.wAvg/unitPrice)*100-100
				buyingAdviceControl:SetHidden(false)
				buyingAdviceControl:SetText(zo_strformat("<<1>>%",dealPercent))

				if(dealPercent > 25) then
					buyingAdviceControl:SetColor(0, 1, 0, 1)
				elseif(dealPercent < -10) then
					buyingAdviceControl:SetColor(1, 0, 0, 1)
				else
					buyingAdviceControl:SetColor(1, 1, 1, 1)
				end 
			else
				buyingAdviceControl:SetText("0.00%")
				buyingAdviceControl:SetColor(1, 1, 1, 1)
			end
		else
			buyingAdviceControl:SetText("0.00%")
			buyingAdviceControl:SetColor(1, 1, 1, 1)
		end
	end

	sellerControl:SetText(ZO_FormatUserFacingDisplayName(sellerName))

    if(BUI.Settings.Modules["GuildStore"].unitPrice) then
	   	if(data.stackCount ~= 1) then 
	    	unitPriceControl:SetHidden(false)
	    	unitPriceControl:SetText(zo_strformat("@<<1>>",data.purchasePrice/data.stackCount))
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

-- Neuter MasterMerchan't hooks into the interface. This is always called (even without MM integration turned on in the BUI settings) because these functions crash the gamepad
function BUI.GuildStore.FixMM() 
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

-- Flip A (Sort) and X (Select), there's probably a far superior method than this. Things to improve upon!
function BUI.GuildStore.HookResultsKeybinds()
	if BUI.Settings.Modules["GuildStore"].flipGSbuttons then
	    BUI.Hook(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS, "InitializeKeybindStripDescriptors", function(self)
		    local function NotAwaitingResponse() 
		        return not self.awaitingResponse
		    end
		    local function HasNoCoolDownAndNotAwaitingResponse() 
		        return self:HasNoCooldown() and NotAwaitingResponse()
		    end

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

function BUI.GuildStore.BrowseResults.RefreshFooter(self)
    BUI.GenericFooter.Refresh(self)
end

function BUI.GuildStore.BrowseResults.InitializeFooter(self)
    local function RefreshFooter()
        self:RefreshFooter()
    end

    local footerControl = self.control:GetNamedChild("Footer")
	self.footer =
	{
	    control = footerControl,
	    previousButton = footerControl:GetNamedChild("PreviousButton"),
	    nextButton = footerControl:GetNamedChild("NextButton"),
	    pageNumberLabel = footerControl:GetNamedChild("PageNumberText"),
	    GoldLabel = footerControl:GetNamedChild("GoldLabel"),
	    TVLabel = footerControl:GetNamedChild("TVLabel"),
	    CWLabel = footerControl:GetNamedChild("CWLabel"),
	    APLabel = footerControl:GetNamedChild("APLabel"),
	}

    BUI.GenericFooter.Initialize(self)

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshFooter)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshFooter)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, RefreshFooter)
end


function BUI.GuildStore.BrowseResults.InitializeList(self)
    self.itemList = BUI_VerticalItemParametricScrollList:New(self.control:GetNamedChild("List")) -- replace the itemList with my own generic one (with better gradient size, etc.)

    self:GetList():AddDataTemplate("BUI_BrowseResults_Row", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local BROWSE_RESULTS_ITEM_HEIGHT = 30

    self:GetList():SetAlignToScreenCenter(true, BROWSE_RESULTS_ITEM_HEIGHT)
    self:GetList():SetNoItemText(GetString(SI_DISPLAY_GUILD_STORE_NO_ITEMS))
    self:GetList():SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self:LayoutTooltips(selectedData)
        end
    )
end

function BUI.GuildStore.BrowseResults.AddEntryToList(self, itemData)
    if(itemData) then
        -- filter by name logic
        if(self.textFilter ~= nil) then
            if(string.find(string.lower(itemData.name), self.textFilter, 1, true) == nil ) then
                return
            end
        end
        ---------------------------

        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        entry:InitializeTradingHouseVisualData(itemData)
        self:GetList():AddEntry("BUI_BrowseResults_Row", 
                                entry, 
                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                SCROLL_LIST_SELECTED_OFFSET_VALUE, 
                                SCROLL_LIST_SELECTED_OFFSET_VALUE)
    end
end

function BUI.GuildStore.Listings.InitializeList(self)
    self.itemList = BUI_VerticalItemParametricScrollList:New(self.control:GetNamedChild("List")) -- replace the itemList with my own generic one (with better gradient size, etc.)
    self:GetList():AddDataTemplate("BUI_Listings_Row", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)
    local LISTINGS_ITEM_HEIGHT = 30
    self:GetList():SetAlignToScreenCenter(true, LISTINGS_ITEM_HEIGHT)
    self:GetList():SetNoItemText(GetString(SI_GAMEPAD_TRADING_HOUSE_NO_LISTINGS))
    self:GetList():SetOnSelectedDataChangedCallback(
        function(list, selectedData)
            self:UpdateItemSelectedTooltip(selectedData)
        end
    )
end

function BUI.GuildStore.Listings.BuildList(self)
    ddebug("Building List")
    for i = 1, GetNumTradingHouseListings() do
         local itemData = ZO_TradingHouse_CreateItemData(i, GetTradingHouseListingItemInfo)
        if(itemData) then
            itemData.name = zo_strformat(SI_TOOLTIP_ITEM_NAME, itemData.name)
            itemData.price = itemData.purchasePrice
            itemData.time = itemData.timeRemaining
            local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
            entry:InitializeTradingHouseVisualData(itemData)
            self:GetList():AddEntry("BUI_Listings_Row", 
                                    entry, 
                                    SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                    SCROLL_LIST_HEADER_OFFSET_VALUE, 
                                    SCROLL_LIST_SELECTED_OFFSET_VALUE, 
                                    SCROLL_LIST_SELECTED_OFFSET_VALUE)
        end
    end
end

local function GetMarketPrice(itemLink, stackCount)
    if(stackCount == nil) then stackCount = 1 end

    if(BUI.Settings.Modules["GuildStore"].ddIntegration and ddDataDaedra ~= nil) then
        local dData = ddDataDaedra:GetKeyedItem(itemLink)
        if(dData ~= nil) then
            if(dData.wAvg ~= nil) then
                return dData.wAvg*stackCount
            end
        end
    end
    if (BUI.Settings.Modules["GuildStore"].mmIntegration and MasterMerchant ~= nil) then
        local mmData = MasterMerchant:itemStats(itemLink, false)
        if(mmData.avgPrice ~= nil) then
            return mmData.avgPrice*stackCount
        end
    end
    return 0
end

local function SetupSellListing(control, data, selected, selectedDuringRebuild, enabled, activated)
    BUI_SharedGamepadEntryLabelSetup(control.label, control:GetNamedChild("NumStack"), data, selected)
    BUI_SharedGamepadEntryIconSetup(control.icon, control.stackCountLabel, data, selected)

    if control.highlight then
        if selected and data.highlight then
            control.highlight:SetTexture(data.highlight)
        end
        control.highlight:SetHidden(not selected or not data.highlight)
    end
    if(data.stackCount > 1) then
	    local labelTxt = control.label:GetText()
	    control.label:SetText(zo_strformat("<<1>> |cFFFFFF(<<2>>)|r",labelTxt,data.stackCount))
	end
   

    -- control:GetNamedChild("Price"):SetText(data.stackSellPrice)
	-- Replace the "Value" with the market price of the item (in yellow)
    if(BUI.Settings.Modules["Inventory"].showMarketPrice) then
        local marketPrice = GetMarketPrice(GetItemLink(data.dataSource.searchData.bagId, data.dataSource.searchData.slotIndex), data.stackCount)
        if(marketPrice ~= 0) then
            control:GetNamedChild("Price"):SetColor(1,0.75,0,1)
            control:GetNamedChild("Price"):SetText(math.floor(marketPrice))
        else
            control:GetNamedChild("Price"):SetColor(1,1,1,1)
            control:GetNamedChild("Price"):SetText(data.stackSellPrice)
        end
    else
        control:GetNamedChild("Price"):SetColor(1,1,1,1)
        control:GetNamedChild("Price"):SetText(data.stackSellPrice)
    end

    control:GetNamedChild("ItemType"):SetText(string.upper(data.dataSource.bestGamepadItemCategoryName))

    local buyingAdviceControl = control:GetNamedChild("BuyingAdvice")

	local dS = data.dataSource.searchData
    local bagId = dS.bagId
    local slotIndex = dS.slotIndex
    local itemData = GetItemLink(data.dataSource.searchData.bagId, data.dataSource.searchData.slotIndex)
	

	if(ddDataDaedra ~= nil and BUI.Settings.Modules["GuildStore"].ddIntegration) then
		local wAvg = ddDataDaedra:GetKeyedItem(itemData)
		if(wAvg ~= nil) then
			if(wAvg.wAvg ~= nil) then
				buyingAdviceControl:SetText(zo_strformat("<<1>>",wAvg.wAvg*data.stackCount))
			else
				buyingAdviceControl:SetText("0")
			end
		else
			buyingAdviceControl:SetText("0")
		end
	end
end

function BUI.GuildStore.Sell.InitializeList(self)
    local function OnSelectionChanged(...)
        self:OnSelectionChanged(...)
    end
    local USE_TRIGGERS = true
    local SORT_FUNCTION = nil
    local CATEGORIZATION_FUNCTION = nil
    local ENTRY_SETUP_CALLBACK = nil
    self.messageControl = self.control:GetNamedChild("StatusMessage")
    self.itemList = BUI_GamepadInventoryList:New(self.listControl, BAG_BACKPACK, SLOT_TYPE_ITEM, OnSelectionChanged, ENTRY_SETUP_CALLBACK, 
                                                    CATEGORIZATION_FUNCTION, SORT_FUNCTION, USE_TRIGGERS, "BUI_Sell_Row", SetupSellListing)
    self.itemList:SetItemFilterFunction(function(slot) local isBound = IsItemBound(slot.bagId, slot.slotIndex) 
                                                    return slot.quality ~= ITEM_QUALITY_TRASH and not slot.stolen and not isBound end)
    local LISTINGS_ITEM_HEIGHT = 30
    self.itemList:GetParametricList():SetAlignToScreenCenter(true, LISTINGS_ITEM_HEIGHT)

    self.itemList:GetParametricList().maxOffset = 0
    self.itemList:GetParametricList().headerDefaultPadding = 40
    self.itemList:GetParametricList().headerSelectedPadding = 0
    self.itemList:GetParametricList().universalPostPadding = 5
end

function BUI.GuildStore.Browse:UpdateNameFilter(newValue)
    self.lastNameFilter = self.nameFilter
    self.nameFilter = newValue
    ZO_TradingHouse_SearchCriteriaChanged(SEARCH_CRITERIA_CHANGED)
end

function BUI.GuildStore.Browse:SetupNameFilter(control, data, selected, reselectingDuringRebuild, enabled, active)
    local editBox = control

    self.nameFilterBox = control
    self.nameFilterBox.edit:SetHandler("OnTextChanged", function() self:UpdateNameFilter(self.nameFilterBox.edit:GetText()) end)

    self.keybindStripDescriptor[1].callback = function()
                local selectedData = self.itemList:GetSelectedData()
                if selectedData.dropDown then
                    self:FocusDropDown(selectedData.dropDown)
                elseif selectedData.priceSelector then
                    self.priceSelectorMode = selectedData.priceSelectorMode
                    self:FocusPriceSelector(selectedData.priceSelector)
                else
                    self.nameFilterBox.edit:TakeFocus()
                end
            end
    self.keybindStripDescriptor[1].visible = function() 
                local selectedData = self.itemList:GetSelectedData()
                if selectedData then
                    return true
                else
                    return false
                end
            end
end

function BUI.GuildStore.Browse.PerformDeferredInitialization(self)
    if(self.deferred_init) then return end
    self.itemList:AddDataTemplate("BUI_BrowseFilterEditboxTemplate", function(...) self:SetupNameFilter(...) end)
    self.deferred_init = true
end

function BUI.GuildStore.Browse:ResetList(filters, dontReselect)
    self.itemList:Clear()

    -- Category
    self:AddDropDownEntry("GuildStoreBrowseCategory", CATEGORY_DROP_DOWN_MODE)
    self:InitializeFilterData(filters)

    local nameFilter = ZO_GamepadEntryData:New("Name Filter")
    self.itemList:AddEntry("BUI_BrowseFilterEditboxTemplate", nameFilter)

    self:AddPriceSelectorEntry("Min. Price", MIN_PRICE_SELECTOR_MODE)
    self:AddPriceSelectorEntry("Max. Price", MAX_PRICE_SELECTOR_MODE)
    self:AddDropDownEntry("GuildStoreBrowseLevelType", LEVEL_DROP_DOWN_MODE)
    self:AddLevelSelectorEntry("GuildStoreBrowseMinLevel", MIN_LEVEL_SLIDER_MODE)
    self:AddLevelSelectorEntry("GuildStoreBrowseMaxLevel", MAX_LEVEL_SLIDER_MODE)
    self:AddDropDownEntry("GuildStoreBrowseQuality", QUALITY_DROP_DOWN_MODE)

    self.itemList:Commit(dontReselect)
end

function BUI.GuildStore.BrowseResults.Setup()
	-- Now go and override GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS with our own top level control
	ZO_TradingHouse_BrowseResults_Gamepad_OnInitialize(BUI_BrowseResults)

    --/zgoo ZO_TradingHouse_Browse_GamepadList.scrollList
    GAMEPAD_TRADING_HOUSE_BROWSE.SetupNameFilter = BUI.GuildStore.Browse.SetupNameFilter
    GAMEPAD_TRADING_HOUSE_BROWSE.UpdateNameFilter = BUI.GuildStore.Browse.UpdateNameFilter
    GAMEPAD_TRADING_HOUSE_BROWSE.ResetList = BUI.GuildStore.Browse.ResetList

    local orig_funct = GAMEPAD_TRADING_HOUSE_BROWSE.PerformDeferredInitialization
    GAMEPAD_TRADING_HOUSE_BROWSE.PerformDeferredInitialization = function(self) orig_funct(self)
                                                                BUI.GuildStore.Browse.PerformDeferredInitialization(self)
                                                                -- BUI.GuildStore.Browse.ResetList(self) 
                                                            end

	-- Lets overwrite some functions so that they work with our new custom TLC
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.PopulateTabList = BUI.GuildStore.BrowseResults.PopulateTabList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.AddEntryToList = BUI.GuildStore.BrowseResults.AddEntryToList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.InitializeList = BUI.GuildStore.BrowseResults.InitializeList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.RefreshFooter = BUI.GuildStore.BrowseResults.RefreshFooter
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.InitializeFooter = BUI.GuildStore.BrowseResults.InitializeFooter
	--GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.Initialize = BUI.GuildStore.BrowseResults.Initialize

	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:InitializeList()
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:InitializeFooter()
	--GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:PopulateTabList()

	-- Now we have to hide the header in this new guild store interface
	GAMEPAD_TRADING_HOUSE_BROWSE.OnHiding = function(self) 
		if self.dropDown then
	        self.dropDown:Deactivate()
	    end
	    self:UnfocusPriceSelector()

        GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.textFilter = string.lower(self.nameFilter)
		TRADING_HOUSE_GAMEPAD.m_header:SetHidden(true) -- here's the change
		BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
	end

	GAMEPAD_TRADING_HOUSE_BROWSE.OnShowing = function(self) 
		self:PerformDeferredInitialization()
    	self:OnTargetChanged(self.itemList, self.itemList:GetTargetData())
		TRADING_HOUSE_GAMEPAD.m_header:SetHidden(false) -- here's the change
		BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
	end

	-- Replace the fragment with my own TLC to bind everything together...
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT = ZO_FadeSceneFragment:New(BUI_BrowseResults)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:SetFragment(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT)

    TRADING_HOUSE_CREATE_LISTING_GAMEPAD.Hiding = function(self)
        self:UnfocusPriceSelector()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

        BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
    end

    TRADING_HOUSE_GAMEPAD_SCENE:UnregisterAllCallbacks("StateChange")
    TRADING_HOUSE_GAMEPAD_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        local self = TRADING_HOUSE_GAMEPAD
        if newState == SCENE_SHOWING then
               ZO_GamepadGenericHeader_Activate(self.m_header)
               ZO_GamepadGenericHeader_SetActiveTabIndex(self.m_header, self:GetCurrentMode())
               --self.m_header:SetHidden(true)
            self:RefreshHeaderData()
            self:RegisterForSceneEvents()
        elseif newState == SCENE_SHOWN then
            if self.m_currentObject then
                self.m_currentObject:Show()
            end
        elseif newState == SCENE_HIDING then
            BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif newState == SCENE_HIDDEN then
            self:UnregisterForSceneEvents()
            BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TRADING_HOUSE_FRAGMENT:Hide()
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            ZO_GamepadGenericHeader_Deactivate(self.m_header)
            if self.m_currentObject then
                self.m_currentObject:Hide()
            end
          end
     end)

	BUI.GuildStore.HookResultsKeybinds()
	BUI.GuildStore.DisableAnimations(BUI.Settings.Modules["GuildStore"].scrollingDisable)
end

function BUI.GuildStore.Listings.Setup()
	-- Now go and override GAMEPAD_TRADING_HOUSE_LISTINGS with our own top level control
	ZO_TradingHouse_Listings_Gamepad_OnInitialize(BUI_Listings)

    -- Now we can overwrite the Listings panel inside the Guild Store
    GAMEPAD_TRADING_HOUSE_LISTINGS.BuildList = BUI.GuildStore.Listings.BuildList
	GAMEPAD_TRADING_HOUSE_LISTINGS.InitializeList = BUI.GuildStore.Listings.InitializeList

	GAMEPAD_TRADING_HOUSE_LISTINGS:InitializeList()

	-- Now go and override GAMEPAD_TRADING_HOUSE_SELL with our own top level control
	ZO_TradingHouse_Sell_Gamepad_OnInitialize(BUI_Sell)
	GAMEPAD_TRADING_HOUSE_SELL.InitializeList = BUI.GuildStore.Sell.InitializeList

	GAMEPAD_TRADING_HOUSE_SELL:InitializeList()
	
	-- Create Listing (Sell Item)
	-- Automatically fill in the market price if the "replace inventory values with market price" setting is enabled
	local orig_funct = ZO_TradingHouse_CreateListing_Gamepad_BeginCreateListing
    	ZO_TradingHouse_CreateListing_Gamepad_BeginCreateListing = function(selectedData, bag, index, listingPrice)
									if(BUI.Settings.Modules["Inventory"].showMarketPrice) then
										local marketPrice = GetMarketPrice(GetItemLink(bag, index), selectedData.stackCount)
										if(marketPrice ~= 0) then
											orig_funct(selectedData, bag, index, math.floor(marketPrice))
										else
											orig_funct(selectedData, bag, index, listingPrice)
										end
									else
										orig_funct(selectedData, bag, index, listingPrice)
									end
                                                        	end
end
