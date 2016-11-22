BUI_STORE_SCENE_NAME = "gamepad_store"

ZO_MODE_STORE_BUY = 1

BUI.Store.Buy = ZOS_GamepadStoreListComponent:Subclass()

function BUI.Store.Buy:New(...)
	local object = ZOS_GamepadStoreListComponent.New(self, ...)
	--object:Initialize(self, ...)
    return object
end

function BUI.Store.Buy:Initialize(scene)
    ZOS_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_BUY, GetString(SI_STORE_MODE_BUY))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
			STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY)
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
	end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_BUY, ZO_MODE_STORE_BUY, "EsoUI/Art/Vendor/vendor_tabIcon_buy_up.dds", fragment, self.keybindStripDescriptor)
end

function BUI.Store.Buy:RegisterEvents()
    local function OnCurrencyChanged()
	    self.list:RefreshVisible()
	end

    local function OnInventoryFullUpdate()
        self.list:UpdateList()
    end

    local function OnInventorySingleSlotUpdate(_, _, _, _, _, updateReason)
        if updateReason == INVENTORY_UPDATE_REASON_DEFAULT then
            self.list:UpdateList()
        end
    end

    local function OnBuySuccess(eventCode, name, type)
        if type == STORE_ENTRY_TYPE_COLLECTIBLE then
            self.list:UpdateList()
        end
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryFullUpdate)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventorySingleSlotUpdate)
    self.control:RegisterForEvent(EVENT_BUY_RECEIPT, OnBuySuccess)
end

function BUI.Store.Buy:UnregisterEvents()
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_ALLIANCE_POINT_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
    self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    self.control:UnregisterForEvent(EVENT_BUY_RECEIPT)
end

function BUI.Store.Buy:InitializeKeybindStrip()
    local repairAllKeybind = STORE_WINDOW_GAMEPAD:GetRepairAllKeybind()

    	-- Buy screen keybind
	self.keybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
		repairAllKeybind
    }

    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmBuy() end,
                                                      GetString(SI_ITEM_ACTION_BUY),
													  nil,
                                                      function() return self:CanBuy() end
												    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor,
													GAME_NAVIGATION_TYPE_BUTTON)

	ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self.list)

	self.confirmKeybindStripDescriptor = {}

	ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
                                                      GAME_NAVIGATION_TYPE_BUTTON,
                                                      function() self:ConfirmBuy() end,
                                                      GetString(SI_ITEM_ACTION_BUY),
													  nil,
                                                      function() return self:CanBuy() end
												    )

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.confirmKeybindStripDescriptor,
													GAME_NAVIGATION_TYPE_BUTTON,
													function() self:UnselectBuyItem() end,
													nil)
end

function BUI.Store.Buy:ConfirmBuy()
    local selectedData = self.list:GetTargetData()
    if self.confirmationMode then
		local quantity = STORE_WINDOW_GAMEPAD:GetSpinnerValue()
		if quantity > 0 then
			BuyStoreItem(selectedData.slotIndex, quantity)
			self:UnselectBuyItem()
		end
	else
		local maxItems = GetStoreEntryMaxBuyable(selectedData.slotIndex)
		if maxItems > 1 then
			self:SelectBuyItem()
            STORE_WINDOW_GAMEPAD:SetupSpinner(zo_max(GetStoreEntryMaxBuyable(selectedData.slotIndex), 1), 1, selectedData.sellPrice, selectedData.currencyType1 or CURT_MONEY)
		elseif maxItems == 1 then
			BuyStoreItem(selectedData.slotIndex, 1)
		end
	end
end

function BUI.Store.Buy:CanBuy()
	local selectedData = self.list:GetTargetData()
    if selectedData then
        if selectedData.entryType == STORE_ENTRY_TYPE_COLLECTIBLE then
            local collectibleId = GetCollectibleIdFromLink(selectedData.itemLink)
            if IsCollectibleUnlocked(collectibleId) then
                return false, GetString("SI_STOREFAILURE", STORE_FAILURE_ALREADY_HAVE_COLLECTIBLE) -- "You already have that collectible"
            end
            return true --Always allow the purchase of collectibles, regardless of bag space
        end
        return STORE_WINDOW_GAMEPAD:CanAffordAndCanCarry(selectedData) -- returns enabled, disabledAlertText
    else
        return false
    end
end

function BUI.Store.Buy:SelectBuyItem()
	self.confirmationMode = true
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.confirmKeybindStripDescriptor)
	STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function BUI.Store.Buy:UnselectBuyItem()
	self.confirmationMode = false
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
	STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
end

function BUI.Store.Buy:AddItems(items, prePaddingOverride, postPaddingOverride)
    local currentBestCategoryName = nil

    for i, itemData in ipairs(items) do
		--itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)

        local nextItemData = items[i + 1]
        local isNextEntryAHeader = nextItemData and nextItemData.bestGamepadItemCategoryName ~= itemData.bestGamepadItemCategoryName
        local postPadding = postPaddingOverride or (isNextEntryAHeader and STORE_ITEM_HEADER_DEFAULT_PADDING)

        local entry = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        entry.data = itemData.data
        if not itemData.ignoreStoreVisualInit then
            entry:InitializeStoreVisualData(itemData)
        end

        if itemData.locked then
            entry.enabled = false
        end

        if itemData.bestGamepadItemCategoryName and itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
            currentBestCategoryName = itemData.bestGamepadItemCategoryName
		end

        self:AddEntry(self.template, entry)

    end

    self:Commit()
end

function BUI.Store.Buy:CreateItemList(scene, storeMode, overrideTemplate, overrideHeaderTemplateSetupFunction)
    local setupFunction = function(...) self:SetupEntry(...) end
    local listName = string.format("StoreMode%d", storeMode)

    local SETUP_LIST_LOCALLY = true
    local list = scene:AddList(listName, SETUP_LIST_LOCALLY)
    self.fragment = scene:GetListFragment(listName)
    ZOS_GamepadStoreList.SetMode(list, storeMode, setupFunction, "BUI_GamepadItemSubEntryTemplate", overrideHeaderTemplateSetupFunction)
    list.AddItems = BUI.Store.Buy.AddItems
    list.UpdateList = ZOS_GamepadStoreList.UpdateList

    list:SetOnSelectedDataChangedCallback(function(list, selectedData)
        if list:IsActive() then
            self:OnSelectedItemChanged(selectedData)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindButton)
        end
    end)

    local OnEffectivelyShown = function()
        list:Activate()
        self:OnSelectedItemChanged(list:GetTargetData())
    end

    local OnEffectivelyHidden = function()
        self:OnExitUnselectItem()
        list:Deactivate()
    end

    list:GetControl():SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    list:GetControl():SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    return list
end

function BUI.Store.Buy:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, forceValid, mode)
    BUI_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:SetHidden(selected and self.confirmationMode)

    -- Default to CURT_MONEY
    local useDefaultCurrency = (not data.currencyType1) or (data.currencyType1 == 0)
    local currencyType = CURT_MONEY

    if not useDefaultCurrency then
        currencyType = data.currencyType1
    end

    self:SetupPrice(control, price, forceValid, mode, currencyType)
end

function BUI.Store.Buy:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)
	local price = self.confirmationMode and selected and data.sellPrice * STORE_WINDOW_GAMEPAD:GetSpinnerValue() or data.sellPrice
	self:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, not ZO_STORE_FORCE_VALID_PRICE, ZO_MODE_STORE_BUY)
end

function BUI.Store.Buy:OnSelectedItemChanged(buyData)
    if buyData then
	    GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
        GAMEPAD_TOOLTIPS:LayoutStoreWindowItem(GAMEPAD_LEFT_TOOLTIP, buyData)
        STORE_WINDOW_GAMEPAD:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor)
    end
end
