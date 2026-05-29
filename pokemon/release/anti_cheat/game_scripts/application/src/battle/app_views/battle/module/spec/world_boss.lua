-- chunkname: @src.battle.app_views.battle.module.spec.world_boss

local _format = string.format
local BattleWorldBossView = class("BattleWorldBossView", battleModule.CBase)

BattleWorldBossView.RESOURCE_FILENAME = "battle_world_boss.json"
BattleWorldBossView.RESOURCE_BINDING = {
	["bossLifePanel.award"] = "award",
	bossLifePanel = "bossLifePanel"
}

function BattleWorldBossView:ctor(parent)
	battleModule.CBase.ctor(self, parent)

	self.root = cache.createWidget(self.RESOURCE_FILENAME)

	bindUI(self, self.root, self.RESOURCE_BINDING)
	self.root:addTo(parent.layer, 999):show()
	self:init()
end

function BattleWorldBossView:init()
	self.sceneID = self.parent.sceneID

	self.bossLifePanel:show()

	self.awardLevel = -1

	self:updateFeedbackPos()
end

function BattleWorldBossView:updateFeedbackPos()
	local x, y = self.bossLifePanel:getPosition()
	local px = self.bossLifePanel:get("round"):getPosition()

	self.parent.UIWidgetFeedback:setPosition(x + px, y)
	self:call("setWeatherUIPos", cc.p(x + px, y), 1.2)
end

function BattleWorldBossView:onNewBattleRound(args)
	local csvConfig = csv.scene_conf[self.parent.sceneID]
	local curRound = math.max(math.min(args.curRound, csvConfig.roundLimit), 0)

	self.bossLifePanel:get("round.round"):setString(_format(gLanguageCsv.theRound, curRound, csvConfig.roundLimit))
end

function BattleWorldBossView:onInitBossLife(infoArgs)
	local name = infoArgs.name
	local headIconRes = infoArgs.headIconRes
	local firstAward = infoArgs.damageAward[1]

	self.damageAward = infoArgs.damageAward

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

	self.fullWidth = bar2:width()

	bar1:show()
	bar2:show()

	self.awardEffect = widget.addAnimation(self.award, "worldboss/bossbaoxiang.skel", "effect", 100)

	self.awardEffect:anchorPoint(cc.p(0.5, 0.5)):xy(cc.p(self.award:width() / 2, self.award:height() / 2))
	self:onRefreshBossHp(0, 0, firstAward.damage, 0)
	self:onRefreshBossAward(firstAward.boxRes, 0)
end

function BattleWorldBossView:onRefreshBossHp(hp, damage, limit, level)
	if level < self.awardLevel then
		return
	end

	local showTime = 0.8
	local per = hp * 100
	local width = hp * self.fullWidth
	local bar1 = self.bossLifePanel:get("bar1")
	local bar2 = self.bossLifePanel:get("bar2")
	local txt1 = self.bossLifePanel:get("hp")
	local txt2 = self.bossLifePanel:get("hpMax")

	bar1:stopAllActions()

	if level > self.awardLevel then
		self.awardLevel = level

		local nextLevel = self.awardLevel + 1

		txt2:setString("/" .. limit)
		bar1:setPercent(0)

		if self.damageAward[nextLevel] then
			self.award:loadTexture(self.damageAward[nextLevel].boxRes)
			self.awardEffect:stopAllActions()
			self.awardEffect:play("effect")
		end
	end

	txt1:setString(math.floor(damage))

	if math.abs(bar2:width() - width) < 0.01 and math.abs(bar1:getPercent() - per) < 0.01 then
		return
	end

	bar2:width(width)

	local sequence = transition.executeSequence(bar1):progressTo(showTime, per)

	sequence:done()
end

function BattleWorldBossView:onRefreshBossAward(awardRes, level)
	if not level or not awardRes or level and level == 0 then
		return
	end

	self.award:loadTexture(awardRes)
end

function BattleWorldBossView:onShowSpec(isShow)
	self.root:setVisible(isShow)
end

function BattleWorldBossView:onClose()
	ViewBase.onClose(self)
end

function BattleWorldBossView:getBossBuffPanel()
	return self.bossLifePanel
end

return BattleWorldBossView
