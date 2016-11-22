ZO_GAMEPAD_HEADER_CONTROLS =
{
    TABBAR          = 1,
    TITLE           = 2,
    CENTER_BASELINE = 3,
    TITLE_BASELINE  = 4,
    DIVIDER_SIMPLE  = 5,
    DIVIDER_PIPPED  = 6,
    DATA1           = 7,
    DATA1HEADER     = 8,
    DATA2           = 9,
    DATA2HEADER     = 10,
    DATA3           = 11,
    DATA3HEADER     = 12,
    DATA4           = 13,
    DATA4HEADER     = 14,
    MESSAGE         = 15,
}

-- Alias the control names to make the code less verbose and more readable.
local TABBAR            = ZO_GAMEPAD_HEADER_CONTROLS.TABBAR
local TITLE             = ZO_GAMEPAD_HEADER_CONTROLS.TITLE
local CENTER_BASELINE   = ZO_GAMEPAD_HEADER_CONTROLS.CENTER_BASELINE
local TITLE_BASELINE    = ZO_GAMEPAD_HEADER_CONTROLS.TITLE_BASELINE
local DIVIDER_SIMPLE    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_SIMPLE
local DIVIDER_PIPPED    = ZO_GAMEPAD_HEADER_CONTROLS.DIVIDER_PIPPED
local DATA1             = ZO_GAMEPAD_HEADER_CONTROLS.DATA1
local DATA1HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA1HEADER
local DATA2             = ZO_GAMEPAD_HEADER_CONTROLS.DATA2
local DATA2HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA2HEADER
local DATA3             = ZO_GAMEPAD_HEADER_CONTROLS.DATA3
local DATA3HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA3HEADER
local DATA4             = ZO_GAMEPAD_HEADER_CONTROLS.DATA4
local DATA4HEADER       = ZO_GAMEPAD_HEADER_CONTROLS.DATA4HEADER
local MESSAGE           = ZO_GAMEPAD_HEADER_CONTROLS.MESSAGE

local function ProcessData(control, data)
    if(control == nil) then
        return false
    end

    if type(data) == "function" then
        data = data(control)
    end

    if type(data) == "string" or type(data) == "number" then
        control:SetText(data)
    end

    control:SetHidden(not data)
    return data ~= nil
end

local function SetAlignment(control, alignment, defaultAlignment)
    if(control == nil) then
        return
    end

    if(alignment == nil) then
        alignment = defaultAlignment
    end

    control:SetHorizontalAlignment(alignment)
end

local function IsScreenHeader(controls)
    return not controls[CENTER_BASELINE]
end

function BUI_StoreHeader_RefreshData(control, data)
    local controls = control.controls

    ProcessData(controls[TITLE], data.titleText)

    if data.titleTextAlignment ~= nil then
        SetAlignment(controls[TITLE], data.titleTextAlignment, IsScreenHeader(control.controls) and TEXT_ALIGN_CENTER or TEXT_ALIGN_LEFT)
    end
end

local function Tab_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)
    if data.canSelect == nil then
        data.canSelect = true
    end
    ZO_GamepadMenuHeaderTemplate_Setup(control, data, selected, selectedDuringRebuild, enabled, activated)

end

local function TabBar_OnDataChanged(control, newData, oldData, reselectingDuringRebuild)
    d("------------------------------")
    d(newData)
    if type(newData) == "table" then
        newData.callback()
        ddebug("CALLBACK CALLED LOL")
    end
end

function BUI_StoreHeader_Refresh(control, data, blockTabBarCallbacks)
    BUI_StoreHeader_RefreshData(control, data)

    control:GetNamedChild("TitleContainer"):GetNamedChild("Title"):SetText(data.titleText(data.name))

    if control.controls ~= nil then

        local tabBarControl = control.controls[TABBAR]
        tabBarControl:SetHidden(false)

        if not control.tabBar then
            local tabBarData = { attachedTo=control, parent=data.tabBarData.parent, onNext=data.tabBarData.onNext, onPrev = data.tabBarData.onPrev }
            control.tabBar = BUI_TabBarScrollList:New(tabBarControl, tabBarControl:GetNamedChild("LeftIcon"), tabBarControl:GetNamedChild("RightIcon"), tabBarData)

            control.tabBar.hideUnselectedControls = false

            control.tabBar:AddDataTemplate("BUI_GamepadTabBarTemplate", Tab_Setup, ZO_GamepadMenuEntryTemplateParametricListFunction, MenuEntryTemplateEquality)
        end

        if control.tabBar then


            local numEntries = 0

            if data.tabBarEntries then
                control.tabBar:Clear()
                for i, tabData in ipairs(data.tabBarEntries) do
                    if (tabData.visible == nil) or tabData.visible() then
                        control.tabBar:AddEntry("BUI_GamepadTabBarTemplate", tabData)
                        numEntries = numEntries + 1
                    end
                end
                control.tabBar:Commit()

            end

            -- if(blockTabBarCallbacks) then
            --     control.tabBar:RemoveOnSelectedDataChangedCallback(TabBar_OnDataChanged)
            -- else
            control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
            -- end
            -- --if data.activatedCallback then
            control.tabBar:SetOnActivatedChangedFunction(TabBar_OnDataChanged)
            -- --end

            --if(blockTabBarCallbacks) then
                control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
            --end

            control.tabBar:Activate()
        end
    end

    -- if control.tabBar then
    --     BUI_StoreHeader_RefreshData(control, data)
    --
    --     if(blockTabBarCallbacks) then
    --         control.tabBar:RemoveOnSelectedDataChangedCallback(TabBar_OnDataChanged)
    --     else
    --         control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
    --     end
    --
    --     if data.activatedCallback then
    --         control.tabBar:SetOnActivatedChangedFunction(data.activatedCallback)
    --     end
    --
    --     local pipsEnabled = false
    --     local tabBarControl = control.controls[TABBAR]
    --
    --     local pipsControl = nil
    --     local numEntries = 0
    --
    --     if data.tabBarEntries then
    --         control.tabBar:Clear()
    --         for i, tabData in ipairs(data.tabBarEntries) do
    --             if (tabData.visible == nil) or tabData.visible() then
    --                 control.tabBar:AddEntry("ZO_GamepadTabBarTemplate", tabData)
    --                 numEntries = numEntries + 1
    --             end
    --         end
    --         control.tabBar:Commit()
    --
    --     end
    --
    --     tabBarControl:SetHidden(numEntries == 0)
    --
    --
    --     if(blockTabBarCallbacks) then
    --         control.tabBar:SetOnSelectedDataChangedCallback(TabBar_OnDataChanged)
    --     end
    -- end
end
