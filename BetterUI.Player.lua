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

local function GetSkillType(genericType, map)
	return map[tonumber(genericType)]
end

function BUI.Player.GetResearch()
	BUI.Player.ResearchTraits = {}
	for i,craftType in pairs(BUI.CONST.CraftingSkillTypes) do
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
	local craftType,rIndex,traitIndex
	
	if(GetItemLinkItemType(itemLink) == ITEMTYPE_ARMOR) then
		local armorType = GetItemLinkArmorType(itemLink) 
		local equipType = GetItemLinkEquipType(itemLink)
		craftType = GetSkillType(armorType, BUI.CONST.armorCraftMap)
		rIndex = BUI.CONST.armorRImap[armorType][equipType]
	else
		local weaponType = GetItemLinkWeaponType(itemLink)
		craftType = GetSkillType(weaponType, BUI.CONST.weaponCraftMap)
		rIndex = BUI.CONST.weaponRImap[weaponType]
	end

	traitIndex = BUI.Player.FindByTrait(craftType,rIndex,traitType)

	if(traitIndex ~= -1) then
		return not BUI.Player.ResearchTraits[craftType][rIndex][traitIndex]
	else
		return false
	end
end