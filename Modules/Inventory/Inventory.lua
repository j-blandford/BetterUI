local _

-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Local variable definitions; de-clutters the global namespace!
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

local PRESERVE_PREVIOUS_COOLDOWN = true
local OVERWRITE_PREVIOUS_COOLDOWN = false
local USE_LEADING_EDGE = true
local DONT_USE_LEADING_EDGE = false

local GENERIC_HEADER_INFO_LABEL_HEIGHT = 0
local GENERIC_HEADER_INFO_DATA_HEIGHT = 0
local GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY = 4
local ROW_OFFSET_Y = GENERIC_HEADER_INFO_LABEL_HEIGHT
local DATA_OFFSET_X = 5
local HEADER_OFFSET_X = 29

local NEW_ICON_TEXTURE = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new.dds"

BUI_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y = ZO_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y + GENERIC_HEADER_INFO_LABEL_HEIGHT
BUI_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE = 5


BUI_EQUIP_SLOT_DIALOG = "BUI_EQUIP_SLOT_PROMPT"









-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Local function definitions; de-clutters the global namespace! ... also local functions are faster to call than global ones
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

local function BUI_GamepadMenuEntryTemplateParametricListFunction(control, distanceFromCenter, continousParametricOffset) end

local function BUI_SharedGamepadEntryLabelSetup(label, data, selected)
    if label then
        label:SetFont("$(GAMEPAD_MEDIUM_FONT)|28|soft-shadow-thick")
        if data.modifyTextType then
            label:SetModifyTextType(data.modifyTextType)
        end

        local labelTxt = data.text

        if(data.stackCount > 1) then
           labelTxt = labelTxt..zo_strformat(" |cFFFFFF(<<1>>)|r",data.stackCount)
        end

        if(BUI.Settings.Modules["CIM"].attributeIcons) then
            local dS = data.dataSource
            local bagId = dS.bagId
            local slotIndex = dS.slotIndex
            local itemData = GetItemLink(bagId, slotIndex)

            local setItem, _, _, _, _ = GetItemLinkSetInfo(itemData, false)
            local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemData)
            
            if(data.stolen) then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_stolen.dds|t" end
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

local function BUI_Cooldown(control, remaining, duration, cooldownType, timeType, useLeadingEdge, alpha, desaturation, preservePreviousCooldown)
    local inCooldownNow = remaining > 0 and duration > 0
    if inCooldownNow then
        local timeLeftOnPreviousCooldown = control.cooldown:GetTimeLeft()
        if not preservePreviousCooldown or timeLeftOnPreviousCooldown == 0 then
            control.cooldown:SetDesaturation(desaturation)
            control.cooldown:SetAlpha(alpha)
            control.cooldown:StartCooldown(remaining, duration, cooldownType, timeType, useLeadingEdge)
        end
    else
        control.cooldown:ResetCooldown()
    end
    control.cooldown:SetHidden(not inCooldownNow)
end

local function BUI_CooldownSetup(control, data)
    local GAMEPAD_DEFAULT_COOLDOWN_TEXTURE = "EsoUI/Art/Mounts/timer_icon.dds"
    if control.cooldown then
        local currentTime = GetFrameTimeMilliseconds()
        local timeOffset = currentTime - (data.timeCooldownRecorded or 0)
        local remaining = (data.cooldownRemaining or 0) - timeOffset
        local duration = (data.cooldownDuration or 0)
        control.inCooldown = (remaining > 0) and (duration > 0)
        control.cooldown:SetTexture(data.cooldownIcon or GAMEPAD_DEFAULT_COOLDOWN_TEXTURE)
        
        if data.cooldownIcon then
            control.cooldown:SetFillColor(ZO_SELECTED_TEXT:UnpackRGBA())
            control.cooldown:SetVerticalCooldownLeadingEdgeHeight(4)
            BUI_Cooldown(control, remaining, duration, CD_TYPE_VERTICAL_REVEAL, CD_TIME_TYPE_TIME_UNTIL, USE_LEADING_EDGE, 1, 1, PRESERVE_PREVIOUS_COOLDOWN)
        else
            BUI_Cooldown(control, remaining, duration, CD_TYPE_RADIAL, CD_TIME_TYPE_TIME_UNTIL, DONT_USE_LEADING_EDGE, 0.85, 0, OVERWRITE_PREVIOUS_COOLDOWN)
        end
    end
end
-----------------------------------------------------------------------------------------------------

local function BUI_IconSetup(statusIndicator, equippedIcon, data)

    statusIndicator:ClearIcons()

    local isItemNew
    if type(data.brandNew) == "function" then
        isItemNew = data.brandNew()
    else 
        isItemNew = data.brandNew
    end

    if isItemNew and data.enabled then
        statusIndicator:AddIcon(NEW_ICON_TEXTURE)
        statusIndicator:SetHidden(false)
    end


    local slotIndex = data.dataSource.slotIndex

    if data.isEquippedInCurrentCategory or data.isEquippedInAnotherCategory then
        local slotIndex = data.dataSource.slotIndex
        local equipType = data.dataSource.equipType
        if slotIndex == EQUIP_SLOT_BACKUP_MAIN or slotIndex == EQUIP_SLOT_BACKUP_OFF or slotIndex == EQUIP_SLOT_RING2 or slotIndex == EQUIP_SLOT_TRINKET2 then
            equippedIcon:SetTexture(BUI.Lib.GetString("TEXTURE_EQUIP_BACKUP_ICON"))
        else
            equippedIcon:SetTexture(BUI.Lib.GetString("TEXTURE_EQUIP_ICON"))
        end
        if equipType == EQUIP_TYPE_INVALID then 
            equippedIcon:SetTexture(BUI.Lib.GetString("TEXTURE_EQUIP_SLOT_ICON"))
        end
        equippedIcon:SetHidden(false)
    else
        equippedIcon:SetHidden(true)
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

local function BUI_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    BUI_SharedGamepadEntryLabelSetup(control.label, data, selected)

    control:GetNamedChild("ItemType"):SetText(string.upper(data.bestItemCategoryName))
    control:GetNamedChild("Stat"):SetText((data.dataSource.statValue == 0) and "-" or data.dataSource.statValue)

    -- Replace the "Value" with the market price of the item (in yellow)
    if(BUI.Settings.Modules["Inventory"].showMarketPrice) then
        local marketPrice = GetMarketPrice(GetItemLink(data.bagId,data.slotIndex), data.stackCount)
        if(marketPrice ~= 0) then
            control:GetNamedChild("Value"):SetColor(1,0.75,0,1)
            control:GetNamedChild("Value"):SetText(math.floor(marketPrice))
        else
            control:GetNamedChild("Value"):SetColor(1,1,1,1)
            control:GetNamedChild("Value"):SetText(data.stackSellPrice)
        end
    else
        control:GetNamedChild("Value"):SetColor(1,1,1,1)
        control:GetNamedChild("Value"):SetText(data.stackSellPrice)
    end
    
    BUI_SharedGamepadEntryIconSetup(control.icon, control.stackCountLabel, data, selected)
    if control.highlight then
        if selected and data.highlight then
            control.highlight:SetTexture(data.highlight)
        end
        control.highlight:SetHidden(not selected or not data.highlight)
    end
    BUI_CooldownSetup(control, data)
    BUI_IconSetup(control:GetNamedChild("StatusIndicator"), control:GetNamedChild("EquippedMain"), data)
end


-- The below functions are included from ZO_GamepadInventory.lua
local function MenuEntryTemplateEquality(left, right)
    return left.uniqueId == right.uniqueId
end

local function GetCategoryTypeFromWeaponType(bagId, slotIndex)
    local weaponType = GetItemWeaponType(bagId, slotIndex)
    if weaponType == WEAPONTYPE_AXE or weaponType == WEAPONTYPE_HAMMER or weaponType == WEAPONTYPE_SWORD or weaponType == WEAPONTYPE_DAGGER then
        return GAMEPAD_WEAPON_CATEGORY_ONE_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_TWO_HANDED_SWORD or weaponType == WEAPONTYPE_TWO_HANDED_AXE or weaponType == WEAPONTYPE_TWO_HANDED_HAMMER then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE
    elseif weaponType == WEAPONTYPE_FIRE_STAFF or weaponType == WEAPONTYPE_FROST_STAFF or weaponType == WEAPONTYPE_LIGHTNING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF
    elseif weaponType == WEAPONTYPE_HEALING_STAFF then
        return GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF
    elseif weaponType == WEAPONTYPE_BOW then
        return GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW
    elseif weaponType ~= WEAPONTYPE_NONE then
        return GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED
    end
end

local function IsTwoHandedWeaponCategory(categoryType)
    return (categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_MELEE or
            categoryType == GAMEPAD_WEAPON_CATEGORY_DESTRUCTION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_RESTORATION_STAFF or
            categoryType == GAMEPAD_WEAPON_CATEGORY_TWO_HANDED_BOW)
end

local function GetBestItemCategoryDescription(itemData)
    if itemData.equipType == EQUIP_TYPE_INVALID then
        return GetString("SI_ITEMTYPE", itemData.itemType)
    end
    local categoryType = GetCategoryTypeFromWeaponType(itemData.bagId, itemData.slotIndex)
    if categoryType ==  GAMEPAD_WEAPON_CATEGORY_UNCATEGORIZED then
        local weaponType = GetItemWeaponType(itemData.bagId, itemData.slotIndex)
        return GetString("SI_WEAPONTYPE", weaponType)
    elseif categoryType then
        return GetString("SI_GAMEPADWEAPONCATEGORY", categoryType)
    end
    local armorType = GetItemArmorType(itemData.bagId, itemData.slotIndex)
    local itemLink = GetItemLink(itemData.bagId,itemData.slotIndex)
    if armorType ~= ARMORTYPE_NONE then
        return GetString("SI_ARMORTYPE", armorType).." "..GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))
    end
    return GetString("SI_ITEMTYPE", itemData.itemType)
end

local function GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return function(itemData)
        if filteredEquipSlot then
            return ZO_Character_DoesEquipSlotUseEquipType(filteredEquipSlot, itemData.equipType)
        end
        if nonEquipableFilterType then
            return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, nonEquipableFilterType)
        else
            return true
        end
        
        return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
    end
end
-- END ----------------------------





local function SetupItemList(list)
    list:AddDataTemplate("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, BUI_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
end

local function SetupCategoryList(list)
    list:AddDataTemplate("BUI_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)    
end








-------------------------------------------------------------------------------------------------------------------------------------------------------
--
--    Global function definitions; defined within the BUI.Inventory namespace and used to overwrite certain functions within "ZO_GamepadInventory"
--
-------------------------------------------------------------------------------------------------------------------------------------------------------


-- A function which can rescale the whole inventory interface
function BUI.Inventory.RescaleControls(self)
    --self.control:SetWidth
end


-- Allows the inventory to return to the last position selected in the interface
function BUI.Inventory.ToSavedPosition(self)
    if(BUI.Settings.Modules["Inventory"].savePosition) then
        local lastPosition = self.categoryPositions[self.categoryList.selectedIndex]
        if(lastPosition ~= nil) then
            if(#self.itemList.dataList > lastPosition) then
                self.itemList.selectedIndex = lastPosition
                self.itemList.targetSelectedIndex = lastPosition
            else
                self.itemList.selectedIndex = #self.itemList.dataList
                self.itemList.targetSelectedIndex = #self.itemList.dataList
            end
        end
    else 
        self.itemList.selectedIndex = 1
        self.itemList.targetSelectedIndex = 1        
    end

        -- Toggle "Switch Slot" with "Assign to Quickslot" 
    if self.categoryList.selectedData ~= nil then
        KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindDescriptor)
        KEYBIND_STRIP:RemoveKeybindButton(self.switchEquipKeybindDescriptor)

        if self.categoryList.selectedData.filterType == ITEMFILTERTYPE_QUICKSLOT then
            KEYBIND_STRIP:AddKeybindButton(self.quickslotKeybindDescriptor)
        else 
            KEYBIND_STRIP:AddKeybindButton(self.switchEquipKeybindDescriptor)
        end
    end
   

end

function BUI.Inventory.RefreshItemActionList(self)
    self.itemActionList:Clear()

    local function MarkAsJunk()
        local target = GAMEPAD_INVENTORY.itemList:GetTargetData()
        SetItemIsJunk(target.bagId, target.slotIndex, true)
        --GAMEPAD_INVENTORY:RefreshItemList()
    end
    local function UnmarkAsJunk()
        local target = GAMEPAD_INVENTORY.itemList:GetTargetData()
        SetItemIsJunk(target.bagId, target.slotIndex, false)  
       -- GAMEPAD_INVENTORY:RefreshItemList()
    end

    local targetData = self.actionMode == ITEM_LIST_ACTION_MODE and self.itemList:GetTargetData() or self:GenerateItemSlotData(self.categoryList:GetTargetData())   
    self:SetSelectedInventoryData(targetData)

    if(BUI.Settings.Modules["CIM"].enableJunk) then
        if(self.categoryList:GetTargetData().showJunk ~= nil) then
            self.itemActions.slotActions.m_slotActions[#self.itemActions.slotActions.m_slotActions+1] = {"Unmark as Junk", UnmarkAsJunk, "secondary"}
        else
            self.itemActions.slotActions.m_slotActions[#self.itemActions.slotActions.m_slotActions+1] = {"Mark as Junk", MarkAsJunk, "secondary"}
        end 
    end

    local actions = self.itemActions:GetSlotActions()
    local numActions = actions:GetNumSlotActions()
    for i = 1, numActions do
        local action = actions:GetSlotAction(i)
        local data = ZO_GamepadEntryData:New(actions:GetRawActionName(action))
        data.action = action
   
        self.itemActionList:AddEntry("ZO_GamepadItemEntryTemplate", data)
    end
    self.itemActionList:Commit()

    if targetData and numActions == 0 then
        self:MarkDirty()
    end
end

function BUI.Inventory.RefreshItemList(self)
    self.itemList:Clear()
    if self.categoryList:IsEmpty() then return end

    self.itemList.control:GetNamedChild("SelectBg"):SetHidden(false)

    local filteredEquipSlot = self.categoryList:GetTargetData().equipSlot
    local nonEquipableFilterType = self.categoryList:GetTargetData().filterType
    local showJunkCategory = (self.categoryList:GetTargetData().showJunk ~= nil)
    local filteredDataTable
    local isQuestItem = nonEquipableFilterType == ITEMFILTERTYPE_QUEST

    if isQuestItem then
        filteredDataTable = {}
        local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
        for _, questItems in pairs(questCache) do
            for _, questItem in pairs(questItems) do            
                ZO_InventorySlot_SetType(questItem, SLOT_TYPE_QUEST_ITEM)
                table.insert(filteredDataTable, questItem)
            end         
        end
    else
        local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
        filteredDataTable = SHARED_INVENTORY:GenerateFullSlotData(comparator, BAG_BACKPACK, BAG_WORN)
        for _, itemData in pairs(filteredDataTable) do
            itemData.bestItemCategoryName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
            if itemData.bagId == BAG_WORN then
                itemData.isEquippedInCurrentCategory = false
                itemData.isEquippedInAnotherCategory = false
                if itemData.slotIndex == filteredEquipSlot then
                    itemData.isEquippedInCurrentCategory = true
                else
                    itemData.isEquippedInAnotherCategory = true
                end
            else
                local slotIndex = GetItemCurrentActionBarSlot(itemData.bagId, itemData.slotIndex)
                itemData.isEquippedInCurrentCategory = slotIndex and true or nil
            end
            ZO_InventorySlot_SetType(itemData, SLOT_TYPE_GAMEPAD_INVENTORY_ITEM)
        end
    end
    table.sort(filteredDataTable, ZO_GamepadInventory_DefaultItemSortComparator)
    local lastBestItemCategoryName
    for i, itemData in ipairs(filteredDataTable) do
        local nextItemData = filteredDataTable[i + 1]
        local data = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        data:InitializeInventoryVisualData(itemData)
        local remaining, duration
        if isQuestItem then 
            remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
        else
            remaining, duration = GetItemCooldownInfo(itemData.bagId, itemData.slotIndex)
        end
        if remaining > 0 and duration > 0 then
            data:SetCooldown(remaining, duration)
        end
        data.itemTypeString = lastBestItemCategoryName
        data.isEquippedInCurrentCategory = itemData.isEquippedInCurrentCategory
        data.isEquippedInAnotherCategory = itemData.isEquippedInAnotherCategory
        data.isJunk = itemData.isJunk
        if (not data.isJunk and not showJunkCategory) or (data.isJunk and showJunkCategory) or not BUI.Settings.Modules["CIM"].enableJunk then
            self.itemList:AddEntry("BUI_GamepadItemSubEntryTemplate", data)
        end
    end
    self.itemList:Commit()

    -- If the user has been to this menu before, a variable lastSelection holds the position they were before switching categories
    self:ToSavedPosition()

    if self.itemList:IsEmpty() then
        SCENE_MANAGER:Hide("gamepad_inventory_item_filter")
    end
end

function BUI.Inventory.InitializeCategoryList(self)
    self.categoryList = self:AddList("Category", SetupCategoryList, BUI_VerticalParametricScrollList)
    self.categoryList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))

    local function OnSelectedCategoryChanged(list, selectedData)
         if selectedData then 
            self:SetSelectedItemUniqueId(self:GenerateItemSlotData(selectedData))
            self.selectedItemFilterType = selectedData.filterType
        else
            self:SetSelectedItemUniqueId(nil)
        end
        self:UpdateCategoryLeftTooltip(selectedData)
    end
    self.categoryList:SetOnSelectedDataChangedCallback(OnSelectedCategoryChanged)
    --Match the functionality to the target data
    local function OnTargetCategoryChanged(list, targetData)
        self.currentlySelectedData = targetData
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.rootKeybindDescriptor)
    end
    self.categoryList:SetOnTargetDataChangedCallback(OnTargetCategoryChanged)
end

function BUI_InventoryUtils_MatchMaterials(itemData)
    return (ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_CRAFTING)) and not ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_QUICKSLOT)
end

function BUI_InventoryUtils_All(itemData)
    return true
end

function BUI.Inventory.RefreshCategoryList(self)
    self.categoryList:Clear()
    if(self.header.tabBar ~= nil) then self.header.tabBar.dataList = { } end

    do
        local isListEmpty = self:IsItemListEmpty(nil, nil)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_ALL")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(BUI_InventoryUtils_All, nil, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end
    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_WEAPONS)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_WEAPONS")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_weapons.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_WEAPONS, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_WEAPONS
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end
    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_ARMOR)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_APPAREL")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_apparel.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_ARMOR, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_ARMOR
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end 
    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_CONSUMABLE)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_CONSUMABLE")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_consumables.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_CONSUMABLE, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_CONSUMABLE
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end
    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_CRAFTING)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_MATERIALS")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_CRAFTING, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_CRAFTING
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end
    do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_MISCELLANEOUS)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_MISC")
            local iconFile = "esoui/art/inventory/gamepad/gp_inventory_icon_miscellaneous.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_MISCELLANEOUS, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_MISCELLANEOUS
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
        end
    end
    do
        local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
        if next(questCache) then
            local name = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
            local iconFile = "/esoui/art/notifications/gamepad/gp_notificationicon_quest.dds"
            local data = ZO_GamepadEntryData:New(name, iconFile)
            data.filterType = ITEMFILTERTYPE_QUEST
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data) 
            BUI.GenericHeader.AddToList(self.header, data) 
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end          
        end
    end
    do
        if(BUI.Settings.Modules["CIM"].enableJunk and HasAnyJunk(BAG_BACKPACK, false)) then
            local isListEmpty = self:IsItemListEmpty(nil, nil)
            if not isListEmpty then
                local name = BUI.Lib.GetString("INV_ITEM_JUNK")
                local iconFile = "EsoUI/Art/Inventory/inventory_tabicon_junk_up.dds"
                local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(BUI_InventoryUtils_All, nil, BAG_BACKPACK)
                local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
                data.showJunk = true
                data:SetIconTintOnSelection(true)
                self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
                BUI.GenericHeader.AddToList(self.header, data)
                if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
            end
        end
    end
     do
        local isListEmpty = self:IsItemListEmpty(nil, ITEMFILTERTYPE_QUICKSLOT)
        if not isListEmpty then
            local name = BUI.Lib.GetString("INV_ITEM_QUICKSLOT")
            local iconFile = "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds"
            local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, ITEMFILTERTYPE_QUICKSLOT, BAG_BACKPACK)
            local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
            data.filterType = ITEMFILTERTYPE_QUICKSLOT
            data:SetIconTintOnSelection(true)
            self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
            BUI.GenericHeader.AddToList(self.header, data)
            if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end

        end
    end

    self.populatedCategoryPos = true
    self.categoryList:Commit()
    self.header.tabBar:Activate()
end

local function CanUseItemQuestItem(inventorySlot)
    if inventorySlot then
        if inventorySlot.toolIndex then
            return CanUseQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        elseif inventorySlot.conditionIndex then
            return CanUseQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end
    end
    return false
end

local function TryUseQuestItem(inventorySlot)
    if inventorySlot then
        if inventorySlot.toolIndex then
            UseQuestTool(inventorySlot.questIndex, inventorySlot.toolIndex)
        elseif inventorySlot.conditionIndex then
            UseQuestItem(inventorySlot.questIndex, inventorySlot.stepIndex, inventorySlot.conditionIndex)
        end
    end
end



function BUI.Inventory.SetSelectedInventoryData(self, inventoryData)
    if SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
        if inventoryData then
            if self.selectedItemUniqueId and CompareId64s(inventoryData.uniqueId, self.selectedItemUniqueId) ~= 0 then

                SCENE_MANAGER:HideCurrentScene() -- The previously selected item no longer exists, back out of the command list
            end
        elseif inventoryData == nil and (SCENE_MANAGER:GetPreviousSceneName() == "gamepad_inventory_root") then
            SCENE_MANAGER:HideCurrentScene() -- The equipped item was deleted from the category list, back out of command list
        else
            if self.selectedItemUniqueId then
                SCENE_MANAGER:PopScenes(2) -- The previously selected filter is empty, back out two scenes
            end
        end
    end
    if(inventoryData) then
        self.selectedItemUniqueId = inventoryData.uniqueId
    else
        self.selectedItemUniqueId = nil
    end

    self.itemActions.inventorySlot = inventoryData

    for i, command in ipairs(self.itemActions) do
        if(command.activateCallback) then
            command.activateCallback(inventoryData)
        end
    end

    -- All of the callbacks that are possible on the "A" button press have to have CallSecureProtected()
    local PRIMARY_ACTION = 1

    if(self.primaryCallbacks == nil) then
        self.primaryCallbacks = {
            Use = function() 
                local bag, index = ZO_Inventory_GetBagAndIndex(self.itemActions.inventorySlot)
                local usable, onlyFromActionSlot = IsItemUsable(bag, index)

                if not CanUseItemQuestItem(self.itemActions.inventorySlot.dataSource) then
                    if usable and not onlyFromActionSlot then
                        self:SaveListPosition()
                        CallSecureProtected("UseItem",bag, index) -- > this is a key alteration. we've replaced the inventory completely, so even ZOS's own code won't function without CSP(...)
                        self:ToSavedPosition()
                        return true
                    end
                 else
                    self:SaveListPosition()
                    TryUseQuestItem(self.itemActions.inventorySlot.dataSource)
                    self:ToSavedPosition()
                    return true
                end
            end,
            Equip = function()
                local bag, index = ZO_Inventory_GetBagAndIndex(self.itemActions.inventorySlot)
                local equipSucceeds, possibleError = IsEquipable(bag, index)
                if(equipSucceeds) then
                    self:SaveListPosition()
                    BUI.Inventory.TryEquipItem(self, self.itemActions.inventorySlot) -- > My own equip function, alters the functionality to allow main hand and off hand dialog
                    self:ToSavedPosition()
                    return true
                end
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, possibleError)
            end,
            Unequip = function()
                local equipSlot = ZO_Inventory_GetSlotIndex(self.itemActions.inventorySlot)
                self:SaveListPosition()
                UnequipItem(equipSlot) -- > for future reference, maybe need CSP(...) here upon API changes
                self:ToSavedPosition()   
            end   
        }
    end

    local INDEX_ACTION_NAME = 1
    local INDEX_ACTION_CALLBACK = 2
    local INDEX_ACTION_TYPE = 3
    local INDEX_ACTION_VISIBILITY = 4
    local INDEX_ACTION_OPTIONS = 5
    local PRIMARY_ACTION_KEY = 1

    -- We have to overwrite the DoPrimaryAction() function, replacing certain commands with the CallSecureProtected equivalent ("Use" is one that needs to be overriddem)
    self.itemActions.slotActions.DoPrimaryAction = function(options)
        local self = self
        local primaryAction = self.itemActions.slotActions:GetAction(PRIMARY_ACTION_KEY, "primary", options)
        local success = false
        if(primaryAction) then
            success = true
            if IsUnitDead("player") then    
                local actionOptions = primaryAction[INDEX_ACTION_OPTIONS]
                if actionOptions and actionOptions.visibleWhenDead == true then
                    -- We also have to let other functions through, as many addons add new keybinds
                    if(self.primaryCallbacks[self.itemActions.actionName] == nil) then
                        self:SaveListPosition() -- allows other addons' keybinds to return to the current item slot index.
                        primaryAction[INDEX_ACTION_CALLBACK]()
                    else
                        self.primaryCallbacks[self.itemActions.actionName]()
                    end
                else
                    ZO_AlertEvent(EVENT_UI_ERROR, SI_CANNOT_DO_THAT_WHILE_DEAD)
                end
            else
                if self.itemActions.slotActions:CheckPrimaryActionVisibility(options) then
                    if(self.primaryCallbacks[self.itemActions.actionName] == nil) then
                        self:SaveListPosition()
                        primaryAction[INDEX_ACTION_CALLBACK]()
                    else
                        self.primaryCallbacks[self.itemActions.actionName]()
                    end
                end
            end
        end
        return success
    end

    self.itemActions:RefreshKeybindStrip()
end



function BUI.Inventory.InitializeItemList(self)
    self.itemList = self:AddList("Items", SetupItemList, BUI_VerticalParametricScrollList)

    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)
        if SCENE_MANAGER:IsShowing("gamepad_inventory_item_filter") or SCENE_MANAGER:IsShowing("gamepad_inventory_item_actions") then
            if self.actionMode == ITEM_LIST_ACTION_MODE then
                self:SetSelectedInventoryData(selectedData)
            end
            self:PrepareNextClearNewStatus(selectedData)
            self.itemList:RefreshVisible()
            self:UpdateRightTooltip()
        end
    end)

    self.itemList.maxOffset = 0
    self.itemList.headerDefaultPadding = 15
    self.itemList.headerSelectedPadding = 0
    self.itemList.universalPostPadding = 5

    local function OnInventoryUpdated(bagId)
        self:MarkDirty()
        if SCENE_MANAGER:IsShowing("gamepad_inventory_root") then
            self:RefreshCategoryList()
        end
    end
    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnInventoryUpdated)
end

function BUI.Inventory.SaveListPosition(self)
    self.categoryPositions[self.categoryList.selectedIndex] = self.itemList.selectedIndex
end


function BUI.Inventory.AddList(self, name, callbackParam, listClass, ...)
    local listContainer = CreateControlFromVirtual("$(parent)"..name, self.control.container, "BUI_Gamepad_ParametricList_Screen_ListContainer")
    local list = self:CreateAndSetupList(listContainer.list, callbackParam, listClass, ...)
    list.alignToScreenCenterExpectedEntryHalfHeight = 15
    self.lists[name] = list
    local CREATE_HIDDEN = true
    self:CreateListFragment(name, CREATE_HIDDEN)
    return list
end

local function WrapValue(newValue, maxValue)
    if(newValue < 1) then return maxValue end
    if(newValue > maxValue) then return 1 end
    return newValue
end

function BUI_TabBar_OnTabNext(parent, successful)
    if(successful) then 
        parent:SaveListPosition()

        parent.categoryList.targetSelectedIndex = WrapValue(parent.categoryList.targetSelectedIndex + 1, #parent.categoryList.dataList)
        parent.categoryList.selectedIndex = parent.categoryList.targetSelectedIndex
        parent.categoryList.selectedData = parent.categoryList.dataList[parent.categoryList.selectedIndex]
        parent.RefreshItemList(parent)
    end 
end
function BUI_TabBar_OnTabPrev(parent, successful)
    if(successful) then  
        parent:SaveListPosition()
        
        parent.categoryList.targetSelectedIndex = WrapValue(parent.categoryList.targetSelectedIndex - 1, #parent.categoryList.dataList) 
        parent.categoryList.selectedIndex = parent.categoryList.targetSelectedIndex 
        parent.categoryList.selectedData = parent.categoryList.dataList[parent.categoryList.selectedIndex]
        parent.RefreshItemList(parent)
    end
end

-- local function copied (and slightly edited for unequipped items!) from "inventoryutils_gamepad.lua"
local function BUI_GetEquipSlotForEquipType(equipType)
    local equipSlot = nil
    for i, testSlot in ZO_Character_EnumerateOrderedEquipSlots() do
        local locked = IsLockedWeaponSlot(testSlot)
        local isEquipped = HasItemInSlot(BAG_WORN, testSlot)
         local isCorrectSlot = ZO_Character_DoesEquipSlotUseEquipType(testSlot, equipType)
        if not locked and isCorrectSlot then
              equipSlot = testSlot
              break
         end
    end
    return equipSlot
end

function BUI.Inventory.TryEquipItem(self, inventorySlot)
    local equipType = inventorySlot.dataSource.equipType

    -- Check if the current item is an armour (or two handed, where it doesn't need a dialog menu), if so, then just equip into it's slot
    local armorType = GetItemArmorType(inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex)
    if armorType ~= ARMORTYPE_NONE or equipType == EQUIP_TYPE_TWO_HAND or equipType == EQUIP_TYPE_NECK then
        if equipType == EQUIP_TYPE_TWO_HAND then
            CallSecureProtected("RequestMoveItem",inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex, BAG_WORN, BUI_GetEquipSlotForEquipType(equipType), 1)
        else
            CallSecureProtected("RequestMoveItem",inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex, BAG_WORN, BUI_GetEquipSlotForEquipType(equipType), 1)
        end
    else
        -- Else, it's a weapon, so show a dialog so the user can pick either slot!
        ZO_Dialogs_ShowDialog(BUI_EQUIP_SLOT_DIALOG, {inventorySlot, self.equipToMainSlot}, {mainTextParams={BUI.Lib.GetString("SI_INV_EQUIPSLOT_MAIN")}}, true)
    end
end

function BUI.Inventory.RefreshHeader(self)
    BUI.GenericHeader.Refresh(self.header, self.headerData)
end

function BUI.Inventory.RefreshFooter(self)
    BUI.GenericFooter.Refresh(self)
end


function BUI.Inventory.InitializeHeader(self)
    local function UpdateTitleText()
        if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
            return GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER)
        elseif self.actionMode == ITEM_LIST_ACTION_MODE then
            return self.categoryList:GetTargetData().text
        end
        return nil
    end
    local function RefreshHeader()
        if not self.control:IsHidden() then
            self:RefreshHeader()
            self:RefreshFooter()
        end
    end

    self.headerData = {
        titleText = UpdateTitleText,
        tabBarData = { parent = self, onNext = BUI_TabBar_OnTabNext, onPrev = BUI_TabBar_OnTabPrev }
    }

    self.equipToMainSlot = true
    BUI.GenericHeader.SetEquipText(self.header, self.equipToMainSlot)

    self:RefreshHeader()
    local function RefreshSelectedData()
        if not self.control:IsHidden() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end
    local function RefreshHeaderAndSelectedData()
        self:RefreshHeader()
        self:RefreshFooter()
        RefreshSelectedData()
    end

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshHeaderAndSelectedData)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshHeaderAndSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, RefreshSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_REINCARNATED, RefreshSelectedData)
end

function BUI.Inventory.UpdateRightTooltip(self)
    -- ddebug("UpdateRightTooltip called")
    -- local selectedData = self.itemList:GetSelectedData()

    -- selectedData.equipSlot = BUI_GetEquipSlotForEquipType(selectedData.equipType)

    -- if selectedData and selectedData.equipSlot and GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_RIGHT_TOOLTIP, BAG_WORN, selectedData.equipSlot) and selectedData.dataSource.equipType ~= 0 then     
    --     self:UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, selectedData.equipSlot)
    --     GAMEPAD_TOOLTIPS:SetStatusLabelHidden(GAMEPAD_RIGHT_TOOLTIP, false)
    -- else
    --     self:UpdateTooltipEquippedIndicatorText(GAMEPAD_RIGHT_TOOLTIP, 0)
    --     GAMEPAD_TOOLTIPS:SetStatusLabelHidden(GAMEPAD_RIGHT_TOOLTIP, true)
    -- end
end


function BUI.Inventory.InitializeFooter(self)
    local function RefreshFooter()
        self:RefreshFooter()
    end

    BUI.GenericFooter.Initialize(self)

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshFooter)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshFooter)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, RefreshFooter)
end

local function InventoryBackCallback()
    SCENE_MANAGER:ClearSceneStack() 
    SCENE_MANAGER:HideCurrentScene() 
    return true 
end

function BUI.Inventory.CreateListTriggerKeybindDescriptors(list, optionalHeaderComparator)
    local leftTrigger = {
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        callback = function()
            if type(list) == "function" then
                list = list()
            end
            if not list:IsEmpty() then
                list.currentCategoryName = list.dataList[list.selectedIndex].dataSource.bestItemCategoryName
                if(BUI.Settings.Modules["Inventory"].useTriggersForSkip) then
                    list:SetPreviousSelectedDataByEval(function(data) if(data.dataSource.bestItemCategoryName ~= list.currentCategoryName) then return true else return false end end )
                else
                    list:SetSelectedIndex(list.selectedIndex-tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
                end
            end
        end
    }
    local rightTrigger = {
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        callback = function()
            if type(list) == "function" then
                list = list()
            end
            if not list:IsEmpty() then
                list.currentCategoryName = list.dataList[list.selectedIndex].dataSource.bestItemCategoryName
                if(BUI.Settings.Modules["Inventory"].useTriggersForSkip) then
                    list:SetNextSelectedDataByEval(function(data) if(data.dataSource.bestItemCategoryName ~= list.currentCategoryName) then return true else return false end end )
                else
                    list:SetSelectedIndex(list.selectedIndex+tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
                end
            end
        end,
    }
    return leftTrigger, rightTrigger
end

function BUI.Inventory.AddListTriggerKeybindDescriptors(descriptor, list, optionalHeaderComparator)
    local leftTrigger, rightTrigger = BUI.Inventory.CreateListTriggerKeybindDescriptors(list, optionalHeaderComparator)
    table.insert(descriptor, leftTrigger)
     table.insert(descriptor, rightTrigger)
end

function BUI.Inventory.InitializeKeybindStrip(self)
    self.rootKeybindDescriptor = {}
    
    self.itemFilterKeybindStripDescriptor = 
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,
            callback = function()
                self:SaveListPosition()
                self:ShowActions()
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_DESTROY),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            order = 2000,
            disabledDuringSceneHiding = true,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,
            callback = function()
                local targetData = self.itemList:GetTargetData()
                if(ZO_InventorySlot_CanDestroyItem(targetData) and ZO_InventorySlot_InitiateDestroyItem(targetData)) then
                    self:SaveListPosition()
                    self.itemList:Deactivate()
                    self.listWaitingOnDestroyRequest = self.itemList
                end
            end,
        },
    }
    -- Replace "Toggle Mode" with "Switch Slot", keeping the variable name "toggleCompareModeKeybindStripDescriptor" for compatibility
    self.switchEquipKeybindDescriptor = {
            alignment = KEYBIND_STRIP_ALIGN_RIGHT,
            name = BUI.Lib.GetString("SI_INV_SWITCH_EQUIPSLOT"),
            keybind = "UI_SHORTCUT_SECONDARY",
            visible = function()
                return true
            end,
            callback = function()
                self.equipToMainSlot = not self.equipToMainSlot
                BUI.GenericHeader.SetEquipText(self.header, self.equipToMainSlot)
            end,
    }


    self.quickslotKeybindDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
        keybind = "UI_SHORTCUT_SECONDARY",
        visible = function()
                return true
            end,
        callback = function() self:ShowQuickslot() end,
    }
    BUI.Inventory.AddListTriggerKeybindDescriptors(self.itemFilterKeybindStripDescriptor, self.itemList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, InventoryBackCallback)
    self.itemActionsKeybindStripDescriptor = {}
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.itemActionsKeybindStripDescriptor, self.itemActionList)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemActionsKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.rootKeybindDescriptor, self.categoryList)
end

function BUI.Inventory.InitializeEquipSlotDialog(self)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.BASIC)
    local confirmString = zo_strupper(GetString(SI_DESTROY_ITEM_CONFIRMATION))

    local function ReleaseDialog(data, mainSlot)
        local equipType = data[1].dataSource.equipType

        if(equipType ~= EQUIP_TYPE_RING) then
            if(mainSlot) then    
                CallSecureProtected("RequestMoveItem",data[1].dataSource.bagId, data[1].dataSource.slotIndex, BAG_WORN, data[2] and EQUIP_SLOT_MAIN_HAND or EQUIP_SLOT_BACKUP_MAIN, 1)
            else
                CallSecureProtected("RequestMoveItem",data[1].dataSource.bagId, data[1].dataSource.slotIndex, BAG_WORN, data[2] and EQUIP_SLOT_OFF_HAND or EQUIP_SLOT_BACKUP_OFF, 1)
            end
        else
            if(mainSlot) then    
                CallSecureProtected("RequestMoveItem",data[1].dataSource.bagId, data[1].dataSource.slotIndex, BAG_WORN, EQUIP_SLOT_RING1, 1)
            else
                CallSecureProtected("RequestMoveItem",data[1].dataSource.bagId, data[1].dataSource.slotIndex, BAG_WORN, EQUIP_SLOT_RING2, 1)
            end
        end

        ZO_Dialogs_ReleaseDialogOnButtonPress(BUI_EQUIP_SLOT_DIALOG)
    end
    ZO_Dialogs_RegisterCustomDialog(BUI_EQUIP_SLOT_DIALOG,
    {
        blockDialogReleaseOnPress = true, 
        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.BASIC,
            allowRightStickPassThrough = true,
        },
        setup = function()
            dialog.setupFunc(dialog)
        end,
        title =
        {
            text = BUI.Lib.GetString("SI_INV_EQUIPSLOT_TITLE"),
        },
        mainText = 
        {
            text = BUI.Lib.GetString("SI_INV_EQUIPSLOT_PROMPT"),
        },
      
        buttons =
        {
            {
                keybind = "DIALOG_PRIMARY",
                text = BUI.Lib.GetString("INV_EQUIP_PROMPT_MAIN"),
                callback = function()
                    ReleaseDialog(dialog.data, true)
                end,
            },
            {
                keybind = "DIALOG_NEGATIVE",
                text = BUI.Lib.GetString("INV_EQUIP_PROMPT_BACKUP"),
                callback = function()
                    ReleaseDialog(dialog.data, false)
                end,
            },
        }
    })
end

ZO_GAMEPAD_SPLIT_STACK_DIALOG = "GAMEPAD_SPLIT_STACK"

function SecureTryPlaceInventoryItemInEmptySlot(targetBag)
    local emptySlotIndex = FindFirstEmptySlotInBag(targetBag)
    if(emptySlotIndex ~= nil) then
        CallSecureProtected("PlaceInInventory",targetBag, emptySlotIndex)
    else
        local errorStringId = (targetBag == BAG_BACKPACK) and SI_INVENTORY_ERROR_INVENTORY_FULL or SI_INVENTORY_ERROR_BANK_FULL
        ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, errorStringId)
    end
end

function BUI.Inventory.InitializeSplitStackDialog(self)
    local dialog = ZO_GenericGamepadDialog_GetControl(GAMEPAD_DIALOGS.PARAMETRIC)

    local function SetupDialog(stackControl, data)
        local itemIcon, _, _, _, _, _, _, quality = GetItemInfo(dialog.data.bagId, dialog.data.slotIndex)
        local stackSize = GetSlotStackSize(dialog.data.bagId, dialog.data.slotIndex)
        data.itemIcon = itemIcon
        data.quality = quality
        data.stackSize = stackSize
        dialog.setupFunc(dialog)
    end

    local function UpdateStackSizes(control)
        local value2 = control.slider:GetValue()
        local value1 = dialog.data.stackSize - value2
        control.sliderValue1:SetText(value1)
        control.sliderValue2:SetText(value2)
    end

    ZO_Dialogs_RegisterCustomDialog(ZO_GAMEPAD_SPLIT_STACK_DIALOG,
    {
        blockDirectionalInput = true,

        gamepadInfo = {
            dialogType = GAMEPAD_DIALOGS.PARAMETRIC,
        },

        setup = SetupDialog,

        title =
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_TITLE,
        },

        mainText = 
        {
            text = SI_GAMEPAD_INVENTORY_SPLIT_STACK_PROMPT,
        },

        parametricList =
        {
            {
                template = "ZO_GamepadSliderItem",

                templateData = {
                    setup = function(control, data, selected, reselectingDuringRebuild, enabled, active)
                        local iconFile = dialog.data.itemIcon

                        if iconFile == nil or iconFile == "" then
                            control.icon1:SetHidden(true)
                            control.icon2:SetHidden(true)
                        else
                            control.icon1:SetTexture(iconFile)
                            control.icon2:SetTexture(iconFile)
                            control.icon1:SetHidden(false)
                            control.icon2:SetHidden(false)
                        end

                        control.slider:SetMinMax(1, dialog.data.stackSize - 1)
                        control.slider:SetValue(zo_floor(dialog.data.stackSize / 2))
                        control.slider:SetValueStep(1)
                        control.slider.valueChangedCallback = function() UpdateStackSizes(control) end
                        if selected then
                            control.slider:Activate()
                            self.splitStackSlider = control.slider
                            UpdateStackSizes(control)
                        else
                            control.slider:Deactivate()
                        end
                    end,
                },
            },
        },
       
        buttons =
        {
            {
                keybind = "DIALOG_NEGATIVE",
                text = GetString(SI_DIALOG_CANCEL),
            },

            {
                keybind = "DIALOG_PRIMARY",
                text = GetString(SI_GAMEPAD_SELECT_OPTION),
                callback = function()
                    CallSecureProtected("PickupInventoryItem",dialog.data.bagId, dialog.data.slotIndex, self.splitStackSlider:GetValue())
                    SecureTryPlaceInventoryItemInEmptySlot(dialog.data.bagId)
                end,
            },
        }
    })
end