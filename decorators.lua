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

local Decorators = {}


--[[--------------------------------------------------------------------------
  Frame Decorators

  Add common things to a given frame.  Behavior may be different depending
  on the unit type of the frame.
----------------------------------------------------------------------------]]


-- Media
local bar_common    = cfg.media.bar.common
local bar_power     = cfg.media.bar.power
local bg_highlight  = cfg.media.background.highlight
local font_small    = cfg.media.font.small


function Decorators.PowerBar(frame)
  local f, bg = lib.CreateBar(frame, frame:GetWidth(), 4, bar_power)
  frame.Power = f
  frame.Power.bg = bg
  frame.Power:SetPoint("BOTTOM", frame, "BOTTOM", 0, 0)
  frame.Power.frequentUpdates = true
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
    qicon:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 16, 16)
    qicon:SetSize(32, 32)
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


------------------------------------------------------------------------------
--  Hook Functions
------------------------------------------------------------------------------


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
  
  button.time = lib.CreateString(button, font_small, 8, "OUTLINE")
  button.time:SetPoint("BOTTOMLEFT", button, -2, -2)
  button.time:SetJustifyH('CENTER')
  button.time:SetVertexColor(1,1,1)
  
  button.count = lib.CreateString(button, font_small, 8, "OUTLINE")
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


------------------------------------------------------------------------------
-- Expose API
------------------------------------------------------------------------------


lib.Decorators = Decorators

