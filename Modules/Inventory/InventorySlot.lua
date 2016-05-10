INVENTORY_SLOT_ACTIONS_USE_CONTEXT_MENU = true
INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU = false

local INDEX_ACTION_NAME = 1
local INDEX_ACTION_CALLBACK = 2
local INDEX_ACTION_TYPE = 3
local INDEX_ACTION_VISIBILITY = 4
local INDEX_ACTION_OPTIONS = 5

local PRIMARY_ACTION_KEY = 1

-- Main class definition is here
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
end



function BUI.Inventory.SlotActions:Initialize(alignmentOverride)
    self.alignment = KEYBIND_STRIP_ALIGN_RIGHT

    local slotActions = ZO_InventorySlotActions:New(INVENTORY_SLOT_ACTIONS_PREVENT_CONTEXT_MENU)
	slotActions.AddSlotPrimaryAction = BUI_AddSlotPrimary -- Add a new function which allows us to neatly add our own slots *with context* of the original!!

    self.slotActions = slotActions

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

			self.actionName = slotActions:GetPrimaryActionName()

			-- Now check if the slot that has been found for the current item needs to be replaced with the CSP ones
			if self.actionName == "Use" then
				slotActions:AddSlotPrimaryAction("Use", function(...) TryUseItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
			end
			--slotActions:AddSlotAction(SI_ITEM_ACTION_EQUIP, function() GAMEPAD_INVENTORY:TryEquipItem(inventorySlot) end, "primary")
			if self.actionName == "Equip" then
				slotActions:AddSlotPrimaryAction("Equip", function(...) GAMEPAD_INVENTORY:TryEquipItem(inventorySlot) end, "primary", nil, {visibleWhenDead = false})
			end
        end
    end

    self:AddSubCommand(primaryCommand, PrimaryCommandHasBind, PrimaryCommandActivate)

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
