local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

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
			getFunc = function() return BUI.settings.showStyleTrait end,
			setFunc = function(value) BUI.settings.showStyleTrait = value end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display the account name next to the character name?",
			getFunc = function() return BUI.settings.showAccountName end,
			setFunc = function(value) 
						BUI.settings.showAccountName = value 
						UNIT_FRAMES.firstDirtyGroupIndex = 1
					end,
			width = "full",
		},
		{
			type = "colorpicker",
			name = "Character name colour",
			getFunc = function() return unpack(BUI.settings.showCharacterColor) end,
			setFunc = function(r,g,b,a) BUI.settings.showCharacterColor={r,g,b,a} end,
			width = "full",	--or "half" (optional)
		},
		{
			type = "checkbox",
			name = "Display the health value (text) on the target?",
			getFunc = function() return BUI.settings.showHealthText end,
			setFunc = function(value) 
						BUI.settings.showHealthText = value 
						UNIT_FRAMES.firstDirtyGroupIndex = 1
						end,
			width = "full",
		},
		{
			type = "checkbox",
			name = "Display value labels on Attribute bars",
			tooltip = "Displays the Health, Stamina and Magicka values on your attribute bars",
			getFunc = function() return BUI.settings.attributeLabels end,
			setFunc = function(value) 
						BUI.settings.attributeLabels = value 
						end,
			width = "full",
		},
		        {
            type = "editbox",
            name = "Chat window history size",
            tooltip = "Alters how many lines to store in the chat buffer, default=200",
            getFunc = function() return BUI.settings.Tooltips.chatHistory end,
            setFunc = function(value) BUI.settings.Tooltips.chatHistory = tonumber(value) 
            							if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.settings.Tooltips.chatHistory) end end,
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

    if BUI.settings.showHealthText and self.BUI_labelRef ~= nil then
        self.BUI_labelRef:SetText(BUI.DisplayNumber(self.currentValue).." ("..string.format("%.0f",100*self.currentValue/self.maxValue).."%)")
    	self.BUI_labelRef:SetHidden(false)
    else
    	self.BUI_labelRef:SetHidden(true)
    end

end

function BUI.Tooltips.Setup()

	Init("General", "General Interface")

	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)

	BUI.Tooltips.CreateBarLabel("BUI_targetFrame_healthLabel",UNIT_FRAMES.staticFrames.reticleover.healthBar,UNIT_FRAMES.staticFrames.reticleover.frame,ZO_TargetUnitFramereticleover)

	BUI.Tooltips.CreateAttributeLabels()

	ZO_PreHook(UNIT_FRAMES,"UpdateGroupAnchorFrames", BUI.Tooltips.UpdateGroupAnchorFrames)

	if(ZO_ChatWindowTemplate1Buffer ~= nil) then ZO_ChatWindowTemplate1Buffer:SetMaxHistoryLines(BUI.settings.Tooltips.chatHistory) end

	--UNIT_FRAMES.CreateFrame = BUI.Tooltips.CreateFrame
	UNIT_FRAMES.staticFrames.reticleover.healthBar.UpdateText = BUI.Tooltips.UpdateText
	UNIT_FRAMES.staticFrames.reticleover.RefreshControls = BUI.Tooltips.RefreshControls
end