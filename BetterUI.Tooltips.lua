local _

local function AddInventoryPostInfo(tooltip, itemLink)
	if itemLink  then
		if BUI.MMIntegration and BUI.settings.showMMPrice then
			local tipLine, avePrice, graphInfo = MasterMerchant:itemPriceTip(itemLink, false, clickable)
			if(tipLine ~= nil) then
				tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r <<1>>",tipLine), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			else 
				tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r MM price (0 sales, 0 days): UNKNOWN"), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			end
		end
	end
end

local function AddInventoryPreInfo(tooltip, itemLink)
	if itemLink  then
		local style = GetItemLinkItemStyle(itemLink)
		local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)

		local traitString

		-- if BUI.Player.IsResearchable(itemLink) then
		-- 	traitString = "|c00FF00Researchable|r"
		-- else
		-- 	traitString = "|cFF0000Known|r"
		-- end

		--GetString("SI_ITEMTRAITTYPE", traitType))

		--tooltip:AddLine(zo_strformat("<<1>> (<<2>>)",string.upper(GetString("SI_ITEMSTYLE", style)),traitString),{ fontSize = 30, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))
	end
end

local function BUI_UpdateAttributeBar(self, current, max, effectiveMax)
    if self.externalVisibilityRequirement and not self.externalVisibilityRequirement() then
        return false
    end
    local forceInit = false
    if(current == nil or max == nil or effectiveMax == nil) then        
        current, max, effectiveMax = GetUnitPower(self:GetEffectiveUnitTag(), self.powerType)
        forceInit = true
    end
    if self.current == current and self.max == max and self.effectiveMax == effectiveMax then
        return
    end
    self.current = current
    self.max = max
    self.effectiveMax = effectiveMax
    local barMax = max
    local barCurrent = current
    if #self.barControls > 1 then
        barMax = barMax / 2
        barCurrent = barCurrent / 2
    end
    for _, control in pairs(self.barControls) do
        ZO_StatusBar_SmoothTransition(control, barCurrent, barMax, forceInit)
    end
    if not forceInit then
        self:ResetFadeOutDelay()
    end
    self:UpdateContextualFading()
    if(self.textEnabled) then
        self.label:SetText(zo_strformat(SI_UNIT_FRAME_BARVALUE, current, max))
    end

    if(BUI.settings.attributeLabels) then
    	self.control.BUI_labelRef:SetText(BUI.DisplayNumber(current).." ("..string.format("%.0f",100*current/max).."%)")
    	self.control.BUI_labelRef:SetHidden(false)
    else
    	self.control.BUI_labelRef:SetHidden(true)
    end
end


function BUI.InventoryHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		AddInventoryPreInfo(self, linkFunc(...))
		origMethod(self, ...)
		AddInventoryPostInfo(self, linkFunc(...))
	end
end

function BUI.ReturnItemLink(itemLink)
	return itemLink
end

function BUI.Tooltips.CreateBarLabel(name, controller, anchor)
	local labelTxt = BUI.WindowManager:CreateControl(name, controller, CT_LABEL)
    labelTxt:SetFont("$(GAMEPAD_MEDIUM_FONT)|20|soft-shadow-thick")
    labelTxt:SetText("100/100 (100%)")
    labelTxt:SetColor(1, 1, 1, 1)
    labelTxt:SetAnchor(CENTER, anchor, TOP, 0,10)
    controller.BUI_labelRef = labelTxt
end

function BUI.Tooltips.CreateAttributeLabels()
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_healthLabel",PLAYER_ATTRIBUTE_BARS.bars[1].control,ZO_PlayerAttributeHealth)
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_magickaLabel",PLAYER_ATTRIBUTE_BARS.bars[3].control,ZO_PlayerAttributeMagicka)
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_staminaLabel",PLAYER_ATTRIBUTE_BARS.bars[5].control,ZO_PlayerAttributeStamina)

	PLAYER_ATTRIBUTE_BARS.bars[1].UpdateStatusBar = BUI_UpdateAttributeBar
	PLAYER_ATTRIBUTE_BARS.bars[3].UpdateStatusBar = BUI_UpdateAttributeBar
	PLAYER_ATTRIBUTE_BARS.bars[5].UpdateStatusBar = BUI_UpdateAttributeBar
end

function BUI.Tooltips.Setup()
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)

	BUI.Tooltips.CreateBarLabel("BUI_targetFrame_healthLabel",UNIT_FRAMES.staticFrames.reticleover.frame,ZO_TargetUnitFramereticleover)

	BUI.Tooltips.CreateAttributeLabels()
    
	BUI.Hook(UNIT_FRAMES.staticFrames.reticleover,"RefreshControls", function(self) 
     	if(self.hidden) then
	        self.dirty = true
	    else
	        if(self.hasTarget) then
	            if self.nameLabel then
	                local name

	                if IsInGamepadPreferredMode()  then
	                	if BUI.settings.showAccountName then
	                    	name = zo_strformat("|c<<1>><<2>>|r<<3>>",BUI.RGBToHex(BUI.settings.showCharacterColor),ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag)),GetUnitDisplayName(self.unitTag))
	                    else
	                    	name = ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag))
	                    end
	                else
	                    name = GetUnitName(self.unitTag)
	                end
	                self.nameLabel:SetText(name)

	                if BUI.settings.showHealthText then
	                	local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
		                
		                BUI_targetFrame_healthLabel:SetText(BUI.DisplayNumber(health).." ("..string.format("%.0f",100*health/maxHealth).."%)")
	                	BUI_targetFrame_healthLabel:SetHidden(false)
	                else
	                	BUI_targetFrame_healthLabel:SetHidden(true)
	                end
	            end
	            self:UpdateUnitReaction()
	            self:UpdateLevel()
	            self:UpdateCaption()
	            local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
	            self.healthBar:Update(POWERTYPE_HEALTH, health, maxHealth, FORCE_INIT)

	            for i = 1, NUM_POWER_POOLS do
	                local powerType, cur, max = GetUnitPowerInfo(self.unitTag, i)
	                self:UpdatePowerBar(i, powerType, cur, max, FORCE_INIT)
	            end
	            self:UpdateStatus(IsUnitDead(self.unitTag), IsUnitOnline(self.unitTag))
	            self:UpdateRank()
	            self:UpdateDifficulty()
	            self:DoAlphaUpdate(IsUnitInGroupSupportRange(self.unitTag), IsUnitOnline(self.unitTag), IsUnitGroupLeader(unitTag))
	        end
    	end
     end, true)

	ZO_UnitFrames_Initialize()
end