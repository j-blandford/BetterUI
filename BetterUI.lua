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
		registerForDefaults = true,	--boolean (optional) (will set all options controls back to default values)
	}

	local optionsTable = {
		[1] = {
			type = "header",
			name = "General Settings",
			width = "full",
		},
		[2] = {
			type = "checkbox",
			name = "Display Daily Writ helper unit",
			tooltip = "Displays the daily writ, and progress, at each crafting station",
			getFunc = function() return BUI.settings.showWritHelper end,
			setFunc = function(value) BUI.settings.showWritHelper = value end,
			width = "full",
		},
		[3] = {
			type = "checkbox",
			name = "Display value labels on Attribute bars",
			tooltip = "Displays the Health, Stamina and Magicka values on your attribute bars",
			getFunc = function() return BUI.settings.attributeLabels end,
			setFunc = function(value) 
						BUI.settings.attributeLabels = value 
						end,
			width = "full",
		},
		[4] = {
				type = "checkbox",
				name = "Display MasterMerchant price and percentage",
				tooltip = "Displays the MM price on any item and the percentage profit in guild store listings",
				getFunc = function() return BUI.settings.showMMPrice end,
				setFunc = function(value) BUI.settings.showMMPrice = value end,
				width = "full",
			},
		[5] = {
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
				},
				[3] = {
					type = "checkbox",
					name = "Display the health value (text) on the target?",
					getFunc = function() return BUI.settings.showHealthText end,
					setFunc = function(value) BUI.settings.showHealthText = value end,
					width = "full",
				},
			}
		},
		[6] = {
			type = "submenu",
			name = "Guild Store Options",
			controls = {
				[1] = {
					type="checkbox",
					name="Flip sort and select buttons (A+X)",
					tooltip="Switches the default A=Sort and X=Select to be A=Select and X=Sort",
					getFunc = function() return BUI.settings.flipGSbuttons end,
					setFunc = function(value) BUI.settings.flipGSbuttons = value
											ReloadUI() end,
					width="full",
					warning="Reloads the UI for the change to propagate"
				},
				[2] = {
					type = "checkbox",
					name = "Unit Price in Guild Store",
					tooltip = "Displays a price per unit in guild store listings",
					getFunc = function() return BUI.settings.showUnitPrice end,
					setFunc = function(value) BUI.settings.showUnitPrice = value end,
					width = "full",
				},
				[3] = {
					type = "checkbox",
					name = "Disable scrolling animation",
					getFunc = function() return BUI.settings.scrollingDisable end,
					setFunc = function(value) BUI.settings.scrollingDisable = value 
											BUI.GuildStore.DisableAnimations(value) end,
					width = "full",
				},
				[4] = {
					type = "checkbox",
					name = "Condense listing view",
					tooltip = "Allows more items to be seen at once whilst browsing",
					getFunc = function() return BUI.settings.condensedListings end,
					setFunc = function(value) BUI.settings.condensedListings = value 
											ReloadUI() end,
					width = "full",
					warning="Reloads the UI for the change to propagate"
				},
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

function BUI.RGBToHex(rgba)
	r,g,b,a = unpack(rgba)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function BUI.DisplayNumber(number)
	local formatted = number
 	while true do  
    	formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    	if (k==0) then
     		break
    	end
  	end
  return formatted
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
		BUI.Tooltips.Setup()
		--BUI.Player.GetResearch()
	else
		d("[BUI] Not Loaded: gamepad mode disabled.")
	end

	BUI.SetupOptionsMenu()
end

-- register our event handler function to be called to do initialization
BUI.EventManager:RegisterForEvent(BUI.name, EVENT_ADD_ON_LOADED, function(...) BUI.Initialize(...) end)