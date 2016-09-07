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
			if (self.healthBar and self.healthBar.BUI_labelRef) then
				self.healthBar.BUI_labelRef:SetHidden(not IsUnitOnline(self.unitTag))
			end

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
