--Gamepad Store Component
---------------------------

ZOS_GamepadStoreComponent = ZO_Object:Subclass()

function ZOS_GamepadStoreComponent:New(...)
    local component = ZO_Object.New(self)
    component:Initialize(...)
    return component
end

function ZOS_GamepadStoreComponent:Initialize(control, storeMode, tabText)
    self.control = control
    self.storeMode = storeMode
    self.tabText = tabText
end

function ZOS_GamepadStoreComponent:Refresh()

end

function ZOS_GamepadStoreComponent:GetTabText()
    return self.tabText
end

function ZOS_GamepadStoreComponent:Show()
    SCENE_MANAGER:AddFragment(self.fragment)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZOS_GamepadStoreComponent:Hide()
    SCENE_MANAGER:RemoveFragment(self.fragment)
    if self.keybindStripDescriptor then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    end
end

function ZOS_GamepadStoreComponent:GetStoreMode()
    return self.storeMode
end

function ZOS_GamepadStoreComponent:GetModeData()
    return self.modeData
end

function ZOS_GamepadStoreComponent:CreateModeData(name, mode, icon, fragment, keybind)
    self.modeData = {
        text = GetString(name),
        mode = mode,
        iconFile = icon,
        fragment = fragment,
        keybind = keybind,
    }
end

--Gamepad Store List Component
----------------------------------

ZO_STORE_FORCE_VALID_PRICE = true

ZOS_GamepadStoreListComponent = ZOS_GamepadStoreComponent:Subclass()

function ZOS_GamepadStoreListComponent:New(...)
    return ZOS_GamepadStoreComponent.New(self, ...)
end

function ZOS_GamepadStoreListComponent:Initialize(scene, storeMode, tabText, overrideTemplate, overrideHeaderTemplateSetupFunction)
    self.list = self:CreateItemList(scene, storeMode, overrideTemplate, overrideHeaderTemplateSetupFunction)
    self.list:UpdateList()
    local control = self.list:GetControl()
    ZOS_GamepadStoreComponent.Initialize(self, control, storeMode, tabText)
end

function ZOS_GamepadStoreListComponent:Refresh()
    self.list:UpdateList()
end

function ZOS_GamepadStoreListComponent:SetupEntry(control, data, selected, selectedDuringRebuild, enabled, activated)

end

function ZOS_GamepadStoreListComponent:SetupStoreItem(control, data, selected, selectedDuringRebuild, enabled, activated, price, forceValid, mode)
    ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    control:SetHidden(selected and self.confirmationMode)

    -- Default to CURT_MONEY
    local useDefaultCurrency = (not data.currencyType1) or (data.currencyType1 == 0)
    local currencyType = CURT_MONEY

    if not useDefaultCurrency then
        currencyType = data.currencyType1
    end

    self:SetupPrice(control, price, forceValid, mode, currencyType)
end

function ZOS_GamepadStoreListComponent:SetupPrice(control, price, forceValid, mode, currencyType)
    local options = self:GetCurrencyOptions()
    local invalidPrice = not forceValid and price > GetCarriedCurrencyAmount(currencyType) or false
    local priceControl = control:GetNamedChild("Price")

    local storeUsesAP, storeUsesTelvarStones = select(2, GetStoreCurrencyTypes())
    if storeUsesAP and mode == ZOS_MODE_STORE_BUY and currencyType == CURT_ALLIANCE_POINTS then
        invalidPrice = not forceValid and price > GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS) or false
    elseif storeUsesTelvarStones and mode == ZOS_MODE_STORE_BUY and currencyType == CURT_TELVAR_STONES then
        invalidPrice = not forceValid and price > GetCarriedCurrencyAmount(CURT_TELVAR_STONES) or false
    end

    --ZO_CurrencyControl_SetSimpleCurrency(priceControl, currencyType, price, options, CURRENCY_SHOW_ALL, invalidPrice)
end

function ZOS_GamepadStoreListComponent:OnSelectedItemChanged(data)

end

function ZOS_GamepadStoreListComponent:CreateItemList(scene, storeMode, overrideTemplate, overrideHeaderTemplateSetupFunction)
    local setupFunction = function(...) self:SetupEntry(...) end
    local listName = string.format("StoreMode%d", storeMode)

    local SETUP_LIST_LOCALLY = true
    local list = scene:AddList(listName, SETUP_LIST_LOCALLY)
    self.fragment = scene:GetListFragment(listName)
    ZOS_GamepadStoreList.SetMode(list, storeMode, setupFunction, overrideTemplate, overrideHeaderTemplateSetupFunction)
    list.AddItems = ZOS_GamepadStoreList.AddItems
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

function ZOS_GamepadStoreListComponent:OnExitUnselectItem()
    if self.confirmationMode then
        self.confirmationMode = false
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.confirmKeybindStripDescriptor)
        STORE_WINDOW_GAMEPAD:SetQuantitySpinnerActive(self.confirmationMode, self.list)
    end
end

function ZOS_GamepadStoreListComponent:GetCurrencyOptions()
    return ZO_GAMEPAD_CURRENCY_OPTIONS
end
