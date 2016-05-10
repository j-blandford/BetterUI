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

    --local newColor = ZO_ColorDef:New(1, 0.95, 0.5)

    icon:SetColor(1, 0.95, 0.5, icon:GetControlAlpha())

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

        --    control.tabBar = BUI_TabBarScrollList:New(tabBarControl, tabBarControl:GetNamedChild("LeftIcon"), tabBarControl:GetNamedChild("RightIcon"))
            --control.tabBar:AddDataTemplate("BUI_GamepadTabBarTemplate", TabBar_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
        end

    --    ZO_GamepadGenericHeader_SetDataLayout(control, layout or DEFAULT_LAYOUT)
end

local TEXT_ALIGN_RIGHT = 2

function BUI.GenericHeader.AddToList(control, data)
    local tabBarControl = control.controls[TABBAR]
    control.tabBar:AddEntry("BUI_GamepadTabBarTemplate", data)
end

function BUI.GenericHeader.SetEquipText(control, isEquipMain)
    local equipControl = control:GetNamedChild("TitleContainer"):GetNamedChild("EquipText")
    equipControl:SetText(zo_strformat(BUI.Lib.GetString("SI_INV_EQUIPSLOT"), BUI.Lib.GetString(isEquipMain and "SI_INV_EQUIPSLOT_MAIN" or "SI_INV_EQUIPSLOT_BACKUP")))
    equipControl:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
end

function BUI.GenericHeader.RefreshData()
    -- blank
end

function BUI.GenericHeader.Refresh(control, data, blockTabBarCallbacks)
    --ZO_GamepadGenericHeader_RefreshData(control, data)

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
