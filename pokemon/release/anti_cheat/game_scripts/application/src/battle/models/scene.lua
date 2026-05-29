local CsvBuffStageArgsGroupCache = {}
local SceneRound = require("battle.models.scene_round")
local FieldBuffManager = require("battle.models.buff.field_manager")
local SceneBuffRecordManager = require("battle.models.scene_buff")
globals.SceneModel = class("SceneModel")

function SceneModel:ctor()
	self.framesInScene = 0
	self.heros = CMap.new()
	self.enemyHeros = CMap.new()
	self.backHeros = CMap.new()
	self.extraHeros = CMap.new()
	self.seats = CMap.new()
	self.aidHeros = CMap.new()
	self.herosOrder = {}
	self.aidHerosOrder = nil
	self.autoFight = false
	self.sceneID = nil
	self.play = nil
	self.inputs = {}
	self.guide = nil
	self.updateResumeStack = {}
	self.isFirstLoad = true
	self.placeIdInfoTb = {}
	self.deadObjsToBeDeleted = {}
	self.deferListInBattleTurn = {}
	self.allBuffs = self:createBuffCollection()

	self.allBuffs:add_index(CCollection.index.new("delSelfWhenTriggered"):hash("hadDelSelfWhen2"):filter(function(k, v)
		return v.hadDelSelfWhen2
	end):value_immutably(false))

	self.fieldBuffs = self:createBuffCollection()
	self.fieldManager = FieldBuffManager.new(self)
	self.needToDelBuffIDs = {}
	self.totalDamage = {}
	self.forceRecordTb = {
		{},
		{}
	}
	self.buffGlobalManager = BuffGlobalModel.new()
	self.forceRecordObject = {}
	self.deferBeAttackList = {}
	self.beAttackZOrder = 0
	self.realDeathRecordTb = {}
	self.extraRecord = BattleExRecord.new()
	self.recordBuffManager = SceneBuffRecordManager.new(self)
	self.replaceGroupBuffIdMap = nil
	self.maxReplaceGroupBuffId = VersionValueRoot.new(-1)
	self.cowEnableCount = 0
	self.hasSendRecord = false
	self.specialRound = SceneRound.new(self)

	battleQuery.sceneBindBuff(self, self.allBuffs)
	battleComponents.bind(self, "Event")
end

function SceneModel:init(sceneID, data, isRecord)
	self.isRecord = isRecord
	self.data = data or {}
	self.battleID = data.battleID
	self.sceneID = sceneID
	self.closeRandFix = data.closeRandFix

	local sceneConf = csv.scene_conf[sceneID]

	if sceneConf then
		self.sceneConf = battleEasy.getSceneConfCsv(sceneID, 1)
	else
		self.sceneConf = battleEasy.getEndlessTowerSceneCsv(self.data.isAbyssEndless, sceneID, 1)
	end

	self.gateType = data.gateType or sceneConf.gateType
	self.sceneTag = self.sceneConf.tag or {}

	self:initBySceneConf()

	if isRecord then
		self.play = newRecordPlayModel(self, self.gateType)
	else
		self.play = newPlayModel(self, self.gateType)
	end

	self.play:init(self.data)

	self.guide = BattleGuideModel.new(self)

	self.guide:init(self.play)
	gRootViewProxy:proxy():showMainUI(false)
	self:waitInitAniDone()
end

function SceneModel:modelWait(type, f)
	log.battle.scene.wait(type)
	table.insert(self.updateResumeStack, {
		type = type,
		resume = f
	})
	gRootViewProxy:proxy():onModelWait(type)
end

function SceneModel:modelResume()
	local size = table.length(self.updateResumeStack)

	if size > 0 then
		local wait = self.updateResumeStack[size]
		local resume = wait.resume

		table.remove(self.updateResumeStack)
		log.battle.scene.resume(wait.type, size - 1)

		if size > 1 then
			wait = self.updateResumeStack[size - 1]
		end

		gRootViewProxy:notify("extraRoundModelWait")
		resume(self, true)

		return true
	end

	return false
end

function SceneModel:insertPlayCustomWait(type, resume)
	self:modelWait(type, function(self, continue)
		if continue then
			return resume()
		end
	end)
end

function SceneModel:waitInitAniDone(continue)
	if not continue then
		return self:modelWait("scene_init", self.waitInitAniDone)
	end

	self:start()
end

function SceneModel:getHerosMap(force)
	return force == 1 and self.heros or self.enemyHeros
end

function SceneModel:getObject(id)
	return self:getFieldObject(id) or self.backHeros:find(id)
end

function SceneModel:getFieldObject(id)
	local obj = self.heros:find(id) or self.enemyHeros:find(id) or self.extraHeros:find(id)

	return obj
end

function SceneModel:getNormalObject(id)
	local obj = self.heros:find(id) or self.enemyHeros:find(id)

	return obj
end

function SceneModel:getObjectExcludeDead(id)
	local obj = self:getFieldObject(id)

	if obj and not obj:isAlreadyDead() then
		return obj
	end
end

function SceneModel:getObjectBySeat(seat)
	local id = self.seats:find(seat)

	if id then
		return self:getNormalObject(id)
	end
end

function SceneModel:getObjectBySeatExcludeDead(seat)
	local obj = self:getObjectBySeat(seat)

	if obj and not obj:isAlreadyDead() then
		return obj
	end
end

function SceneModel:getForceNum(force)
	local map = self:getHerosMap(force)
	local ret = 0

	for _, obj in map:order_pairs() do
		if obj and not obj:isAlreadyDead() then
			ret = ret + 1
		end
	end

	return ret
end

function SceneModel:getForceNumIncludeDead(force)
	local map = self:getHerosMap(force)
	local ret = 0

	for _, obj in map:order_pairs() do
		if obj then
			ret = ret + 1
		end
	end

	return ret
end

function SceneModel:getForceIDs(force)
	local forces = self:getHerosMap(force)

	return itertools.keys(forces)
end

function SceneModel:getExtraRoundMode()
	return self.play.battleTurnInfoTb.extraRoundMode
end

function SceneModel:getRowRemain(force, row, getExObjs)
	local map = self:getHerosMap(force)
	local ret = {}

	local function objChosen(obj)
		local rowRange = battle.RowSeatRange[force][row]

		if obj and not obj:isAlreadyDead() and obj.seat <= rowRange.max and obj.seat >= rowRange.min then
			table.insert(ret, obj)
		end
	end

	for _, obj in map:order_pairs() do
		objChosen(obj)
	end

	if getExObjs then
		local exObjs = self:getAllNormalSelectExobjs(force)

		for _, exObj in ipairs(exObjs) do
			objChosen(exObj)
		end
	end

	return table.length(ret), ret
end

function SceneModel:getColumnRemain(force, column)
	local map = self:getHerosMap(force)
	local ret = {}

	for _, obj in map:order_pairs() do
		if obj and not obj:isAlreadyDead() and (obj.seat + 2) % 3 == column - 1 then
			table.insert(ret, obj)
		end
	end

	return table.length(ret), ret
end

function SceneModel:getAllNormalSelectExobjs(force)
	local exObjs = {}
	local hashId = {}

	local function forceCheck(obj)
		if not force then
			return true
		end

		if force == obj.force then
			return true
		end

		return false
	end

	local function exObjFilter(obj)
		if hashId[obj.id] then
			return false
		end

		if not forceCheck(obj) then
			return false
		end

		if not obj:isNormalSelectable() then
			return false
		end

		return true
	end

	for _, obj in self.extraHeros:order_pairs() do
		if exObjFilter(obj) then
			hashId[obj.id] = true

			table.insert(exObjs, obj)
		end
	end

	return exObjs
end

function SceneModel:getTotalForceFightPoint(force)
	local heros = self:getHerosMap(force)
	local ret = 0

	for _, obj in heros:order_pairs() do
		ret = ret + obj.fightPoint
	end

	return ret
end

function SceneModel:addInput(input)
	if self.play:isMyTurn() or self.fullManual then
		table.insert(self.inputs, input)
	end
end

function SceneModel:start()
	self:startGroupRound()
end

function SceneModel:startGroupRound(continue)
	if not continue then
		return self:modelWait("start_group_round", self.startGroupRound)
	end

	self.play:startGroupRound()
end

function SceneModel:initBySceneConf()
	self.sceneLevel = self.sceneConf.sceneLevel
	self.showLevel = self.sceneConf.showLevel
	self.skillLevel = self.sceneConf.skillLevel
	self.demonCorrectSelf = self.sceneConf.demonCorrectSelf
	self.demonCorrect = self.sceneConf.demonCorrect

	local sceneLevelCorrect = self.sceneConf.sceneLevelCorrect

	if sceneLevelCorrect then
		local cfg = csv.scene_level_correct[self.data.levels[1]]

		if cfg[sceneLevelCorrect] then
			self.sceneLevel = cfg[sceneLevelCorrect]
		end
	end
end

function SceneModel:over(continue)
	if not continue then
		return self:modelWait("battle_over", self.over)
	end

	self.guide:checkGuide(function()
		self.play:onOver()
	end, {
		round = battle.GuideTriggerPoint.End
	})
end

function SceneModel:newWave(continue)
	if not continue then
		return self:modelWait("new_wave", self.newWave)
	end

	if self.play:isPlaying() == false then
		return
	end

	gRootViewProxy:proxy():runDeferListWithEffect("battleTurn")
	gRootViewProxy:proxy():clearDeleteObjLayer()
	gRootViewProxy:proxy():showMainUI(false)
	self.play:onNewWavePlayAni()
end

function SceneModel:waitNewWaveAniDone(continue)
	if not continue and self.play:isPlaying() then
		return self:modelWait("new_wave_play_ani", self.waitNewWaveAniDone)
	end

	gRootViewProxy:proxy():showMainUI(true)
	gRootViewProxy:notify("showMain", false)
	gRootViewProxy:proxy():showSpeedRank(false)
	self.guide:checkGuide(function()
		self.play:onNewWave()
	end, {
		round = battle.GuideTriggerPoint.Start
	})
end

function SceneModel:newRound(continue)
	log.battle.scene.newRound({
		play = self.play,
		continue = continue,
		isPlaying = self.play:isPlaying()
	})
	gRootViewProxy:proxy():flushAllDeferList()

	if not continue and self.play:isPlaying() then
		return self:modelWait("new_round", self.newRound)
	end

	self.deadObjsToBeDeleted = {}

	if self.play.curRound > 0 then
		self:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundEnd)
	end

	self:checkObjsDeadState()
	gRootViewProxy:proxy():flushAllDeferList()
	self.play:onNewRound()
end

function SceneModel:newRoundBattleTurn(continue)
	if not continue and self.play:isPlaying() then
		return self:modelWait("new_round_battle_turn", self.newRoundBattleTurn)
	end

	self.guide:checkGuide(function()
		self:newBattleTurn()
	end)
end

function SceneModel:newBattleTurn(continue)
	log.battle.scene.newBattleTurn({
		play = self.play,
		continue = continue,
		self.play:isPlaying()
	})
	gRootViewProxy:proxy():flushAllDeferList()

	if not continue and self.play:isPlaying() then
		return self:modelWait("new_battle_turn", self.newBattleTurn)
	end

	self.deadObjsToBeDeleted = {}
	self.realDeathRecordTb = {}
	self.inputs = {}

	battleEasy.logHerosInfo(self, "newBattleTurn")
	self.specialRound:onNewBattleTurn()
	self.play:onNewBattleTurn()
	gRootViewProxy:proxy():flushAllDeferList()
end

function SceneModel:waitAidGuide(continue)
	if not continue then
		gRootViewProxy:proxy():checkOuterGuide(battle.OuterGuideName.aid)

		return self:modelWait(battle.OuterGuideName.aid, self.waitAidGuide)
	end

	self.play:newBattleTurnGoon()
end

function SceneModel:waitNewBattleRoundAniDone(continue)
	if not continue and self.play:isPlaying() then
		return self:modelWait("new_battle_turn_play_ani", self.waitNewBattleRoundAniDone)
	end

	local obj = self.play.curHero
	local args = {
		curRound = self.play.curRound,
		obj = obj,
		skillsOrder = obj.skillsOrder,
		immuneInfos = self:immuneInfosToCurHeroSkills(),
		skillsStateInfoTb = obj.skills,
		isTurnAutoFight = self.play:isNowTurnAutoFight(),
		weathers = self.buffGlobalManager:makeWeatherArgs(self)
	}

	battleEasy.queueNotify("newBattleRoundTo", args)

	if self.aidHeros:size() > 0 then
		self:waitAidGuide()
	else
		self.play:newBattleTurnGoon()
	end
end

function SceneModel:onSubModulesNewBattleTurn2()
	gRootViewProxy:notify("playExplorer")
end

function SceneModel:onSubModulesNewBattleTurn()
	local obj = self.play.curHero
	local args = {
		totalWave = self.play.waveCount,
		wave = self.play.curWave,
		isMultLast = self.play:isMultLast(),
		curRound = self.play.curRound,
		scene = self
	}

	gRootViewProxy:proxy():runDeferListWithEffect("battleTurn")
	gRootViewProxy:proxy():runDeferList("new_battle_turn_play_ani")
	battleEasy.queueNotify("newBattleRound", args)
	battleEasy.queueNotify("showSpec", true)
end

function SceneModel:immuneInfosToCurHeroSkills()
	local ret = {}
	local curHero = self.play.curHero

	for _, skillID in ipairs(curHero.skillsOrder) do
		skillID = curHero.skillsMap[skillID] or skillID
		ret[skillID] = {}

		for _, obj in self:ipairsHeros() do
			ret[skillID][obj.id] = obj:selectTextImmuneInfo(skillID)
		end
	end

	return ret
end

function SceneModel:addObjToBeDeleted(obj)
	self.deadObjsToBeDeleted[obj.id] = obj
end

function SceneModel:setDeathRecord(obj, order)
	local objStr = obj:toString()

	for _, v in ipairs(self.realDeathRecordTb) do
		if v.tag == objStr and order < v.order then
			v.order = order

			return
		end
	end

	table.insert(self.realDeathRecordTb, {
		order = order,
		tag = objStr,
		id = obj.id,
		force = obj.force
	})
end

function SceneModel:onAuraEffect()
	self.recordBuffManager:getRecord("aura"):onAuraEffect()
end

function SceneModel:endBattleTurn()
	battleEasy.queueEffect(function()
		gRootViewProxy:proxy():runDeferList("battleEnd")
		gRootViewProxy:proxy():flushAllDeferList()
	end)
	self:checkBackStageObjs()
	self:addSummonObj()
	self:checkViewSync()

	local deletedCount = 0

	for _, obj in pairs(self.deadObjsToBeDeleted) do
		self:onObjDel(obj, true)

		deletedCount = deletedCount + 1
	end

	if deletedCount > 0 then
		self.deadObjsToBeDeleted = {}
	end

	self.extraRecord:refreshEventRecord(battle.TimeIntervalType.battleRound)
	battleEasy.queueNotify("battleTurnEnd")
	battleEasy.logHerosInfo(self, "endBattleTurn")
end

function SceneModel:onGroupObjDead(obj)
	gRootViewProxy:proxy():collectNotify("battleTurn", obj, "PlayGroupShieldEffect", obj:counterEffectArgs({
		state = battle.ObjectState.realDead
	}))
end

function SceneModel:eraseObj(obj)
	local objMap = self:getHerosMap(obj.force)
	local isRemove = objMap:erase(obj.id) or obj.seat > 12

	if isRemove then
		self:removeFromSeat(obj)
		self:refreshHerosOrder()
	end

	isRemove = isRemove or self.extraHeros:erase(obj.id) ~= nil
	isRemove = isRemove or self.backHeros:erase(obj.id) ~= nil

	return isRemove
end

function SceneModel:onObjDel(obj, needQueue)
	local objMap = self:getHerosMap(obj.force)
	local isRemove = self:eraseObj(obj)

	if isRemove then
		if needQueue then
			battleEasy.queueEffect(function()
				if obj.seat > 12 then
					self:onGroupObjDead(obj)
				else
					battleEasy.queueZOrderNotify("sceneDeadObj", battle.EffectZOrder.dead, tostring(obj), obj)
				end
			end)
		else
			obj:processRealDeathClean()
			battleComponents.unbindAll(obj)
			gRootViewProxy:notify("sceneDelObj", tostring(obj))
		end
	end
end

function SceneModel:addObj(force, seat, obj)
	self:addToSeat(obj, seat)
	self:getHerosMap(force):insert(obj.id, obj)
	self:refreshHerosOrder()
end

function SceneModel:shiftSeat(obj, seat)
	local function removeFromSeat(object)
		if not self:removeFromSeat(object) then
			errorInWindows("shiftSeat Fail: obj(%s) can't remove from seat(%s)", object.id, object.seat)
		end
	end

	local shiftObj = self:getObjectBySeat(seat)
	local oldSeat = obj.seat

	removeFromSeat(obj)

	if shiftObj then
		removeFromSeat(shiftObj)

		shiftObj.seat = oldSeat

		self:addToSeat(shiftObj, oldSeat)
	end

	obj.seat = seat

	self:addToSeat(obj, seat)

	return shiftObj
end

function SceneModel:changeSeat(obj, seat)
	if not self:removeFromSeat(obj) then
		errorInWindows("changeSeat Fail: obj(%s) can't remove from seat(%s)", obj.id, obj.seat)
	end

	obj.seat = seat

	self:addToSeat(obj, seat)
end

function SceneModel:removeFromSeat(obj)
	local id = self.seats:find(obj.seat)

	if id == obj.id then
		self.seats:erase(obj.seat)

		return true
	end

	return false
end

function SceneModel:addToSeat(obj, seat)
	if seat > 0 and seat < 13 then
		local oldID = self.seats:find(seat)

		if oldID then
			local oldObj = self:getNormalObject(oldID)

			if not oldObj then
				errorInWindows("can't get obj by id(%s)", oldID)
			elseif not oldObj:isRealDeath() then
				errorInWindows("obj(%s)'s target seat(%s) already has obj(%s)", obj.id, seat, oldID)
			end
		end

		self.seats:insert(seat, obj.id)
	end
end

function SceneModel:addExtraObj(obj)
	log.battle.scene.addExtraObj({
		object = obj
	})
	self.extraHeros:insert(obj.id, obj)
end

function SceneModel:addAidObj(obj)
	log.battle.scene.addAidObj({
		object = obj
	})
	self.aidHeros:insert(obj.id, obj)
end

function SceneModel:eraseExtraObj(obj)
	self.extraHeros:erase(obj.id)
end

function SceneModel:addBackStageObj(obj)
	log.battle.scene.addBackStageObj({
		object = obj
	})
	self.backHeros:insert(obj.id, obj)
end

function SceneModel:addSummonObj()
	for _, objTb in ipairs(self.play.summonHeros) do
		gRootViewProxy:proxy():collectCallBack("battleTurn", gRootViewProxy:proxy():createModelCallSprite(objTb.obj, "forceSetVisible", true))

		if not self.extraHeros:find(objTb.obj.id) and not objTb.obj:isExtraObj() and self:getFieldObject(objTb.obj.id) then
			self.play:addRoundLeftHero(objTb)
		end
	end

	self.play.summonHeros = {}
end

function SceneModel:isBackHeros(obj)
	return obj and self.backHeros:find(obj.id)
end

function SceneModel:getAidObj(id)
	return self.aidHeros:find(id)
end

function SceneModel:getBackObject(id)
	return self.backHeros:find(id)
end

function SceneModel:playEnd(continue)
	if not continue then
		return self:modelWait("play_end", self.playEnd)
	end

	local tb = self.extraRecord:getEvent(battle.ExRecordEvent.campDamage)

	log.battle.scene.campDamage({
		totalDamage = tb
	})
	printInfo("\n\n\t\tbattle %s over - id=%s, scene=%s, frame=%s, rndcnt=%s, result=%s, star=%s\n\n", self.isRecord and "record" or "", stringz.bintohex(self.battleID or ""), self.sceneID, self.framesInScene, ymrand.randCount, self.play.result, self.play.gateStar)

	ymrand.randCount = 0
	self.isBattleAllEnd = true

	gGameUI.guideManager:battleStageSave(function()
		self.play:postEndResultToServer(functools.partial(self.showBattleEndView, self))
	end)
end

function SceneModel:showBattleEndView(endInfos, serverData, oldCapture)
	local resultsData = endInfos or {}

	resultsData.serverData = serverData
	resultsData.oldCapture = oldCapture

	gRootViewProxy:raw():showEndView(resultsData)
end

function SceneModel:update(delta)
	self.framesInScene = self.framesInScene + 1

	self:preDelBuff()

	if self:modelResume() then
		return
	end

	if not self.play:isPlaying() then
		return
	end

	if self.play:runOneFrame() then
		return
	end

	if self.play:isMyTurn() or self.fullManual then
		if self.autoFight then
			self.play:setAttack(0, 0)
		end

		if self.play.handleInput then
			self.play:onceBattle(self.play.handleInput[1], self.play.handleInput[2])

			self.play.handleInput = nil
		end
	end
end

function SceneModel:setAutoFight(flag)
	self.autoFight = flag
end

function SceneModel:setFullManual(flag)
	self.fullManual = flag
end

function SceneModel:resetPlaceIdInfo(force)
	local retT0 = {}
	local retT = {}
	local heros = self:getHerosMap(force)

	for _, obj in heros:order_pairs() do
		if obj and not obj:isAlreadyDead() then
			retT[obj.seat] = obj
		end
	end

	local hasOnlyOneRow = {
		false,
		false
	}
	local hasOnlyOneColumn = {
		false,
		false,
		false
	}

	itertools.each(retT, function(seat, _)
		local rowNum = (math.floor((seat + 2) / 3) - 1) % 2 + 1
		local columnNum = (seat - 1) % 3 + 1

		retT0[seat] = {}
		retT0[seat].row1 = rowNum == 1 and 1 or nil
		retT0[seat].row2 = rowNum == 2 and 2 or nil
		retT0[seat].column1 = columnNum == 1 and 1 or nil
		retT0[seat].column2 = columnNum == 2 and 2 or nil
		retT0[seat].column3 = columnNum == 3 and 3 or nil
		hasOnlyOneRow[1] = retT0[seat].row1 and true or hasOnlyOneRow[1]
		hasOnlyOneRow[2] = retT0[seat].row2 and true or hasOnlyOneRow[2]
		hasOnlyOneColumn[1] = retT0[seat].column1 and true or hasOnlyOneColumn[1]
		hasOnlyOneColumn[2] = retT0[seat].column2 and true or hasOnlyOneColumn[2]
		hasOnlyOneColumn[3] = retT0[seat].column3 and true or hasOnlyOneColumn[3]
	end)

	if not hasOnlyOneRow[1] or not hasOnlyOneRow[2] then
		itertools.each(retT, function(seat, _)
			retT0[seat].row1 = 1
			retT0[seat].row2 = 2
		end)
	end

	if hasOnlyOneColumn[1] and not hasOnlyOneColumn[2] and not hasOnlyOneColumn[3] or not hasOnlyOneColumn[1] and hasOnlyOneColumn[2] and not hasOnlyOneColumn[3] or not hasOnlyOneColumn[1] and not hasOnlyOneColumn[2] and hasOnlyOneColumn[3] then
		itertools.each(retT, function(seat, _)
			retT0[seat].column1 = 1
			retT0[seat].column2 = 2
			retT0[seat].column3 = 3
		end)
	end

	local startNum = force == 1 and 0 or self.play.ForceNumber

	for i = 1 + startNum, self.play.ForceNumber + startNum do
		self.placeIdInfoTb[i] = retT0[i] or {}
	end

	return retT0, retT
end

function SceneModel:deleteBuff(buffID)
	table.insert(self.needToDelBuffIDs, buffID)
end

function SceneModel:preDelBuff()
	for _, buffID in ipairs(self.needToDelBuffIDs) do
		local buff = self.allBuffs:erase(buffID)

		self.fieldBuffs:erase(buffID)

		if buff then
			buff:overClean()
			buff:__delete()
		end
	end

	arraytools.clear(self.needToDelBuffIDs)
end

function SceneModel:updateBuffByNode(triggerPoint)
	log.battle.scene.updateBuffByNode({
		play = self.play,
		triggerPoint = triggerPoint
	})

	for _, buff in self.allBuffs:order_pairs() do
		if not self:isBackHeros(buff.holder) then
			buff:update(triggerPoint)
		end
	end
end

function SceneModel:updateBuffEveryTurn(triggerPoint)
	self:updateBuffByNode(triggerPoint)
end

function SceneModel:updateBuffForAidObj(triggerPoint, trigger)
	for _, obj in self:ipairsAidHeros() do
		for _, buff in obj:iterBuffs() do
			buff:update(triggerPoint, trigger)
		end
	end
end

function SceneModel:onAllPassive(typ)
	local allPassiveSkills = {}
	local objs = {}

	for _, obj in self:ipairsHeros() do
		if not obj:isAlreadyDead() then
			for _, skill in pairs(obj.passiveSkills) do
				table.insert(allPassiveSkills, skill)
			end

			table.insert(objs, obj)
			obj.triggerEnv[battle.TriggerEnvType.PassiveSkill]:push_back(typ)
		end
	end

	self:sortPassiveSkills(allPassiveSkills)

	for _, skill in ipairs(allPassiveSkills) do
		skill.owner:onOnePassiveTrigger(skill, typ)
	end

	for _, obj in ipairs(objs) do
		obj.triggerEnv[battle.TriggerEnvType.PassiveSkill]:pop_back()
	end
end

function SceneModel:sortPassiveSkills(skillList)
	local function more(a, b)
		return b < a
	end

	local function less(a, b)
		return a < b
	end

	local sortFuncs = {
		{
			getVal = function(skill)
				return skill.cfg.passivePriority
			end,
			checkFunc = less
		},
		{
			getVal = function(skill)
				return skill.owner.id
			end,
			checkFunc = less
		},
		{
			getVal = function(skill)
				return skill.id
			end,
			checkFunc = less
		}
	}

	table.sort(skillList, function(a, b)
		for k, v in ipairs(sortFuncs) do
			local val1, val2 = v.getVal(a), v.getVal(b)

			if k == #sortFuncs then
				return v.checkFunc(val1, val2)
			end

			if val1 and val2 then
				if val1 ~= val2 then
					return v.checkFunc(val1, val2)
				end
			elseif val1 then
				return true
			elseif val2 then
				return false
			end
		end
	end)
end

function SceneModel:checkObjsDeadState()
	local hasObj = false

	for _, obj in self:ipairsOnSiteHeros() do
		if obj then
			if obj:isRealDeath() then
				hasObj = true

				self:onObjDel(obj, true)
			elseif not obj:isFakeDeath() and obj:hp() == 0 then
				errorInWindows("obj(%s) is not fakeDeath but hp == 0", obj.unitID)

				hasObj = true

				obj:setDead()

				if obj:isRealDeath() then
					self:onObjDel(obj, true)
				end
			end
		end
	end

	self:ipairGroupObject(function(obj)
		if self.deadObjsToBeDeleted[obj.id] then
			self:onObjDel(obj, true)

			self.deadObjsToBeDeleted[obj.id] = nil
		end
	end)
	self:checkBackStageObjs()

	if hasObj and not self:getSpecialSceneInfo() then
		self.play:checkBattleEnd()
	end
end

function SceneModel:getSceneAttrCorrect(force)
	return gSceneAttrCorrect[force == 1 and self.sceneID or -self.sceneID] or {}
end

function SceneModel:isCraftGateType()
	return self.gateType == game.GATE_TYPE.craft or self.gateType == game.GATE_TYPE.crossCraft or self.gateType == game.GATE_TYPE.crossArena
end

function SceneModel:createGroupObj(force, seat)
	self.forceRecordObject[force] = self.forceRecordObject[force] or {}

	if self.forceRecordObject[force][seat] then
		return self.forceRecordObject[force][seat]
	end

	self.forceRecordObject[force][seat] = GroupObjectModel.new(self, force)

	self.forceRecordObject[force][seat]:init()
	self.forceRecordObject[force][seat]:initView()

	return self.forceRecordObject[force][seat]
end

function SceneModel:ipairGroupObject(f)
	for i = battle.SpecialObjectId.teamShiled, battle.SpecialObjectId.teamShiled do
		for force = 1, 2 do
			local obj = self:getGroupObj(force, i)

			if obj then
				f(obj)
			end
		end
	end
end

function SceneModel:getGroupObj(force, seat)
	if self.forceRecordObject[force] then
		return self.forceRecordObject[force][seat]
	end
end

function SceneModel:excuteGroupObjFunc(force, seat, funcName, ...)
	local obj = self:getGroupObj(force, seat)

	if obj and obj[funcName] and type(obj[funcName]) == "function" then
		return obj[funcName](obj, ...)
	end

	return nil
end

function SceneModel:getGroupBuffId(easyEffectFunc)
	return ({
		teamShield = 13
	})[easyEffectFunc]
end

function SceneModel:getBuffQuery()
	return self.allBuffs:getQuery()
end

function SceneModel:initGroupObj(buff)
	local force = buff.caster.force
	local specialId = self:getGroupBuffId(buff.csvCfg.easyEffectFunc)
	local obj = self:getGroupObj(force, specialId)
	local curHero = self.play.curHero

	if curHero then
		buff.isSelfTurn = curHero.id == buff.holder.id
	end

	obj:reloadUnit(buff)
end

function SceneModel:addObjToExtraRound(obj, order)
	local lastInfo = self:getSpecialSceneInfo()

	if lastInfo then
		order = order or 1
	end

	local index = math.max(table.length(self.play.nextHeros) + 1, 1)

	table.insert(self.play.nextHeros, order or index, obj.id)
end

function SceneModel:cleanObjInExtraRound(obj)
	for i = table.length(self.play.nextHeros), 1, -1 do
		if self.play.nextHeros[i] == obj.id then
			table.remove(self.play.nextHeros, i)
		end
	end
end

function SceneModel:cleanExRoundByBuffId(obj, buffId)
	local delExAttackIdx = {}
	local delNextHerosOrder = {}
	local size = obj.extraRoundData:size()
	local orderIdx = 0

	for realIdx, data in obj.extraRoundData:pairs() do
		orderIdx = orderIdx + 1

		if data.buffId and data.buffId == buffId then
			table.insert(delExAttackIdx, realIdx)
			table.insert(delNextHerosOrder, size - orderIdx + 1)
		end
	end

	for i = table.length(delExAttackIdx), 1, -1 do
		obj.extraRoundData:erase(delExAttackIdx[i])

		if obj.curExtraDataIdx == delExAttackIdx[i] then
			obj:resetExtraDataIdx()
		end
	end

	local allObjIndex = {}
	local idxInDelNHO, num = 0, 0
	local hash = arraytools.hash(delNextHerosOrder)

	for i, objId in ipairs(self.play.nextHeros) do
		if objId == obj.id then
			idxInDelNHO = idxInDelNHO + 1

			if hash[idxInDelNHO] then
				table.insert(allObjIndex, i)

				num = num + 1

				if num >= table.length(delNextHerosOrder) then
					break
				end
			end
		end
	end

	for i = table.length(allObjIndex), 1, -1 do
		table.remove(self.play.nextHeros, allObjIndex[i])
	end
end

function SceneModel:mergeDeferBeAttack(ret)
	local tempRef = {}

	local function getKey(attackInfo)
		local key1 = attackInfo.attacker and attackInfo.attacker.id
		local key2 = attackInfo.target and attackInfo.target.id

		return key1 .. key2 .. attackInfo.damageArgs.skillDamageId
	end

	for i = table.length(ret), 1, -1 do
		local attackInfo = ret[i]

		if attackInfo.canMerge and attackInfo.damageArgs.skillDamageId then
			local key = getKey(attackInfo)

			if not tempRef[key] then
				tempRef[key] = attackInfo
			else
				if attackInfo.damageArgs.isBeginDamageSeg then
					tempRef[key].damageArgs.isBeginDamageSeg = true
				end

				tempRef[key].damage = tempRef[key].damage + attackInfo.damage
				tempRef[key].damageArgs.leftDamage = tempRef[key].damage

				table.remove(ret, i)
			end
		end
	end
end

function SceneModel:deferBeAttack(id, attacker, target, damage, processID, damageArgs, canMerge)
	local attackInfo = {
		attacker = attacker,
		target = target,
		damage = damage,
		processID = processID,
		damageArgs = damageArgs,
		canMerge = canMerge
	}

	if not self.deferBeAttackList[id] then
		self.deferBeAttackList[id] = {}
	end

	damageArgs.beAttackZOrder = damageArgs.beAttackZOrder + 0.5

	table.insert(self.deferBeAttackList[id], attackInfo)
end

function SceneModel:runBeAttackDefer(id)
	self:checkDeferAttackOnDeath(id)

	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]

		self.deferBeAttackList[id] = {}

		local rebound, others = {}, {}

		for _, attackInfo in ipairs(t) do
			if attackInfo.damageArgs.from == battle.DamageFrom.rebound then
				table.insert(rebound, attackInfo)
			else
				table.insert(others, attackInfo)
			end
		end

		self:mergeDeferBeAttack(others)

		local sortT = arraytools.merge({
			rebound,
			others
		})

		for _, attackInfo in ipairs(sortT) do
			local target = attackInfo.target
			local attacker = attackInfo.attacker
			local damage = attackInfo.damage
			local processID = attackInfo.processID
			local damageArgs = attackInfo.damageArgs

			damageArgs.isDefer = true

			if damageArgs.from == battle.DamageFrom.rebound then
				damage = math.min(damage, target:hp() - 1)
				damage = math.max(damage, 0)
			end

			local _damage = target:beAttack(attacker, damage, processID, damageArgs)
			local skill = attacker and attacker.curSkill

			if skill and skill.isSpellTo and damageArgs.fromExtra and (damageArgs.fromExtra[battle.DamageFromExtra.allocate] or damageArgs.fromExtra[battle.DamageFromExtra.link]) then
				skill:addToSegDamage(_damage:get(battle.ValueType.normal))
			end
		end
	end
end

function SceneModel:deleteBeAttackDefer(id, DamageFromExtraType, damageId)
	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]

		for k = table.length(t), 1, -1 do
			local attackInfo = t[k]

			if attackInfo.damageArgs.fromExtra[DamageFromExtraType] and damageId == attackInfo.damageArgs.damageId then
				table.remove(t, k)
			end
		end
	end
end

function SceneModel:checkDeferAttackOnDeath(id)
	if self.deferBeAttackList[id] then
		local t = self.deferBeAttackList[id]
		local targetMark = {}

		for i = table.length(t), 1, -1 do
			local attackInfo = t[i]

			if attackInfo.damageArgs.from ~= battle.DamageFrom.rebound then
				local target = attackInfo.target

				if not targetMark[target.id] then
					attackInfo.damageArgs.isLastDamageSeg = true
					targetMark[target.id] = true
				end
			end
		end
	end
end

function SceneModel:cleanInWaveGoon(isGroupRound)
	for _, obj in self:ipairsAllHeros() do
		if obj:isSummonType() and (isGroupRound or obj.waveGoonDel) then
			obj:processRealDeathClean()
			self:onObjDel(obj, true)
		end
	end

	self:ipairGroupObject(function(obj)
		if not obj:isDeath() then
			self:onGroupObjDead(obj)
		end

		obj:init()
	end)
	self:buffRoundInherit("wave")
	self.extraRecord:refreshEventRecord(battle.TimeIntervalType.wave)

	self.deferBeAttackList = {}

	gRootViewProxy:proxy():flushCurDeferList()
end

function SceneModel:buffRoundInherit(processType)
	for _, buff in self.allBuffs:order_pairs() do
		if not buff.isAuraType then
			local overType = buff.csvCfg.roundInherit[processType]

			if overType == 1 then
				buff:overClean()
			elseif overType == 2 then
				buff:over({
					endType = battle.BuffOverType.process
				})
			end
		end
	end
end

function SceneModel:recordSceneAlterBuff(buffId, buffCfgId)
	if self.replaceGroupBuffIdMap == nil then
		self.replaceGroupBuffIdMap = {}
	end

	if buffCfgId and CsvBuffStageArgsGroupCache[buffCfgId] == nil then
		local buff = csv.buff[buffCfgId]
		local stageArgs = buff.stageArgs
		
		local h = {}

		if stageArgs[1].buffGroupId then
			for _, v in ipairs(stageArgs[1].buffGroupId[1]) do
				h[v] = true
			end

			CsvBuffStageArgsGroupCache[buffCfgId] = {
				assignGroup = h,
				convertGroup = stageArgs[1].buffGroupId[2]
			}
		end
	end

	self.replaceGroupBuffIdMap[buffId] = buffCfgId

	if buffCfgId == nil then
		self.maxReplaceGroupBuffId:cmpSet(-1)
	elseif buffId > self.maxReplaceGroupBuffId:get() then
		self.maxReplaceGroupBuffId:set(buffId)
	end

	for _, obj in self.backHeros:order_pairs() do
		obj:clearBuffImmune()
	end

	for _, obj in self:ipairsHeros() do
		obj:clearBuffImmune()
	end
end

function SceneModel:getExistLastSceneAlterBuff()
	if self.replaceGroupBuffIdMap == nil then
		return -1
	end

	local buffCfgId = -1
	local maxBuffID = self.maxReplaceGroupBuffId:get()

	if maxBuffID ~= -1 then
		buffCfgId = self.replaceGroupBuffIdMap[maxBuffID]

		return buffCfgId, CsvBuffStageArgsGroupCache[buffCfgId]
	end

	for k, v in pairs(self.replaceGroupBuffIdMap) do
		if maxBuffID < k then
			maxBuffID = k
			buffCfgId = v
		end
	end

	self.maxReplaceGroupBuffId:cmpSet(maxBuffID)

	return buffCfgId, CsvBuffStageArgsGroupCache[buffCfgId]
end

function SceneModel:getMaxReplaceGroupBuffId()
	return self.maxReplaceGroupBuffId:newValue()
end

function SceneModel:updateBeAttackZOrder()
	self.beAttackZOrder = self.beAttackZOrder + 1
end

local FilterObjectMap = {
	[battle.FilterObjectType.noAlreadyDead] = function(obj)
		return obj and obj:isAlreadyDead()
	end,
	[battle.FilterObjectType.noRealDeath] = function(obj)
		return obj and obj:isRealDeath()
	end,
	[battle.FilterObjectType.excludeEnvObj] = function(obj, env)
		if obj and env.fromObj and (not env.skillFormulaType or env.skillFormulaType == battle.SkillFormulaType.damage) then
			return obj.id == env.fromObj.id
		end
	end,
	[battle.FilterObjectType.excludeObjLevel1] = function(obj, env)
		return obj and obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, env)
	end
}

function SceneModel:getFilterObjects(force, env, ...)
	local ret = {}

	if force == 3 then
		force = 1
		ret = self:getFilterObjects(3 - force, env, ...)
	end

	local heros = self:getHerosMap(force)

	for _, obj in heros:order_pairs() do
		local fObj = self:getFilterObject(obj.id, env, ...)

		if fObj then
			table.insert(ret, fObj)
		end
	end

	table.sort(ret, function(o1, o2)
		return o1.id < o2.id
	end)

	return ret
end

function SceneModel:getFilterObject(id, env, ...)
	local obj = self:getFieldObject(id)
	local filters = {
		...
	}

	if table.length(filters) == 1 and type(filters[1]) == "table" then
		filters = filters[1]
	end

	for _, i in ipairs(filters) do
		if FilterObjectMap[i](obj, env or {}) then
			return
		end
	end

	return obj
end

function SceneModel:ipairsHeros()
    if self.herosOrder == nil then
        self:refreshHerosOrder()
    end
    return ipairs(self.herosOrder)
end

function SceneModel:refreshHerosOrder()
	local iter1 = itertools.iter(self:getHerosMap(1):pairs())
	local iter2 = itertools.iter(self:getHerosMap(2):pairs())

	self.herosOrder = itertools.values(itertools.chain({
		iter1,
		iter2
	}))

	table.sort(self.herosOrder, function(o1, o2)
		return o1.id < o2.id
	end)
end

function SceneModel:ipairsAidHeros()
	if self.aidHerosOrder == nil then
		self.aidHerosOrder = itertools.values(self.aidHeros)

		table.sort(self.aidHerosOrder, function(a, b)
			local pa = a.unitCfg.frontPriority
			local pb = b.unitCfg.frontPriority

			if a:speed() ~= b:speed() then
				return a:speed() > b:speed()
			elseif pa ~= pb then
				return pb < pa
			else
				return a.id < b.id
			end
		end)
	end

	return ipairs(self.aidHerosOrder)
end

function SceneModel:ipairsAllHeros()
	local ret = {}

	for _, obj in self:ipairsHeros() do
		table.insert(ret, obj)
	end

	for _, obj in self.backHeros:order_pairs() do
		table.insert(ret, obj)
	end

	for _, obj in self.extraHeros:order_pairs() do
		table.insert(ret, obj)
	end

	return ipairs(ret)
end

function SceneModel:ipairsOnSiteHeros()
	local ret = {}

	for _, obj in self:ipairsHeros() do
		table.insert(ret, obj)
	end

	for _, obj in self.extraHeros:order_pairs() do
		table.insert(ret, obj)
	end

	return ipairs(ret)
end

function SceneModel:isObjectOnSite(id)
	return self.backHeros:find(id) == nil
end

function SceneModel:ipairsNatureCountHeros()
	local ret = {}

	for _, obj in self:ipairsHeros() do
		table.insert(ret, obj)
	end

	for _, obj in self.extraHeros:order_pairs() do
		if obj.extraObjectCsvCfg.natureIncluded then
			table.insert(ret, obj)
		end
	end

	return ipairs(ret)
end

function SceneModel:createBuffCollection()
	local ret = CCollection.new()

	ret:add_index(CCollection.index.new("buff"):order(BuffModel.BuffCmp):default())
	ret:add_index(CCollection.index.new("easyEffectFunc"):hash({
		"csvCfg",
		"easyEffectFunc"
	}))
	ret:add_index(CCollection.index.new("groupID"):hash({
		"csvCfg",
		"group"
	}))
	ret:add_index(CCollection.index.new("flagID"):hash({
		"csvCfg",
		"buffFlag"
	}))
	ret:add_index(CCollection.index.new("cfgId"):hash("cfgId"))

	return ret
end

function SceneModel:createBuffMap()
	return CMap.new(BuffModel.BuffCmp)
end

function SceneModel:checkBackStageObjs()
	local function cmpH(a, b)
		local data1 = a:getEventByKey(battle.ExRecordEvent.frontStage)
		local data2 = b:getEventByKey(battle.ExRecordEvent.frontStage)
		local p1 = data1 and data1.frontPriority or battle.FrontStagePriority.defaultPriority
		local p2 = data2 and data2.frontPriority or battle.FrontStagePriority.defaultPriority

		if p1 == p2 then
			return a.id < b.id
		else
			return p2 < p1
		end
	end

	local deleteObjs = {}

	for _, obj in self.backHeros:order_pairs(cmpH) do
		local data = obj:getEventByKey(battle.ExRecordEvent.frontStage)

		if data then
			local seat

			if data.frontStageTargetFormula then
				seat = data.frontStageTargetFormula()
			else
				seat = data.frontStageTarget

				if not self:isSeatEmptyWithFollowType(data.seatType, seat, obj) then
					seat = nil
				end
			end

			if seat then
				data.frontStageTarget = seat

				obj:doFrontStage()
			elseif not data.waiting then
				if data.isFailDelete then
					table.insert(deleteObjs, obj)
				end

				obj:cleanEventByKey(battle.ExRecordEvent.frontStage)
			end
		end
	end

	for _, obj in ipairs(deleteObjs) do
		self:onObjDel(obj)
	end
end

function SceneModel:overAssignTypeBuffs(type)
	local flag

	if type == "markId" then
		for _, obj in self:ipairsHeros() do
			local csv = gGameEndSpeRuleCsv[obj.markID]

			if csv then
				for _, cfgId in ipairs(csv.buffID) do
					local buff = obj:getBuff(cfgId)

					if buff and not buff.csvCfg.waveInherit then
						buff:overClean()
					end
				end
			end
		end
	end
end

function SceneModel:waitJumpOneMultWave(continue)
	if not continue then
		return self:modelWait("jump_mult_wave", self.waitJumpOneMultWave)
	end

	self.play:onMultWaveEffectClean()
end

function SceneModel:isSeatEmpty(seat)
	local obj = self:getObjectBySeat(seat)

	if obj and not obj:isRealDeath() then
		return false
	end

	if self.recordBuffManager:getRecord(battle.OverlaySpecBuff.occupiedSeat):isSeatExitObj(seat) then
		return false
	end

	local lastInfo = self:getSpecialSceneInfo()

	if lastInfo then
		return lastInfo:isSeatEmpty(seat)
	end

	if not self:isForceExistEmptySeat(seat <= 6 and 1 or 2) then
		return false
	end

	return true
end

function SceneModel:isSeatEmptyWithFollowType(type, seat, obj)
	type = type or battle.FrontStageSeatType.real

	local emyptyCheckFunc = {
		[battle.FrontStageSeatType.real] = function()
			return self:isSeatEmpty(seat)
		end,
		[battle.FrontStageSeatType.follow] = function()
			local isEmpty = true

			for _, oldExObj in self.extraHeros:order_pairs() do
				if oldExObj.seat == seat and oldExObj.followMark == obj.followMark then
					isEmpty = false

					break
				end
			end

			return isEmpty
		end
	}

	if obj.mode == battle.ObjectType.Normal then
		return self:isSeatEmpty(seat)
	else
		return emyptyCheckFunc[type]()
	end
end

function SceneModel:getForceEmptySeatCount(force)
	local playNumber = self.sceneConf.playNumber or self.play.ForceNumber
	local objCount = 0
	local stepNum = force == 1 and 0 or self.play.ForceNumber
	local occupiedSeat = self.recordBuffManager:getRecord(battle.OverlaySpecBuff.occupiedSeat)

	for seat = 1 + stepNum, self.play.ForceNumber + stepNum do
		local obj = self:getObjectBySeat(seat)

		if obj and not obj:isRealDeath() or occupiedSeat:isSeatExitObj(seat) then
			objCount = objCount + 1
		end
	end

	objCount = objCount + occupiedSeat:sum(force)

	local num = math.max(playNumber - objCount, 0)

	return num
end

function SceneModel:isForceExistEmptySeat(force)
	return self:getForceEmptySeatCount(force) > 0
end

function SceneModel:waitSecondAttack(resume)
	self:modelWait("second_attack", function(self, continue)
		if continue then
			return resume()
		end
	end)
end

local function canFieldBuffEffect(scene, buff, obj)
	if buff.fieldType == battle.FieldType.newField then
		local CourtMap = scene.fieldManager.CourtMap
		local force = scene.fieldManager:getAbsForce(buff.id)

		if force == CourtMap.both or force == obj.force then
			return true
		else
			return false
		end
	end

	return true
end

local function triggerFieldBuffOnPoint(scene, buff, obj)
	if buff.isOver then
		return
	end

	if canFieldBuffEffect(scene, buff, obj) then
		local trigger = {
			buffId = buff.id,
			obj = obj
		}
		local triggerPoint = battle.BuffTriggerPoint.onBuffTrigger

		if buff:isTrigger(triggerPoint, trigger) then
			buff:updateWithTrigger(triggerPoint, trigger)
		end
	end
end

function SceneModel:tirggerFieldBuffs(triggerObject, triggerBuff)
	if triggerObject then
		for _, buff in self.fieldBuffs:order_pairs() do
			triggerFieldBuffOnPoint(self, buff, triggerObject)
		end
	end

	if triggerBuff then
		for _, obj in self:ipairsHeros() do
			if not obj:isAlreadyDead() and not obj:leaveInfluenceBuff() then
				triggerFieldBuffOnPoint(self, triggerBuff, obj)
			end
		end
	end
end

function SceneModel:cleanFieldBuffInfo(buff)
	if not buff.isFieldBuff then
		return
	end

	if buff.fieldType ~= battle.FieldType.newField then
		return
	end

	self.fieldManager:clean(buff.id)
end

function SceneModel:getExtraBattleRoundMode()
	if self.play.extraBattleRoundData then
		return self.play.extraBattleRoundData.mode
	end

	return nil
end

function SceneModel:getSpecialSceneInfo()
	if self.specialRound:isEffect() then
		return self.specialRound
	end
end

local function OnSiteHolderFilter(buffData)
	local holder = buffData.buff.holder

	return self:isObjectOnSite(holder.id)
end

function SceneModel:ipairsOnSiteOverlaySpecBuff(key, filter)
	return self:ipairsOverlaySpecBuff(key, function(buffData)
		if filter then
			return filter(buffData) or OnSiteHolderFilter(buffData)
		end

		return OnSiteHolderFilter(buffData)
	end)
end

function SceneModel:getConvertGroupCache()
	local buffCfgId, cache = self:getExistLastSceneAlterBuff()

	if buffCfgId ~= -1 and cache then
		return cache
	end

	return nil
end

function SceneModel:checkCowWithBuff(buff)
	return
end

function SceneModel:setCsvObject(obj)
	self.csvObject = obj
end

function SceneModel:getCsvObject()
	return self.csvObject
end

function SceneModel:isSpecScene()
	local specSceneInfo = self:getSpecialSceneInfo()

	if specSceneInfo ~= nil then
		return true
	end

	return false
end

function SceneModel:getRoundAllWave(isAddSpecScene)
	local round = self.play.totalRound

	if isAddSpecScene then
		local lastInfo = self:getSpecialSceneInfo()

		if lastInfo then
			round = round + lastInfo.totalRound
		end
	end

	return round
end

local DamageCorrectRanageType = {
	moreAndLessEq = 2,
	moreEqAndLess = 1
}
local NumberMin = -99
local NumberMax = 99
local DamageCorrectRanageFunc = {
	[DamageCorrectRanageType.moreEqAndLess] = function(v, l, r)
		if r == NumberMax then
			return l <= v
		end

		return l <= v and v < r
	end,
	[DamageCorrectRanageType.moreAndLessEq] = function(v, l, r)
		if l == NumberMin then
			return v <= r
		end

		return l < v and v <= r
	end
}
local DamageCorrectFormulaFunc = {
	[battle.damageCorrectFormulaType.stage] = function(value, newValue, csvItem, index)
		return value * csvItem.rate, false
	end,
	[battle.damageCorrectFormulaType.segLess] = function(value, newValue, csvItem, index)
		return csvItem.args[1] - (csvItem.args[1] - value) * csvItem.rate, false
	end,
	[battle.damageCorrectFormulaType.segMore] = function(value, newValue, csvItem, index)
		return csvItem.args[1] + (value - csvItem.args[1]) * csvItem.rate, false
	end,
	[battle.damageCorrectFormulaType.segIndex] = function(value, newValue, csvItem, index)
		if not index then
			printWarn("segIndex index is nil")

			index = 1
		end

		return value * (csvItem.args[index] or ConstSaltNumbers.one), false
	end,
	[battle.damageCorrectFormulaType.set] = function(value, newValue, csvItem, index)
		return csvItem.rate, false
	end
}

function SceneModel:applyDamageCorrect(process, value, attacker, target, index)
	if not gDamageCorrect[process] then
		return value
	end

	if self.sceneTag.pvpAttrTakeEffect ~= true then
		return value
	end

	if attacker.fightPoint < gCommonConfigCsv.correctFightPoint or target.fightPoint < gCommonConfigCsv.correctFightPoint then
		return value
	end

	local continue = true
	local newValue = value

	for k, v in ipairs(gDamageCorrect[process]) do
		if DamageCorrectRanageFunc[v.rangeType](value, v.range[1], v.range[2]) then
			newValue, continue = DamageCorrectFormulaFunc[v.formulaType](value, newValue, v, index)

			if continue == false then
				break
			end
		end
	end

	return newValue
end

local traceback_ = debug.traceback
-- local sendException_ = ymdump.sendException
local first = true

local function errorInWindows(fmt, ...)
	local msg = string.format(fmt, ...)

	if editorInWindows then
		error(msg)

		return
	end

	if first and LOCAL_LANGUAGE == "cn" then
		-- sendException_(msg .. "\n" .. traceback_())
	end

	first = false
end

local skillProcessMap = {}
local initMap

function initMap(...)
	initMap = display.showData

	return initMap(...)
end

function SceneModel:getCfgSkillProcess(skillId)
	if self.data.skill_process then
		local data = self.data.skill_process

		self.data.skill_process = nil
		skillProcessMap = initMap(data)
	end

	local skillCfg = csv.skill[skillId]
	local skillProcess = skillProcessMap[skillId] or skillCfg.skillProcess

	if not skillProcess then
		errorInWindows("skill=%s, cfgSkillProcess=%s skillProcess is nil", skillId, dumps(skillCfg.skillProcess))
	end

	return skillProcess or {}
end

local SceneSendMark = setmetatable({}, {
	__mode = "k"
})

function SceneModel:battleReport(desc, traceback)
	if ANTI_AGENT then
		return
	end

	if device.platform == "windows" then
		return
	end

	if SceneSendMark[self] or self.isRecord then
		return
	end

	SceneSendMark[self] = true

	local record = table.shallowcopy(self.data)

	record.sceneID = self.sceneID or 0
	record.gateType = self.gateType or 0

	battleReport({
		play_record = record,
		traceback = traceback or "",
		desc = desc or ""
	})
end

function SceneModel:triggerWhenSeatEmpty(forceMap, seat, buffInfo)
	local triggerInfo = {
		mode = 1,
		forceMap = forceMap,
		seat = seat
	}

	if buffInfo then
		triggerInfo.mode = 2
		triggerInfo.group = buffInfo.group
	end

	for _, obj in self:ipairsHeros() do
		obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onSeatEmpty, triggerInfo)
	end
end

function SceneModel:influenceSceneBuff(itype, obj, state)
	self.recordBuffManager:influenceSceneBuff(itype, obj, state)
end

function SceneModel:checkViewSync()
	for _, obj in self.extraHeros:order_pairs() do
		obj:syncViewSeat()
	end
end
