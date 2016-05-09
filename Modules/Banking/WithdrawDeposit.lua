local BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE_NAME = "bui_banking_withdrawdepositgold"

BUI.Banking.WithdrawDepositGold = ZO_Object:Subclass()

function BUI.Banking.WithdrawDepositGold:New(...)
    local object = ZO_Object.New(self)
    object:Initialize(...)
    return object
end

function BUI.Banking.WithdrawDepositGold:Initialize(control)
    self.control = control
    self.isInitialized = false

    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_FRAGMENT = ZO_SimpleSceneFragment:New(control) -- **Replaces** the old inventory with a new one defined in "Templates/GamepadInventory.xml"
    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_FRAGMENT:SetHideOnSceneHidden(true)


    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE = ZO_InteractScene:New(BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE_NAME, SCENE_MANAGER, BANKING_INTERACTION)
    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE:AddFragment(GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_FRAGMENT)
    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE:AddFragment(GAMEPAD_NAV_QUADRANT_1_BACKGROUND_FRAGMENT)
    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE:AddFragment(MINIMIZE_CHAT_FRAGMENT)

    local StateChanged = function(oldState, newState)
        if newState == SCENE_SHOWING then
            self:PerformDeferredInitialization()
            self:RegisterForEvents()
            self:SetTitleText()
            self:UpdateInput()
            self.selector:Activate()
            KEYBIND_STRIP:AddKeybindButtonGroup(self.keybindStripDescriptor)
            -- Setup the larger and offset LEFT_TOOLTIP and background fragment
            BUI.CIM.SetTooltipWidth(BUI_GAMEPAD_DEFAULT_PANEL_WIDTH)
        elseif newState == SCENE_HIDDEN then
            self.selector:Clear()
            self.selector:Deactivate()
            self:UnregisterForEvents()
            KEYBIND_STRIP:RemoveKeybindButtonGroup(self.keybindStripDescriptor)
            BUI.CIM.SetTooltipWidth(BUI_ZO_GAMEPAD_DEFAULT_PANEL_WIDTH)
        end
    end
    GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE:RegisterCallback("StateChange", StateChanged)
end

function BUI.Banking.WithdrawDepositGold:UpdateInput()
    if self.initData and self.initData.currentQueryAmountFunction then
        local amount = self.initData.currentQueryAmountFunction()
        self.selector:SetMaxValue(amount)
        local hasEnough = (amount >= self.selector:GetValue())
        if hasEnough ~= self.hasEnough then
            self.hasEnough = hasEnough
            self.selector:SetTextColor(hasEnough and ZO_SELECTED_TEXT or ZO_ERROR_COLOR)
            KEYBIND_STRIP:UpdateKeybindButtonGroup(self.keybindStripDescriptor) -- The keybindings need visible to check for self.hasEnough
        end
    end
end

function BUI.Banking.WithdrawDepositGold:PerformDeferredInitialization()
    if self.isInitialized then return end

    self:InitializeKeybindStrip()
    self:InitializeHeader()

    local selectorChild = self.control:GetNamedChild("InputContainer"):GetNamedChild("Selector")
    self.selector = ZO_CurrencySelector_Gamepad:New(selectorChild)
    self.selector:SetClampValues(true)

    self.isInitialized = true
end

function BUI.Banking.WithdrawDepositGold:RegisterForEvents()
    local function OnUpdateEvent()
        self:UpdateInput()
        self:RefreshHeader()
    end

    self.control:RegisterForEvent(EVENT_MONEY_UPDATE, OnUpdateEvent)
    self.control:RegisterForEvent(EVENT_BANKED_MONEY_UPDATE, OnUpdateEvent)
    self.selector:RegisterCallback("OnValueChanged", OnUpdateEvent)
end

function BUI.Banking.WithdrawDepositGold:UnregisterForEvents()
    self.control:UnregisterForEvent(EVENT_MONEY_UPDATE)
    self.control:UnregisterForEvent(EVENT_BANKED_MONEY_UPDATE)
    self.selector:UnregisterCallback("OnValueChanged")
end

function BUI.Banking.WithdrawDepositGold:InitializeKeybindStrip()
    self.keybindStripDescriptor =
    {
        {
            alignment = KEYBIND_STRIP_ALIGN_LEFT,
            name = GetString(SI_GAMEPAD_SELECT_OPTION),
            keybind = "UI_SHORTCUT_PRIMARY",
            visible = function()
                return self.hasEnough
            end,
            callback = function()
                local amount = self.selector:GetValue()
                self.initData.selectFunc(amount)
                SCENE_MANAGER:HideCurrentScene()
            end,
        }
    }
    ZO_Gamepad_AddBackNavigationKeybindDescriptors(self.keybindStripDescriptor, GAME_NAVIGATION_TYPE_BUTTON)
end

local function UpdateCarriedGold(control)
    return SetSimpleCurrency(control, GetCurrentMoney())
end

local function UpdateBankedGold(control)
    return SetSimpleCurrency(control, GetBankedMoney())
end

function BUI.Banking.WithdrawDepositGold:InitializeHeader()
    self.header = self.control:GetNamedChild("HeaderContainer"):GetNamedChild("Header")
    ZO_GamepadGenericHeader_Initialize(self.header, ZO_GAMEPAD_HEADER_TABBAR_DONT_CREATE)

    self.headerData = {
        data1HeaderText = GetString(SI_CURRENCY_YOUR_GOLD),
        --data1Text = UpdateCarriedGold,

        data2HeaderText = GetString(SI_CURRENCY_YOUR_BANKED_GOLD),
       -- data2Text = UpdateBankedGold,
    }

    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function BUI.Banking.WithdrawDepositGold:RefreshHeader()
    ZO_GamepadGenericHeader_Refresh(self.header, self.headerData)
end

function BUI.Banking.WithdrawDepositGold:SetTitleText()
    if self.initData then
        self.headerData.titleText = self.initData.title
        self:RefreshHeader()
    end
end

local function WithdrawMoney(amount)
    WithdrawMoneyFromBank(amount)
    local alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_WITHDRAWN, ZO_CurrencyControl_FormatCurrency(amount), GOLD_ICON_16)
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, alertString)
end

local function DepositMoney(amount)
    DepositMoneyIntoBank(amount)
    local alertString = zo_strformat(SI_GAMEPAD_BANK_GOLD_AMOUNT_DEPOSITED, ZO_CurrencyControl_FormatCurrency(amount), GOLD_ICON_16)
    ZO_AlertNoSuppression(UI_ALERT_CATEGORY_ALERT, nil, alertString)
end

local WITHDRAW_INIT_DATA =
{
    title = GetString(SI_BANK_WITHDRAW_GOLD_TITLE),
    selectFunc = WithdrawMoney,
    currentQueryAmountFunction = GetBankedMoney,
}

local DEPOSIT_INIT_DATA =
{
    title = GetString(SI_BANK_DEPOSIT_GOLD_TITLE),
    selectFunc = DepositMoney,
    currentQueryAmountFunction = GetCurrentMoney,
}

local function PushWithdrawDepositGoldScene()
    SCENE_MANAGER:Push(BANKING_WITHDRAW_DEPOSIT_GOLD_SCENE_NAME)
end

function BUI.Banking.WithdrawDepositGold:ShowWithdraw()
    self.initData = WITHDRAW_INIT_DATA
    PushWithdrawDepositGoldScene()
end

function BUI.Banking.WithdrawDepositGold:ShowDeposit()
    self.initData = DEPOSIT_INIT_DATA
    PushWithdrawDepositGoldScene()
end

GAMEPAD_BANKING_WITHDRAW_DEPOSIT_GOLD = BUI.Banking.WithdrawDepositGold:New(BUI_BankingWithdrawDepositGold)