local addon, ns = ...
local cfg = ns.cfg

local tags = oUF.Tags
local format = string.format


-- Short Value
local SVal = function(val)
	if val then
		if (val >= 1e6) then
			return ("%.1fm"):format(val / 1e6)
		elseif (val >= 1e3) then
			return ("%.1fk"):format(val / 1e3)
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


-- Percent Health
tags.Events["kln:percent_hp"] = 'UNIT_HEALTH UNIT_MAXHEALTH'
tags.Methods["kln:percent_hp"] = function(u)
	local m = UnitHealthMax(u)
	if(m == 0) then
		return 0
	else
		return math.floor((UnitHealth(u)/m  *100 + .05) * 10 / 10) .. '%'
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
			return "|cFFFFAAAA"..SVal(min).."|r/"..SVal(max)
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
			if min~=max then 
				return "|cFFFFAAAA"..SVal(min).."|r/"..SVal(max).." | "..per
			else
				return SVal(max).." | "..per
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
		return "-"..missinghp
	else
		return ""
	end
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
	if min~=max then 
		return SVal(min).."/"..SVal(max)
	else
		return SVal(max)
	end
end


-- Player Power
tags.Events["my:power"] = 'UNIT_MAXPOWER UNIT_POWER'
tags.Methods["my:power"] = function(unit)
	local curpp, maxpp = UnitPower(unit), UnitPowerMax(unit);
	local playerClass, englishClass = UnitClass(unit);

	if(maxpp == 0) then
		return ""
	else
		if (englishClass == "WARRIOR") then
			return curpp
		elseif (englishClass == "DEATHKNIGHT" or englishClass == "ROGUE" or englishClass == "HUNTER") then
			return curpp .. ' /' .. maxpp
		else
			return SVal(curpp) .. " /" .. SVal(maxpp) .. " | " .. math.floor(curpp/maxpp*100+0.5) .. "%"
		end
	end
end;


-- Unit Level
tags.Events["kln:level"] = 'UNIT_LEVEL PLAYER_LEVEL_UP UNIT_CLASSIFICATION_CHANGED'
tags.Methods["kln:level"] = function(unit)
	
	local c = UnitClassification(unit)
	local l = UnitLevel(unit)
	local d = GetQuestDifficultyColor(l)
	
	local str = l
		
	if l <= 0 then l = "??" end
	
	if c == "worldboss" then
		str = string.format("|cff%02x%02x%02xBoss|r",250,20,0)
	elseif c == "eliterare" then
		str = string.format("|cff%02x%02x%02x%s|r|cff0080FFR|r+",d.r*255,d.g*255,d.b*255,l)
	elseif c == "elite" then
		str = string.format("|cff%02x%02x%02x%s|r+",d.r*255,d.g*255,d.b*255,l)
	elseif c == "rare" then
		str = string.format("|cff%02x%02x%02x%s|r|cff0080FFR|r",d.r*255,d.g*255,d.b*255,l)
	else
		if not UnitIsConnected(unit) then
			str = "??"
		else
			if UnitIsPlayer(unit) then
				str = string.format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
			elseif UnitPlayerControlled(unit) then
				str = string.format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
			else
				str = string.format("|cff%02x%02x%02x%s",d.r*255,d.g*255,d.b*255,l)
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


local GetTime = GetTime

local numberize = function(val)
	if val >= 1e6 then
		return ("%.1fm"):format(val/1e6)
	elseif val >= 1e3 then
		return ("%.1fk"):format(val/1e3)
	else
		return ("%d"):format(val)
	end
end

local getTime = function(expirationTime)
    local expire = (expirationTime-GetTime())
	local timeLeft = numberize(expire)
    return timeLeft
end


tags.Events["Shaman:EarthShield"] = 'UNIT_AURA'
tags.Methods["Shaman:EarthShield"] = function(unit)
	local esCount = select(4, UnitAura(unit,GetSpellInfo(974)))
	if esCount then
		if esCount > 3 then 
			return "|cff33cc00"..esCount.."|r "
		else
			return "|cffffcc00"..esCount.."|r "
		end
	end
end

tags.Events["Shaman:Riptide"] = 'UNIT_AURA'
tags.Methods["Shaman:Riptide"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(61295))
	if source == "player" then return "|cff0099cc"..getTime(timeLeft).."|r " end
end

tags.Events["Priest:PowerWordShield"] = 'UNIT_AURA'
tags.Methods["Priest:PowerWordShield"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(17))
	if name then
		return "|cffffcc00"..getTime(timeLeft).."|r"
	else
		local name,_,_,_,_,_,timeLeft,source = UnitDebuff(unit,GetSpellInfo(6788))
		if name then return "|cffaa0000"..getTime(timeLeft).."|r " end
	end
end

tags.Events["Priest:Renew"] = 'UNIT_AURA'
tags.Methods["Priest:Renew"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(139))
	if source == "player" then return "|cff33cc00"..getTime(timeLeft).."|r " end
end

tags.Events["Druid:Lifebloom"] = 'UNIT_AURA'
tags.Methods["Druid:Lifebloom"] = function(unit)
	local name,_,_,c,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(33763))
	if source == "player" then
		if c == 1 then
			return "|cffcc0000"..getTime(timeLeft).."|r "
		elseif c == 2 then
			return "|cffff6314"..getTime(timeLeft).."|r "
		elseif c == 3 then
			return "|cffffcc00"..getTime(timeLeft).."|r "
		end
	end
end

tags.Events["Druid:Rejuv"] = 'UNIT_AURA'
tags.Methods["Druid:Rejuv"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(774))
	if source == "player" then return "|cffd814ff"..getTime(timeLeft).."|r " end
end

tags.Events["Druid:Regrowth"] = 'UNIT_AURA'
tags.Methods["Druid:Regrowth"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(8936))
	if source == "player" then return "|cff33cc00"..getTime(timeLeft).."|r " end
end

tags.Events["Paladin:Beacon"] = 'UNIT_AURA'
tags.Methods["Paladin:Beacon"] = function(unit)
	local name,_,_,_,_,_,_,source = UnitAura(unit,GetSpellInfo(53563))
	if name then
		if source == "player" then
			return "|cffffff33M|r "
		else
			return "|cffffcc00M|r "
		end
	end
end

tags.Events["Paladin:Forbearance"] = 'UNIT_AURA'
tags.Methods["Paladin:Forbearance"] = function(unit)
	if UnitDebuff(unit,GetSpellInfo(25771)) then return "|cffaa0000M|r " end
end

tags.Events["Monk:EnvelopingMist"] = 'UNIT_AURA'
tags.Methods["Monk:EnvelopingMist"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(124682))
	if source == "player" then return "|cff33cc00"..getTime(timeLeft).."|r " end
end

tags.Events["Monk:RenewingMist"] = 'UNIT_AURA'
tags.Methods["Monk:RenewingMist"] = function(unit)
	local name,_,_,_,_,_,timeLeft,source = UnitAura(unit,GetSpellInfo(119611))
	if source == "player" then return "|cff0099cc"..getTime(timeLeft).."|r " end
end

tags.Events["Warrior:Vigilance"] = 'UNIT_AURA'
tags.Methods["Warrior:Vigilance"] = function(unit)
	local name,_,_,_,_,_,timeLeft,_ = UnitAura(unit,GetSpellInfo(114030))
	if name then return "|cff33cc00"..getTime(timeLeft).."|r " end
end

tags.Events["Warrior:Safeguard"] = 'UNIT_AURA'
tags.Methods["Warrior:Safeguard"] = function(unit)
	local name,_,_,_,_,_,timeLeft,_ = UnitAura(unit,GetSpellInfo(114029))
	if name then return "|cff33cc00"..getTime(timeLeft).."|r " end
end

tags.Events["DK:DeathBarrier"] = 'UNIT_AURA'
tags.Methods["DK:DeathBarrier"] = function(unit)
	local name,_,_,_,_,_,timeLeft,_ = UnitAura(unit,GetSpellInfo(115635))
	if name then return "|cffffcc00"..getTime(timeLeft).."|r " end
end
