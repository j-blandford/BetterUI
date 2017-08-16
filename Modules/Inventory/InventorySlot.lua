INVENTORY_SLOT_ACTIONS_USE_CONTEXT_MENU = true
INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU = false

local INDEX_ACTION_NAME = 1
local INDEX_ACTION_CALLBACK = 2
local INDEX_ACTION_TYPE = 3
local INDEX_ACTION_VISIBILITY = 4
local INDEX_ACTION_OPTIONS = 5

local PRIMARY_ACTION_KEY = 1

-- Main class definition is here
-- Note: these classes WILL be removed in the near future!

BUI.Inventory.SlotActions = ZO_ItemSlotActionsController:Subclass()

-- This is a way to overwrite the ItemSlotAction's primary command. This is done so that "TryUseItem" and other functions use "CallSecureProtected" when activated
local function BUI_AddSlotPrimary(self, actionStringId, actionCallback, actionType, visibilityFunction, options)
    local actionName = actionStringId

    visibilityFunction = function()
	    return not IsUnitDead("player")
	end

	-- The following line inserts a row into the FIRST slotAction table, which corresponds to PRIMARY_ACTION_KEY
    table.insert(self.m_slotActions, 1, { actionName, actionCallback, actionType, visibilityFunction, options })
    self.m_hasActions = true

    if(self.m_contextMenuMode and (not options or options ~= "silent") and (not visibilityFunction or visibilityFunction())) then
        AddMenuItem(actionName, actionCallback)

		--table.remove(ZO_Menu.items, 1) -- get rid of the old Primary menu item, leaving our replacement at the top
		--ZO_Menu.itemPool:ReleaseObject(1)
    end
end

-- Our overwritten TryUseItem allows us to call it securely
local function TryUseItem(inventorySlot)
    local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
    local usable, onlyFromActionSlot = IsItemUsable(bag, index)
    if usable and not onlyFromActionSlot then
        ClearCursor()
        CallSecureProtected("UseItem",bag, index) -- the problem with the slots gets solved here!
        return true
    end

    return false
end

local function TryBankItem(inventorySlot)
    if(PLAYER_INVENTORY:IsBanking()) then
        local bag, index = ZO_Inventory_GetBagAndIndex(inventorySlot)
        if(bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK) then
            --Withdraw
            if(DoesBagHaveSpaceFor(BAG_BACKPACK, bag, index)) then
                CallSecureProtected("PickupInventoryItem",bag, index)
                CallSecureProtected("PlaceInTransfer")
            else
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_INVENTORY_FULL)
            end
        else
            --Deposit
            if IsItemStolen(bag, index) then
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_STOLEN_ITEM_CANNOT_DEPOSIT_MESSAGE)
            elseif DoesBagHaveSpaceFor(BAG_BANK, bag, index) or DoesBagHaveSpaceFor(BAG_SUBSCRIBER_BANK, bag, index) then
                CallSecureProtected("PickupInventoryItem",bag, index)
                CallSecureProtected("PlaceInTransfer")
            else
                if not IsESOPlusSubscriber() then
                    if GetNumBagUsedSlots(BAG_SUBSCRIBER_BANK) > 0 then
                        TriggerTutorial(TUTORIAL_TRIGGER_BANK_OVERFULL)
                    else
                        TriggerTutorial(TUTORIAL_TRIGGER_BANK_FULL_NO_ESO_PLUS)
                    end
                end
                ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, SI_INVENTORY_ERROR_BANK_FULL)
            end
        end
        return true
    end
end
function BUI.Inventory.SlotActions:Initialize(alignmentOverride, additionalMouseOverbinds, useKeybindStrip)
    self.alignment = KEYBIND_STRIP_ALIGN_RIGHT

    local slotActions = ZO_InventorySlotActions:New(INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU)
	slotActions.AddSlotPrimaryAction = BUI_AddSlotPrimary -- Add a new function which allows us to neatly add our own slots *with context* of the original!!

    self.slotActions = slotActions
    self.useKeybindStrip = useKeybindStrip == nil and true or useKeybindStrip

    local primaryCommand =
    {
        alignment = alignmentOverride,
        name = function()
            if(self.selectedAction) then
                return slotActions:GetRawActionName(self.selectedAction)
            end

            return self.actionName or ""
        end,
        keybind = "UI_SHORTCUT_PRIMARY",
        order = 500,
        callback = function()
            if self.selectedAction then
                self:DoSelectedAction()
            else
                slotActions:DoPrimaryAction()
            end
        end,
        visible =   function()
                        return slotActions:CheckPrimaryActionVisibility() or self:HasSelectedAction()
                    end,
    }

    local function PrimaryCommandHasBind()
        return (self.actionName ~= nil) or self:HasSelectedAction()
    end

    local function PrimaryCommandActivate(inventorySlot)
        slotActions:Clear()
        slotActions:SetInventorySlot(inventorySlot)
        self.selectedAction = nil -- Do not call the update function, just clear the selected action

        if not inventorySlot then
            self.actionName = nil
        else
            ZO_InventorySlot_DiscoverSlotActionsFromActionList(inventorySlot, slotActions)

			--self.actionName = slotActions:GetPrimaryActionName()

            -- Instead of deleting it at add time, let's delete it now!
            local primaryAction = slotActions:GetAction(PRIMARY_ACTION_KEY, "primary", nil)
            
            if primaryAction and primaryAction[INDEX_ACTION_NAME] then
                self.actionName = primaryAction[INDEX_ACTION_NAME]

                if self.actionName == GetString(SI_ITEM_ACTION_USE) or 
					self.actionName == GetString(SI_ITEM_ACTION_EQUIP) or 
					self.actionName == GetString(SI_ITEM_ACTION_BANK_WITHDRAW) or 
					self.actionName == GetString(SI_ITEM_ACTION_BANK_DEPOSIT) then
                    table.remove(slotActions.m_slotActions, PRIMARY_ACTION_KEY)
                end
            else
				self.actionName = slotActions:GetPrimaryActionName()
			end
			-- Now check if the slot that has been found for the current item needs to be replaced with the CSP ones
			if self.actionName == GetString(SI_ITEM_ACTION_USE) then
				slotActions:AddSlotPrimaryAction(GetString(SI_ITEM_ACTION_USE), function(...) TryUseItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
			end
			if self.actionName == GetString(SI_ITEM_ACTION_EQUIP) then
				slotActions:AddSlotPrimaryAction(GetString(SI_ITEM_ACTION_EQUIP), function(...) GAMEPAD_INVENTORY:TryEquipItem(inventorySlot, ZO_Dialogs_IsShowingDialog()) end, "primary", nil, {visibleWhenDead = false})
			end
			if self.actionName == GetString(SI_ITEM_ACTION_BANK_WITHDRAW) then
				slotActions:AddSlotPrimaryAction(GetString(SI_ITEM_ACTION_BANK_WITHDRAW), function(...) TryBankItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
			end
			if self.actionName == GetString(SI_ITEM_ACTION_BANK_DEPOSIT) then
				slotActions:AddSlotPrimaryAction(GetString(SI_ITEM_ACTION_BANK_DEPOSIT), function(...) TryBankItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
			end				
        end
    end

    self:AddSubCommand(primaryCommand, PrimaryCommandHasBind, PrimaryCommandActivate)

    if additionalMouseOverbinds then
        local mouseOverCommand, mouseOverCommandIsVisible
        for i=1, #additionalMouseOverbinds do
            mouseOverCommand =
            {
                alignment = alignmentOverride,
                name = function()
                    return slotActions:GetKeybindActionName(i)
                end,
                keybind = additionalMouseOverbinds[i],
                callback = function() slotActions:DoKeybindAction(i) end,
                visible =   function()
                                return slotActions:CheckKeybindActionVisibility(i)
                            end,
            }

            mouseOverCommandIsVisible = function()
                return slotActions:GetKeybindActionName(i) ~= nil
            end

            self:AddSubCommand(mouseOverCommand, mouseOverCommandIsVisible)
        end
    end
end

function BUI.Inventory.SlotActions:SetInventorySlot(inventorySlot)
    self.inventorySlot = inventorySlot

    for i, command in ipairs(self) do
        if command.activateCallback then
            command.activateCallback(inventorySlot)
        end
    end

    self:RefreshKeybindStrip()
end
