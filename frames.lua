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

local FACTORY = {}
local CAST = {}


--[[--------------------------------------------------------------------------
  Frame Factory
  
  Creates the frames, strings, and elements which comprise the parts of
  any unit frames.
----------------------------------------------------------------------------]]


-- Media
local bar_common    = cfg.media.bar.common
local bg_common     = cfg.media.background.common
local border_common = cfg.media.border.common
local font_common   = cfg.media.font.common


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
function FACTORY.CreateString(frame, font, size, outline)
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
function FACTORY.CreateBar(frame, width, height, texture, texture_bg)
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
function FACTORY.CreateBackground(frame)
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
function FACTORY.CreateCastbar(frame, width, height)
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
  FACTORY.CreateBackground(c)
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
  local txt = FACTORY.CreateString(s, font_common, 14, "NONE")
  txt:SetPoint("LEFT", 4, 0)
  txt:SetJustifyH("LEFT")
  
  -- Time
  local t = FACTORY.CreateString(s, font_common, 14, "NONE")
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
    local l = FACTORY.CreateString(s, font_common, 10, "THINOUTLINE")
    l:SetPoint("CENTER", -2, 17)
    l:SetJustifyH("RIGHT")
    l:Hide()
    s.Lag = l
    frame:RegisterEvent("UNIT_SPELLCAST_SENT", CAST.OnCastSent)
  end

  s.OnUpdate = CAST.OnCastbarUpdate
  s.PostCastStart = CAST.PostCastStart
  s.PostChannelStart = CAST.PostCastStart
  s.PostCastStop = CAST.PostCastStop
  s.PostChannelStop = CAST.PostChannelStop
  s.PostCastFailed = CAST.PostCastFailed
  s.PostCastInterrupted = CAST.PostCastFailed

  frame.Castbar = s
  frame.Castbar.Text = txt
  frame.Castbar.Time = t
  frame.Castbar.Icon = i
  frame.Castbar.Spark = sp

  return s
end


------------------------------------------------------------------------------
-- Internal
------------------------------------------------------------------------------


local ticks = {}

-- Special thanks to Allez for coming up with this solution
local channelingTicks = {
  -- Warlock
  [GetSpellInfo(1120)] = 5,   -- Drain Soul
  [GetSpellInfo(689)] = 5,    -- Drain Life
  --[GetSpellInfo(5138)] = 5, -- Drain Mana
  [GetSpellInfo(5740)] = 4,   -- Rain of Fire
  -- Druid
  [GetSpellInfo(740)] = 4,    -- Tranquility
  [GetSpellInfo(16914)] = 9,  -- Hurricane
  -- Priest
  [GetSpellInfo(15407)] = 3,  -- Mind Flay
  [GetSpellInfo(48045)] = 5,  -- Mind Sear
  [GetSpellInfo(47540)] = 2,  -- Penance
  -- Mage
  [GetSpellInfo(5143)] = 5,   -- Arcane Missiles
  [GetSpellInfo(10)] = 5,     -- Blizzard
  [GetSpellInfo(12051)] = 4,  -- Evocation
}


CAST.setBarTicks = function(castBar, ticknum)
  if ticknum and ticknum > 0 then
    local delta = castBar:GetWidth() / ticknum
    for k = 1, ticknum do
      if not ticks[k] then
        ticks[k] = castBar:CreateTexture(nil, 'OVERLAY')
        ticks[k]:SetTexture(cfg.statusbar_texture)
        ticks[k]:SetVertexColor(0.8, 0.6, 0.6)
        ticks[k]:SetWidth(1)
        ticks[k]:SetHeight(castBar:GetHeight())
      end
      ticks[k]:ClearAllPoints()
      ticks[k]:SetPoint("CENTER", castBar, "LEFT", delta * k, 0 )
      ticks[k]:Show()
    end
  else
    for k, v in pairs(ticks) do
      v:Hide()
    end
  end
end


CAST.OnCastbarUpdate = function(self, elapsed)
  local currentTime = GetTime()
  if self.casting or self.channeling then
    local parent = self:GetParent()
    local duration = self.casting and self.duration + elapsed or self.duration - elapsed
    if (self.casting and duration >= self.max) or (self.channeling and duration <= 0) then
      self.casting = nil
      self.channeling = nil
      return
    end
    if parent.unit == 'player' then
      if self.delay ~= 0 then
        self.Time:SetFormattedText('%.1f | |cffff0000%.1f|r', duration, self.casting and self.max + self.delay or self.max - self.delay)
      else
        self.Time:SetFormattedText('%.1f | %.1f', duration, self.max)
        if self.SafeZone and self.SafeZone.timeDiff then
          self.Lag:SetFormattedText("%d ms", self.SafeZone.timeDiff * 1000)
        end
      end
    else
      self.Time:SetFormattedText('%.1f | %.1f', duration, self.casting and self.max + self.delay or self.max - self.delay)
    end
    self.duration = duration
    self:SetValue(duration)
    self.Spark:SetPoint('CENTER', self, 'LEFT', (duration / self.max) * self:GetWidth(), 0)
  else
    self.Spark:Hide()
    local alpha = self:GetAlpha() - 0.02
    if alpha > 0 then
      self:SetAlpha(alpha)
    else
      self.fadeOut = nil
      self:Hide()
    end
  end
end


CAST.OnCastSent = function(self, event, unit, spell, rank)
  if self.unit ~= unit or not self.Castbar.SafeZone then return end
  self.Castbar.SafeZone.sendTime = GetTime()
end


CAST.PostCastStart = function(self, unit, name, rank, text)
  local pcolor = {1, .5, .5}
  local interruptcb = {.5, .5, 1}
  self:SetAlpha(1.0)
  self.Spark:Show()
  self:SetStatusBarColor(unpack(self.casting and self.CastingColor or self.ChannelingColor))
  if unit == "player" then
    local sf = self.SafeZone
    if sf and sf.sendTime ~= nil then
      sf.timeDiff = GetTime() - sf.sendTime
      sf.timeDiff = sf.timeDiff > self.max and self.max or sf.timeDiff
      sf:SetWidth(self:GetWidth() * sf.timeDiff / self.max)
      sf:Show()
    end
    
    if self.casting then
      CAST.setBarTicks(self, 0)
    else
      local spell = UnitChannelInfo(unit)
      self.channelingTicks = channelingTicks[spell] or 0
      CAST.setBarTicks(self, self.channelingTicks)
    end
  elseif (unit == "target" or unit == "focus") and not self.interrupt then
    self:SetStatusBarColor(interruptcb[1],interruptcb[2],interruptcb[3],1)
  else
    self:SetStatusBarColor(pcolor[1], pcolor[2], pcolor[3],1)
  end
end


CAST.PostCastStop = function(self, unit, name, rank, castid)
  if not self.fadeOut then 
    self:SetStatusBarColor(unpack(self.CompleteColor))
    self.fadeOut = true
  end
  self:SetValue(self.max)
  self:Show()
end


CAST.PostChannelStop = function(self, unit, name, rank)
  self.fadeOut = true
  self:SetValue(0)
  self:Show()
end


CAST.PostCastFailed = function(self, event, unit, name, rank, castid)
  self:SetStatusBarColor(unpack(self.FailColor))
  self:SetValue(self.max)
  if not self.fadeOut then
    self.fadeOut = true
  end
  self:Show()
end


------------------------------------------------------------------------------
-- Mirror Bar
------------------------------------------------------------------------------


lib.StyleMirrorBar = function(f)
  -- NOTE:  The bars are just styled, not repositioned
  for _, bar in pairs({'MirrorTimer1','MirrorTimer2','MirrorTimer3',}) do
    _G[bar..'Border']:Hide()

    _G[bar]:SetParent(UIParent)
    _G[bar]:SetScale(1)
    _G[bar]:SetHeight(20)
    _G[bar]:SetWidth(300)
    _G[bar]:SetBackdropColor(.1,.1,.1)
    _G[bar]:SetFrameLevel(1)

    bg = lib.CreateBackground(_G[bar])
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
-- Expose API
------------------------------------------------------------------------------


lib.CreateString      = FACTORY.CreateString
lib.CreateBar         = FACTORY.CreateBar
lib.CreateBackground  = FACTORY.CreateBackground
lib.CreateCastbar     = FACTORY.CreateCastbar

-- MirrorBar handled above

lib.RightClickMenu = function(self)
  local unit = self.unit:sub(1, -2)
  local cunit = self.unit:gsub("^%l", string.upper)
  if(cunit == 'Vehicle') then
    cunit = 'Pet'
  end
  if unit == "party" or unit == "partypet" then
    ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..self.id.."DropDown"], "cursor", 0, 0)
  elseif _G[cunit.."FrameDropDown"] then
    ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
  end
end
