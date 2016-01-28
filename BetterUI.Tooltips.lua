local _

local function AddInventoryInfo(tooltip, itemLink)
	if itemLink  then
		if BUI.MMIntegration and BUI.settings.showMMPrice then
			local tipLine, avePrice, graphInfo = MasterMerchant:itemPriceTip(itemLink, false, clickable)
			tooltip:AddLine(zo_strformat("<<1>>",tipLine), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
		end
		--d(itemLink)
		local style = GetItemLinkItemStyle(itemLink)
		local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)

		local traitString

		if BUI.Player.IsResearchable(itemLink) then
			traitString = "|c00FF00Researchable|r"
		else
			traitString = "|cFF0000Known|r"
		end

		--GetString("SI_ITEMTRAITTYPE", traitType))

		--tooltip:AddLine(zo_strformat("<<1>> (<<2>>)",string.upper(GetString("SI_ITEMSTYLE", style)),traitString),{ fontSize = 30, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("title"))
	end
end

function BUI.InventoryHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		AddInventoryInfo(self, linkFunc(...))
	end
end

function BUI.ReturnItemLink(itemLink)
	return itemLink
end

function BUI.Tooltips.Setup()
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)
	BUI.InventoryHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", BUI.ReturnItemLink)

    healthLbl = BUI.WindowManager:CreateControl("BUI_targetFrame_healthLabel", UNIT_FRAMES.staticFrames.reticleover.frame, CT_LABEL)
    healthLbl:SetFont("$(GAMEPAD_MEDIUM_FONT)|20|soft-shadow-thick")
    healthLbl:SetText("0/0")
    healthLbl:SetColor(1, 1, 1, 1)
    healthLbl:SetAnchor(CENTER, ZO_CompassFrame, TOP, 0,-3)

	BUI.Hook(UNIT_FRAMES.staticFrames.reticleover,"RefreshControls", function(self) 
     	if(self.hidden) then
	        self.dirty = true
	    else
	        if(self.hasTarget) then
	            if self.nameLabel then
	                local name

	                if IsInGamepadPreferredMode() and IsUnitPlayer(self.unitTag) then
	                	if BUI.settings.showAccountName then
	                    	name = zo_strformat("|c<<1>><<2>>|r<<3>>",BUI.RGBToHex(BUI.settings.showCharacterColor),ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag)),GetUnitDisplayName(self.unitTag))
	                    else
	                    	name = ZO_FormatUserFacingDisplayName(GetUnitName(self.unitTag))
	                    end
	                else
	                    name = GetUnitName(self.unitTag)
	                end
	                if BUI.settings.showHealthText then
	                	local health, maxHealth = GetUnitPower(self.unitTag, POWERTYPE_HEALTH)
		                self.nameLabel:SetText(name)
		                BUI_targetFrame_healthLabel:SetText(BUI.DisplayNumber(health).." ("..BUI.DisplayNumber(100*health/maxHealth).."%)")
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