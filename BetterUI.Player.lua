local _

function BUI.Player.FindByTrait(craftType, researchIndex, traitType)
	if(rIndex == -1) then return -1 end

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

-- Credit to ScotteYx for this! thanks for this improvement
function BUI.Player.GetNumberOfMatchingItems(itemLink, BAG)
    -- Get bag size
    local bagSize = GetBagSize(BAG)
 
    -- Var to hold item matches
    local itemMatches = 0
 
    -- Iterate through BAG
    for i = 0, bagSize do
        -- Get current item
        local currentItem = GetItemLink(BAG, i)
 
        -- Check if current item is researchable
        if (BUI.Player.IsResearchable(currentItem)) then
 
            -- Get current/item to check item trait
            local currentItemTrait, _, _, _, _ = GetItemLinkTraitInfo(currentItem)
            local itemToCheckTrait, _, _, _, _ = GetItemLinkTraitInfo(itemLink)
 
            -- Check if current item trait equals item's trait we're checking
            if (currentItemTrait == itemToCheckTrait) then
 
                -- Get current/item to check equip type
                local currentItemEquipType = GetItemLinkEquipType(currentItem)
                local itemToCheckEquipType = GetItemLinkEquipType(itemLink)
 
                -- Check if current item equip type equals item's equip type we're checking
                if (currentItemEquipType == itemToCheckEquipType) then
 
                    -- Get item type
                    local itemType = GetItemLinkItemType(currentItem)
 
                    -- If armor
                    if (itemType == ITEMTYPE_ARMOR) then
 
                        -- Get armor type
                        local currentItemArmorType = GetItemLinkArmorType(currentItem)
 
                        -- Check if current item armor type equals item's armor type we're checking
                        if (currentItemArmorType == GetItemLinkArmorType(itemLink)) then
 
                            -- If here, then we have a match so increment counter
                            itemMatches = itemMatches + 1
                        end
                    else
                        -- If weapon
                        if (itemType == ITEMTYPE_WEAPON) then
 
                            -- Get weapon type
                            local currentItemWeaponType = GetItemLinkWeaponType(currentItem)
 
                            -- If current item armor type != item's armor type we're checking
                            if (currentItemWeaponType == GetItemLinkWeaponType(itemLink)) then
 
                                -- If here, then we have a match so increment counter
                                itemMatches = itemMatches + 1
                            end
                        end
                    end
                end
            end
        end
    end
 
    -- return number of matches
    return itemMatches;
end
---------------------------------------------------------------------------

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
		if(armorType ~= nil) then
			local equipType = GetItemLinkEquipType(itemLink)
			craftType = GetSkillType(armorType, BUI.CONST.armorCraftMap)
			
			if(BUI.CONST.armorRImap[armorType] ~= nil) then
				rIndex = BUI.CONST.armorRImap[armorType][equipType]
			else
				return false
			end
		else
			return false
		end
	else
		local weaponType = GetItemLinkWeaponType(itemLink)
		craftType = GetSkillType(weaponType, BUI.CONST.weaponCraftMap)
		if(BUI.CONST.weaponRImap[weaponType] ~= nil) then
			rIndex = BUI.CONST.weaponRImap[weaponType]
		else
			return false
		end
	end

	traitIndex = BUI.Player.FindByTrait(craftType,rIndex,traitType)

	if(traitIndex ~= -1) then
		return not BUI.Player.ResearchTraits[craftType][rIndex][traitIndex]
	else
		return false
	end
end