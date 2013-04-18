
local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_ElusiveBrewUptime was unable to locate oUF install')


local GetTime = GetTime
local class = select(2, UnitClass("player"))
local spec
local eb = 115308  -- The Elusive Brew buff, not the stacks
local spellName = GetSpellInfo(eb)


local function isTank(self, event, levels)
  spec = GetSpecialization()
  if spec ~= 1 then
    self.ElusiveBrewUptime:Hide()
  else
    self.ElusiveBrewUptime:Show()
  end
  return spec == 1
end


local onUpdate = function(self, elapsed)
  if self.remaining == nil then return end
  local remaining = self.remaining - elapsed
  if(remaining <= 0) then
    self:SetValue(0)
    return
  end

  self.remaining = remaining
  self:SetValue(remaining)
end

  
local function Update(self, event, unit)
  if unit ~= "player" or spec ~= 1 then return end
  
  local count, _, duration, expire, _, _, _, spellId = select(4, UnitBuff(unit, spellName, nil))
  if not spellId or spellId ~= eb then return end

  local ebu = self.ElusiveBrewUptime
  ebu.max = duration
  ebu.remaining = expire - GetTime()

  ebu:SetMinMaxValues(0, ebu.max)
  ebu:SetValue(ebu.remaining)
end


local function Enable(self, unit)
  local ebu = self.ElusiveBrewUptime
  if class == "MONK" and ebu then
    ebu.__owner = self

    -- Aura scanning, engage!
    self:RegisterEvent("UNIT_AURA", Update)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", isTank)
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", isTank)

    isTank(self)

    if ebu:IsObjectType'StatusBar' then
      ebu:SetMinMaxValues(0, 100)
      ebu:SetValue(0)
      if not ebu:GetStatusBarTexture() then
        ebu:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
      end
    end

    ebu:SetScript("OnUpdate", onUpdate)

    return true
  end
end


local function Disable(self)
  if(self.ElusiveBrewUptime) then
    self:UnregisterEvent('UNIT_AURA', Update)
    self:UnregisterEvent('PLAYER_TALENT_UPDATE', isTank)
    self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED', isTank)

    self.ElusiveBrewUptime:SetScript("OnUpdate", nil)
  end
end


oUF:AddElement('ElusiveBrewUptime', Update, Enable, Disable)
