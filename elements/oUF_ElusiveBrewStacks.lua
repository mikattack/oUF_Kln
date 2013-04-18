
local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_ElusiveBrewStacks was unable to locate oUF install')


local GetTime = GetTime
local elap, interval = 0, 0.75

local class = select(2, UnitClass("player"))
local spec
local eb_stacks = 128939 -- The Elusive Brew stacks, not the buff


local function isTank(self, event, levels)
  spec = GetSpecialization()
  if spec ~= 1 then
    self.ElusiveBrewStacks:Hide()
  else
    self.ElusiveBrewStacks:Show()
  end
  return spec == 1
end


--[[
  Because there are TWO "Elusive Brew" auras, we need to manually search through the
  buff list to find the correct one to query.
--]]
local function getStacksInfo(targetSpellID)
  for i=1, 40 do
    local name, _, _, count, _, _, _, _, _, _, spellID = UnitAura('player', i, filter)
    if not name then return nil end
    if spellID == targetSpellID then return count end
  end
  return nil
end


local function UpdateStacks(stacks, count)
  for i=1, #stacks do
    if i <= count then
      stacks[i]:Show()
    else
      stacks[i]:Hide()
    end
  end
end

  
local function Update(self, event, unit)
  if unit ~= "player" or spec ~= 1 then return end
  
  local count = getStacksInfo(eb_stacks)
  if not count then
    count = 0
  end
  UpdateStacks(self.ElusiveBrewStacks.stacks, count)
end


local function Enable(self, unit)
  local ebs = self.ElusiveBrewStacks
  if class == "MONK" and ebs then
    ebs.__owner = self

    -- Aura scanning, engage!
    self:RegisterEvent("UNIT_AURA", Update)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", isTank)
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", isTank)

    isTank(self)
    return true
  end
end


local function Disable(self)
  if(self.ElusiveBrewStacks) then
    self:UnregisterEvent('UNIT_AURA', Update)
    self:UnregisterEvent('PLAYER_TALENT_UPDATE', isTank)
    self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED', isTank)
  end
end


oUF:AddElement('ElusiveBrewStacks', Update, Enable, Disable)
