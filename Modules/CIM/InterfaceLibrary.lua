local _

BUI_TEST_SCENE_NAME = "BUI_TEST_SCENE"

BUI.Interface.Window = ZO_Object:Subclass()

function BUI.Lib.CIM.SetTooltipWidth(width)
    -- Setup the larger and offset LEFT_TOOLTIP and background fragment so that the new inventory fits!
    GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT.control:SetWidth(width)
    GAMEPAD_TOOLTIPS.tooltips.GAMEPAD_LEFT_TOOLTIP.control:SetAnchor(3,GuiRoot,3, width+66, 54)
end

function BUI.Interface.Window:New(tlw_name, scene_name)
	local self = {}
	self.windowName = tlw_name
	self.control = BUI.WindowManager:CreateControlFromVirtual(tlw_name, GuiRoot, "BUI_GenericInterface")
	self.header = self.control:GetNamedChild("ContainerHeader")

	return self
end

function BUI.Interface.Window.Initialize(self)
	self.header.columns = {}

	self.header.columns[1] = CreateControlFromVirtual("Column".."1",self.header:GetNamedChild("HeaderColumnBar"),"BUI_GenericColumn_Label")
	self.header.columns[1]:SetText("Name")

	BUI_TEST_SCENE = ZO_InteractScene:New(BUI_TEST_SCENE_NAME, SCENE_MANAGER, ZO_TRADING_HOUSE_INTERACTION)
	--self.header:
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
        	BUI.Lib.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif(newState == SCENE_HIDING) then
           BUI.Lib.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif(newState == SCENE_HIDDEN) then

        end
    end
    SCENE_NAME:RegisterCallback("StateChange",  SceneStateChange)

end

function BUI.Interface.Window:ToggleScene()
	--SCENE_MANAGER:Show
	SCENE_MANAGER:Toggle(BUI_TEST_SCENE_NAME)
end

testWindow = BUI.Interface.Window:New("BUI_TestWindow")
testWindow.Initialize = BUI.Interface.Window.Initialize
testWindow.InitializeFragment = BUI.Interface.Window.InitializeFragment
testWindow.InitializeScene = BUI.Interface.Window.InitializeScene
testWindow.ToggleScene = BUI.Interface.Window.ToggleScene

testWindow:Initialize()
testWindow:InitializeFragment("BUI_TEST_FRAGMENT")
testWindow:InitializeScene(BUI_TEST_SCENE)

testWindow:ToggleScene()