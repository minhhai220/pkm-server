-- chunkname: @src.battle.views.sprite_effect

local HolderActionPlayType = {
	deferCallBack = 1,
	normal = 0
}

local function effectEvents(processID, cfg)
	if cfg == nil then
		return {}
	end

	local delay = cfg.delay
	local ret = {}

	for key, fields in pairs(battle.EffectEventArgFields) do
		if cfg[fields[1]] then
			local args = {
				delay = delay,
				processID = processID
			}

			for _, field in ipairs(fields) do
				args[field] = csvClone(cfg[field])
			end

			ret[key] = args
		end
	end

	return ret
end

local function insertEffect(tb, effect)
	if effect then
		table.insert(tb, effect)
	end
end

local function checkEventsCanPlay(id, tab, typ)
	if not tab then
		return true
	end

	if not tab[id] then
		return true
	end

	if not tab[id][typ] then
		return true
	end

	return false
end

local function checkEffectEventCheat(effectID)
	if ANTI_AGENT then
		return
	end

	checkSpecificCsvCheat("effect_event", itertools.ivalues({
		effectID
	}))
end

local function addEffectEvents(self, eventID)
	local info = self:popEffectInfo(eventID)
	local customInfo = self:popCustomEffectInfo(eventID)

	if customInfo then
		for effectType, args in pairs(customInfo) do
			insertEffect(self.battleView.effectJumpCache, self.battleView:onEventEffect(self.key, effectType, args))
		end
	end

	if eventID == 1 and info == nil then
		return
	end

	local effectID, processID

	if info then
		effectID, processID = info.effectID, info.processID
	else
		effectID = gEffectByEventCsv[eventID]
	end

	if self:popIgnoreEffect(processID, eventID) then
		return
	end

	local effectCfg = csv.effect_event[effectID]
	local processArgs = self:getProcessArgs(processID)

	log.battle.sprite.event({
		eventID = eventID,
		effectID = effectID,
		processID = processID
	})

	if effectCfg then
		checkEffectEventCheat(effectID)

		if not self.battleView:getEffectEventEnable() then
			self:dealJumpSkillEffect(processArgs)

			return
		end

		if processArgs then
			local battleView = self.battleView
			local events = effectEvents(processID, effectCfg)

			for type, oneEventArgs in pairs(events) do
				for i, obj in ipairs(processArgs.viewTargets) do
					local objSpr = battleView:onViewProxyCall("getSceneObj", tostring(obj))

					if not objSpr.canHideAllEffect then
						local args = clone(oneEventArgs)

						args.effectID = effectID
						args.processArgs = processArgs

						if not args.targets then
							args.targets = {}
						end

						table.insert(args.targets, objSpr)

						if type == "follow" then
							args.index = i
							args.faceTo = obj.faceTo
						else
							args.faceTo = self.faceTo
						end

						args.fromSprite = self

						if type == "music" then
							type = "sound"
						end

						local isSelfEffect = type == "effect" and args.effectType == 0

						if checkEventsCanPlay(obj.id, processArgs.ignoreEvenet, type) then
							if not isSelfEffect then
								insertEffect(battleView.effectJumpCache, battleView:onEventEffect(obj, type, args))
							end
						else
							self:dealCantPlayEffect(processArgs, obj)
						end

						if type == "cutting" then
							break
						end
					end
				end
			end

			if processArgs.otherTargets and effectCfg.onlyTargetShow then
				for seat, obj in pairs(processArgs.otherTargets) do
					insertEffect(battleView.effectJumpCache, battleView:onEventEffectByObj(obj, "show", {
						show = {
							{
								hide = true
							}
						}
					}))
				end
			end

			if processArgs.deferList and processArgs.deferList[processArgs.process.id] then
				insertEffect(battleView.effectJumpCache, battleView:onEventEffect(obj, "callback", {
					delay = 0,
					func = function()
						battleView:runDefer(processArgs.deferList[processArgs.process.id])
					end
				}))
			end
		else
			self:onAddEffectsByCsv(processID, effectID, effectCfg)
		end

		if effectCfg.otherEventIDs then
			for _, eventID in ipairs(effectCfg.otherEventIDs) do
				addEffectEvents(self, eventID)
			end
		end
	elseif eventID ~= 1 then
		printWarn("no effect_event eventID= %s, effectID= %s, processID= %s", eventID, effectID, processID)
	end
end

local function revertScaleWhenAniOver(self, aniName)
	local scale = self.spineActionScales[aniName]

	if scale and self.spinePrevAction == aniName then
		self:setScaleX(self._scaleX, true)
		self:setScaleY(self._scaleY, true)

		self.spinePrevAction = nil
	end
end

local function getBuffEffectKey(effectRes, aniName, effectAniType, assignLayer)
	aniName = aniName or "effect_loop"
	assignLayer = assignLayer or -1

	local effectKey = string.format("%s|%s", effectRes, assignLayer)

	if effectAniType == 0 then
		effectKey = string.format("%s|%s|%s", effectRes, assignLayer, aniName)
	end

	return effectKey
end

function BattleSprite:getProcessArgs(processID)
	return self.effectProcessArgs[processID]
end

function BattleSprite:dealJumpSkillEffect(processArgs)
	if processArgs then
		for _, obj in ipairs(processArgs.viewTargets) do
			if processArgs.values then
				local valueArgs = processArgs.values[obj.id]

				if valueArgs then
					for k, v in ipairs(valueArgs) do
						self.battleView:filter(battle.FilterDeferListTag.cantJump):runDefer(v and v.deferList)
					end
				end
			end
		end

		if processArgs.deferList and processArgs.deferList[processArgs.process.id] then
			insertEffect(self.battleView.effectJumpCache, self.battleView:onEventEffect(obj, "callback", {
				delay = 0,
				func = function()
					self.battleView:filter(battle.FilterDeferListTag.cantJump):runDefer(processArgs.deferList[processArgs.process.id])
				end
			}))
		end
	end
end

function BattleSprite:dealCantPlayEffect(processArgs, obj)
	if processArgs and processArgs.values then
		local valueArgs = processArgs.values[obj.id]

		if not valueArgs then
			return
		end

		for _, data in ipairs(valueArgs) do
			insertEffect(self.battleView.effectJumpCache, self.battleView:onEventEffect(obj, "callback", {
				delay = 0,
				func = function()
					self.battleView:filter(battle.FilterDeferListTag.cantJump):runDefer(data.deferList)
				end
			}))
		end
	end
end

local respondEvent = {
	[sp.EventType.ANIMATION_EVENT] = function(self, eventArgs)
		local eventID = eventArgs.eventData.intValue

		addEffectEvents(self, eventID)
	end,
	[sp.EventType.ANIMATION_START] = function(self, eventArgs)
		local aniName = eventArgs.animation
		local scale = self.spineActionScales[aniName]

		if scale then
			self.sprite:setScaleX(scale)
			self.sprite:setScaleY(scale)

			self.spinePrevAction = aniName
		end

		performWithDelay(self, function()
			addEffectEvents(self, 1)
		end, 0)
	end,
	[sp.EventType.ANIMATION_INTERRUPT] = function(self, eventArgs)
		return revertScaleWhenAniOver(self, eventArgs.animation)
	end,
	[sp.EventType.ANIMATION_END] = function(self, eventArgs)
		return revertScaleWhenAniOver(self, eventArgs.animation)
	end,
	[sp.EventType.ANIMATION_COMPLETE] = function(self, eventArgs)
		if battle.LoopActionMap[eventArgs.animation] then
			return
		end

		if self.actionCompleteCallback then
			self.actionCompleteCallback(eventArgs.animation, eventArgs.loopCount)

			self.actionCompleteCallback = nil
		end
	end
}

function BattleSprite:onSpriteEvent(event, eventArgs)
	respondEvent[event](self, eventArgs)
end

function BattleSprite:setSpineEffectMapRound(roundID)
	self.spineEffectMapRound = roundID
end

function BattleSprite:popEffectInfo(eventID)
	if not self.spineEventMap[self.spineEffectMapRound] then
		return
	end

	local usedView = self:getRealUseView()
	local ret = self.spineEventMap[self.spineEffectMapRound][usedView and usedView.actionState or self.actionState]

	if ret and #ret > 0 then
		for k, v in ipairs(ret) do
			if v.eventID == eventID then
				return table.remove(ret, k)
			end
		end
	end
end

function BattleSprite:saveEffectInfo(roundID, action, processID, effectID)
	local effectCfg = csv.effect_event[effectID]

	if not effectCfg or not effectCfg.eventID then
		return
	end

	self.spineEventMap[roundID] = self.spineEventMap[roundID] or {}
	self.spineEventMap[roundID][action] = self.spineEventMap[roundID][action] or {}

	table.insert(self.spineEventMap[roundID][action], {
		processID = processID,
		effectID = effectID,
		eventID = effectCfg.eventID
	})
end

function BattleSprite:saveCustomEffectInfo(roundID, eventID, args)
	self.spineEventMap[roundID] = self.spineEventMap[roundID] or {}
	self.spineEventMap[roundID].customEvent = self.spineEventMap[roundID].customEvent or {}
	self.spineEventMap[roundID].customEvent[eventID] = args
end

function BattleSprite:popCustomEffectInfo(eventID)
	if not self.spineEventMap[self.spineEffectMapRound] then
		return
	end

	if not self.spineEventMap[self.spineEffectMapRound].customEvent then
		return
	end

	local effectInfo = self.spineEventMap[self.spineEffectMapRound].customEvent[eventID]

	self.spineEventMap[self.spineEffectMapRound].customEvent[eventID] = nil

	return effectInfo
end

function BattleSprite:saveIgnoreEffect(roundID, processID, effectID)
	local effectCfg = csv.effect_event[effectID]

	if not effectCfg or not effectCfg.eventID then
		return
	end

	self.ignoreEffectMap = self.ignoreEffectMap or {}
	self.ignoreEffectMap[roundID] = self.ignoreEffectMap[roundID] or {}

	table.insert(self.ignoreEffectMap[roundID], {
		processID = processID,
		effectID = effectID,
		eventID = effectCfg.eventID
	})
end

function BattleSprite:popIgnoreEffect(processID, eventID)
	local roundID = self.spineEffectMapRound

	if not self.ignoreEffectMap or not self.ignoreEffectMap[roundID] then
		return false
	end

	for k, v in ipairs(self.ignoreEffectMap[roundID]) do
		if v.eventID == eventID and (v.processID == processID or not processID) then
			table.remove(self.ignoreEffectMap[roundID], k)

			return true
		end
	end

	return false
end

function BattleSprite:onProcessArgs(processID, args)
	if not args.viewTargets then
		args.viewTargets = args.targets
	end

	for _, obj in ipairs(args.targets) do
		local protectData = obj:getEventByKey(battle.ExRecordEvent.protectTarget)

		if protectData and protectData.showProcess then
			local protectObj = protectData.obj

			if not itertools.include(args.viewTargets, protectObj) then
				table.insert(args.viewTargets, protectObj)

				if args.values and not args.values[protectObj.id] and args.values[obj.id] then
					args.values[protectObj.id] = clone(args.values[obj.id])

					for k, v in pairs(args.values[protectObj.id]) do
						v.value = battleEasy.valueTypeTable()
					end
				end
			end
		end
	end

	self.effectProcessArgs[processID] = args
end

function BattleSprite:onProcessDel(processID)
	self.effectProcessArgs[processID] = nil
end

function BattleSprite:setSkillJumpSwitch(switch)
	self.skillJumpSwitchOnce = switch
end

function BattleSprite:onEventEffect(type, args)
	local target = args.target or self
	local effect = newEventEffect(type, self, args, target)

	return self.effectManager:addAndPlay(nil, effect)
end

function BattleSprite:onEventEffectQueue(type, args)
	local target = self
	local effect = newEventEffect(type, self, args, target)

	return self.effectManager:queueAppend(effect)
end

function BattleSprite:onEventEffectCancel(effect)
	if effect.key then
		self.effectManager:delAndStop(effect.key)
	elseif effect.queID then
		self.effectManager:queueErase(effect.queID)
	end
end

function BattleSprite:onCleanEffectCache()
	local curActionState = self.actionState

	if self.spineEventMap[self.spineEffectMapRound] then
		for action, actionTab in pairs(self.spineEventMap[self.spineEffectMapRound]) do
			self.actionState = action

			while next(actionTab) do
				local _, data = next(actionTab)

				addEffectEvents(self, data.eventID)
			end
		end
	end

	self.actionState = curActionState

	for k, v in ipairs(self.battleView.effectJumpCache) do
		self.battleView:onEventEffectCancel(v)
	end

	self.battleView.effectJumpCache = {}

	local units = self.battleView:onViewProxyCall("getSceneAllObjs")

	for k1, v1 in pairs(units) do
		if v1.spineEventMap[self.spineEffectMapRound] then
			v1.spineEventMap[self.spineEffectMapRound] = nil
		end

		for k, v in ipairs(v1.effectJumpCache) do
			v1:onEventEffectCancel(v)
		end
	end

	self.effectJumpCache = {}

	if self.ignoreEffectMap and self.ignoreEffectMap[self.spineEffectMapRound] then
		self.ignoreEffectMap[self.spineEffectMapRound] = nil
	end

	self:onUltJumpEnd()
end

function BattleSprite:globalEventEffectQueue(type, args)
	return self.battleView:onEventEffectQueueFor(self, type, args)
end

function BattleSprite:onAddEventEffect(type, args, noQueue)
	if self.battleView:onViewProxyCall("isMergeEffectRunning") then
		return self:onEventEffectQueue(type, args)
	elseif not noQueue then
		return self:globalEventEffectQueue(type, args)
	else
		return self:onEventEffect(type, args)
	end
end

function BattleSprite:onAddEffectsByCsv(processID, effectID, effectCfg, selects)
	local target = self
	local events = effectEvents(processID, effectCfg)

	for type, args in pairs(events) do
		if selects == nil or selects[type] then
			args.effectID = effectID
			args.faceTo = self.faceTo

			function args.onComplete()
				return
			end

			local effect = newEventEffect(type, self, args, target)

			insertEffect(self.effectJumpCache, self.effectManager:addAndPlay(nil, effect))
		end
	end
end

local EffectPositionByPosFuncs = {
	[0] = function(sprite, offsetPos)
		local pos = sprite.startYinyingPos
		local yinYingPos = cc.p(pos.x * sprite:getScaleX(), pos.y)

		return cc.pAdd(yinYingPos, offsetPos)
	end,
	function(sprite, offsetPos)
		local headPos = sprite.unitCfg.everyPos.headPos

		return cc.pAdd(headPos, offsetPos)
	end,
	function(sprite, offsetPos)
		local hitPos = sprite.unitCfg.everyPos.hitPos

		return cc.pAdd(hitPos, offsetPos)
	end,
	function(sprite, offsetPos)
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2

		cx = sprite.model.force == 1 and cx or display.width - cx

		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos)
	end,
	function(sprite, offsetPos)
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2

		cx = sprite.model.force == 1 and display.width - cx or cx

		return cc.pAdd(cc.p(cx, battle.StandingPos[2].y), offsetPos)
	end,
	function(sprite, offsetPos)
		return cc.pAdd(cc.p(battle.StandingPos[13].x, battle.StandingPos[2].y), offsetPos)
	end,
	function(sprite, offsetPos)
		local heroPos = {}

		heroPos.x, heroPos.y = sprite:xy()

		return cc.pAdd(heroPos, offsetPos)
	end,
	function(sprite, offsetPos)
		local forcePos = -230

		if sprite.model.force == 2 then
			forcePos = -forcePos
		end

		local basePos = cc.p(battle.StandingPos[13].x + forcePos, battle.StandingPos[2].y + 840)

		return cc.pAdd(basePos, offsetPos)
	end,
	function(sprite, offsetPos)
		local cx = (battle.StandingPos[2].x + battle.StandingPos[5].x) / 2

		cx = sprite.model.force == 1 and cx or display.width - cx

		local selfPosX, selfPosY = sprite:getSelfPos()

		return cc.pAdd(cc.p(cx, selfPosY), offsetPos)
	end
}
local OverlayEffects = {
	[battle.BuffOverlayType.Coexist] = true,
	[battle.BuffOverlayType.Overlay] = true,
	[battle.BuffOverlayType.OverlayDrop] = true
}
local EffectScaleNum = 2

function BattleSprite:addBuffEffect(effectRes, pos, deep, cfgOffsetPos, aniName, showEffect, selfTurn, effectAniType, overlayType, assignLayer, buffArgs)
	if not effectRes or effectRes == "" then
		return
	end

	if self.battleView.DEBUG_BATTLE_HIDE then
		return
	end

	local effectMapKey = self:getEffectMapKey(pos)
	local effectKey = getBuffEffectKey(effectRes, aniName, effectAniType, assignLayer)
	local sprite, isNew = self.effectResManager:add(effectMapKey, effectKey, effectRes, {
		id = buffArgs.id,
		pos = pos,
		cfgId = buffArgs.cfgId,
		showEffect = showEffect,
		justRefresh = buffArgs.justRefresh
	})

	if not sprite then
		return
	end

	if isNew then
		sprite:scale(EffectScaleNum)
	end

	if sprite and OverlayEffects[overlayType] and not isNew then
		return sprite:play(aniName)
	end

	if sprite:play(aniName) == false then
		sprite:play("effect")
	end

	local layerEffectX, layerEffectY = 0, 0

	if isNew then
		local useLayer = self.battleView:getAssignLayer(assignLayer)

		if useLayer then
			local posZ = deep

			if assignLayer == battle.AssignLayer.gameLayer then
				local lineNum = 10000
				local posIdx = math.floor(deep / lineNum)
				local rate = 1

				if posIdx == 0 then
					posZ = deep / lineNum * (display.height - battle.StandingPos[1].y)
				elseif posIdx == 3 then
					posZ = deep - lineNum * posIdx + (display.height - battle.StandingPos[3].y)
				else
					posZ = (deep / lineNum - posIdx) * (battle.StandingPos[posIdx].y - battle.StandingPos[posIdx + 1].y) + (display.height - battle.StandingPos[posIdx].y)
				end
			end

			useLayer:add(sprite)
			sprite:setLocalZOrder(posZ)

			if pos < 3 then
				layerEffectX, layerEffectY = self:getCurPos()
			end
		else
			self:add(sprite, deep)
		end
	end

	local offsetPos = cc.p(cfgOffsetPos.x - layerEffectX, cfgOffsetPos.y - layerEffectY)

	if self.model.force == 2 then
		offsetPos = cc.p(-offsetPos.x, offsetPos.y)
	end

	local effectPosition = EffectPositionByPosFuncs[pos](self, offsetPos)
	local show = battleEasy.ifElse(self.lockEffectSwitch, true, showEffect)
	local flipVal = battleEasy.ifElse(cfgOffsetPos.flip, -1, 1)

	if cfgOffsetPos.staticTurn then
		sprite:setScaleX(flipVal * EffectScaleNum)
	else
		sprite:setScaleX(flipVal * self.faceTo * EffectScaleNum)
	end

	sprite:setPosition(effectPosition)
end

function BattleSprite:deleteBuffEffect(effectRes, aniName, pos, effectAniType, assignLayer, buffArgs)
	if not effectRes or effectRes == "" then
		return
	end

	local effectMapKey = self:getEffectMapKey(pos)
	local effectKey = getBuffEffectKey(effectRes, aniName, effectAniType, assignLayer)
	local sprite = self.effectResManager:remove(effectMapKey, effectKey, buffArgs.id)

	if sprite then
		if self.effectResManager:isEmpty(battle.EffectResType.FollowToScale) then
			self:unscheduleUpdate()
		end

		removeCSprite(sprite)
	end

	self:cleanBuffEffects(buffArgs.id)
end

local HolderAction_ = "HolderAction"

local function sortVisibleArgs(isOver, args)
	if type(args) == "boolean" then
		return battleEasy.ifElse(not isOver, args, not args)
	end

	if args == nil then
		return isOver
	end

	if args.isShow == nil then
		return isOver
	end

	return battleEasy.ifElse(not isOver, args.isShow, not args.isShow)
end

local function orderVisibleByKey(effectResManager, resType, isOver, args, extraArgs)
	local switch = sortVisibleArgs(isOver, args)
	local key = HolderAction_ .. extraArgs.id

	local function addCheck(resKey, effectInfo)
		return true
	end

	if args.hideByCfgId then
		local map = {}

		for k, v in ipairs(args.hideByCfgId) do
			map[v] = true
		end

		function addCheck(resKey, effectInfo)
			for _, data in effectResManager:pairsInfo(resType, resKey) do
				if map[data.cfgId] then
					return true
				end
			end

			return false
		end
	end

	if isOver then
		effectResManager:setPower(resType, "visible", key)
	else
		effectResManager:setPower(resType, "visible", {
			id = key,
			cfgId = extraArgs.cfgId,
			value = switch,
			addCheck = addCheck
		})
	end
end

local holderActionTypeMap = {
	hide = {
		lifebar = "hideLifebar",
		sprite = "hideSprite",
		other = "hideOthers"
	},
	hideEffect = {
		buffImmuneText = "hideBuffImmuneText",
		forceself = "hideEffectInForceSelf",
		follow = "hideFollowSprite",
		normal = "hideEffectInNormal",
		inholder = "hideEffectInHolder",
		process = "hideEffectProcess",
		forceenemy = "hideEffectInForceEnemy"
	}
}
local holderActionMap

holderActionMap = {
	pause = {
		onBuff = function(self, isOver)
			if not isOver then
				self:pauseSprite()
			else
				self:resumeSprite()
			end
		end
	},
	hideOthers = {
		onBuff = function(self, isOver, args)
			local switch = sortVisibleArgs(isOver, args)

			if switch then
				self.effectResManager:setEnv("normal")
			else
				self.effectResManager:setEnv("lockEffect")
				self:objToHideEff(false)
			end
		end
	},
	hideSprite = {
		onBuff = function(self, isOver, args, extraArgs)
			local switch = sortVisibleArgs(isOver, args)

			self:onSetSpriteVisible(switch, "hideSprite" .. extraArgs.id, isOver)
		end
	},
	hideLifebar = {
		onBuff = function(self, isOver, args, extraArgs)
			local switch = sortVisibleArgs(isOver, args)

			if isOver then
				self.lifebar:setVisibleEnable(switch)
				self.lifebar:onSetLifebarVisible(switch, "hide" .. extraArgs.id, isOver)
			else
				self.lifebar:onSetLifebarVisible(switch, "hide" .. extraArgs.id, isOver)
				self.lifebar:setVisibleEnable(switch)
			end
		end
	},
	hideBuffTextAdd = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				self.effectResManager:setPower(battle.EffectResType.BuffText, "add", HolderAction_ .. extraArgs.id)
			else
				self.effectResManager:setPower(battle.EffectResType.BuffText, "add", {
					switch = isOver,
					id = HolderAction_ .. extraArgs.id
				})
			end
		end
	},
	hideOnceEffectAdd = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				self.effectResManager:setPower(battle.EffectResType.OnceEffect, "add", HolderAction_ .. extraArgs.id)
			else
				self.effectResManager:setPower(battle.EffectResType.OnceEffect, "add", {
					switch = isOver,
					id = HolderAction_ .. extraArgs.id
				})
			end
		end
	},
	hideEffectInForceSelf = {
		onBuff = function(self, isOver, args, extraArgs)
			local force = self.model.force
			local effectResType = battle.EffectResType.BuffEffectInForceSelf

			if force == 2 then
				effectResType = battle.EffectResType.BuffEffectInForceEnemy
			end

			orderVisibleByKey(self.effectResManager, effectResType, isOver, args, extraArgs)
		end
	},
	hideEffectInForceEnemy = {
		onBuff = function(self, isOver, args, extraArgs)
			local force = self.model.force
			local effectResType = battle.EffectResType.BuffEffectInForceEnemy

			if force == 2 then
				effectResType = battle.EffectResType.BuffEffectInForceSelf
			end

			orderVisibleByKey(self.effectResManager, effectResType, isOver, args, extraArgs)
		end
	},
	hideEffectInNormal = {
		onBuff = function(self, isOver, args, extraArgs)
			orderVisibleByKey(self.effectResManager, battle.EffectResType.BuffEffectInNormal, isOver, args, extraArgs)
		end
	},
	hideEffectInHolder = {
		onBuff = function(self, isOver, args, extraArgs)
			orderVisibleByKey(self.effectResManager, battle.EffectResType.BuffEffectInHolder, isOver, args, extraArgs)
		end
	},
	hideFollowSprite = {
		onBuff = function(self, isOver, args, extraArgs)
			orderVisibleByKey(self.effectResManager, battle.EffectResType.FollowSprite, isOver, args, extraArgs)
		end
	},
	hideBuffImmuneText = {
		onBuff = function(self, isOver, args)
			local ret = sortVisibleArgs(isOver, args)

			self:setShowTextDi(ret)
		end
	},
	setObjHolderAction = {
		onBuff = function(self, isOver, args, extraArgs)
			local casterView = self.battleView:onViewProxyCall("getSceneObj", extraArgs.tostrCaster)

			if not casterView then
				return
			end

			if holderActionTypeMap[args.key] then
				for argKey, newType in pairs(holderActionTypeMap[args.key]) do
					holderActionMap[newType].onBuff(casterView, isOver, args[argKey], extraArgs)
				end
			else
				holderActionMap[args.key].onBuff(casterView, isOver, args, extraArgs)
			end
		end
	},
	move = {
		onBuff = function(self, isOver, args)
			local x, y = self:getCurPos()

			if args.absolutePos then
				x, y = battle.StandingPos[13].x, battle.StandingPos[2].y
			end

			local rate = battleEasy.ifElse(isOver, -1, 1)
			local force = battleEasy.ifElse(self.force == 1, -1, 1)
			local pos = {
				x = battleEasy.ifElse(args.x, args.x * rate * force + x, x),
				y = battleEasy.ifElse(args.y, args.y * rate + y, y)
			}

			if isOver then
				self:onAddEventEffect("moveTo", {
					a = 1000,
					speed = args.speed,
					x = pos.x,
					y = pos.y,
					knockUpBack = args.knockUpBack and true or false
				})
			else
				self:onAddEventEffect("moveTo", {
					a = 1000,
					speed = args.speed,
					x = pos.x,
					y = pos.y,
					knockUp = args.knockUp and true or false
				})
			end
		end
	},
	setPositionTo = {
		onBuff = function(self, isOver, args, extraArgs)
			local casterView = self.battleView:onViewProxyCall("getSceneObj", extraArgs.tostrCaster)
			local seat = casterView:getSeat()

			if isOver then
				self.posZ:set(nil, "setPosTo", true)
				self.posAdjust:set(nil, "setPosTo", true)
				self:moveToPosIdx(self:getSeat())
			else
				self.posZ:set(casterView.posZ:get() - 1, "setPosTo")
				self.posAdjust:set(cc.p(0, 0), "setPosTo")

				local x, y = casterView:getSelfPos()

				self:setPosition(cc.p(x, y))
				self:setCurPos(cc.p(x, y))
			end

			self:setLocalZOrder(self.posZ:get())
		end
	},
	opacity = {
		onBuff = function(self, isOver, args)
			local transParency = math.min(math.floor((args and args.value or 1) * 255), 255)

			if isOver then
				self:setSpriteOpacity(255)
			else
				self:setSpriteOpacity(transParency)
			end
		end,
		onCheck = function(self, data, item)
			if not data then
				return true
			end

			local minRate = data.args and data.args.value or 1

			if item.args and minRate > item.args.value then
				return true
			end

			return false
		end
	},
	onceEffect = {
		onBuff = function(self, isOver, args, extraArgs)
			local timePos = args.timePos or 0
			local isPlay = isOver and timePos == 1

			isPlay = isPlay or not isOver and timePos == 0

			local onceEffectOffsetPos = {
				x = 0,
				y = 0
			}

			if args.onceEffectOffsetPos then
				onceEffectOffsetPos = csvClone(args.onceEffectOffsetPos)
			end

			local onceEffectPos = args.onceEffectPos

			if args.onceEffectPosIndex == 1 then
				local casterView = self.battleView:onViewProxyCall("getSceneObj", extraArgs.tostrCaster)
				local faceTo = casterView.force == 1 and -1 or 1

				onceEffectOffsetPos.x = onceEffectOffsetPos.x * faceTo

				local pos = cc.p(battleEasy.getAttackPos(casterView.seat, onceEffectOffsetPos))

				onceEffectOffsetPos.x = pos.x
				onceEffectOffsetPos.y = pos.y
				onceEffectOffsetPos.faceTo = faceTo
				onceEffectPos = 7
			elseif args.onceEffectPosIndex == 2 then
				local casterView = self.battleView:onViewProxyCall("getSceneObj", extraArgs.tostrCaster)
				local pos = cc.p(battleEasy.getPos(casterView.seat, onceEffectOffsetPos))

				onceEffectOffsetPos.x = pos.x
				onceEffectOffsetPos.y = pos.y
				onceEffectPos = 7
			elseif args.onceEffectPosIndex == 3 then
				local faceTo = self.force == 1 and -1 or 1

				onceEffectOffsetPos.x = onceEffectOffsetPos.x * faceTo

				local pos = cc.p(battleEasy.getAttackPos(self.seat, onceEffectOffsetPos))

				onceEffectOffsetPos.x = pos.x
				onceEffectOffsetPos.y = pos.y
				onceEffectOffsetPos.faceTo = faceTo
				onceEffectPos = 7
			elseif args.onceEffectPosIndex == 4 then
				local pos = cc.p(battleEasy.getPos(self.seat, onceEffectOffsetPos))

				onceEffectOffsetPos.x = pos.x
				onceEffectOffsetPos.y = pos.y
				onceEffectPos = 7
			end

			if isPlay then
				self.battleView:onViewProxyCall("onFrameOnceEffect", {
					tostrModel = self.key,
					resPath = args.onceEffectResPath,
					aniName = args.onceEffectAniName or "effect",
					pos = onceEffectPos or 0,
					offsetPos = onceEffectOffsetPos,
					assignLayer = args.onceEffectAssignLayer or 4,
					wait = args.onceEffectWait or false,
					delay = args.onceEffectDelay or 0
				})
			end
		end
	},
	wait = {
		onBuff = function(self, isOver, args)
			local timePos = args.timePos or 0
			local isPlay = isOver and timePos == 1

			isPlay = isPlay or not isOver and timePos == 0

			if isPlay then
				self.battleView:onEventEffectQueueFront("wait", {
					lifetime = args.lifetime
				})
			end
		end
	},
	changeImage = {
		onBuff = function(self, isOver, args)
			if isOver then
				removeCSprite(self.changeImageSprite)

				self.changeImageSprite = nil

				self:onSetSpriteVisible(true, "changeImage", isOver)
			else
				self:onSetSpriteVisible(false, "changeImage")

				local resetPos = cc.p(self.sprite:getPositionX(), self.sprite:getPositionY())

				if self.changeImageSprite then
					self.changeImageSprite:removeAnimation()
				end

				local unitCfg = csv.unit[args.res]
				local unitRes = unitCfg.unitRes

				self.changeImageSprite = newCSpriteWithOption(unitRes)

				self:add(self.changeImageSprite, battle.SpriteLayerZOrder.selfSpr)
				self.changeImageSprite:setPosition(resetPos)
				self.changeImageSprite:play(battle.SpriteActionTable.standby)
				self.changeImageSprite:setScaleX(self.faceTo * unitCfg.scaleX * unitCfg.scale * unitCfg.scaleC)
				self.changeImageSprite:setScaleY(unitCfg.scale * unitCfg.scaleC)

				local ani = self.changeImageSprite:getAni()

				ani:setSkin(unitCfg.skin)
				ani:setToSetupPose()
			end
		end
	},
	shader = {
		onBuff = function(self, isOver, args)
			if isOver then
				self:curShowSprite():setGLProgram("normal")
			elseif args.switch == 4 then
				local brightnessCard = args.extraArgs[1] or {}
				local brightness = brightnessCard[self.cardID] or 0.8

				self:curShowSprite():setShihuaShader(brightness)
			else
				self:curShowSprite():setHSLShader(args.extraArgs[1], args.extraArgs[2], args.extraArgs[3], args.extraArgs[4], args.extraArgs[5], args.switch)
			end
		end
	},
	playSelfAniOnce = {
		onBuff = function(self, isOver, args, extraArgs)
			if not isOver then
				local action = self:getActionName(args.aniName)
				local hasAni = self.sprite:findAnimation(action)

				if not hasAni then
					return
				end

				local state = self.actionState

				self:setActionState(args.aniName, function()
					self.actionCompleteCallback = nil

					self:setActionState(state)
				end)
			end
		end
	},
	playAni = {
		onBuff = function(self, isOver, args, extraArgs)
			local effectMapKey = self:getEffectMapKey(args.pos)
			local effectKey = getBuffEffectKey(args.effectRes, args.aniName, args.effectAniType)
			local effectInfo = self.effectResManager:getEffectInfo(effectMapKey, effectKey)

			if not effectInfo then
				return
			end

			local sprite = effectInfo.spr
			local id = HolderAction_ .. extraArgs.id

			local function reset()
				self.effectResManager:removeResInfo(effectMapKey, effectKey, id)
			end

			if isOver then
				if args.hide then
					reset()
				end

				sprite:play(args.aniName)
			else
				self.battleView:onEventEffect(nil, "callback", {
					func = function()
						if args.hide then
							self.effectResManager:addResInfo(effectMapKey, effectKey, {
								objToHideEffVisible = false,
								id = id
							})
						else
							reset()
						end

						sprite:play(args.newAniName)
					end,
					delay = args.delay or 0
				})
			end
		end
	},
	hideLinkEffect = {
		onBuff = function(self, isOver, args)
			self.battleView:onViewProxyNotify("linkEffectForceVisible", isOver, self.force)
		end
	},
	hideSpeedRank = {
		onBuff = function(self, isOver, args)
			gRootViewProxy:notify("speedRankHideObj", self.model.id, not isOver)
		end
	},
	hideGroupObj = {
		onBuff = function(self, isOver, args)
			local groupObject = self.model.scene:getGroupObj(self.model.force, battle.SpecialObjectId.teamShiled)

			if not groupObject then
				return
			end

			local spr = self.battleView:onViewProxyCall("getSceneObj", tostring(table.getraw(groupObject)))

			if not spr then
				return
			end

			if not groupObject:isDeath() then
				spr:setVisible(isOver)
				spr:setVisibleEnable(isOver)
			end
		end
	},
	hideGroundRing = {
		onBuff = function(self, isOver, args)
			if not self.groundRing then
				return
			end

			if not isOver then
				self.groundRingVisible:set(false, "holderAction")
				self.groundRing:setVisible(self.groundRingVisible:get())
			else
				self.groundRingVisible:set(nil, "holderAction", true)
			end
		end
	},
	rayEffect = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				return
			end

			gRootViewProxy:notify("addRayEffect", extraArgs.tostrCaster, extraArgs.tostrModel, args, extraArgs.id)
		end
	},
	hideEffectProcess = {
		onBuff = function(self, isOver, args)
			local isShowAll = sortVisibleArgs(isOver, args)

			self.canHideAllEffect = not isShowAll
		end
	},
	changeShieldBar = {
		onBuff = function(self, isOver, args)
			if not isOver then
				self.lifebar:onAddSpineShield(args)
			else
				self.lifebar:onDelSpineShield()
			end
		end
	},
	showShieldBarIcon = {
		onBuff = function(self, isOver, args)
			if not isOver then
				self.lifebar:onShowIconShield()
			else
				self.lifebar:onHideIconShield()
			end
		end
	},
	playDeferList = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				return
			end

			gRootViewProxy:proxy():runDeferListWithEffect(battleEasy.keyToID(args.key, extraArgs))
		end
	},
	skin = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				self:setSkin()
			elseif args.bindUnitRes[self.unitRes] == true then
				self:setSkin(args.skin)
			end
		end,
		onCheck = function(self, data, item)
			return item.args.bindUnitRes[self.unitRes] == true
		end
	},
	comboPoint = {
		onBuff = function(self, isOver, args, extraArgs)
			if isOver then
				return
			end

			local data = {
				overlayCount = extraArgs.overlayCount,
				overlayLimit = extraArgs.overlayLimit,
				effectData = args
			}

			self.lifebar:updateComboPoint(data)
		end
	}
}

local playBuffEffects = {
	iconEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.iconResPath and csvCfg.iconResPath ~= "" then
			if buffArgs.isAdd then
				self:onDealBuffEffectsMap(csvCfg.iconResPath, buffArgs.cfgId, buffArgs.boxRes)
			end

			self:aniEffectProxy("iconEffect" .. buffArgs.cfgId, buffArgs.aniCounter):onShowBuffIcon(csvCfg.iconResPath, buffArgs.cfgId, buffArgs.overlayCount)
		end
	end,
	onceEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if not buffArgs.isOnceEffectPlayed and csvCfg.onceEffectResPath and csvCfg.onceEffectResPath ~= "" then
			self.battleView:onViewProxyCall("onFrameOnceEffect", {
				tostrModel = buffArgs.tostrModel,
				resPath = csvCfg.onceEffectResPath,
				aniName = csvCfg.onceEffectAniName,
				pos = csvCfg.onceEffectPos,
				offsetPos = csvCfg.onceEffectOffsetPos,
				assignLayer = csvCfg.onceEffectAssignLayer,
				wait = csvCfg.onceEffectWait,
				delay = csvCfg.onceEffectDelay or 0
			})
		end
	end,
	textEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if not buffArgs.args.cantShowText and csvCfg.textResPath and csvCfg.textResPath ~= "" then
			self.battleView:onEventEffect(nil, "callback", {
				func = function()
					self:onShowBuffText(csvCfg.textResPath)
				end,
				delay = csvCfg.onceEffectDelay or 0
			})
		end
	end,
	mainEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.effectResPath and csvCfg.effectResPath ~= "" then
			local aniName = csvCfg.effectAniName[buffArgs.aniSelectId]
			local effect = self.battleView:onEventEffect(nil, "callback", {
				func = function()
					if not self or not self.addBuffEffect then
						return
					end

					self:aniEffectProxy("mainEffect" .. buffArgs.cfgId, buffArgs.aniCounter):addBuffEffect(csvCfg.effectResPath, csvCfg.effectPos, csvCfg.deepCorrect, csvCfg.effectOffsetPos, aniName, csvCfg.effectShowOnAttack, buffArgs.isSelfTurn, csvCfg.effectAniChoose.type, buffArgs.csvCfg.overlayType, csvCfg.effectAssignLayer, buffArgs)
				end,
				delay = csvCfg.effectResDelay or 0
			})

			self:collectBuffEffects(buffArgs.id, effect)
		end
	end,
	dispelEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if buffArgs.dispel then
			self.battleView:onViewProxyCall("onFrameOnceEffect", {
				pos = 2,
				aniName = "effect",
				resPath = "buff/qusan/qusan.skel",
				tostrModel = buffArgs.tostrModel,
				offsetPos = csvCfg.onceEffectOffsetPos,
				assignLayer = csvCfg.onceEffectAssignLayer,
				wait = csvCfg.onceEffectWait,
				delay = csvCfg.onceEffectDelay or 0
			})
		end
	end,
	spineEffect = function(self, buffArgs, isOver)
		local spineEffectCfg = buffArgs.csvCfg.spineEffect
		local bindUnitRes = spineEffectCfg.unitRes

		if not bindUnitRes and (spineEffectCfg.skin or spineEffectCfg.action) then
			errorInWindows("spineEffect is must in %s", buffArgs.cfgId)
		end

		bindUnitRes = arraytools.hash(bindUnitRes or {
			self.unitRes
		})

		if spineEffectCfg.skin then
			if isOver then
				self:delBuffHolderAction("skin", buffArgs.id)
			else
				self:addBuffHolderAction("skin", buffArgs.id, {
					skin = spineEffectCfg.skin,
					bindUnitRes = bindUnitRes
				}, HolderActionPlayType.normal, buffArgs)
			end
		end

		if spineEffectCfg.action then
			for action, replaceAct in csvMapPairs(spineEffectCfg.action) do
				local state = battle.SpriteActionTable[action] or action

				if state == battle.SpriteActionTable.death then
					if not isOver then
						self:onChangeDeathEffect({
							res = spineEffectCfg.unitRes[1],
							action = replaceAct
						})
					end
				else
					if isOver then
						self:onPopAction(state, buffArgs.id)
					else
						self:onPushAction(state, replaceAct, buffArgs.id, bindUnitRes)
					end

					if state == self.actionState and state == battle.SpriteActionTable.standby then
						self:onPlayState(battle.SpriteActionTable.standby)
					end
				end
			end
		end
	end,
	holderActionEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.holderActionType then
			if csvCfg.holderActionType.typ then
				self:addBuffHolderAction(csvCfg.holderActionType.typ, buffArgs.id, csvCfg.holderActionType.args, csvCfg.holderActionType.playType, buffArgs, csvCfg.holderActionType.args and csvCfg.holderActionType.args.applyTarget)
			elseif csvCfg.holderActionType.list then
				local deferKey = self.battleView:pushDeferList(buffArgs.id, "holderActionType")

				for k, v in ipairs(csvCfg.holderActionType.list) do
					self:addBuffHolderAction(v.typ, buffArgs.id .. "_" .. k, v.args, v.playType, buffArgs, v.args and v.args.applyTarget)
				end

				self.battleView:runDeferToQueueFront(self.battleView:popDeferList(deferKey))
			end

			if csvCfg.holderActionType.effect then
				local revertEffect = {}

				for k, v in ipairs(csvCfg.holderActionType.effect) do
					gRootViewProxy:proxy():collectCallBack("new_battle_turn_play_ani", function()
						self:onPlayBuffHolderAction(v.typ, {
							id = buffArgs.id .. "_" .. k,
							args = v.args,
							extraArgs = buffArgs
						}, false)
					end)

					if v.revertFrame then
						table.insert(revertEffect, v)
					end
				end

				table.sort(revertEffect, function(a, b)
					return a.revertFrame < b.revertFrame
				end)

				local playCount = table.length(csvCfg.holderActionType.effect)

				for k, v in ipairs(revertEffect) do
					gRootViewProxy:proxy():collectCallBack("new_battle_turn_play_ani", function()
						self:onPlayBuffHolderAction(v.typ, {
							id = buffArgs.id .. "_" .. playCount + k,
							args = v.args,
							extraArgs = buffArgs
						}, true)
					end)
				end
			end
		end
	end,
	LinkEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.linkEffect then
			gRootViewProxy:notify("addLinkEffect", buffArgs.tostrModel, buffArgs.tostrCaster, csvCfg.linkEffect, buffArgs.id)
		end
	end,
	RayEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.rayEffect then
			gRootViewProxy:notify("addRayEffect", buffArgs.tostrCaster, buffArgs.tostrModel, csvCfg.rayEffect, buffArgs.id)
		end
	end,
	LifeBarPointEffect = function(self, buffArgs)
		local csvCfg = buffArgs.csvCfg

		if csvCfg.pointEffect then
			local data = {
				overlayCount = buffArgs.overlayCount,
				overlayLimit = csvCfg.overlayLimit,
				effectData = csvCfg.pointEffect
			}

			self:onUpdateLifebarPoint({
				buffOverLayData = data
			})
		end
	end
}

function BattleSprite:onPlayBuffAniEffect(buffArgs, aniEffects)
	if not buffArgs.csvCfg then
		return
	end

	if self.battleView.DEBUG_BATTLE_HIDE then
		return
	end

	if not aniEffects then
		for k, f in pairs(playBuffEffects) do
			f(self, buffArgs)
		end
	else
		for _, v in pairs(aniEffects) do
			playBuffEffects[v](self, buffArgs)
		end
	end
end

local TargetFinder = {
	selfForceExcludeSelf = function(self, f)
		local objs = self.battleView:onViewProxyCall("getSceneAllObjs")

		for key, spr in pairs(objs) do
			if key ~= self.key and self.force == spr.force then
				f(spr)
			end
		end
	end
}

function BattleSprite:addBuffHolderAction(typ, id, args, playType, extraArgs, applyTarget)
	if not typ then
		return
	end

	playType = playType or HolderActionPlayType.normal

	if type(args) == "table" then
		if applyTarget and TargetFinder[applyTarget] then
			TargetFinder[applyTarget](self, function(spr)
				spr:addBuffHolderAction(typ, id, args, playType, extraArgs)
			end)

			return
		end

		if holderActionTypeMap[typ] then
			for argKey, newType in pairs(holderActionTypeMap[typ]) do
				if args[argKey] then
					self:addBuffHolderAction(newType, id, args[argKey], playType, extraArgs)
				end
			end

			return
		end
	end

	if playType == HolderActionPlayType.deferCallBack then
		battleEasy.deferCallback(function()
			self:onPlayBuffHolderAction(typ, {
				id = id,
				args = args,
				extraArgs = extraArgs,
				playType = playType
			}, false)
		end)

		return
	end

	if not self.buffEffectHolderMap[typ] then
		self.buffEffectHolderMap[typ] = {
			datas = CList.new()
		}
	end

	local ret = self.buffEffectHolderMap[typ]
	local data

	for _, v in ret.datas:pairs() do
		if v.id == id then
			data = v

			break
		end
	end

	if not data then
		data = {
			ref = 0,
			id = id,
			args = args,
			idx = ret.datas.counter + 1
		}

		ret.datas:push_back(data)
	end

	data.args = args
	data.extraArgs = extraArgs
	data.ref = data.ref + 1
	data.playType = playType

	if data.ref > 1 then
		self:onPlayBuffHolderAction(typ, data, false)
	elseif data.ref == 0 then
		ret.datas:erase(data.idx)
	end
end

function BattleSprite:delBuffHolderAction(typ, id, playType, applyTarget)
	if not typ then
		return
	end

	if not self.buffEffectHolderMap[typ] then
		self.buffEffectHolderMap[typ] = {
			datas = CList.new()
		}
	end

	if playType == HolderActionPlayType.deferCallBack or playType == 2 then
		return
	end

	if applyTarget and TargetFinder[applyTarget] then
		TargetFinder[applyTarget](self, function(spr)
			spr:delBuffHolderAction(typ, id, playType)
		end)

		return
	end

	if holderActionTypeMap[typ] then
		for _, newType in pairs(holderActionTypeMap[typ]) do
			self:delBuffHolderAction(newType, id, playType)
		end

		return
	end

	local ret = self.buffEffectHolderMap[typ]
	local data, showEndAction, nextPlayIdx

	for k, v in ret.datas:pairs() do
		if v.id == id then
			data = v
			showEndAction = ret.isPlayId == id
		elseif v.ref > 0 then
			nextPlayIdx = v.idx
		end
	end

	if not data then
		data = {
			ref = 0,
			id = id,
			idx = ret.datas.counter + 1
		}

		ret.datas:push_back(data)
	end

	data.ref = data.ref - 1

	if data.ref ~= 0 then
		return
	end

	data = ret.datas:erase(data.idx)

	if showEndAction then
		if not nextPlayIdx then
			self:onPlayBuffHolderAction(typ, data, true)

			ret.isPlayId = nil
		else
			self:onPlayBuffHolderAction(typ, ret.datas:index(nextPlayIdx), false)
		end
	end
end

function BattleSprite:onPlayBuffHolderAction(typ, data, isOver)
	if not typ then
		for k, v in pairs(self.buffEffectHolderMap) do
			local actionCls = holderActionMap[k]

			if actionCls then
				local _data

				if actionCls.onCheck then
					for _, data in v.datas:pairs() do
						if data.ref > 0 and actionCls.onCheck(self, _data, data) then
							_data = data
						end
					end
				else
					_data = v.datas:back()
				end

				if _data and (v.isPlayId == nil or v.isPlayId ~= _data.id) and _data.ref > 0 then
					v.isPlayId = actionCls.onBuff(self, false, _data.args, _data.extraArgs) or _data.id
				end
			end
		end

		return
	end

	if holderActionTypeMap[typ] then
		for argKey, newType in pairs(holderActionTypeMap[typ]) do
			if type(data.args) == "table" and data.args[argKey] then
				self:onPlayBuffHolderAction(newType, {
					args = data.args[argKey],
					extraArgs = data.extraArgs
				}, isOver)
			end
		end

		return
	end

	if not holderActionMap[typ].onCheck or holderActionMap[typ].onCheck(self, nil, data) ~= false then
		local isPlayId = holderActionMap[typ].onBuff(self, isOver, data.args, data.extraArgs) or data.id

		if self.buffEffectHolderMap[typ] and data.playType ~= HolderActionPlayType.deferCallBack then
			self.buffEffectHolderMap[typ].isPlayId = isPlayId
		end
	end
end

function BattleSprite:onCloseBuffHolderAction(actionType)
	if holderActionMap[actionType] then
		local actionData = self.buffEffectHolderMap[actionType]

		if actionData and actionData.isPlayId then
			for _, item in actionData.datas:pairs() do
				if item.id == actionData.isPlayId then
					holderActionMap[actionType].onBuff(self, true, item.args, item.extraArgs)

					actionData.isPlayId = nil

					break
				end
			end
		end
	end
end

function BattleSprite:onDeleteBuffEffect(buffArgs)
	local battleView = self.battleView
	local csvCfg = buffArgs.csvCfg
	local holderActionArgs = csvCfg.holderActionType

	if holderActionArgs then
		if holderActionArgs.typ then
			self:delBuffHolderAction(holderActionArgs.typ, buffArgs.id, nil, holderActionArgs.args and holderActionArgs.args.applyTarget)
		elseif holderActionArgs.list then
			for k, v in csvPairs(holderActionArgs.list) do
				self:delBuffHolderAction(v.typ, buffArgs.id .. "_" .. k, v.playType, v.args and v.args.applyTarget)
			end
		end
	end

	self:deleteBuffEffect(csvCfg.effectResPath, csvCfg.effectAniName[buffArgs.aniSelectId], csvCfg.effectPos, csvCfg.effectAniChoose.type, csvCfg.effectAssignLayer, buffArgs)

	if csvCfg.effectOnEnd and csvCfg.effectOnEnd.res then
		battleView:onViewProxyCall("onFrameOnceEffect", {
			tostrModel = buffArgs.tostrModel,
			resPath = csvCfg.effectOnEnd.res,
			aniName = csvCfg.effectOnEnd.aniName,
			pos = csvCfg.effectOnEnd.pos or 2,
			offsetPos = csvCfg.onceEffectOffsetPos,
			assignLayer = csvCfg.onceEffectAssignLayer,
			wait = csvCfg.onceEffectWait,
			delay = csvCfg.onceEffectDelay or 0
		})
	end

	playBuffEffects.spineEffect(self, buffArgs, true)
	self:onDelBuffIcon(buffArgs.cfgId)
	self:onDelBuffShader(buffArgs)
	gRootViewProxy:notify("delLinkEffect", buffArgs.id)

	if csvCfg.pointEffect then
		self:onUpdateLifebarPoint({
			buffOverLayData = {
				overlayCount = 0
			}
		})
	end
end

function BattleSprite:onPlayBuffShader(buffArgs)
	local buffshader = buffArgs.buffshader
	local switch, extraArgs = csvNext(buffshader)
	local args = {
		buffId = buffArgs.buffId,
		switch = switch,
		extraArgs = extraArgs
	}

	self:addBuffHolderAction("shader", buffArgs.buffId, args, HolderActionPlayType.normal, buffArgs)
end

function BattleSprite:onDelBuffShader(buffArgs)
	local csvCfg = buffArgs.csvCfg

	if csvCfg.buffshader and csvSize(csvCfg.buffshader) ~= 0 then
		self:delBuffHolderAction("shader", buffArgs.cfgId)
	end
end

function BattleSprite:getEffectMapKey(pos)
	local force = self.model.force

	if pos == 4 then
		force = 3 - force
	end

	if pos == 3 or pos == 4 then
		if force == 1 then
			return battle.EffectResType.BuffEffectInForceSelf
		elseif force == 2 then
			return battle.EffectResType.BuffEffectInForceEnemy
		end
	elseif pos == 5 then
		return battle.EffectResType.BuffEffectInNormal
	end

	return battle.EffectResType.BuffEffectInHolder
end

function BattleSprite:onAddBuffHolderAction(...)
	self:addBuffHolderAction(...)
end

function BattleSprite:onDelBuffHolderAction(...)
	self:delBuffHolderAction(...)
end

function BattleSprite:updateBuffeffectsScale()
	self:scheduleUpdate(function()
		local alterScaleX = 2 * math.abs(self:getScaleX())
		local alterScaleY = 2 * self:getScaleY()

		for _, sprite in ipairs(self.buffEffectsFollowObjToScale) do
			local curScaleX = sprite:getScaleX()
			local signX = battleEasy.ifElse(1 / curScaleX > 0, 1, -1)
			local curScaleY = sprite:getScaleY()

			if alterScaleX ~= signX * curScaleX then
				sprite:setScaleX(signX * alterScaleX)
			end

			if alterScaleY ~= curScaleY then
				sprite:setScaleY(alterScaleY)
			end
		end
	end)
end

function BattleSprite:onPlayGroupShieldEffect(args)
	self:aniEffectCall("groupShield", args.aniCounter, function()
		if args.state == battle.ObjectState.normal then
			self:onReloadUnit("effectLayer", args.unitRes)
			self:setVisibleEnable(true)
			self:setVisible(true)
		elseif args.state == battle.ObjectState.realDead then
			self:onAddEventEffect("effect", {
				action = battle.SpriteActionTable.death,
				onComplete = function()
					self:setVisible(false)
					self:setVisibleEnable(false)
				end
			}, true)
		end
	end)
end
