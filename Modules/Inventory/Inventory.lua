local _

local BLOCK_TABBAR_CALLBACK = true
ZO_GAMEPAD_INVENTORY_SCENE_NAME = "gamepad_inventory_root"

BUI.Inventory.Class = ZO_GamepadInventory:Subclass() -- allows us to completely alter the interface, this is a VERY powerful feature - use sparingly!

local NEW_ICON_TEXTURE = "EsoUI/Art/Miscellaneous/Gamepad/gp_icon_new.dds"

local CATEGORY_ITEM_ACTION_MODE = 1
local ITEM_LIST_ACTION_MODE = 2
local CRAFT_BAG_ACTION_MODE = 3

local INVENTORY_TAB_INDEX = 1
local CRAFT_BAG_TAB_INDEX = 2

local INVENTORY_CATEGORY_LIST = "categoryList"
local INVENTORY_ITEM_LIST = "itemList"
local INVENTORY_CRAFT_BAG_LIST = "craftBagList"


-- This is the structure of an "slotAction" array
local INDEX_ACTION_NAME = 1
local INDEX_ACTION_CALLBACK = 2
local INDEX_ACTION_TYPE = 3
local INDEX_ACTION_VISIBILITY = 4
local INDEX_ACTION_OPTIONS = 5
local PRIMARY_ACTION_KEY = 1

-- All of the callbacks that are possible on the "A" button press have to have CallSecureProtected()
local PRIMARY_ACTION = 1

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

-- The below functions are included from ZO_GamepadInventory.lua
local function MenuEntryTemplateEquality(left, right)
    return left.uniqueId == right.uniqueId
end

local function BUI_GamepadMenuEntryTemplateParametricListFunction(control, distanceFromCenter, continousParametricOffset) end

local function BUI_SharedGamepadEntryLabelSetup(label, data, selected)
    if label then
        label:SetFont("$(GAMEPAD_MEDIUM_FONT)|28|soft-shadow-thick")
        if data.modifyTextType then
            label:SetModifyTextType(data.modifyTextType)
        end

        local labelTxt = data.text

        local dS = data.dataSource
        local bagId = dS.bagId
        local slotIndex = dS.slotIndex
        local isLocked = dS.isPlayerLocked

        if(data.stackCount > 1) then
           labelTxt = labelTxt..zo_strformat(" |cFFFFFF(<<1>>)|r",data.stackCount)
        end

        if(BUI.Settings.Modules["CIM"].attributeIcons) then
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

        if isLocked then
            label:SetAlpha(0.5)
        end

        if ZO_ItemSlot_SetupTextUsableAndLockedColor then
            ZO_ItemSlot_SetupTextUsableAndLockedColor(label, data.meetsUsageRequirements)
        end
    end
end

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

local function SetupItemList(list)
    list:AddDataTemplate("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, BUI_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
end

local function SetupCraftBagList(list)
    list:AddDataTemplate("BUI_GamepadItemSubEntryTemplate", BUI_SharedGamepadEntry_OnSetup, BUI_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
end
local function SetupCategoryList(list)
    list:AddDataTemplate("BUI_GamepadItemEntryTemplate", ZO_SharedGamepadEntry_OnSetup, BUI_GamepadMenuEntryTemplateParametricListFunction)
    --list:AddDataTemplate("BUI_GamepadItemEntryTemplate_Craft", ZO_SharedGamepadEntry_OnSetup, BUI_GamepadMenuEntryTemplateParametricListFunction, nil)
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

function BUI_InventoryUtils_MatchMaterials(itemData)
    return (ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_CRAFTING)) and not ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, ITEMFILTERTYPE_QUICKSLOT)
end

function BUI_InventoryUtils_All(itemData)
    return true
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

        parent:RefreshItemList()
        parent:ToSavedPosition()
    end
end
function BUI_TabBar_OnTabPrev(parent, successful)
    if(successful) then
        parent:SaveListPosition()

        parent.categoryList.targetSelectedIndex = WrapValue(parent.categoryList.targetSelectedIndex - 1, #parent.categoryList.dataList)
        parent.categoryList.selectedIndex = parent.categoryList.targetSelectedIndex
        parent.categoryList.selectedData = parent.categoryList.dataList[parent.categoryList.selectedIndex]

        parent:RefreshItemList()
        parent:ToSavedPosition()
    end
end


function BUI.Inventory.Class:ToSavedPosition()
    if(BUI.Settings.Modules["Inventory"].savePosition) then
        local lastPosition = self.categoryPositions[self.categoryList.selectedIndex]
        if(lastPosition ~= nil) then
            lastPosition = (#self.itemList.dataList > lastPosition) and lastPosition or #self.itemList.dataList
            self.itemList:SetSelectedIndexWithoutAnimation(lastPosition, true, false)
        end
    else
        self.itemList:SetSelectedIndexWithoutAnimation(1, true, false)
    end

    -- Toggle "Switch Slot" with "Assign to Quickslot"
    if self.categoryList.selectedData ~= nil then
        --KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindDescriptor)
        --KEYBIND_STRIP:RemoveKeybindButton(self.switchEquipKeybindDescriptor)

        if not self.categoryList:GetTargetData().onClickDirection then
            self:SwitchActiveList(INVENTORY_ITEM_LIST)
        else
            self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST)
        end

    end
end


function BUI.Inventory.Class:SaveListPosition()
    self.categoryPositions[self.categoryList.selectedIndex] = self._currentList.selectedIndex
end


function BUI.Inventory.Class:InitializeCategoryList()

    self.categoryList = self:AddList("Category", SetupCategoryList)
    self.categoryList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_EMPTY))

    --Match the tooltip to the selected data because it looks nicer
    local function OnSelectedCategoryChanged(list, selectedData)
        self:UpdateCategoryLeftTooltip(selectedData)

        if selectedData.onClickDirection then
            self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST)
        else
            self:SwitchActiveList(INVENTORY_ITEM_LIST)
        end
    end

    self.categoryList:SetOnSelectedDataChangedCallback(OnSelectedCategoryChanged)

    --Match the functionality to the target data
    local function OnTargetCategoryChanged(list, targetData)
        if targetData then
                self.selectedEquipSlot = targetData.equipSlot
                self:SetSelectedItemUniqueId(self:GenerateItemSlotData(targetData))
                self.selectedItemFilterType = targetData.filterType
        else
            self:SetSelectedItemUniqueId(nil)
        end

        self.currentlySelectedData = targetData
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.categoryListKeybindStripDescriptor)
    end

    self.categoryList:SetOnTargetDataChangedCallback(OnTargetCategoryChanged)
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

function BUI.Inventory.Class:IsItemListEmpty(filteredEquipSlot, nonEquipableFilterType)
    local comparator = GetItemDataFilterComparator(filteredEquipSlot, nonEquipableFilterType)
    return SHARED_INVENTORY:IsFilteredSlotDataEmpty(comparator, BAG_BACKPACK, BAG_WORN)
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

function BUI.Inventory.Class:TryEquipItem(inventorySlot)
    local equipType = inventorySlot.dataSource.equipType

    -- Check if the current item is an armour (or two handed, where it doesn't need a dialog menu), if so, then just equip into it's slot
    local armorType = GetItemArmorType(inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex)
    if armorType ~= ARMORTYPE_NONE or equipType == EQUIP_TYPE_TWO_HAND or equipType == EQUIP_TYPE_NECK then
        if equipType == EQUIP_TYPE_TWO_HAND then
            CallSecureProtected("RequestMoveItem",inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex, BAG_WORN, self.equipToMainSlot and EQUIP_SLOT_MAIN_HAND or EQUIP_SLOT_BACKUP_MAIN, 1)
        else
            CallSecureProtected("RequestMoveItem",inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex, BAG_WORN, BUI_GetEquipSlotForEquipType(equipType), 1)
        end
    elseif equipType == EQUIP_TYPE_COSTUME then
        CallSecureProtected("RequestMoveItem",inventorySlot.dataSource.bagId, inventorySlot.dataSource.slotIndex, BAG_WORN, EQUIP_SLOT_COSTUME, 1)
    else
        -- Else, it's a weapon, so show a dialog so the user can pick either slot!
        ZO_Dialogs_ShowDialog(BUI_EQUIP_SLOT_DIALOG, {inventorySlot, self.equipToMainSlot}, {mainTextParams={BUI.Lib.GetString("SI_INV_EQUIPSLOT_MAIN")}}, true)
    end
end

function BUI.Inventory.Class:NewCategoryItem(categoryName, filterType, iconFile, FilterFunct)
    if FilterFunct == nil then
        FilterFunct = ZO_InventoryUtils_DoesNewItemMatchFilterType
    end

    local isListEmpty = self:IsItemListEmpty(nil, filterType)
    if not isListEmpty then
        local name = BUI.Lib.GetString(categoryName)
        local hasAnyNewItems = SHARED_INVENTORY:AreAnyItemsNew(ZO_InventoryUtils_DoesNewItemMatchFilterType, filterType, BAG_BACKPACK)
        local data = ZO_GamepadEntryData:New(name, iconFile, nil, nil, hasAnyNewItems)
        data.filterType = filterType
        data:SetIconTintOnSelection(true)
        self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
        BUI.GenericHeader.AddToList(self.header, data)
        if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
    end
end

function BUI.Inventory.Class:RefreshCategoryList()
    self.categoryList:Clear()
    self.header.tabBar:Clear()


    --for categoryItem in pairs(self.categoryItemCollection) do
    --    self:NewCategoryItem(categoryItem.name, categoryItem.filterType, categoryItem.iconFile, categoryItem.FilterFunct)
    --end

    self:NewCategoryItem("INV_ITEM_ALL", nil, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_all.dds", BUI_InventoryUtils_All)
    self:NewCategoryItem("INV_ITEM_WEAPONS", ITEMFILTERTYPE_WEAPONS, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_weapons.dds")
    self:NewCategoryItem("INV_ITEM_APPAREL", ITEMFILTERTYPE_ARMOR, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_apparel.dds")

    self:NewCategoryItem("INV_ITEM_MATERIALS", ITEMFILTERTYPE_CRAFTING, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds")
    self:NewCategoryItem("INV_ITEM_MISC", ITEMFILTERTYPE_MISCELLANEOUS, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_miscellaneous.dds")

    self:NewCategoryItem("INV_ITEM_CONSUMABLE", ITEMFILTERTYPE_QUICKSLOT, "EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_quickslot.dds")
    -- do
    --     local questCache = SHARED_INVENTORY:GenerateFullQuestCache()
    --     if next(questCache) then
    --         local name = GetString(SI_GAMEPAD_INVENTORY_QUEST_ITEMS)
    --         local iconFile = "/esoui/art/notifications/gamepad/gp_notificationicon_quest.dds"
    --         local data = ZO_GamepadEntryData:New(name, iconFile)
    --         data.filterType = ITEMFILTERTYPE_QUEST
    --         data:SetIconTintOnSelection(true)
    --         self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
    --     --    BUI.GenericHeader.AddToList(self.header, data)
    --         if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
    --     end
    -- end
    do
        local name = "Crafting Bag"
        local iconFile = "/EsoUI/Art/Inventory/Gamepad/gp_inventory_icon_materials.dds"
        local data = ZO_GamepadEntryData:New(name, iconFile)
        data.onClickDirection = "CRAFTBAG"
        data:SetIconTintOnSelection(true)

        local newColor = ZO_ColorDef:New(1, 0.95, 0.5)

        data:SetIconTint(newColor,newColor)

        self.categoryList:AddEntry("BUI_GamepadItemEntryTemplate", data)
        BUI.GenericHeader.AddToList(self.header, data)
        if not self.populatedCategoryPos then self.categoryPositions[#self.categoryPositions+1] = 1 end
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

    self.populatedCategoryPos = true

    self.categoryList:Commit()
    self.header.tabBar:Commit()
end

function BUI.Inventory.Class:InitializeHeader()
    local function UpdateTitleText()
        return self.categoryList:GetTargetData().text
    end

    local tabBarEntries =
        {
            {
                text = GetString(SI_GAMEPAD_INVENTORY_CATEGORY_HEADER),
                callback = function()
                    self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
                end,
            },
            {
                text = GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_HEADER),
                callback = function()
                    self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST)
                end,
            },
        }

    self.categoryHeaderData = {
        tabBarEntries = tabBarEntries,
        tabBarData = { parent = self, onNext = BUI_TabBar_OnTabNext, onPrev = BUI_TabBar_OnTabPrev }

    }

    self.craftBagHeaderData = {
        tabBarEntries = tabBarEntries,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,
    }

    self.itemListHeaderData = {
        titleText = UpdateTitleText,

        data1HeaderText = GetString(SI_GAMEPAD_INVENTORY_AVAILABLE_FUNDS),
        data1Text = UpdateGold,

        data2HeaderText = GetString(SI_GAMEPAD_INVENTORY_ALLIANCE_POINTS),
        data2Text = UpdateAlliancePoints,

        data3HeaderText = GetString(SI_GAMEPAD_INVENTORY_TELVAR_STONES),
        data3Text = UpdateTelvarStones,

        data4HeaderText = GetString(SI_GAMEPAD_INVENTORY_CAPACITY),
        data4Text = UpdateCapacityString,
    }

     BUI.GenericHeader.Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
     BUI.GenericHeader.SetEquipText(self.header, self.equipToMainSlot)

     BUI.GenericHeader.Refresh(self.header, self.categoryHeaderData, ZO_GAMEPAD_HEADER_TABBAR_CREATE)
end

function BUI.Inventory.Class:RefreshCraftBagList()
    self.craftBagList:RefreshList()
end

function BUI.Inventory.Class:RefreshItemList()
    self.itemList:Clear()
    if self.categoryList:IsEmpty() then return end

    local targetCategoryData = self.categoryList:GetTargetData()
    local filteredEquipSlot = targetCategoryData.equipSlot
    local nonEquipableFilterType = targetCategoryData.filterType
    local filteredDataTable

    local isQuestItem = nonEquipableFilterType == ITEMFILTERTYPE_QUEST
    --special case for quest items
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

                itemData.isHiddenByWardrobe = WouldEquipmentBeHidden(itemData.slotIndex or EQUIP_SLOT_NONE)
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
            if itemData.toolIndex then
                remaining, duration = GetQuestToolCooldownInfo(itemData.questIndex, itemData.toolIndex)
            elseif itemData.stepIndex and itemData.conditionIndex then
                remaining, duration = GetQuestItemCooldownInfo(itemData.questIndex, itemData.stepIndex, itemData.conditionIndex)
            end
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
        --if (not data.isJunk and not showJunkCategory) or (data.isJunk and showJunkCategory) or not BUI.Settings.Modules["CIM"].enableJunk then
            self.itemList:AddEntry("BUI_GamepadItemSubEntryTemplate", data)
        --end
    end

    self.itemList:Commit()
end

function BUI.Inventory.Class:RefreshActiveKeybinds()
    if self.currentKeybindDescriptor then
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currentKeybindDescriptor)
    end
end


function BUI.Inventory.Class:InitializeItemList()
    self.itemList = self:AddList("Items", SetupItemList, BUI_VerticalParametricScrollList)

    self.itemList:SetOnSelectedDataChangedCallback(function(list, selectedData)
        self.currentlySelectedData = selectedData

        self:SetSelectedInventoryData(selectedData)

        self:UpdateItemLeftTooltip(selectedData)
        self:PrepareNextClearNewStatus(selectedData)
        self.itemList:RefreshVisible()
        self:UpdateRightTooltip()
        self:RefreshActiveKeybinds()
    end)

    self.itemList.maxOffset = 0
    self.itemList.headerDefaultPadding = 15
    self.itemList.headerSelectedPadding = 0
    self.itemList.universalPostPadding = 5

end

function BUI.Inventory.Class:InitializeCraftBagList()
    local function OnSelectedDataCallback(list, selectedData)
        self.currentlySelectedData = selectedData
        self:UpdateItemLeftTooltip(selectedData)

        local currentList = self:GetCurrentList()
        if currentList == self.craftBagList or ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
            self:SetSelectedInventoryData(selectedData)
            self.craftBagList:RefreshVisible()
        end
        self:RefreshActiveKeybinds()
    end
    ddebug("InitializeCraftBagList")

    local function VendorEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_Inventory_BindSlot(data, slotType, data.slotIndex, data.bagId)
        ZO_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end

    self.craftBagList = self:AddList("CraftBag", true, BUI.Inventory.List, BAG_VIRTUAL, SLOT_TYPE_CRAFT_BAG_ITEM, OnSelectedDataCallback, nil, nil, nil, false, "BUI_GamepadItemSubEntryTemplate", VendorEntryTemplateSetup)
    self.craftBagList:SetNoItemText(GetString(SI_GAMEPAD_INVENTORY_CRAFT_BAG_EMPTY))
    self.craftBagList:SetAlignToScreenCenter(true, 30)
end

function BUI.Inventory.Class:InitializeItemActions()
    self.itemActions = BUI.Inventory.SlotActions:New(KEYBIND_STRIP_ALIGN_LEFT)
end


-- override of ZO_Gamepad_ParametricList_Screen:OnStateChanged
function BUI.Inventory.Class:OnStateChanged(oldState, newState)
    if newState == SCENE_SHOWING then
        self:PerformDeferredInitialize()
        BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)

        --figure out which list to land on
        local listToActivate = self.previousListType or INVENTORY_CATEGORY_LIST
        -- We normally do not want to enter the gamepad inventory on the item list
        -- the exception is if we are coming back to the inventory, like from looting a container
        if listToActivate == INVENTORY_ITEM_LIST and not SCENE_MANAGER:WasSceneOnStack(ZO_GAMEPAD_INVENTORY_SCENE_NAME) then
            listToActivate = INVENTORY_CATEGORY_LIST
        end

        -- switching the active list will handle activating/refreshing header, keybinds, etc.
        self:SwitchActiveList(listToActivate)

        self:ActivateHeader()

        ZO_InventorySlot_SetUpdateCallback(function() self:RefreshItemActions() end)
    elseif newState == SCENE_HIDING then
        ZO_InventorySlot_SetUpdateCallback(nil)
        self:Deactivate()
        self:DeactivateHeader()

    elseif newState == SCENE_HIDDEN then
        BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)

        self.listWaitingOnDestroyRequest = nil
        self:TryClearNewStatusOnHidden()

        self:ClearActiveKeybinds()
        ZO_SavePlayerConsoleProfile()
    end
end


function BUI.Inventory.Class:OnDeferredInitialize()
    local SAVED_VAR_DEFAULTS =
    {
        useStatComparisonTooltip = true,
    }
    self.savedVars = ZO_SavedVars:NewAccountWide("ZO_Ingame_SavedVariables", 2, "GamepadInventory", SAVED_VAR_DEFAULTS)

    self:SetListsUseTriggerKeybinds(true)

    self.categoryPositions = { }
    self.populatedCategoryPos = false
    self.equipToMainSlot = true

    self:InitializeCategoryList()
    self:InitializeItemList()
    self:InitializeCraftBagList()

    self:InitializeHeader()

    self:InitializeKeybindStrip()

    self:InitializeConfirmDestroyDialog()

    self:InitializeItemActions()
    self:InitializeActionsDialog()

    local function RefreshHeader()
        if not self.control:IsHidden() then
            self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
        end
    end

    local function RefreshSelectedData()
        if not self.control:IsHidden() then
            self:SetSelectedInventoryData(self.currentlySelectedData)
        end
    end

    --self:SetActiveKeybinds(self.categoryListKeybindStripDescriptor)

    self:RefreshCategoryList()
    --self:SetCurrentList(self.categoryList)

    self:SetSelectedItemUniqueId(self:GenerateItemSlotData(self.categoryList:GetTargetData()))
    --self.actionMode = CATEGORY_ITEM_ACTION_MODE
    self:RefreshHeader()
    self:ActivateHeader()

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_ALLIANCE_POINT_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, RefreshHeader)
    self.control:RegisterForEvent(EVENT_PLAYER_DEAD, RefreshSelectedData)
    self.control:RegisterForEvent(EVENT_PLAYER_REINCARNATED, RefreshSelectedData)

    local function OnInventoryUpdated(bagId)
        self:MarkDirty()
        local currentList = self:GetCurrentList()
        self:RefreshHeader(BLOCK_TABBAR_CALLBACK)
        if ZO_Dialogs_IsShowing(ZO_GAMEPAD_INVENTORY_ACTION_DIALOG) then
            self:OnUpdate() --don't wait for next update loop in case item was destroyed and scene/keybinds need immediate update
        else
            if currentList == self.categoryList then
            self:RefreshCategoryList()
            elseif currentList == self.itemList then
                -- if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
                --     KEYBIND_STRIP:UpdateKeybindButton(self.quickslotKeybindStripDescriptor)
                -- elseif self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
                --     KEYBIND_STRIP:UpdateKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
                -- end
            end
            RefreshSelectedData() --dialog will refresh selected when it hides, so only do it if it's not showing
        end

    end

    SHARED_INVENTORY:RegisterCallback("FullInventoryUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", OnInventoryUpdated)

    SHARED_INVENTORY:RegisterCallback("FullQuestUpdate", OnInventoryUpdated)
    SHARED_INVENTORY:RegisterCallback("SingleQuestUpdate", OnInventoryUpdated)

end

function BUI.Inventory.Class:Initialize(control)
    GAMEPAD_INVENTORY_ROOT_SCENE = ZO_Scene:New(ZO_GAMEPAD_INVENTORY_SCENE_NAME, SCENE_MANAGER)
    BUI_Gamepad_ParametricList_Screen.Initialize(self, control, ZO_GAMEPAD_HEADER_TABBAR_CREATE, false, GAMEPAD_INVENTORY_ROOT_SCENE)

    -- need this earlier than deferred init so trade can split stacks before inventory is possibly viewed
    self:InitializeSplitStackDialog()

    local function OnCancelDestroyItemRequest()
        if self.listWaitingOnDestroyRequest then
            self.listWaitingOnDestroyRequest:Activate()
            self.listWaitingOnDestroyRequest = nil
        end
        ZO_Dialogs_ReleaseDialog(ZO_GAMEPAD_CONFIRM_DESTROY_DIALOG)
    end

    local function OnUpdate(updateControl, currentFrameTimeSeconds)
       self:OnUpdate(currentFrameTimeSeconds)
    end

    self.trySetClearNewFlagCallback =   function(callId)
                                            self:TrySetClearNewFlag(callId)
                                        end

    local function RefreshVisualLayer()
        if self.scene:IsShowing() then
            self:OnUpdate()
            if self.actionMode == CATEGORY_ITEM_ACTION_MODE then
                self:RefreshCategoryList()
                self:SwitchActiveList(INVENTORY_ITEM_LIST)
            end
        end
    end

    control:RegisterForEvent(EVENT_CANCEL_MOUSE_REQUEST_DESTROY_ITEM, OnCancelDestroyItemRequest)
    control:RegisterForEvent(EVENT_VISUAL_LAYER_CHANGED, RefreshVisualLayer)
    control:SetHandler("OnUpdate", OnUpdate)
end


function BUI.Inventory.Class:RefreshHeader(blockCallback)
    local currentList = self:GetCurrentList()
    local headerData
    if currentList == self.craftBagList then
        headerData = self.craftBagHeaderData
    elseif currentList == self.categoryList then
        headerData = self.categoryHeaderData
    else
        headerData = self.itemListHeaderData
    end

    BUI.GenericHeader.Refresh(self.header, headerData, blockCallback)

    self:RefreshCategoryList()
end

function BUI.Inventory.Class:Select()
    if not self.categoryList:GetTargetData().onClickDirection then
        self:SwitchActiveList(INVENTORY_ITEM_LIST)
    else
        self:SwitchActiveList(INVENTORY_CRAFT_BAG_LIST)
    end
end

function BUI.Inventory.Class:SwitchActiveList(listDescriptor)
	if listDescriptor == self.currentListType then return end

	self.previousListType = self.currentListType
	self.currentListType = listDescriptor

	-- TODO: Better way to handle this?
	if self.previousListType == INVENTORY_ITEM_LIST then
	 	KEYBIND_STRIP:RemoveKeybindButton(self.quickslotKeybindStripDescriptor)
	 	KEYBIND_STRIP:RemoveKeybindButton(self.toggleCompareModeKeybindStripDescriptor)

		self.listWaitingOnDestroyRequest = nil
		self:TryClearNewStatusOnHidden()
		ZO_SavePlayerConsoleProfile()
	end

	GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
	GAMEPAD_TOOLTIPS:Reset(GAMEPAD_RIGHT_TOOLTIP)

	if listDescriptor == INVENTORY_CATEGORY_LIST then
        listDescriptor = INVENTORY_ITEM_LIST
    end

	if listDescriptor == INVENTORY_ITEM_LIST then
		self:SetActiveKeybinds(self.itemFilterKeybindStripDescriptor)

		self:RefreshItemList()

		self:SetCurrentList(self.itemList)

		--if self.selectedItemFilterType == ITEMFILTERTYPE_QUICKSLOT then
		--	KEYBIND_STRIP:AddKeybindButton(self.quickslotKeybindStripDescriptor)
		--	TriggerTutorial(TUTORIAL_TRIGGER_INVENTORY_OPENED_AND_QUICKSLOTS_AVAILABLE)
		--elseif self.selectedItemFilterType == ITEMFILTERTYPE_ARMOR or self.selectedItemFilterType == ITEMFILTERTYPE_WEAPONS then
			--KEYBIND_STRIP:AddKeybindButton(self.toggleCompareModeKeybindStripDescriptor)
		--end

		self:SetSelectedItemUniqueId(self.itemList:GetTargetData())
		self.actionMode = ITEM_LIST_ACTION_MODE
		self:RefreshItemActions()
		self:UpdateRightTooltip()
		self:RefreshHeader(BLOCK_TABBAR_CALLBACK)

	elseif listDescriptor == INVENTORY_CRAFT_BAG_LIST then
		self:SetActiveKeybinds(self.craftBagKeybindStripDescriptor)

        self:SetCurrentList(self.craftBagList)
		self:RefreshCraftBagList()

		self:SetSelectedItemUniqueId(self.craftBagList:GetTargetData())
		self.actionMode = CRAFT_BAG_ACTION_MODE
		self:RefreshItemActions()
		self:RefreshHeader()
		self:ActivateHeader()
		self:LayoutCraftBagTooltip(GAMEPAD_RIGHT_TOOLTIP)

		TriggerTutorial(TUTORIAL_TRIGGER_CRAFT_BAG_OPENED)
	end

	self:RefreshActiveKeybinds()
end

function BUI.Inventory.Class:AddList(name, callbackParam, listClass, ...)

    local listContainer = CreateControlFromVirtual("$(parent)"..name, self.control.container, "BUI_Gamepad_ParametricList_Screen_ListContainer")
    local list = self.CreateAndSetupList(self, listContainer.list, callbackParam, listClass, ...)
	list.alignToScreenCenterExpectedEntryHalfHeight = 15
    self.lists[name] = list

    local CREATE_HIDDEN = true
    self:CreateListFragment(name, CREATE_HIDDEN)
    return list
end


--------------
-- Keybinds --
--------------

function BUI.Inventory.Class:InitializeKeybindStrip()
    self.categoryListKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            order = -500,
            callback = function() self:Select() end,
            visible = function() return not self.categoryList:IsEmpty() end,
        },
        {
            name = GetString(SI_GAMEPAD_INVENTORY_EQUIPPED_MORE_ACTIONS),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                self:ShowActions()
            end,
        },
        {

            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
    }

    --ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.categoryListKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)

    self.itemFilterKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                self:ShowActions()
            end,
        },
        {
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                StackBag(BAG_BACKPACK)
            end,
        },
        {
            name = GetString(SI_ITEM_ACTION_DESTROY),
            keybind = "UI_SHORTCUT_RIGHT_STICK",
            order = 2000,
            disabledDuringSceneHiding = true,

            visible = function()
                local targetData = self.itemList:GetTargetData()
                return self.selectedItemUniqueId ~= nil and ZO_InventorySlot_CanDestroyItem(targetData)
            end,

            callback = function()
                local targetData = self.itemList:GetTargetData()
                if(ZO_InventorySlot_CanDestroyItem(targetData) and ZO_InventorySlot_InitiateDestroyItem(targetData)) then
                    self.itemList:Deactivate()
                    self.listWaitingOnDestroyRequest = self.itemList
                end
            end
        }
    }

    local function ListBackFunction()
        self:SwitchActiveList(INVENTORY_CATEGORY_LIST)
    end
    --ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.itemFilterKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, ListBackFunction)

    self.toggleCompareModeKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_RIGHT,
        name = GetString(SI_GAMEPAD_INVENTORY_TOGGLE_ITEM_COMPARE_MODE),
        keybind = "UI_SHORTCUT_SECONDARY",
        visible = function()
            local targetCategoryData = self.categoryList:GetTargetData()
            if targetCategoryData then
                local equipSlotHasItem = select(2, GetEquippedItemInfo(targetCategoryData.equipSlot))
                return equipSlotHasItem
            end
        end,
        callback = function()
            self.savedVars.useStatComparisonTooltip = not self.savedVars.useStatComparisonTooltip
            self:UpdateRightTooltip()
        end,
    }

    self.quickslotKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        name = GetString(SI_GAMEPAD_ITEM_ACTION_QUICKSLOT_ASSIGN),
        keybind = "UI_SHORTCUT_SECONDARY",
        order = -500,
        callback = function() self:ShowQuickslot() end,
    }

    self.craftBagKeybindStripDescriptor =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = GetString(SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND),
            keybind = "UI_SHORTCUT_TERTIARY",
            order = 1000,
            visible = function()
                return self.selectedItemUniqueId ~= nil
            end,

            callback = function()
                self:ShowActions()
            end,
        },
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.craftBagKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end
