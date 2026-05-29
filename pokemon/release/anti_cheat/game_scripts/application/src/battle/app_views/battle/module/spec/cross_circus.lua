-- chunkname: @src.battle.app_views.battle.module.spec.cross_circus

local BattleCrossCircusView = class("BattleCrossCircusView", battleModule.CBase)

function BattleCrossCircusView:ctor(parent)
	battleModule.CBase.ctor(self, parent)
	self:init()
end

function BattleCrossCircusView:init()
	local t = self.parent.data

	self.leftHeadPnl = self.parent.UIWidgetLeft:get("infoPVP")
	self.rightHeadPnl = self.parent.UIWidgetRight:get("infoPVP")

	self.leftHeadPnl:get("level"):setFontSize(40):anchorPoint(0, 0.5):x(self.leftHeadPnl:get("roleName"):x()):setString(getServerArea(t.role_key[1], true))
	self.leftHeadPnl:get("levelLv"):visible(false)
	self.rightHeadPnl:get("level"):setFontSize(40):anchorPoint(1, 0.5):x(self.rightHeadPnl:get("roleName"):x()):setString(getServerArea(t.defence_role_key[1], true))
	self.rightHeadPnl:get("levelLv"):visible(false)
	self:call("refreshInfoPvP")
end

return BattleCrossCircusView
