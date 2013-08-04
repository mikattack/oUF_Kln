------------------------------------------------------------------------------
--| Monk Brew Uptime Statusbar
--| 
--| Note that only the tank and dps specs have brewing mechanics in which
--| consumed stacks apply a buff.  The heal spec's consumer is a channeled
--| spell which consumes them.
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------


local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_MonkBrewUptime was unable to locate oUF install')


-- Brew Types
local TANK_AURA = 115308  -- Elusive Brew   (consume)
local DPS_AURA  = 116740  -- Tigerseye Brew (consume)


local GetTime = GetTime
local class = select(2, UnitClass("player"))
local spec
local brewId
local brewName


local function isValidSpec()
  return spec == 1 or spec == 3
end


local function updateSpecInfo()
  spec = GetSpecialization()
  if spec == 1 then
    brewId   = TANK_AURA
    brewName = GetSpellInfo(TANK_AURA)
  elseif spec == 3 then
    brewId   = DPS_AURA
    brewName = GetSpellInfo(DPS_AURA)
  else
    brewId   = nil
    brewName = nil
  end
end


local function updateBarVisibility(self, ...)
  if isValidSpec() then
    self.MonkBrewUptime:Show()
  else
    self.MonkBrewUptime:Hide()  
  end
end


local function updateBar(self, event, levels)
  updateSpecInfo()
  updateBarVisibility(self)
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
  if unit ~= "player" or not isValidSpec() or brewName == nil then return end
  
  local count, _, duration, expire, _, _, _, spellId = select(4, UnitBuff(unit, brewName, nil))
  if not spellId or spellId ~= brewId then return end

  local ebu = self.MonkBrewUptime
  ebu.max = duration
  ebu.remaining = expire - GetTime()

  ebu:SetMinMaxValues(0, ebu.max)
  ebu:SetValue(ebu.remaining)
end


local function Enable(self, unit)
  local ebu = self.MonkBrewUptime
  if class == "MONK" and ebu then
    ebu.__owner = self

    -- Aura scanning, engage!
    self:RegisterEvent("UNIT_AURA", Update)
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", updateBar)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", updateBar)
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", updateBar)

    updateBar(self)

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
  if(self.MonkBrewUptime) then
    self:UnregisterEvent('UNIT_AURA', Update)
    self:UnregisterEvent('PLAYER_SPECIALIZATION', updateBar)
    self:UnregisterEvent('PLAYER_TALENT_UPDATE', updateBar)
    self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED', updateBar)

    self.ElusiveBrewUptime:SetScript("OnUpdate", nil)
  end
end


oUF:AddElement('MonkBrewUptime', Update, Enable, Disable)
