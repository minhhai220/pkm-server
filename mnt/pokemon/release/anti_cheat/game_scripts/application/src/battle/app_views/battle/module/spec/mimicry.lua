-- chunkname: @src.battle.app_views.battle.module.spec.mimicry

local _format = string.format
local BattleWorldBossView = require("battle.app_views.battle.module.spec.world_boss")
local BattleMimicryView = class("BattleMimicryView", BattleWorldBossView)

function BattleMimicryView:onInitBossLife(infoArgs)
	local name = infoArgs.name
	local headIconRes = infoArgs.headIconRes
	local hpMax = infoArgs.hpMax

	if name then
		self.bossLifePanel:get("name"):text(name)
	end

	if headIconRes then
		self.bossLifePanel:get("headIcon"):texture(headIconRes)
	end

	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")

	text.addEffect(self.bossLifePanel:get("hp"), {
		outline = {
			color = cc.c4b(254, 253, 236, 255)
		}
	})
	text.addEffect(self.bossLifePanel:get("hpMax"), {
		outline = {
			color = cc.c4b(209, 128, 0, 255)
		}
	})
	self.award:hide()
	bar1:show()
	bar2:show()
	self:onRefreshBossHp(hpMax, hpMax)
end

function BattleMimicryView:onRefreshBossHp(hp, hpMax)
	local showTime = 0.8
	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")
	local txt1 = self.bossLifePanel:get("hp")
	local txt2 = self.bossLifePanel:get("hpMax")

	bar1:stopAllActions()
	txt1:setString(math.floor(hp))
	txt2:setString("/" .. hpMax)

	local percent = math.floor(hp) / hpMax * 100
	local sequence = transition.executeSequence(bar1):progressTo(showTime, percent)

	sequence:done()
end

return BattleMimicryView
