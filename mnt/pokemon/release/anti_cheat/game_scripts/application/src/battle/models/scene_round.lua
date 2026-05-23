local SceneRoundState = {
	idel = 1,
	over = 3,
	run = 2
}
local SceneRound = class("SceneRound")

function SceneRound:ctor(scene)
	self.roundLeftHeros = {}
	self.totalRound = 0
	self.totalRoundBattleTurn = 0
	self.targets = {}
	self.seatOccupied = {}
	self.reserveSeatMap = {}
	self.reverseExAttackArray = {}
	self.ownerID = nil
	self.roundLimit = {
		0,
		0,
		0
	}
	self._scene = scene
	self._state = SceneRoundState.over
end

function SceneRound:init(buff, data, viewData)
	self.roundLeftHeros = {}
	self.totalRound = 0
	self.totalRoundBattleTurn = 0
	self.seatOccupied = {}
	self.reserveSeatMap = {}
	self.reverseExAttackArray = {}
	self.otherObjData = {}
	self.ownerID = buff.caster.id
	self.attackCount = {}
	self._state = SceneRoundState.idel
	self.buff = buff
	self.data = data
	self._extraAttackArgsGet = data.extraAttackArgsGet
	self.targetFormula = nil
	self.targets = {}
	self.roundLimit = {
		0,
		0,
		0
	}
	self._isRoundUpdate = false
	self._isSeatEmpty = false
	self._attackRule = nil
	self._autoChoose = {
		findTargetType = 0
	}
	self.viewData = viewData
end

function SceneRound:setRoundOverCondition(round, battleTurn, attackCount)
	self.roundLimit = {
		round,
		battleTurn,
		attackCount
	}
end

function SceneRound:setSiteTargets(targets, formula)
	if targets then
		self.targets = targets
	else
		self.targetFormula = formula
	end
end

function SceneRound:setRoundUpdate(isUpdate)
	self._isRoundUpdate = isUpdate
end

function SceneRound:isRoundUpdate()
	return self._isRoundUpdate
end

function SceneRound:setAttackRule(attackRule)
	self._attackRule = attackRule
end

function SceneRound:setAutoChoose(findTargetType)
	self._autoChoose.findTargetType = findTargetType or 0
end

function SceneRound:setSeatEmpty(b)
	self._isSeatEmpty = b
end

function SceneRound:isSeatEmpty(seat)
	if self._isSeatEmpty and self.seatOccupied and self.seatOccupied[seat] then
		return false
	end

	return true
end

function SceneRound:autoChoose(curHero)
	local function filter(obj)
		return not obj:isAlreadyDead() and not self._scene:isBackHeros(obj) and obj.id ~= curHero.id
	end

	local ret = {}

	for _, obj in self._scene:ipairsHeros() do
		if filter(obj) then
			if self._autoChoose.findTargetType == 0 then
				if obj.force ~= curHero.force then
					table.insert(ret, obj)
				end
			elseif self._autoChoose.findTargetType == 1 then
				table.insert(ret, obj)
			end
		end
	end

	return ret
end

function SceneRound:isOtherBackObj(id)
	if not self:isEffect() then
		return false
	end

	for _, data in ipairs(self.otherObjData) do
		if data.obj.id == id then
			return true
		end
	end

	return false
end

function SceneRound:isEffect()
	return self._state == SceneRoundState.run
end

function SceneRound:isIdleWaitEffect()
	return self._state == SceneRoundState.idel
end

function SceneRound:_onNewRound()
	local buff = self.buff

	if self.targetFormula then
		self.targets = buff:findTargetsByCfg(self.targetFormula)
	end

	local function overWithTrigger()
		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			reason = 3,
			cfgId = buff.cfgId,
			buffId = buff.id
		})

		self._state = SceneRoundState.over
	end

	if self.data.isSoloWithCaster then
		if table.length(self.targets) ~= 1 then
			overWithTrigger()

			return
		end

		if self.targets[1].extraObjectCsvCfg then
			if self.targets[1].extraObjectCsvCfg.category > 0 then
				overWithTrigger()

				return
			else
				local newTarget = self._scene:getObjectBySeatExcludeDead(self.targets[1].seat)

				if newTarget then
					table.remove(self.targets)
					table.insert(self.targets, newTarget)
				else
					overWithTrigger()

					return
				end
			end
		end

		if self.targets[1]:isRealDeath() then
			overWithTrigger()

			return
		end

		if not self.data.ignoreWithCaster then
			if not self._scene:getNormalObject(buff.caster.id) then
				overWithTrigger()

				return
			end

			table.insert(self.targets, 1, buff.caster)
		end
	end

	if table.length(self.targets) == 0 then
		overWithTrigger()

		return
	end

	if self._attackRule == 0 then
		table.sort(self.targets, function(a, b)
			return a:speed() > b:speed()
		end)
	elseif self._attackRule == 1 then
		for i, obj in ipairs(self.targets) do
			if obj.id == self.buff.caster.id then
				self.targets[i], self.targets[1] = self.targets[1], self.targets[i]

				break
			end
		end
	elseif self._attackRule == 2 then
		for i, obj in ipairs(self.targets) do
			if obj.id == self.buff.holder.id then
				self.targets[i], self.targets[1] = self.targets[1], self.targets[i]

				break
			end
		end
	end

	local objectHash = {}

	self.beginTakeDamageTb = {}

	for _, obj in ipairs(self.targets) do
		objectHash[obj.id] = true
		self.beginTakeDamageTb[obj.id] = obj:getTakeDamageRecord(battle.ValueType.normal)
	end

	local backStageObjs = {}
	local backStageHash = {}

	for seat = 1, 12 do
		local obj = self._scene:getObjectBySeat(seat)

		if obj then
			if objectHash[obj.id] then
				table.insert(self.reserveSeatMap, {
					isFromMainScene = true,
					obj = obj,
					oriSeat = seat
				})
			else
				table.insert(self.reserveSeatMap, {
					isBackStage = true,
					obj = obj,
					attacked = not itertools.include(self._scene.play.roundLeftHeros, function(data)
						return data.obj.id == obj.id
					end),
					oriSeat = seat
				})
				table.insert(backStageObjs, obj)

				backStageHash[obj.id] = true
				self.seatOccupied[seat] = true
			end
		else
			self.seatOccupied[seat] = true
		end
	end

	for _, objId in ipairs(self._scene.play.nextHeros) do
		if backStageHash[objId] then
			table.insert(self.reverseExAttackArray, objId)
		end
	end

	for _, obj in ipairs(backStageObjs) do
		for _, data in obj.extraRoundData:pairs() do
			obj:addExRecord(battle.ExRecordEvent.sceneRoundExAttackData, data)
		end

		BuffModel.BuffEffectFuncTb.backStage({
			holder = obj,
			scene = self._scene
		}, {
			1,
			self.data.backStageStoreRound
		}, false)
	end

	for _, obj in self._scene.extraHeros:order_pairs() do
		if obj.mode == battle.ObjectType.FollowNormal then
			table.insert(self.otherObjData, {
				obj = obj,
				seat = obj.seat
			})
			obj:backStage()
		end
	end

	if self.viewData.changeViewSeat then
		for _, obj in ipairs(self.targets) do
			local posIdx = obj.force == 1 and 3 or 9

			if obj.seat ~= posIdx then
				obj:changeViewSeat(posIdx)
			end
		end
	end

	if self.roundLimit[3] > 0 then
		for _, obj in ipairs(self.targets) do
			self.attackCount[obj.id] = self.roundLimit[3]
		end
	end

	buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
		reason = 2,
		cfgId = buff.cfgId,
		buffId = buff.id
	})

	self._state = SceneRoundState.run

	self:setExtraRoundArgs(self.targets[1])

	for force = 1, 2 do
		local groupObject = self._scene:getGroupObj(force, battle.SpecialObjectId.teamShiled)

		if groupObject and not groupObject:isDeath() then
			local spr = gRootViewProxy:call("getSceneObj", tostring(table.getraw(groupObject)))

			if spr then
				battleEasy.queueEffect(function()
					spr:setVisible(false)
					spr:setVisibleEnable(false)
				end)
			end
		end
	end

	battleEasy.queueEffect(function()
		gRootViewProxy:proxy():onBrawlSpeedChange(self.viewData.timeScale)
	end)
end

function SceneRound:setExtraRoundArgs(obj)
	local args = self._extraAttackArgsGet(obj)

	obj:addExtraBattleData(args)
	self._scene:addObjToExtraRound(obj)
end

function SceneRound:onNewBattleTurn()
	if self._state == SceneRoundState.over then
		return
	end

	if self._state == SceneRoundState.idel then
		self:_onNewRound()
	end
end

function SceneRound:_getNextHero()
	local nextObj

	for _, obj in ipairs(self.targets) do
		if not nextObj and not self.roundLeftHeros[obj.seat] and (not self.attackCount[obj.id] or self.attackCount[obj.id] > 0) then
			nextObj = obj

			break
		end
	end

	return nextObj
end

function SceneRound:onBattleTurnEnd()
	if self._state == SceneRoundState.over then
		return
	end

	local battleTurnInfoTb = self._scene.play.battleTurnInfoTb
	local curHero = self._scene.play.curHero

	if curHero then
		if self.attackCount[curHero.id] then
			self.attackCount[curHero.id] = self.attackCount[curHero.id] - 1
		end

		self.totalRoundBattleTurn = self.totalRoundBattleTurn + 1
		self.roundLeftHeros[curHero.seat] = true
	end

	local isAllAttacked = true

	for _, obj in self._scene:ipairsHeros() do
		if self.roundLeftHeros[obj.seat] == nil then
			isAllAttacked = false

			break
		end
	end

	if isAllAttacked then
		self.roundLeftHeros = {}

		if self:isRoundUpdate() then
			self.totalRound = self.totalRound + 1

			self._scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundEnd)
			self._scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundStart)
		end
	end

	if self:checkBattleState() then
		self:_onRoundOver()

		return
	end

	local nextObj = self:_getNextHero()

	if nextObj then
		if nextObj:isFakeDeath() then
			local data = {
				obj = nextObj,
				id = self.id,
				atOnce = self.id,
				buffCfgId = self.buff.cfgId
			}

			data.mode = battle.ExtraBattleRoundMode.atOnce

			self._scene.play:resetGateAttackRecord(nextObj, data)
		else
			self:setExtraRoundArgs(nextObj)
		end
	end
end

function SceneRound:checkBattleState()
	if self.roundLimit[1] > 0 and self.totalRound >= self.roundLimit[1] then
		return true
	end

	if self.roundLimit[2] > 0 and self.totalRoundBattleTurn >= self.roundLimit[2] then
		return true
	end

	local aliveCount = 0
	local totalAttackCount = 0

	for _, obj in ipairs(self.targets) do
		local fieldObj = self._scene:getFieldObject(obj.id)

		if fieldObj and not obj:isRealDeath() then
			totalAttackCount = totalAttackCount + (self.attackCount[obj.id] or 0)
			aliveCount = aliveCount + 1
		end
	end

	if aliveCount < 2 then
		return true
	end

	if self.roundLimit[3] > 0 and totalAttackCount == 0 then
		return true
	end

	return false
end

local function popOneRandomFromTable(ret)
	local len = table.length(ret)

	if len > 0 then
		local randIdx = ymrand.random(1, len)

		return table.remove(ret, randIdx)
	end
end

function SceneRound:_onRoundOver()
	if self._state ~= SceneRoundState.run then
		return
	end

	gRootViewProxy:proxy():pushDeferList("playInEndBrawl")

	local minnVal = -1
	local maxxVal = -1
	local minnObjs = {}
	local maxxObjs = {}

	for _, obj in ipairs(self.targets) do
		if not obj:isAlreadyDead() then
			local oldDamage = self.beginTakeDamageTb[obj.id]
			local curDamage = obj:getTakeDamageRecord(battle.ValueType.normal)
			local diff = curDamage - oldDamage

			if minnVal == -1 then
				table.insert(minnObjs, obj)

				minnVal = diff
			elseif diff == minnVal then
				table.insert(minnObjs, obj)
			elseif diff < minnVal then
				minnObjs = {}

				table.insert(minnObjs, obj)

				minnVal = diff
			end

			if maxxVal == -1 then
				table.insert(maxxObjs, obj)

				maxxVal = diff
			elseif diff == maxxVal then
				table.insert(maxxObjs, obj)
			elseif maxxVal < diff then
				maxxObjs = {}

				table.insert(maxxObjs, obj)

				maxxVal = diff
			end
		end
	end

	local minObj, maxObj

	if maxxVal == minnVal and maxxVal ~= -1 then
		minObj = popOneRandomFromTable(minnObjs)
		maxObj = popOneRandomFromTable(minnObjs)
	else
		minObj = popOneRandomFromTable(minnObjs)
		maxObj = popOneRandomFromTable(maxxObjs)
	end

	local buff = self.buff

	buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
		reason = 0,
		cfgId = buff.cfgId,
		buffId = buff.id,
		winnerSeat = minObj and minObj.seat or 0,
		loserSeat = maxObj and maxObj.seat or 0
	})
	self:resetState()
	buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
		reason = 1,
		cfgId = buff.cfgId,
		buffId = buff.id,
		winnerSeat = minObj and minObj.seat or 0,
		loserSeat = maxObj and maxObj.seat or 0
	})
	buff:over()

	local playInEndBrawl = gRootViewProxy:proxy():popDeferList("playInEndBrawl")

	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndBrawl)
		end)
	end)
end

function SceneRound:resetState()
	if self._state ~= SceneRoundState.run then
		return
	end

	self._state = SceneRoundState.over

	for _, rData in ipairs(self.reserveSeatMap) do
		local obj = rData.obj

		if not obj:isRealDeath() then
			if rData.isFromMainScene and self._scene:getNormalObject(obj.id) then
				self._scene.play:cleanSpecRoundExRoundData(obj, self.buff.id)
				obj:changeViewSeat(rData.oriSeat)
			elseif rData.isBackStage then
				local data = {
					transferMp = 0,
					isBrawl = true,
					roundMark = 0,
					frontStageTarget = rData.oriSeat,
					cfgId = self.buff.cfgId,
					stageRound = self._scene.play.curRound,
					stageAttacked = rData.attacked,
					frontPriority = battle.FrontStagePriority.maxPriority,
					seatType = battle.FrontStageSeatType.real
				}

				obj:addExRecord(battle.ExRecordEvent.frontStage, data)
			end
		end
	end

	for _, objId in ipairs(self.reverseExAttackArray) do
		self._scene:addObjToExtraRound({
			id = objId
		})
	end

	for _, info in ipairs(self.otherObjData) do
		local data = {
			transferMp = 0,
			isBrawl = true,
			roundMark = 0,
			frontStageTarget = info.seat,
			cfgId = self.buff.cfgId,
			stageRound = self._scene.curRound,
			stageAttacked = info.attacked,
			frontPriority = battle.FrontStagePriority.maxPriority,
			seatType = battle.FrontStageSeatType.follow
		}

		info.obj:addExRecord(battle.ExRecordEvent.frontStage, data)
	end

	self._scene:checkBackStageObjs()

	for force = 1, 2 do
		local groupObject = self._scene:getGroupObj(force, battle.SpecialObjectId.teamShiled)

		if groupObject and not groupObject:isDeath() then
			local spr = gRootViewProxy:call("getSceneObj", tostring(table.getraw(groupObject)))

			if spr then
				battleEasy.queueEffect(function()
					spr:setVisible(true)
					spr:setVisibleEnable(true)
				end, {
					zOrder = battle.EffectZOrder.dead
				})
			end
		end
	end

	battleEasy.queueEffect(function()
		gRootViewProxy:proxy():onBrawlSpeedChange()
	end, {
		zOrder = battle.EffectZOrder.dead
	})
end

return SceneRound
