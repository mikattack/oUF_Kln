------------------------------------------------------------------------------
--| MONK
------------------------------------------------------------------------------

local addon, ns = ...
local cfg = ns.Kln.cfg
local lib = ns.Kln.lib

local ResourceBar

local bar_power  = cfg.media.bar.power
local bar_common = cfg.media.bar.common


------------------------------------------------------------------------------
-- Hook Callbacks
------------------------------------------------------------------------------


local spawn = function(frame, ...)
  if frame.mystyle ~= 'player' then return end

  ResourceBar(frame)

  frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 60)
end


------------------------------------------------------------------------------
-- Internal Functions
------------------------------------------------------------------------------


local resourceX, resourceY = 0, 24


-- Soulshard/Burning Embers
ResourceBar = function(self)
  local wsb = CreateFrame("Frame", "WarlockSpecBars", self)
  wsb:SetPoint('CENTER', UIParent, "BOTTOM", resourceX, resourceY)
  wsb:SetWidth(self.Health:GetWidth()/2+50)
  wsb:SetHeight(11)

  local background = lib.CreateBackground(wsb)
  background:SetFrameStrata('MEDIUM')
  
  for i = 1, 4 do
    wsb[i] = CreateFrame("StatusBar", "WarlockSpecBars"..i, wsb)
    wsb[i]:SetHeight(9)
    wsb[i]:SetStatusBarTexture(bar_common)
    wsb[i]:SetStatusBarColor(.86,.22,1)
    wsb[i].bg = wsb[i]:CreateTexture(nil,"BORDER")
    wsb[i].bg:SetTexture(bar_common)
    wsb[i].bg:SetVertexColor(0,0,0)
    wsb[i].bg:SetPoint("TOPLEFT",wsb[i],"TOPLEFT",0,0)
    wsb[i].bg:SetPoint("BOTTOMRIGHT",wsb[i],"BOTTOMRIGHT",0,0)
    wsb[i].bg.multiplier = .3
    
    local h = CreateFrame("Frame",nil,wsb[i])
    h:SetPoint("TOPLEFT",-3,3)
    h:SetPoint("BOTTOMRIGHT",3,-3)
    
    if i == 1 then
      wsb[i]:SetPoint("LEFT", wsb, "LEFT", 1, 0)
    else
      wsb[i]:SetPoint("LEFT", wsb[i-1], "RIGHT", 2, 0)
    end
  end
  
  self.WarlockSpecBars = wsb
end


------------------------------------------------------------------------------
-- Handoff
------------------------------------------------------------------------------


cfg.layouts.WARLOCK = {
  ['spawn'] = spawn,
  ['postspawn'] = postspawn
}