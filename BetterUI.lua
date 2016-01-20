local _
local LAM = LibStub:GetLibrary("LibAddonMenu-2.0")

function BUI.SetupOptionsMenu()

	local panelData = {
		type = "panel",
		name = BUI.name,
		displayName = "Better gamepad interface Settings",
		author = "prasoc",
		version = BUI.version,
		slashCommand = "/bui",	--(optional) will register a keybind to open to this panel
		registerForRefresh = true,	--boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
		registerForDefaults = false,	--boolean (optional) (will set all options controls back to default values)
	}

	local optionsTable = {
		[1] = {
			type = "header",
			name = "General Settings",
			width = "full",
		},
		[2] = {
			type = "description",
			title = nil,
			text = "Toggle main addon functions here",
			width = "full",
		},
		[3] = {
			type = "checkbox",
			name = "Unit Price in Guild Store",
			tooltip = "Displays a price per unit in guild store listings",
			getFunc = function() return BUI.settings.showUnitPrice end,
			setFunc = function(value) BUI.settings.showUnitPrice = value end,
			width = "full",
		},
		[4] = {
			type = "checkbox",
			name = "MasterMerchant Price in Guild Store",
			tooltip = "Displays the MM percentage in guild store listings",
			getFunc = function() return BUI.settings.showMMPrice end,
			setFunc = function(value) BUI.settings.showMMPrice = value end,
			width = "full",
		},
		[5] = {
			type = "checkbox",
			name = "Display Daily Writ helper unit",
			tooltip = "Displays the daily writ, and progress, at each crafting station",
			getFunc = function() return BUI.settings.showWritHelper end,
			setFunc = function(value) BUI.settings.showWritHelper = value end,
			width = "full",
		},
		[6] = {
			type = "submenu",
			name = "Target Frame Display Options",
			controls = {
				[1] = {
					type = "checkbox",
					name = "Display the account name next to the character name?",
					getFunc = function() return BUI.settings.showAccountName end,
					setFunc = function(value) BUI.settings.showAccountName = value end,
					width = "full",
				},
				[2] = {
					type = "colorpicker",
					name = "Character name colour",
					getFunc = function() return unpack(BUI.settings.showCharacterColor) end,
					setFunc = function(r,g,b,a) BUI.settings.showCharacterColor={r,g,b,a} end,
					width = "full",	--or "half" (optional)
				}
			}
		}
	}
	LAM:RegisterAddonPanel("NewUI", panelData)
	LAM:RegisterOptionControls("NewUI", optionsTable)
end

function BUI.Hook(control, method, postHookFunction, overwriteOriginal)
	if control == nil then return end

	local originalMethod = control[method]
	control[method] = function(self, ...)
		if(overwriteOriginal == false) then originalMethod(self, ...) end
		postHookFunction(self, ...)
	end
end

local function AddInfo_Gamepad(tooltip, itemLink)
	if itemLink then

		local tipLine, avePrice, graphInfo = MasterMerchant:itemPriceTip(itemLink, false, clickable)

		tooltip:AddLine(zo_strformat("<<1>>",tipLine), { fontSize = 24, fontColorField = GAMEPAD_TOOLTIP_COLOR_GENERAL_COLOR_1 }, tooltip:GetStyle("bodySection"))
	end
end

local function TooltipHook(tooltipControl, method, linkFunc)
	local origMethod = tooltipControl[method]

	tooltipControl[method] = function(self, ...)
		origMethod(self, ...)
		AddInfo_Gamepad(self, linkFunc(...))
	end
end

local function ReturnItemLink(itemLink)
	return itemLink
end

function BUI.HookBagTips()
	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_LEFT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_RIGHT_TOOLTIP), "LayoutItem", ReturnItemLink)
	TooltipHook(GAMEPAD_TOOLTIPS:GetTooltip(GAMEPAD_MOVABLE_TOOLTIP), "LayoutItem", ReturnItemLink)
end

function BUI.RGBToHex(rgba)
	r,g,b,a = unpack(rgba)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end


function BUI.Initialize(event, addon)
    -- filter for just BUI addon event
	if addon ~= BUI.name then return end

	-- load our saved variables
	BUI.settings = ZO_SavedVars:New("BetterUISavedVars", 1, nil, BUI.defaults)
	BUI.EventManager:UnregisterForEvent("BetterUIInitialize", EVENT_ADD_ON_LOADED)

	if(IsInGamepadPreferredMode()) then
		BUI.GuildStore.SetupCustomResults()
		BUI.GuildStore.SetupMM()
		BUI.Writs.Setup()
	else
		d("[BUI] Not Loaded: gamepad mode disabled.")
	end

	BUI.SetupOptionsMenu()
end

-- register our event handler function to be called to do initialization
BUI.EventManager:RegisterForEvent(BUI.name, EVENT_ADD_ON_LOADED, function(...) BUI.Initialize(...) end)