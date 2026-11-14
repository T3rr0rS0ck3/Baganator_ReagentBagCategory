-- Baganator - Reagent Bag Category
--
-- Plugin for Baganator: items inside the reagent bag are always shown in their
-- own category in the category view - regardless of which default category
-- they would otherwise belong to.
--
-- How it works (without any changes to Baganator or Syndicator):
--  1. While the category view is built, items from the reagent bag get their
--     own grouping key (just like Baganator itself does e.g. for locked
--     lockboxes).
--  2. These keys are assigned to the "Reagent Bag" category as "directly
--     added items" - the same mechanism Baganator uses when an item is
--     dragged into a category.

local ADDON_NAME = ...

-- nil on clients without a reagent bag - the addon stays inactive there
local REAGENT_BAG_ID = Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag
-- Starts with "i:" so Baganator's export/editor code doesn't trip over it
local KEY_PREFIX = "i:rbc:"
local FRAME_PREFIX = "Baganator_CategoryViewBackpackViewFrame"
local MODS_FLAG = "rbcReagentBag"
local LOGO = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\logo"

-- Localisation: English is the default / leading language.
-- Other languages only override individual strings; anything missing falls back to English.
local L = {
  TITLE = "Baganator - Reagent Bag Category",
  CATEGORY_NAME = "Reagent Bag",
  ENABLE = "Always show the reagent bag as its own category",
  ENABLE_TOOLTIP = "All items inside the reagent bag are placed into their own category in the category view.",
  CREATE = "Create category",
  CREATED = "Category \"%s\" was created in the current Baganator profile.",
  EXISTS = "The category already exists in the current Baganator profile.",
  NO_PROFILE = "Baganator profile not found.",
  NO_REAGENT_BAG = "This game version has no reagent bag - the addon is inactive.",
  INFO = "The category is created automatically on first start and placed at the top. You can change its name, colour, position etc. in Baganator's category settings as usual. Keep its priority high.\n\nIf the category was deleted, the button above recreates it.\n\nWorks for the currently logged in character (not in the offline view of other characters).",
  ENABLED_MSG = "Reagent bag as own category: |cff00ff00on|r",
  DISABLED_MSG = "Reagent bag as own category: |cffff0000off|r",
  HELP = "Commands: /brk (settings), /brk on|off, /brk create",
  OPEN_FAILED = "Could not open the settings panel - use Esc > Options > AddOns.",
  OPTIONS_ERROR = "Options error: ",
  LOADED = "loaded - /brk for options",
  COMMANDS_HEADER = "Chat commands",
  COMMANDS = "|cffffd100/brk|r  -  open these settings and show the current status\n"
    .. "|cffffd100/brk on|r  -  show the reagent bag as its own category\n"
    .. "|cffffd100/brk off|r  -  sort reagent bag items into the normal categories again\n"
    .. "|cffffd100/brk create|r  -  (re)create the category in the current Baganator profile\n"
    .. "|cffffd100/brk help|r  -  list the commands in chat\n\n"
    .. "|cffffd100/reagenzientasche|r works as an alias for |cffffd100/brk|r.",
}

local translations = {
  deDE = {
    CATEGORY_NAME = "Reagenzientasche",
    ENABLE = "Reagenzientasche grundsätzlich als eigene Kategorie anzeigen",
    ENABLE_TOOLTIP = "Alle Gegenstände in der Reagenzientasche landen in der Kategorie-Ansicht in einer eigenen Kategorie.",
    CREATE = "Kategorie anlegen",
    CREATED = "Kategorie \"%s\" wurde im aktuellen Baganator-Profil angelegt.",
    EXISTS = "Die Kategorie existiert im aktuellen Baganator-Profil bereits.",
    NO_PROFILE = "Baganator-Profil nicht gefunden.",
    NO_REAGENT_BAG = "Diese Spielversion hat keine Reagenzientasche - das Addon ist inaktiv.",
    INFO = "Die Kategorie wird beim ersten Start automatisch angelegt und ganz oben einsortiert. Name, Farbe, Position usw. kannst du danach ganz normal in Baganators Kategorie-Einstellungen ändern. Die Priorität sollte hoch bleiben.\n\nWurde die Kategorie gelöscht, legt der Knopf oben sie neu an.\n\nFunktioniert für den aktuell eingeloggten Charakter (nicht in der Offline-Ansicht anderer Charaktere).",
    ENABLED_MSG = "Reagenzientasche als eigene Kategorie: |cff00ff00an|r",
    DISABLED_MSG = "Reagenzientasche als eigene Kategorie: |cffff0000aus|r",
    HELP = "Befehle: /brk (Einstellungen), /brk an|aus, /brk anlegen",
    OPEN_FAILED = "Einstellungsfenster konnte nicht geöffnet werden - bitte Esc > Optionen > AddOns nutzen.",
    OPTIONS_ERROR = "Optionen-Fehler: ",
    LOADED = "geladen - /brk für Optionen",
    COMMANDS_HEADER = "Chat-Befehle",
    COMMANDS = "|cffffd100/brk|r  -  öffnet diese Einstellungen und zeigt den aktuellen Status\n"
      .. "|cffffd100/brk on|r  (oder |cffffd100an|r)  -  Reagenzientasche als eigene Kategorie anzeigen\n"
      .. "|cffffd100/brk off|r  (oder |cffffd100aus|r)  -  Items der Reagenzientasche wieder normal einsortieren\n"
      .. "|cffffd100/brk create|r  (oder |cffffd100anlegen|r)  -  Kategorie im aktuellen Baganator-Profil (neu) anlegen\n"
      .. "|cffffd100/brk help|r  -  Befehle im Chat auflisten\n\n"
      .. "|cffffd100/reagenzientasche|r funktioniert genauso wie |cffffd100/brk|r.",
  },
}

for key, value in pairs(translations[GetLocale()] or {}) do
  L[key] = value
end

local function Print(msg)
  print("|T" .. LOGO .. ":14:14|t |cff33ccaa" .. L.TITLE .. ":|r " .. msg)
end

local function IsEnabled()
  return BAGANATOR_RBC_CONFIG == nil or BAGANATOR_RBC_CONFIG.enabled ~= false
end

local function RequestRefresh()
  if Baganator and Baganator.API and Baganator.API.RequestItemButtonsRefresh and Baganator.Constants then
    Baganator.API.RequestItemButtonsRefresh({Baganator.Constants.RefreshReason.Searches})
  end
end

---------------------------------------------------------------------------
-- Find the Baganator profile / category
---------------------------------------------------------------------------
local function GetProfile()
  if BAGANATOR_CONFIG and BAGANATOR_CONFIG.Profiles and BAGANATOR_CURRENT_PROFILE then
    return BAGANATOR_CONFIG.Profiles[BAGANATOR_CURRENT_PROFILE], BAGANATOR_CURRENT_PROFILE
  end
end

local function FindCategory(profile)
  if not profile or type(profile.category_modifications) ~= "table" or type(profile.custom_categories) ~= "table" then
    return
  end
  for source, mods in pairs(profile.category_modifications) do
    if type(mods) == "table" and mods[MODS_FLAG] and profile.custom_categories[source] then
      return source, mods
    end
  end
end

local function IsOurKey(key)
  return type(key) == "string" and key:sub(1, #KEY_PREFIX) == KEY_PREFIX
end

local function ClearOurItems(mods)
  if mods and type(mods.addedItems) == "table" then
    for key in pairs(mods.addedItems) do
      if IsOurKey(key) then
        mods.addedItems[key] = nil
      end
    end
    if next(mods.addedItems) == nil then
      mods.addedItems = nil
    end
  end
end

local function ClearAllProfiles()
  if BAGANATOR_CONFIG and BAGANATOR_CONFIG.Profiles then
    for _, profile in pairs(BAGANATOR_CONFIG.Profiles) do
      local _, mods = FindCategory(profile)
      ClearOurItems(mods)
    end
  end
end

---------------------------------------------------------------------------
-- Split off reagent bag items in the category view and assign them
---------------------------------------------------------------------------
local hooked = {}

local function MarkReagentBagItems(everything)
  if not IsEnabled() or type(everything) ~= "table" then
    return
  end
  for _, info in ipairs(everything) do
    if info.bagID == REAGENT_BAG_ID and not info.rbcInReagentBag then
      info.rbcInReagentBag = true
      if info.key then info.key = KEY_PREFIX .. info.key end
      if info.keyNoGUID then info.keyNoGUID = KEY_PREFIX .. info.keyNoGUID end
      if info.keyGUID then info.keyGUID = KEY_PREFIX .. info.keyGUID end
    end
  end
end

-- Runs right before the categories are assembled
local function AttachReagentBagItems(everything)
  local _, mods = FindCategory(GetProfile())
  if not mods then
    return
  end
  ClearOurItems(mods)
  if not IsEnabled() or type(everything) ~= "table" then
    return
  end
  for _, info in ipairs(everything) do
    if info.rbcInReagentBag and IsOurKey(info.key) then
      mods.addedItems = mods.addedItems or {}
      mods.addedItems[info.key] = true
    end
  end
end

local function HookBackpackFrame(frame)
  if hooked[frame] then
    return false
  end
  local splitter = frame.LayoutManager and frame.LayoutManager.SpecialisedSplitting
  if not splitter or type(splitter.ApplySplitting) ~= "function" then
    return false
  end
  local original = splitter.ApplySplitting
  -- The method was copied onto the instance via Mixin, so it can be
  -- overridden here (the frozen mixin table itself stays untouched).
  splitter.ApplySplitting = function(self, everything, callback, ...)
    MarkReagentBagItems(everything)
    return original(self, everything, function(...)
      AttachReagentBagItems(everything)
      return callback(...)
    end, ...)
  end
  hooked[frame] = true
  return true
end

local function ScanForFrames()
  local any = false
  for name, value in pairs(_G) do
    if type(name) == "string" and type(value) == "table" and name:sub(1, #FRAME_PREFIX) == FRAME_PREFIX then
      if HookBackpackFrame(value) then
        any = true
      end
    end
  end
  if any then
    RequestRefresh()
  end
end

---------------------------------------------------------------------------
-- Create the category in the current Baganator profile
---------------------------------------------------------------------------
local function CreateCategory(silent)
  if not REAGENT_BAG_ID then
    if not silent then Print(L.NO_REAGENT_BAG) end
    return false
  end
  local profile = GetProfile()
  if not profile or type(profile.custom_categories) ~= "table" or type(profile.category_display_order) ~= "table" then
    if not silent then Print(L.NO_PROFILE) end
    return false
  end

  if FindCategory(profile) then
    if not silent then Print(L.EXISTS) end
    return false
  end

  local categories = profile.custom_categories
  local source = "1"
  while categories[source] do
    source = tostring(tonumber(source) + 1)
  end

  categories[source] = {
    name = L.CATEGORY_NAME,
    search = "",
  }

  profile.category_modifications = profile.category_modifications or {}
  profile.category_modifications[source] = {
    priority = 3, -- highest priority in Baganator's editor
    showGroupPrefix = false,
    hideIn = {},
    [MODS_FLAG] = true,
  }

  if type(profile.category_hidden) == "table" then
    profile.category_hidden[source] = false
  end

  -- Place at the very top, but after "Recent items" (if present)
  local order = profile.category_display_order
  local position = 1
  local recentIndex = tIndexOf(order, "default_auto_recents")
  if recentIndex then
    position = recentIndex + 1
    if order[position] == "----" then
      position = position + 1
    end
  end
  table.insert(order, position, source)

  Print(L.CREATED:format(L.CATEGORY_NAME))
  RequestRefresh()
  return true
end

local function EnsureCategoryForCurrentProfile()
  local profile, profileName = GetProfile()
  if not profile or not profileName then
    return
  end
  BAGANATOR_RBC_CONFIG.createdForProfile = BAGANATOR_RBC_CONFIG.createdForProfile or {}
  -- Only create it automatically once per profile. If the user deletes the
  -- category later, it is not recreated without being asked.
  if not BAGANATOR_RBC_CONFIG.createdForProfile[profileName] then
    if not FindCategory(profile) then
      CreateCategory(true)
    end
    BAGANATOR_RBC_CONFIG.createdForProfile[profileName] = true
  end
end

---------------------------------------------------------------------------
-- Options (Settings > AddOns) and slash command
---------------------------------------------------------------------------
local settingsCategory
local enableCheckbox

local function SetEnabled(value)
  BAGANATOR_RBC_CONFIG.enabled = value and true or false
  if enableCheckbox then
    enableCheckbox:SetChecked(BAGANATOR_RBC_CONFIG.enabled)
  end
  Print(BAGANATOR_RBC_CONFIG.enabled and L.ENABLED_MSG or L.DISABLED_MSG)
  RequestRefresh()
end

local function CreateOptionsPanel()
  local panel = CreateFrame("Frame")
  panel.name = L.TITLE

  local logo = panel:CreateTexture(nil, "ARTWORK")
  logo:SetTexture(LOGO)
  logo:SetSize(64, 64)
  logo:SetPoint("TOPLEFT", 12, -12)

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 10, -14)
  title:SetText(L.TITLE)

  local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
  version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
  local versionText = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
    or GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version")
  version:SetText(versionText and ("v" .. versionText:gsub("^v", "")) or "")

  enableCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  enableCheckbox:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 4, -12)
  local label = enableCheckbox.Text or enableCheckbox.text
  if type(label) ~= "table" or not label.SetText then
    label = enableCheckbox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT", enableCheckbox, "RIGHT", 4, 0)
  end
  label:SetFontObject("GameFontHighlight")
  label:SetText(L.ENABLE)
  enableCheckbox:SetScript("OnClick", function(self)
    SetEnabled(self:GetChecked())
  end)
  enableCheckbox:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L.ENABLE_TOOLTIP, 1, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  enableCheckbox:SetScript("OnLeave", GameTooltip_Hide)

  local createButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  createButton:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 4, -12)
  createButton:SetSize(180, 24)
  createButton:SetText(L.CREATE)
  createButton:SetScript("OnClick", function()
    CreateCategory(false)
  end)

  local info = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  info:SetPoint("TOPLEFT", createButton, "BOTTOMLEFT", -4, -16)
  info:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
  info:SetJustifyH("LEFT")
  info:SetText(L.INFO)

  local commandsHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  commandsHeader:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -20)
  commandsHeader:SetText(L.COMMANDS_HEADER)

  local commands = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  commands:SetPoint("TOPLEFT", commandsHeader, "BOTTOMLEFT", 0, -8)
  commands:SetPoint("RIGHT", panel, "RIGHT", -16, 0)
  commands:SetJustifyH("LEFT")
  commands:SetSpacing(3)
  commands:SetText(L.COMMANDS)

  panel:SetScript("OnShow", function()
    enableCheckbox:SetChecked(IsEnabled())
  end)

  if Settings and Settings.RegisterCanvasLayoutCategory then
    settingsCategory = Settings.RegisterCanvasLayoutCategory(panel, L.TITLE)
    Settings.RegisterAddOnCategory(settingsCategory)
  elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    settingsCategory = panel
  end
end

local function OpenOptions()
  if not settingsCategory then
    return false
  end
  local ok = pcall(function()
    if Settings and Settings.OpenToCategory and settingsCategory.GetID then
      Settings.OpenToCategory(settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
      InterfaceOptionsFrame_OpenToCategory(settingsCategory)
      InterfaceOptionsFrame_OpenToCategory(settingsCategory)
    else
      error("no settings api")
    end
  end)
  return ok
end

SLASH_BAGANATORRBC1 = "/brk"
SLASH_BAGANATORRBC2 = "/reagenzientasche"
SlashCmdList["BAGANATORRBC"] = function(msg)
  msg = strtrim(msg or ""):lower()
  if msg == "an" or msg == "on" then
    SetEnabled(true)
  elseif msg == "aus" or msg == "off" then
    SetEnabled(false)
  elseif msg == "anlegen" or msg == "create" then
    CreateCategory(false)
  else
    Print(IsEnabled() and L.ENABLED_MSG or L.DISABLED_MSG)
    Print(L.HELP)
    if msg == "" and not OpenOptions() then
      Print(L.OPEN_FAILED)
    end
  end
end

---------------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
    BAGANATOR_RBC_CONFIG = BAGANATOR_RBC_CONFIG or {}
    if BAGANATOR_RBC_CONFIG.enabled == nil then
      BAGANATOR_RBC_CONFIG.enabled = true
    end
    self:UnregisterEvent("ADDON_LOADED")
    local ok, err = pcall(CreateOptionsPanel)
    if not ok then
      Print(L.OPTIONS_ERROR .. tostring(err))
    end
  elseif event == "PLAYER_LOGOUT" then
    -- Assignments are temporary only - don't persist them in Baganator's settings
    ClearAllProfiles()
  elseif event == "PLAYER_LOGIN" then
    self:UnregisterEvent("PLAYER_LOGIN")
    self:RegisterEvent("PLAYER_LOGOUT")
    if not REAGENT_BAG_ID then
      Print(L.NO_REAGENT_BAG)
      return
    end
    Print(L.LOADED)
    -- Baganator creates its windows on login; wait a moment, then hook in
    C_Timer.After(0, function()
      EnsureCategoryForCurrentProfile()
      ScanForFrames()
    end)
    C_Timer.After(3, ScanForFrames)

    -- Baganator creates new windows when the skin changes
    if Baganator.API.Skins and Baganator.API.Skins.RegisterListener then
      Baganator.API.Skins.RegisterListener(function(details)
        -- The backpack window reports here before its LayoutManager
        -- exists - so hook in on the next frame.
        local region = details and details.region
        if type(region) == "table" and region.GetName then
          local name = region:GetName()
          if name and name:sub(1, #FRAME_PREFIX) == FRAME_PREFIX then
            C_Timer.After(0, function()
              if HookBackpackFrame(region) then
                RequestRefresh()
              end
            end)
          end
        end
      end)
    end
  end
end)
