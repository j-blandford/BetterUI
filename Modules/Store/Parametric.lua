
BUI_Store_ParametricList_Screen = ZO_Gamepad_ParametricList_Screen:Subclass()

function BUI_Store_ParametricList_Screen:New(...)
    local object = ZO_Gamepad_ParametricList_Screen.New(self)
    --object:Initialize(...)
    return object
end

function BUI_Store_ParametricList_Screen:Initialize(control, createTabBar, activateOnShow, scene)
    control.owner = self
    self.control = control

    local mask = control:GetNamedChild("Mask")

    local container = mask:GetNamedChild("Container")
    control.container = container

    self.activateOnShow = (activateOnShow ~= false) -- nil should be true
    self:SetScene(scene)

    local headerContainer = container:GetNamedChild("HeaderContainer")
    control.header = headerContainer.header
    self.headerFragment = ZO_ConveyorSceneFragment:New(headerContainer, ALWAYS_ANIMATE)

    self.header = control.header
    BUI.GenericHeader.Initialize(self.header, createTabBar)

    self.updateCooldownMS = 0

    self.lists = {}
    self:AddList("Main")
    self._currentList = nil
    self.addListTriggerKeybinds = false
    self.listTriggerKeybinds = nil
    self.listTriggerHeaderComparator = nil

    self:InitializeKeybindStripDescriptors()

    self.dirty = true
end
