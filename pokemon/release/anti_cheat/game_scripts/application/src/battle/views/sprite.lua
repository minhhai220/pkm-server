-- chunkname: @src.battle.views.sprite

globals.EffectResManager = class("EffectResManager")

local function getForce(seat)
	return (seat == 13 or seat <= 6) and 1 or 2
end

local CallEffectResManagerOrigin = {
	[battle.EffectResType.BuffText] = false,
	[battle.EffectResType.OnceEffect] = false,
	[battle.EffectResType.FollowSprite] = false,
	[battle.EffectResType.BuffEffectInHolder] = false,
	[battle.EffectResType.BuffEffectInNormal] = true,
	[battle.EffectResType.BuffEffectInForceSelf] = true,
	[battle.EffectResType.BuffEffectInForceEnemy] = true,
	[battle.EffectResType.FollowToScale] = false
}
local EffectEnvMap = {
	normal = {
		addSprite = function(self, effectInfo)
			effectInfo.spr:visible(true)
		end,
		objToHideEff = function(self, effectInfo, flag)
			return effectInfo.showEffect or not flag
		end
	},
	lockEffect = {
		addSprite = function(self, effectInfo)
			if effectInfo.showEffect ~= nil then
				effectInfo.spr:visible(effectInfo.showEffect)
			end
		end,
		objToHideEff = function(self, effectInfo, flag)
			return effectInfo.showEffect
		end
	},
	debug = {
		addSprite = function(self, effectInfo)
			effectInfo.spr:visible(false)
		end,
		objToHideEff = function(self, effectInfo, flag)
			return false
		end
	}
}

function EffectResManager:ctor(sprite, battleView)
	self.resKeyMap = {}
	self.resKeyInfoMap = {}
	self.resKeyMapPower = {}
	self.envFuncMap = nil

	self:setEnv("normal")

	if sprite then
		self.sprite = sprite
		self.battleView = sprite.battleView
	else
		self.sprite = battleView
		self.battleView = battleView
	end

	for key, isFromBattleView in pairs(CallEffectResManagerOrigin) do
		if sprite ~= nil or isFromBattleView then
			self.resKeyMap[key] = {}
			self.resKeyInfoMap[key] = {}
			self.resKeyMapPower[key] = {}
		end

		if sprite and isFromBattleView then
			self:bind(key, self.battleView.effectResManager)
		end
	end
end

function EffectResManager:bind(key, resManager)
	self.resKeyMap[key] = resManager.resKeyMap[key]
	self.resKeyInfoMap[key] = resManager.resKeyInfoMap[key]
	self.resKeyMapPower[key] = resManager.resKeyMapPower[key]
end

function EffectResManager:setEnv(envType)
	self.envFuncMap = EffectEnvMap[envType]
end

function EffectResManager:excuteProcess(name, ...)
	if self.envFuncMap and self.envFuncMap[name] then
		return self.envFuncMap[name](self, ...)
	end
end

function EffectResManager:pairs(key)
	if not key then
		return pairs(self.resKeyMap)
	end

	return pairs(self.resKeyMap[key])
end

function EffectResManager:pairsInfo(key, resKey)
	return pairs(self.resKeyInfoMap[key][resKey])
end

function EffectResManager:getEffectInfo(key, resKey)
	return self.resKeyMap[key][resKey]
end

function EffectResManager:setVisibleAll(visible)
	for key, resTable in pairs(self.resKeyMap) do
		for resKey, info in pairs(resTable) do
			info.spr:setVisible(visible)
		end
	end
end

function EffectResManager:getEffectRefInfo(key, resKey)
	return self.resKeyInfoMap[key][resKey]
end

function EffectResManager:isEmpty(key)
	return not next(self.resKeyMap[key])
end

function EffectResManager:setPower(key, powerIdx, data)
	if type(data) ~= "table" then
		local _data = self.resKeyMapPower[key][powerIdx]

		if _data and _data.id == data then
			self.resKeyMapPower[key][powerIdx] = nil
		end
	else
		self.resKeyMapPower[key][powerIdx] = data
	end
end

function EffectResManager:addResInfo(key, resKey, data)
	if not self.resKeyInfoMap[key][resKey] then
		self.resKeyInfoMap[key][resKey] = {}
	end

	table.insert(self.resKeyInfoMap[key][resKey], data)

	if data.visible ~= nil then
		local effectInfo = self:getEffectInfo(key, resKey)

		effectInfo.spr:setVisible(data.visible)
	end
end

function EffectResManager:removeResInfo(key, resKey, id)
	if not self.resKeyInfoMap[key][resKey] then
		return
	end

	local removeData

	for i, data in ipairs(self.resKeyInfoMap[key][resKey]) do
		if data.id == id then
			table.remove(self.resKeyInfoMap[key][resKey], i)

			removeData = data

			break
		end
	end

	if removeData then
		local effectInfo = self:getEffectInfo(key, resKey)

		if not effectInfo or not effectInfo.spr then
			return
		end

		effectInfo.spr:setVisible(self:getKeyInResInfoBy(key, resKey, "visible", "last"))
	end
end

local FilterFuncMap = {
	last = function(data, key)
		if data[key] ~= nil then
			return data[key], false, false
		end

		return nil, true, false
	end
}

function EffectResManager:getKeyInResInfoBy(key, resKey, argKey, way)
	if not self.resKeyInfoMap[key][resKey] then
		return
	end

	local effectInfo = self.resKeyMap[key][resKey]
	local filter = FilterFuncMap[way]

	assertInWindows(filter ~= nil, "EffectResManager way:%s in FilterFuncMap is not define", way)

	local powerData = self.resKeyMapPower[key][argKey]

	if powerData and powerData.addCheck(effectInfo) then
		return powerData.value
	end

	local argValue, val, isSkip, isBreak

	for k, v in ipairs(self.resKeyInfoMap[key][resKey]) do
		val, isSkip, isBreak = filter(v, argKey)

		if not isSkip then
			argValue = val
		end

		if isBreak then
			break
		end
	end

	return argValue
end

local function makeEffectInfo(spr, count, showEffect, hideInAttack)
	return {
		spr = spr,
		count = count or 0,
		showEffect = showEffect
	}
end

function EffectResManager:add(key, resKey, sprRes, extraData)
	if self.resKeyMapPower[key].add and not self.resKeyMapPower[key].add.switch then
		return
	end

	local effectInfo = self.resKeyMap[key][resKey]

	if effectInfo == nil then
		local sprite = extraData.spr or newCSpriteWithOption(sprRes)

		sprite:visible(true)

		if key == battle.EffectResType.OnceEffect or key == battle.EffectResType.BuffText then
			return sprite, true
		end

		effectInfo = makeEffectInfo(sprite, 1, extraData.showEffect, key == battle.EffectResType.BuffEffectInHolder)
		self.resKeyMap[key][resKey] = effectInfo

		self:addResInfo(key, resKey, {
			visible = true,
			id = extraData.id,
			cfgId = extraData.cfgId
		})
		self:excuteProcess("addSprite", effectInfo)

		if extraData.pos and (extraData.pos < 3 or extraData.pos > 6) then
			self:add(battle.EffectResType.FollowToScale, resKey, sprRes, {
				id = extraData.id,
				cfgId = extraData.cfgId,
				spr = sprite
			})
			self.sprite:updateBuffeffectsScale()
		end

		return sprite, true
	end

	if extraData.justRefresh ~= true then
		effectInfo.count = effectInfo.count + 1
	end

	if effectInfo.count == 0 then
		self.resKeyMap[key][resKey] = nil

		return
	end

	return effectInfo.spr, false
end

function EffectResManager:remove(key, resKey, id)
	self:removeResInfo(key, resKey, id)

	if not self.resKeyMap[key][resKey] then
		return
	end

	local effectInfo = self.resKeyMap[key][resKey]

	effectInfo.count = effectInfo.count - 1

	if effectInfo.count == 0 then
		self.resKeyMap[key][resKey] = nil

		local spr = effectInfo.spr

		if spr then
			if key == battle.EffectResType.FollowToScale then
				return
			else
				self:remove(battle.EffectResType.FollowToScale, resKey, id)
			end

			return spr
		end
	end
end

function EffectResManager:passOneMultWaveClean()
	for key, data in pairs(self.resKeyMap) do
		if battle.EffectResType.FollowSprite ~= key then
			for _, effectInfo in pairs(data) do
				local spr = effectInfo.spr

				if spr then
					removeCSprite(spr)
				end
			end

			self.resKeyMap[key] = {}
		end
	end

	local sprite = self.sprite ~= self.battleView and self.sprite or nil

	for key, isFromBattleView in pairs(CallEffectResManagerOrigin) do
		if battle.EffectResType.FollowSprite ~= key then
			if sprite ~= nil or isFromBattleView then
				self.resKeyMap[key] = {}
				self.resKeyInfoMap[key] = {}
				self.resKeyMapPower[key] = {}
			end

			if sprite and isFromBattleView then
				self:bind(key, self.battleView.effectResManager)
			end
		end
	end
end

require("easy.sprite")
require("battle.views.lifebar")

globals.BattleSprite = class("BattleSprite", cc.Node)

function globals.newCSpriteWithOption(aniRes, ...)
	local sprite = newCSprite(aniRes, ...)
	local enable = gEffectOptionCsv[aniRes]

	if sprite:isSpine() and enable ~= nil then
		sprite:getAni():setTwoColorTint(enable)
	end

	return sprite
end

function BattleSprite:ctor(battleView, model, key, args)
	self.battleView = battleView
	self.model = model
	self.key = key
	self.args = args
	self.type = args.type
	self.spineEventMap = {}
	self.debug = {
		enabled = false
	}
	self.effectDebug = {
		enabled = false
	}
	self.relationshipStatus = "showRelationship"
	self.skillSceneTag = CVector.new()
	self.followSprite = {}
	self.aniEffectPlayIDMap = {}
	self.replaceView = nil
	self.canSetVisible = true
	self.refreshBuffIconOnce = false
	self.skillJumpSwitchOnce = false
	self.recordOrderDataTb = {}
	self.skins = CVector.new()
	self.actionTable = {}
	self.actionState = battle.SpriteActionTable.run

	self:resetActionTab()

	self.queueCallBack = {}
	self.buffEffects = {}
end

function BattleSprite:init()
	self:initUnitData()

	self.monsterCfg = self.model.monsterCfg
	self.force = getForce(self.seat)
	self.forceFaceTo = self.force == 1 and 1 or -1
	self.faceTo = self.forceFaceTo
	self.posAdjust = battleEasy.priorDataTable(self:getPosAdjust(), "posAdjust")
	self.beHitTime = 200

	if self.monsterCfg and self.monsterCfg.posAdjust and self.monsterCfg.posAdjust[self.seat - 6] ~= 0 then
		self.posAdjust:set(cc.p(self.monsterCfg.posAdjust[self.seat - 6].x, self.monsterCfg.posAdjust[self.seat - 6].y), "init")
	end

	local posx, posy = self:getSelfPos()

	self.posXY = cc.p(posx, posy)
	self.posZ = battleEasy.priorDataTable(posy, "posZ")
	self._scale = nil
	self._scaleX = nil
	self._scaleY = nil
	self.battleMovePosZ = 0
	self.effectManager = battleEffect.Manager.new("BattleSprite." .. self.model.id)
	self.effectProcessArgs = {}

	self:loadSprite(self.unitRes, battle.SpriteLayerZOrder.selfSpr)

	self.deathEffect = {
		action = "effect",
		res = "effect/death.skel"
	}
	self.spineActionScales = {}
	self.spinePrevAction = nil

	if self.unitCfg.scaleCMode == 2 then
		for _, skillID in csvPairs(self.unitCfg.skillList) do
			local skillCfg = csv.skill[skillID]

			if skillCfg and skillCfg.spineAction then
				self.spineActionScales[skillCfg.spineAction] = self.unitCfg.scale
			end
		end
	end

	self:initLifeBar()
	self:initNatureQuan()
	self:initGroundRing()

	self.effectResManager = EffectResManager.new(self)

	self:setPosition(self.posXY)

	self.buffEffectsMap = {}
	self.buffEffectHolderMap = {}
	self.buffEffectsFollowObjToScale = {}
	self.specBindEffectCache = {}
	self.effectJumpCache = {}
	self.startYinyingPos = self.sprite:getBonePosition("yinying")

	self:updHitPanel()
end

function BattleSprite:initLifeBar()
	self.lifebar = CLifeBar.new(self.model, self.battleView)

	self:add(self.lifebar, battle.SpriteLayerZOrder.lifebar, "lifebar")
end

function BattleSprite:initQuan(effectRes, effectAni, deep)
	local quan = newCSpriteWithOption(effectRes)
	local size = self.natureQuan:getContentSize()

	quan:addTo(self.natureQuan, deep):setScale(1):xy(size.width / 2, size.height / 2):hide():play(effectAni)

	return quan
end

function BattleSprite:initNatureQuan()
	self.natureQuan = cc.Node:create()

	self.natureQuan:hide():anchorPoint(0.5, 1):xy(self.unitCfg.everyPos.hitPos)
	self:add(self.natureQuan, battle.SpriteLayerZOrder.quan, "nature_quan")

	local size = self.natureQuan:getContentSize()
	local textDi = ccui.ImageView:create(battle.SpriteRes.natureQuanTxtDi)

	textDi:addTo(self.natureQuan, -5):xy(size.width / 2, size.height / 2)

	self.natureQuan.textDi = textDi
	self.natureQuan.canShowTextDi = true
	self.natureQuan.canSelect = self:initQuan(battle.SpriteRes.natureQuan, "xuanzhong_loop", 1)

	self.natureQuan.canSelect:show()

	self.natureQuan.cantSelect = self:initQuan(nil, nil, 2)
end

function BattleSprite:initGroundRing()
	self.groundRing = newCSpriteWithOption(battle.SpriteRes.groundRing)

	self.groundRing:addTo(self, battle.SpriteLayerZOrder.ground):hide():play("effect_loop")

	self.groundRingVisible = battleEasy.priorDataTable(false, "groundRingVisible")
end

function BattleSprite:initUnitData(unitRes)
	self.id = self.model.id
	self.seat = self.seat or self.model.seat
	self.unitID = self.model.unitID
	self.unitCfg = csv.unit[self.unitID]
	self.unitSpecBind = self.unitCfg.specBind
	self.unitRes = unitRes or self.unitCfg.unitRes
	self.cardID = self.model.cardID
	self.cardCfg = csv.cards[self.unitCfg.cardID]
end

function BattleSprite:getSeat()
	return self.seat
end

function BattleSprite:setSeat(seat)
	self.seat = seat
end

function BattleSprite:loadSprite(res, zOrder)
	if res then
		self.sprite = newCSpriteWithOption(res)
		self.spriteVisible = battleEasy.priorDataTable(true, "spriteVisible")

		self.sprite:setPosition(cc.p(0, 0))
		self.sprite:setSpriteEventHandler(handler(self, self.onSpriteEvent))
		self:add(self.sprite, zOrder)
		self:setScale(1)
		self:setSkin()
	end
end

function BattleSprite:reloadUnit(unitRes)
	local resetPos = cc.p(self.sprite:getPositionX(), self.sprite:getPositionY())

	self.sprite:removeAnimation()
	self:initUnitData(unitRes)

	self._scale = nil
	self._scaleX = nil
	self._scaleY = nil
	self.actionState = battle.SpriteActionTable.run

	self:loadSprite(self.unitRes, battle.SpriteLayerZOrder.selfSpr)
	self.sprite:setPosition(resetPos)
	self:onSetSpriteVisible()
	self:setActionState(battle.SpriteActionTable.standby)
end

function BattleSprite:addToLayer(layerName)
	local layer = self.battleView[layerName]

	if layer then
		self:retain()
		self:removeFromParent()
		layer:add(self, 999)
		self:release()
	end
end

function BattleSprite:updateLifeBarState(isShow)
	self.lifebar:setVisible(isShow)
	self.lifebar:setVisibleEnable(isShow)
end

function BattleSprite:pauseAnimation()
	self.isPausing = true

	if self.sprite then
		self.sprite:pause()
	end

	for k, tt in pairs(self.buffEffectsMap) do
		if tt.sprite then
			tt.sprite:pause()
		end
	end
end

function BattleSprite:resumeAnimation()
	self.isPausing = nil

	if self.sprite then
		self.sprite:resume()
	end

	for k, tt in pairs(self.buffEffectsMap) do
		if tt.sprite then
			tt.sprite:resume()
		end
	end
end

function BattleSprite:getFaceTo()
	return self.faceTo
end

function BattleSprite:pauseSprite()
	self.isPausing = true

	if self.sprite then
		self.sprite:pause()
	end
end

function BattleSprite:resumeSprite()
	self.isPausing = nil

	if self.sprite then
		self.sprite:resume()
	end
end

function BattleSprite:setPlaySpeed(val)
	if self.sprite then
		self.sprite:setAnimationSpeedScale(val)
	end
end

function BattleSprite:setSpriteOpacity(opacity)
	self:curShowSprite():setCascadeOpacityEnabled(true)
	self:curShowSprite():setOpacity(opacity)

	self:curShowSprite()._opacity = opacity
end

function BattleSprite:objToBlank(args)
	transition.executeSequence(self):scaleTo(args.startLast / 1000, args.scale):delay(args.delayLast / 1000):scaleTo(args.endLast / 1000, 1):done()
end

function BattleSprite:objToHideEff(flag)
	for resKey, effectInfo in self.effectResManager:pairs(battle.EffectResType.BuffEffectInHolder) do
		local spr = effectInfo.spr

		if spr then
			if not flag then
				local isShow = self.effectResManager:getKeyInResInfoBy(battle.EffectResType.BuffEffectInHolder, resKey, "objToHideEffVisible", "last")

				if isShow == nil then
					isShow = self.effectResManager:excuteProcess("objToHideEff", effectInfo, flag)
				end

				spr:setVisible(isShow)
			else
				local isShow = self.effectResManager:excuteProcess("objToHideEff", effectInfo, flag)

				isShow = isShow and self.effectResManager:getKeyInResInfoBy(battle.EffectResType.BuffEffectInHolder, resKey, "visible", "last")

				spr:setVisible(isShow)
			end
		end
	end

	for resKey, effectInfo in self.effectResManager:pairs(battle.EffectResType.FollowSprite) do
		effectInfo.spr:objToHideEff(flag, self)
	end

	gRootViewProxy:notify("setBuffIconVisible", self, true)
end

function BattleSprite:setGLProgram(programName)
	self.sprite:setGLProgram(programName)

	for k, tt in pairs(self.buffEffectsMap) do
		if tt.sprite then
			tt.sprite:setGLProgram(programName)
		end
	end
end

function BattleSprite:setScale(value, force)
	self.scaleX = nil
	self.scaleY = nil

	cc.Node.setScale(self, 1)

	if value ~= self._scale or force then
		self._scale = value

		self:setScaleX(self.faceTo * value, force)
		self:setScaleY(value, force)
	end
end

function BattleSprite:setShowFaceTo(faceTo)
	if faceTo > 0 and self._scaleX > 0 then
		return
	end

	if faceTo < 0 and self._scaleX < 0 then
		return
	end

	if self._scaleX or self._scaleX == 0 then
		self._scaleX = faceTo > 0 and 1 or -1
	else
		self._scaleX = -self._scaleX
	end

	local sx = self.sprite:getScaleX()

	self.sprite:setScaleX(-sx)
end

function BattleSprite:setScaleX(value, force)
	cc.Node.setScaleX(table.getraw(self), 1)

	if value ~= self._scaleX or force then
		self._scaleX = value

		self:curShowSprite():setScaleX(value * self.unitCfg.scaleX * self.unitCfg.scale * self.unitCfg.scaleC)
	end
end

function BattleSprite:setScaleY(value, force)
	cc.Node.setScaleY(table.getraw(self), 1)

	if value ~= self._scaleY or force then
		self._scaleY = value

		self:curShowSprite():setScaleY(value * self.unitCfg.scale * self.unitCfg.scaleC)
	end
end

function BattleSprite:getScale()
	return self._scale or 1
end

function BattleSprite:getScaleX()
	return self._scaleX or 1
end

function BattleSprite:getScaleY()
	return self._scaleY or 1
end

function BattleSprite:getMovePosZ()
	return self.battleMovePosZ
end

function BattleSprite:getPosBySeat(seat)
	local x, y

	if seat < 0 then
		x, y = battle.StandingPos[99].x, battle.StandingPos[99].y
	elseif seat <= 6 or seat > 12 then
		x, y = battle.StandingPos[seat].x, battle.StandingPos[seat].y
	else
		x, y = display.width - battle.StandingPos[seat - 6].x, battle.StandingPos[seat - 6].y
	end

	return x + self.posAdjust:get().x, y + self.posAdjust:get().y
end

function BattleSprite:getSelfPos()
	return self:getPosBySeat(self:getSeat())
end

function BattleSprite:setCurPos(ccpos)
	self.posXY = ccpos
end

function BattleSprite:getCurPos()
	return self.posXY.x, self.posXY.y
end

function BattleSprite:curPosEqual(x, y)
	return self.posXY.x == x and self.posXY.y == y
end

function BattleSprite:getAttackPos(posIdx, adjust, attackFriendFix)
	local x, y
	local attackFriendFaceto = attackFriendFix and -1 or 1

	posIdx = posIdx or battle.AttackPosIndex.selfPos

	if posIdx == battle.AttackPosIndex.selfPos then
		return self:getSelfPos()
	elseif posIdx <= 6 or posIdx == battle.AttackPosIndex.center then
		x, y = battle.AttackPos[posIdx].x, battle.AttackPos[posIdx].y
	else
		x, y = display.width - battle.AttackPos[posIdx - 6].x, battle.AttackPos[posIdx - 6].y
	end

	local scaleC = 1

	if self.unitCfg.scaleCMode == 1 then
		scaleC = self.unitCfg.scaleC
	end

	x, y = x + self.faceTo * adjust.x * scaleC * attackFriendFaceto, y + adjust.y - 1

	return x, y
end

function BattleSprite:getProtectPos(posIdx, adjust)
	local x, y

	if posIdx <= 6 or posIdx >= 13 then
		x, y = battle.ProtectPos[posIdx].x, battle.ProtectPos[posIdx].y
	else
		x, y = display.width - battle.ProtectPos[posIdx - 6].x, battle.ProtectPos[posIdx - 6].y
	end

	local scaleC = 1

	if self.unitCfg.scaleCMode == 1 then
		scaleC = self.unitCfg.scaleC
	end

	x, y = x + self.faceTo * adjust.x * scaleC, y + adjust.y - 1

	return x, y
end

function BattleSprite:updHitPanel()
	local panel = self.battleView:onViewProxyCall("getObjHitPanel", self.seat)

	if panel then
		panel:setVisible(true)
		panel:setEnabled(true)
		panel:setTouchEnabled(true)

		local posx, posy = self:getSelfPos()
		local hitPos = self.model.unitCfg.everyPos.hitPos

		posx = posx + hitPos.x
		posy = posy + hitPos.y

		panel:setAnchorPoint(0.5, 0)
		panel:setPosition(posx, posy)

		local size = self.model.unitCfg.rectSize

		panel:setContentSize(cc.size(size.x, size.y))
	end
end

function BattleSprite:onUpdate(delta)
	return self.effectManager:update(delta)
end

function BattleSprite:onChangeDeathEffect(effect)
	self.deathEffect = effect
end

function BattleSprite:getActionName(state)
	local data

	if not self.actionTable[state] then
		return state
	end

	for _, listData in self.actionTable[state]:pairs() do
		if not listData.linkSpine then
			data = listData

			break
		end

		if self.unitRes and listData.linkSpine[self.unitRes] == true then
			data = listData

			break
		end
	end

	return data and data.action or state
end

function BattleSprite:setActionState(state, onComplete)
	if not state then
		return
	end

	if self.actionState == "win_loop" then
		return
	end

	if self.actionState == state then
		if not battle.LoopActionMap[state] then
			if not self.actionCompleteCallback then
				self.actionCompleteCallback = onComplete
			end

			self:onPlayState(state)
		end

		return
	end

	if self.actionCompleteCallback then
		self.actionCompleteCallback()
	end

	self.actionState = state
	self.actionCompleteCallback = onComplete

	self:onPlayState(state)
end

function BattleSprite:onPlayState(state)
	if not state then
		return
	end

	local action = self:getActionName(state)
	local ok = self.sprite:play(action)

	if not ok and self.actionCompleteCallback then
		errorInWindows(action .. " no such animation in " .. self.sprite.__aniRes)

		local func = self.actionCompleteCallback

		self.actionCompleteCallback = nil

		func()
	end
end

function BattleSprite:addActionCompleteListener(cb)
	self.actionCompleteCallback = self.actionCompleteCallback and callbacks.new(self.actionCompleteCallback, cb) or cb

	return self.actionCompleteCallback
end

function BattleSprite:showGuide(str, lastTime, cfg)
	local w = 368
	local h = 162

	if not self.qipao then
		self.qipao = newCSpriteWithOption()

		self.qipao:setContentSize(cc.size(w, h))

		local lpos = self.unitCfg.everyPos.lifePos

		self.qipao:addTo(self.battleView.gameLayer, battle.SpriteLayerZOrder.qipao):xy(cc.p(self:getPositionX() + lpos.x + cfg.topPosX, self:getPositionY() + lpos.y + 20 + cfg.topPosY)):anchorPoint(1, 0)

		local qipaoDi = cc.Scale9Sprite:create("city/gate/bg_dialog.png")

		qipaoDi:setCapInsets(CCRectMake(40, 60, 1, 1))
		qipaoDi:size(cc.size(w, h))
		qipaoDi:xy(cc.p(w / 2, h / 2))
		self.qipao:add(qipaoDi)

		if self.force == 1 then
			qipaoDi:setScaleX(-1)
			self.qipao:xy(cc.p(lpos.x + w, lpos.y + 20))
		end
	end

	self.qipao:show()
	self.qipao:removeChildByName("richText")

	local richtext = rich.createWithWidth("#C0x5b545b#" .. str, 30, deltaSize, w - 35)

	richtext:setAnchorPoint(cc.p(0, 1))

	local height = richtext:getContentSize().height

	richtext:xy(25, h - (h - 17 - height) / 2)
	self.qipao:add(richtext, 3, "richText")
	transition.executeSequence(self.qipao):delay((lastTime or 1000) / 1000):func(function()
		if self.qipao then
			self.qipao:hide()
		end
	end):done()
end

function BattleSprite:resetPos()
	self:setVisible(true)
	self:setLocalZOrder(self.posZ:get())
	self:setRotation(0)
	self:stopAllActions()
	self:setActionState(battle.SpriteActionTable.standby)
	self:moveToPosIdx(self:getSeat())
	self:setScaleX(self.forceFaceTo)
	self:setScaleY(1)
end

function BattleSprite:resetActionTab()
	self.actionTable = {}

	for _, action in pairs(battle.SpriteActionTable) do
		if action ~= battle.SpriteActionTable.death then
			self:onPushAction(action, action)
		end
	end
end

function BattleSprite:isComeBacking(bool)
	if bool ~= nil then
		self.comeBacking = bool
	end

	return self.comeBacking
end

function BattleSprite:stopAllHolderAction()
	for typ, effect in pairs(self.buffEffectHolderMap) do
		if effect.isPlayId then
			for _, v in effect.datas:pairs() do
				if v.id == effect.isPlayId then
					self:onPlayBuffHolderAction(typ, v, true)

					effect.isPlayId = nil

					break
				end
			end
		end
	end
end

function BattleSprite:onSetSpriteVisible(visible, reason, isOver)
	if self.changeImageSprite then
		self.sprite:setVisible(false)
	end

	if visible ~= nil and reason ~= nil then
		self.spriteVisible:set(visible, reason, isOver)
	end

	self:curShowSprite():setVisible(self.spriteVisible:get())
end

function BattleSprite:getCurShowSpriteVisible()
	return self:curShowSprite():isVisible()
end

function BattleSprite:getSpriteVisible()
	return self.sprite:isVisible()
end

function BattleSprite:getPosAdjust()
	local offsetPos = self.args.offsetPos or cc.p(0, 0)

	return cc.p(self.forceFaceTo * offsetPos.x, offsetPos.y)
end

function BattleSprite:getBeAttackPosAdjust()
	return cc.p(0, 0)
end

function BattleSprite:updateFaceTo(force)
	self.force = force
	self.forceFaceTo = self.force == 1 and 1 or -1
	self.faceTo = self.forceFaceTo

	self:setScaleX(self.forceFaceTo)
end

function BattleSprite:setVisibleEnable(enable)
	self.canSetVisible = enable
end

function BattleSprite:setVisible(visible)
	if not self.canSetVisible or self:isVisible() == visible then
		return
	end

	cc.Node.setVisible(table.getraw(self), visible)
	self.battleView:onViewProxyNotify("updateSpriteLinkVisible", self.key)
end

function BattleSprite:addReplaceView(view, tag)
	self.replaceView = view
end

function BattleSprite:removeReplaceView(view)
	self.replaceView = nil
end

function BattleSprite:checkSceneTag(tag)
	return
end

function BattleSprite:getRealUseView()
	local view = self

	if self.replaceView and self.replaceView:checkSceneTag(self.skillSceneTag:back()) then
		view = self.replaceView
	end

	return view
end

function BattleSprite:pushApplySkillSceneTag(args)
	self.skillSceneTag:push_back(args)
end

function BattleSprite:popApplySkillSceneTag()
	self.skillSceneTag:pop_back()
end

function BattleSprite:showHero(isShow, args)
	if args.obj then
		self.groundRingVisible:set(isShow and self.key == args.obj)
		self.groundRing:setVisible(self.groundRingVisible:get())
		self.natureQuan:setVisible(false)
	end

	self.lifebar:setVisible(isShow and not args.hideLife)
	self:setVisible(isShow)
end

function BattleSprite:addFollowSpr(spr, args)
	return self.effectResManager:add(battle.EffectResType.FollowSprite, spr.key, nil, {
		id = spr.key,
		spr = spr
	})
end

function BattleSprite:removeFollowSpr(spr)
	self.effectResManager:remove(battle.EffectResType.FollowSprite, spr.key, spr.key)
end

function BattleSprite:sceneDelFollowObj(layer)
	for _, effectInfo in self.effectResManager:pairs(battle.EffectResType.FollowSprite) do
		gRootViewProxy:notify("sceneDelObj", effectInfo.spr.key)
	end
end

function BattleSprite:sceneDelObj(layer)
	self.effectManager:clear()
	self:unscheduleUpdate()
	self:retain()
	self:sceneDelFollowObj(layer)
	self:removeSelf()
	layer:addChild(self)
	self:release()
end

function BattleSprite:onShadeByShadow()
	self.natureQuan:show()
	self.natureQuan.canSelect:hide()
	self.natureQuan.textDi:hide()
	self.natureQuan.cantSelect:show()
end

function BattleSprite:onAddCantSelect(effectRes, effectAni)
	self.natureQuan.cantSelect:removeSelf()

	self.natureQuan.cantSelect = self:initQuan(effectRes, effectAni, 2)
end

function BattleSprite:curShowSprite()
	if self.changeImageSprite then
		return self.changeImageSprite
	end

	return self.sprite
end

function BattleSprite:isInBuffPanel()
	return true
end

local EmptyProxyMeta = setmetatable({}, {
	__index = function()
		return function()
			return
		end
	end
})

function BattleSprite:aniEffectProxy(key, playID)
	if self.aniEffectPlayIDMap[key] and playID < self.aniEffectPlayIDMap[key] then
		return EmptyProxyMeta
	end

	self.aniEffectPlayIDMap[key] = playID

	return self
end

function BattleSprite:aniEffectCall(key, playID, func)
	if self.aniEffectPlayIDMap[key] and playID < self.aniEffectPlayIDMap[key] then
		return EmptyProxyMeta
	end

	self.aniEffectPlayIDMap[key] = playID

	return func()
end

function BattleSprite:onPushAction(state, action, from, linkSpine)
	if self.actionTable[state] == nil then
		self.actionTable[state] = CList.new()
	end

	self.actionTable[state]:push_front({
		action = action,
		from = from,
		linkSpine = linkSpine
	})
end

function BattleSprite:onPopAction(state, from)
	if self.actionTable[state] == nil then
		return
	end

	for k, v in self.actionTable[state]:pairs() do
		if v.from == from then
			self.actionTable[state]:erase(k)

			break
		end
	end
end

function BattleSprite:setSkin(skinName)
	skinName = skinName or self.unitCfg.skin or "default"

	local ani = self.sprite:getAni()

	ani:setSkin(skinName)
	ani:setToSetupPose()
end

function BattleSprite:setStartActionAndPos()
	self:setActionState("standby_loop")

	self.startYinyingPos = self.sprite:getBonePosition("yinying")
end

require("battle.views.sprite_normal")
require("battle.views.sprite_effect")
require("battle.views.sprite_proxy")
require("battle.views.sprite_debug")
require("battle.views.sprite_controller")
