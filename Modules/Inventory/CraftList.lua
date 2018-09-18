BUI.Inventory.CraftList = BUI.Inventory.List:Subclass()
function GetFilterComparator(filterType)
	return function(itemData)
		if filterType then
			-- we can pass a table of filters into the function, and this case has to be handled separately
			if type(filterType) == "table" then
				local filterHit = false
				
				for key, filter in pairs(filterType) do
					if ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, filter) then
						filterHit = true
					end
				end
				
				return filterHit
			else
				return ZO_InventoryUtils_DoesNewItemMatchFilterType(itemData, filterType)	
			end
		else
			-- for "All"
			return true
		end

		return ZO_InventoryUtils_DoesNewItemMatchSupplies(itemData)
	end
end

local DEFAULT_GAMEPAD_ITEM_SORT =
{
    bestGamepadItemCategoryName = { tiebreaker = "bestItemTypeName" },
	bestItemTypeName = { tiebreaker = "name"},
    name = { tiebreaker = "requiredLevel" },
    requiredLevel = { tiebreaker = "requiredChampionPoints", isNumeric = true },
    requiredChampionPoints = { tiebreaker = "iconFile", isNumeric = true },
    iconFile = { tiebreaker = "uniqueId" },
    uniqueId = { isId64 = true },
}

local function BUI_CraftList_DefaultItemSortComparator(left, right)
    return ZO_TableOrderingFunction(left, right, "bestGamepadItemCategoryName", DEFAULT_GAMEPAD_ITEM_SORT, ZO_SORT_ORDER_UP)
end

function BUI.Inventory.CraftList:AddSlotDataToTable(slotsTable, inventoryType, slotIndex)
    local itemFilterFunction = self.itemFilterFunction
    local categorizationFunction = self.categorizationFunction or ZO_InventoryUtils_Gamepad_GetBestItemCategoryDescription
    local slotData = SHARED_INVENTORY:GenerateSingleSlotData(inventoryType, slotIndex)
    if slotData then
        if (not itemFilterFunction) or itemFilterFunction(slotData) then
            -- itemData is shared in several places and can write their own value of bestItemCategoryName.
            -- We'll use bestGamepadItemCategoryName instead so there are no conflicts.
            slotData.bestGamepadItemCategoryName = categorizationFunction(slotData)
			slotData.bestItemTypeName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(slotData)) 
			slotData.bestItemCategoryName = slotData.bestGamepadItemCategoryName
			slotData.itemCategoryName = slotData.bestGamepadItemCategoryName
	
            table.insert(slotsTable, slotData)
        end
    end
end

function BUI.Inventory.CraftList:RefreshList(filterType) 
	self.list:Clear()

	self.itemFilterFunction = GetFilterComparator(filterType)

	filteredDataTable = self:GenerateSlotTable()
	
	table.sort(filteredDataTable, BUI_CraftList_DefaultItemSortComparator)

    local lastBestItemCategoryName
    for i, itemData in ipairs(filteredDataTable) do
        local nextItemData = filteredDataTable[i + 1]

        local data = ZO_GamepadEntryData:New(itemData.name, itemData.iconFile)
        data:InitializeInventoryVisualData(itemData)

		data.bestItemCategoryName = itemData.bestItemCategoryName
		data.itemCategoryName = itemData.bestItemCategoryName
		data.bestItemTypeName = zo_strformat(SI_INVENTORY_HEADER, GetBestItemCategoryDescription(itemData))
		data.bestGamepadItemCategoryName = itemData.bestItemCategoryName

        if itemData.bestItemCategoryName ~= lastBestItemCategoryName then
            data:SetHeader(itemData.bestItemCategoryName)
        end

        self.list:AddEntry("BUI_GamepadItemSubEntryTemplate", data)
		
        lastBestItemCategoryName = itemData.bestItemCategoryName
    end
	
    self.list:Commit()
end