
local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_Stagger was unable to locate oUF install')


local GetTime = GetTime
local class = select(2, UnitClass("player"))
local spec


local spellIds = {
  staggerLight    = 124275,
  staggerModerate = 124274,
  staggerHeavy    = 124273,
}
local spellNames = {
  staggerLight    = GetSpellInfo(124275),
  staggerModerate = GetSpellInfo(124274),
  staggerHeavy    = GetSpellInfo(124273),
}


local function isTank(self, event, levels)
  spec = GetSpecialization()
  if spec ~= 1 then
    self.Stagger:Hide()
  else
    self.Stagger:Show()
  end
  return spec == 1
end


local function SetStagger(self, level, expiration, amount)
  local stagger = self.Stagger
  local mu = 0.3
  local r,g,b

  if level == 0 then
    r,g,b = 0.00, 1.00,  0.59
  elseif level == 1 then
    r,g,b = 0.00, 1.00,  0.59
  elseif level == 2 then
    r,g,b = 1.00,  0.96,  0.41
  else
    r,g,b = 0.77,  0.12,  0.23
  end

  local maxhealth = UnitHealthMax("player") * 0.06
  stagger:SetMinMaxValues(0, maxhealth)
  stagger:SetValue(amount)
  stagger:SetStatusBarColor(r, g, b)
  if stagger.bg then
    stagger.bg:SetVertexColor(r * mu, g * mu, b * mu)
  end
end

  
local function Update(self, event, unit)
  if unit ~= "player" or spec ~= 1 then return end

  -- Light
  local expiration,_,_,_,_,_,_,_, amount = select(7, UnitDebuff("player", spellNames['staggerLight']))
  if amount then
    SetStagger(self, 1, expiration, amount)
    return
  end

  -- Medium
  local expiration,_,_,_,_,_,_,_, amount = select(7, UnitDebuff("player", spellNames['staggerModerate']))
  if amount then
    SetStagger(self, 2, expiration, amount)
    return
  end

  -- DANGER WILL ROBINSON!
  local expiration,_,_,_,_,_,_,_, amount = select(7, UnitDebuff("player", spellNames['staggerHeavy']))
  if amount then
    SetStagger(self, 3, expiration, amount)
    return
  end

  SetStagger(self, 0, 0, 0)
end


local function Enable(self, unit)
  local stagger = self.Stagger
  if class == "MONK" and stagger then
    stagger.__owner = self

    -- Aura scanning, engage!
    self:RegisterEvent("UNIT_AURA", Update)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", isTank)
    self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", isTank)

    isTank(self)

    if stagger:IsObjectType'StatusBar' then
      stagger:SetMinMaxValues(0, 100)
      stagger:SetValue(0)
      if not stagger:GetStatusBarTexture() then
        stagger:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
      end
    end

    SetStagger(self, 0, 0, 0)

    return true
  end
end


local function Disable(self)
  if(self.Stagger) then
    self:UnregisterEvent('UNIT_AURA', Update)
    self:UnregisterEvent('PLAYER_TALENT_UPDATE', isTank)
    self:UnregisterEvent('ACTIVE_TALENT_GROUP_CHANGED', isTank)
  end
end


oUF:AddElement('Stagger', Update, Enable, Disable)
