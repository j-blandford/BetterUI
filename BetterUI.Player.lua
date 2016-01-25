local _

function BUI.Player.IsResearchable(itemLink)
	local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(CRAFTING_TYPE_BLACKSMITHING, traitType)
	
	for traitIndex = 1, numTraits do
		local traitType, traitDescription, known = GetSmithingResearchLineTraitInfo(CRAFTING_TYPE_BLACKSMITHING, traitType, traitIndex)

        if known then
            return false
        end
    end

    return true
end