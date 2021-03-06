------------------------------------------------------------------------------
--| oUF_Kln
--| Authors: Drakull, Myno, Kellen
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------


local addon, ns = ...
  
local cfg   = ns.Kln.cfg
local lib   = ns.Kln.lib
local units = ns.Kln.units

local layouts = cfg.layouts or {}

-- Redeclare health colors
oUF.colors.smooth = { 
  1, 0, 0,          --low health
  1, .196, .196,    --half health
  .165, .188, .196  --max health
}

-- Redeclare Rune colors
--[[
oUF.colors.runes = {
  {0.87, 0.12, 0.23},
  {0.40, 0.95, 0.20},
  {0.14, 0.50, 1},
  {.70, .21, 0.94},
}
--]]


------------------------------------------------------------------------------
-- Load Custom Layout (as necessary)
------------------------------------------------------------------------------

-- 
-- Don't be fooled.  "Layouts" are really just "hooks" into th oUF spawning
-- process.  Didn't seem like there was a way to do this through oUF, so I'm
-- faking it.
-- 

local _, class = UnitClass("player")
local name = UnitName("player")
local layout = nil

-- Detect a layout (preferring a character-specific one over a class-based one)
if cfg.layouts then
  if cfg.layouts[name] then
    layout = cfg.layouts[name]
  elseif cfg.layouts[class] then
    layout = cfg.layouts[class]
  end
end

-- 
-- Provide layouts a convenience for accessing frames spawned by oUF.
-- 

-- Spawned frames (disallow transforms on Boss or Raid frames)
local frames = {
  player        = "oUF_klnFramesPlayer",
  target        = "oUF_klnFramesTarget",
  targettarget  = "oUF_klnFramesTargetTarget",
  focus         = "oUF_klnFramesFocus",
  focustarget   = "oUF_klnFramesFocusTarget",
  pet           = "oUF_klnFramesPet",
  raid          = nil,
  boss          = nil,
}

local lapi = {}
function lapi.GetFrame(name) return _G[frames[name]] end
function lapi.GetFrameName(name) return frames[name] end


------------------------------------------------------------------------------
-- Default Layout
------------------------------------------------------------------------------

--
-- The default layout sets up the general look and positioning the oUF_Kln.
-- Though these settings cannot be altered, they can be overridden through
-- "spawn" and "postspawn" hooks.  This is how each class is given a
-- unique layout (for those classes which have them).
-- 
-- Hooks:
--  "spawn"     - Run once per unit frame, passed the spawned frame.
--  "postspawn" - Run once after spawning everything.  Passed the frame
--                accessor convenience method API.
-- 

local framewidth  = math.ceil(UIParent:GetWidth() * 0.2442)
local frameheight = 26

local DefaultLayout = {
  player = function(self, ...)
    self.mystyle = "player"
    units.Player(self, framewidth, frameheight)
    self:SetSize(framewidth,frameheight)
    self:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 60)

    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", cfg.updateSpec)
  end,
  

  target = function(self, ...)
    self.mystyle = "target"
    units.Target(self, framewidth * 0.70, frameheight)
    self:SetSize(framewidth * 0.70,frameheight)
    self.Auras:SetWidth(framewidth)

    self:SetPoint("BOTTOMLEFT", lapi.GetFrame('player'), "TOPLEFT", 0, 8)
  end,
  

  targettarget = function(self, ...)
    self.mystyle = "tot"
    units.TargetOfTarget(self, framewidth * 0.30 - 8, frameheight)
    self:SetSize(framewidth * 0.30 - 8,frameheight)

    self:SetPoint("LEFT", lapi.GetFrame('target'), "RIGHT", 8, 0)
  end,


  focus = function(self, ...)
    self.mystyle = "focus"
    units.Target(self, framewidth * 0.70, frameheight)
    self:SetSize(framewidth * 0.70,frameheight)

    self:SetPoint("TOP", UIParent, "TOP", -math.floor((framewidth * 0.30) / 2), -15)
  end,
  

  focustarget = function(self, ...)
    self.mystyle = "focustarget"
    units.TargetOfTarget(self, framewidth * 0.30 - 8, frameheight)
    self:SetSize(framewidth * 0.30 - 8,frameheight)

    self:SetPoint("LEFT", lapi.GetFrame('focus'), "RIGHT", 8, 0)
  end,
  
  pet = function(self, ...)
    self.mystyle = "pet"
    units.Pet(self, framewidth * 0.75, 12)
    self:SetSize(framewidth * 0.75, 12)

    self:SetPoint("TOPLEFT", lapi.GetFrame('player'), "BOTTOMLEFT", 0, -8)
  end,
  

  raid = function(self, ...)
    self.mystyle = "raid"
    units.Raid(self, 77, 32)
  end,


  boss = function(self, ...)
    self.mystyle = "boss"
    units.Boss(self, framewidth, frameheight)
    self:SetSize(framewidth, frameheight)
  end,
}


------------------------------------------------------------------------------
--  oUF Style Registration
------------------------------------------------------------------------------

-- 
-- Common unit frame handler.
-- 
local UnitFrameStyle = function(self, unit, isSingle)
  self.menu = lib.RightClickMenu
  self:RegisterForClicks('AnyUp')
  
  -- Call Unit Specific Styles
  if (DefaultLayout[unit]) then
    local f = DefaultLayout[unit](self)
    if layout and layout.spawn and type(layout.spawn) == 'function' then
      layout.spawn(self)
    end
  end
end


-- 
-- Raid frames handler.
-- 
local RaidStyle = function(self, unit)
  if (cfg.enableRightClickMenu) then
    self.menu = lib.RightClickMenu
    self:RegisterForClicks('AnyUp')
  end
  
  if (DefaultLayout[unit]) then
    local f = DefaultLayout[unit](self)
    if layout and layout.spawn and type(layout.spawn) == 'function' then
      layout.spawn(self)
    end
    return f
  end
end


-- 
-- Boss frames handler.
-- 
local BossStyle = function(self, unit)
  self.mystyle="boss"
  return DefaultLayout['boss'](self)
end


------------------------------------------------------------------------------
--  Spawn Frames
------------------------------------------------------------------------------


oUF:RegisterStyle('klnFrames', UnitFrameStyle)
oUF:RegisterStyle('klnRaid', RaidStyle)
oUF:RegisterStyle('klnBoss', BossStyle)


oUF:Factory(function(self)
  -- Single Frames
  self:SetActiveStyle('klnFrames')

  self:Spawn('player')
  self:Spawn('target')
  self:Spawn('targettarget')
  self:Spawn('pet')
  self:Spawn('focus')
  self:Spawn('focustarget')
  
  -- Raid Frames
  if cfg.showRaid then
    local point = cfg.raidOrientationHorizontal and "LEFT" or "TOP"
    local soloraid = cfg.raidShowSolo and "custom show;" or "party,raid;"
    
    self:SetActiveStyle('klnRaid')

    local raid = {}
    for i = 1, 5 do
      local header = oUF:SpawnHeader(
        "klnGroup"..i,
        nil,
        soloraid,
        "showRaid",           true,
        "point",              point,
        "startingIndex",      1,
        "yOffset",            -5,
        "xoffset",            4,
        "columnSpacing",      7,
        "groupFilter",        tostring(i),
        "groupBy",            "GROUP",
        "groupingOrder",      "1,2,3,4,5",
        "sortMethod",         "NAME",
        "columnAnchorPoint",  "RIGHT",
        "maxColumns",         8,
        "unitsPerColumn",     5,
        "oUF-initialConfigFunction", [[
          self:SetHeight(32)
          self:SetWidth(77)
        ]]
      )
      
      if i == 1 then
        header:SetAttribute("showSolo", true)
        header:SetAttribute("showPlayer", true) 
        header:SetAttribute("showParty", true)
        header:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", cfg.raidX, cfg.raidY)
      else
        if cfg.raidOrientationHorizontal then
          header:SetPoint("BOTTOMLEFT", raid[i-1], "TOPLEFT", 0, 5)
        else
          header:SetPoint("TOPLEFT", raid[i-1], "TOPRIGHT", 4, 0)
        end
      end
      header:SetScale(cfg.raidScale)
      raid[i] = header
    end

    -- Apply any configured raid layouts
    if layouts.raid and type(layouts.raid) == 'function' then
      layouts.raid(lapi)
    end
  end

  -- Apply any last minute layout updates
  if layout and layout.postspawn and type(layout.postspawn == 'function') then
    layout.postspawn(lapi)
  end
end)


-- Boss Frames
oUF:SetActiveStyle('klnBoss')
local boss1 = oUF:Spawn("boss1", "oUF_Boss1")
boss1:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -5, 220)
local boss2 = oUF:Spawn("boss2", "oUF_Boss2")
boss2:SetPoint("BOTTOMRIGHT", oUF_Boss1, "TOPRIGHT", 0, 8)
local boss3 = oUF:Spawn("boss3", "oUF_Boss3")
boss3:SetPoint("BOTTOMRIGHT", oUF_Boss2, "TOPRIGHT", 0, 8)
local boss4 = oUF:Spawn("boss4", "oUF_Boss4")
boss4:SetPoint("BOTTOMRIGHT", oUF_Boss3, "TOPRIGHT", 0, 8)
local boss5 = oUF:Spawn("boss5", "oUF_Boss5")
boss5:SetPoint("BOTTOMRIGHT", oUF_Boss4, "TOPRIGHT", 0, 8)

-- Boss debug
--[[
local function debugFrame(frame)
  local f = CreateFrame("Frame", nil, UIParent)
  f:SetBackdropColor(0.2, 1, 0.2, 1)
  f:SetSize(frame:GetWidth(), frame:GetHeight())
  f:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0) 
  
  f.texture = f:CreateTexture()
  f.texture:SetAllPoints(f)
  f.texture:SetTexture(1,0,0, 0.5)

  return f
end
local debugBoss1 = debugFrame(oUF_Boss1)
local debugBoss2 = debugFrame(oUF_Boss2)
local debugBoss3 = debugFrame(oUF_Boss3)
local debugBoss4 = debugFrame(oUF_Boss4)
local debugBoss5 = debugFrame(oUF_Boss5)
--]]


lib.StyleMirrorBar()
oUF:DisableBlizzard('party')
