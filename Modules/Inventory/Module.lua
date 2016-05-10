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
            type = "checkbox",
            name = "Use triggers to move to next item type",
            tooltip = "Rather than skip a certain number of items every trigger press (default global behaviour), this will move to the next item type",
            getFunc = function() return BUI.Settings.Modules["Inventory"].useTriggersForSkip end,
            setFunc = function(value) BUI.Settings.Modules["Inventory"].useTriggersForSkip = value end,
            width = "full",
        },
		{
			type = "header",
			name = "|c0066FF[Enhanced Inventory]|r Display",
			width = "full",
		},
        {
            type = "checkbox",
            name = "Replace \"Value\" with the market's price",
            tooltip = "Replaces the item \"Value\" with either MasterMerchant's price or dataDaedra's market price",
            getFunc = function() return BUI.Settings.Modules["Inventory"].showMarketPrice end,
            setFunc = function(value) BUI.Settings.Modules["Inventory"].showMarketPrice = value end,
            width = "full",
        },
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable)
end

function BUI.Inventory.InitModule(m_options)
    m_options["savePosition"] = true
    m_options["enableWrapping"] = true
    m_options["showMarketPrice"] = false
    m_options["useTriggersForSkip"] = false

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

    -- -- Overwrite the destroy callback because everything called from GAMEPAD_INVENTORY will now be classed as "insecure"
    ZO_InventorySlot_InitiateDestroyItem = function(inventorySlot)
        SetCursorItemSoundsEnabled(false)
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        CallSecureProtected("PickupInventoryItem",bag, index) -- > Here is the key change!
        SetCursorItemSoundsEnabled(true)

        CallSecureProtected("PlaceInWorldLeftClick") -- DESTROY! (also needs to be a secure call)
        return true
    end
	--

	GAMEPAD_INVENTORY = BUI.Inventory.Class:New(BUI_GamepadInventoryTopLevel) -- Bam! Initialise the custom inventory class so it's integrated neatly


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


    -- Just some modification to the Nav_1_Quadrant to be wider and cleaner

    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:GetNamedChild("NestedBg"):GetNamedChild("LeftDivider"):SetWidth(4)
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:GetNamedChild("NestedBg"):GetNamedChild("RightDivider"):SetWidth(4)
	GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
    GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, BUI_GAMEPAD_DEFAULT_PANEL_WIDTH+66, 54)

	--

    --     local self = GAMEPAD_INVENTORY
    --     if newState == SCENE_SHOWING then
    --         self:PerformDeferredInitialization()
    --         --SCENE_MANAGER:Push("gamepad_inventory_item_filter")
	--
    --         -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
    --         BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
	--
    --         self:RefreshFooter()
    --     elseif(newState == SCENE_SHOWN) then
    --         --SCENE_MANAGER:Push("gamepad_inventory_item_filter")
	--
    --     elseif newState == SCENE_HIDING then
    --         ZO_InventorySlot_SetUpdateCallback(nil)
    --         self:DisableCurrentList()
    --     elseif newState == SCENE_HIDDEN then
    --         GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    --         KEYBIND_STRIP:RemoveKeybindButtonGroup(self.rootKeybindDescriptor)
	--
    --         -- Reset to the old width and offset for any other left_tooltip use, slowly going to replace them all :)
    --         BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
    --     end
    -- end)

    --
    --     local self = GAMEPAD_INVENTORY
    --     if newState == SCENE_SHOWING then
    --         GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
    --         GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 936, 54)
    --         self:PerformDeferredInitialization()
    --         self:RefreshCategoryList()
	--
    --         self:SetSelectedInventoryData(nil)
    --         self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
	--
    --         self.actionMode = ITEM_LIST_ACTION_MODE
    --         self:RefreshItemList()
    --         self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
    --         if self.itemList:IsEmpty() then
    --             return
    --         end
    --         self:SetCurrentList(self.itemList)
	--
    --         self:UpdateRightTooltip()
    --         KEYBIND_STRIP:AddKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
    --         ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActionList() end)
    --         self:RefreshHeader()
    --         self:RefreshItemActionList()
	--
    --     elseif newState == SCENE_HIDING then
    --         ZO_InventorySlot_SetUpdateCallback(nil)
    --         self:DisableCurrentList()
    --         self.listWaitingOnDestroyRequest = nil
    --     elseif newState == SCENE_HIDDEN then
    --         self:SetSelectedInventoryData(nil)
    --         BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
	--
    --         KEYBIND_STRIP:RemoveKeybindButtonGroup(self.itemFilterKeybindStripDescriptor)
    --         KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindDescriptor)
    --         KEYBIND_STRIP:RemoveKeybindButton(self.switchEquipKeybindDescriptor)
    --         if SCENE_MANAGER:IsShowingNext("gamepad_inventory_item_actions") then
    --             --if taking action on an item, it is no longer new
    --             self.clearNewStatusOnSelectionChanged = true
    --             -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
    --             GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
    --             GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, 936, 54)
    --         else
    --             GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
    --             GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)
    --         end
    --         self:TryClearNewStatusOnHidden()
    --         ZO_SavePlayerConsoleProfile()
    --     end
    -- end)

	inv = GAMEPAD_INVENTORY

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

end
