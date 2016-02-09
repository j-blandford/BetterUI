local _


function BUI.Player.FindByTrait(craftType, researchIndex, traitType)
	local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftType, researchIndex)

	for traitIndex=1,numTraits do
		local foundTrait, _, _ = GetSmithingResearchLineTraitInfo(craftType, researchIndex, traitIndex)

		if(foundTrait == traitType) then
			return traitIndex
		end
	end
	return -1
end

function BUI.Player.GetResearch()
	BUI.Player.ResearchTraits = {}
	for i,craftType in pairs(BUI.Player.CraftingSkillTypes) do
		BUI.Player.ResearchTraits[craftType] = {}
		for researchIndex = 1, GetNumSmithingResearchLines(craftType) do
			local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(craftType, researchIndex)
			BUI.Player.ResearchTraits[craftType][researchIndex] = {}
			for traitIndex = 1, numTraits do
				local traitType, _, known = GetSmithingResearchLineTraitInfo(craftType, researchIndex, traitIndex)
				BUI.Player.ResearchTraits[craftType][researchIndex][traitIndex] = known
			end
		end
	end
end

function BUI.Player.IsResearchable(itemLink)
	local traitType, traitDescription, traitSubtype, traitSubtypeName, traitSubtypeDescription = GetItemLinkTraitInfo(itemLink)
	local name, icon, numTraits, timeRequiredForNextResearchSecs = GetSmithingResearchLineInfo(CRAFTING_TYPE_BLACKSMITHING, traitType)

	--d("--")
	--d(GetItemLinkCraftingSkillType(itemLink))
	return false -- not BUI.Player.ResearchTraits[craftType][researchIndex][traitIndex]
end