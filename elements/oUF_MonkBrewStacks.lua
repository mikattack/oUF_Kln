------------------------------------------------------------------------------
--| Monk Brew Stacks Visualization
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------


local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_MonkBrewStacks was unable to locate oUF install')


local GetTime = GetTime
local elap, interval = 0, 0.75

-- Brew Types
local TANK_AURA   = 128939  -- Elusive Brew (stacks)
local HEALER_AURA = 115867  -- Mana Tea
local DPS_AURA    = 125195  -- Tigerseye Brew (stacks)

-- Default/fallback configuration
local breakpoints = {
  ["tank"] = 6,
  ["heal"] = 4,
  ["dps"]  = 10,
}

local colors = {
  ["under"] = {1.00, 0.96, 0.41},
  ["break"] = {1.00, 0.49, 0.04},
  ["over"]  = {0.67, 0.83, 0.45},
}

local generator = function (f)
  local texture = [[Interface\TargetingFrame\UI-StatusBar]]
  local back, front
  local defaultWidth = 10

  if f.texture then
    texture = f.texture
  end

  back = f:CreateTexture(nil, "BACKGROUND")
  back:SetTexture(texture)
  back:SetSize(defaultWidth, f:GetHeight())

  front = f:CreateTexture(nil, "BORDER")
  front:SetTexture(texture)
  front:SetPoint("TOPLEFT", back, "TOPLEFT", 1, -1)
  front:SetPoint("BOTTOMRIGHT", back, "BOTTOMRIGHT", -1, 1)

  return {
    ["front"] = front,
    ["back"] = back
  }
end

-- Internal state
local brewId
local brewName
local class = select(2, UnitClass("player"))
local spec
local stacks = {}


local function isValidSpec()
  return spec >= 1 and spec <= 3
end


local function getSpec()
  if spec == 1 then
    return "tank"
  elseif spec == 2 then
    return "heal"
  else
    return "dps"
  end
end


local function updateSpecInfo()
  spec = GetSpecialization()
  if spec == 1 then
    brewId   = TANK_AURA
    brewName = GetSpellInfo(TANK_AURA)
  elseif spec == 2 then
    brewId   = HEAL_AURA
    brewName = GetSpellInfo(HEAL_AURA)
  elseif spec == 3 then
    brewId   = DPS_AURA
    brewName = GetSpellInfo(DPS_AURA)
  else
    brewId   = nil
    brewName = nil
  end
end


local function updateStacksVisibility(self, ...)
  if isValidSpec() then
    self.MonkBrewStacks:Show()
  else
    self.MonkBrewStacks:Hide()  
  end
end


local function updateStacksConfiguration(self, ...)
  if not isValidSpec() then return end

  local width, height, stackWidth
  local specName = getSpec()
  local breakpoint = breakpoints[specName]
  local ticks = specName == "tank" and 15 or 20
  local r, g, b

  width = self.MonkBrewStacks:GetWidth()
  height = self.MonkBrewStacks:GetHeight()
  stackWidth = (width - (ticks - 1)) / ticks

  for i=1, #stacks do
    -- Resize
    stacks[i]["back"]:SetWidth(stackWidth)
    stacks[i]["back"]:SetHeight(height)

    -- Colorize
    if i < breakpoint then
      r,g,b = unpack(colors["under"])
    elseif i == breakpoint then
      r,g,b = unpack(colors["break"])
    else
      r,g,b = unpack(colors["over"])
    end
    stacks[i]["front"]:SetVertexColor(r,g,b)
    stacks[i]["back"]:SetVertexColor(r*0.3, g*0.3, b*0.3)

    -- Show hide whole tick
    if i <= ticks then
      stacks[i]["front"]:Hide()
      stacks[i]["back"]:Show()
    else
      stacks[i]["front"]:Hide()
      stacks[i]["back"]:Hide()
    end
  end
end


local function updateDisplay(self, ...)
  updateSpecInfo()
  updateStacksConfiguration(self)
  updateStacksVisibility(self)
end


--[[
  Because there are TWO "Brew" auras (one for stacks and one for the buff),
  we need to manually search through the aura list to find the correct one
  to query.
--]]
local function getStacksInfo(targetSpellID)
  for i=1, 40 do
    local name, _, _, count, _, _, _, _, _, _, spellID = UnitAura('player', i, filter)
    if not name then return nil end
    if spellID == targetSpellID then return count end
  end
  return nil
end


local function UpdateStacks(count)
  local len = spec == 1 and 15 or 20
  for i=1, len do
    if i <= count then
      stacks[i]["front"]:Show()
    else
      stacks[i]["front"]:Hide()
    end
  end
end

  
local function Update(self, event, unit)
  if unit ~= "player" or not isValidSpec() then return end
  
  local count = getStacksInfo(brewId)
  if not count then
    count = 0
  end
  UpdateStacks(count)
end


local function Enable(self, unit)
  local ebs = self.MonkBrewStacks
  if class == "MONK" and ebs then
    ebs.__owner = self

    -- If stack tick frames are uninitialized, generate them
    if #stacks == 0 then
      if ebs.breakpoints then breakpoints = ebs.breakpoints end
      if ebs.colors then colors = ebs.colors end
      if ebs.generator then generator = ebs.generator end

      for i=1, 20 do
        stacks[i] = generator(ebs)
        if i == 1 then
          stacks[i]["back"]:SetPoint("LEFT", ebs, "LEFT", 0, 0)
        else
          stacks[i]["back"]:SetPoint("LEFT", stacks[i - 1]["back"], "RIGHT", 1, 0)
        end
      end
    end

    -- Aura scanning, engage!
    self:RegisterEvent("UNIT_AURA", Update)
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", updateDisplay)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", updateDisplay)
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", updateDisplay)

    updateDisplay(self)
    return true
  end
end


local function Disable(self)
  if(self.MonkBrewStacks) then
    self:UnregisterEvent('UNIT_AURA', Update)
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", updateDisplay)
    self:UnregisterEvent('PLAYER_TALENT_UPDATE', updateDisplay)
    self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED', updateDisplay)
  end
end


oUF:AddElement('MonkBrewStacks', Update, Enable, Disable)
