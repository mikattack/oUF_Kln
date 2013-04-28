------------------------------------------------------------------------------
--| oUF_Kln
--| Authors: Drakull, Myno, Kellen
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------


local addon, ns = ...
local cfg = ns.Kln.cfg
local lib = ns.Kln.lib

local Decorators = lib.Decorators

local units = {}
ns.Kln.units = units


--[[--------------------------------------------------------------------------
  Unit Frame Factory

  Creates the frames, strings, and elements which comprise the parts of
  a particular unit frame.  This is certainly overkill, but I like the
  clarity.
----------------------------------------------------------------------------]]


local _, playerClass = UnitClass("player")
local ResourceBars = {}

-- Media
local bar_common    = cfg.media.bar.common
local bar_power     = cfg.media.bar.power
local bar_raid      = cfg.media.bar.raid

local bg_common     = cfg.media.background.common
local bg_highlight  = cfg.media.background.highlight

local border_common = cfg.media.border.common

local font_common   = cfg.media.font.common
local font_small    = cfg.media.font.small
local font_raid     = cfg.media.font.raid
local font_square   = cfg.media.font.square


------------------------------------------------------------------------------
--  Event Functions
------------------------------------------------------------------------------


-- For the Raid frames target highlight border
local function ChangedTarget(self, event, unit)
  if UnitIsUnit('target', self.unit) then
    self.TargetBorder:Show()
  else
    self.TargetBorder:Hide()
  end
end


------------------------------------------------------------------------------
--  Hook Functions
------------------------------------------------------------------------------


local function PostUpdateRaidFrame(Health, unit, min, max)
  local dc = not UnitIsConnected(unit)
  local dead = UnitIsDead(unit)
  local ghost = UnitIsGhost(unit)
  local inrange = UnitInRange(unit)
  
  Health:SetStatusBarColor(.12,.12,.12,1)
  Health:SetAlpha(1)
  Health:SetValue(min)
  
  if dc or dead or ghost then
    if dc then
      Health:SetAlpha(.225)
    else
      Health:SetValue(0)
    end
  else
    Health:SetValue(min)
    if(unit == 'vehicle') then
      Health:SetStatusBarColor(.12,.12,.12,1)
    end
  end
end


local function PostUpdateRaidFramePower(Power, unit, min, max)
  local dc = not UnitIsConnected(unit)
  local dead = UnitIsDead(unit)
  local ghost = UnitIsGhost(unit)
  
  Power:SetAlpha(1)
  
  if dc or dead or ghost then
    Power:SetAlpha(.3)
  end
end


------------------------------------------------------------------------------
--  Unit Frame Generators
------------------------------------------------------------------------------


function units.Player(frame, width, height)
  frame:SetSize(width,height)
  frame.background = lib.CreateBackground(frame)

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local percent, raw, power

  percent = lib.CreateString(frame.Health, font_common, 28, "OUTLINE")
  percent:SetPoint("LEFT", frame.Health, "LEFT", 3, 3)
  percent.frequentUpdates = true

  raw = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  raw:SetPoint("BOTTOMLEFT", percent, "BOTTOMRIGHT", 0, 3)
  raw.frequentUpdates = true

  power = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  power:SetPoint("RIGHT", frame.Health, "RIGHT", -2, 1)

  frame:Tag(percent, "[kln:percent_hp]")
  frame:Tag(raw, "[kln:raw_hp]")
  frame:Tag(power, "[kln:power]")

  -- Debuff Highlight
  local dbh = frame.Health:CreateTexture(nil, "OVERLAY")
  dbh:SetAllPoints(frame.Health)
  dbh:SetTexture(bar_common)
  dbh:SetBlendMode("ADD")
  dbh:SetVertexColor(0, 0, 0, 0)
  frame.DebuffHighlight = dbh

  -- Castbar (fixed position)
  local cb = lib.CreateCastbar(frame, 250, 26)
  local offset = cb:GetHeight() / 2
  cb:SetPoint("BOTTOM", UIParent, "BOTTOM", offset, 210)

  -- Resource bar(s)
  ResourceBars.Runes(frame)
  ResourceBars.HolyPower(frame)
  --ResourceBars.Harmony(frame)
  --ResourceBars.Soulshards(frame)
  ResourceBars.Eclipse(frame)
  ResourceBars.Shadoworbs(frame)

  -- Scented wax and flower petals
  Decorators.PowerBar(frame)
  Decorators.StatusIcons(frame)
  Decorators.HealPrediction(frame)

  frame.Health.frequentUpdates = true
  frame.Health.colorSmooth = true
  frame.Health.bg.multiplier = 0.3
  
  frame.Power.colorTapping = true
  frame.Power.colorDisconnected = true
  frame.Power.colorClass = true
  frame.Power.colorReaction = true
  frame.Power.bg.multiplier = 0.3
    
  frame.Health.Smooth = true
  frame.Power.Smooth = true
end


-- NOTE: Resused for Focus
function units.Target(frame, width, height)
  frame:SetSize(width,height)
  frame.background = lib.CreateBackground(frame)

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  health:SetPoint("RIGHT", frame.Health, "RIGHT", -1, 0)
  health.frequentUpdates = true

  frame:Tag(name, "[kln:level] [kln:color][kln:name][kln:afkdnd]")
  frame:Tag(health, "[kln:full_hp]")

  -- Debuff Highlight
  local dbh = frame.Health:CreateTexture(nil, "OVERLAY")
  dbh:SetAllPoints(frame.Health)
  dbh:SetTexture(bar_common)
  dbh:SetBlendMode("ADD")
  dbh:SetVertexColor(0, 0, 0, 0)
  frame.DebuffHighlight = dbh

  -- Castbar (fixed position)
  local cb = lib.CreateCastbar(frame, 250, 26)
  if cb then
    -- In case of the "focus" unit
    cb:SetPoint("TOP", oUF_klnFramesCastbarplayer, "BOTTOM", 0, -8)
  end

  -- Auras
  Decorators.Auras(frame)
  frame.Auras.CustomFilter = lib.CustomAuraFilters.target
  if frame.mystyle == "target" then
    frame.Auras:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 6)
    frame.Auras.initialAnchor = "BOTTOMLEFT"
    frame.Auras["growth-x"] = "RIGHT"
    frame.Auras["growth-y"] = "UP"
  else
    frame.Auras:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -6)
    frame.Auras.initialAnchor = "TOPLEFT"
    frame.Auras["growth-x"] = "RIGHT"
    frame.Auras["growth-y"] = "DOWN"
  end

  -- Cherry frosting
  Decorators.PowerBar(frame)
  Decorators.StatusIcons(frame)
  Decorators.HealPrediction(frame)

  frame.DebuffHighlightBackdrop = true
  frame.Health.frequentUpdates = true
  frame.Health.colorSmooth = true
  frame.Health.bg.multiplier = 0.3
  
  frame.Power.colorTapping = true
  frame.Power.colorDisconnected = true
  frame.Power.colorClass = true
  frame.Power.colorReaction = true
  frame.Power.bg.multiplier = 0.3
    
  frame.Health.Smooth = true
  frame.Power.Smooth = true
end


-- NOTE: Resused for Focus->Target
function units.TargetOfTarget(frame, width, height)
  frame:SetSize(width,height)
  frame.background = lib.CreateBackground(frame)

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  health:SetPoint("RIGHT", frame.Health, "RIGHT", -1, 0)
  health.frequentUpdates = true

  frame:Tag(name, "[kln:color][kln:shortname]")
  frame:Tag(health, "[kln:percent_hp]")

  -- The "Decapitate" fragrance, from Charnel
  Decorators.PowerBar(frame)

  frame.DebuffHighlightBackdrop = true
  frame.Health.colorSmooth = true
  frame.Health.bg.multiplier = 0.3
  
  frame.Power.colorTapping = true
  frame.Power.colorDisconnected = true
  frame.Power.colorClass = true
  frame.Power.colorReaction = true
  frame.Power.bg.multiplier = 0.3
    
  frame.Health.Smooth = true
  frame.Power.Smooth = true
end


function units.Pet(frame, width, height)
  -- 
  -- NOTE: I have some personal opinions about the pet frame.
  --       1. You should know your pet.  It's name is unnessecary to display.
  --       2. If #1 is false, you can click on the frame and see your pet's
  --          particulars in the Target frame.
  --       3. If you need a precise power readout on your pet, then you're
  --          a better player than I and probably should be writing your own
  --          UI layout rather than reading this one.
  --       4. I don't really play with pets :(
  -- 

  frame:SetSize(width,height)
  frame.background = lib.CreateBackground(frame)

  height = 12

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- You say "Death", I say "Knight".  Ready?  "Death"...
  Decorators.PowerBar(frame)

  frame.Health.colorSmooth = true
  frame.Health.bg.multiplier = 0.3
  
  frame.Power.colorClass = true
  frame.Power.colorReaction = true
  frame.Power.bg.multiplier = 0.3
    
  frame.Health.Smooth = true
  frame.Power.Smooth = true
end


function units.Raid(frame, width, height)
  frame.background = lib.CreateBackground(frame)

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 4, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)
  frame.Health:SetStatusBarColor(.12, .12, .12, 1)
  frame.Health:SetStatusBarTexture(bar_raid)

  -- Text readouts
  local name, deficit

  name = lib.CreateString(frame.Health, font_raid, 12, "NONE")
  name:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", 1, -1)
  name:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
  name:SetJustifyH("LEFT")
  name.frequentUpdates = true

  deficit = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  deficit:SetPoint("BOTTOMLEFT", percent, "BOTTOMRIGHT", 1, 1)
  deficit.frequentUpdates = true

  frame:Tag(name, "[kln:color][name][kln:raidafkdnd]")
  frame:Tag(deficit, "[kln:raid_hp]")

  -- "The files are *in* the computer."
  Decorators.PowerBar(frame)
  Decorators.StatusIcons(frame)
  Decorators.HealPrediction(frame)
  Decorators.Highlight(frame)
  Decorators.Border(frame)
  Decorators.RaidDebuffs(frame)

  frame.Range = {
    insideAlpha = 1,
    outsideAlpha = .6,
  }

  frame.DrkIndicators = true
  frame.showThreatIndicator = true

  frame.Power:SetHeight(3);
  frame.Power.colorClass = true
  frame.Power.bg.multiplier = .35
  frame.Power:SetAlpha(.9)

  frame.colors.health = { r=.12, g=.12, b=.12, a=1 }
  frame.Health.colorHealth = true
  frame.Health.bg:SetVertexColor(.4,.4,.4,1)
  frame.Health.frequentUpdates = true

  -- Event Handlers
  frame.Health.PostUpdate = PostUpdateRaidFrame
  frame.Power.PostUpdate  = PostUpdateRaidFramePower
  frame:RegisterEvent('PLAYER_TARGET_CHANGED', ChangedTarget)
  frame:RegisterEvent('GROUP_ROSTER_UPDATE', ChangedTarget)
  --frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE", lib.UpdateThreat)
  --frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", lib.UpdateThreat)
end


function units.Boss(frame, width, height)
  frame:SetSize(width,height)
  frame.background = lib.CreateBackground(frame)

  -- Health bar
  local f, bg = lib.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = lib.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = lib.CreateString(frame.Health, font_common, 28, "OUTLINE")
  health:SetPoint("RIGHT", frame.Health, "RIGHT", -2, 1)
  health.frequentUpdates = true

  frame:Tag(name, "[kln:level] [kln:color][name]")
  frame:Tag(health, "[kln:boss]")

  -- Slightly toasted, minty flavor
  Decorators.PowerBar(frame)
  Decorators.StatusIcons(frame)

  frame.Health.frequentUpdates = true
  frame.Health.colorSmooth = true
  frame.Health.bg.multiplier = 0.3
  
  frame.Power.colorTapping = true
  frame.Power.colorClass = true
  frame.Power.colorReaction = true
  frame.Power.bg.multiplier = 0.3
    
  frame.Health.Smooth = true
  frame.Power.Smooth = true
end


------------------------------------------------------------------------------
-- Class-specific Resource Bars
------------------------------------------------------------------------------


-- 
-- TODO:  Roll these into class-specific layouts
-- 

local resourceX, resourceY = 0, 24


-- LASER CHICKEN: Eclipse
function ResourceBars.Eclipse(self)
  if playerClass ~= "DRUID" then return end

  local eclipseBar = CreateFrame('Frame', nil, self)
  eclipseBar:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  eclipseBar:SetFrameLevel(4)
  eclipseBar:SetHeight(6)
  eclipseBar:SetWidth(self:GetWidth()+.5)
  local h = CreateFrame("Frame", nil, eclipseBar)
  h:SetPoint("TOPLEFT",-3,3)
  h:SetPoint("BOTTOMRIGHT",3,-3)
  eclipseBar.eBarBG = h
  lib.CreateBackground(h)

  local lunarBar = CreateFrame('StatusBar', nil, eclipseBar)
  lunarBar:SetPoint('LEFT', eclipseBar, 'LEFT', 0, 0)
  lunarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
  lunarBar:SetStatusBarTexture(bar_common)
  lunarBar:SetStatusBarColor(.1, .3, .7)
  lunarBar:SetFrameLevel(5)

  local solarBar = CreateFrame('StatusBar', nil, eclipseBar)
  solarBar:SetPoint('LEFT', lunarBar:GetStatusBarTexture(), 'RIGHT', 0, 0)
  solarBar:SetSize(eclipseBar:GetWidth(), eclipseBar:GetHeight())
  solarBar:SetStatusBarTexture(bar_common)
  solarBar:SetStatusBarColor(1,.85,.13)
  solarBar:SetFrameLevel(5)
  
  
  eclipseBar.SolarBar = solarBar
  eclipseBar.LunarBar = lunarBar
  self.EclipseBar = eclipseBar
  self.EclipseBar.PostUnitAura = eclipseBarBuff
    
  local EBText = lib.CreateString(solarBar, font_common, 14, "OUTLINE")
  EBText:SetPoint('CENTER', eclipseBar, 'CENTER', 0,0)
  local EBText2 = lib.CreateString(solarBar, font_common, 16, "THINOUTLINE")
  EBText2:SetPoint('LEFT', EBText, 'RIGHT', 1,-1)
  --EBText2:SetShadowColor(0,0,0,1)
  --EBText2:SetShadowOffset(1,1)

  self.EclipseBar.PostDirectionChange = function(element, unit)
    EBText:SetText("")
    EBText2:SetText("")
  end
    
  --self:Tag(EBText, '[pereclipse]')
  self.EclipseBar.PostUpdatePower = function(unit)

    local eclipsePowerMax = UnitPowerMax('player', SPELL_POWER_ECLIPSE)
    local eclipsePower = math.abs(UnitPower('player', SPELL_POWER_ECLIPSE)/eclipsePowerMax*100)

    if ( GetEclipseDirection() == "sun" ) then
      EBText:SetText(eclipsePower .. "  >>")
      EBText2:SetText("|cff006accSTARFIRE|r")
      EBText2:ClearAllPoints()
      EBText2:SetPoint('RIGHT', EBText, 'LEFT', 1,-1)
    elseif ( GetEclipseDirection() == "moon" ) then
      EBText:SetText("<<  " .. eclipsePower)
      EBText2:SetText("|cffeac500WRATH|r")
      EBText2:ClearAllPoints()
      EBText2:SetPoint('LEFT', EBText, 'RIGHT', 1,-1)
    else
      EBText:SetText(eclipsePower)
      EBText2:SetText("")
    end
  end
  
  self.EclipseBar.PostUpdateVisibility = function(unit)
    local eclipsePowerMax = UnitPowerMax('player', SPELL_POWER_ECLIPSE)
    local eclipsePower = math.abs(UnitPower('player', SPELL_POWER_ECLIPSE)/eclipsePowerMax*100)

    if ( GetEclipseDirection() == "sun" ) then
      EBText:SetText(eclipsePower .. "  >>")
      EBText2:SetText("|cff006accSTARFIRE|r ")
      EBText2:ClearAllPoints()
      EBText2:SetPoint('RIGHT', EBText, 'LEFT', 1,-1)
    elseif ( GetEclipseDirection() == "moon" ) then
      EBText:SetText("<<  " .. eclipsePower)
      EBText2:SetText("|cffeac500WRATH|r")
      EBText2:ClearAllPoints()
      EBText2:SetPoint('LEFT', EBText, 'RIGHT', 1,-1)
    else
      EBText:SetText(eclipsePower)
      EBText2:SetText("")
    end
  end
end


-- MONK: Harmony (Chi)
function ResourceBars.Harmony(self)
  if playerClass ~= "MONK" then return end
  
  local mhb = CreateFrame("Frame", "MonkHarmonyBar", self)
  mhb:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  mhb:SetWidth(self.Health:GetWidth() * .75)
  mhb:SetHeight(11)

  local background = lib.CreateBackground(mhb)
  background:SetFrameStrata('MEDIUM')

  -- Placeholder slots for the "orbs"
  local maxPower = UnitPowerMax("player", SPELL_POWER_CHI)
  mhb.slots = CreateFrame("Frame", nil, self)
  mhb.slots:SetAllPoints(mhb)
  mhb.slots:SetFrameLevel(mhb:GetFrameLevel() + 1)
  local r,g,b = unpack(oUF.colors.class.MONK);
  for i = 1, maxPower do
    mhb.slots[i] = mhb.slots:CreateTexture(nil,"BORDER")
    mhb.slots[i]:SetTexture(r * 0.1, g * 0.1, b * 0.1, 1)
    mhb.slots[i]:SetHeight(9)
    mhb.slots[i]:SetWidth(mhb:GetWidth() / maxPower - 2)
    if i == 1 then
      mhb.slots[i]:SetPoint("LEFT", mhb.slots, "LEFT", 1, 0)
    else
      mhb.slots[i]:SetPoint("LEFT", mhb.slots[i - 1], "RIGHT", 2, 0)
    end
  end
  
  -- The actual "orbs"
  for i = 1, 5 do
    mhb[i] = CreateFrame("StatusBar", "MonkHarmonyBar"..i, mhb)
    mhb[i]:SetHeight(9)
    mhb[i]:SetStatusBarTexture(bar_common)
    mhb[i]:SetStatusBarColor(.9,.9,.9)

    mhb[i].bg = mhb[i]:CreateTexture(nil,"BORDER")
    mhb[i].bg:SetTexture(0,1,0, 1)
    mhb[i].bg:SetPoint("TOPLEFT",mhb[i],"TOPLEFT",0,0)
    mhb[i].bg:SetPoint("BOTTOMRIGHT",mhb[i],"BOTTOMRIGHT",0,0)
    mhb[i].bg.multiplier = .3
    
    if i == 1 then
      mhb[i]:SetPoint("LEFT", mhb, "LEFT", 1, 0)
    else
      mhb[i]:SetPoint("LEFT", mhb[i-1], "RIGHT", 2, 0)
    end
  end
  
  self.MonkHarmonyBar = mhb
end


-- PRIEST: Shadow Orbs
function ResourceBars.Shadoworbs(self)
  if playerClass ~= "PRIEST" then return end

  local pso = CreateFrame("Frame", nil, self)
  pso:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  pso:SetHeight(5)
  pso:SetWidth(self.Health:GetWidth()/2+50)
  
  local maxShadowOrbs = UnitPowerMax('player', SPELL_POWER_SHADOW_ORBS)
  
  for i = 1,maxShadowOrbs do
    pso[i] = CreateFrame("StatusBar", self:GetName().."_PriestShadowOrbs"..i, self)
    pso[i]:SetHeight(5)
    pso[i]:SetWidth(pso:GetWidth()/3-2)
    pso[i]:SetStatusBarTexture(bar_common)
    pso[i]:SetStatusBarColor(.86,.22,1)
    pso[i]:SetFrameLevel(11)
    pso[i].bg = pso[i]:CreateTexture(nil, "BORDER")
    pso[i].bg:SetTexture(bar_common)
    pso[i].bg:SetPoint("TOPLEFT", pso[i], "TOPLEFT", 0, 0)
    pso[i].bg:SetPoint("BOTTOMRIGHT", pso[i], "BOTTOMRIGHT", 0, 0)
    pso[i].bg.multiplier = 0.3
    
    --helper backdrop
    local h = CreateFrame("Frame", nil, pso[i])
    --h:SetFrameLevel(10)
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    --lib.createBackdrop(h,1)
    
    if (i == 1) then
      pso[i]:SetPoint('LEFT', pso, 'LEFT', 1, 0)
    else
      pso[i]:SetPoint('TOPLEFT', pso[i-1], 'TOPRIGHT', 2, 0)
    end
  end
  
  self.PriestShadowOrbs = pso
end


-- WARLOCK: Soulshards
function ResourceBars.Soulshards(self)
  if playerClass ~= "WARLOCK" then return end
  
  local wsb = CreateFrame("Frame", "WarlockSpecBars", self)
  wsb:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  wsb:SetWidth(self.Health:GetWidth()/2+50)
  wsb:SetHeight(11)
  lib.CreateBackground(wsb)
  
  for i = 1, 4 do
    wsb[i] = CreateFrame("StatusBar", "WarlockSpecBars"..i, wsb)
    wsb[i]:SetHeight(9)
    wsb[i]:SetStatusBarTexture(bar_common)
    wsb[i]:SetStatusBarColor(.86,.22,1)
    wsb[i].bg = wsb[i]:CreateTexture(nil,"BORDER")
    wsb[i].bg:SetTexture(bar_common)
    wsb[i].bg:SetVertexColor(0,0,0)
    wsb[i].bg:SetPoint("TOPLEFT",wsb[i],"TOPLEFT",0,0)
    wsb[i].bg:SetPoint("BOTTOMRIGHT",wsb[i],"BOTTOMRIGHT",0,0)
    wsb[i].bg.multiplier = .3
    
    local h = CreateFrame("Frame",nil,wsb[i])
    --h:SetFrameLevel(10)
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    
    if i == 1 then
      wsb[i]:SetPoint("LEFT", wsb, "LEFT", 1, 0)
    else
      wsb[i]:SetPoint("LEFT", wsb[i-1], "RIGHT", 2, 0)
    end
  end
  
  self.WarlockSpecBars = wsb
end


-- PALADIN: Holy Power
function ResourceBars.HolyPower(self)
  if playerClass ~= "PALADIN" then return end

  local php = CreateFrame("Frame", nil, self)
  SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  php:SetHeight(5)
  php:SetWidth(self.Health:GetWidth()/2+75)
  
  --local maxHolyPower = UnitPowerMax("player",SPELL_POWER_HOLY_POWER)
  
  for i = 1, 5 do
    php[i] = CreateFrame("StatusBar", self:GetName().."_Holypower"..i, self)
    php[i]:SetHeight(5)
    php[i]:SetWidth((php:GetWidth()/5)-2)
    php[i]:SetStatusBarTexture(bar_common)
    php[i]:SetStatusBarColor(.9,.95,.33)
    php[i]:SetFrameLevel(11)
    php[i].bg = php[i]:CreateTexture(nil, "BORDER")
    php[i].bg:SetTexture(bar_common)
    php[i].bg:SetPoint("TOPLEFT", php[i], "TOPLEFT", 0, 0)
    php[i].bg:SetPoint("BOTTOMRIGHT", php[i], "BOTTOMRIGHT", 0, 0)
    php[i].bg.multiplier = 0.3

    local h = CreateFrame("Frame", nil, php[i])
    h:SetFrameLevel(10)
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    --lib.createBackdrop(h,1)
    
    if (i == 1) then
      php[i]:SetPoint('LEFT', php, 'LEFT', 1, 0)
    else
      php[i]:SetPoint('TOPLEFT', php[i-1], "TOPRIGHT", 2, 0)
    end
  end
  
  self.PaladinHolyPower = php
end


-- DEATH KNIGHT: Runebar
function ResourceBars.Runes(self)
  if playerClass ~= "DEATHKNIGHT" then return end

  self.Runes = CreateFrame("Frame", nil, self)
  self.Runes:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  self.Runes:SetHeight(5)
  self.Runes:SetWidth(self.Health:GetWidth()-15)
  
  for i= 1, 6 do
    self.Runes[i] = CreateFrame("StatusBar", self:GetName().."_Runes"..i, self)
    self.Runes[i]:SetHeight(5)
    self.Runes[i]:SetWidth((self.Health:GetWidth() / 6)-5)
    self.Runes[i]:SetStatusBarTexture(bar_common)
    self.Runes[i]:SetFrameLevel(11)
    self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
    self.Runes[i].bg:SetTexture(bar_common)
    self.Runes[i].bg:SetPoint("TOPLEFT", self.Runes[i], "TOPLEFT", 0, 0)
    self.Runes[i].bg:SetPoint("BOTTOMRIGHT", self.Runes[i], "BOTTOMRIGHT", 0, 0)
    self.Runes[i].bg.multiplier = 0.3
    
    local h = CreateFrame("Frame", nil, self.Runes[i])
    h:SetFrameLevel(10)
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    --lib.createBackdrop(h,1)
    
    if (i == 1) then
      self.Runes[i]:SetPoint('LEFT', self.Runes, 'LEFT', 1, 0)
    else
      self.Runes[i]:SetPoint('TOPLEFT', self.Runes[i-1], 'TOPRIGHT', 2, 0)
    end
  end
end


-- ROGUE: Combo Points
function ResourceBars.ComboPoints(self)
  if playerClass ~= "ROGUE" and playerClass ~= "DRUID" then return end

  local dcp = CreateFrame("Frame", nil, self)
  dcp:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  dcp:SetHeight(5)
  dcp:SetWidth(self.Health:GetWidth()/2+75)

  for i= 1, 5 do
    dcp[i] = CreateFrame("StatusBar", self:GetName().."_CPoints"..i, self)
    dcp[i]:SetHeight(5)
    dcp[i]:SetWidth((dcp:GetWidth()/5)-2)
    dcp[i]:SetStatusBarTexture(bar_common)
    dcp[i]:SetFrameLevel(11)
    dcp[i].bg = dcp[i]:CreateTexture(nil, "BORDER")
    dcp[i].bg:SetTexture(bar_common)
    dcp[i].bg:SetPoint("TOPLEFT", dcp[i], "TOPLEFT", 0, 0)
    dcp[i].bg:SetPoint("BOTTOMRIGHT", dcp[i], "BOTTOMRIGHT", 0, 0)
    dcp[i].bg.multiplier = 0.3
    
    local h = CreateFrame("Frame", nil, dcp[i])
    h:SetFrameLevel(10)
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    --lib.createBackdrop(h,1)
    
    if (i == 1) then
      dcp[i]:SetPoint('LEFT', dcp, 'LEFT', 1, 0)
    else
      dcp[i]:SetPoint('TOPLEFT', dcp[i-1], 'TOPRIGHT', 2, 0)
    end
  end
  dcp[1]:SetStatusBarColor(.3,.9,.3)
  dcp[2]:SetStatusBarColor(.3,.9,.3)
  dcp[3]:SetStatusBarColor(.3,.9,.3)
  dcp[4]:SetStatusBarColor(.9,.9,0)
  dcp[5]:SetStatusBarColor(.9,.3,.3)  
  --end
  
  self.DrkCPoints = dcp
end
