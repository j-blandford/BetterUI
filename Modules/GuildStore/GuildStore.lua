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
local MIN_POSTING_AMOUNT = 1
local CLAMP_VALUES = true
local SEARCH_CRITERIA_CHANGED = true

local DONT_SELECT_ITEM = false
local IGNORE_CALLBACK = true
local IGNORE_CALL_BACK = true

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

local GUILDSTORE_LEFT_TOOL_TIP_REFRESH_DELAY_MS = 300


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
    local currentBestCategoryName
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

            local currentItemType = GetItemLinkItemType(itemData)
            local isRecipeAndUnknown = false
            if (currentItemType == ITEMTYPE_RECIPE) then
                isRecipeAndUnknown = not IsItemLinkRecipeKnown(itemData)
            end
            
            if(hasEnchantment) then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
            if(setItem) then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
            if isRecipeAndUnknown then labelTxt = labelTxt.." |t16:16:/esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_provisioning.dds|t" end
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
	    local dealValue = tonumber(dealString)

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

-- Flip A (Sort) and X (Select)
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

function BUI.GuildStore.BrowseResults:RefreshFooter()
    BUI.GenericFooter.Refresh(self)
end

function BUI.GuildStore.BrowseResults:InitializeFooter()
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

function BUI.GuildStore.BrowseResults:BuildList()
	local numNonGuildItems = self.numItemsOnPage
	
	--[[
		According to design, we need to add in guild specific items if the category filter is ALL_ITEMS
		Guild specific items are different than items that are returned from a normal search query because they are not stored on the server and retrieved via the TradingHouseManager
		Instead guild specific items are created in lua when specifically requested. A problem arises because search queries are returned to the client page by page and pre-sorted.
		In order to insert the guild specific items in the correct sorted place, without knowing the full contents of the sorted list (it could be hundreds, even thousands, of items long),
		we have to check entries as they are added to the list using a sort comparator and specifically insert in these guild items where needed, on a page by page basis
	--]]
	local displayGuildItems = not TRADING_HOUSE_GAMEPAD:GetSearchActiveFilter() -- TRADING_HOUSE_GAMEPAD:GetSearchActiveFilter() returns nil when the category filter combo box is set to ALL_ITEMS
	if displayGuildItems then
		local DONT_IGNORE_FILTERING = false
		local CACHE_GUILD_ITEMS = true
		self:AddGuildSpecificItemsToList(DONT_IGNORE_FILTERING, CACHE_GUILD_ITEMS) -- cache guild specific items in a table that will be removed from during the add entry block below
	end
	
	for i = 1, numNonGuildItems do
		local itemData = ZO_TradingHouse_CreateItemData(i, GetTradingHouseSearchResultItemInfo)
		
		if itemData then
			itemData.itemLink = GetTradingHouseSearchResultItemLink(itemData.slotIndex)
			self:FormatItemDataFields(itemData)
			
			if displayGuildItems then
				-- Check the cached guild specific items to see if any items should be inserted between the current item and the last item added.
				self:InsertCachedGuildSpecificItemsForSortPosition(self.cachedLastItemData, itemData)
				self.cachedLastItemData = itemData
			end
			
			self:AddEntryToList(itemData)
		end
	end
	
	if displayGuildItems and not self.hasMorePages then
		self:InsertCachedGuildSpecificItemsForSortPosition(self.cachedLastItemData, nil) -- Check one last time to see if any guild specific items should be at the end of the list
	end
	
	if (self.listResultCount == 0) then
		if (self.nextPageCallLater ~= nil) then
			EVENT_MANAGER:UnregisterForUpdate(self.nextPageCallLater)
		end
		
		if (self.hasMorePages) then
			self.innerCallLaterIdIsSet = false
			local nextCallLaterId = zo_callLater(function()
				if GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.hasMorePages and GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:HasNoCooldown() and not GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.control:IsHidden() then
					TRADING_HOUSE_GAMEPAD:SearchNextPage()
				else
					local nextCallLaterId = zo_callLater(function()
						if GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.hasMorePages and GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:HasNoCooldown() and not GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.control:IsHidden() then
							TRADING_HOUSE_GAMEPAD:SearchNextPage()
						end
					end, GetTradingHouseCooldownRemaining() + 250)
					self.nextPageCallLater = "NextPageCallLater"..nextCallLaterId
					self.innerCallLaterIdIsSet = true
				end
			end, GetTradingHouseCooldownRemaining() + 100)
		
			if (not self.innerCallLaterIdIsSet) then
				self.nextPageCallLater = "NextPageCallLater"..nextCallLaterId
			end
			
		end
	
	end
	
	self.listResultCount = 0
end

function BUI.GuildStore.BrowseResults:InitializeList()
    self.itemList = BUI_VerticalItemParametricScrollList:New(self.control:GetNamedChild("List")) -- replace the itemList with my own generic one (with better gradient size, etc.)

    self:GetList():AddDataTemplate("BUI_BrowseResults_Row", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local BROWSE_RESULTS_ITEM_HEIGHT = 30
	
	self.listResultCount = 0

    self:GetList():SetAlignToScreenCenter(true, BROWSE_RESULTS_ITEM_HEIGHT)
    self:GetList():SetNoItemText(GetString(SI_DISPLAY_GUILD_STORE_NO_ITEMS))
    self:GetList():SetOnSelectedDataChangedCallback(
        function(list, selectedData)
			if self.callLaterLeftToolTip ~= nil then
				EVENT_MANAGER:UnregisterForUpdate(self.callLaterLeftToolTip)
			end
	
			local callLaterId = zo_callLater(function() self:LayoutTooltips(selectedData) end, GUILDSTORE_LEFT_TOOL_TIP_REFRESH_DELAY_MS)
			self.callLaterLeftToolTip = "CallLaterFunction"..callLaterId
		
            --self:LayoutTooltips(selectedData)
			
			--self.listResultCount = 0
        end
    )
end

function BUI.GuildStore.BrowseResults:AddEntryToList(itemData)
    if(itemData) then
        -- filter by name logic
        if(self.textFilter ~= nil) then
            if(string.find(string.lower(itemData.name), self.textFilter, 1, true) == nil ) then
                return
            end
        end
		if(self.recipeUnknownFilter ~= nil) then
			local currentItemType = GetItemLinkItemType(itemData.itemLink)
            local isRecipeAndUnknown = false
            if (currentItemType == ITEMTYPE_RECIPE) then
                isRecipeAndUnknown = not IsItemLinkRecipeKnown(itemData.itemLink)

				if (self.recipeUnknownFilter == 2 and not isRecipeAndUnknown) or (self.recipeUnknownFilter == 3 and isRecipeAndUnknown) then
                	return
            	end
            end
        end
        ---------------------------
	
		self.listResultCount = self.listResultCount + 1
	
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

function BUI.GuildStore.Listings:InitializeList()
    self.itemList = BUI_VerticalItemParametricScrollList:New(self.control:GetNamedChild("List")) -- replace the itemList with my own generic one (with better gradient size, etc.)
    self:GetList():AddDataTemplate("BUI_Listings_Row", SetupListing, ZO_GamepadMenuEntryTemplateParametricListFunction)

    local LISTINGS_ITEM_HEIGHT = 30
    self:GetList():SetAlignToScreenCenter(true, LISTINGS_ITEM_HEIGHT)
    self:GetList():SetNoItemText(GetString(SI_GAMEPAD_TRADING_HOUSE_NO_LISTINGS))
    self:GetList():SetOnSelectedDataChangedCallback(
        function(list, selectedData)
			GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
			if self.callLaterLeftToolTip ~= nil then
				EVENT_MANAGER:UnregisterForUpdate(self.callLaterLeftToolTip)
			end
	
			local callLaterId = zo_callLater(function() self:UpdateItemSelectedTooltip(selectedData) end, GUILDSTORE_LEFT_TOOL_TIP_REFRESH_DELAY_MS)
			self.callLaterLeftToolTip = "CallLaterFunction"..callLaterId
            
			--self:UpdateItemSelectedTooltip(selectedData)
        end
    )
end

function BUI.GuildStore.Listings:BuildList()
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
        if (mmData.avgPrice ~= nil) then
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

function BUI.GuildStore.Sell:InitializeList()
    local function OnSelectionChanged(list, selectedData, oldSelectedData)
		if self.callLaterLeftToolTip ~= nil then
			EVENT_MANAGER:UnregisterForUpdate(self.callLaterLeftToolTip)
		end
	
		local callLaterId = zo_callLater(function() self:OnSelectionChanged(list, selectedData, oldSelectedData) end, GUILDSTORE_LEFT_TOOL_TIP_REFRESH_DELAY_MS)
		self.callLaterLeftToolTip = "CallLaterFunction"..callLaterId
    end

    local USE_TRIGGERS = true
    local SORT_FUNCTION = nil
    local CATEGORIZATION_FUNCTION = nil
    local ENTRY_SETUP_CALLBACK = nil
    local LISTINGS_ITEM_HEIGHT = 30

    self.messageControl = self.control:GetNamedChild("StatusMessage")
    self.itemList = BUI_GamepadInventoryList:New(self.listControl, BAG_BACKPACK, SLOT_TYPE_ITEM, OnSelectionChanged, ENTRY_SETUP_CALLBACK,
                                                    CATEGORIZATION_FUNCTION, SORT_FUNCTION, USE_TRIGGERS, "BUI_Sell_Row", SetupSellListing)
    self.itemList:SetItemFilterFunction(function(slot) local isBound = IsItemBound(slot.bagId, slot.slotIndex)
                                                    return slot.quality ~= ITEM_QUALITY_TRASH and not slot.stolen and not isBound end)

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
    
    return false
end

ZO_TRADING_HOUSE_YES_OR_NO_ANY =
{
	{ 1, nil, SI_GAMEPAD_SELECT_OPTION },
	{ 2, nil, SI_YES },
	{ 3, nil, SI_NO },
}

function BUI.GuildStore.Browse:PopulateUnknownRecipesDropDown(dropDown)
	dropDown:ClearItems()
	dropDown:SetSortsItems(false)
	
	--ZO_TradingHouse_InitializeColoredComboBox(dropDown, ZO_TRADING_HOUSE_YES_OR_NO_ANY, self.UpdateCheckboxFilter, INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, nil, DONT_SELECT_ITEM)
	
	for _, data in ipairs(ZO_TRADING_HOUSE_YES_OR_NO_ANY) do
		local entry = dropDown:CreateItemEntry(GetString(data[ZO_RANGE_COMBO_INDEX_TEXT]), self.UpdateCheckboxFilter)
		entry.value = data[ZO_RANGE_COMBO_INDEX_MIN_VALUE]
		
		dropDown:AddItem(entry)
	end
	
	if self.lastRecipeUnknownFilterEntryName then
		dropDown:SelectItemByIndex(self.lastRecipeUnknownFilter, IGNORE_CALLBACK)
		
		dropDown:SetHighlightedItem(self.lastRecipeUnknownFilter)
	else
		dropDown:SelectFirstItem()
	end
end

function BUI.GuildStore.Browse:SetupUnknownRecipesFilterDropDown(control, data, selected, reselectingDuringRebuild, enabled, active)
	ZO_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
	--control:SetAlpha(ZO_GamepadMenuEntryTemplate_GetAlpha(selected, data.disabled))
	
	local dropdown = ZO_ComboBox_ObjectFromContainer(control:GetNamedChild("Dropdown"))
	
	dropdown:SetDeactivatedCallback(function() self:UnfocusDropDown() end)
	
	--Initialize?
	dropdown:SetSortsItems(false)
	--dropdown:SelectFirstItem()
	local DONT_RESELECT = false
	dropdown:SetHighlightedItem(1, DONT_RESELECT)
	
	--data.initCallback(dropdown)
	
	self.unknownRecipesDropDown = dropdown
	
	self:PopulateUnknownRecipesDropDown(dropdown)
	
	data.dropDown = dropdown
end

function BUI.GuildStore.Browse.PerformDeferredInitialization(self)
    if(self.deferred_init) then return end

	self.UpdateCheckboxFilter = function(comboBox, entryName, entry)
		local selectionChanged = self.lastRecipeUnknownFilterEntryName ~= entryName
		if self.lastRecipeUnknownFilterEntryName then
			self.lastRecipeUnknownFilter = self.unknownRecipesDropDown:GetHighlightedIndex()
		end
		
		self.lastRecipeUnknownFilterEntryName = entryName
		self.recipeUnknownFilter = entry.value
		ZO_TradingHouse_ComboBoxSelectionChanged(comboBox, entryName, entry, selectionChanged)
		
		self.unknownRecipesDropDown:SetSelectedItemText(entryName)
		
		--if selectionChanged then
			--self:UpdateLevelSlidersMinMax()
		--	self.itemList:RefreshVisible()
		--end
		
		--return selectionChanged
	end

	self.lastRecipeUnknownFilter = 1
	self.lastRecipeUnknownFilterEntryName = nil
	
	--self:ConfigureCraftingFilterTypes()
    
    self.itemList:AddDataTemplateWithHeader("ZO_GamepadGuildStoreComboUnknownRecipes", function(...) self:SetupUnknownRecipesFilterDropDown(...) end, ZO_GamepadMenuEntryTemplateParametricListFunction, nil, "ZO_GamepadGuildStoreBrowseHeaderTemplate")
--    self.itemList:AddDataTemplate("BUI_BrowseFilterCheckboxTemplate", function(...) self:SetupCheckboxFilter(...) end)
	self.itemList:AddDataTemplate("BUI_BrowseFilterEditboxTemplate", function(...) self:SetupNameFilter(...) end)
    self.deferred_init = true
end

function BUI.GuildStore.Browse:ResetList(filters, dontReselect)
    self.itemList:Clear()

    -- Category
    self:AddDropDownEntry("GuildStoreBrowseCategory", CATEGORY_DROP_DOWN_MODE)
    self:InitializeFilterData(filters)

	--local recipeUnknownFilter = ZO_GamepadEntryData:New("Unknown Recipes")
    --self.itemList:AddEntry("BUI_BrowseFilterCheckboxTemplate", recipeUnknownFilter)
    
    --self:AddDropDownEntry("BUI_BrowseFilterCheckboxTemplate", 5)

    local dropDownData = ZO_GamepadEntryData:New("Unknown Recipes")
    dropDownData.dropDownMode = 5
    dropDownData:SetHeader("Unknown Recipes")
    self.itemList:AddEntryWithHeader("ZO_GamepadGuildStoreComboUnknownRecipes", dropDownData)
    
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
	GAMEPAD_TRADING_HOUSE_BROWSE.SetupUnknownRecipesFilterDropDown = BUI.GuildStore.Browse.SetupUnknownRecipesFilterDropDown
	GAMEPAD_TRADING_HOUSE_BROWSE.PopulateUnknownRecipesDropDown = BUI.GuildStore.Browse.PopulateUnknownRecipesDropDown
	--GAMEPAD_TRADING_HOUSE_BROWSE.SetupCheckboxFilter = BUI.GuildStore.Browse.SetupCheckboxFilter
	--GAMEPAD_TRADING_HOUSE_BROWSE.UpdateCheckboxFilter = BUI.GuildStore.Browse.UpdateCheckboxFilter
    GAMEPAD_TRADING_HOUSE_BROWSE.SetupNameFilter = BUI.GuildStore.Browse.SetupNameFilter
    GAMEPAD_TRADING_HOUSE_BROWSE.UpdateNameFilter = BUI.GuildStore.Browse.UpdateNameFilter
    GAMEPAD_TRADING_HOUSE_BROWSE.ResetList = BUI.GuildStore.Browse.ResetList
	GAMEPAD_TRADING_HOUSE_BROWSE.ConfigureCraftingFilterTypes = BUI.GuildStore.Browse.ConfigureCraftingFilterTypes
	
	--GAMEPAD_TRADING_HOUSE_BROWSE.unknownRecipesDropDown = BUI.GuildStore.Browse.unknownRecipesDropDown
	--GAMEPAD_TRADING_HOUSE_BROWSE.lastRecipeUnknownFilter = BUI.GuildStore.Browse.lastRecipeUnknownFilter
	--GAMEPAD_TRADING_HOUSE_BROWSE.lastRecipeUnknownFilterEntryName = BUI.GuildStore.Browse.lastRecipeUnknownFilterEntryName
	
    BUI.PostHook(GAMEPAD_TRADING_HOUSE_BROWSE, 'PerformDeferredInitialization', function(self)
        BUI.GuildStore.Browse.PerformDeferredInitialization(self)
        self:ResetList()
    end)

	-- Lets overwrite some functions so that they work with our new custom TLC
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.PopulateTabList = BUI.GuildStore.BrowseResults.PopulateTabList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.AddEntryToList = BUI.GuildStore.BrowseResults.AddEntryToList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.InitializeList = BUI.GuildStore.BrowseResults.InitializeList
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.RefreshFooter = BUI.GuildStore.BrowseResults.RefreshFooter
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.InitializeFooter = BUI.GuildStore.BrowseResults.InitializeFooter
	--GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.Initialize = BUI.GuildStore.BrowseResults.Initialize
	
	--EVENT_MANAGER:RegisterForEvent("BUI_OnSearchResultsReceived",
	--	EVENT_TRADING_HOUSE_SEARCH_RESULTS_RECEIVED,
	--	function(...) BUI.GuildStore.BrowseResults:OnSearchResultsReceived(...) end)

	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:InitializeList()
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:InitializeFooter()
	--GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:PopulateTabList()

	-- Now we have to hide the header in this new guild store interface
	GAMEPAD_TRADING_HOUSE_BROWSE.OnHiding = function(self)
		if self.dropDown then
	        self.dropDown:Deactivate()
	    end
	    self:UnfocusPriceSelector()
		
        GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.recipeUnknownFilter = self.recipeUnknownFilter
        GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.textFilter = string.lower(self.nameFilter)
		TRADING_HOUSE_GAMEPAD.m_header:SetHidden(true) -- here's the change
		BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)

        if wykkydsToolbar then
            wykkydsToolbar:SetHidden(false)
		end
	end

	GAMEPAD_TRADING_HOUSE_BROWSE.OnShowing = function(self)
		self:PerformDeferredInitialization()
    	self:OnTargetChanged(self.itemList, self.itemList:GetTargetData())

		TRADING_HOUSE_GAMEPAD.m_header:SetHidden(false) -- here's the change
		BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)

        if wykkydsToolbar then
            wykkydsToolbar:SetHidden(true)
		end
	end

	-- Replace the fragment with my own TLC to bind everything together...
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT = ZO_FadeSceneFragment:New(BUI_BrowseResults)
    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS:SetFragment(GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS_FRAGMENT)

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.OnShowing = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(true)
	    end
	
	    --GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.keybindStripDescriptor[1]["keybind"] = "UI_SHORTCUT_SECONDARY"
	    --GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.keybindStripDescriptor[2]["keybind"] = "UI_SHORTCUT_PRIMARY"
    end

    GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.OnHiding = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(false)
        end
    end

    --TRADING_HOUSE_CREATE_LISTING_GAMEPAD.OnHiding = 
    TRADING_HOUSE_CREATE_LISTING_GAMEPAD.Hiding = function(self)
        self:UnfocusPriceSelector()
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)

		GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
		BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
		if self.callLaterLeftToolTip ~= nil then
			EVENT_MANAGER:UnregisterForUpdate(self.callLaterLeftToolTip)
			self.callLaterLeftToolTip = nil
		end
		
		--local callLaterId = zo_callLater(function() self:UpdateItemSelectedTooltip(selectedData) end, GUILDSTORE_LEFT_TOOL_TIP_REFRESH_DELAY_MS)
		--self.callLaterLeftToolTip = "CallLaterFunction"..callLaterId
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

            if wykkydsToolbar then
                wykkydsToolbar:SetHidden(true)
            end
        elseif newState == SCENE_SHOWN then
            if self.m_currentObject then
                self.m_currentObject:Show()
            end

            --if wykkydsToolbar then
            --    wykkydsToolbar:SetHidden(true)
            --end
        elseif newState == SCENE_HIDING then
            BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)

            if wykkydsToolbar then
                wykkydsToolbar:SetHidden(false)
            end
        elseif newState == SCENE_HIDDEN then
            self:UnregisterForSceneEvents()
            BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TRADING_HOUSE_FRAGMENT:Hide()
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)

            ZO_GamepadGenericHeader_Deactivate(self.m_header)

            if self.m_currentObject then
                self.m_currentObject:Hide()
            end

            --if wykkydsToolbar then
            --    wykkydsToolbar:SetHidden(false)
            --end
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

    GAMEPAD_TRADING_HOUSE_LISTINGS.OnShowing = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(true)
        end
    end

    GAMEPAD_TRADING_HOUSE_LISTINGS.OnHiding = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(false)
        end
	end
	
	GAMEPAD_TRADING_HOUSE_BROWSE_RESULTS.BuildList = BUI.GuildStore.BrowseResults.BuildList

	-- Now go and override GAMEPAD_TRADING_HOUSE_SELL with our own top level control
	ZO_TradingHouse_Sell_Gamepad_OnInitialize(BUI_Sell)

	GAMEPAD_TRADING_HOUSE_SELL.InitializeList = BUI.GuildStore.Sell.InitializeList
	GAMEPAD_TRADING_HOUSE_SELL:InitializeList()

    GAMEPAD_TRADING_HOUSE_SELL.OnShowing = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(true)
end
    end

    GAMEPAD_TRADING_HOUSE_SELL.OnHiding = function(self)
	    if wykkydsToolbar then
            wykkydsToolbar:SetHidden(false)
        end
    end

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
