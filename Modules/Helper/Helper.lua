local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")
  
function BUI.Helper.GamePadBuddy.GetItemStatusIndicator(bagId, slotIndex)
	if GamePadBuddy then
		local itemFlagStatus = GamePadBuddy:GetItemFlagStatus(bagId, slotIndex)
		local iconTextureName
		if itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_NONE then
			iconTextureName = ""
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_ORNATE then
			iconTextureName = "|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_currencies.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_INTRICATE then
			iconTextureName = "|t24:24:/esoui/art/inventory/gamepad/gp_inventory_icon_craftbag_all.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TCC_QUEST then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_quest_green.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TCC_USABLE then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_quest_white.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TCC_USELESS then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_quest_red.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_RESEARABLE then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_research_researchable.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_DUPLICATED then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_research_duplicated.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_KNOWN then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_research_known.dds|t"
		elseif itemFlagStatus == GamePadBuddy.CONST.ItemFlags.ITEM_FLAG_TRAIT_RESEARCHING then
			iconTextureName = "|t24:24:/BetterUI/Modules/Helper/Images/icon_research_researching.dds|t"				
		end
		return iconTextureName
	end
	return "";
end

function BUI.Helper.IokaniGearChanger.GetGearSet(bagId, slotIndex)
	if GearChangerByIakoni then
		local itemType = GetItemType(bagId, slotIndex)
		if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
			local result = ""
			local a=GearChangerByIakoni.savedVariables.ArraySet
			local b=GearChangerByIakoni.savedVariables.ArraySetSavedFlag
			local itemID = Id64ToString(GetItemUniqueId(bagId, slotIndex))
			for i=1, 10 do
				if b[i] == 1 then --check only if the set is saved
					for _,u in pairs(GearChangerByIakoni.WornArray) do
						if itemID==a[i][u] then
							--find gear in set i
							result = result .. "|t24:24:/BetterUI/Modules/Helper/Images/icon_set_" .. i .. ".dds|t"
							if not BUI.Settings.Modules["Inventory"].showIconIakoniGearChangerAllSets then
								return result							
							else
								break
							end
						end
					end
				end
			end
			return result			
		end
	end
	return "";
end

    
local CUSTOM_GAMEPAD_ITEM_SORT =
{
	sortPriorityName  = { tiebreaker = "bestItemTypeName" },
	bestItemTypeName = { tiebreaker = "name" },
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

function BUI_GamepadInventory_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "sortPriorityName", CUSTOM_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

function BUI.Helper.AutoCategory:GetCustomCategory(itemData)
	local useCustomCategory = false
	if AutoCategory then
		useCustomCategory = true
		local bagId = itemData.bagId
		local slotIndex = itemData.slotIndex
		local matched, categoryName, categoryPriority = AutoCategory:MatchCategoryRules(bagId, slotIndex)		
		return useCustomCategory, matched, categoryName, categoryPriority
	end
	
	return useCustomCategory, false, "", 0
end