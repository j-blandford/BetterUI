local _

local BANKING_ROW_TEMPLATE = "BUI_GenericEntry_Template"

local LIST_WITHDRAW = 1
local LIST_DEPOSIT  = 2

local CURRENCY = {GOLD = 1, TELVAR = 2}

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
    local fullDesc = GetString("SI_ITEMTYPE", itemData.itemType)
	
	-- Stops types like "Poison" displaying "Poison" twice
	if( fullDesc ~= GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))) then
		fullDesc = fullDesc.." "..GetString("SI_EQUIPTYPE",GetItemLinkEquipType(itemLink))
	end
	
	return fullDesc
end


-- Things to look towards: custom sorting orders
local DEFAULT_GAMEPAD_ITEM_SORT =
{
    itemCategoryName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

local function ItemSortFunc(data1, data2)
     return ZO_TableOrderingFunction(data1, data2, "itemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
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
		if (mmData.avgPrice ~= nil) then
			return mmData.avgPrice*stackCount
		end
	end
	return 0
end

local function SetupListing(control, data)
    local itemQualityColour = ZO_ColorDef:FromInterfaceColor(INTERFACE_COLOR_TYPE_ITEM_QUALITY_COLORS, data.quality)
    local fullItemName = itemQualityColour:Colorize(data.name)..(data.stackCount > 1 and " ("..data.stackCount..")" or "")

    if(BUI.Settings.Modules["CIM"].attributeIcons) then
        local dS = data
        local bagId = dS.bagId
        local slotIndex = dS.slotIndex
        local itemData = GetItemLink(bagId, slotIndex)
		local isLocked = dS.isPlayerLocked
	
		if isLocked then fullItemName = "|t24:24:"..ZO_GAMEPAD_LOCKED_ICON_32.."|t" .. fullItemName end
		
        local setItem, _, _, _, _ = GetItemLinkSetInfo(itemData, false)
        local hasEnchantment, _, _ = GetItemLinkEnchantInfo(itemData)
	
		local currentItemType = GetItemLinkItemType(itemData) --GetItemType(bagId, slotIndex)
		local isRecipeAndUnknown = false
		if (currentItemType == ITEMTYPE_RECIPE) then
			isRecipeAndUnknown = not IsItemLinkRecipeKnown(itemData)
		end
	
		local isUnbound = not IsItemBound(bagId, slotIndex) and not data.stolen and data.quality ~= ITEM_QUALITY_TRASH
	
		if isUnbound then fullItemName = fullItemName.." |t16:16:/esoui/art/guild/gamepad/gp_ownership_icon_guildtrader.dds|t" end
        if(hasEnchantment) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_enchanted.dds|t" end
        if(setItem) then fullItemName = fullItemName.." |t16:16:/BetterUI/Modules/Inventory/Images/inv_setitem.dds|t" end
		if isRecipeAndUnknown then fullItemName = fullItemName.." |t16:16:/esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_provisioning.dds|t" end
    end
    control:GetNamedChild("ItemType"):SetText(string.upper(data.itemCategoryName))
    control:GetNamedChild("Stat"):SetText((data.statValue == 0) and "-" or data.statValue)
    control:GetNamedChild("Icon"):ClearIcons()
    control:GetNamedChild("Label"):SetText(fullItemName)
    control:GetNamedChild("Icon"):AddIcon(data.iconFile)
    control:GetNamedChild("Icon"):SetHidden(false)
    if not data.meetsUsageRequirement then control:GetNamedChild("Icon"):SetColor(1,0,0,1) else control:GetNamedChild("Icon"):SetColor(1,1,1,1) end
	
	if(BUI.Settings.Modules["Inventory"].showMarketPrice) then
		local marketPrice = GetMarketPrice(GetItemLink(data.bagId,data.slotIndex), data.stackCount)
		if(marketPrice ~= 0) then
			control:GetNamedChild("Value"):SetColor(1,0.75,0,1)
			control:GetNamedChild("Value"):SetText(ZO_CurrencyControl_FormatCurrency(math.floor(marketPrice), USE_SHORT_CURRENCY_FORMAT))
		else
			control:GetNamedChild("Value"):SetColor(1,1,1,1)
			control:GetNamedChild("Value"):SetText(data.stackSellPrice)
		end
	else
		control:GetNamedChild("Value"):SetColor(1,1,1,1)
		control:GetNamedChild("Value"):SetText(ZO_CurrencyControl_FormatCurrency(data.stackSellPrice, USE_SHORT_CURRENCY_FORMAT))
	end
end

local function SetupLabelListing(control, data)
    control:GetNamedChild("Label"):SetText(data.label)
end

BUI.Banking.Class = BUI.Interface.Window:Subclass()

function BUI.Banking.Class:New(...)
	return BUI.Interface.Window.New(self, ...)
end

function BUI.Banking.Class:RefreshFooter()
    self.footer.footer:GetNamedChild("DepositButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_all.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))))
    self.footer.footer:GetNamedChild("WithdrawButtonSpaceLabel"):SetText(zo_strformat("|t24:24:/esoui/art/icons/mapkey/mapkey_bank.dds|t <<1>>",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BANK), GetBagSize(BAG_BANK))))
    if(self.currentMode == LIST_WITHDRAW) then
        self.footerFragment.control:GetNamedChild("Data1Value"):SetText(BUI.DisplayNumber(GetBankedCurrencyAmount(CURT_MONEY)))
        self.footerFragment.control:GetNamedChild("Data2Value"):SetText(BUI.DisplayNumber(GetBankedCurrencyAmount(CURT_TELVAR_STONES)))
    else
        self.footerFragment.control:GetNamedChild("Data1Value"):SetText(BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_MONEY)))
        self.footerFragment.control:GetNamedChild("Data2Value"):SetText(BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_TELVAR_STONES)))
    end
end

local function OnItemSelectedChange(self, list, selectedData)
    -- Check if we are on the "Deposit/withdraw" gold/telvar row

    if(selectedData.label ~= nil) then
        -- Yes! We are, so add the "withdraw/deposit gold/telvar" keybinds here
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.withdrawDepositKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currencyKeybinds)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.currencyKeybinds)

        GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_LEFT_TOOLTIP)
    else
        -- We are not, add the "withdraw/deposit" keybinds here
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencyKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
        KEYBIND_STRIP:UpdateKeybindButtonGroup(self.withdrawDepositKeybinds)

        GAMEPAD_TOOLTIPS:LayoutBagItem(GAMEPAD_LEFT_TOOLTIP, selectedData.bagId, selectedData.slotIndex)
    end
end

function BUI.Banking.Class:Initialize(tlw_name, scene_name)
	BUI.Interface.Window.Initialize(self, tlw_name, scene_name)

	self:InitializeKeybind()
    self:InitializeList()

    -- Setup data templates of the lists
    self:SetupList(BANKING_ROW_TEMPLATE, SetupListing)
    self:AddTemplate("BUI_HeaderRow_Template",SetupLabelListing)

    self.currentMode = LIST_WITHDRAW
    self.lastPositions = { [LIST_WITHDRAW] = 1, [LIST_DEPOSIT] = 1 }

    self.selectedDataCallback = OnItemSelectedChange

    -- this is essentially a way to encapsulate a function which allows us to override "selectedDataCallback" but still keep some logic code
    local function SelectionChangedCallback(list, selectedData)
        local selectedControl = list:GetSelectedControl()
        if self.selectedDataCallback then
            self:selectedDataCallback(selectedControl, selectedData)
        end
        if selectedControl and selectedControl.bagId then
            SHARED_INVENTORY:ClearNewStatus(selectedControl.bagId, selectedControl.slotIndex)
            self:GetParametricList():RefreshVisible()
        end
    end

    -- these are event handlers which are specific to the banking interface. Handling the events this way encapsulates the banking interface
    -- these local functions are essentially just router functions to other functions within this class. it is done in this way to allow for
    -- us to access this classes' members (through "self")
    local function UpdateItems_Handler()
        self:RefreshFooter()
        self:RefreshList()
    end

    local function UpdateSingle_Handler(eventId, bagId, slotId, isNewItem, itemSound)
        self:UpdateSingleItem(bagId, slotId)
        self:selectedDataCallback(self.list:GetSelectedControl(), self.list:GetSelectedData())
    end

    local function UpdateCurrency_Handler()
        self:RefreshFooter()
    end

    local function OnEffectivelyShown()
        if self.isDirty then
            self:RefreshList()
        elseif self.selectedDataCallback then
            self:selectedDataCallback(self.list:GetSelectedControl(), self.list:GetSelectedData())
        end
        self.list:Activate()
	
		if wykkydsToolbar then
			wykkydsToolbar:SetHidden(true)
		end

        self.control:RegisterForEvent(EVENT_INVENTORY_FULL_UPDATE, UpdateItems_Handler)
        self.control:RegisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE, UpdateSingle_Handler)
    end

    local function OnEffectivelyHidden()
        self.list:Deactivate()
        self.selector:Deactivate()

        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        GAMEPAD_TOOLTIPS:Reset(GAMEPAD_LEFT_TOOLTIP)
	
		if wykkydsToolbar then
			wykkydsToolbar:SetHidden(false)
		end

        self.control:UnregisterForEvent(EVENT_INVENTORY_FULL_UPDATE)
        self.control:UnregisterForEvent(EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
	end

    local selectorContainer = self.control:GetNamedChild("Container"):GetNamedChild("InputContainer")
    self.selector = ZO_CurrencySelector_Gamepad:New(selectorContainer:GetNamedChild("Selector"))
	self.selector:SetClampValues(true)
	self.selectorCurrency = selectorContainer:GetNamedChild("CurrencyTexture")

    self.list:SetOnSelectedDataChangedCallback(SelectionChangedCallback)

    self.control:SetHandler("OnEffectivelyShown", OnEffectivelyShown)
    self.control:SetHandler("OnEffectivelyHidden", OnEffectivelyHidden)

    -- Always-running event listeners, these don't add much overhead
    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, UpdateCurrency_Handler)
    self.control:RegisterForEvent(EVENT_BANKED_MONEY_UPDATE, UpdateCurrency_Handler)
    self.control:RegisterForEvent(EVENT_TELVAR_STONE_UPDATE, UpdateCurrency_Handler)
    self.control:RegisterForEvent(EVENT_BANKED_TELVAR_STONES_UPDATE, UpdateCurrency_Handler)
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


function BUI.Banking.Class:ActivateSpinner()
    self.spinner:SetHidden(false)
    self.spinner:Activate()
    if(self:GetList() ~= nil) then
        self:GetList():Deactivate()

        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
    end
end

function BUI.Banking.Class:DeactivateSpinner()
    self.spinner:SetValue(1)
    self.spinner:SetHidden(true)
    self.spinner:Deactivate()
    if(self:GetList() ~= nil) then
        self:GetList():Activate()
        KEYBIND_STRIP:RemoveAllKeyButtonGroups()
        KEYBIND_STRIP:AddKeybindButtonGroup(self.withdrawDepositKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
    end
end


function BUI.Banking.Class:MoveItem(list, quantity)
	local bag, index = ZO_Inventory_GetBagAndIndex(list:GetSelectedData())
    local stackCount = GetSlotStackSize(bag, index)

	local toBag = self.currentMode == LIST_WITHDRAW and BAG_BACKPACK or BAG_BANK
	local fromBag = self.currentMode == LIST_WITHDRAW and BAG_BANK or BAG_BACKPACK

	-- Check to see if we're calling this function from within the spinner class...
	if(quantity == nil) then
		-- We're not, so either (a) move the item, or (b) display the spinner
	    if stackCount > 1 then
		    self:UpdateSpinnerConfirmation(true, self.list)
		    self:SetSpinnerValue(list:GetSelectedData().stackCount, list:GetSelectedData().stackCount)
		else
			local nextSlot = FindEmptySlotInBag(toBag)
	    	CallSecureProtected("RequestMoveItem", fromBag, index, toBag, nextSlot, 1)
		end
	else
		-- We're in the spinner! Confirm the move here :)
		local nextSlot = FindEmptySlotInBag(toBag)
    	CallSecureProtected("RequestMoveItem", fromBag, index, toBag, nextSlot, quantity)
        self:UpdateSpinnerConfirmation(false, self.list)
	end
end

function BUI.Banking.Class:CancelWithdrawDeposit(list)
    if self.confirmationMode then
        self:UpdateSpinnerConfirmation(DEACTIVATE_SPINNER, list)
    else
        SCENE_MANAGER:HideCurrentScene()
    end
end

function BUI.Banking.Class:DisplaySelector(currencyType)
    local currency_max

    if(self.currentMode == LIST_DEPOSIT) then
        currency_max = GetCarriedCurrencyAmount((currencyType == CURRENCY.GOLD) and CURT_MONEY or CURT_TELVAR_STONES)
    else
        currency_max = GetBankedCurrencyAmount((currencyType == CURRENCY.GOLD) and CURT_MONEY or CURT_TELVAR_STONES)
    end

    -- Does the player actually have anything that can be transferred?
    if(currency_max ~= 0) then
        self.selector:SetMaxValue(currency_max)
        self.selector:SetClampValues(0, currency_max)
        self.selector.control:GetParent():SetHidden(false)
	
		local CURRENCY_TYPE_TO_TEXTURE =
		{
			[CURRENCY.GOLD] = "EsoUI/Art/currency/gamepad/gp_gold.dds",
			[CURRENCY.TELVAR] = "EsoUI/Art/currency/gamepad/gp_telvar.dds",
		}
	
		self.selectorCurrency:SetTexture(CURRENCY_TYPE_TO_TEXTURE[currencyType])
	
        self.selector:Activate()
        self.list:Deactivate()

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencyKeybinds)
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.coreKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.currencySelectorKeybinds)
    else
        -- No, display an alert
        ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, "Not enough funds available for transfer.")
    end
end

function BUI.Banking.Class:HideSelector()
    self.selector.control:GetParent():SetHidden(true)
    self.selector:Deactivate()
    self.list:Activate()

    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.currencySelectorKeybinds)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.currencyKeybinds)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
end

function BUI.Banking.Class:CreateListTriggerKeybindDescriptors(list)
    local leftTrigger = {
        keybind = "UI_SHORTCUT_LEFT_TRIGGER",
        ethereal = true,
        callback = function()
            local list = self.list
            if not list:IsEmpty() then
                list:SetSelectedIndex(list.selectedIndex-tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
            end
        end
    }
    local rightTrigger = {
        keybind = "UI_SHORTCUT_RIGHT_TRIGGER",
        ethereal = true,
        callback = function()
			local list = self.list
            if not list:IsEmpty() then
                list:SetSelectedIndex(list.selectedIndex+tonumber(BUI.Settings.Modules["CIM"].triggerSpeed))
            end
        end,
    }
    return leftTrigger, rightTrigger
end

function BUI.Banking.Class:InitializeKeybind()
	if not BUI.Settings.Modules["Banking"].m_enabled then
		return
	end
	
	self.coreKeybinds = {
                alignment = KEYBIND_STRIP_ALIGN_LEFT,
		        {
		            name = "Toggle List",
		            keybind = "UI_SHORTCUT_SECONDARY",
		            callback = function()
		                self:ToggleList(self.currentMode == LIST_DEPOSIT)
		            end,
		            visible = function()
		                return true
		            end,
		            enabled = true,
		        },
                {
            keybind = "UI_SHORTCUT_TERTIARY",
            name = function()
                local cost = GetNextBankUpgradePrice()
                if GetCurrentMoney() >= cost then
                    return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_CurrencyControl_FormatCurrency(cost), GOLD_ICON_24)
                end
                return zo_strformat(SI_BANK_UPGRADE_TEXT, ZO_ERROR_COLOR:Colorize(ZO_CurrencyControl_FormatCurrency(cost)), GOLD_ICON_24)
            end,
            visible = function()
                return IsBankUpgradeAvailable()
            end,
            callback = function()
                if GetNextBankUpgradePrice() > GetCurrentMoney() then
                    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, GetString(SI_BUY_BANK_SPACE_CANNOT_AFFORD))
                else
                    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.mainKeybindStripDescriptor)
                    DisplayBankUpgrade()
                end
            end
        },
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_ITEM_ACTION_STACK_ALL),
            keybind = "UI_SHORTCUT_LEFT_STICK",
            order = 1500,
            disabledDuringSceneHiding = true,
            callback = function()
                if(self.currentMode == LIST_WITHDRAW) then
                    StackBag(BAG_BANK)
                else
                    StackBag(BAG_BACKPACK)
                end
            end,
        },
	}

    self.withdrawDepositKeybinds = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
                {
                    name = function() return (self.currentMode == LIST_WITHDRAW) and GetString(SI_BUI_BANKING_WITHDRAW) or GetString(SI_BUI_BANKING_DEPOSIT) end,
                    keybind = "UI_SHORTCUT_PRIMARY",
                    callback = function()
                        self:SaveListPosition()
                        self:MoveItem(self.list)
                        --self:RefreshList()
                    end,
                    visible = function()
                        return true
                    end,
                    enabled = true,
                },
    }

    self.currencySelectorKeybinds =
    {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = "CONFIRM AMOUNT",
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return true
            end,
            callback = function()
                local amount = self.selector:GetValue()
                if(self.currentMode == LIST_WITHDRAW) then
                    if(self:GetList().selectedData.currencyType == CURRENCY.GOLD) then
                        WithdrawCurrencyFromBank(CURT_MONEY, amount)
                    else
                        WithdrawCurrencyFromBank(CURT_TELVAR_STONES, amount)
                    end
                else
                    if(self:GetList().selectedData.currencyType == CURRENCY.GOLD) then
                        DepositCurrencyIntoBank(CURT_MONEY, amount)
                    else
                        DepositCurrencyIntoBank(CURT_TELVAR_STONES, amount)
                    end
                end
                self:HideSelector()
                self:RefreshFooter()
            end,
        }
    }

    self.currencyKeybinds = {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
                {
                    name = function() return self:GetList().selectedData.label end,
                    keybind = "UI_SHORTCUT_PRIMARY",
                    callback = function()
                        self:SaveListPosition()
                        self:DisplaySelector(self:GetList().selectedData.currencyType)
                    end,
                    visible = function()
                        return true
                    end,
                    enabled = true,
                },
    }


	ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.coreKeybinds, GAME_NAVIGATION_TYPE_BUTTON) -- "Back"
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.currencySelectorKeybinds, GAME_NAVIGATION_TYPE_BUTTON, function() self:HideSelector() end)

	self.triggerSpinnerBinds = {}
	local leftTrigger, rightTrigger = self:CreateListTriggerKeybindDescriptors(self.list)
    table.insert(self.coreKeybinds, leftTrigger)
    table.insert(self.coreKeybinds, rightTrigger)


	self.spinnerKeybindStripDescriptor = {
        alignment = KEYBIND_STRIP_ALIGN_LEFT,
        {
            name = "Confirm",
            keybind = "UI_SHORTCUT_PRIMARY",
            callback = function()
            	self:SaveListPosition()
		        self:MoveItem(self.list, self.spinner:GetValue())
            end,
            visible = function()
                return true
            end,
            enabled = true,
        },
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.spinnerKeybindStripDescriptor,
                                                    GAME_NAVIGATION_TYPE_BUTTON,
                                                    function()
                                                        local list = self.list
                                                        self:CancelWithdrawDeposit(list)
                                                        KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
                                                    end)
end

function BUI.Banking.Class:SaveListPosition()
	-- Able to return to the current position again!
	self.lastPositions[self.currentMode] = self.list.selectedIndex
end

function BUI.Banking.Class:ReturnToSaved()
    local lastPosition = self.lastPositions[self.currentMode]

    self.list:SetSelectedIndexWithoutAnimation(lastPosition, true, false)
end

function BUI.Banking.Class:RefreshList()
	self.list:Clear()

    -- We have to add 2 rows to the list, one for Withdraw/Deposit GOLD and one for Withdraw/Deposit TEL-VAR
    local wdString = self.currentMode == LIST_WITHDRAW and "WITHDRAW" or "DEPOSIT"
    self.list:AddEntry("BUI_HeaderRow_Template", {label="|cFFBF00"..wdString.." GOLD|r", currencyType = CURRENCY.GOLD}, 0, 0, 0, 0)
    self.list:AddEntry("BUI_HeaderRow_Template", {label="|c0066FF"..wdString.." TEL VAR|r", currencyType = CURRENCY.TELVAR}, 0, 0, 0, 0)


	local current_bag = (self.currentMode == LIST_WITHDRAW) and BAG_BANK or BAG_BACKPACK

	local slots = {}
    local bagSlots = GetBagSize(current_bag)
    for slotIndex = 0, bagSlots - 1 do
        local slotData = SHARED_INVENTORY:GenerateSingleSlotData(current_bag, slotIndex)
        if slotData then
                slotData.itemCategoryName = GetBestItemCategoryDescription(slotData)
                slots[#slots + 1] = slotData
        end
    end

    table.sort(slots, ItemSortFunc)

    for i, itemData in ipairs(slots) do
    	if not itemData.stolen then -- can't deposit stolen items
	        self:AddEntryToList(itemData)
	    end
    end
    self:ReturnToSaved()
    self:RefreshFooter()
end

-- Go through and get the item which has been passed to us through the event
function BUI.Banking.Class:UpdateSingleItem(bagId, slotIndex)
    if GetSlotStackSize(bagId, slotIndex) > 0 then
        self.list:RefreshVisible()
        return
    end
    
    for index = 1, #self.list.dataList do
        if self.list.dataList[index].bagId == bagId and self.list.dataList[index].slotIndex == slotIndex then
            self:RemoveItemStack(index)
            break
        end
    end
end

-- This is the final function for the Event "EVENT_INVENTORY_SINGLE_SLOT_UPDATE".
function BUI.Banking.Class:RemoveItemStack(itemIndex)

    if(itemIndex >= #self.list.dataList) then
      self.list:MovePrevious()
    end
    table.remove(self.list.dataList,itemIndex)
    table.remove(self.list.templateList,itemIndex)
    table.remove(self.list.prePadding,itemIndex)
    table.remove(self.list.postPadding,itemIndex)
    table.remove(self.list.preSelectedOffsetAdditionalPadding,itemIndex)
    table.remove(self.list.postSelectedOffsetAdditionalPadding,itemIndex)
    table.remove(self.list.selectedCenterOffset,itemIndex)

    self.list:RefreshVisible()
end

function BUI.Banking.Class:ToggleList(toWithdraw)
	self:SaveListPosition()

	self.currentMode = toWithdraw and LIST_WITHDRAW or LIST_DEPOSIT
	local footer = self.footer:GetNamedChild("Footer")
	if(self.currentMode == LIST_WITHDRAW) then
		footer:GetNamedChild("SelectBg"):SetTextureRotation(0)

		footer:GetNamedChild("DepositButtonLabel"):SetColor(0.26,0.26,0.26,1)
		footer:GetNamedChild("WithdrawButtonLabel"):SetColor(1,1,1,1)
	else
		footer:GetNamedChild("SelectBg"):SetTextureRotation(3.1415)

		footer:GetNamedChild("DepositButtonLabel"):SetColor(1,1,1,1)
		footer:GetNamedChild("WithdrawButtonLabel"):SetColor(0.26,0.26,0.26,1)
	end
	KEYBIND_STRIP:UpdateKeybindButtonGroup(self.coreKeybinds)
	--KEYBIND_STRIP:UpdateKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
	self:RefreshList()
end

function BUI.Banking.Init()
    BUI.Banking.Window = BUI.Banking.Class:New("BUI_TestWindow", BUI_TEST_SCENE)
    BUI.Banking.Window:SetTitle("|c0066FFBank|r")

    -- Set the column headings up, maybe put them into a table?
    BUI.Banking.Window:AddColumn("Name",20)
    BUI.Banking.Window:AddColumn("Type",515)
    BUI.Banking.Window:AddColumn("Stat",705)
    BUI.Banking.Window:AddColumn("Value",775)

    BUI.Banking.Window:RefreshVisible()

    SCENE_MANAGER.scenes['gamepad_banking'] = SCENE_MANAGER.scenes['BUI_BANKING']
	
	if ((not USE_SHORT_CURRENCY_FORMAT ~= nil) and BUI.Settings.Modules["Inventory"].useShortFormat ~= nil) then
		USE_SHORT_CURRENCY_FORMAT = BUI.Settings.Modules["Inventory"].useShortFormat
	end

    --tw = BUI.Banking.Window --dev mode
end
