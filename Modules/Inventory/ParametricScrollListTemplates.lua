-- Templated from "common/gamepad/zo_gamepadparametricscrolllisttemplates.lua" in order to heavily alter the function of the scrollList.
    -- Any better way to do this? please contact me!

ZO_TABBAR_MOVEMENT_TYPES = 
{
    PAGE_FORWARD = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST,
    PAGE_BACK = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST + 1,
    PAGE_NAVIGATION_FAILED = ZO_PARAMETRIC_MOVEMENT_TYPES.LAST + 2
}
ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS =
{
    [ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_NEXT] = SOUNDS.GAMEPAD_MENU_DOWN,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.MOVE_PREVIOUS] = SOUNDS.GAMEPAD_MENU_UP,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_NEXT] = SOUNDS.GAMEPAD_MENU_JUMP_DOWN,
    [ZO_PARAMETRIC_MOVEMENT_TYPES.JUMP_PREVIOUS] = SOUNDS.GAMEPAD_MENU_JUMP_UP,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_FORWARD] = SOUNDS.GAMEPAD_PAGE_FORWARD,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_BACK] = SOUNDS.GAMEPAD_PAGE_BACK,
    [ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED] = SOUNDS.GAMEPAD_PAGE_NAVIGATION_FAILED,
}
local function GamepadParametricScrollListPlaySound(movementType)
    PlaySound(ZO_PARAMETRIC_SCROLL_MOVEMENT_SOUNDS[movementType])
end

local GAMEPAD_DEFAULT_POST_PADDING = 5
local GAMEPAD_HEADER_SELECTED_PADDING = 0
local GAMEPAD_HEADER_DEFAULT_PADDING = 15

PARAMETRIC_SCROLL_LIST_VERTICAL = true
PARAMETRIC_SCROLL_LIST_HORIZONTAL = false
BUI_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE = 32
BUI_HORIZONTAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE = 32

local DEFAULT_EXPECTED_ENTRY_HEIGHT = 30
local DEFAULT_EXPECTED_HEADER_HEIGHT = 24

local function GetControlDimensionForMode(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetHeight() or control:GetWidth()
end
local function TransformAnchorOffsetsForMode(mode, offsetX, offsetY)
    if mode == PARAMETRIC_SCROLL_LIST_VERTICAL then
        return offsetY, offsetX
    end
    return offsetX, offsetY
end

local function GetStartOfControl(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetTop() or control:GetLeft()
end
local function GetEndOfControl(mode, control)
    return mode == PARAMETRIC_SCROLL_LIST_VERTICAL and control:GetBottom() or control:GetRight()
end







BUI_VerticalParametricScrollList = ZO_ParametricScrollList:Subclass()
function BUI_VerticalParametricScrollList:New(...)
    local list = ZO_ParametricScrollList.New(self, ...)

    list.EnsureValidGradient = function(self)
    ddebug("Ensuring valid gradient")
        if self.validateGradient and self.validGradientDirty then
            if self.mode == PARAMETRIC_SCROLL_LIST_VERTICAL then
                local listStart = GetStartOfControl(self.mode, self.scrollControl)
                local listEnd = GetEndOfControl(self.mode, self.scrollControl)
                local listMid = listStart + (GetControlDimensionForMode(self.mode, self.scrollControl) / 2.0)
                if self.alignToScreenCenter and self.alignToScreenCenterAnchor then
                    listMid = GetStartOfControl(self.mode, self.alignToScreenCenterAnchor)
                end
                listMid = listMid + self.fixedCenterOffset
                local hasHeaders = false
                for templateName, dataTypeInfo in pairs(self.dataTypes) do
                    if dataTypeInfo.hasHeader then
                        hasHeaders = true
                        break
                    end
                end
                local selectedControlBufferStart = 0
                if hasHeaders then
                    selectedControlBufferStart = selectedControlBufferStart - self.headerSelectedPadding + DEFAULT_EXPECTED_HEADER_HEIGHT
                end
                local selectedControlBufferEnd = DEFAULT_EXPECTED_ENTRY_HEIGHT
                if self.alignToScreenCenterExpectedEntryHalfHeight then
                    selectedControlBufferEnd = self.alignToScreenCenterExpectedEntryHalfHeight * 2.0
                end
                -- Have some small minimum effect
                local MINIMUM_ALLOWED_FADE_GRADIENT = 32
                local gradientMaxStart = zo_max(listMid - listStart - selectedControlBufferStart, MINIMUM_ALLOWED_FADE_GRADIENT)
                local gradientMaxEnd = zo_max(listEnd - listMid - selectedControlBufferEnd, MINIMUM_ALLOWED_FADE_GRADIENT)
                local gradientStartSize = zo_min(gradientMaxStart, BUI_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE)
                local gradientEndSize = zo_min(gradientMaxEnd, BUI_VERTICAL_PARAMETRIC_LIST_DEFAULT_FADE_GRADIENT_SIZE)
                local FIRST_FADE_GRADIENT = 1
                local SECOND_FADE_GRADIENT = 2
                local GRADIENT_TEX_CORD_0 = 0
                local GRADIENT_TEX_CORD_1 = 1
                local GRADIENT_TEX_CORD_NEG_1 = -1
                self.scrollControl:SetFadeGradient(FIRST_FADE_GRADIENT, GRADIENT_TEX_CORD_0, GRADIENT_TEX_CORD_1, gradientStartSize)
                self.scrollControl:SetFadeGradient(SECOND_FADE_GRADIENT, GRADIENT_TEX_CORD_0, GRADIENT_TEX_CORD_NEG_1, gradientEndSize)
            end
            self.validGradientDirty = false
        end
            ddebug("END Ensuring valid gradient")
    end
    return list
end

function BUI_VerticalParametricScrollList:Initialize(control)
    ZO_ParametricScrollList.Initialize(self, control, PARAMETRIC_SCROLL_LIST_VERTICAL, ZO_GamepadOnDefaultScrollListActivatedChanged)
    self:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING)
    self:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING)
    self:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)
    self.alignToScreenCenterExpectedEntryHalfHeight = 15
end









BUI_VerticalItemParametricScrollList = BUI_VerticalParametricScrollList:Subclass()
function BUI_VerticalItemParametricScrollList:New(control)
    local list = BUI_VerticalParametricScrollList.New(self, control)
    list:SetUniversalPostPadding(GAMEPAD_DEFAULT_POST_PADDING)
    return list
end









BUI_HorizontalScrollList_Gamepad = ZO_HorizontalScrollList:Subclass()

function BUI_HorizontalScrollList_Gamepad:New(...)
    return ZO_HorizontalScrollList.New(self, ...)
end

function BUI_HorizontalScrollList_Gamepad:Initialize(control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    ZO_HorizontalScrollList.Initialize(self, control, templateName, numVisibleEntries, setupFunction, equalityFunction, onCommitWithItemsFunction, onClearedFunction)
    self:SetActive(true)
    self.movementController = ZO_MovementController:New(MOVEMENT_CONTROLLER_DIRECTION_HORIZONTAL)
end

function BUI_HorizontalScrollList_Gamepad:UpdateAnchors(primaryControlOffsetX, initialUpdate, reselectingDuringRebuild)
    if self.isUpdatingAnchors then return end
    self.isUpdatingAnchors = true

    local oldPrimaryControlOffsetX = self.lastPrimaryControlOffsetX or 0
    local oldVisibleIndex = zo_round(oldPrimaryControlOffsetX / self.controlEntryWidth)
    local newVisibleIndex = zo_round(primaryControlOffsetX / self.controlEntryWidth)

    local visibleIndicesChanged = oldVisibleIndex ~= newVisibleIndex
    local oldData = self.selectedData
    for i, control in ipairs(self.controls) do
        local index = self:CalculateOffsetIndex(i, newVisibleIndex)
        if not self.allowWrapping and (index >= #self.list or index < 0) then
            control:SetHidden(true)
        else
            control:SetHidden(false)

            if initialUpdate or visibleIndicesChanged then
                local dataIndex = self:CalculateDataIndexFromOffset(index)
                local selected = i == self.halfNumVisibleEntries + 1

                local data = self.list[dataIndex]
                if selected then
                    self.selectedData = data
                    if not reselectingDuringRebuild and self.selectionHighlightAnimation and not self.selectionHighlightAnimation:IsPlaying() then
                        self.selectionHighlightAnimation:PlayFromStart()
                    end
                    if not initialUpdate and not reselectingDuringRebuild and self.dragging then
                        self.onPlaySoundFunction(ZO_HORIZONTALSCROLLLIST_MOVEMENT_TYPES.INITIAL_UPDATE)
                    end
                end
                self.setupFunction(control, data, selected, reselectingDuringRebuild, self.enabled, self.selectedFromParent)
            end

            local offsetX = primaryControlOffsetX + index * self.controlEntryWidth
            control:SetAnchor(CENTER, self.control, CENTER, offsetX, 25)

            if self.minScale and self.maxScale then
                local amount = ZO_EaseInQuintic(zo_max(1.0 - zo_abs(offsetX) / (self.control:GetWidth() * .5), 0.0))
                control:SetScale(zo_lerp(self.minScale, self.maxScale, amount))
            end
        end
    end

    self.lastPrimaryControlOffsetX = primaryControlOffsetX

    self.leftArrow:SetEnabled(self.enabled and (self.allowWrapping or newVisibleIndex ~= 0))
    self.rightArrow:SetEnabled(self.enabled and (self.allowWrapping or newVisibleIndex ~= 1 - #self.list))

    self.isUpdatingAnchors = false

    if (self.selectedData ~= oldData or initialUpdate) and self.onSelectedDataChangedCallback then
        self.onSelectedDataChangedCallback(self.selectedData, oldData, reselectingDuringRebuild)
    end
end

function BUI_HorizontalScrollList_Gamepad:SetOnActivatedChangedFunction(onActivatedChangedFunction)
    self.onActivatedChangedFunction = onActivatedChangedFunction
    self.dirty = true
end

function BUI_HorizontalScrollList_Gamepad:Commit()
    ZO_HorizontalScrollList.Commit(self)

    local hideArrows = not self.active
    self.leftArrow:SetHidden(hideArrows)
    self.rightArrow:SetHidden(hideArrows)
end

function BUI_HorizontalScrollList_Gamepad:SetActive(active)
    if (self.active ~= active) or self.dirty then
        self.active = active
        self.dirty = false

        if self.active then
            DIRECTIONAL_INPUT:Activate(self)
            self.leftArrow:SetHidden(false)
            self.rightArrow:SetHidden(false)
        else
            DIRECTIONAL_INPUT:Deactivate(self)
            self.leftArrow:SetHidden(true)
            self.rightArrow:SetHidden(true)
        end

        if self.onActivatedChangedFunction then
            self.onActivatedChangedFunction(self, self.active)
        end
    end
end

function BUI_HorizontalScrollList_Gamepad:Activate()
    self:SetActive(true)
end

function BUI_HorizontalScrollList_Gamepad:Deactivate()
    self:SetActive(false)
end

function BUI_HorizontalScrollList_Gamepad:UpdateDirectionalInput()
    local result = self.movementController:CheckMovement()
    if result == MOVEMENT_CONTROLLER_MOVE_NEXT then
        self:MoveLeft()
    elseif result == MOVEMENT_CONTROLLER_MOVE_PREVIOUS then
        self:MoveRight()
    end
end












BUI_HorizontalParametricScrollList = ZO_ParametricScrollList:Subclass()
function BUI_HorizontalParametricScrollList:New(control, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    onActivatedChangedFunction = onActivatedChangedFunction or ZO_GamepadOnDefaultScrollListActivatedChanged
    local list = ZO_ParametricScrollList.New(self, control, PARAMETRIC_SCROLL_LIST_HORIZONTAL, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    list:SetHeaderPadding(GAMEPAD_HEADER_DEFAULT_PADDING, GAMEPAD_HEADER_SELECTED_PADDING)
    list:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)
    return list
end

function BUI_HorizontalListEntrySetup(control, data, selected, reselectingDuringRebuild, enabled, selectedFromParent)
      control:SetText(data.text)
    
    local color = selectedFromParent and ZO_SELECTED_TEXT or ZO_DISABLED_TEXT
    control:SetColor(color:UnpackRGBA())
end

function BUI_HorizontalListRow_Initialize(self, setupFunction, equalityFunction)
    self.GetHeight = function(control)
                         return 50
                     end
    self.label = self:GetNamedChild("Name")
    self.horizontalListControl = self:GetNamedChild("HorizontalList")
    self.horizontalListObject = BUI_HorizontalScrollList_Gamepad:New(self.horizontalListControl, "ZO_GamepadHorizontalListEntry", 1, setupFunction, equalityFunction)
    self.horizontalListObject:SetAllowWrapping(true)
end











ZO_TABBAR_ICON_WIDTH = 50
ZO_TABBAR_ICON_HEIGHT = 50
BUI_TabBarScrollList = BUI_HorizontalParametricScrollList:Subclass()
function BUI_TabBarScrollList:New(control, leftIcon, rightIcon, data, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    local list = BUI_HorizontalParametricScrollList.New(self, control, onActivatedChangedFunction, onCommitWithItemsFunction, onClearedFunction)
    list:EnableAnimation(true)
    list:SetDirectionalInputEnabled(false)
    list:SetHideUnselectedControls(false)
    local function CreateButtonIcon(name, parent, keycode, anchor)
        local buttonIcon = CreateControl(name, parent, CT_BUTTON)
        buttonIcon:SetNormalTexture(ZO_Keybindings_GetTexturePathForKey(keycode))
        buttonIcon:SetDimensions(ZO_TABBAR_ICON_WIDTH, ZO_TABBAR_ICON_HEIGHT)
        buttonIcon:SetAnchor(anchor, control, anchor)
        return buttonIcon
    end

    list.attachedTo = data.attachedTo
    list.parent = data.parent
    list.MoveNextCallback = data.onNext
    list.MovePrevCallback = data.onPrev

    list.leftIcon = leftIcon or CreateButtonIcon("$(parent)LeftIcon", control, KEY_GAMEPAD_LEFT_SHOULDER, LEFT)
    list.rightIcon = rightIcon or CreateButtonIcon("$(parent)RightIcon", control, KEY_GAMEPAD_RIGHT_SHOULDER, RIGHT)
    list.entryAnchors = { CENTER, CENTER }
    list:InitializeKeybindStripDescriptors()
    list.control = control
    list:SetPlaySoundFunction(GamepadParametricScrollListPlaySound)
    return list
end
function BUI_TabBarScrollList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    BUI_HorizontalParametricScrollList.Activate(self)
end
function BUI_TabBarScrollList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    BUI_HorizontalParametricScrollList.Deactivate(self)
end
function BUI_TabBarScrollList:InitializeKeybindStripDescriptors()
    self.keybindStripDescriptor =
    {
        {
            keybind = "UI_SHORTCUT_LEFT_SHOULDER",
            ethereal = true,
            callback = function()
                if self.active then
                    self:MovePrevious(BUI.settings.Inventory.enableWrapping)
                end
            end,
        },
        {
            keybind = "UI_SHORTCUT_RIGHT_SHOULDER",
            ethereal = true,
            callback = function()
                if self.active then
                    self:MoveNext(BUI.settings.Inventory.enableWrapping)
                end
            end,
        },
    }
end
function BUI_TabBarScrollList:Commit(dontReselect)
    if #self.dataList > 1 then
        self.leftIcon:SetHidden(false)
        self.rightIcon:SetHidden(false)
    else
        self.leftIcon:SetHidden(true)
        self.rightIcon:SetHidden(true)
    end
    BUI_HorizontalParametricScrollList.Commit(self, dontReselect)
    self:RefreshPips()
end
function BUI_TabBarScrollList:SetPipsEnabled(enabled, divider)
    self.pipsEnabled = enabled
    if not divider then
        -- There is a default divider in the tabbar control
        divider = self.control:GetNamedChild("Divider")
    end
    if not self.pips and enabled then
        self.pips = ZO_GamepadPipCreator:New(divider)
    end
    self:RefreshPips()
end
function BUI_TabBarScrollList:RefreshPips()
    if not self.pipsEnabled then
        if self.pips then
            self.pips:RefreshPips()
        end
        return
    end
    local selectedIndex = self.targetSelectedIndex or self.selectedIndex
    local numPips = 0
    local selectedPipIndex = 0
    for i = 1,#self.dataList do
        if self.dataList[i].canSelect ~= false then
            numPips = numPips + 1
            local active = (selectedIndex == i)
            if active then
                selectedPipIndex = numPips
            end
        end
    end
    self.pips:RefreshPips(numPips, selectedPipIndex)
end
function BUI_TabBarScrollList:UpdateHeaderText()
    if self.attachedTo ~= nil then
        local selectedIndex = self.targetSelectedIndex or self.selectedIndex
        self.attachedTo:GetNamedChild("TitleContainer"):GetNamedChild("Title"):SetText(self.dataList[selectedIndex].text)
    end
end
function BUI_TabBarScrollList:SetSelectedIndex(selectedIndex, allowEvenIfDisabled, forceAnimation)
    BUI_HorizontalParametricScrollList.SetSelectedIndex(self, selectedIndex, allowEvenIfDisabled, forceAnimation)
    self:RefreshPips()
end
function BUI_TabBarScrollList:MovePrevious(allowWrapping, suppressFailSound)
    local succeeded = ZO_ConveyorSceneFragment_ReverseAnimationDirectionForBehavior(ZO_ParametricScrollList.MovePrevious, self)
    if not succeeded and allowWrapping then
        self:SetLastIndexSelected() --Wrap
        succeeded = true
    end
    if succeeded then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_BACK)
        self:UpdateHeaderText()
    elseif not suppressFailSound then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED)
    end
    if(self.MovePrevCallback ~= nil) then self.MovePrevCallback(self.parent, succeeded) end
    return succeeded
end
function BUI_TabBarScrollList:MoveNext(allowWrapping, suppressFailSound)
    local succeeded = ZO_ParametricScrollList.MoveNext(self)
    if not succeeded and allowWrapping then
        ZO_ConveyorSceneFragment_ReverseAnimationDirectionForBehavior(ZO_ParametricScrollList.SetFirstIndexSelected, self) --Wrap
        succeeded = true
    end
    if succeeded then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_FORWARD)
        self:UpdateHeaderText()
    elseif not suppressFailSound then
        self.onPlaySoundFunction(ZO_TABBAR_MOVEMENT_TYPES.PAGE_NAVIGATION_FAILED)
    end
    if(self.MoveNextCallback ~= nil) then self.MoveNextCallback(self.parent, succeeded) end
    return succeeded
end














local SUB_LIST_CENTER_OFFSET = -50
BUI_VerticalParametricScrollListSubList = BUI_VerticalParametricScrollList:Subclass()
function BUI_VerticalParametricScrollListSubList:New(control, parentList, parentKeybinds, onDataChosen)
    local manager = BUI_VerticalParametricScrollList.New(self, control, parentList, parentKeybinds, onDataChosen)
    return manager
end
function BUI_VerticalParametricScrollListSubList:Initialize(control, parentList, parentKeybinds, onDataChosen)
    BUI_VerticalParametricScrollList.Initialize(self, control)
    self.parentList = parentList
    self.parentKeybinds = parentKeybinds
    self.onDataChosen = onDataChosen
    self:InitializeKeybindStrip()
    self.control:SetHidden(true)
    self:SetFixedCenterOffset(SUB_LIST_CENTER_OFFSET)
end
function BUI_VerticalParametricScrollListSubList:Commit(dontReselect)
    ZO_ParametricScrollList.Commit(self, dontReselect)
    self:UpdateAnchors(self.targetSelectedIndex)
    self.onDataChosen(self:GetTargetData())
end
function BUI_VerticalParametricScrollListSubList:CancelSelection()
    local indexToReturnTo = zo_clamp(self.indexOnOpen, 1, #self.dataList)
    self.targetSelectedIndex = indexToReturnTo
    self:UpdateAnchors(indexToReturnTo)
    self.onDataChosen(self:GetDataForDataIndex(indexToReturnTo))
end
function BUI_VerticalParametricScrollListSubList:InitializeKeybindStrip()
    local function OnEntered()
        self.onDataChosen(self:GetTargetData())
        self.didSelectEntry = true
        self:Deactivate()
    end
    local function OnBack()
        self:Deactivate()
    end
    self.keybindStripDescriptor = {}
    ZO_Gamepad_AddForwardNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnEntered)
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON, OnBack)
    ZO_Gamepad_AddListTriggerKeybindDescriptors(self.keybindStripDescriptor, self)
end
function BUI_VerticalParametricScrollListSubList:Activate()
    self.parentList:Deactivate()
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.parentKeybinds)
    BUI_VerticalParametricScrollList.Activate(self)
    KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
    self.control:SetHidden(false)
    self.indexOnOpen = self.selectedIndex
    self.didSelectEntry = false
end
function BUI_VerticalParametricScrollListSubList:Deactivate()
    if not self.active then
        return
    end
    if self.active and not self.didSelectEntry then
        self:CancelSelection()
    end
    BUI_VerticalParametricScrollList.Deactivate(self)
    KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
    self.parentList:Activate()
    KEYBIND_STRIP:AddKeybindButtonGroup(self.parentKeybinds)
    self.control:SetHidden(true)
end