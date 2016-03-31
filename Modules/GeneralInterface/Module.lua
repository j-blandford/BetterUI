local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

local ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT = "inventory"
local ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT = "bank"
local ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT = "inventoryAndBank"

local function Init(mId, moduleName)
	local panelData = Init_ModulePanel(moduleName, "General Interface Improvement Settings")

	local optionsTable = {
		{
			type = "header",
			name = "Module Settings",
			width = "full",
		},
		{
		type = "checkbox",
			name = "Display item style and trait knowledge",
			tooltip = "On items, displays the style of the item and whether the trait can be researched",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showStyleTrait end,
			setFunc = function(value) BUI.Settings.Modules["Tooltips"].showStyleTrait = value end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display the account name next to the character name?",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showAccountName end,
			setFunc = function(value) 
						BUI.Settings.Modules["Tooltips"].showAccountName = value 
						UNIT_FRAMES.firstDirtyGroupIndex = 1
					end,
			width = "full",
		},
		{
			type = "colorpicker",
			name = "Character name colour",
			getFunc = function() return unpack(BUI.Settings.Modules["Tooltips"].showCharacterColor) end,
			setFunc = function(r,g,b,a) BUI.Settings.Modules["Tooltips"].showCharacterColor={r,g,b,a} end,
			width = "full",	--or "half" (optional)
		},
		{
			type = "checkbox",
			name = "Display the health value (text) on the target?",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].showHealthText end,
			setFunc = function(value) 
						BUI.Settings.Modules["Tooltips"].showHealthText = value 
						UNIT_FRAMES.firstDirtyGroupIndex = 1
						end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display value labels on Attribute bars",
			tooltip = "Displays the Health, Stamina and Magicka values on your attribute bars",
			getFunc = function() return BUI.Settings.Modules["Tooltips"].attributeLabels end,
			setFunc = function(value) 
						BUI.Settings.Modules["Tooltips"].attributeLabels = value 
						end,
			width = "full",
		},
		        {
            type = "editbox",
            name = "Chat window history size",
            tooltip = "Alters how many lines to store in the chat buffer, default=200",
            getFunc = function() return BUI.Settings.Modules["Tooltips"].chatHistory end,
            setFunc = function(value) BUI.Settings.Modules["Tooltips"].chatHistory = tonumber(value) 
            							if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.Settings.Modules["Tooltips"].chatHistory) end end,
            default=200,
            width = "full",
        },  
	}
	LAM:RegisterAddonPanel("BUI_"..mId, panelData)
	LAM:RegisterOptionControls("BUI_"..mId, optionsTable) 
end

function BUI.Tooltips.UpdateText(self, updateBarType, updateValue)
    if(self.showBarText == SHOW_BAR_TEXT or self.showBarText == SHOW_BAR_TEXT_MOUSE_OVER) then
        local visible = GetVisibility(self)
        if(self.leftText and self.rightText) then
            self.leftText:SetHidden(not visible)
            self.rightText:SetHidden(not visible)
            if visible then
                if updateBarType then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARTYPE, self.barTypeName))
                end
                if updateValue then
                    self.rightText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            end
        elseif(self.leftText) then
            if visible then
                self.leftText:SetHidden(false)
                if updateValue then
                    self.leftText:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, self.currentValue, self.maxValue))
                end
            else
                self.leftText:SetHidden(true)
            end
        end
    end

    if BUI.Settings.Modules["Tooltips"].showHealthText and self.BUI_labelRef ~= nil then
        self.BUI_labelRef:SetText(BUI.DisplayNumber(self.currentValue).." ("..string.format("%.0f",100*self.currentValue/self.maxValue).."%)")
    	self.BUI_labelRef:SetHidden(false)
    else
    	self.BUI_labelRef:SetHidden(true)
    end

end

function BUI.Tooltips.InitModule(m_options)
    m_options["chatHistory"] = 200
    m_options["showStyleTrait"] = true
    m_options["showHealthText"] = true
    m_options["showAccountName"] = true
    m_options["showCharacterColor"] = {1, 0.5, 0, 1}
    m_options["attributeLabels"] = true
    
    return m_options
end


function BUI.Tooltips.Setup()

	Init("General", "General Interface")

	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)

	-- ZOS have released a buggy tooltip which is blind to the stackCount of the item being displayed, let's fix that
	local LEFT_TOOLTIP = GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP)
	LEFT_TOOLTIP.LayoutBagItem = function(self, bagId, slotIndex, enchantMode, showInventoryAndBagCount)
	    local itemLink = GetItemLink(bagId, slotIndex)
	    local _,stack,_,_,_,_,_,_ = GetItemInfo(bagId, slotIndex)
	    local equipped = bagId == BAG_WORN
	    local showInventoryCount = ZO_ITEM_TOOLTIP_SHOW_INVENTORY_BODY_COUNT
	    local showBankCount = ZO_ITEM_TOOLTIP_SHOW_BANK_BODY_COUNT
	    local stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
	    if showInventoryAndBagCount then
	        stackCount = ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT
	    else
	        if bagId == BAG_BANK then
	            showBankCount = ZO_ITEM_TOOLTIP_HIDE_BANK_BODY_COUNT
	            stackCount = ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT
	        elseif bagId == BAG_BACKPACK then
	            showInventoryCount = ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT
	            stackCount = ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT
	        elseif equipped then
	            showInventoryCount = ZO_ITEM_TOOLTIP_HIDE_INVENTORY_BODY_COUNT
	            stackCount = 1
	        end
	    end
	    self.currentStack = stack
	    return self:LayoutItemWithStackCount(itemLink, equipped, GetItemCreatorName(bagId, slotIndex), nil, enchantMode, nil, stackCount, showInventoryCount, showBankCount)
	end
	LEFT_TOOLTIP.LayoutItemWithStackCount = function(self, itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, customOrBagStackCount, showInventoryCount, showBankCount)
	    local isValidItemLink = itemLink ~= ""
	    if isValidItemLink then
	        local stackCount
	        if customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_TITLE_COUNT then
	            local bagCount, bankCount = GetItemLinkStacks(itemLink)
	            stackCount = bagCount
	        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_BANK_TITLE_COUNT then
	            local bagCount, bankCount = GetItemLinkStacks(itemLink)
	            stackCount = bankCount
	        elseif customOrBagStackCount == ZO_ITEM_TOOLTIP_INVENTORY_AND_BANK_TITLE_COUNT then
	            local bagCount, bankCount = GetItemLinkStacks(itemLink)
	            stackCount = bagCount + bankCount
	        else
	            stackCount = customOrBagStackCount
	        end
	        local itemName = GetItemLinkName(itemLink)
	        if stackCount and stackCount > 1 then
	        	if(self.currentStack ~= nil) then
	        		itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, self.currentStack)
	        	else
		            itemName = zo_strformat(SI_TOOLTIP_ITEM_NAME_WITH_QUANTITY, itemName, stackCount)
		        end
	        end
	        return self:LayoutItem(itemLink, equipped, creatorName, forceFullDurability, enchantMode, previewValueToAdd, itemName, showInventoryCount, showBankCount)
	    end
	end

	BUI.Tooltips.CreateBarLabel("BUI_targetFrame_healthLabel",UNIT_FRAMES.staticFrames.reticleover.healthBar,UNIT_FRAMES.staticFrames.reticleover.frame,ZO_TargetUnitFramereticleover)

	BUI.Tooltips.CreateAttributeLabels()

	ZO_PreHook(UNIT_FRAMES,"UpdateGroupAnchorFrames", BUI.Tooltips.UpdateGroupAnchorFrames)

	if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.Settings.Modules["Tooltips"].chatHistory) end

	--UNIT_FRAMES.CreateFrame = BUI.Tooltips.CreateFrame
	UNIT_FRAMES.staticFrames.reticleover.healthBar.UpdateText = BUI.Tooltips.UpdateText
	UNIT_FRAMES.staticFrames.reticleover.RefreshControls = BUI.Tooltips.RefreshControls
end