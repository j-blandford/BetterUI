local _

-- A modified header class for the inventory system.
-- Has the added functionality of a tabbar (of type BUI_TabBarScrollList)

-----------------------------------------------------------------------------

-- Alias the control names to make the code less verbose and more readable.
local TABBAR            = ZO_GAMEPAD_HEADER_CONTROLS.TABBAR
local TITLE             = ZO_GAMEPAD_HEADER_CONTROLS.TITLE
local CENTER_BASELINE   = ZO_GAMEPAD_HEADER_CONTROLS.CENTER_BASELINE
local TITLE_BASELINE    = ZO_GAMEPAD_HEADER_CONTROLS.TITLE_BASELINE
local DIVIDER_SIMPLE    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_SIMPLE
local DIVIDER_PIPPED    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_PIPPED

local DEFAULT_LAYOUT        = ZO_GAMEPAD_HEADER_LAYOUTS.DATA_PAIRS_SEPARATE
local FIRST_DATA_CONTROL    = DATA1HEADER
local LAST_DATA_CONTROL     = DATA1HEADER

local GENERIC_HEADER_INFO_LABEL_HEIGHT = 33
local GENERIC_HEADER_INFO_DATA_HEIGHT = 50
local GENERIC_HEADER_INFO_FONT_HEIGHT_DISPARITY = 4 -- This is used to align the baselines of the headers and their texts; will need to update if fonts change
local ROW_OFFSET_Y = GENERIC_HEADER_INFO_LABEL_HEIGHT + 10
local DATA_OFFSET_X = 5
local HEADER_OFFSET_X = 29

BUI_GAMEPAD_CONTENT_HEADER_DIVIDER_INFO_BOTTOM_PADDING_Y = GENERIC_HEADER_INFO_LABEL_HEIGHT
BUI_GAMEPAD_CONTENT_DIVIDER_INFO_PADDING_Y = 50

local Anchor = ZO_Object:Subclass()
function Anchor:New(pointOnMe, targetId, pointOnTarget, offsetX, offsetY)
    local object = ZO_Object.New(self)
    object.targetId = targetId
    object.anchor = ZO_Anchor:New(pointOnMe, nil, pointOnTarget, offsetX, offsetY)
    return object
end


local function TabBar_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    local label = control:GetNamedChild("Label")
    label:SetHidden(true)
    local icon = control:GetNamedChild("Icon")
    local text = data.text
    if type(text) == "function" then
        text = text()
    end
    local iconPath = data.iconsNormal[1]
    icon:SetTexture(iconPath)

	if not data.filterType then
		icon:SetColor(1, 0.95, 0.5, icon:GetControlAlpha())
	else
		icon:SetColor(1, 1, 1, icon:GetControlAlpha())
	end

    if data.canSelect == nil then
        data.canSelect = true
    end
    ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)

end

function BUI.GenericHeader.Initialize(control, createTabBar, layout)
    control.controls =
        {
            [TABBAR]            = control:GetNamedChild("TabBar"),
            [TITLE]             = control:GetNamedChild("TitleContainer"):GetNamedChild("Title"),
            [TITLE_BASELINE]    = control:GetNamedChild("TitleContainer"),
            [DIVIDER_SIMPLE]    = control:GetNamedChild("DividerSimple"),
            [DIVIDER_PIPPED]    = control:GetNamedChild("DividerPipped"),
        }

        if createTabBar == ZO_GAMEPAD_HEADER_TABBAR_CREATE then
            local tabBarControl = control.controls[TABBAR]

            tabBarControl:SetHidden(false)

        end

end

local TEXT_ALIGN_RIGHT = 2

function BUI.GenericHeader.AddToList(control, data)
    local tabBarControl = control.controls[TABBAR]
    control.tabBar:AddEntry("BUI_GamepadTabBarTemplate", data)
end

function BUI.GenericHeader.SetEquipText(control, isEquipMain)
    local equipControl = control:GetNamedChild("TitleContainer"):GetNamedChild("EquipText")
    equipControl:SetText(zo_strformat(GetString(SI_BUI_INV_EQUIP_TEXT), GetString(isEquipMain and SI_BUI_INV_EQUIPSLOT_MAIN or SI_BUI_INV_EQUIPSLOT_BACKUP)))
    equipControl:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
end

function BUI.GenericHeader.SetTitleText(control, titleText)
    local titleTextControl = control:GetNamedChild("TitleContainer"):GetNamedChild("Title")
    titleTextControl:SetText(titleText)
end


function BUI.GenericHeader.SetEquippedIcons(control, equipMain, equipOff, equipPoison)
	local equipMainControl = control:GetNamedChild("TitleContainer"):GetNamedChild("MainHandIcon")
	local equipOffControl = control:GetNamedChild("TitleContainer"):GetNamedChild("OffHandIcon")
	local equipPoisonControl = control:GetNamedChild("TitleContainer"):GetNamedChild("PoisonIcon")
	
	local DEFAULT_INVSLOT_ICON = "/esoui/art/inventory/inventory_slot.dds"

	if(equipMain ~= "") then equipMainControl:SetTexture(equipMain) else equipMainControl:SetTexture(DEFAULT_INVSLOT_ICON) end
	if(equipOff ~= "") then equipOffControl:SetTexture(equipOff) else equipOffControl:SetTexture(DEFAULT_INVSLOT_ICON)  end
	if(equipPoison ~= "") then equipPoisonControl:SetTexture(equipPoison) else equipPoisonControl:SetTexture(DEFAULT_INVSLOT_ICON)  end
end

function BUI.GenericHeader.RefreshData()
    -- blank, ready for overriding
end

function BUI.GenericHeader.Refresh(control, data, blockTabBarCallbacks)
	--ddebug("LOL")
	--d(data)
	
	control:GetNamedChild("TitleContainer"):GetNamedChild("Title"):SetText(data.titleText(data.name))

    local tabBarControl = control.controls[TABBAR]
    tabBarControl:SetHidden(false)

    if not control.tabBar then
        local tabBarData = { attachedTo=control, parent=data.tabBarData.parent, onNext=data.tabBarData.onNext, onPrev = data.tabBarData.onPrev }
        control.tabBar = BUI_TabBarScrollList:New(tabBarControl, tabBarControl:GetNamedChild("LeftIcon"), tabBarControl:GetNamedChild("RightIcon"), tabBarData)
        control.tabBar:Activate()
        control.tabBar.hideUnselectedControls = false

        control.tabBar:AddDataTemplate("BUI_GamepadTabBarTemplate", TabBar_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
    end

    if control.tabBar then
        if(blockTabBarCallbacks) then
            control.tabBar:RemoveOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        else
            control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        end
        if data.activatedCallback then
            control.tabBar:SetOnActivatedChangedFunction(data.activatedCallback)
        end

        control.tabBar:Commit()
        if(blockTabBarCallbacks) then
            control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
        end
    end
end
