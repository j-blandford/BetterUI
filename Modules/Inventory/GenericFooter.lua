local _

function BUI.GenericFooter.Initialize(self)
	self.footer = self.control.container:GetNamedChild("FooterContainer").footer

	BUI.GenericFooter.Refresh(self)
end

function BUI.GenericFooter.Refresh(self)
	self.footer:GetNamedChild("GoldLabel"):SetText(zo_strformat("|cFFD700<<1>>|r |t16:16:/esoui/art/currency/currency_gold.dds|t",BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_MONEY))))
	self.footer:GetNamedChild("TVLabel"):SetText(zo_strformat("|c0077BE<<1>>|r |t16:16:/esoui/art/currency/battletoken.dds|t",BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_TELVAR_STONES))))
	self.footer:GetNamedChild("CWLabel"):SetText(zo_strformat("(<<1>>)|t32:32:/esoui/art/inventory/inventory_all_tabicon_inactive.dds|t",zo_strformat(SI_GAMEPAD_INVENTORY_CAPACITY_FORMAT, GetNumBagUsedSlots(BAG_BACKPACK), GetBagSize(BAG_BACKPACK))))
	self.footer:GetNamedChild("APLabel"):SetText(zo_strformat("|c00FF00<<1>>|r |t16:16:/esoui/art/currency/alliancepoints.dds|t",BUI.DisplayNumber(GetCarriedCurrencyAmount(CURT_ALLIANCE_POINTS))))
end