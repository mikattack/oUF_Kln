------------------------------------------------------------------------------
--| MONK
------------------------------------------------------------------------------

local addon, ns = ...
local cfg = ns.Kln.cfg
local lib = ns.Kln.lib
local GetTime = GetTime

local tags = oUF.Tags

local ResourceBar

local bar_power  = cfg.media.bar.power
local bar_common = cfg.media.bar.common
local font       = cfg.media.font.common


------------------------------------------------------------------------------
-- Hook Callbacks
------------------------------------------------------------------------------


local spawn = function(frame, ...)
  if frame.mystyle ~= 'player' then return end

  ResourceBar(frame)

  local stackWidth = math.floor(230 / 15)
  local specialBarWidth = (stackWidth * 15) + (14)

  -- Elusive Brew Stacks
  frame.ElusiveBrewStacks = CreateFrame("Frame", nil, frame)
  frame.ElusiveBrewStacks:SetSize(specialBarWidth, frame:GetHeight())
  frame.ElusiveBrewStacks:SetPoint("RIGHT", frame.Health, "LEFT", -16, 0)
  lib.CreateBackground(frame.ElusiveBrewStacks)

  frame.ElusiveBrewStacks.stacks = {}
  local front, back
  local r,g,b
  for i=1, 15 do
    back = frame.ElusiveBrewStacks:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(bar_power)
    back:SetSize(stackWidth, frame:GetHeight())

    front = frame.ElusiveBrewStacks:CreateTexture(nil, "BORDER")
    front:SetTexture(bar_power)
    front:SetPoint("TOPLEFT", back, "TOPLEFT", 1, -1)
    front:SetPoint("BOTTOMRIGHT", back, "BOTTOMRIGHT", -1, 1)

    if i == 1 then
      back:SetPoint("LEFT", frame.ElusiveBrewStacks, "LEFT", 0, 0)
    else
      back:SetPoint("LEFT", frame.ElusiveBrewStacks.stacks[i - 1], "RIGHT", 2, 0)
    end

    if i < 6 then
      r,g,b = 1.00,  0.96,  0.41
    elseif i == 6 then
      r,g,b = 1.00,  0.49,  0.04
    else
      r,g,b = 0.67,  0.83,  0.45
    end
    front:SetVertexColor(r,g,b)
    back:SetVertexColor(r*0.3, g*0.3, b*0.3)

    front:Hide()
    frame.ElusiveBrewStacks.stacks[i] = front
  end
  

  -- Elusive Brew Uptime
  f, bg = lib.CreateBar(frame, specialBarWidth, 7, bar_power)
  f:SetStatusBarColor(1.00,  0.96,  0.41)
  bg:SetVertexColor(1.00 * 0.3,  0.96 * 0.3,  0.41 * 0.3)
  frame.ElusiveBrewUptime = f
  frame.ElusiveBrewUptime.bg = bg
  frame.ElusiveBrewUptime:SetPoint("BOTTOM", frame.ElusiveBrewStacks, "TOP", 0, 8)
  lib.CreateBackground(frame.ElusiveBrewUptime)

  -- Stagger
  f, bg = lib.CreateBar(frame, specialBarWidth, 7, bar_power)
  frame.Stagger = f
  frame.Stagger.bg = bg
  frame.Stagger:SetPoint("TOP", frame.ElusiveBrewStacks, "BOTTOM", 0, -8)
  lib.CreateBackground(frame.Stagger)

  -- Shuffle Uptime
  --local shuffle = CreateShuffle(frame)
  --shuffle:SetPoint('BOTTOMLEFT', frame.ElusiveBrewUptime, 'TOPLEFT', -3, -2)
end


------------------------------------------------------------------------------
-- Internal Functions
------------------------------------------------------------------------------


local resourceX, resourceY = 0, 24


-- Harmony (Chi)
ResourceBar = function(self)
  local mhb = CreateFrame("Frame", "MonkHarmonyBar", self)
  mhb:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  mhb:SetWidth(self.Health:GetWidth() * .75)
  mhb:SetHeight(11)

  local background = lib.CreateBackground(mhb)
  background:SetFrameStrata('MEDIUM')

  -- Placeholder slots for the "orbs"
  local maxPower = UnitPowerMax("player",SPELL_POWER_CHI)
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

  -- Update background slots on talent swap
  local SetResourceSlotWidth = function(self, ...)
    local hasAscension = select(5, GetTalentInfo(8))  -- Ascension (Tier:3, Slot:2, Talent:8)
    if hasAscension then
      self[5]:Show()
      for i = 1,5 do
        self[i]:SetWidth(self:GetWidth() / 5 - 2)
      end
    elseif maxPower == 5 then
      self[5]:Hide()
      for i = 1,4 do
        self[i]:SetWidth(self:GetWidth() / 4 - 2)
      end
    end
  end
  mhb.slots:RegisterEvent("PLAYER_TALENT_UPDATE", SetResourceSlotWidth)
  mhb.slots:SetScript("OnEvent", function(self, event, ...)
    if not event == "PLAYER_TALENT_UPDATE" then return end
    SetResourceSlotWidth(mhb.slots)
  end)
  SetResourceSlotWidth(mhb.slots)

  
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


-- TAG: Shuffle
local SHUFFLE = GetSpellInfo(115307)
tags.Events["Monk:Shuffle"] = 'UNIT_AURA'
tags.Methods["Monk:Shuffle"] = function(u, r)
  local _, _, _, _, _, _, expirationTime, source = UnitAura('player', SHUFFLE)
  if source then
    return format("%.0f", expirationTime - GetTime())
  else
    return '-'
  end
end


-- TAG: Shuffle
local VENGENCE = GetSpellInfo(115307)
tags.Events["Tank:AttackPower"] = 'UNIT_AURA'
tags.Methods["Tank:AttackPower"] = function(u, r)
  local _, _, _, _, _, _, expirationTime, source = UnitAura('player', VENGENCE)
  if source then
    return format("%.0f", expirationTime - GetTime())
  else
    return '-'
  end
end


-- Shuffle Display
CreateShuffle = function (frame)
  local label = lib.CreateString(frame, font, 16, "THINOUTLINE")
  local value = lib.CreateString(frame, font, 28, "THINOUTLINE")

  label:SetText('Shuffle')
  label:SetPoint('BOTTOMLEFT', value, 'BOTTOMRIGHT', -1, 3)

  value:SetText('-')
  frame:Tag(value, "[Monk:Shuffle]")

  return value
end


------------------------------------------------------------------------------
-- Handoff
------------------------------------------------------------------------------


cfg.layouts.MONK = {
  ['spawn'] = spawn,
  ['postspawn'] = postspawn
}