------------------------------------------------------------------------------
--| MONK
------------------------------------------------------------------------------

local addon, ns = ...
local cfg = ns.cfg
local lib = ns.lib

local ResourceBar

local bar_power  = cfg.media.bar.power
local bar_common = cfg.media.bar.common


------------------------------------------------------------------------------
-- Hook Callbacks
------------------------------------------------------------------------------


local spawn = function(frame, ...)
  if frame.mystyle ~= 'player' then return end

  ResourceBar(frame)

  local stackWidth = math.floor(210 / 15)
  local specialBarWidth = (stackWidth * 15) + (14)

  -- Elusive Brew Stacks
  frame.ElusiveBrewStacks = CreateFrame("Frame", nil, frame)
  frame.ElusiveBrewStacks:SetSize(specialBarWidth, frame:GetHeight())
  frame.ElusiveBrewStacks:SetPoint("RIGHT", frame.Health, "LEFT", -20, 0)
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


------------------------------------------------------------------------------
-- Handoff
------------------------------------------------------------------------------


cfg.layouts.MONK = {
  ['spawn'] = spawn,
  ['postspawn'] = postspawn
}