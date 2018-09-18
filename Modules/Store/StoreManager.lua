BUI_STORE_SCENE_NAME = "gamepad_store"

BUI.Store.Class = ZO_GamepadStoreManager:Subclass()

local DONT_ACTIVATE_LIST_ON_SHOW = false


function BUI.Store.Class:New(...)
    return ZO_GamepadStoreManager.New(self, ...)
end

function BUI.Store.Class:RebuildHeaderTabs()
    local function OnCategoryChanged(component)
        if self.activeComponent ~= component then
            self:ShowComponent(component)
        end
    end

    local function OnActivatedChanged(list, activated)
        if activated then
            local component = self.activeComponents[list:GetSelectedIndex()]
            if not self.activeComponent or self.activeComponent ~= component then
                self:ShowComponent(component)
            end
        else
            if not SCENE_MANAGER:IsShowing(self.sceneName) then
                self:HideActiveComponent()
            end
        end
        ZO_GamepadOnDefaultScrollListActivatedChanged(list, activated)
    end

    local tabsTable = {}
    for _, component in ipairs(self.activeComponents) do
        table.insert(tabsTable, {
            text = component:GetTabText(),
            callback = function() OnCategoryChanged(component) end,
        })
    end

    self.headerData =
    {
        tabBarEntries = tabsTable,
        tabBarData = {
                parent = self,
                onNext = function(...) d("LEL") end,
                onPrev = function(...) d("LUL") end
        },
        titleText = function(...) return "LOL" end,
        titleTextAlignment = TEXT_ALIGN_LEFT,
        name = "Buy",
        activatedCallback = function(...) OnActivatedChanged(...) end,
    }

    --ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
    BUI_StoreHeader_Refresh(self.header, self.headerData)
end


local function OnOpenStore()
    if IsInGamepadPreferredMode() then
        local componentTable = {}

        if not IsStoreEmpty() then
            table.insert(componentTable, ZO_MODE_STORE_BUY)
        end

        -- table.insert(componentTable, ZO_MODE_STORE_SELL)
        -- table.insert(componentTable, ZO_MODE_STORE_BUY_BACK)
		--
        -- if CanStoreRepair() then
        --     table.insert(componentTable, ZO_MODE_STORE_REPAIR)
        -- end

        STORE_WINDOW_GAMEPAD:SetActiveComponents(componentTable)
        SCENE_MANAGER:Show(BUI_STORE_SCENE_NAME)
    end
end

local function OnCloseStore()
    if IsInGamepadPreferredMode() then
        -- Ensure that all dialogs related to the store close on interaction end
        ZO_Dialogs_ReleaseDialog("REPAIR_ALL")

        SCENE_MANAGER:Hide(BUI_STORE_SCENE_NAME)
    end
end

function BUI.Store.Class:Initialize(control)
    self.control = control
    self.sceneName = GAMEPAD_STORE_SCENE_NAME

    GAMEPAD_VENDOR_SCENE = ZO_InteractScene:New(self.sceneName, SCENE_MANAGER, STORE_INTERACTION)

    --ZO_Gamepad_ParametricList_Screen.Initialize(self, control, true, false, GAMEPAD_VENDOR_SCENE)
    BUI_Store_ParametricList_Screen.Initialize(self, control, true, false, GAMEPAD_VENDOR_SCENE)

    self.spinner = control:GetNamedChild("SpinnerContainer")
    self.spinner:InitializeSpinner()

    self.control:RegisterForEvent(EVENT_OPEN_STORE, OnOpenStore)
    self.control:RegisterForEvent(EVENT_CLOSE_STORE, OnCloseStore)

    local function UpdateActiveComponentKeybindButtonGroup()
        local activeComponent = self:GetActiveComponent()
        if activeComponent then
            KEYBIND_STRIP:UpdateKeybindButtonGroup(activeComponent.keybindStripDescriptor)
        end
    end

    local OnCurrencyChanged = function()
        if not self.control:IsControlHidden() then
            self:RefreshHeaderData()
        end
        UpdateActiveComponentKeybindButtonGroup()
    end

    local OnFailedRepair = function(eventId, reason)
        self:FailedRepairMessageBox(reason)
    end

    local OnBuySuccess = function(...)
        if not self.control:IsControlHidden() then
            ZO_StoreManager_OnPurchased(...)
        end
    end

    local OnSellSuccess = function(eventId, itemName, quantity, money)
        if not self.control:IsControlHidden() then
            PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        end
    end

    local OnBuyBackSuccess = function(eventId, itemName, itemQuantity, money, itemSoundCategory)
        if(itemSoundCategory == ITEM_SOUND_CATEGORY_NONE) then
            -- Fall back sound if there was no other sound to play
            PlaySound(SOUNDS.ITEM_MONEY_CHANGED)
        else
            PlayItemSound(itemSoundCategory, ITEM_SOUND_ACTION_ACQUIRE)
        end
        UpdateActiveComponentKeybindButtonGroup()
    end

    local OnInventoryUpdated = function()
        if not self.control:IsControlHidden() then
            self:RefreshHeaderData()
        end
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, OnCurrencyChanged)
    self.control:RegisterForEvent(EVENT_BUY_RECEIPT, OnBuySuccess)
    self.control:RegisterForEvent(EVENT_SELL_RECEIPT, OnSellSuccess)
    self.control:RegisterForEvent(EVENT_BUYBACK_RECEIPT, OnBuyBackSuccess)
    self.control:RegisterForEvent(EVENT_ITEM_REPAIR_FAILURE, OnFailedRepair)
    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, OnInventoryUpdated)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, OnInventoryUpdated)

    self:InitializeKeybindStrip()
    self.components = {}

    local function OnItemRepaired(bagId, slotIndex)
        if self.isRepairingAll then
            if self.numberItemsRepairing > 0 then
                self.numberItemsRepairing = self.numberItemsRepairing - 1
                if self.numberItemsRepairing == 0 then
                    self:RepairMessageBox()
                    self.isRepairingAll = false
                end
            end
        else
            self:RepairMessageBox(bagId, slotIndex)
        end
        UpdateActiveComponentKeybindButtonGroup()
    end

    SHARED_INVENTORY:RegisterCallback("ItemRepaired", OnItemRepaired)

end

function BUI.Store.Class:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
		BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)

        self:InitializeStore()
        self:SetMode(self.deferredStartingMode or self.activeComponents[1]:GetStoreMode())
        self.deferredStartingMode = nil
        ZO_GamepadGenericHeader_Activate(self.header)
    elseif newState == SCENE_HIDING then
        self.spinner:DetachFromListEntry()
        GAMEPAD_TOOLTIPS:ClearLines(GAMEPAD_LEFT_TOOLTIP)
    elseif newState == SCENE_HIDDEN then
		BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)

        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
        ZO_GamepadGenericHeader_Deactivate(self.header)
    end
end

function BUI.Store.Class:SetActiveComponents(componentTable)
    self.activeComponents = {}
    for index, componentMode in ipairs(componentTable) do
        local component = self.components[componentMode]

		if component ~= nil then
        	component:Refresh()
        	table.insert(self.activeComponents, component)
		end
    end
    self:RebuildHeaderTabs()
end 

local function SetupItemList(list)
    list:AddDataTemplate("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
end

function BUI.Store.Class:AddList(name, callbackParam, listClass, ...)
    local listContainer = CreateControlFromVirtual("$(parent)"..name, self.control.container, "BUI_Store_ParametricList_Screen_ListContainer")
    local list = self:CreateAndSetupList(listContainer.list, SetupItemList, BUI_VerticalParametricScrollList, ...)
    self.lists[name] = list
    local CREATE_HIDDEN = true
    self:CreateListFragment(name, CREATE_HIDDEN)
    return list
end

function BUI.Store.Class:AddComponent(component)
    self.components[component:GetStoreMode()] = component
end
