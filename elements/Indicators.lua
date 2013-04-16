local _,ns = ...
local cfg = ns.cfg
local oUF = ns.oUF or oUF
assert(oUF, "oUF_Drk was unable to locate oUF install.")

local _, playerClass = UnitClass("player")

local Enable = function(self)
	if self.DrkIndicators then
		self.NumbersIndicator = self.Health:CreateFontString(nil,"OVERLAY")
		self.NumbersIndicator:ClearAllPoints()
		self.NumbersIndicator:SetPoint("BOTTOMRIGHT",self.Health,"BOTTOMRIGHT",4,-4)
		self.NumbersIndicator:SetFont(cfg.media.font.common,13,"THINOUTLINE")
		self.NumbersIndicator.frequentUpdates = .25
		self:Tag(self.NumbersIndicator,cfg.IndicatorList["NUMBERS"][playerClass])
	
		self.SquareIndicator = self.Health:CreateFontString(nil,"OVERLAY")
		self.SquareIndicator:ClearAllPoints()
		self.SquareIndicator:SetPoint("BOTTOMRIGHT",self.NumbersIndicator,"BOTTOMLEFT",3,1)
		self.SquareIndicator:SetFont(cfg.media.font.square,10,"THINOUTLINE")
		self.SquareIndicator.frequentUpdates = .25
		self:Tag(self.SquareIndicator,cfg.IndicatorList["SQUARE"][playerClass])
	end
	if self.showThreatIndicator then
		self.ThreatIndicator = self.Health:CreateFontString(nil,"OVERLAY")
		self.ThreatIndicator:ClearAllPoints()
		self.ThreatIndicator:SetPoint("LEFT",self.Health,"LEFT",1,0)
		self.ThreatIndicator:SetFont(cfg.media.font.square,6,"THINOUTLINE")
		self.ThreatIndicator.frequentUpdates = .25
		self:Tag(self.ThreatIndicator,"[kln:threat]")
	end
end

oUF:AddElement('DrkIndicators',nil,Enable,nil)