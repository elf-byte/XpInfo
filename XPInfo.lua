-- XPInfo - standalone always-visible XP info frame
-- Isolated from pfUI modules/xpbar.lua OnEnter + session tracking

local addon = CreateFrame("Frame", "XPInfoFrame", UIParent)
addon:SetWidth(220)
addon:SetHeight(110)
addon:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
addon:SetMovable(true)
addon:EnableMouse(true)
addon:RegisterForDrag("LeftButton")
addon:SetScript("OnDragStart", function() this:StartMoving() end)
addon:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
addon:SetClampedToScreen(true)
addon:SetFrameStrata("MEDIUM")

-- background
local bg = addon:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(addon)
bg:SetTexture(0, 0, 0, 0.75)

-- border
local border = CreateFrame("Frame", nil, addon)
border:SetPoint("TOPLEFT", -1, 1)
border:SetPoint("BOTTOMRIGHT", 1, -1)
border:SetBackdrop({
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

-- title
local title = addon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOP", 0, -6)
title:SetText("|cffaaaaaaExperience|r")

-- the actual info lines
local lines = {}
for i = 1, 7 do
  lines[i] = addon:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lines[i]:SetPoint("TOPLEFT", 8, -8 - (i * 13))
  lines[i]:SetJustifyH("LEFT")
  lines[i]:SetWidth(204)
end

-- session data (same logic as pfUI)
local data = CreateFrame("Frame")
data:RegisterEvent("PLAYER_ENTERING_WORLD")
data:RegisterEvent("PLAYER_LEVEL_UP")
data:SetScript("OnEvent", function()
  if event == "PLAYER_ENTERING_WORLD" then
    this.starttime = GetTime()
    this.startxp = UnitXP("player") or 0
  elseif event == "PLAYER_LEVEL_UP" then
    -- keep previous level XP in the session total
    this.startxp = this.startxp - UnitXPMax("player")
  end
end)

-- simple round helper (pfUI style)
local function round(num, places)
  places = places or 0
  local mult = 10 ^ places
  return math.floor(num * mult + 0.5) / mult
end

local function Update()
  local xp    = UnitXP("player")
  local xpmax = UnitXPMax("player")
  local exh   = GetXPExhaustion()

  if not xp or not xpmax or xpmax == 0 then return end

  local xp_perc       = round(xp / xpmax * 100)
  local remaining     = xpmax - xp
  local remaining_perc = round(remaining / xpmax * 100)
  local exh_perc      = exh and round(exh / xpmax * 100) or 0

  local elapsed = GetTime() - (data.starttime or GetTime())
  if elapsed < 1 then elapsed = 1 end   -- avoid div/0

  local session   = xp - (data.startxp or xp)
  local xp_persec = session / elapsed
  local avg_hour  = math.floor(xp_persec * 3600)
  local time_remaining = (xp_persec > 0) and SecondsToTime(remaining / xp_persec) or "—"

  -- fill the lines (same data as pfUI tooltip)
  lines[1]:SetText(string.format("|cffffffffXP:|r  %s / %s  (%s%%)", xp, xpmax, xp_perc))
  lines[2]:SetText(string.format("|cffffffffRemaining:|r  %s  (%s%%)", remaining, remaining_perc))

  if exh and exh > 0 then
    lines[3]:SetText(string.format("|cff5555ffRested:|r  +%s  (%s%%)", exh, exh_perc))
  else
    lines[3]:SetText("|cff555555Rested:|r  none")
  end

  if IsResting() then
    lines[4]:SetText("|cffffffffStatus:|r  Resting")
  else
    lines[4]:SetText("|cff555555Status:|r  —")
  end

  lines[5]:SetText(string.format("|cffffffffThis Session:|r  %s", session))
  lines[6]:SetText(string.format("|cffffffffXP / Hour:|r  %s", avg_hour))
  lines[7]:SetText(string.format("|cffffffffTime to Level:|r  %s", time_remaining))
end

-- update on XP changes + every 2 seconds
addon:RegisterEvent("PLAYER_XP_UPDATE")
addon:RegisterEvent("UPDATE_EXHAUSTION")
addon:RegisterEvent("PLAYER_ENTERING_WORLD")
addon:RegisterEvent("PLAYER_LEVEL_UP")
addon:SetScript("OnEvent", function()
  Update()
end)

local timer = 0
addon:SetScript("OnUpdate", function()
  timer = timer + arg1
  if timer > 2 then
    timer = 0
    Update()
  end
end)

-- slash command to toggle
SLASH_XPINFO1 = "/xpinfo"
SlashCmdList["XPINFO"] = function()
  if addon:IsShown() then
    addon:Hide()
  else
    addon:Show()
  end
end

-- start visible
addon:Show()
Update()

print("|cff00ff00XPInfo|r loaded. Drag the frame to move. /xpinfo to toggle.")
