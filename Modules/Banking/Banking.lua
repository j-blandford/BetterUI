local _

local BANKING_ROW_TEMPLATE = "BUI_GenericEntry_Template"

local LIST_WITHDRAW = 1
local LIST_DEPOSIT  = 2

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

local function BUI_GamepadMenuEntryTemplateParametricListFunction(control, distanceFromCenter, continousParametricOffset) end

local function SetupListing(control, data)
    local itemQualityColour = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)
    local fullItemName = itemQualityColour:Colorize(data.name)..(data.stackCount > 1 and " ("..data.stackCount..")" or "")

    if(BUI.Settings.Modules["CIM"].attributeIcons) then
        local dS = data
        local bagId = dS.bagId
        local slotIndex = dS.slotIndex
        local itemData = GetItemLink(bagId, slotIndex)

        local setItem, _, _, _, _ = GetItemLinkSetInfo(itemData, false)
        local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemData)
    
        if(data.stolen) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_stolen.dds|t" end
        if(hasEnchantment) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
        if(setItem) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
    end
    control:GetNamedChild("ItemType"):SetText(string.upper(GetBestItemCategoryDescription(data)))
    control:GetNamedChild("Stat"):SetText((data.statValue == 0) and "-" or data.statValue)
    control:GetNamedChild("Icon"):ClearIcons()
    control:GetNamedChild("Label"):SetText(fullItemName)
    control:GetNamedChild("Icon"):AddIcon(data.iconFile)
    control:GetNamedChild("Icon"):SetHidden(false)
    control:GetNamedChild("Value"):SetText(data.stackSellPrice)
end

BUI.Banking.Class = BUI.Interface.Window:Subclass()

function BUI.Banking.Class:New(...)
	return BUI.Interface.Window.New(self, ...)
end

local function OnCloseBank()
    if IsInGamepadPreferredMode() then
        SCENE_MANAGER:Hide(BUI_TEST_SCENE_NAME)
    end
end

function BUI.Banking.Class:Initialize(tlw_name, scene_name)
	BUI.Interface.Window.Initialize(self, tlw_name, scene_name)

	self:InitializeKeybind()
    self:InitializeList()
    self:SetupList(BANKING_ROW_TEMPLATE, SetupListing)

    self.currentMode = LIST_WITHDRAW

    local function OnOpenBank()
        if IsInGamepadPreferredMode() then
            --self.firstOpenedModeIndex = MODE_WITHDRAW
            SCENE_MANAGER:Show(BUI_TEST_SCENE_NAME)
        end
    end
    
    -- this is essentially a way to encapsulate a function which allows us to override "selectedDataCallback" but still keep some logic code
    local function SelectionChangedCallback(list, selectedData)
        local selectedControl = list:GetSelectedControl()
        if self.selectedDataCallback then
            self.selectedDataCallback(selectedControl, selectedData)
        end
        if selectedControl and selectedControl.bagId then
            SHARED_INVENTORY:ClearNewStatus(selectedControl.bagId, selectedControl.slotIndex)
            self:GetParametricList():RefreshVisible()
        end
    end

    local function OnEffectivelyShown()
        if self.isDirty then
            self:RefreshList()
        elseif self.selectedDataCallback then
            self.selectedDataCallback(self.list:GetSelectedControl(), self.list:GetSelectedData())
        end
        self.list:Activate()
    end

    local function OnEffectivelyHidden()
        self.list:Deactivate()
    end

    local function RefreshInventory()
    	self:RefreshList()
    end

    self.list:SetOnSelectedDataChangedCallback(SelectionChangedCallback)

    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    self.control:RegisterForEvent(EVENT_OPEN_BANK, OnOpenBank)
    self.control:RegisterForEvent(EVENT_CLOSE_BANK, OnCloseBank)

    self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, RefreshInventory)
    self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, RefreshInventory)
	--self.header:
end

-- Thanks to Ayantir for the following method to quickly return the next free slotIndex!
local tinyBagCache = {
    [BAG_BACKPACK] = {},
    [BAG_BANK] = {},
}

-- Thanks Merlight & circonian, FindFirstEmptySlotInBag don't refresh in realtime.
local function FindEmptySlotInBag(bagId)
    for slotIndex = 0, (GetBagSize(bagId) - 1) do
        if not SHARED_INVENTORY.bagCache[bagId][slotIndex] and not tinyBagCache[bagId][slotIndex] then
            tinyBagCache[bagId][slotIndex] = true
            return slotIndex
        end
    end
    return nil
end

function BUI.Banking.Class:WithdrawItem(list, toBag)
	local bag, index = ZO_Inventory_GetBagAndIndex(list:GetSelectedData())
	local stackCountBackpack, stackCountBank = GetItemLinkStacks(GetItemLink(bag, index))

    if(stackCountBank > 1) then
	    self:UpdateSpinnerConfirmation(true, self.list)
	    self:SetSpinnerValue(list:GetSelectedData().stackCount, list:GetSelectedData().stackCount)
	else
		local nextSlot = FindEmptySlotInBag(BAG_BACKPACK)
    	CallSecureProtected("RequestMoveItem", BAG_BANK, index, BAG_BACKPACK, nextSlot, 1)
    	self:RefreshList()
	end

end

function BUI.Banking.Class:CancelWithdrawDeposit(list)
    if self.confirmationMode then
        self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, list)
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

function BUI.Banking.Class:CreateListTriggerKeybindDescriptors(list)
    local leftTrigger = {
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        callback = function()
            ddebug("LEFT TRIGGERED")
        end
    }
    local rightTrigger = {
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        callback = function()
            ddebug("RIGHT TRIGGERED")
        end,
    }
    return leftTrigger, rightTrigger
end

function BUI.Banking.Class:InitializeKeybind()
	self.coreKeybinds = {
		alignment = KEYBIND_STRIP_ALIGN_LEFT,
		        {
		            name = BUI.Lib.GetString("BANKING_WITHDRAW"),
		            keybind = "UI_SHORTCUT_PRIMARY",
		            callback = function()
		                --local selectedData = self:GetList():GetSelectedData()

		                self:WithdrawItem(self.list, BAG_BACKPACK)
		                --self:RefreshList()
		            end,
		            visible = function()
		                return true
		            end,
		            enabled = true,
		        },
	}
	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.coreKeybinds, GAME_NAVIGATION_TYPE_BUTTON) -- "Back"

	self.triggerSpinnerBinds = {}
	local leftTrigger, rightTrigger = self:CreateListTriggerKeybindDescriptors(self.list)
    table.insert(self.triggerSpinnerBinds, leftTrigger)
    table.insert(self.triggerSpinnerBinds, rightTrigger)


	self.spinnerKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        coreKeybinds,
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.spinnerKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function()
                                                        local list = self.list
                                                        self:CancelWithdrawDeposit(list)
                                                    end)
end

function BUI.Banking.Class:RefreshList()
	self.list:Clear()
	local slots = {}
    local bagSlots = GetBagSize(BAG_BANK)
    for slotIndex = 0, bagSlots - 1 do
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(BAG_BANK, slotIndex)
        if slotData then
                slots[#slots + 1] = slotData
        end
    end

    for i, itemData in ipairs(slots) do
        self:AddEntryToList(itemData)
        -- testWindow:.dataBySlotIndex[itemData.slotIndex] = entry
    end
end

function BUI.Banking.Class:ToggleList()
	self.currentMode = (self.currentMode == LIST_WITHDRAW) and LIST_DEPOSIT or LIST_WITHDRAW
	local footer = self.footer:GetNamedChild("Footer")
	if(self.currentMode == LIST_WITHDRAW) then
		footer:GetNamedChild("SelectBg"):SetTextureRotation(0)
		footer:GetNamedChild("Select"):SetTextureRotation(0)
	else
		footer:GetNamedChild("SelectBg"):SetTextureRotation(3.1415)
		footer:GetNamedChild("Select"):SetTextureRotation(3.1415)
	end
end

function BUI.Banking.Init()
    BUI.Banking.Window = BUI.Banking.Class:New("BUI_TestWindow", BUI_TEST_SCENE)
    BUI.Banking.Window:SetTitle("Bank")

    -- Set the column headings up, maybe put them into a table?
    BUI.Banking.Window:AddColumn("Name",10)
    BUI.Banking.Window:AddColumn("Type",515)
    BUI.Banking.Window:AddColumn("Stat",705)
    BUI.Banking.Window:AddColumn("Value",775)

    BUI.Banking.Window.selectedDataCallback = function(control, data) GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, data.bagId, data.slotIndex) end

    BUI.Banking.Window:RefreshVisible()

    tw = BUI.Banking.Window
end