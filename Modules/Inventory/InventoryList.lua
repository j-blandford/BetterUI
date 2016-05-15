local TEXTURE_EQUIP_ICON = "BetterUI/Modules/Inventory/Images/inv_equip.dds"
local TEXTURE_EQUIP_BACKUP_ICON = "BetterUI/Modules/Inventory/Images/inv_equip_backup.dds"
local TEXTURE_EQUIP_SLOT_ICON = "BetterUI/Modules/Inventory/Images/inv_equip_quickslot.dds"

local DEFAULT_GAMEPAD_ITEM_SORT =
{
    bestGamepadItemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}


function BUI_Inventory_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "bestGamepadItemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

function BUI_SharedGamepadEntryLabelSetup(label, data, selected)
    if label then
        label:SetFont("$(GAMEPAD_MEDIUM_FONT)|28|soft-shadow-thick")
        if data.modifyTextType then
            label:SetModifyTextType(data.modifyTextType)
        end

        local dS = data.dataSource
        local bagId = dS.bagId
        local slotIndex = dS.slotIndex
        local isLocked = dS.isPlayerLocked

        local labelTxt = ""

        if isLocked then labelTxt = "|t24:24:"..ZO_GAMEPAD_LOCKED_ICON_32.."|t" end

        labelTxt = labelTxt .. data.text

        if(data.stackCount > 1) then
           labelTxt = labelTxt..zo_strformat(" |cFFFFFF(<<1>>)|r",data.stackCount)
        end

        if(BUI.Settings.Modules["CIM"].attributeIcons) then
            local itemData = GetItemLink(bagId, slotIndex)

            local setItem, _, _, _, _ = GetItemLinkSetInfo(itemData, false)
            local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemData)

            if data.stolen then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_stolen.dds|t" end
            if hasEnchantment then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
            if setItem then labelTxt = labelTxt.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
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

function BUI_IconSetup(statusIndicator, equippedIcon, data)

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
            equippedIcon:SetTexture(TEXTURE_EQUIP_BACKUP_ICON)
        else
            equippedIcon:SetTexture(TEXTURE_EQUIP_ICON)
        end
        if equipType == EQUIP_TYPE_INVALID then
            equippedIcon:SetTexture(TEXTURE_EQUIP_SLOT_ICON)
        end
        equippedIcon:SetHidden(false)
    else
        equippedIcon:SetHidden(true)
    end
end

function BUI_SharedGamepadEntryIconSetup(icon, stackCountLabel, data, selected)
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

function BUI_Cooldown(control, remaining, duration, cooldownType, timeType, useLeadingEdge, alpha, desaturation, preservePreviousCooldown)
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

function BUI_CooldownSetup(control, data)
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

function BUI_SharedGamepadEntry_OnSetup(control, data, selected, reselectingDuringRebuild, enabled, active)
    BUI_SharedGamepadEntryLabelSetup(control.label, data, selected)

    control:GetNamedChild("ItemType"):SetText(string.upper(data.bestGamepadItemCategoryName))
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

-- END LOCAL FUNCTION DEFINITIONS

BUI.Inventory.List = ZOS_GamepadInventoryList:Subclass()

function BUI.Inventory.List:New(...)
    local object = ZOS_GamepadInventoryList.New(self, ...)
    return object
end

function BUI.Inventory.List:Initialize(control, inventoryType, slotType, selectedDataCallback, entrySetupCallback, categorizationFunction, sortFunction, useTriggers, template, templateSetupFunction)
    self.control = control
    self.inventoryType = inventoryType
    self.selectedDataCallback = selectedDataCallback
    self.entrySetupCallback = entrySetupCallback
    self.categorizationFunction = categorizationFunction
    self.sortFunction = BUI_Inventory_DefaultItemSortComparator
    self.dataBySlotIndex = {}
    self.isDirty = true
    self.useTriggers = (useTriggers ~= false) -- nil => true
    self.template = template or DEFAULT_TEMPLATE

    local function VendorEntryTemplateSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
        ZO_Inventory_BindSlot(data, slotType, data.slotIndex, data.bagId)
        BUI_SharedGamepadEntry_OnSetup(control, data, selected, selectedDuringRebuild, enabled, activated)
    end

    self.list = BUI_VerticalParametricScrollList:New(self.control)
    self.list:AddDataTemplate(self.template, templateSetupFunction or VendorEntryTemplateSetup, ZO_GamepadMenuEntryTemplateParametricListFunction)

	self.list.maxOffset = 0
    self.list.headerDefaultPadding = 15
    self.list.headerSelectedPadding = 0
    self.list.universalPostPadding = 5

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
                    itemData.bestGamepadItemCategoryName = GetBestItemCategoryDescription(itemData)
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

function BUI.Inventory.List:GenerateSlotTable()
    local slots = {}

    local bagId = self.inventoryType
    local slotIndex = ZO_GetNextBagSlotIndex(bagId)
    while slotIndex do
        self:AddSlotDataToTable(slots, slotIndex)
        slotIndex = ZO_GetNextBagSlotIndex(bagId, slotIndex)
    end

    table.sort(slots, self.sortFunction or ItemSortFunc)
    return slots
end

-- this function is a VERY basic generic refresh, with no form of sorting or specific interface information
-- if you want to use BUI.Inventory.List, it will be very useful if you OVERWRITE THIS METHOD!
function BUI.Inventory.List:RefreshList()
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

		if itemData.bestGamepadItemCategoryName ~= currentBestCategoryName then
			currentBestCategoryName = itemData.bestGamepadItemCategoryName
			entry:SetHeader(currentBestCategoryName)
		end

        self.list:AddEntry(self.template, entry)

        self.dataBySlotIndex[itemData.slotIndex] = entry
    end

    self.list:Commit()
end
