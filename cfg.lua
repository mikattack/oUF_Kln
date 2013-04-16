------------------------------------------------------------------------------
--| oUF_Kln
--| Authors: Drakull, Myno, Kellen
--| 
--| Copyright (c) 2010-2013 Kellen <addons@mikitik.com>. All rights reserved.
--| See the accompanying README and LICENSE files for more information.
------------------------------------------------------------------------------


local addon, ns = ...
local cfg = CreateFrame("Frame")


------------------------------------------------------------------------------
--  Configuration
------------------------------------------------------------------------------


-- Raid & party frames
cfg.showRaid = true 							-- show raid frames
cfg.raidShowSolo = true 					-- show raid frames even when solo
cfg.showIncHeals = true 					-- Show incoming heals in player and raid frames
cfg.showTooltips = true 					-- Show Tooltips on raid frames
cfg.enableRightClickMenu = false 	-- Enables the right click menu for raid frames
cfg.showRoleIcons = false 				-- Show Role Icons on raid frames
cfg.showIndicators = true 				-- Show Class Indicators on raid frames (HoT's, buffs etc.)
cfg.showThreatIndicator = true 		-- Show Threat Indicator on raid frames

cfg.raidOrientationHorizontal = true
cfg.raidScale = 1
cfg.raidX = -5
cfg.raidY = 30


-- Raid indicators
cfg.IndicatorList = {
	["NUMBERS"] = {
		["DEATHKNIGHT"] = "[DK:DeathBarrier]",
		["DRUID"]				= "[Druid:Lifebloom][Druid:Rejuv][Druid:Regrowth]",
		--["HUNTER"]		= missdirect,
		--["MAGE"]			= ,
		["MONK"]				= "[Monk:EnvelopingMist][Monk:RenewingMist]",
		--["PALADIN"]		= ,
		["PRIEST"]			= "[Priest:Renew][Priest:PowerWordShield]",
		--["ROGUE"]			= tricks,
		["SHAMAN"]			= "[Shaman:Riptide][Shaman:EarthShield]",
		--["WARLOCK"]		= ,
		["WARRIOR"]			= "[Warrior:Vigilance]",
	},
	["SQUARE"] = {
		--["DEATHKNIGHT"] 	= ,
		--["DRUID"]			= ,
		--["HUNTER"]		= ,
		--["MAGE"]			= ,
		--["MONK"]			= ,
		["PALADIN"]			= "[Paladin:Forbearance][Paladin:Beacon]",
		--["PRIEST"]		= ,
		--["ROGUE"]			= ,
		--["SHAMAN"]		= ,
		--["WARLOCK"]		= ,
		--["WARRIOR"]		= ,
	},
}


-- Raid tracked auras
cfg.DebuffWatchList = {
	debuffs = {
		--## USAGE: ["DEBUFF_NAME"] = PRIORITY, ##--
		--## PRIORITY -> 10: high, 9: medium, 8: low, dispellable debuffs have standard priority of 5.
		--["61295"] = 10, -- Riptide for testing purposes only

		--[[## CATACLYSM ##]]--
		--[[ T13 ]]--
		--Dragon Soul
			--Warlord Zon'ozz
				["103434"] = 9, -- Disrupting Shadows
			--Yor'sahj the Unsleeping
				["103628"] = 9, -- Deep Corruption
			--Hagara the Stormbinder
				["109325"] = 9, -- Frostflake
				["104451"] = 9, -- Ice Tomb
			--Ultraxion
				["105926"] = 9, -- Fading Light
			--Spine of Deathwing
				["105479"] = 8, -- Searing Plasma
				["105490"] = 9, -- Fiery Grip
				["106199"] = 10, -- Blood Corruption: Death
				["106200"] = 10, -- Blood Corruption: Earth
			--Madness of Deathwing
				["108649"] = 9, -- Corrupting Parasite
				["106400"] = 10, -- Impale
				["106444"] = 9, -- Impale (Stacks)
				["106794"] = 9, -- Shrapnel (should be the right one)
				--["106791"] = 9, -- Shrapnel

		--[[## MISTS OF PANDARIA ##]]--
		--World Bosses
			--Sha of Anger
				["119622"] = 8, -- Growing Anger
				["119626"] = 9, -- Aggressive Behavior
		--[[ T14 ]]--
		--Heart of Fear
			--Imperial Vizier Zor'lok
				["122706"] = 9, -- Noise Cancelling
				["122740"] = 10, -- Convert
			--Blade Lord Ta'yak
				["123474"] = 8, -- Overwhelming Assault
				["123180"] = 9, -- Wind Step
			--Garalon
				["122835"] = 8, ["129815"] = 8, -- Pheromones
				["123081"] = 10, -- Pungency
			--Wind Lord Mel'jarak
				["121885"] = 10, ["129078"] = 10, ["121881"] = 10, -- Amber Prison
				["122055"] = 8, -- Residue
				["122064"] = 9, -- Corrosive Resin
			--Amber-Shaper Un'sok
				["122784"] = 9, ["122370"] = 9, -- Reshape Life
				["121949"] = 10, -- Parasitic Growth
				--["Amber Globule"] = 9,
			--Grand Empress Shek'zeer
				["123707"] = 8, -- Eyes of the Empress
				["124097"] = 8, -- Sticky Resin
				["123788"] = 9, -- Cry of Terror
				["124862"] = 10, ["124863"] = 10, -- Visions of Demise
		--Mogu'shan Vaults
			--The Stone Guard
				["116281"] = 8, -- Cobalt Mine
				["130395"] = 10, -- Jasper Chains
				["116301"] = 9, -- Living Jade
				["116304"] = 9, -- Living Jasper
				["116199"] = 9, -- Living Cobalt
				["116322"] = 9, -- Living Amethyst
			--Feng the Accursed
				["116942"] = 8, -- Flaming Spear
				["116784"] = 9, -- Wildfire Spark
				["116577"] = 10, ["116576"] = 10, ["116574"] = 10, ["116417"] = 10, -- Arcane Resonance
			--Gara'jal the Spiritbinder
				["117723"] = 8, -- Frail Soul
				["122151"] = 9, -- Voodoo Doll
				["122181"] = 10, -- Conduit to the Spirit Realm
			--The Spirit Kings
				["117708"] = 8, -- Maddening Shout
				["118047"] = 8, ["118048"] = 8, -- Pillage
				["118141"] = 9, -- Pinning Arrow
				["118163"] = 8, -- Robbed Blind
				["117514"] = 9, ["117529"] = 9, ["117506"] = 9,-- Undying Shadows
			--Elegon
				--["117878"] = 8, -- Overcharged
				["117949"] = 9, -- Closed Circuit
				["132222"] = 10, -- Destabilizing Energies
				["132226"] = 10, -- Destabilized
			--Will of the Emperor
				["116829"] = 10, -- Focused Energy
		--Terrace of Endless Spring
			--Protectors of the Endless
				["117436"] = 10, ["131931"] = 10, ["111850"] = 10, -- Lightning Prison
			--Tsulong
				["122777"] = 8, -- Nightmares
				["123011"] = 10, ["123018"] = 10, -- Terrorize
			--Lei Shi
				["123705"] = 10, -- Scary Fog
				["123121"] = 8, -- Spray
			--Sha of Fear
				["120629"] = 8, -- Huddle in Terror
		--[[ T15 ]]--
		--Throne of Thunder
			--Jin'rokh the Breaker
				--["138732"] = 9, ["138733"] = 9, ["139997"] = 9, -- Ionization (dispellable)
				["137422"] = 4, -- Focused Lightning
			--Horridon
				["136708"] = 6, -- Stone Gaze (so it's > Sunbeam Debuff)
			--Council of Elders
				["137641"] = 9, -- Soul Fragment (Ball)
				["137650"] = 7, -- Shadowed Soul
				["136990"] = 8, -- Frostbite
				["136992"] = 8, -- Biting Cold
			--Tortos
				["137552"] = 8, ["137633"] = 8, --Crystal Shell
				["140701"] = 9, -- Crystal Shell: Max Capacity
			--Megaera
				["139857"] = 9, -- Torrent of Ice
				["139822"] = 9, -- Cinders
			--Ji-Kun
				["134256"] = 9, -- Slimed
			--Durumu the Forgotten
				["139204"] = 9, -- Infrared Tracking
				["139202"] = 9, -- Blue Ray Tracking
				["133768"] = 10, -- Arterial Cut
				["133597"] = 10, -- Dark Parasite
				["133798"] = 10, -- Life Drain
			--Primordius
				["136228"] = 10, -- Volatile Pathogen
				["136050"] = 9, -- Malformed Blood
				["137000"] = 9, -- Black Blood
			--Dark Animus
				["138486"] = 9, -- Crimson Wake Target Debuff
				["138609"] = 9, -- Matter Swap
				["136962"] = 8, -- Anima Ring
			--Iron Qon
				["134647"] = 8, -- Scorched
				["137668"] = 9, -- Burning Cinders
				["137669"] = 9, -- Arcing Lightning
				["135145"] = 9, -- Freeze
				["137664"] = 8, -- Frozen Blood
			--Twin Consorts
				["137341"] = 4, -- Beast of Nightmares
				["137360"] = 4, -- Corrupted Healing
				["137408"] = 7, -- Fan of Flames
				["137440"] = 8, -- Icy Shadows
			--Lei Shen
				["135695"] = 8, -- Static Shock
				["136295"] = 8, -- Overcharge
				["139011"] = 9, -- Helm of Command
				["136478"] = 7, -- Fusion Slash
			--Ra-den
	},
}


-- Media Defaults Redux
cfg.media = {}
cfg.media.bar = {
  ["common"] = "Interface\\AddOns\\oUF_Drk\\media\\bar\\Statusbar",
  ["power"]  = "Interface\\AddOns\\oUF_Drk\\media\\bar\\Flat",
	["raid"]   = "Interface\\AddOns\\oUF_Drk\\media\\bar\\Minimalist",
}
cfg.media.background = {
	["common"] 		= "Interface\\AddOns\\oUF_Drk\\media\\backdrop\\common",
	["highlight"] = "Interface\\AddOns\\oUF_Drk\\media\\backdrop\\raid",
}
cfg.media.border = {
	["common"] 	= "Interface\\AddOns\\oUF_Drk\\media\\border\\square",
	["aura"] 		= "Interface\\AddOns\\oUF_Drk\\media\\backdrop\\icon",
}
cfg.media.font = {
	["common"] 	= "Interface\\AddOns\\oUF_Drk\\media\\fonts\\BigNoodleTitling.ttf",
	["small"] 	= "Interface\\AddOns\\oUF_Drk\\media\\fonts\\Semplice.ttf",
	["raid"] 		= "Interface\\AddOns\\oUF_Drk\\media\\fonts\\Vibroceb.ttf",
	["square"] 	= "Interface\\AddOns\\oUF_Drk\\media\\fonts\\Squares.ttf",
}


------------------------------------------------------------------------------
--  Handoff
------------------------------------------------------------------------------


-- Do not change this
cfg.spec = nil
cfg.updateSpec = function()
	cfg.spec = GetSpecialization()
end

ns.cfg = cfg
