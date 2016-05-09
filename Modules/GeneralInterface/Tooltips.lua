local _

local function AddInventoryPostInfo(tooltip, itemLink)
	if itemLink  then
		if MasterMerchant ~= nil and BUI.Settings.Modules["GuildStore"].mmIntegration then
			local tipLine, avePrice, graphInfo = MasterMerchant:itemPriceTip(itemLink, false, clickable)
			if(tipLine ~= nil) then
				tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r <<1>>",tipLine), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			else 
				tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r MM price (0 sales, 0 days): UNKNOWN"), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
			end
		end

        if ddDataDaedra ~= nil and BUI.Settings.Modules["GuildStore"].ddIntegration then
            local ddData = ddDataDaedra:GetKeyedItem(itemLink)
            if(ddData ~= nil) then
                if(ddData.wAvg ~= nil) then
                    --local dealPercent = (unitPrice/wAvg.wAvg*100)-100
                    tipLine = "dataDaedra: wAvg="..ddData.wAvg
                    tooltip:AddLine(zo_strformat("|c0066ff[BUI]|r <<1>>",tipLine), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
                end
            end
        end
	end
end

-- Original code by prasoc, edited by ScotteYx. Thanks for the improvement :)
local function AddInventoryPreInfo(tooltip, itemLink)
    local style = GetItemLinkItemStyle(itemLink)
    local itemStyle = string.upper(GetString("SI_ITEMSTYLE", style))
 
    if itemLink and BUI.Settings.Modules["Tooltips"].showStyleTrait then
        local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
 
        if (traitType ~= ITEM_TRAIT_TYPE_NONE and(itemStyle) ~=("NONE")) then
            local traitString
            if BUI.Player.IsResearchable(itemLink) then
                -- If there's duplicates
                if BUI.Player.GetNumberOfMatchingItems(itemLink, BAG_BACKPACK) + BUI.Player.GetNumberOfMatchingItems(itemLink, BAG_BANK) > 1 then
                    traitString = "|cFF9900Duplicate|r"
                else
                    traitString = "|c00FF00Researchable|r"
                end
            else
                traitString = "|cFF0000Known|r"
            end
            tooltip:AddLine(zo_strformat("<<1>> (Trait: <<2>>)", itemStyle, traitString), { fontSize = 30, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))
        else
            if ((itemStyle) ~=("NONE")) then
                tooltip:AddLine(zo_strformat("<<1>>", itemStyle), { fontSize = 30, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))
            end
        end
    end
end
---------------------------------------------------------------------------

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

    if(BUI.Settings.Modules["Tooltips"].attributeLabels) then
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

function BUI.Tooltips.CreateBarLabel(name, parent, controller, anchor)
	local labelTxt = BUI.WindowManager:CreateControl(name, controller, CT_LABEL)
    labelTxt:SetFont("$(GAMEPAD_MEDIUM_FONT)|20|soft-shadow-thick")
    labelTxt:SetText(" ")
    labelTxt:SetColor(1, 1, 1, 1)
    labelTxt:SetAnchor(CENTER, anchor, TOP, 0,10)
    parent.BUI_labelRef = labelTxt
end

function BUI.Tooltips.CreateAttributeLabels()
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_healthLabel",PLAYER_ATTRIBUTE_BARS.bars[1].control,ZO_PlayerAttributeHealth)
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_magickaLabel",PLAYER_ATTRIBUTE_BARS.bars[3].control,ZO_PlayerAttributeMagicka)
	BUI.Tooltips.CreateBarLabel("BUI_playerFrame_staminaLabel",PLAYER_ATTRIBUTE_BARS.bars[5].control,ZO_PlayerAttributeStamina)

	PLAYER_ATTRIBUTE_BARS.bars[1].UpdateStatusBar = BUI_UpdateAttributeBar
	PLAYER_ATTRIBUTE_BARS.bars[3].UpdateStatusBar = BUI_UpdateAttributeBar
	PLAYER_ATTRIBUTE_BARS.bars[5].UpdateStatusBar = BUI_UpdateAttributeBar
end


function BUI.Tooltips.RefreshControls(self)
 	if(self.hidden) then
        self.dirty = true
    else
        if(self.hasTarget) then
            if self.nameLabel then
                local name

                if IsInGamepadPreferredMode()  then
                	if BUI.Settings.Modules["Tooltips"].showAccountName then
                    	name = zo_strformat("|c<<1>><<2>>|r|c<<3>><<4>>|r",BUI.RGBToHex(BUI.Settings.Modules["Tooltips"].showCharacterColor),ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag)),BUI.RGBToHex(BUI.Settings.Modules["Tooltips"].showAccountColor),GetUnitDisplayName(self.unitTag))
                    else
                    	name = ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag))
                    end
                else
                    name = GetUnitName(self.unitTag)
                end
                self.nameLabel:SetText(name)
            end
            self:UpdateUnitReaction()
            self:UpdateLevel()
            self:UpdateCaption()

            local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
            self.healthBar:Update(POWERTYPE_HEALTH, health, maxHealth, FORCE_INIT)
            self.healthBar.BUI_labelRef:SetHidden(not IsUnitOnline(self.unitTag))

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
end

function BUI.Tooltips.UpdateHealthbar(self, barType, cur, max, forceInit)
    local barCur = cur
    local barMax = max
    if(#self.barControls == 2) then
        barCur = cur / 2
        barMax = max / 2
    end
    for i = 1, #self.barControls do
        ZO_StatusBar_SmoothTransition(self.barControls[i], barCur, barMax, forceInit)
    end
    local updateBarType = false
    local updateValue = cur ~= self.currentValue or self.maxValue ~= max
    self.currentValue = cur
    self.maxValue = max
    if(barType ~= self.barType) then
        updateBarType = true
        self.barType = barType
        self.barTypeName = GetString("SI_COMBATMECHANICTYPE", self.barType)
    end
    self:UpdateText(updateBarType, updateValue)

    if BUI.Settings.Modules["Tooltips"].showHealthText and self.BUI_labelRef ~= nil then
        self.BUI_labelRef:SetText(BUI.DisplayNumber(self.currentValue).." ("..string.format("%.0f",100*self.currentValue/self.maxValue).."%)")
    	self.BUI_labelRef:SetHidden(false)
    else
    	self.BUI_labelRef:SetHidden(true)
    end
end

function BUI.Tooltips.UpdateGroupAnchorFrames(self)
    for unitTag, unitFrame in pairs(self.groupFrames) do
	    if(unitFrame.healthBar.BUI_labelRef == nil) then
		    unitFrame.healthBar.BUI_labelRef =  BUI.WindowManager:CreateControl(unitFrame.frame:GetName().."HealthLabel", unitFrame.frame, CT_LABEL)
		    unitFrame.healthBar.BUI_labelRef:SetFont("$(GAMEPAD_MEDIUM_FONT)|20|soft-shadow-thick")
		    unitFrame.healthBar.BUI_labelRef:SetText("100 (100%)")
		    unitFrame.healthBar.BUI_labelRef:SetColor(1, 1, 1, 1)
		    unitFrame.healthBar.BUI_labelRef:SetAnchor(CENTER, unitFrame.frame, TOP, 5,53)
		    unitFrame.healthBar.BUI_labelRef:SetHidden(true)

            unitFrame.frame:GetNamedChild("Background2"):SetAnchor(6, unitFrame.frame, 6, -6, 42 )

		    unitFrame.frame:SetHeight(30)
		    unitFrame.frame:GetNamedChild("Background1"):SetHeight(24)
		    unitFrame.healthBar.barControls[1]:SetHeight(20)

		    unitFrame.RefreshControls = BUI.Tooltips.RefreshControls
		    unitFrame.healthBar.Update = BUI.Tooltips.UpdateHealthbar

		   	unitFrame.RefreshControls(unitFrame)
		end
    end

    return true
end