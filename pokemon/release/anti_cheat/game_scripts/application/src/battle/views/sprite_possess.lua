-- chunkname: @src.battle.views.sprite_possess

globals.BattlePossessSprite = class("BattlePossessSprite", BattleSprite)

function BattlePossessSprite:loadSprite(res, zOrder, args)
	if self.args.res then
		self.sprite = newCSpriteWithOption(self.args.res)

		self.sprite:setPosition(cc.p(0, 0))
		self.sprite:setSpriteEventHandler(handler(self, self.onSpriteEvent))
		self:add(self.sprite, zOrder)
		self:setScale(1)
	end
end

function BattlePossessSprite:init()
	BattleSprite.init(self)

	self.holderView = gRootViewProxy:call("getSceneObj", self.args.targetKey)

	self.holderView:addFollowSpr(self)

	self.casterView = gRootViewProxy:call("getSceneObj", self.args.casterKey)

	self.casterView:addReplaceView(self)

	self.isDirty = false
	self._holderPos = cc.p(self.holderView:getPosition())
	self._holderVis = nil
	self._holderZOrder = self.holderView:getLocalZOrder()

	self:setActionState(battle.SpriteActionTable.standby)
end

function BattlePossessSprite:getHolderVisible()
	return self.holderView:isVisible() and self.holderView:getSpriteVisible()
end

function BattlePossessSprite:onFixedUpdate(delta)
	if self.isDirty then
		return
	end

	if self._holderVis ~= self:getHolderVisible() then
		self._holderVis = self:getHolderVisible()
	end

	self:setVisible(self._holderVis)

	if self._holderPos.x ~= self.holderView:getPositionX() or self._holderPos.y == self.holderView:getPositionY() then
		self._holderPos.x, self._holderPos.y = self.holderView:getPosition()

		local posAdjust = self:getPosAdjust()
		local x, y = self._holderPos.x + posAdjust.x, self._holderPos.y + posAdjust.y

		self:setPosition(cc.p(x, y))
		self:setCurPos(cc.p(self._holderPos.x, self._holderPos.y))
	end

	if self:getScaleX() ~= self.holderView:getScaleX() or self:getScaleY() ~= self.holderView:getScaleY() then
		local scaleX, scaleY = self.holderView:getScaleX(), self.holderView:getScaleY()

		self:setScaleX(scaleX)
		self:setScaleY(scaleY)
	end

	if self._holderZOrder ~= self.holderView:getLocalZOrder() then
		self._holderZOrder = self.holderView:getLocalZOrder()

		self:setLocalZOrder(self._holderZOrder + 1)
	end
end

function BattlePossessSprite:onAddToScene()
	BattleSprite.onAddToScene(self)
	self:resetPosZ(self._holderPos.y - 1)
	self:setLocalZOrder(self.posZ:get())
end

function BattlePossessSprite:popEffectInfo(eventID)
	return self.casterView:popEffectInfo(eventID)
end

function BattlePossessSprite:getProcessArgs(processID)
	return self.casterView:getProcessArgs(processID)
end

function BattlePossessSprite:popIgnoreEffect(processID, eventID)
	return self.casterView:popIgnoreEffect(processID, eventID)
end

function BattlePossessSprite:getSeat()
	return self.args.targetSeat
end

function BattlePossessSprite:initLifeBar()
	return
end

function BattlePossessSprite:initNatureQuan()
	return
end

function BattlePossessSprite:initGroundRing()
	return
end

function BattlePossessSprite:updHitPanel()
	return
end

function BattlePossessSprite:setDirty(isOver)
	self.isDirty = isOver
end

function BattlePossessSprite:showHero(isShow, args)
	self:setVisible(isShow)
end

function BattlePossessSprite:checkSceneTag(args)
	if args then
		return args.isPossessAttack
	end

	return false
end

function BattlePossessSprite:sceneDelObj(layer)
	self.holderView:removeFollowSpr(self)
	self.casterView:removeReplaceView(self)
	self:removeSelf()
end

function BattlePossessSprite:isInBuffPanel()
	return false
end

function BattlePossessSprite:objToHideEff(isAttacting, playView)
	local dirtyTag, visible = isAttacting, not isAttacting
	local args = playView.skillSceneTag:back()
	local isBigSkill = args and args.isBigSkill

	if self.casterView == playView then
		playView:objToHideEff(isAttacting)

		if isBigSkill then
			self.casterView:setVisible(visible)
		end

		visible = isAttacting

		self:setDirty(dirtyTag)
		self:setVisible(visible)
	elseif isBigSkill then
		self:setDirty(dirtyTag)
		self:setVisible(visible)
	end
end
