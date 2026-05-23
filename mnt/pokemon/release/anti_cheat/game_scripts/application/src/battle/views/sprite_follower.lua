-- chunkname: @src.battle.views.sprite_follower

globals.BattleFollowerSprite = class("BattleFollowerSprite", BattleSprite)

function BattleFollowerSprite:initLifeBar()
	BattleSprite.initLifeBar(self)

	if self.model.extraObjectCsvCfg.hideLifebar == battle.hpShowState.hide then
		self.lifebar:onSetLifebarVisible(false, "lifeBarVisible")
	elseif self.model.extraObjectCsvCfg.hideLifebar == battle.hpShowState.always then
		self.lifebar:onSetLifebarVisible(true, "lifeBarVisible")
	end

	if self.model.extraObjectCsvCfg.hideLifebar ~= battle.hpShowState.normal then
		self.lifebar:setVisibleEnable(false)
	end
end

function BattleFollowerSprite:updHitPanel()
	return
end

function BattleFollowerSprite:isInBuffPanel()
	return false
end

function BattleFollowerSprite:showHero(isShow, args)
	self.lifebar:setVisible(isShow and not args.hideLife)
	self:setVisible(isShow)
end

function BattleFollowerSprite:getPosBySeat()
	local effectSeatType = self.args.effectSeatType
	local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2
	local posAdjustX, posAdjustY = self.posAdjust:get().x, self.posAdjust:get().y

	if effectSeatType == 1 then
		return BattleSprite.getPosBySeat(self, self:getSeat())
	elseif effectSeatType == 2 then
		cx = self.force == 1 and cx or display.width - cx

		return cx + posAdjustX, battle.StandingPos[2].y + posAdjustY
	elseif effectSeatType == 3 then
		cx = self.force == 1 and display.width - cx or cx

		return cx + posAdjustX, battle.StandingPos[2].y + posAdjustY
	elseif effectSeatType == 4 then
		return battle.StandingPos[13].x + posAdjustX, battle.StandingPos[2].y + posAdjustY
	end
end

function BattleFollowerSprite:getBeAttackPosAdjust()
	local offsetPos = self.model.extraObjectCsvCfg.beAttackOffsetPos or cc.p(0, 0)

	return cc.p(self.forceFaceTo * offsetPos.x, offsetPos.y)
end

function BattleFollowerSprite:resetPosZ(effectY)
	if not self.model.extraObjectCsvCfg.posZ then
		local _, y = self:getSelfPos()
		local frontRow = display.height - (effectY or y)
		local backRow = frontRow - 1
		local rowNum = 2 - math.floor((self:getSeat() + 2) / 3) % 2

		self.posZ:set((rowNum == 1 and 2 * frontRow or backRow) + (self.model.extraObjectCsvCfg.lerpZ or 0), "reset")

		self.battleMovePosZ = 2 * frontRow

		return
	end

	local posZ = self.model.extraObjectCsvCfg.posZ

	self.posZ:set(posZ, "reset")

	self.battleMovePosZ = posZ
end

function BattleFollowerSprite:syncSeatWithMarkObj()
	local id = self.model:syncSeatGetMarkObjId()

	if not id then
		return
	end

	local benchmarkObjView = self.battleView:onViewProxyCall("getSceneObjById", id)

	if not benchmarkObjView then
		return
	end

	local seat = benchmarkObjView:getSeat()

	if seat == self:getSeat() then
		return
	end

	self:setSeat(seat)
	self:moveToPosIdx(seat)
end
