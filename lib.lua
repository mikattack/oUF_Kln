------------------------------------------------------------------------------
--| oUF_Kln
--| Authors: Drakull, Myno, Kellen
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------

local addon, ns = ...
local cfg = ns.cfg
local cast = ns.cast

local api = {}  -- Skip to the end to see the public API

local _, playerClass = UnitClass("player")

oUF.colors.runes = {
  {0.87, 0.12, 0.23},
  {0.40, 0.95, 0.20},
  {0.14, 0.50, 1},
  {.70, .21, 0.94},
}

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

-- Internal API's
local ElementFactory  = {}
local UnitFactory     = {}
local Decorators      = {}
local ResourceBars    = {}


------------------------------------------------------------------------------
--  Utility Functions
------------------------------------------------------------------------------


local function FormatTime(s)
  local day, hour, minute = 86400, 3600, 60
  if s >= day then
    return format("%dd", floor(s/day + 0.5)), s % day
  elseif s >= hour then
    return format("%dh", floor(s/hour + 0.5)), s % hour
  elseif s >= minute then
    if s <= minute * 5 then
      return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
    end
    return format("%dm", floor(s/minute + 0.5)), s % minute
  elseif s >= minute / 12 then
    return floor(s + 0.5), (s * 100 - floor(s * 100))/100
  end

  return format("%.1f", s), (s * 100 - floor(s * 100))/100
end


local function CreateAuraTimer(self, elapsed)
  if not self.timeLeft or self.timeLeft > 1800 then
    return
  end

  self.elapsed = (self.elapsed or 0) + elapsed

  if self.elapsed < 0.1 then
    return
  end

  if not self.first then
    self.timeLeft = self.timeLeft - self.elapsed
  else
    self.timeLeft = self.timeLeft - GetTime()
    self.first = false
  end
  if self.timeLeft > 0 then
    local time = FormatTime(self.timeLeft)
      self.time:SetText(time)
    if self.timeLeft < 5 then
      self.time:SetTextColor(1, 0.5, 0.5)
    else
      self.time:SetTextColor(.7, .7, .7)
    end
  else
    self.time:Hide()
    self:SetScript("OnUpdate", nil)
  end
  self.elapsed = 0
end


-- Right Click Menu
local function SpawnMenu(self)
  local unit = self.unit:sub(1, -2)
  local cunit = self.unit:gsub("^%l", string.upper)

  if(cunit == 'Vehicle') then
    cunit = 'Pet'
  end

  if(unit == "party" or unit == "partypet") then
    ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
  elseif(_G[cunit.."FrameDropDown"]) then
    ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
  end
end


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


local function PostCreateIcon(self, button)
  self.showDebuffType = true
  self.disableCooldown = true
  button.cd.noOCC = true
  button.cd.noCooldownCount = true

  button.icon:SetTexCoord(.04, .96, .04, .96)
  button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

  button:SetBackdrop({
    bgFile   = bar_power,
    edgeFile = bar_power,
    tile     = false,
    tileSize = 32, 
    edgeSize = 1,
    insets = { 
      left   = 1,
      right  = 1,
      top    = 1,
      bottom = 1,
    }
  });
  button:SetBackdropColor(0,0,0,1)
  button:SetBackdropBorderColor(0,0,0,1)

  button.overlay:SetTexture(bar_power)
  button.overlay:ClearAllPoints()
  button.overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
  button.overlay:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 1, -1)
  button.overlay:SetDrawLayer('BACKGROUND')
  
  button.time = ElementFactory.CreateString(button, font_small, 8, "OUTLINE")
  button.time:SetPoint("BOTTOMLEFT", button, -2, -2)
  button.time:SetJustifyH('CENTER')
  button.time:SetVertexColor(1,1,1)
  
  button.count = ElementFactory.CreateString(button, font_small, 8, "OUTLINE")
  button.count:ClearAllPoints()
  button.count:SetPoint("TOPRIGHT", button, 2, 2)
  button.count:SetVertexColor(1,1,1) 
end


local function PostUpdateIcon(self, unit, icon, index, offset, filter, isDebuff)
  local _, _, _, _, _, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
  
  if duration and duration > 0 then
    icon.time:Show()
    icon.timeLeft = expirationTime  
    icon:SetScript("OnUpdate", CreateAuraTimer)     
  else
    icon.time:Hide()
    icon.timeLeft = math.huge
    icon:SetScript("OnUpdate", nil)
  end
  
  --[[
  -- Desaturate Player Auras
  if unit == "target" then
    if (unitCaster == 'player' or unitCaster == 'vehicle') then
      icon.icon:SetDesaturated(nil)
    elseif not UnitPlayerControlled(unit) then -- If Unit is Player Controlled don't desaturate debuffs
      icon:SetBackdropColor(0, 0, 0)
      --icon.overlay:SetVertexColor(0.3, 0.3, 0.3)
      icon.overlay:SetVertexColor(.22, .27, .35)
      icon.icon:SetDesaturated(1)
    end
  end
  --]]
  
  --icon.first = true
end


--[[--------------------------------------------------------------------------
  Element Factory
  
  Creates the frames, strings, and elements which comprise the parts of
  any unit frames.
----------------------------------------------------------------------------]]


-- 
-- Creates a string for a given frame.
-- 
-- The string is a child of the passed frame but has no position set for it.
-- 
-- @param frame   Frame to create string for.
-- @param font    Path of the font file.
-- @param size    Font size.
-- @param outline Font outline (default: 'NONE', 'OUTLINE', 'THICKOUTLINE').
-- @return FontString
-- 
function ElementFactory.CreateString(frame, font, size, outline)
  outline = outline or 'NONE'

  local fs = frame:CreateFontString(nil, "OVERLAY")
  fs:SetFont(font, size, outline)
  fs:SetShadowColor(0, 0, 0, 0.8)
  fs:SetShadowOffset(1, -1)
  return fs
end


-- 
-- Creates a StatusBar for a given frame.
-- 
-- The bar is a child of the passed frame but has no position set for it.
-- 
-- @param frame       Frame to create bar for.
-- @param width       Flavor of chocolate.
-- @param height      Clog size.
-- @param texture     Path to texture for bar foreground/background.
-- @param texture_bg  [optional] Path to texture for bar background.
-- @return StatusBar,
--         Texture    The foreground bar and background texture.
-- 
function ElementFactory.CreateBar(frame, width, height, texture, texture_bg)
  texture_bg = texture_bg or texture

  local s = CreateFrame("StatusBar", nil, frame)
  s:SetHeight(height)
  s:SetWidth(width)
  s:SetStatusBarTexture(texture)
  s:GetStatusBarTexture():SetHorizTile(true)
  s:SetFrameStrata("MEDIUM")

  local b = s:CreateTexture(nil, "BACKGROUND")
  b:SetTexture(texture_bg)
  b:SetAllPoints(s)

  return s, b

  -- TODO:
  --   Add an addressible frame which can be toggled on and off (outside
  --   of combat) to possibly allow for drag-n-drop location configuration.
  --   Maybe.
end


-- 
-- Creates a black background for a frame with a semi-transparent border
-- around it.
-- 
-- The background frame is positioned to fill the entirety of the parent
-- frame's.
-- 
-- @param frame
-- @return Frame  The created background frame.
-- 
function ElementFactory.CreateBackground(frame)
  local bg = CreateFrame("Frame", nil, frame)
  bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -4, 4)
  bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 4, -4)
  bg:SetFrameStrata("BACKGROUND")

  bg:SetBackdrop({
    bgFile   = bg_common,
    edgeFile = border_common,
    tile     = false,
    tileSize = 0, 
    edgeSize = 11, 
    insets = { 
      left   = 3,
      right  = 3,
      top    = 3,
      bottom = 3,
    }
  });
  bg:SetBackdropColor(0,0,0,1)
  bg:SetBackdropBorderColor(0,0,0,0.4)

  return bg
end


-- 
-- Creates a castbar.
-- 
-- An entire castbar is created but not positioned.  Castbars may only by
-- created for "player" or "target" units.
-- 
-- @param frame
-- @param width
-- @param height
-- @return Frame  The created castbar frame.
-- 
function ElementFactory.CreateCastbar(frame, width, height)
  if frame.mystyle ~= "player" and frame.mystyle ~= "target" then
    return
  end

  local s = CreateFrame("StatusBar", "oUF_klnFramesCastbar"..frame.mystyle, frame)

  s:SetHeight(height)
  s:SetWidth(width)

  s:SetStatusBarTexture(bar_common)
  s:SetStatusBarColor(.5, .5, 1, 1)
  
  -- Color
  s.CastingColor    = {.5, .5, 1}
  s.CompleteColor   = {0.5, 1, 0}
  s.FailColor       = {1.0, 0.05, 0}
  s.ChannelingColor = {.5, .5, 1}

  -- Background & Container
  local c = CreateFrame("Frame", nil, s)
  c:SetPoint("TOPLEFT", s, "TOPLEFT", -(height + 1), 0)
  c:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", 0, 0)
  c:SetFrameLevel(0)
  ElementFactory.CreateBackground(c)
  s.background = c;

  -- Backdrop
  local b = s:CreateTexture(nil, "BACKGROUND")
  b:SetTexture(bar_common)
  b:SetAllPoints(s)
  b:SetVertexColor(.5*0.2,.5*0.2,1*0.2,0.7)

  -- Spark
  sp = s:CreateTexture(nil, "OVERLAY")
  sp:SetBlendMode("ADD")
  sp:SetAlpha(0.5)
  sp:SetHeight(s:GetHeight() * 2.5)
  
  -- Spell text
  local txt = ElementFactory.CreateString(s, font_common, 14, "NONE")
  txt:SetPoint("LEFT", 4, 0)
  txt:SetJustifyH("LEFT")
  
  -- Time
  local t = ElementFactory.CreateString(s, font_common, 14, "NONE")
  t:SetPoint("RIGHT", -2, 0)
  txt:SetPoint("RIGHT", t, "LEFT", -5, 0)
  
  -- Icon
  local i = s:CreateTexture(nil, "ARTWORK")
  i:SetPoint("RIGHT", s, "LEFT", -1, 0)
  i:SetSize(s:GetHeight() - 1, s:GetHeight() - 1)
  i:SetTexCoord(0.1, 0.9, 0.1, 0.9)

  if frame.mystyle == "player" then
    -- Latency only for player unit
    local z = s:CreateTexture(nil,"OVERLAY")
    z:SetTexture(bar_common)
    z:SetVertexColor(1,0,0,.6)
    z:SetPoint("TOPRIGHT")
    z:SetPoint("BOTTOMRIGHT")
    s.SafeZone = z

    -- Custom latency display
    local l = ElementFactory.CreateString(s, font_common, 10, "THINOUTLINE")
    l:SetPoint("CENTER", -2, 17)
    l:SetJustifyH("RIGHT")
    l:Hide()
    s.Lag = l
    frame:RegisterEvent("UNIT_SPELLCAST_SENT", cast.OnCastSent)
  end

  s.OnUpdate = cast.OnCastbarUpdate
  s.PostCastStart = cast.PostCastStart
  s.PostChannelStart = cast.PostCastStart
  s.PostCastStop = cast.PostCastStop
  s.PostChannelStop = cast.PostChannelStop
  s.PostCastFailed = cast.PostCastFailed
  s.PostCastInterrupted = cast.PostCastFailed

  frame.Castbar = s
  frame.Castbar.Text = txt
  frame.Castbar.Time = t
  frame.Castbar.Icon = i
  frame.Castbar.Spark = sp

  return s
end


--[[--------------------------------------------------------------------------
  Unit Frame Factory

  Creates the frames, strings, and elements which comprise the parts of
  a particular unit frame.  This is certainly overkill, but I like the
  clarity.
----------------------------------------------------------------------------]]


function UnitFactory.Player(frame, width, height)
  frame:SetSize(width,height)
  frame.background = ElementFactory.CreateBackground(frame)

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local percent, raw, power

  percent = ElementFactory.CreateString(frame.Health, font_common, 28, "OUTLINE")
  percent:SetPoint("LEFT", frame.Health, "LEFT", 3, 3)
  percent.frequentUpdates = true

  raw = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
  raw:SetPoint("BOTTOMLEFT", percent, "BOTTOMRIGHT", 0, 3)
  raw.frequentUpdates = true

  power = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
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
  local cb = ElementFactory.CreateCastbar(frame, 250, 26)
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
function UnitFactory.Target(frame, width, height)
  frame:SetSize(width,height)
  frame.background = ElementFactory.CreateBackground(frame)

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
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
  local cb = ElementFactory.CreateCastbar(frame, 250, 26)
  if cb then
    -- In case of the "focus" unit
    cb:SetPoint("TOP", oUF_klnFramesCastbarplayer, "BOTTOM", 0, -8)
  end

  -- Auras
  Decorators.Auras(frame)
  frame.Auras.CustomFilter = ns.CustomAuraFilters.target
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
function UnitFactory.TargetOfTarget(frame, width, height)
  frame:SetSize(width,height)
  frame.background = ElementFactory.CreateBackground(frame)

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
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


function UnitFactory.Pet(frame, width, height)
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
  frame.background = ElementFactory.CreateBackground(frame)

  height = 12

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 5, bar_common)
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


function UnitFactory.Raid(frame, width, height)
  frame.background = ElementFactory.CreateBackground(frame)

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 4, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)
  frame.Health:SetStatusBarColor(.12, .12, .12, 1)
  frame.Health:SetStatusBarTexture(bar_raid)

  -- Text readouts
  local name, deficit

  name = ElementFactory.CreateString(frame.Health, font_raid, 12, "NONE")
  name:SetPoint("TOPLEFT", frame.Health, "TOPLEFT", 1, -1)
  name:SetPoint("RIGHT", frame, "RIGHT", -1, 0)
  name:SetJustifyH("LEFT")
  name.frequentUpdates = true

  deficit = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
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


function UnitFactory.Boss(frame, width, height)
  frame:SetSize(width,height)
  frame.background = ElementFactory.CreateBackground(frame)

  -- Health bar
  local f, bg = ElementFactory.CreateBar(frame, width, height - 5, bar_common)
  frame.Health = f
  frame.Health.bg = bg
  frame.Health:SetPoint("TOP", 0, 0)

  -- Text readouts
  local name, health

  name = ElementFactory.CreateString(frame.Health, font_common, 16, "OUTLINE")
  name:SetPoint("LEFT", frame.Health, "LEFT", 3, 0)
  name.frequentUpdates = true

  health = ElementFactory.CreateString(frame.Health, font_common, 28, "OUTLINE")
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


--[[--------------------------------------------------------------------------
  Frame Decorators

  Add common things to a given frame.  Behavior may be different depending
  on the unit type of the frame.
----------------------------------------------------------------------------]]


function Decorators.PowerBar(frame)
  local f, bg = ElementFactory.CreateBar(frame, frame:GetWidth(), 4, bar_power)
  frame.Power = f
  frame.Power.bg = bg
  frame.Power:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
  frame.Power.frequentUpdates = true
  -- s:SetStatusBarColor(165/255, 73/255, 23/255, 1)  -- Boss color
end


function Decorators.StatusIcons(frame)
  local unit = frame.mystyle

  local h = CreateFrame("Frame", nil, frame)
  h:SetAllPoints(frame)
  --h:SetFrameLevel(10)

  -- Raid Marks
  ri = h:CreateTexture(nil,'OVERLAY')
  ri:SetSize(20, 20)
  if unit == 'player' or unit == 'target' or unit == 'focus' then
    ri:SetPoint("RIGHT", frame, "LEFT", -3, 0)
  elseif frame.mystyle == 'raid' then 
    ri:SetPoint("CENTER", frame, "TOP", 0, 0)
    ri:SetSize(12, 12)
  else
    ri:SetPoint("LEFT", frame, "RIGHT", 3, 0)
  end
  frame.RaidIcon = ri

  -- Raid-specific Icons
  if unit == 'raid' then
    -- Leader, Assist, Master Looter Icon
    li = h:CreateTexture(nil, "OVERLAY")
    li:SetPoint("TOPLEFT", frame, 0, 8)
    li:SetSize(12, 12)
    frame.Leader = li
    ai = h:CreateTexture(nil, "OVERLAY")
    ai:SetPoint("TOPLEFT", frame, 0, 8)
    ai:SetSize(12 ,12)
    frame.Assistant = ai
    local ml = h:CreateTexture(nil, 'OVERLAY')
    ml:SetSize(10, 10)
    ml:SetPoint('LEFT', frame.Leader, 'RIGHT')
    frame.MasterLooter = ml

    -- Resurrection
    rezicon = h:CreateTexture(nil,'OVERLAY')
    rezicon:SetPoint('CENTER',frame,'CENTER',0,-3)
    rezicon:SetSize(16,16)
    frame.ResurrectIcon = rezicon

    -- Ready Check
    rc = frame.Health:CreateTexture(nil, "OVERLAY")
    rc:SetSize(14, 14)
    rc:SetPoint("TOPRIGHT", frame.Health, "TOPRIGHT", -1, 2)
    frame.ReadyCheck = rc
  end

  --LFDRole icon
  if unit == 'player' or unit == 'target' then
    frame.LFDRole = h:CreateTexture(nil, 'OVERLAY')
    frame.LFDRole:SetSize(15,15)
    frame.LFDRole:SetAlpha(0.9)
    frame.LFDRole:SetPoint('BOTTOMLEFT', -6, -8)
  elseif unit == 'raid' then 
    frame.LFDRole = h:CreateTexture(nil, 'OVERLAY')
    frame.LFDRole:SetSize(12,12)
    frame.LFDRole:SetPoint('CENTER', frame, 'RIGHT', 1, 0)
    frame.LFDRole:SetAlpha(0)
  end

  -- Stop adding icons for non-player or non-targets
  if unit ~= "player" and unit ~= "target" then
    return
  end

  --Combat Icon
  if unit == "player" then
    frame.Combat = h:CreateTexture(nil, 'OVERLAY')
    frame.Combat:SetSize(15, 15)
    frame.Combat:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
    frame.Combat:SetTexCoord(0.58, 0.90, 0.08, 0.41)
    frame.Combat:SetPoint('BOTTOMRIGHT', -20, -20)
  elseif unit == "target" then
    local combat = CreateFrame("Frame", nil, h)
    combat:SetSize(15, 15)
    combat:SetPoint("BOTTOMRIGHT", 7, -7)
    frame.CombatIcon = combat

    local combaticon = combat:CreateTexture(nil, "ARTWORK")
    combaticon:SetAllPoints(true)
    combaticon:SetTexture("Interface\\CharacterFrame\\UI-StateIcon")
    combaticon:SetTexCoord(0.58, 0.9, 0.08, 0.41)
    combat.icon = combaticon

    combat.__owner = frame
    combat:SetScript("OnUpdate", function(self)
        local unit = self.__owner.unit
        if unit and UnitAffectingCombat(unit) then
            self.icon:Show()
        else
            self.icon:Hide()
        end
    end)
  end

  -- PvP Icon
  frame.PvP = h:CreateTexture(nil, "OVERLAY")
  frame.PvP:SetHeight(14)
  frame.PvP:SetWidth(14)
  local faction = PvPCheck
  if faction == "Horde" then
    frame.PvP:SetTexCoord(0.08, 0.58, 0.045, 0.545)
  elseif faction == "Alliance" then
    frame.PvP:SetTexCoord(0.07, 0.58, 0.06, 0.57)
  else
    frame.PvP:SetTexCoord(0.05, 0.605, 0.015, 0.57)
  end
  if unit == 'player' then
    frame.PvP:SetPoint("TOPRIGHT", 7, 7)
  elseif unit == 'target' then
    frame.PvP:SetPoint("TOPRIGHT", 7, 7)
  end

  -- Rest Icon
  if unit == 'player' then
    frame.Resting = h:CreateTexture(nil, 'OVERLAY')
    frame.Resting:SetSize(15,15)
    frame.Resting:SetPoint('BOTTOMRIGHT', -20, -20)
    frame.Resting:SetTexture('Interface\\CharacterFrame\\UI-StateIcon')
    frame.Resting:SetTexCoord(0.09, 0.43, 0.08, 0.42)
  end

  -- Phase Icon
  if unit == 'target' then
    picon = h:CreateTexture(nil, 'OVERLAY')
    picon:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -18, 8)
    picon:SetSize(16, 16)
    frame.PhaseIcon = picon
  end

  -- Quest Icon
  if unit == 'target' then
    qicon = frame.Health:CreateTexture(nil, 'OVERLAY')
    qicon:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -2, 8)
    qicon:SetSize(16, 16)
    frame.QuestIcon = qicon
  end
end


function Decorators.HealPrediction(frame)
  if not cfg.showIncHeals then return end

  local mhpb = CreateFrame('StatusBar', nil, frame.Health)
  mhpb:SetPoint('TOPLEFT', frame.Health:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
  mhpb:SetPoint('BOTTOMLEFT', frame.Health:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
  mhpb:SetWidth(frame:GetWidth())
  mhpb:SetStatusBarTexture(bar_common)

  if frame.mystyle == "raid" then
    mhpb:SetStatusBarColor(0, 200/255, 0, 0.4)
  else
    mhpb:SetFrameLevel(2)
    mhpb:SetStatusBarColor(0, 200/255, 0, 0.8)
  end

  local ohpb = CreateFrame('StatusBar', nil, frame.Health)
  ohpb:SetPoint('TOPLEFT', mhpb:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
  ohpb:SetPoint('BOTTOMLEFT', mhpb:GetStatusBarTexture(), 'BOTTOMRIGHT', 0, 0)
  ohpb:SetWidth(frame:GetWidth())
  ohpb:SetStatusBarTexture(bar_common)

  if frame.mystyle == "raid" then
    ohpb:SetStatusBarColor(0, 200/255, 0, 0.4)
  else
    ohpb:SetFrameLevel(2)
    ohpb:SetStatusBarColor(0, 200/255, 0, 0.8)
  end

  frame.HealPrediction = {
    myBar = mhpb,
    otherBar = ohpb,
    maxOverflow = 1.01,
  }
end


function Decorators.Highlight(frame)
  local OnEnter = function(f)
    UnitFrame_OnEnter(f)
    f.Highlight:Show()
    if f.mystyle == "raid" then
      GameTooltip:Hide()
      f.LFDRole:SetAlpha(1)
    end
  end

  local OnLeave = function(f)
    UnitFrame_OnLeave(f)
    f.Highlight:Hide()
    if f.mystyle == "raid" then
      f.LFDRole:SetAlpha(0)
    end
  end

  frame:SetScript("OnEnter", OnEnter)
  frame:SetScript("OnLeave", OnLeave)
  
  local hl = frame.Health:CreateTexture(nil, "OVERLAY")
  hl:SetAllPoints(frame.Health)
  hl:SetTexture(bg_highlight)
  hl:SetVertexColor(.5, .5, .5, .1)
  hl:SetBlendMode("ADD")
  hl:Hide()
  frame.Highlight = hl
end


function Decorators.Border(frame)
  local glowBorder = {
    edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeSize = 1
  }
  frame.TargetBorder = CreateFrame("Frame", nil, frame)
  frame.TargetBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", -2.5, 2.5)
  frame.TargetBorder:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 3, -2.5)
  frame.TargetBorder:SetBackdrop(glowBorder)
  frame.TargetBorder:SetBackdropBorderColor(.7, .7, .7, .8)
  frame.TargetBorder:Hide()
end


function Decorators.RaidDebuffs(frame)
  local raid_debuffs = cfg.DebuffWatchList
  local debuffs = raid_debuffs.debuffs

  local CustomFilter = function(icons, ...)
    local _, icon, _, _, _, _, dtype, _, _, _, _, _, spellID = ...
    name = tostring(spellID)
    if debuffs[name] then
      icon.priority = debuffs[name]
      return true
    else
      icon.priority = 0
    end
  end

  local debuffs = CreateFrame("Frame", nil, frame)
  debuffs:SetWidth(12)
  debuffs:SetHeight(12)
  debuffs:SetFrameLevel(5)
  debuffs:SetPoint("TOPRIGHT", self, "TOPRIGHT", -4, -4)
  debuffs.size = 12
  
  debuffs.CustomFilter = CustomFilter
  frame.raidDebuffs = debuffs
end


function Decorators.Auras(frame)
  auras = CreateFrame("Frame", nil, frame)

  auras.size = 22
  auras.numBuffs = 10
  auras.numDebuffs = 16
  auras.spacing = 1

  auras:SetHeight(auras.size * 2 + 2)
  auras:SetWidth(frame:GetWidth())

  auras.PostCreateIcon = PostCreateIcon
  auras.PostUpdateIcon = PostUpdateIcon

  frame.Auras = auras
end


------------------------------------------------------------------------------
-- Class-specific Resource Bars
------------------------------------------------------------------------------



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
  ElementFactory.CreateBackground(h)

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
    
	local EBText = ElementFactory.CreateString(solarBar, font_common, 14, "OUTLINE")
	EBText:SetPoint('CENTER', eclipseBar, 'CENTER', 0,0)
	local EBText2 = ElementFactory.CreateString(solarBar, font_common, 16, "THINOUTLINE")
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

  local background = ElementFactory.CreateBackground(mhb)
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
  ElementFactory.CreateBackground(wsb)
	
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


------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------


api.Player            = UnitFactory.Player
api.Target            = UnitFactory.Target
api.TargetOfTarget    = UnitFactory.TargetOfTarget
api.Pet               = UnitFactory.Pet
api.Raid              = UnitFactory.Raid
api.Boss              = UnitFactory.Boss

api.CreateString      = ElementFactory.CreateString
api.CreateBar         = ElementFactory.CreateBar
api.CreateBackground  = ElementFactory.CreateBackground

-- Phanx libraries
api.GetPlayerRole     = ns.GetPlayerRole
api.CustomAuraFilters = ns.CustomAuraFilters

api.SpawnMenu = SpawnMenu
api.StyleMirrorBar = function(f)
  -- NOTE:  The bars are just styled, not repositioned
  for _, bar in pairs({'MirrorTimer1','MirrorTimer2','MirrorTimer3',}) do
    _G[bar..'Border']:Hide()

    _G[bar]:SetParent(UIParent)
    _G[bar]:SetScale(1)
    _G[bar]:SetHeight(20)
    _G[bar]:SetWidth(300)
    _G[bar]:SetBackdropColor(.1,.1,.1)
    _G[bar]:SetFrameLevel(1)

    bg = ElementFactory.CreateBackground(_G[bar])
    bg:SetFrameLevel(0)

    _G[bar..'Background'] = _G[bar]:CreateTexture(bar..'Background', 'BACKGROUND', _G[bar])
    _G[bar..'Background']:SetTexture(bar_common)
    _G[bar..'Background']:SetAllPoints(bar)
    _G[bar..'Background']:SetVertexColor(.15,.3,.5,.75)

    _G[bar..'Text']:SetFont(font_common, 14)
    _G[bar..'Text']:ClearAllPoints()
    _G[bar..'Text']:SetPoint('CENTER', MirrorTimer1StatusBar, 0, 1)

    _G[bar..'StatusBar']:SetAllPoints(_G[bar])
    _G[bar..'StatusBar']:SetStatusBarTexture(bar_common)
  end
end


------------------------------------------------------------------------------
-- The Handoff
------------------------------------------------------------------------------


ns.lib = api
