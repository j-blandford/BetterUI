BUI.Inventory.List = ZO_GamepadInventoryList:Subclass()

function BUI.Inventory.List:New(...)
    local object = ZO_GamepadInventoryList.New(self, ...)
    return object
end

function BUI.Inventory.List:Initialize(control, inventoryType, slotType, selectedDataCallback, entrySetupCallback, categorizationFunction, sortFunction, useTriggers, template, templateSetupFunction)
    self.control = control
    self.inventoryType = inventoryType
    self.selectedDataCallback = selectedDataCallback
    self.entrySetupCallback = entrySetupCallback
    self.categorizationFunction = categorizationFunction
    self.sortFunction = sortFunction
    self.dataBySlotIndex = {}
    self.isDirty = true
    self.useTriggers = (useTriggers ~= false) -- nil => true
    self.template = template or DEFAULT_TEMPLATE

    local function VendorEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_Inventory_BindSlot(data, slotType, data.slotIndex, data.bagId)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end

    self.list = ZO_GamepadVerticalParametricScrollList:New(self.control)
    self.list:AddDataTemplate(self.template, templateSetupFunction or VendorEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

    -- generate the trigger keybinds so we can add/remove them later when necessary
    self.triggerKeybinds = {}
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.triggerKeybinds, self.list)

    local function SelectionChangedCallback(list, selectedData)
        local selectedControl = list:GetTargetControl()
        if self.selectedDataCallback then
            self.selectedDataCallback(list, selectedData)
        end
        if selectedData then
            GAMEPAD_INVENTORY:PrepareNextClearNewStatus(selectedData)
            self:GetParametricList():RefreshVisible()
        end
    end

    local function OnEffectivelyShown()
        if self.isDirty then
            self:RefreshList()
        elseif self.selectedDataCallback then
            self.selectedDataCallback(self.list, self.list:GetTargetData())
        end
        self:Activate()
    end

    local function OnEffectivelyHidden()
        GAMEPAD_INVENTORY:TryClearNewStatusOnHidden()
        self:Deactivate()
    end

    local function OnInventoryUpdated(bagId)
        if bagId == self.inventoryType then
            self:RefreshList()
        end
    end

    local function OnSingleSlotInventoryUpdate(bagId, slotIndex)
        if bagId == self.inventoryType then
            local entry = self.dataBySlotIndex[slotIndex]
            if entry then
                local itemData = SHARED_INVENTORY:GenerateSingleSlotData(self.inventoryType, slotIndex)
                if itemData then
                    itemData.bestGamepadItemCategoryName = ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription(itemData)
                    self:SetupItemEntry(entry, itemData)
                    self.list:RefreshVisible()
                else -- The item was removed.
                    self:RefreshList()
                end
            else -- The item is new.
                self:RefreshList()
            end
        end
    end

    self:SetOnSelectedDataChangedCallback(SelectionChangedCallback)

    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnSingleSlotInventoryUpdate)
end
