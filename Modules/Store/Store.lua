BUI_STORE_SCENE_NAME = "bui_gamepad_store"


BUI.Store.Buy = ZO_GamepadStoreBuy:Subclass()

function BUI.Store.Buy:New(...)
	local object = ZO_GamepadStoreBuy.New(self, ...)
	--object:Initialize(self, ...)
    return object
end

function BUI.Store.Buy:Initialize(scene)
    ZOS_GamepadStoreListComponent.Initialize(self, scene, ZO_MODE_STORE_BUY, GetString(SI_STORE_MODE_BUY))

    self.fragment:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:RegisterEvents()
            self.list:UpdateList()
			BUI.Store.Window:UpdateRightTooltip(self.list, ZO_MODE_STORE_BUY)
        elseif newState == SCENE_HIDING then
            self:UnregisterEvents()
            GAMEPAD_TOOLTIPS:ClearTooltip(GAMEPAD_RIGHT_TOOLTIP)
        end
	end)

    self:InitializeKeybindStrip()
    self:CreateModeData(SI_STORE_MODE_BUY, ZO_MODE_STORE_BUY, "EsoUI/Art/Vendor/vendor_tabIcon_buy_up.dds", fragment, self.keybindStripDescriptor)
end


local function OnOpenStore()
    if IsInGamepadPreferredMode() then
        local componentTable = {}

        if not IsStoreEmpty() then
            table.insert(componentTable, ZO_MODE_STORE_BUY)
        end

        table.insert(componentTable, ZO_MODE_STORE_SELL)
        table.insert(componentTable, ZO_MODE_STORE_BUY_BACK)

        if CanStoreRepair() then
            table.insert(componentTable, ZO_MODE_STORE_REPAIR)
        end

        BUI.Store.Window:SetActiveComponents(componentTable)
        SCENE_MANAGER:Show(BUI_STORE_SCENE_NAME)
    end
end

local function OnCloseStore()
    if IsInGamepadPreferredMode() then
        -- Ensure that all dialogs related to the store close on interaction end
        ZO_Dialogs_ReleaseDialog("REPAIR_ALL")

        SCENE_MANAGER:Hide(BUI_STORE_SCENE_NAME)
    end
end

BUI.Store.Class = ZO_GamepadStoreManager:Subclass()

local DONT_ACTIVATE_LIST_ON_SHOW = false


function BUI.Store.Class:New(...)
    return ZO_GamepadStoreManager.New(self, ...)
end


function BUI.Store.Class:Initialize(control)
    self.control = control
    self.sceneName = BUI_STORE_SCENE_NAME

    BUI_STORE_SCENE = ZO_InteractScene:New(self.sceneName, SCENE_MANAGER, STORE_INTERACTION)

    BUI_Gamepad_ParametricList_Screen:Initialize(control, true, DONT_ACTIVATE_LIST_ON_SHOW, BUI_STORE_SCENE)

	self.spinner = control:GetNamedChild("SpinnerContainer")
	self.spinner:InitializeSpinner()

	self.control:RegisterForEvent(EVENT_OPEN_STORE, OnOpenStore)
	self.control:RegisterForEvent(EVENT_CLOSE_STORE, OnCloseStore)

	self:InitializeKeybindStrip()
    self.components = {}

end

function BUI.Store.Class:SetActiveComponents(componentTable)
    self.activeComponents = {}
	ddebug("SetActiveComponents:")
	d(componentTable)
	ddebug("---------------------")
	d(self.components)
    for index, componentMode in ipairs(componentTable) do
        local component = self.components[componentMode]
        component:Refresh()
        table.insert(self.activeComponents, component)
    end
    self:RebuildHeaderTabs()
end

function BUI.Store.Class:AddComponent(component)
    self.components[component:GetStoreMode()] = component
end
