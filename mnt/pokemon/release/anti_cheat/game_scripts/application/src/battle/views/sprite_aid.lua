-- chunkname: @src.battle.views.sprite_aid

globals.BattleAidSprite = class("BattleAidSprite", BattleSprite)

function BattleAidSprite:onComeBack(posIdx, noQueue, skillCfg, aotoBack, protectorViews)
	skillCfg.flashBack = true

	BattleSprite.onComeBack(self, posIdx, noQueue, skillCfg, aotoBack, protectorViews)
end

function BattleAidSprite:onMoveToTarget(posIdx, skillCfg, noQueue, viewId, protectorTb)
	skillCfg.delayBeforeMove = 0
	skillCfg.timeScale = 0.5

	BattleSprite.onMoveToTarget(self, posIdx, skillCfg, noQueue, viewId, protectorTb)
end

function BattleAidSprite:getSeat()
	return -1
end

function BattleAidSprite:updHitPanel()
	return
end

function BattleAidSprite:getPosBySeat(seat)
	local x, y = battle.StandingPos[5].x, battle.StandingPos[5].y
	local offsetX = -2000

	if self.force == 2 then
		x = display.width - x
		offsetX = -offsetX
	end

	return x + self.posAdjust:get().x + offsetX, y + self.posAdjust:get().y
end
