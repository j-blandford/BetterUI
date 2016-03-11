local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local GENERAL_COLOR_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1
local GENERAL_COLOR_GREY = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_2
local GENERAL_COLOR_OFF_WHITE = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_3
local GENERAL_COLOR_RED = GAMEPAD_TOOLTIP_COLOR_FAILED


local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "Inventory Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "|c0066FF[Enhanced Inventory]|r Behaviour",
			width = "full",
		},
		{
			type = "checkbox",
			name = "Save inventory position",
			tooltip = "Keeps track of the list position on each category for quicker browsing",
			getFunc = function() return BUI.Settings.Modules["Inventory"].savePosition end,
			setFunc = function(value) BUI.Settings.Modules["Inventory"].savePosition = value end,
			width = "full",
		},
        {
            type = "checkbox",
            name = "Enable category wrapping",
            tooltip = "Enables quick access to \"Quickslots\" when you press LB when selecting \"All\"",
            getFunc = function() return BUI.Settings.Modules["Inventory"].enableWrapping end,
            setFunc = function(value) BUI.Settings.Modules["Inventory"].enableWrapping = value end,
            width = "full",
        },      
		{
			type = "header",
			name = "|c0066FF[Enhanced Inventory]|r Display",
			width = "full",
		},
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Inventory.InitModule(m_options)
    m_options["savePosition"] = true
    m_options["enableWrapping"] = true

    return m_options
end


-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Finally, the Setup() function which replaces the inventory system with a duplicate that I've heavily modified. Duplication is necessary as I don't
--    have access to the beginning :New() method of ZO_GamepadInventory. Will mess quite a few addons up, but will make GAMEPAD_INVENTORY a reference at the end
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

function BUI.Inventory.Setup()
	Init("Inventory", "Inventory")

    BUI_GamepadInventory_OnInitialize(BUI_GamepadInventoryTopLevel) -- Called manually due to the ability to switch OFF the inventory!

    GAMEPAD_INVENTORY_FRAGMENT = ZO_SimpleSceneFragment:New(BUI_GamepadInventoryTopLevel) -- **Replaces** the old inventory with a new one defined in "Templates/GamepadInventory.xml"
    GAMEPAD_INVENTORY_FRAGMENT:SetHideOnSceneHidden(true)

    -- Now update the changes throughout the interface...
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_INVENTORY_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_INVENTORY)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    GAMEPAD_INVENTORY_ROOT_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragment(GAMEPAD_INVENTORY_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_INVENTORY)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragment(GAMEPAD_INVENTORY_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragment(FRAME_EMOTE_FRAGMENT_INVENTORY)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

    -- Overwrite the destroy callback because everything called from GAMEPAD_INVENTORY will now be classed as "insecure"
    ZO_InventorySlot_InitiateDestroyItem = function(inventorySlot)
        SetCursorItemSoundsEnabled(false)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        CallSecureProtected("PickupInventoryItem",bag, index) -- > Here is the key change!
        SetCursorItemSoundsEnabled(true)

        CallSecureProtected("PlaceInWorldLeftClick") -- DESTROY! (also needs to be a secure call)
        return true
    end
    
    -- Hook and replace methods used in ZO_GamepadInventory
    BUI_GAMEPAD_INVENTORY.AddList = BUI.Inventory.AddList
    BUI_GAMEPAD_INVENTORY.SaveListPosition = BUI.Inventory.SaveListPosition
    BUI_GAMEPAD_INVENTORY.ToSavedPosition = BUI.Inventory.ToSavedPosition

    BUI_GAMEPAD_INVENTORY.InitializeCategoryList = BUI.Inventory.InitializeCategoryList
	BUI_GAMEPAD_INVENTORY.InitializeItemList = BUI.Inventory.InitializeItemList
    BUI_GAMEPAD_INVENTORY.InitializeFooter = BUI.Inventory.InitializeFooter
    BUI_GAMEPAD_INVENTORY.RefreshFooter = BUI.Inventory.RefreshFooter
    BUI_GAMEPAD_INVENTORY.InitializeHeader = BUI.Inventory.InitializeHeader
    BUI_GAMEPAD_INVENTORY.SetSelectedInventoryData = BUI.Inventory.SetSelectedInventoryData

    BUI_GAMEPAD_INVENTORY.RefreshCategoryList = BUI.Inventory.RefreshCategoryList
	BUI_GAMEPAD_INVENTORY.RefreshItemList = BUI.Inventory.RefreshItemList
    BUI_GAMEPAD_INVENTORY.RefreshItemActionList = BUI.Inventory.RefreshItemActionList
	BUI_GAMEPAD_INVENTORY.RefreshHeader = BUI.Inventory.RefreshHeader
    BUI_GAMEPAD_INVENTORY.InitializeKeybindStrip = BUI.Inventory.InitializeKeybindStrip
    BUI_GAMEPAD_INVENTORY.TryEquipItem = BUI.Inventory.TryEquipItem
    BUI_GAMEPAD_INVENTORY.InitializeEquipSlotDialog = BUI.Inventory.InitializeEquipSlotDialog

    BUI_GAMEPAD_INVENTORY.InitializeEquipSlotDialog()
    BUI_GAMEPAD_INVENTORY:InitializeFooter()

    BUI_GAMEPAD_INVENTORY.categoryPositions = { }
    BUI_GAMEPAD_INVENTORY.populatedCategoryPos = false

    -- Just some modification to the Nav_1_Quadrant to be wider and cleaner
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:GetNamedChild("NestedBg"):GetNamedChild("LeftDivider"):SetWidth(4)
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:GetNamedChild("NestedBg"):GetNamedChild("RightDivider"):SetWidth(4)


    -- --Recreate the root inventory scene's OnShow and OnHide callbacks to silently bypass the scene (but still keep the initialization functions intact)
    GAMEPAD_INVENTORY_ROOT_SCENE:UnregisterAllCallbacks("StateChange")
    GAMEPAD_INVENTORY_ROOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        local self = BUI_GAMEPAD_INVENTORY
        if newState == SCENE_SHOWING then
            SCENE_MANAGER:Push("gamepad_inventory_item_filter")

            -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 936, 54)
            self:RefreshFooter()
        elseif(newState == SCENE_SHOWN) then
            SCENE_MANAGER:Push("gamepad_inventory_item_filter")
        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()
        elseif newState == SCENE_HIDDEN then
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rootKeybindDescriptor)

            -- Reset to the old width and offset for any other left_tooltip use, slowly going to replace them all :)
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 536, 54)
        end
    end)

    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:UnregisterAllCallbacks("StateChange")
    GAMEPAD_INVENTORY_ITEM_FILTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        local self = BUI_GAMEPAD_INVENTORY
        if newState == SCENE_SHOWING then
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 936, 54)

            self:PerformDeferredInitialization()
            self:RefreshCategoryList()

            self:SetSelectedInventoryData(nil)
            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))

            self.actionMode = ITEM_LIST_ACTION_MODE
            self:RefreshItemList()
            self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
            if self.itemList:IsEmpty() then
                return
            end
            self:SetCurrentList(self.itemList)
            -- if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
            --     KEYBIND_STRIP:AddKeybindButton(self.quickslotKeybindDescriptor)
            --     TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
            -- elseif self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
            --     KEYBIND_STRIP:AddKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
            -- end
            self:UpdateRightTooltip()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
            ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)
            self:RefreshHeader()
            self:RefreshItemActionList()
        
        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()
            self.listWaitingOnDestroyRequest = nil
        elseif newState == SCENE_HIDDEN then
            self:SetSelectedInventoryData(nil)
            GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
            GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 536, 54)

            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
            KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindDescriptor)
            KEYBIND_STRIP:RemoveKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
            if SCENE_MANAGER:IsShowingNext("gamepad_inventory_item_actions") then
                --if taking action on an item, it is no longer new
                self.clearNewStatusOnSelectionChanged = true
                -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
                GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
                GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 936, 54)
            else
                GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
                GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
            end
            self:TryClearNewStatusOnHidden()
            ZO_SavePlayerConsoleProfile()
        end
    end)

    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:UnregisterAllCallbacks("StateChange")
    GAMEPAD_INVENTORY_ITEM_ACTIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        local self = GAMEPAD_INVENTORY
        if newState == SCENE_SHOWING then
            self:RefreshItemActionList()
            if self.actionMode == ITEM_LIST_ACTION_MODE then
                self:UpdateItemLeftTooltip(self.currentlySelectedData)
            else
                self:UpdateCategoryLeftTooltip(self.currentlySelectedData)
            end
            self:SetCurrentList(self.itemActionList)
            KEYBIND_STRIP:AddKeybindButtonGroup(self.itemActionsKeybindStripDescriptor)
            ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)
        elseif newState == SCENE_HIDING then
            ZO_InventorySlot_SetUpdateCallback(nil)
            self:DisableCurrentList()
        elseif newState == SCENE_HIDDEN then
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
            GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
            self:SetSelectedInventoryData(nil)
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.itemActionsKeybindStripDescriptor)

        end
    end)

    if(BUI.Settings.Modules["CIM"].condenseLTooltip) then
        ZO_TOOLTIP_STYLES["topSection"] = {
            layoutPrimaryDirection = "up",
            layoutSecondaryDirection = "right",
            widthPercent = 100,
            childSpacing = 1,
            fontSize = 22,
            height = 64,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
        }

        ZO_TOOLTIP_STYLES["statValuePairStat"] = {
            fontSize = 22,
            uppercase = true,
            fontColorField = GENERAL_COLOR_OFF_WHITE,
        }
        ZO_TOOLTIP_STYLES["statValuePairValue"] =
        {
            fontSize = 30,
            fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["title"] = {
            fontSize = 36,
            customSpacing = 8,
            uppercase = true,
            fontColorField = GENERAL_COLOR_WHITE,
        }
        ZO_TOOLTIP_STYLES["bodyDescription"] =    {
            fontSize = 22,
        }
    end

    -- Now to link our changes back to the original GAMEPAD_INVENTORY. Will try to add compatibility patches in future updates, as this alteration changes the *whole interface* (right the way from initialize!)
   GAMEPAD_INVENTORY = BUI_GAMEPAD_INVENTORY

end