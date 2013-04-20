local addon, ns = ...
local cfg = ns.cfg

local tags = oUF.Tags
local GetTime = GetTime

local format = string.format
local len = string.len
local sub = string.sub


-- Short Value
local SVal = function(val)
	if val then
		if (val >= 1e6) then
			return ("%.1fm"):format(val / 1e6)
		elseif (val >= 1e3) then
			return ("%.0fk"):format(val / 1e3)
		else
			return ("%d"):format(val)
		end
	end
end


local function hex(r, g, b)
	if r then
		if (type(r) == 'table') then
			if(r.r) then r, g, b = r.r, r.g, r.b else r, g, b = unpack(r) end
		end
		return ('|cff%02x%02x%02x'):format(r * 255, g * 255, b * 255)
	end
end


-- Auto-shortening Name
tags.Events["kln:name"] = 'UNIT_NAME_UPDATE'
tags.Methods["kln:name"] = function(u, r)
	local n = UnitName(r or u)
	if (len(n) >= 14) then
		n = format('%s...', sub(n, 1, 14))
	end
	return n
end


-- TargetOfTarget Name (it's very short)
tags.Events["kln:shortname"] = 'UNIT_NAME_UPDATE'
tags.Methods["kln:shortname"] = function(u, r)
	local n = UnitName(r or u)
	if (len(n) >= 6) then
		n = format('%s...', sub(n, 1, 6))
	end
	return n
end


-- Percent Health
tags.Events["kln:percent_hp"] = 'UNIT_HEALTH UNIT_MAXHEALTH'
tags.Methods["kln:percent_hp"] = function(u)
	local m = UnitHealthMax(u)
	if(m == 0) then
		return 0
	else
		return format("%d%%", math.floor((UnitHealth(u) / m * 100 + .05) * 10) / 10)
	end
end


-- Raw HP ("current/max")
tags.Events["kln:raw_hp"] = 'UNIT_HEALTH UNIT_MAXHEALTH'
tags.Methods["kln:raw_hp"] = function(u)
	if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
		return _TAGS["kln:DDG"](u)
	else
		local min, max = UnitHealth(u), UnitHealthMax(u)
		if min == max then 
			return SVal(max)
		else
			return format("|cFFFFAAAA%s|r / %s", SVal(min), SVal(max))
		end
	end
end


-- Full Health Details ("current/max | percent")
tags.Events["kln:full_hp"] = 'UNIT_HEALTH UNIT_MAXHEALTH'
tags.Methods["kln:full_hp"] = function(u)
	if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
		return _TAGS["kln:DDG"](u)
	else
		local per = _TAGS["kln:percent_hp"](u) or 0
		local min, max = UnitHealth(u), UnitHealthMax(u)
		if u == "player" or u == "target" then
			if min ~= max then 
				return format("|cFFFFAAAA%s|r / %s | %s", SVal(min), SVal(max), per)
			else
				return format("%s | %s", SVal(max), per)
			end
		else
			return per
		end
	end
end


-- Raid Health (deficit)
tags.Events["kln:raid_hp"] = 'UNIT_HEALTH UNIT_CONNECTION PLAYER_FLAGS_CHANGED'
tags.Methods["kln:raid_hp"] = function(u) 
  if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
    return _TAGS["kln:DDG"](u)
  else
	
	local missinghp = SVal(_TAGS["missinghp"](u)) or ""
	if missinghp ~= "" then
		return format("- %s", missinghp)
	else
		return ""
	end
  end
end


-- Boss HP (percent)
tags.Events["kln:boss"] = 'UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH UNIT_TARGETABLE_CHANGED'
tags.Methods["kln:boss"] = function(u)
  local m = UnitHealthMax(u)
  if(m == 0) then
    return 0
  else
    return format("%s%%", math.floor((UnitHealth(u) / m * 100 + .05) * 10) / 10)
  end
end


-- Color String (based on unit, class, status, or reaction)
tags.Events["kln:color"] = 'UNIT_REACTION UNIT_HEALTH UNIT_HAPPINESS'
tags.Methods["kln:color"] = function(u)
	local _, class = UnitClass(u)
	local reaction = UnitReaction(u, "player")
	
	if UnitIsDead(u) or UnitIsGhost(u) or not UnitIsConnected(u) then
		return "|cffA0A0A0"
	elseif (UnitIsTapped(u) and not UnitIsTappedByPlayer(u)) then
		return hex(oUF.colors.tapped)
	elseif (u == "pet") then
		return hex(oUF.colors.class[class])
	elseif (UnitIsPlayer(u)) then
		return hex(oUF.colors.class[class])
	elseif reaction then
		return hex(oUF.colors.reaction[reaction])
	else
		return hex(1, 1, 1)
	end
end


-- AFK/DnD
tags.Events["kln:afkdnd"] = 'PLAYER_FLAGS_CHANGED'
tags.Methods["kln:afkdnd"] = function(unit) 
	return UnitIsAFK(unit) and "|cffCFCFCF <afk>|r" or UnitIsDND(unit) and "|cffCFCFCF <dnd>|r" or ""
end

tags.Events["kln:raidafkdnd"] = 'PLAYER_FLAGS_CHANGED'
tags.Methods["kln:raidafkdnd"] = function(unit) 
	return UnitIsAFK(unit) and "|cffCFCFCF AFK|r" or UnitIsDND(unit) and "|cffCFCFCF DND|r" or ""
end


-- Status (dead, ghost, offline)
tags.Events["kln:DDG"] = 'UNIT_HEALTH'
tags.Methods["kln:DDG"] = function(u)
	if UnitIsDead(u) then
		return "|cffCFCFCF Dead|r"
	elseif UnitIsGhost(u) then
		return "|cffCFCFCF Ghost|r"
	elseif not UnitIsConnected(u) then
		return "|cffCFCFCF Off|r"
	end
end


-- Power
tags.Events["kln:power"] = 'UNIT_MAXPOWER UNIT_POWER'
tags.Methods["kln:power"]  = function(u) 
	local min, max = UnitPower(u), UnitPowerMax(u)
	if min ~= max then 
		return format("%s / %s", SVal(min), SVal(max))
	else
		return SVal(max)
	end
end


-- Unit Level
tags.Events["kln:level"] = 'UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED'
tags.Methods["kln:level"] = function(unit)
	
	local c = UnitClassification(unit)
	local l = UnitLevel(unit)
	local d = GetQuestDifficultyColor(l)
	
	local str = l
		
	if l <= 0 then l = "??" end
	
	if c == "worldboss" then
		str = format("|cff%02x%02x%02xBoss|r",250,20,0)
	elseif c == "eliterare" then
		str = format("|cff%02x%02x%02x%s|r|cff0080FFR|r+",d.r*255,d.g*255,d.b*255,l)
	elseif c == "elite" then
		str = format("|cff%02x%02x%02x%s|r+",d.r*255,d.g*255,d.b*255,l)
	elseif c == "rare" then
		str = format("|cff%02x%02x%02x%s|r|cff0080FFR|r",d.r*255,d.g*255,d.b*255,l)
	else
		if not UnitIsConnected(unit) then
			str = "??"
		else
			if UnitIsPlayer(unit) then
				str = format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
			elseif UnitPlayerControlled(unit) then
				str = format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
			else
				str = format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
			end
		end		
	end
	
	return str
end


-- Threat
tags.Events["kln:threat"] = 'UNIT_THREAT_LIST_UPDATE UNIT_THREAT_SITUATION_UPDATE'
tags.Methods["kln:threat"] = function(unit)
	local status = UnitThreatSituation(unit)
	if status and status > 1 then
		return "|cffff1100M|r"
	end
end


--
-- Class Aura Indicators
--


local EARTH_SHIELD = GetSpellInfo(974)
tags.Events["Shaman:EarthShield"] = 'UNIT_AURA'
tags.Methods["Shaman:EarthShield"] = function(unit)
	local esCount, _, _, _, source = select(4, UnitAura(unit, EARTH_SHIELD))
	if esCount then
		if source == "player" then
      if esCount > 3 then 
        return format("|cff33cc00%.0f|r ", esCount)
      else
        return format("|cffffcc00%.0f|r ", esCount)
      end
		else
			return format("|cffaa2200%.0f|r ", esCount)
		end
	end
end


local RIPTIDE = GetSpellInfo(61295)
tags.Events["Shaman:Riptide"] = 'UNIT_AURA'
tags.Methods["Shaman:Riptide"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, RIPTIDE)
  if source and source == "player" then
    return format("|cff0099cc%.0f|r ", expirationTime - GetTime())
  end
end


local POWER_WORD_SHIELD = GetSpellInfo(17)
local WEAKENED_SOUL = GetSpellInfo(6788)
tags.Events["Priest:PowerWordShield"] = 'UNIT_AURA'
tags.Methods["Priest:PowerWordShield"] = function(unit)
	local _, _, _, _, _, _, expirationTime = UnitAura(unit, POWER_WORD_SHIELD)
  if expirationTime then
    return format("|cffffcc00%.0f|r ", expirationTime - GetTime())
	else
		local _, _, _, _, _, _, expirationTime = UnitDebuff(unit, WEAKENED_SOUL)
    if expirationTime then
      return format("|cffaa0000%.0f|r ", expirationTime - GetTime())
    end
	end
end


local RENEW = GetSpellInfo(139)
tags.Events["Priest:Renew"] = 'UNIT_AURA'
tags.Methods["Priest:Renew"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, RENEW)
  if source and source == "player" then
    return format("|cff33cc00%.0f|r ", expirationTime - GetTime())
  end
end


local LIFEBLOOM = GetSpellInfo(33763)
tags.Events["Druid:Lifebloom"] = 'UNIT_AURA'
tags.Methods["Druid:Lifebloom"] = function(unit)
	local _, _, _, stacks, _, _, expirationTime, source = UnitAura(unit, LIFEBLOOM)
  if source and source == "player" then
    if stacks == 1 then
      return format("|cffcc0000%.0f|r ", expirationTime - GetTime())
    elseif stacks == 2 then
      return format("|cffff6314%.0f|r ", expirationTime - GetTime())
    elseif stacks == 3 then
      return format("|cffffcc00%.0f|r ", expirationTime - GetTime())
		end
	end
end


local REJUVENATION = GetSpellInfo(774)
tags.Events["Druid:Rejuv"] = 'UNIT_AURA'
tags.Methods["Druid:Rejuv"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, REJUVENATION)
  if source and source == "player" then
    return format("|cffd814ff%.0f|r ", expirationTime - GetTime())
  end
end


local REGROWTH = GetSpellInfo(8936)
tags.Events["Druid:Regrowth"] = 'UNIT_AURA'
tags.Methods["Druid:Regrowth"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, REGROWTH)
  if source == "player" then
    return format("|cff33cc00%.0f|r ", expirationTime - GetTime())
  end
end


local BEACON = GetSpellInfo(53563)
tags.Events["Paladin:Beacon"] = 'UNIT_AURA'
tags.Methods["Paladin:Beacon"] = function(unit)
	local _, _, _, _, _, _, _, source = UnitAura(unit, BEACON)
  if source then
		if source == "player" then
			return "|cffffff33M|r "
		else
			return "|cffffcc00M|r "
		end
	end
end


local FORBEARANCE = GetSpellInfo(25771)
tags.Events["Paladin:Forbearance"] = 'UNIT_AURA'
tags.Methods["Paladin:Forbearance"] = function(unit)
	if UnitDebuff(unit, FORBEARANCE) then
    return "|cffaa0000M|r "
  end
end


local ENVELOPING_MIST = GetSpellInfo(124682)
tags.Events["Monk:EnvelopingMist"] = 'UNIT_AURA'
tags.Methods["Monk:EnvelopingMist"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, ENVELOPING_MIST)
  if source and source == "player" then
    return format("|cff33cc00%.0f|r ", expirationTime - GetTime())
  end
end


local RENEWING_MIST = GetSpellInfo(119611)
tags.Events["Monk:RenewingMist"] = 'UNIT_AURA'
tags.Methods["Monk:RenewingMist"] = function(unit)
	local _, _, _, _, _, _, expirationTime, source = UnitAura(unit, RENEWING_MIST)
  if source and source == "player" then
    return format("|cff0099cc%.0f|r ", expirationTime - GetTime())
  end
end


local VIGILANCE = GetSpellInfo(114030)
tags.Events["Warrior:Vigilance"] = 'UNIT_AURA'
tags.Methods["Warrior:Vigilance"] = function(unit)
	local _, _, _, _, _, _, expirationTime = UnitAura(unit, VIGILANCE)
  if expirationTime then
    return format("|cff33cc00%.0f|r ", expirationTime - GetTime())
  end
end


local SAFEGUARD = GetSpellInfo(114029)
tags.Events["Warrior:Safeguard"] = 'UNIT_AURA'
tags.Methods["Warrior:Safeguard"] = function(unit)
	local _, _, _, _, _, _, expirationTime, _ = UnitAura(unit, SAFEGUARD)
  if expirationTime then
    return format("|cff33cc00%.0f|r ", expirationTime - GetTime())
  end
end


local DEATH_BARRIER = GetSpellInfo(115635)
tags.Events["DK:DeathBarrier"] = 'UNIT_AURA'
tags.Methods["DK:DeathBarrier"] = function(unit)
	local _, _, _, _, _, _, expirationTime, _ = UnitAura(unit, DEATH_BARRIER)
  if expirationTime then
    return format("|cffffcc00%.0f|r ", expirationTime - GetTime())
  end
end
