local _

local ACTIVATE_SPINNER = true
local DEACTIVATE_SPINNER = false
local DEFAULT_ROW_TEMPLATE = "BUI_GenericEntry_Template"

BUI_TEST_SCENE_NAME = "BUI_TEST_SCENE"

local BANKING_INTERACTION =
{
    type = "Banking",
    interactTypes = { INTERACTION_BANK },
}

function BUI.CIM.SetTooltipWidth(width)
    -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(width)
    GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, width+66, 54)
end

BUI.Interface.Window = ZO_Object:Subclass()

function BUI.Interface.Window:New(...)
	local object = ZO_Object.New(self)
    object:Initialize(...)
	return object
end

function BUI.Interface.Window:Initialize(tlw_name, scene_name)
    self.windowName = tlw_name
    self.control = BUI.WindowManager:CreateControlFromVirtual(tlw_name, GuiRoot, "BUI_GenericInterface")
    self.header = self.control:GetNamedChild("ContainerHeader")
    self.footer = self.control:GetNamedChild("ContainerFooter")

    self.spinner = self.control:GetNamedChild("ContainerList"):GetNamedChild("SpinnerContainer")
    self.spinner:InitializeSpinner()
    self:DeactivateSpinner()

    self.header.MoveNext = function() self:OnTabNext() end
    self.header.MovePrev = function() self:OnTabPrev() end

	self.header.columns = {}

    BUI_TEST_SCENE = ZO_InteractScene:New(BUI_TEST_SCENE_NAME, SCENE_MANAGER, BANKING_INTERACTION)

    self:InitializeFragment("BUI_TEST_FRAGMENT")
    self:InitializeScene(BUI_TEST_SCENE)

    self:InitializeList()
end

function BUI.Interface.Window:SetSpinnerValue(max, value)
    self.spinner:SetMinMax(1, max)
    self.spinner:SetValue(value)
end

function BUI.Interface.Window:ActivateSpinner()
    self.spinner:SetHidden(false)
    self.spinner:Activate()
end

function BUI.Interface.Window:DeactivateSpinner()
    self.spinner:SetValue(1)
    self.spinner:SetHidden(true)
    self.spinner:Deactivate()
end

function BUI.Interface.Window:UpdateSpinnerConfirmation(activateSpinner, list)
    self.confirmationMode = activateSpinner
    if activateSpinner then
        self:ActivateSpinner()
        --self.spinner:AnchorToSelectedListEntry(list)
        --ZO_GamepadGenericHeader_Deactivate(self.header)

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.coreKeybinds)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
    else
        self:DeactivateSpinner()
        --ZO_GamepadGenericHeader_Activate(self.header)

        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.spinnerKeybindStripDescriptor)
        KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
    end

    list:RefreshVisible()
    self:ApplySpinnerMinMax(activateSpinner)
    list:SetDirectionalInputEnabled(not activateSpinner)
end

function BUI.Interface.Window:ApplySpinnerMinMax(toggleValue)
    if(toggleValue) then
        KEYBIND_STRIP:RemoveKeybindButtonGroup(self.triggerSpinnerBinds)
    else
        KEYBIND_STRIP:AddKeybindButtonGroup(self.triggerSpinnerBinds)
    end
end

-- GetList() can be extended to allow for multiple lists in one Window object
function BUI.Interface.Window:GetList()
    return self.list
end


function BUI.Interface.Window:InitializeKeybind()
    self.coreKeybinds = {
    }

    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.mainKeybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON) -- "Back"

    self.triggerSpinnerBinds = {}
end


function BUI.Interface.Window:InitializeList(listName)
    self.list = BUI_VerticalItemParametricScrollList:New(self.control:GetNamedChild("Container"):GetNamedChild("List")) -- replace the itemList with my own generic one (with better gradient size, etc.)

    self:GetList():SetAlignToScreenCenter(true, 30)

    self:GetList().maxOffset = 0
    self:GetList().headerDefaultPadding = 15
    self:GetList().headerSelectedPadding = 0
    self:GetList().universalPostPadding = 5
end

-- Overridden
function BUI.Interface.Window:RefreshList()
end

-- Overridden
function BUI.Interface.Window:OnItemSelectedChange()
end

function BUI.Interface.Window:SetupList(rowTemplate, SetupFunct)
    self.itemListTemplate = rowTemplate
    self:GetList():AddDataTemplate(rowTemplate, SetupFunct, BUI_GamepadMenuEntryTemplateParametricListFunction)
end

function BUI.Interface.Window:AddEntryToList(data)
    self:GetList():AddEntry(self.itemListTemplate, data)
    self:GetList():Commit()
end

function BUI.Interface.Window:AddColumn(columnName, xOffset)
    local colNumber = #self.header.columns + 1
    self.header.columns[colNumber] = CreateControlFromVirtual("Column"..colNumber,self.header:GetNamedChild("HeaderColumnBar"),"BUI_GenericColumn_Label")
    self.header.columns[colNumber]:SetAnchor(LEFT, self.header:GetNamedChild("HeaderColumnBar"), BOTTOMLEFT, xOffset, 95)
    self.header.columns[colNumber]:SetText(columnName)
end

function BUI.Interface.Window:SetTitle(headerText)
    self.header:GetNamedChild("Header"):GetNamedChild("TitleContainer"):GetNamedChild("Title"):SetText(headerText)
end

function BUI.Interface.Window:RefreshVisible()
    self:RefreshList()
    -- self.list.selectedDataCallback = function(list, selectedData) 
    --     ddebug("SetOnSelectedDataChangedCallback called")
    --     self.currentSelection = selectedData
    --     self:OnItemSelectedChange(selectedData) 
    -- end
    self:GetList():RefreshVisible()
end

function BUI.Interface.Window:SetOnSelectedDataChangedCallback(selectedDataCallback)
    self.selectedDataCallback = selectedDataCallback
end

function BUI.Interface.Window:InitializeFragment()
	self.fragment = ZO_SimpleSceneFragment:New(self.control)
    self.fragment:SetHideOnSceneHidden(true)
end

function BUI.Interface.Window:InitializeScene(SCENE_NAME)
    self.sceneName = SCENE_NAME
    SCENE_NAME:AddFragmentGroup(FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW)
    SCENE_NAME:AddFragmentGroup(FRAGMENT_GROUP.FRAME_TARGET_GAMEPAD)
    SCENE_NAME:AddFragment(self.fragment)
    SCENE_NAME:AddFragment(FRAME_EMOTE_FRAGMENT_INVENTORY)
    SCENE_NAME:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    SCENE_NAME:AddFragment(MINIMIZE_CHAT_FRAGMENT)
    SCENE_NAME:AddFragment(GAMEPAD_MENU_SOUND_FRAGMENT)

    local function SceneStateChange(oldState, newState)
        if(newState == SCENE_SHOWING) then
            KEYBIND_STRIP:AddKeybindButtonGroup(self.coreKeybinds)
        	BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif(newState == SCENE_HIDING) then
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.coreKeybinds)
           BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif(newState == SCENE_HIDDEN) then

        end
    end
    SCENE_NAME:RegisterCallback("StateChange",  SceneStateChange)

end

function BUI.Interface.Window:ToggleScene()
	--SCENE_MANAGER:Show
	SCENE_MANAGER:Toggle(BUI_TEST_SCENE_NAME)
end

function BUI.Interface.Window:OnTabNext()
    ddebug("OnTabNext")
end

function BUI.Interface.Window:OnTabPrev()
    ddebug("OnTabPrev")
end