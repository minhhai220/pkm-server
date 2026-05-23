-- chunkname: @src.battle.app_views.battle.module.rayeffect

local RayEffect = class("RayEffect", battleModule.CBase)

function RayEffect:ctor(parent)
	battleModule.CBase.ctor(self, parent)
end

function RayEffect:onAddRayEffect(casterKey, holderKey, cfg, buffId)
	local deep = cfg.deep
	local aniName = cfg.aniName
	local scaleX = cfg.scaleX or 1
	local effectRes = cfg.effectRes
	local offsetPos = cfg.offsetPos
	local startDelayTime = (cfg.startDelayTime or 0) / 1000
	local time = (cfg.time or 1000) / 1000
	local endDelayTime = (cfg.endDelayTime or 0) / 1000
	local casterSpr = self:call("getSceneObj", casterKey)
	local holderSpr = self:call("getSceneObj", holderKey)

	if not effectRes or not casterSpr or not holderSpr then
		return
	end

	local faceTo = casterSpr.force == 2 and -1 or 1

	offsetPos = offsetPos and cc.p(faceTo * offsetPos.x, offsetPos.y) or cc.p(faceTo * 0, 0)

	local effectPos = cc.pAdd(casterSpr.unitCfg.everyPos.hitPos, offsetPos)
	local hitPosYGap = casterSpr.unitCfg.everyPos.hitPos.y - holderSpr.unitCfg.everyPos.hitPos.y
	local newLine = newCSpriteWithOption(effectRes)

	newLine:addTo(casterSpr, deep)
	newLine:setPosition(effectPos)
	newLine:play(aniName)
	newLine:setVisible(true)

	newLine.boxWidth = newLine:getBoundingBox().width

	local x1, y1 = casterSpr:getSelfPos()
	local x2, y2 = holderSpr:getSelfPos()
	local dx, dy = x2 - x1, y2 - y1 - hitPosYGap
	local dis = math.sqrt(dx * dx + dy * dy)
	local _scaleX = scaleX * (dis / newLine.boxWidth)
	local r = math.atan2(dy, dx) * 180 / math.pi

	newLine:scaleX(0):setRotation(-r)
	transition.executeSequence(newLine):delay(startDelayTime):func(function()
		newLine:play(aniName)
	end):scaleTo(time, _scaleX, 1):done()
	performWithDelay(newLine, function()
		removeCSprite(newLine)
	end, startDelayTime + time + endDelayTime)
end

return RayEffect
