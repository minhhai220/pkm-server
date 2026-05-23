-- chunkname: @src.battle.views.sprite_normal

function BattleSprite:moveToPosIdx(posIdx)
	local x, y = self:getPosBySeat(posIdx)

	if x and y then
		self:setPosition(cc.p(x, y))
		self:setCurPos(cc.p(x, y))
	end
end

function BattleSprite:onDoShiftPos(posIdx, cfg)
	local x, y = self:getPosBySeat(posIdx)

	self:onAddEventEffect("moveTo", {
		changeFaceTo = false,
		speed = 1500,
		a = 1000,
		x = x,
		y = y
	}, false)

	self.seat = self.model.seat

	self:setCurPos(cc.p(x, y))
	self:updHitPanel()
	self:onAddToScene()

	for _ = 1, 1 do
		if not cfg then
			break
		end

		local resPath = cfg.onceEffectResPath

		if not resPath or resPath == "" then
			break
		end

		local sprite = newCSpriteWithOption(resPath)
		local offsetPos = cfg.onceEffectOffsetPos
		local aniName = cfg.onceEffectAniName or "effect"

		self:add(sprite, 12)
		sprite:play(aniName)
		sprite:setSpriteEventHandler(function(_type, event)
			if _type == sp.EventType.ANIMATION_COMPLETE then
				removeCSprite(sprite)
			end
		end)

		local pos = cc.p(0, 0)

		if offsetPos then
			pos = cc.pAdd(cc.p(0, 0), offsetPos)
		end

		sprite:setPosition(pos):scale(2)
	end
end

function BattleSprite:getMoveToTargetPosition(posIdx, skillCfg)
	local x, y = self:getAttackPos(posIdx, skillCfg.posC, skillCfg.attackFriend)

	if posIdx ~= self:getSeat() and (skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2) then
		self.skillNeedCameraFix = true

		local camrX = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.x or 0
		local camrY = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.y or 0

		x, y = self:getAttackPos(posIdx, cc.p(camrX, camrY), skillCfg.attackFriend)
	end

	return x, y
end

function BattleSprite:getMoveToTargetFrontPosition(posIdx, skillCfg)
	local x, y = self:getProtectPos(posIdx, cc.p(0, 0))

	if posIdx ~= self:getSeat() and (skillCfg.cameraNear == 1 or skillCfg.cameraNear == 2) then
		self.skillNeedCameraFix = true

		local camrX = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.x or 0
		local camrY = skillCfg.cameraNear_posC and skillCfg.cameraNear_posC.y or 0

		x, y = self:getProtectPos(posIdx, cc.p(camrX, camrY))
	end

	return x, y
end

function BattleSprite:getMoveTime(posIdx, skillCfg, speed, a)
	local x, y = self:getMoveToTargetPosition(posIdx, skillCfg)
	local speed0 = speed or 1000
	local a = a
	local x2, y2 = self:getCurPos()
	local dis = cc.pGetLength(cc.p(x - x2, y - y2))
	local time = 0

	if a then
		local speedSquare = speed0 * speed0 + 2 * a * dis

		speedSquare = math.max(speedSquare, 0)
		time = (math.sqrt(speedSquare) - speed0) / a
	else
		time = dis / speed0
	end

	return time
end

function BattleSprite:onAddToScene()
	self:setVisible(false)
	self:resetPosZ()
	self:setLocalZOrder(self.posZ:get())
	self:setName("object" .. self.seat)
end

function BattleSprite:resetPosZ(effectY)
	local _, y = self:getSelfPos()
	local frontRow = display.height - (effectY or y)
	local backRow = frontRow - 1
	local rowNum = 2 - math.floor((self:getSeat() + 2) / 3) % 2

	self.posZ:set(rowNum == 1 and 2 * frontRow or backRow, "reset")

	self.battleMovePosZ = 2 * frontRow
end

function BattleSprite:onMoveToTarget(posIdx, skillCfg, noQueue, viewId, protectorTb)
	local needMove = true

	if posIdx == battle.AttackPosIndex.selfPos and not skillCfg.attackFriend then
		needMove = false
	end

	local targetView = self.battleView:onViewProxyCall("getSceneObj", viewId)
	local usedView = self:getRealUseView()
	local x, y = usedView:getMoveToTargetPosition(posIdx, skillCfg)

	if posIdx ~= battle.AttackPosIndex.selfPos and posIdx ~= battle.AttackPosIndex.center and targetView then
		local posAdjust = targetView.posAdjust:get()
		local beAttackPosAdjust = targetView:getBeAttackPosAdjust()

		x = x + posAdjust.x + beAttackPosAdjust.x
		y = y + posAdjust.y + beAttackPosAdjust.y
	end

	local newfaceto = skillCfg.attackFriend and -1 * self.faceTo

	usedView:onAddEventEffect("callback", {
		func = function()
			if self.skillNeedCameraFix then
				self.battleView:onViewProxyNotify("skillStartStageMove", skillCfg.cameraNear)
			end
		end
	}, noQueue)

	if skillCfg.isCantMoveBigSkill then
		usedView:setCurPos(cc.p(x, y))
		usedView:setActionState(battle.SpriteActionTable.standby)
	elseif needMove then
		usedView:onAddEventEffect("moveTo", {
			a = 1000,
			speed = 1500,
			timeScale = skillCfg.timeScale,
			delayMove = skillCfg.delayBeforeMove,
			costTime = skillCfg.moveCostTime,
			x = x,
			y = y,
			changeFaceTo = newfaceto
		}, noQueue)
	end

	if protectorTb then
		local z = math.max(targetView:getLocalZOrder(), self:getLocalZOrder()) + 1
		local seat = protectorTb.targetView:proxy():getSeat()

		protectorTb.view:proxy():onMoveToTargetFront(seat, skillCfg, targetView.posAdjust:get(), noQueue)
		protectorTb.view:proxy():setLocalZOrder(z)
	end
end

function BattleSprite:onMoveToTargetFront(posIdx, skillCfg, posAdjust, noQueue)
	local x, y = self:getMoveToTargetFrontPosition(posIdx, skillCfg)

	x = x + posAdjust.x
	y = y + posAdjust.y

	local changeFaceTo

	if posIdx <= 6 and self:getSeat() > 6 or self:getSeat() <= 6 and posIdx > 6 then
		changeFaceTo = -1 * self.faceTo
	end

	self:onAddEventEffect("moveTo", {
		speed = 1500,
		a = 1000,
		x = x,
		y = y,
		changeFaceTo = changeFaceTo
	}, noQueue)
end

function BattleSprite:onSortReloadUnit(unitID, key, isOver)
	local unitCfg = csv.unit[unitID]

	if self.unitID == self.model.unitID then
		return
	end

	for _, data in ipairs(self.specBindEffectCache) do
		removeCSprite(data.effect)
	end

	self:stopAllHolderAction()

	self.specBindEffectCache = {}

	self:reloadUnit()

	local unitCfg = self.model.unitCfg

	self.lifebar:setPosition(unitCfg.everyPos.lifePos)
	self.lifebar:setScale(unitCfg.lifeScale)

	self.refreshBuffIconOnce = true

	self:onPlayUnitSpecBind()
end

local holderActionCloseInSkill = {
	"shader"
}

function BattleSprite:onSkillBefore(skillStartTb, skillType, noQueue, args)
	self:onAddEventEffect("callback", {
		func = function()
			if skillStartTb then
				self.battleView:runDefer(skillStartTb.skillStartAddBuffsPlayFuncs)
			end
		end
	}, noQueue)
	self:onAddEventEffect("callback", {
		func = function()
			if skillStartTb then
				self.battleView:runDefer(skillStartTb.skillStartTriggerBuffsPlayFuncs)
			end
		end
	}, noQueue)
	self:pushApplySkillSceneTag(args)

	if skillType == battle.MainSkillType.NormalSkill then
		for _, type in ipairs(holderActionCloseInSkill) do
			self:onCloseBuffHolderAction(type)
		end
	end

	if args and args.isBigSkill and self ~= self:getRealUseView() then
		self:setVisible(false)
	end
end

function BattleSprite:onPlayAction(action, time, noQueue, isCantMoveBigSkill)
	if not action then
		return
	end

	if self.isPausing then
		return
	end

	local usedView = self:getRealUseView()

	if not usedView:getCurShowSpriteVisible() then
		usedView:curShowSprite():setVisible(true)
		errorInWindows("Seat %s, origin unitID %s, is not visible but try to play action %s", self.model.seat, self.model.originUnitID, action)
	end

	if battle.LoopActionMap[action] then
		table.insert(self.battleView.effectJumpCache, usedView:onAddEventEffect("effect", {
			action = action,
			lifetime = time,
			isCantMoveBigSkill = isCantMoveBigSkill
		}, noQueue))

		return
	end

	table.insert(self.battleView.effectJumpCache, usedView:onAddEventEffect("effect", {
		action = action,
		lifetime = time,
		onComplete = function()
			return
		end,
		isCantMoveBigSkill = isCantMoveBigSkill
	}, noQueue))
end

function BattleSprite:onUltJumpShowNum(params)
	self:onAddEventEffect("callback", {
		func = function()
			self.battleView:onViewProxyNotify("showNumber", params)
		end
	}, false)
end

local function idCmp(obj1, obj2)
	return obj1.id < obj2.id
end

function BattleSprite:onUltJumpEnd()
	self:onResetSkillEnd()
	self:onAddEventEffect("callback", {
		func = function()
			self:setActionState(battle.SpriteActionTable.standby)
			performWithDelay(self.battleView, function()
				self.battleView:resetEffectEventEnable()
			end, 0)
		end
	}, false)
end

function BattleSprite:onResetSkillEnd(skillType)
	local battleView = self.battleView

	self:onAddEventEffect("callback", {
		func = function()
			if self.skillNeedCameraFix then
				self.skillNeedCameraFix = false

				self.battleView:onViewProxyNotify("skillEndStageMoveBack")
			end

			if battleView.bgmChanged then
				audio.resumeMusic()

				battleView.bgmChanged = false
			end
		end
	}, false)

	if skillType == battle.SkillType.NormalSkill or skillType == battle.SkillType.NormalCombine or skillType == battle.SkillType.AidSkill then
		self:onAddEventEffect("callback", {
			func = function()
				local objs = self.battleView:onViewProxyCall("getSceneAllObjs")

				for _, objSpr in maptools.order_pairs(objs, idCmp) do
					if not objSpr:isComeBacking() and objSpr.id ~= self.id then
						objSpr:resetPos()
					end
				end
			end
		}, false)
	end
end

function BattleSprite:onObjSkillEnd(skillEndTb, skillType, noQueue)
	self:onAddEventEffect("callback", {
		func = function()
			if skillEndTb then
				self.battleView:runDefer(skillEndTb.skillEndAddBuffsPlayFuncs)
			end

			if skillEndTb then
				self.battleView:runDefer(skillEndTb.skillEndTriggerBuffsPlayFuncs)
			end

			if skillEndTb and skillEndTb.skillEndDrops then
				self.battleView:onViewProxyNotify("dropShow", skillEndTb.skillEndDrops)
			end
		end
	}, noQueue)

	if self.battleView:getEffectEventEnable() then
		self:onResetSkillEnd(skillType, noQueue)
	end

	self:onAddEventEffect("callback", {
		func = function()
			if skillEndTb then
				self.battleView:runDefer(skillEndTb.skillEndDeleteDeadObjs)
			end

			if (skillType == battle.SkillType.NormalSkill or skillType == battle.SkillType.NormalCombine or skillType == battle.SkillType.AidSkill) and self.model.force == 1 and not self.battleView:getSceneModel().autoFight then
				self.battleView:onViewProxyNotify("showMain", true)
			end
		end
	}, noQueue)
end

function BattleSprite:onComeBack(posIdx, noQueue, skillCfg, aotoBack, protectorViews)
	local function comeBack(view)
		if skillCfg.flashBack then
			view:onResetPos()
		else
			local args = {
				delayMove = skillCfg.delayBeforeBack,
				costTime = skillCfg.backCostTime,
				timeScale = skillCfg.timeScale
			}

			view:onAddEventEffect("comeBack", args, noQueue)
		end
	end

	if protectorViews then
		for k, v in ipairs(protectorViews) do
			comeBack(v:proxy())
		end
	end

	if posIdx == battle.AttackPosIndex.selfPos and not skillCfg.attackFriend then
		return
	end

	local usedView = self:getRealUseView()

	comeBack(usedView)
end

function BattleSprite:onAfterComeBack(afterComeBackTb, noQueue)
	self:onAddEventEffect("callback", {
		func = function()
			if afterComeBackTb then
				self.battleView:runDefer(afterComeBackTb.afterComeBackRecoverMp)
			end
		end
	}, noQueue)
end

function BattleSprite:onResetPos()
	self:onAddEventEffect("callback", {
		func = function()
			self:resetPos()
		end
	})
end

function BattleSprite:onObjSkillOver(noQueue)
	self:onAddEventEffect("callback", {
		func = function()
			self:popApplySkillSceneTag()
		end
	}, noQueue)
end

function BattleSprite:onNewBattleTurn()
	self:objToHideEff(false)
	self:onPlayBuffHolderAction()
	self:onPlayUnitSpecBind()

	for tag, tagMap in pairs(self.queueCallBack) do
		for id, queue in pairs(tagMap) do
			local lastData = queue[table.length(queue)]

			if lastData.isLast then
				lastData.f()

				tagMap[id] = nil
			end
		end
	end
end

function BattleSprite:onPlayUnitSpecBind()
	local effect, ani

	for k, data in ipairs(self.unitSpecBind) do
		if not self.specBindEffectCache[k] then
			local node = nodetools.get(self, unpack(data.node))

			effect = newCSpriteWithOption(data.effect)

			node:addChild(effect, data.pos[3])
			effect:setPosition(cc.p(data.pos[1], data.pos[2]))
			effect:setScale(data.scale or 1)
			effect:setScaleX(self.faceTo * (data.scale or 1))

			self.specBindEffectCache[k] = {
				lastIndex = 0,
				effect = effect
			}
		end

		local _data = self.specBindEffectCache[k]
		local index = battleCsv.doFormula(data.bind, {
			self = self.model
		})

		index = index + 1

		if _data.lastIndex ~= index then
			ani = data.action[index]

			if ani then
				_data.effect:play(ani)

				_data.lastIndex = index
			else
				errorInWindows("specBind(%s) action not has index(%s) ", self.unitID, index)
			end
		end
	end
end

function BattleSprite:onAttacting(isAttacting, noQueue)
	self:onAddEventEffect("callback", {
		func = function()
			if not isAttacting then
				self.battleView:onViewProxyNotify("showLinkEffect", true)
			end

			self.battleView:onViewProxyNotify("updateLinkEffect", isAttacting, self.key)

			local usedView = self:getRealUseView()

			usedView:objToHideEff(isAttacting, self)

			if isAttacting then
				usedView.sprite._opacity = usedView.sprite:opacity()

				usedView.sprite:opacity(255)
			else
				usedView.sprite:opacity(usedView.sprite._opacity)
			end
		end
	}, noQueue)
end

function BattleSprite:compensateDeadEffect(callback)
	local sprite = newCSpriteWithOption(self.deathEffect.res)

	if not sprite then
		if callback then
			callback()
		end

		return
	end

	self.battleView.gameLayer:addChild(sprite)
	sprite:setSpriteEventHandler(function(_type, event)
		if _type == sp.EventType.ANIMATION_COMPLETE then
			removeCSprite(sprite)

			if callback then
				callback()
			end
		end
	end)

	local x, y = self:getCurPos()
	local effectPos = cc.p(x, y)

	sprite:setPosition(effectPos):scale(2)

	local scaleX = self.faceTo

	sprite:setScaleX(2 * scaleX)

	local aniName = self.deathEffect.action

	sprite:play(aniName)
end

function BattleSprite:onDead(callback)
	self:setDebugEnabled(false)
	self:setEffectDebugEnabled(false)

	for tag, map in pairs(self.queueCallBack) do
		for id, list in pairs(map) do
			for _, data in ipairs(list) do
				if data.f then
					data.f()
				end
			end
		end
	end

	self.queueCallBack = {}

	if not self:isVisible() then
		self.battleView:onEventEffectQueue("callback", {
			func = function()
				self:compensateDeadEffect(callback)
			end
		})

		return
	end

	if self.deathEffect.res == self.unitRes then
		self:onAddEventEffect("effect", {
			action = self.deathEffect.action,
			onComplete = callback
		})

		return
	end

	local effectRes = self.deathEffect.res
	local action = self.deathEffect.action

	local function removeSprite()
		if self.battleView.deathCache ~= nil then
			for _, v in ipairs(self.battleView.deathCache) do
				v:removeSelf()
			end

			self.battleView.deathCache = {}
		end
	end

	local hitPos = self.unitCfg.everyPos.hitPos

	self.lifebar:setVisible(false)
	transition.executeSequence(self.sprite):fadeOut(0.4):done()
	transition.executeSequence(self.sprite):delay(0.1):moveBy(1.2, hitPos.x, hitPos.y):done()
	transition.executeSequence(self.sprite):delay(0.1):scaleTo(1, 0.01):func(removeSprite):func(callback or function()
		return
	end):done()

	local sprite = newCSpriteWithOption(effectRes)

	self:add(sprite)
	arraytools.push(self.battleView.deathCache, sprite)
	sprite:setLocalZOrder(999999)
	sprite:anchorPoint(0.5, 0.5):scale(2)
	sprite:play(action)
	sprite:setTimeScale(1.15)
end

function BattleSprite:onBeAttackPlayAni()
	self:play("beAttack")
	self:setSpriteEventHandler(function(event, eventArgs)
		if event == sp.EventType.ANIMATION_COMPLETE then
			self:play("standby_loop")
		end
	end)
end

function BattleSprite:onDealBuffEffectsMap(iconResPath, cfgId, boxRes)
	return gRootViewProxy:notify("dealBuffEffectsMap", self, iconResPath, cfgId, boxRes)
end

function BattleSprite:onDealBuffIconBox(cfgId, name, boxRes, isOver)
	return gRootViewProxy:notify("dealBuffIconBox", self, cfgId, name, boxRes, isOver)
end

function BattleSprite:onShowBuffIcon(iconResPath, cfgId, overlayCount)
	return gRootViewProxy:notify("showBuffIcon", self, iconResPath, cfgId, overlayCount)
end

function BattleSprite:onShowBuffText(textResPath)
	return gRootViewProxy:notify("showBuffText", self, textResPath)
end

function BattleSprite:onShowBuffImmuneEffect(group)
	local groupRelation = gBuffGroupRelationCsv[group]

	if groupRelation and groupRelation.immuneEffect then
		gRootViewProxy:notify("showBuffText", self, string.format(battle.ShowHeadNumberRes.txtTypeImmune, groupRelation.immuneEffect))
	end
end

function BattleSprite:onAlterBattleScene(args)
	self.battleView:onEventEffect(nil, "callback", {
		func = function()
			gRootViewProxy:notify("alterBattleScene", args)
		end,
		delay = args.delay or 0
	})
end

function BattleSprite:onWeatherRefresh(buff)
	return gRootViewProxy:notify("weatherRefresh", self, buff)
end

function BattleSprite:onDelBuffIcon(cfgId)
	return gRootViewProxy:notify("delBuffIcon", self, cfgId)
end

function BattleSprite:onShowHeadNumber(args)
	return gRootViewProxy:notify("showHeadNumber", self, args)
end

function BattleSprite:onShowHeadText(args)
	local parms = args.args
	local delay = parms.delay or 0

	if parms.miss then
		local backTime = 0.15
		local backX = -40 * self.faceTo
		local backY = 0
		local backDelay = 0.1

		transition.executeSequence(self):delay(delay):moveBy(backTime, backX, backY):delay(backDelay):moveBy(backTime, -backX, -backY):done()
	end

	return gRootViewProxy:notify("showHeadText", self, args)
end

function BattleSprite:onShowBuffContent(contentRes)
	if not contentRes or contentRes == "" then
		return
	end

	if not self then
		return
	end

	local sprite = newCSpriteWithOption(contentRes)

	if not sprite then
		return
	end

	self:add(sprite, 9999)

	local pos = self.unitCfg.everyPos.hitPos

	sprite:setPosition(pos)

	local function remove()
		removeCSprite(sprite)
	end

	transition.executeSequence(sprite):delay(1):fadeOut(0.25):func(remove):done()
end

function BattleSprite:lockLifeBar(isLock)
	self.isLock = isLock
end

function BattleSprite:onUpdateLifebar(args)
	if args.skillType == battle.SkillType.NormalSkill and args.mainSkillType ~= battle.MainSkillType.BigSkill then
		self.lifebar:setVisible(true)
	end

	if self.isLock then
		return
	end

	self.lifebar:update(args)
end

function BattleSprite:onUpdateLifebarPoint(args)
	self.lifebar:updatePoint(args)
end

function BattleSprite:showSkillSelectTextState(isShow, restraintType, immuneInfo)
	local res

	if isShow == false then
		-- block empty
	elseif immuneInfo then
		res = battle.RestraintTypeIcon[immuneInfo]
	else
		res = battle.RestraintTypeIcon[restraintType]
	end

	self.natureQuan:show()
	self.natureQuan.canSelect:show()
	self.natureQuan.textDi:hide()

	if self.natureQuan.canShowTextDi and res then
		self.natureQuan.textDi:show()
		self.natureQuan.textDi:loadTexture(res)
	end

	self.natureQuan.cantSelect:hide()
end

function BattleSprite:setShowTextDi(isShow)
	self.natureQuan.canShowTextDi = isShow
end

function BattleSprite:beHit(delta, init)
	if init then
		self.beHitTime = init

		if self.beHitTime > 0 then
			self:setActionState(battle.SpriteActionTable.hit)
		end
	else
		self.beHitTime = self.beHitTime - delta

		if self.beHitTime <= 0 then
			self:setActionState(battle.SpriteActionTable.standby)
		end
	end
end

function BattleSprite:getLeftBeHitTime()
	return self.beHitTime or 0
end

function BattleSprite:onReloadUnit(layerName, unitRes)
	self:reloadUnit(unitRes)

	if layerName then
		self:addToLayer(layerName)
	end
end

function BattleSprite:onShowHeldItemEffect(itemId)
	if self.battleView.DEBUG_BATTLE_HIDE then
		return
	end

	local itemCfg = csv.held_item.items[itemId]

	assert(itemCfg, "csv.held_item.items not has itemId: " .. itemId)

	local iconRes = itemCfg.icon
	local quality = itemCfg.quality
	local hitPos = self.unitCfg.everyPos.hitPos
	local x = hitPos.x
	local y = hitPos.y + 150
	local panel = ccui.Layout:create():size(300, 300):anchorPoint(0.5, 0):xy(self:getPositionX() + x, self:getPositionY() + y):z(battle.SpriteLayerZOrder.qipao + 10):addTo(self.battleView.gameLayer)
	local effPath = "daojuchufa/daojuchufa.skel"
	local effect = newCSpriteWithOption(effPath)

	if not effect then
		return
	end

	local aniName = "effect"

	effect:play(aniName)
	effect:setSpriteEventHandler(function(_type, event)
		if _type == sp.EventType.ANIMATION_COMPLETE then
			removeCSprite(effect)
		end
	end)
	effect:setPosition(cc.p(150, 150))
	panel:addChild(effect, 1)

	local boxRes = ui.QUALITY_BOX[quality]
	local fgRes = string.format("common/icon/panel_icon_k%d.png", quality)
	local box = ccui.ImageView:create(boxRes):xy(150, 100):z(2):hide():addTo(panel)
	local icon = ccui.ImageView:create(iconRes):xy(150, 100):z(3):scale(2):hide():addTo(panel)
	local fg = ccui.ImageView:create(fgRes):xy(150, 100):z(4):hide():addTo(panel)

	transition.executeSequence(panel):delay(0.3):func(function()
		box:show()
		icon:show()
		fg:show()
	end):moveBy(0.4, 0, 70):delay(1.3):func(function()
		panel:removeFromParent()
	end):done()
end

function BattleSprite:onShowCounterAttackText(key, exAttackMode)
	local txtName = exAttackMode == battle.ExtraAttackMode.prophet and battle.ShowHeadNumberRes.txtXfzr or battle.ShowHeadNumberRes.txtFj

	self.battleView:onEventEffect(nil, "callback", {
		delay = 0,
		func = function()
			self:onShowBuffText(txtName)
		end
	})
end

function BattleSprite:onPlayCharge(args, isOver)
	if not args then
		return
	end

	if isOver then
		self:onPopAction(battle.SpriteActionTable.standby, "charge")

		if args.endCharing then
			table.insert(self.battleView.effectJumpCache, self:onAddEventEffect("effect", {
				action = args.endCharing.action,
				lifetime = args.endCharing.lifeTime,
				onComplete = function()
					self:onPlayState(battle.SpriteActionTable.standby)
				end
			}))
		else
			self:onPlayState(battle.SpriteActionTable.standby)
		end
	else
		self:onPushAction(battle.SpriteActionTable.standby, args.charing.action, "charge")

		if args.startCharing then
			table.insert(self.battleView.effectJumpCache, self:onAddEventEffect("effect", {
				action = args.startCharing.action,
				lifetime = args.startCharing.lifeTime,
				onComplete = function()
					if args.charing then
						self:onPlayState(battle.SpriteActionTable.standby)
					end
				end
			}))
		else
			self:onPlayState(battle.SpriteActionTable.standby)
		end
	end
end

function BattleSprite:getMoveToTargetPos(posChoose, hintTargetType, targets)
	if posChoose == 0 then
		return battle.AttackPosIndex.center
	end

	if posChoose == 5 then
		return battle.AttackPosIndex.selfPos
	end

	local posIdx = battle.AttackPosIndex.selfPos

	if table.length(targets) > 0 then
		local targetViews = {}

		for _, obj in ipairs(targets) do
			table.insert(targetViews, {
				seat = obj.seat,
				force = obj.force
			})
		end

		if posChoose == 1 or posChoose == 4 then
			posIdx = targetViews[1].seat
		elseif posChoose == 6 then
			local idx = targetViews[1].seat
			local column = (idx - 1) % 3 + 1

			posIdx = idx > 6 and column + 6 or column
		elseif posChoose == 7 then
			posIdx = targetViews[table.length(targetViews)].seat
		elseif posChoose == 8 then
			local idx = targetViews[1].seat
			local row = (math.floor((idx + 2) / 3) - 1) % 2 + 1
			local seat = 2 + (row - 1) * 3

			posIdx = idx > 6 and seat + 6 or seat
		else
			local idx = 0
			local cnt = 0
			local calcCnt = true

			for _, spr in ipairs(targetViews) do
				local isAttack = hintTargetType == 0
				local curTargetIsChooseTarget

				if isAttack then
					curTargetIsChooseTarget = spr.force ~= self.force
				else
					curTargetIsChooseTarget = spr.force == self.force
				end

				if curTargetIsChooseTarget then
					local column = (spr.seat - 1) % 3 + 1

					if column == 2 then
						calcCnt = false
						posIdx = spr.seat

						break
					end

					idx = idx + spr.seat
					cnt = cnt + 1
				end
			end

			if calcCnt then
				if cnt > 0 then
					posIdx = math.floor(idx / cnt)
				else
					printWarn("no targets be choose in targets %d when posChoose %d", table.length(targets), posChoose)
				end
			end
		end
	end

	if not posIdx then
		errorInWindows("getMoveToTargetPos posIdx is nil, targets:%d, posChoose:%s, hintTargetType:%s", table.length(targets), posChoose, hintTargetType)

		posIdx = battle.AttackPosIndex.selfPos
	end

	return posIdx
end

function BattleSprite:onStageChange(status)
	self.seat = status and self.model.seat or -1

	self:resetPos()
	self:updHitPanel()
	self:onAddToScene()

	if status then
		self:setVisibleEnable(status)
	end

	self:onSetSpriteVisible(status, "depart", status)
end

function BattleSprite:onRecordOrderData(type, args)
	if not self.recordOrderDataTb[type] then
		self.recordOrderDataTb[type] = CVector.new()
	end

	self.recordOrderDataTb[type]:push_back(args)
end

function BattleSprite:onEscape(args)
	local x, y = 0, 0

	if self.seat <= 6 then
		x = -display.width / 2
		y = battle.StandingPos[self.seat].y
	else
		x = display.width * 1.5
		y = battle.StandingPos[self.seat - 6].y
	end

	self:onAddEventEffect("moveTo", {
		speed = 150,
		a = 100,
		delayMove = args.delayMove or 0,
		costTime = args.costTime or 1000,
		x = x,
		y = y,
		changeFaceTo = -1 * self.faceTo
	}, false)
end

function BattleSprite:onPassOneMultWaveClean()
	self:setActionState(battle.SpriteActionTable.standby)

	for k, v in ipairs(self.effectJumpCache) do
		self:onEventEffectCancel(v)
	end

	self.effectJumpCache = {}

	self.effectManager:passOneMultWaveClear()
	self.effectResManager:passOneMultWaveClean()

	for key, tt in pairs(self.buffEffectsMap) do
		if tt.sprite then
			removeCSprite(tt.sprite)
		end
	end

	self.buffEffectsMap = {}
end

function BattleSprite:pushQueueCallBack(tag, id, f, isLast)
	if not self.queueCallBack[tag] then
		self.queueCallBack[tag] = {}
	end

	self.queueCallBack[tag][id] = self.queueCallBack[tag][id] or {}

	table.insert(self.queueCallBack[tag][id], {
		f = f,
		isLast = isLast
	})
end

function BattleSprite:popQueueCallBack(tag, id, isLast)
	if not self.queueCallBack[tag] then
		return
	end

	if self.queueCallBack[tag][id] then
		if isLast then
			local data = table.remove(self.queueCallBack[tag][id])

			self.queueCallBack[tag][id] = nil

			return data.f
		end

		local data = table.remove(self.queueCallBack[tag][id], 1)

		if table.length(self.queueCallBack[tag][id]) == 0 then
			self.queueCallBack[tag][id] = nil
		end

		return data.f
	end
end

function BattleSprite:collectBuffEffects(id, effect)
	if not effect then
		return
	end

	if not self.buffEffects[id] then
		self.buffEffects[id] = {}
	end

	table.insert(self.buffEffects[id], effect)
end

function BattleSprite:cleanBuffEffects(id)
	if self.buffEffects[id] then
		for _, effect in ipairs(self.buffEffects[id]) do
			self.battleView:onEventEffectCancel(effect)
		end

		self.buffEffects[id] = nil
	end
end
