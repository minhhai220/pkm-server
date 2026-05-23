-- chunkname: @src.battle.models.play.gate

local AidManager = require("battle.models.module.aid")
local GateProcess = require("battle.models.play.gate_process")
local Gate = class("Gate")

battlePlay.Gate = Gate
Gate.ForceNumber = 6
Gate.ObjectNumber = 12
Gate.OperatorArgs = {
	canSkip = false,
	canSpeedAni = false,
	canPause = false,
	canHandle = false,
	isFullManual = false,
	isAuto = true
}

local EmptyAction = {
	0,
	0,
	0
}

Gate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Normal
}

local RoundByRoundCheckEnum = {
	SelfForceNotFail = 1,
	WinOfMore = 2
}

Gate.PlayCsvFunc = {}
Gate.SpecEndRuleCheck = {}
Gate.SpecEndRuleCheckArgs = {}

function Gate:ctor(scene)
	self.scene = scene
	self.curRound = 0
	self.curBattleRound = 0
	self.totalRound = 0
	self.totalRoundBattleTurn = 0
	self.curHero = nil
	self.nextHeros = {}
	self.roundHasAttackedHeros = {}
	self.roundLeftHeros = {}
	self.roundHasAttackedHistory = {}
	self.lastRoundAttackedHistory = {}
	self.attackerArray = {}
	self.aidAttackerArray = {}
	self.battleTurnTriggerArray = {}
	self.summonHeros = {}
	self.result = nil
	self.nowChooseID = nil
	self.curBattleRoundAttack = false
	self.isBossBattle = false
	self.battleTurnInfoTb = {}
	self.speedSortRule = {}
	self.statsRecordTb = {}
	self.forceAdd = {}
	self.recoverMp2RoundLimit = 3
	self.operateForce = scene.data.operateForce or 1
	self.handleInput = {}
	self.curHeroRoundInfo = {}
	self.attackSign = {}
	self.hasAttackedSign = {}
	self.lethalDatas = {}
	self.actionSend = {}
	self.specModuleFunc = nil
	self.battleRoundTriggerId = nil
	self.secondAttackFunc = nil
	self.fullRoundInfo = {}
	self.weathers = {
		{},
		{}
	}
	self.aidManager = AidManager.new(self)
	self.moduleProcess = GateProcess.new()

	self:newGroupRound()
	self:ctorWave()
end

function Gate:initFightOperatorMode()
	local opeArgs = {}
	local lockAutoFight = self.scene.sceneTag or {}

	for k, v in pairs(self.OperatorArgs) do
		opeArgs[k] = v
	end

	opeArgs.canHandle = battleEasy.ifElse(lockAutoFight.canHandle ~= nil, lockAutoFight.canHandle, opeArgs.canHandle)
	opeArgs.isAuto = battleEasy.ifElse(lockAutoFight.isAuto ~= nil, lockAutoFight.isAuto, opeArgs.isAuto)

	self.scene:setAutoFight(opeArgs.isAuto)
	self.scene:setFullManual(opeArgs.canHandle and opeArgs.isFullManual)
	gRootViewProxy:notify("setOperators", opeArgs)
end

function Gate:init(data)
	self.data = data

	self:initFightOperatorMode()
	self:onInitGroupRoundSupply()
	self:onProcessSupply()
	self:initWeatherDatas()
	self.aidManager:init(self.scene.gateType)
end
-- 将各种形态的 extra 统一成一维：{ {weather=.., arms={}}, {weather=.., arms={}} }
local function extraTo1D(extra)
    local DEF = {weather = 0, arms = {}}

    local function norm_one(e)
        if type(e) ~= "table" then return {weather = 0, arms = {}} end
        local w = tonumber(e.weather) or 0
        local a = type(e.arms) == "table" and e.arms or {}
        return {weather = w, arms = a}
    end

    if type(extra) ~= "table" then
        return {DEF, DEF}
    end

    -- ① 二维：extra[1][1].weather 这种
    if type(extra[1]) == "table" and type(extra[1][1]) == "table" then
        local e11 = extra[1] and extra[1][1] or DEF
        local e21 = extra[2] and extra[2][1] or DEF
        return { norm_one(e11), norm_one(e21) }
    end

    -- ② 一维数组：{ {..}, {..} }
    if type(extra[1]) == "table" or type(extra[2]) == "table" then
        return { norm_one(extra[1]), norm_one(extra[2]) }
    end

    -- ③ 含任意整数键：如 [1]、[-4]、[7]…… 以及可能还带根上的 weather/arms
    local candidates = {}         -- k(number) -> table
    for k, v in pairs(extra) do
        if type(k) == "number" and type(v) == "table" then
            candidates[k] = v
        end
    end

    -- 选我方
    local me = candidates[1]
    if not me then
        -- 最小正整数键
        local bestPosK, bestPosV
        local anyK, anyV
        for k, v in pairs(candidates) do
            if k > 0 and (not bestPosK or k < bestPosK) then
                bestPosK, bestPosV = k, v
            end
            if anyK == nil then anyK, anyV = k, v end
        end
        me = bestPosV or anyV
    end
    -- 根上的扁平字段兜底
    if not me and (extra.weather ~= nil or extra.arms ~= nil) then
        me = extra
    end

    -- 选敌方
    local enemy = candidates[2]           -- 优先 key==2
                 or candidates[-4]        -- 再尝试 -4（有的服用这个表示对方/敌方）
    if not enemy then
        -- 任取一个负数键
        for k, v in pairs(candidates) do
            if k < 0 then enemy = v; break end
        end
    end
    if not enemy and me then
        -- 任取一个不是 me 的候选
        for _, v in pairs(candidates) do
            if v ~= me then enemy = v; break end
        end
    end

    return { norm_one(me), norm_one(enemy) }
end

function Gate:initWeatherDatas()
	local extra = self.data.extraOut or {
		{},
		{}
	}

	if not self.data.multipGroup then
		table.insert(self.weathers[1], extra[1] and extra[1].weather)
		table.insert(self.weathers[2], extra[2] and extra[2].weather)
	else
		for i = 1, 2 do
			for _, forceExtra in ipairs(extra[i]) do
				if forceExtra.weather then
					table.insert(self.weathers[i], forceExtra.weather)
				end
			end
		end
	end
end

function Gate:waveAddWeathers(force)
	local realForce = force == self.operateForce and 1 or 2

	if next(self.weathers[force]) then
		self.scene.buffGlobalManager:setWeatherData(realForce, self.weathers[force][1])
		table.remove(self.weathers[force], 1)
	end
end

function Gate:weatherChosen(force)
	local realForce = force == self.operateForce and 1 or 2

	self.scene.buffGlobalManager:enterTimePiontChosen(self.scene, realForce)
end

function Gate:getEnemyRoleOutT(waveId, groupRound)
	local enemiesData = {}
	local monsterCfg = self:getMonsterCsv(self.scene.sceneID, waveId)

	if not monsterCfg then
		return {}
	end

	local monsters = monsterCfg.monsters

	for idx, unitId in ipairs(monsters) do
		if unitId > 0 then
			local isBoss = false
			local roleData = {}

			if monsterCfg.bossMark and monsterCfg.bossMark[idx] == 1 then
				isBoss = true
			end

			roleData.roleId = unitId
			roleData.level = self.scene.sceneLevel
			roleData.skillLevel = self.scene.skillLevel
			roleData.showLevel = self.scene.showLevel
			roleData.roleForce = 2
			roleData.isMonster = true
			roleData.isBoss = isBoss
			roleData.advance = 0
			enemiesData[idx + self.ForceNumber] = roleData
		end
	end

	return {
		[waveId] = enemiesData
	}
end

function Gate:cleanPreviousObjs(force, onlyDelDead)
	local forces = self.scene:getHerosMap(force == self.operateForce and 1 or 2)

	for _, obj in forces:order_pairs() do
		if not onlyDelDead or obj:isDeath() then
			self.scene:onObjDel(obj)
		end
	end

	if not onlyDelDead then
		forces:clear()
	end
end

function Gate:getAidData(force, waveId)
	if not self.data.aidRoleOut then
		return
	end

	local aidDatas = self.data.aidRoleOut[force] or {}

	if self.groupRoundLimit > 1 then
		if waveId == 1 then
			return aidDatas[self.groupRound]
		end

		return
	end

	return aidDatas[self.curWave]
end

function Gate:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	self:cleanPreviousObjs(force, onlyDelDead)

	local realForce = force == self.operateForce and 1 or 2
	local datas = roleOutT or self.data.roleOut
	local wavesData = waveId and datas[waveId] or datas
	local datas2 = roleOutT2 or self.data.roleOut2
	local wavesData2 = waveId and datas2[waveId] or datas2
	local wavesAidData = self:getAidData(force, waveId)
	local stepNum = force == 1 and 0 or self.ForceNumber
	local newAddObjs = {}

	for idx = 1 + stepNum, self.ForceNumber + stepNum do
		local roleData = wavesData[idx]
		local seat = self.operateForce == 2 and battleEasy.mirrorSeat(idx) or idx

		if roleData then
			local obj = self:createObjectModel(force, seat)

			if wavesData2 and next(wavesData2) then
				roleData.role2Data = wavesData2[idx]
			end

			obj:init(roleData)
			self.scene:addObj(realForce, seat, obj)

			if obj.isBoss then
				self:setBoss(obj)
			end

			table.insert(newAddObjs, obj)
		end

		local roleAidData = wavesAidData and wavesAidData[idx]

		if roleAidData and battleEasy.checkAidData(roleAidData) then
			local aidObj = self:createAidObjectModel(force, seat)

			roleAidData.type = battle.ObjectType.Aid

			aidObj:init(roleAidData)
			self.scene:addAidObj(aidObj)
		end
	end

	if force == self.operateForce and (not waveId or waveId == 1) then
		self.scene.forceRecordTb[1].herosStartCount = table.length(newAddObjs)
	end

	self.scene:createGroupObj(force, battle.SpecialObjectId.teamShiled)
	table.insert(self.forceAdd, force)

	return newAddObjs
end

function Gate:addCardRolesInProcess(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	local addObjs = self:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)

	for _, obj in ipairs(addObjs) do
		self:addRoundLeftHero({
			obj = obj
		})
		obj:initedTriggerPassiveSkill()
	end
end

function Gate:waveAddCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	local backHeros = self.scene.backHeros

	for _, obj in backHeros:order_pairs() do
		if obj.force == force or obj:isDeath() then
			self.scene:onObjDel(obj)
		end
	end

	self:waveAddWeathers(force)
	self:waveResetAid(force)
	self:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	gRootViewProxy:notify("waveAddCardRoles", self.operateForce == force and 1 or 2)
end

function Gate:waveResetAid(force)
	self.aidManager:waveAddCardRoles(self.operateForce == force and 1 or 2, self.curWave, self.data.aidRoleOut or {
		{},
		{}
	})
end

function Gate:addCardRole(seat, roleData, backStage, belongForce, replaceObj, summoner)
	local force = belongForce
	local oldObj = self.scene:getObjectBySeatExcludeDead(seat)
	local isFollowMode = roleData.mode ~= battle.ObjectType.Normal

	if isFollowMode then
		local followMark = roleData.followMark

		for _, oldExObj in self.scene.extraHeros:order_pairs() do
			if oldExObj.seat == seat and oldExObj.followMark == followMark then
				if replaceObj then
					self.scene:onObjDel(oldExObj)
				else
					return
				end
			end
		end
	elseif oldObj then
		if replaceObj then
			self.scene:onObjDel(oldObj)
		else
			return
		end
	end

	if backStage then
		seat = -1
	end

	local function addToBackStage(obj)
		obj.force = force

		obj.view:proxy():updateFaceTo(obj.force)
		self.scene:addBackStageObj(obj)
		obj:influenceSceneBuff(battle.InfluenceSceneBuffType.leave, true)
	end

	if roleData then
		local obj

		if isFollowMode then
			obj = self:createExtraObjectModel(force, seat)

			obj:init(roleData)

			local battleTurnFollowMode = obj.extraObjectCsvCfg.battleTurnFollowMode
			local benchmarkObj = battleTurnFollowMode == 1 and oldObj or summoner

			if benchmarkObj then
				benchmarkObj:addSimpleBuff(battle.OverlaySpecBuff.followObject, obj, {})
			end

			obj.force = force

			self.scene:addExtraObj(obj)
		else
			obj = self:createObjectModel(force, seat)

			obj:init(roleData)

			if backStage then
				addToBackStage(obj)
			elseif self.scene:isSeatEmpty(seat) then
				self.scene:addObj(force, seat, obj)
			else
				addToBackStage(obj)

				local data = {
					transferMp = 0,
					waiting = true,
					frontStageTarget = seat,
					roundMark = self.curWave * 1000 + self.totalRoundBattleTurn,
					stageRound = self.scene.curRound
				}

				obj:addExRecord(battle.ExRecordEvent.frontStage, data)

				backStage = true
			end
		end

		if obj.isBoss then
			self:setBoss(obj)
		end

		summoner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderSummon, {
			obj = battleCsv.CsvObject.newWithCache(obj)
		})
		gRootViewProxy:proxy():modelCallSprite(obj, "forceSetVisible", false)

		return obj, backStage
	end
end

function Gate:beforeAddSummonRole(seat, roleData, replaceObj, isFollowMode)
	local oldObj = self.scene:getObjectBySeatExcludeDead(seat)
	local isFollowMode = roleData.mode ~= battle.ObjectType.Normal

	if isFollowMode then
		local followMark = roleData.followMark

		for _, oldExObj in self.scene.extraHeros:order_pairs() do
			if oldExObj.seat == seat and oldExObj.followMark == followMark then
				if replaceObj then
					self.scene:onObjDel(oldExObj)
				else
					return false
				end
			end
		end
	elseif oldObj then
		if replaceObj then
			self.scene:onObjDel(oldObj)
		else
			return false
		end
	end

	return true, oldObj
end

function Gate:addSummonRole(seat, roleData, backStage, belongForce, replaceObj, summoner)
	local force = belongForce
	local isFollowMode = roleData.mode ~= battle.ObjectType.Normal
	local isContinue, oldObj = self:beforeAddSummonRole(seat, roleData, replaceObj, isFollowMode)

	if isContinue == false then
		return
	end

	if backStage then
		seat = -1
	end

	local function addToBackStage(obj)
		obj.force = force

		obj.view:proxy():updateFaceTo(obj.force)
		self.scene:addBackStageObj(obj)
		obj:influenceSceneBuff(battle.InfluenceSceneBuffType.leave, true)
	end

	if roleData then
		local obj
		local initSimpleBuffs = {}

		if isFollowMode then
			obj = self:createExtraObjectModel(force, seat)

			obj:init(roleData)

			obj.force = force

			local battleTurnFollowMode = obj.extraObjectCsvCfg.battleTurnFollowMode
			local benchmarkObj = battleTurnFollowMode == 1 and oldObj or summoner

			if benchmarkObj then
				benchmarkObj:addSimpleBuff(battle.OverlaySpecBuff.followObject, obj, {})
			end

			if roleData.mode == battle.ObjectType.FollowNormal and backStage then
				addToBackStage(obj)
			else
				self.scene:addExtraObj(obj)
			end
		else
			obj = self:createObjectModel(force, seat)

			obj:init(roleData)

			obj.force = force

			if backStage then
				addToBackStage(obj)
			elseif self.scene:isSeatEmpty(seat) then
				self.scene:addObj(force, seat, obj)
			else
				addToBackStage(obj)

				local data = {
					transferMp = 0,
					waiting = true,
					frontStageTarget = seat,
					roundMark = self.curWave * 1000 + self.totalRoundBattleTurn,
					stageRound = self.scene.curRound
				}

				obj:addExRecord(battle.ExRecordEvent.frontStage, data)

				backStage = true
			end
		end

		if obj.isBoss then
			self:setBoss(obj)
		end

		summoner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderSummon, {
			obj = battleCsv.CsvObject.newWithCache(obj)
		})
		gRootViewProxy:proxy():modelCallSprite(obj, "forceSetVisible", false)

		return obj, backStage
	end
end

function Gate:setBoss(obj)
	self.curBoss = obj
end

function Gate:createObjectModel(force, seat)
	return ObjectModel.new(self.scene, seat)
end

function Gate:createExtraObjectModel(force, seat)
	return ObjectExtraModel.new(self.scene, seat)
end

function Gate:createAidObjectModel(force, seat)
	local obj = ObjectAidModel.new(self.scene, seat)

	obj.force = force

	return obj
end

function Gate:doObjsAttrsCorrect(isLeftC, isRightC)
	local sceneID = self.scene.sceneID

	if isLeftC then
		self.scene.forceRecordTb[1].totalFightPoint = self.scene:getTotalForceFightPoint(1)
	end

	if isRightC then
		local cfg = self:getMonsterCsv(sceneID, self.curWave)

		if cfg then
			for _, obj in self.scene:ipairsHeros() do
				if obj:serverForce() == 2 then
					obj:objAttrsCorrectMonster(cfg)
				end
			end
		end

		self.scene.forceRecordTb[2].totalFightPoint = self.scene:getTotalForceFightPoint(2)
	end

	local cfgl = gSceneAttrCorrect[sceneID]
	local cfgr = gSceneAttrCorrect[-sceneID]

	for _, obj in self.scene:ipairsHeros() do
		obj:clearPreCorrectCP()

		if isLeftC and obj:serverForce() == 1 or isRightC and obj:serverForce() == 2 then
			local cfg = self.scene:getSceneAttrCorrect(obj:serverForce())

			if next(cfg) then
				obj:objAttrsCorrectScene(cfg)
			end

			local objTotalCP = self.scene.forceRecordTb[obj.force].totalFightPoint or 0
			local objEnemyTotalCP = self.scene.forceRecordTb[3 - obj.force].totalFightPoint or 0

			if objTotalCP < objEnemyTotalCP then
				obj:objAttrsCorrectCP(objTotalCP, objEnemyTotalCP)
			end
		end

		if not obj:isAlreadyDead() then
			local key = obj.seat

			self.scene.extraRecord:addExRecord(battle.ExRecordEvent.totalHp, obj:hpMax(), key)
		end
	end
end

function Gate:triggerAllPassiveSkills()
	self.scene:onAllPassive(battle.PassiveSkillTypes.enter)

	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() then
			obj:initedTriggerPassiveSkill(true)
		end
	end

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onHolderAfterEnter)
end

function Gate:getSortOrderTb()
	if self.sortOrderTb then
		return self.sortOrderTb
	end

	return {
		1,
		2,
		3,
		4,
		5,
		6,
		7,
		8,
		9,
		10,
		11,
		12
	}
end

function Gate:ipairsByGateOrder()
	local order = self:getSortOrderTb()
	local i = 0

	return function()
		i = i + 1

		local idx = order[i]
		local k = idx and i

		return k, idx
	end
end

function Gate:initBySceneConf()
	self.waveCount = self.scene.sceneConf.sceneCount
	self.roundLimit = self.scene.sceneConf.roundLimit
end

function Gate:newGroupRound()
	self.groupRoundInit = {
		forceTeams = {}
	}
	self.groupRound = 0
	self.groupRoundLimit = 0
	self.groupResultList = {}
	self.groupRoleOut = {}

	self:initBySceneConf()
end

function Gate:getWaveInfo(force)
	return self.groupRoundInit.forceTeams[self.groupRound][force]
end

function Gate:isMultLast()
	return self.groupRound == self.groupRoundLimit
end

function Gate:isMultWaveEnd()
	return self.groupResultList[self.groupRound] ~= nil
end

function Gate:onPassOneMultWave(cb)
	if self.passOneMultWaveCallBack then
		return
	end

	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() then
			obj.view:proxy():onPassOneMultWaveClean()
		end
	end

	for _, aidObj in self.scene:ipairsAidHeros() do
		aidObj.view:proxy():onPassOneMultWaveClean()
	end

	gRootViewProxy:proxy():onPassOneMultWaveClean()
	gRootViewProxy:notify("updateLinkEffect", false)

	self.passOneMultWaveCallBack = cb

	self.scene:waitJumpOneMultWave()
end

function Gate:onMultWaveEffectClean()
	if self.passOneMultWaveCallBack then
		self.passOneMultWaveCallBack()

		self.passOneMultWaveCallBack = nil
	end

	self.scene.forceRecordObject = {}

	gRootViewProxy:notify("sceneClearAll")
end

function Gate:initGroupRound(round, leftLimit, rigLimit)
	self.groupRoundInit.forceTeams[round] = {}

	table.insert(self.groupRoundInit.forceTeams[round], {
		winCount = 0,
		waveIndex = 1,
		waveLimit = leftLimit
	})
	table.insert(self.groupRoundInit.forceTeams[round], {
		winCount = 0,
		waveIndex = 1,
		waveLimit = rigLimit
	})

	self.groupRoundLimit = math.max(self.groupRoundLimit, round)

	return self
end

function Gate:initGroupRoundAsSame(round, waveLimit)
	self:initGroupRound(round, waveLimit, waveLimit)

	return self
end

function Gate:initGroupRoundCheck(checkEndType)
	self.groupRoundInit.checkEndType = checkEndType

	return self
end

function Gate:isSkipGroupRound()
	return false
end

function Gate:startGroupRound(continue)
	self.groupRound = self.groupRound + 1
	self.curWave = 0

	while self:isSkipGroupRound() do
		self.groupRound = self.groupRound + 1
	end

	self.scene.sceneConf:multFixed(self.groupRound)
	self.scene:initBySceneConf()
	self:initBySceneConf()
	self:onInitRoleOutSupply()
	self.moduleProcess:notifyAndRun("onGroupRoundStart", {
		groupRound = self.groupRound,
		groupResult = self.groupResultList[self.groupRound - 1]
	})

	if self.groupRoundLimit > 1 then
		self.aidManager:initAidRoleOut(1, self.groupRound, self.data.aidRoleOut)
		gRootViewProxy:notify("StartGroupRound", self.groupRound, self.groupRoundLimit, self.groupResultList[self.groupRound - 1])
	end

	gRootViewProxy:notify("setWaveNumber", self.curWave, self.waveCount)
	self.scene:newWave()
end

function Gate:checkGroupRoundEnd(result)
	if not self.groupRoundInit.checkEndType then
		return true, result
	end

	local limit = table.length(self.groupRoundInit.forceTeams)
	local isFinal = self.groupRound == limit

	if self.groupRoundInit.checkEndType == Gate.GroupRoundCheckType.WinOfMore then
		local halfLimit = limit / 2

		if halfLimit < self.groupRound then
			local resultIndex = 0

			for _, v in ipairs(arraytools.merge({
				self.groupResultList,
				{
					result
				}
			})) do
				if v == battle.Const.Win then
					resultIndex = resultIndex + 1
				elseif v == battle.Const.Fail then
					resultIndex = resultIndex - 1
				end
			end

			if resultIndex ~= 0 then
				result = resultIndex > 0 and battle.Const.Win or battle.Const.Fail

				return true, result
			end
		end
	elseif self.groupRoundInit.checkEndType == Gate.GroupRoundCheckType.SelfForceNotFail then
		if result == battle.Const.Fail then
			return true, battle.Const.Fail
		elseif isFinal then
			return true, battle.Const.Win
		end
	end

	return false, result
end

function Gate:onGroupRoundEnd(result, isBattleEnd)
	self.moduleProcess:notifyAndRun("onGroupRoundEnd", {
		gate = self,
		groupRound = self.groupRound,
		result = result,
		isBattleEnd = isBattleEnd
	})
end

function Gate:endGroupRound(result)
	table.insert(self.groupResultList, result)
	self.scene:cleanInWaveGoon(true)
	self:onGroupRoundEnd(result, false)
	self:onGroupRoundEndSupply()
	self.scene:startGroupRound()
end

function Gate:ctorWave()
	self.waveInit = {}
	self.curWave = 0
	self.waveResult = nil
	self.waveResultHistory = {}
end

function Gate:initAfterWaveEnd(endType)
	self.waveInit.endType = endType

	return self
end

function Gate:initWaveCheck(checkEndType)
	self.waveInit.checkEndType = checkEndType

	return self
end

function Gate:newWaveAddObjsStrategy()
	battleEasy.logHerosInfo(self.scene, "newWave")

	if self.waveInit.endType then
		local leftNext, rigNext = false, false

		if self.curWave == 1 then
			leftNext = true
			rigNext = true
		elseif self.waveInit.endType == Gate.AfteWaveEndType.WinNext then
			leftNext = self.waveResult == battle.Const.Fail or self.waveResult == battle.Const.Draw
			rigNext = self.waveResult == battle.Const.Win or self.waveResult == battle.Const.Draw
		elseif self.waveInit.endType == Gate.AfteWaveEndType.AllClear then
			leftNext = true
			rigNext = true
		end

		if leftNext then
			local waveInfo = self:getWaveInfo(1)

			self:waveAddCardRoles2(1, self.groupRound, waveInfo.waveIndex)
		end

		if rigNext then
			local waveInfo = self:getWaveInfo(2)

			self:waveAddCardRoles2(2, self.groupRound, waveInfo.waveIndex)
		end

		self:doObjsAttrsCorrect(leftNext, rigNext)
	end

	self.moduleProcess:notifyAndRun("newWaveAddObjsStrategy", {
		gate = self,
		groupRound = self.groupRound,
		waveResultHistory = self.waveResultHistory,
		waveResult = self.waveResult
	})
	self:onWaveAddObjsStrategySupply()
end

function Gate:waveAddCardRoles2(force, groupRound, waveID)
	local backHeros = self.scene.backHeros

	for _, obj in backHeros:order_pairs() do
		if obj.force == force or obj:isDeath() then
			self.scene:onObjDel(obj)
		end
	end

	local groupRoleOut = self.groupRoleOut[groupRound]

	self:waveAddWeathers(force)
	self:addCardRoles(force, waveID, groupRoleOut.waveRoleOut[force], groupRoleOut.waveRoleOut2[force])
	gRootViewProxy:notify("waveAddCardRoles", self.operateForce == force and 1 or 2)
end

function Gate:onNewWavePlayAni()
	self.curWave = self.curWave + 1
	self.curRound = 0
	self.totalRoundBattleTurn = 0

	gRootViewProxy:notify("setWaveNumber", self.curWave, self.waveCount)
	gRootViewProxy:notify("playWaveAni", self.curWave, self.waveCount)
	battleEasy.queueEffect("delay", {
		lifetime = 300
	})
	self.scene:waitNewWaveAniDone()
end

function Gate:playEnterAnimation(cb)
	local selfAdd, enemyAdd = false, false

	for _, f in pairs(self.forceAdd) do
		if f == 1 then
			selfAdd = true
		elseif f == 2 then
			enemyAdd = true
		end
	end

	self.forceAdd = {}

	battleEasy.queueNotify("enterAnimation", selfAdd and self.scene:getForceIDs(1) or nil, enemyAdd and self.scene:getForceIDs(2) or nil, true)
	self.scene:insertPlayCustomWait("enter_animation", cb)
end

function Gate:onNewWave()
	battleEasy.queueEffect("delay", {
		lifetime = 1000
	})
	battleEasy.deferNotify(nil, "lockLifeBar", {
		isLock = false
	})
	self:newWaveAddObjsStrategy()
	self:playEnterAnimation(function()
		self:newWaveGoon()
	end)
end

function Gate:newWaveGoon()
	self:checkGuide(function()
		if self.curWave > 1 then
			self.scene:cleanInWaveGoon()
		end

		self.isBossBattle = false

		for _, obj in self.scene:ipairsAllHeros() do
			obj:onNewWave()

			if obj.force == 2 and obj.isBoss then
				self.isBossBattle = true
			end
		end

		self:newWaveGoonAfter()
	end, {
		round = battle.GuideTriggerPoint.Wave + self.curWave
	})
end

function Gate:newWaveGoonAfter()
	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)

	self.scene.realDeadCounter = 1
	self.nextHeros = {}

	gRootViewProxy:proxy():flushCurDeferList()

	return self.scene:newRound()
end

function Gate:onNewRound()
	self.curRound = self.curRound + 1
	self.totalRound = self.totalRound + 1
	self.curBattleRound = 0
	self.curHero = nil

	log.battle.gate.onNewRound({
		play = self
	})
	self.aidManager:triggerAidAttack(battle.aidTriggerType.RoundStartBefore)

	if self.curRound == 1 then
		self:triggerAllPassiveSkills()
		self:weatherChosen(1)
		self:weatherChosen(2)
		self.scene:triggerWhenSeatEmpty({
			[1] = true,
			[2] = true
		})
	end

	self.hasAttackedSign = {}
	self.roundHasAttackedHeros = {}
	self.roundLeftHeros = {}
	self.lastRoundAttackedHistory = self.roundHasAttackedHistory
	self.roundHasAttackedHistory = {}

	for _, obj in self.scene:ipairsHeros() do
		if obj and not obj:isRealDeath() then
			self:addRoundLeftHero({
				obj = obj
			})
		end
	end

	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)

	for _, obj in self.scene:ipairsHeros() do
		obj:onNewRound()
	end

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundStart)
	self.scene:checkObjsDeadState()
	gRootViewProxy:proxy():flushCurDeferList()
	self.aidManager:triggerAidAttack(battle.aidTriggerType.RoundStartAfter)
	self.scene:newRoundBattleTurn()
end

function Gate:getObjectBaseSpeedRankSortKey(obj)
	return obj.id
end

function Gate:dealWithSwapSpeed()
	local ret = {}
	local keyMap = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.swapSpeedRefresh, 1) or {}

	for _, obj in self.scene:ipairsHeros() do
		local swapData = obj:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.swapSpeed)

		if swapData and (swapData.oriSpeed == -1 or keyMap[swapData.groupKey]) then
			if not ret[swapData.groupKey] then
				ret[swapData.groupKey] = {
					datas = {},
					speeds = {}
				}
			end

			local nowSpeed = obj:speed()

			swapData.oriSpeed = nowSpeed

			table.insert(ret[swapData.groupKey].datas, swapData)
			table.insert(ret[swapData.groupKey].speeds, nowSpeed)
		end
	end

	for groupKey, tb in pairs(ret) do
		local datas = tb.datas
		local speeds = tb.speeds

		table.sort(datas, function(a, b)
			return a.sortKey > b.sortKey
		end)
		table.sort(speeds, function(a, b)
			return b < a
		end)

		for id, data in ipairs(datas) do
			data.newSpeed = speeds[id]
		end
	end

	self.scene.extraRecord:cleanEventByKey(battle.ExRecordEvent.swapSpeedRefresh, 1)
end

function Gate:getSpeedForRankSort(obj, relatively, rankData)
	local swapData = obj:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.swapSpeed)
	local baseSpeed = battleEasy.ifElse(relatively, obj:speed(0), obj:speed())

	if swapData and (not rankData.reset or not rankData.atOnce or not rankData.prophet) then
		return math.max(swapData.newSpeed + baseSpeed - swapData.oriSpeed, 0)
	end

	return baseSpeed
end

function Gate:setBattleRoundData(data)
	self.extraBattleRoundData = data
	self.extraBattleRoundData.mode = data.mode or battle.ExtraBattleRoundMode.normal
	self.battleRoundTriggerId = battleEasy.getRoundTriggerId(data.buffCfgId)
end

function Gate:getRoundLeftHeros(filterDelete)
	local tobeDel = {}
	local ret = itertools.filter(self.roundLeftHeros, function(idx, data)
		local obj = data.obj

		if not obj or obj:isRealDeath() then
			table.insert(tobeDel, idx)

			return nil
		end

		return data
	end)

	if filterDelete then
		for i = table.length(tobeDel), 1, -1 do
			table.remove(self.roundLeftHeros, tobeDel[i])
		end
	end

	return ret
end

function Gate:createTbForSort(datas)
	local tbForSort = {}

	for i, data in ipairs(datas) do
		local obj = data.obj
		local relatively = data.another and obj.unitID % 2 == 0

		table.insert(tbForSort, {
			key = i,
			speedPriority = obj.speedPriority,
			speed = self:getSpeedForRankSort(obj, relatively, data),
			objId = self:getObjectBaseSpeedRankSortKey(obj),
			reset = data.reset,
			atOnce = data.atOnce,
			prophet = data.prophet,
			buffCfgId = data.buffCfgId,
			force = obj.force,
			geminiSpecialDeal = relatively and 1 or 2
		})
	end

	return tbForSort
end

function Gate:speedRankSort(nextHero)
	self:dealWithSwapSpeed()

	local curLefts = self:getRoundLeftHeros(true)

	if nextHero then
		self.extraBattleRoundData = nil
	end

	if not next(curLefts) then
		self.attackSign = {}
		self.attackerArray = {}
		self.extraBattleRoundData = nil
		self.leftHerosFirstIndex = nil

		return false
	end

	local tbForSort = self:createTbForSort(curLefts)

	self:speedRankSortWithRule(tbForSort)

	local added = {}
	local sorted = {}

	self.attackSign = {}

	for k, v in ipairs(tbForSort) do
		local obj = curLefts[v.key].obj

		table.insert(sorted, obj)

		local unitID = 0
		local exUnitID = 0

		if obj.multiShapeTb then
			unitID = battleEasy.ifElse(obj.originUnitID % 2 ~= 0, obj.originUnitID, obj.data.role2Data.roleId)

			if not curLefts[v.key].another and obj.multiShapeTb[1] % 2 == obj.originUnitID % 2 then
				exUnitID = unitID
			end
		end

		if not curLefts[v.key].another then
			unitID = 0
		else
			exUnitID = unitID
		end

		local key = tostring(obj.id) .. tostring(exUnitID)

		if not added[key] then
			table.insert(self.attackSign, unitID)

			added[key] = true
		end
	end

	local firstData = tbForSort[1] and curLefts[tbForSort[1].key]

	if not nextHero then
		self:setBattleRoundData(firstData)
	end

	self:setLeftHerosIndex(firstData)

	self.attackerArray = sorted

	return true
end

function Gate:speedRankSortWithRule(tb)
	local function more(a, b)
		return b < a
	end

	local function less(a, b)
		return a < b
	end

	local sortFuncs = {
		{
			name = "prophet",
			checkFunc = more
		},
		{
			name = "reset",
			checkFunc = more
		},
		{
			name = "atOnce",
			checkFunc = more
		},
		{
			name = "speedPriority",
			checkFunc = more
		},
		{
			name = "speed",
			checkFunc = more
		},
		{
			name = "objId",
			checkFunc = less
		},
		{
			name = "geminiSpecialDeal",
			checkFunc = more
		}
	}

	table.sort(tb, function(a, b)
		for k, v in ipairs(sortFuncs) do
			local val1, val2 = a[v.name], b[v.name]

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

	for k, v in ipairs(self.speedSortRule) do
		v.sort(tb)
	end
end

function Gate:getExtraBattleRoundData(name)
	if self.extraBattleRoundData then
		return self.extraBattleRoundData[name]
	end
end

function Gate:setLeftHerosIndex(firstData)
	self.leftHerosFirstIndex = nil

	for id, data in ipairs(self.roundLeftHeros) do
		if firstData == data then
			self.leftHerosFirstIndex = id

			break
		end
	end
end

function Gate:getTopCardsAttrAvg(num)
	if not self.topCardsAttrAvg then
		self.topCardsAttrAvg = {}

		local attrTab = {
			"speed",
			"damage",
			"specialDamage",
			"hp",
			"defence",
			"specialDefence"
		}
		local topCards = self.data.top_cards_data and self.data.top_cards_data.top_cards or {}
		local card, attr

		for k, dbid in ipairs(topCards) do
			if num < k then
				break
			end

			attr = self.data.top_cards_data.card_attrs[dbid]

			for _, attrName in ipairs(attrTab) do
				self.topCardsAttrAvg[attrName] = (self.topCardsAttrAvg[attrName] or 0) + attr[attrName]

				if k == num then
					self.topCardsAttrAvg[attrName] = self.topCardsAttrAvg[attrName] / num
				end
			end
		end
	end

	return self.topCardsAttrAvg
end

function Gate:getSpeedRankArray()
	local added, attackerTb = {}, {}

	for _, obj in ipairs(self.aidAttackerArray) do
		if not added[obj.id] then
			table.insert(self.attackSign, 1, 0)
			table.insert(attackerTb, obj)

			added[obj.id] = true
		end
	end

	for k, obj in ipairs(self.attackerArray) do
		if not added[obj.id] or self.attackSign[k] ~= 0 then
			table.insert(attackerTb, obj)

			added[obj.id] = true
		end
	end

	local speedRankSign = arraytools.merge({
		self.attackSign,
		{
			0
		},
		self.hasAttackedSign
	})

	return arraytools.merge({
		attackerTb,
		{
			{
				seat = 99999
			}
		},
		self.roundHasAttackedHeros
	}), speedRankSign
end

function Gate:getSpeedRankArrayDeduplication()
	local added, ret, exObjs = {}, {}

	table.insert(ret, self.curHero)

	added[self.curHero.id] = true

	local array = self:getSpeedRankArray()

	for _, obj in ipairs(array) do
		if not added[obj.id] and obj.seat <= self.ObjectNumber then
			local pos = obj.id == self.curHero.id and 1 or table.length(ret) + 1

			table.insert(ret, pos, obj)

			added[obj.id] = true
		end
	end

	for _, exObj in self.scene.extraHeros:order_pairs() do
		if not added[exObj.id] and exObj.extraObjectCsvCfg.triggerBattleTurn then
			local pos = exObj.id == self.curHero.id and 1 or table.length(ret) + 1

			table.insert(ret, pos, exObj)

			added[exObj.id] = true
		end
	end

	return ret
end

function Gate:getObjsNotInSpeedRank()
	local hashTb = {}

	for _, obj in ipairs(self:getSpeedRankArray()) do
		if obj and obj.seat <= self.ObjectNumber then
			hashTb[obj.seat] = true
		end
	end

	local tb = {}

	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() and not hashTb[obj.seat] then
			table.insert(tb, obj)
		end
	end

	return tb
end

function Gate:onNewBattleTurn()
	self.battleRoundTriggerId = nil
	self.curBattleRound = self.curBattleRound + 1
	self.totalRoundBattleTurn = self.totalRoundBattleTurn + 1
	self.handleInput = nil

	BattleAssert.checkBattleTurnLoop(self.curBattleRound)
	battleEasy.queueNotify("newBattleTurnBefore")
	log.battle.gate.onNewBattleTurn({
		play = self
	})

	self.battleTurnInfoTb = {}

	self:onTurnStartSupply()

	local preNextHero = self:getPreNextHero()

	self:speedRankSort(preNextHero)

	self.battleTurnInfoTb.nextHero = preNextHero or self.attackerArray[1]
	self.battleTurnInfoTb.nextAttackerHero = self.attackerArray[1]

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onBattleTurnStartBefore)
	self.scene:onAuraEffect()

	local nextHero = self:getNextHero()
	local hasHero = self:speedRankSort(nextHero)

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onBattleTurnStart)
	self.scene:resetPlaceIdInfo(1)
	self.scene:resetPlaceIdInfo(2)

	if not hasHero and not nextHero then
		self:checkBattleState()

		return
	end

	self:setCurHero(nextHero)
	gRootViewProxy:proxy():flushCurDeferList()
	log.battle.gate.curHero({
		curHero = self.curHero
	})

	self.curHero.isInBattleTurn = true
	self.battleTurnTriggerArray = self:getSpeedRankArrayDeduplication()

	for i, obj in ipairs(self.battleTurnTriggerArray) do
		obj:onNewBattleTurn()
	end

	self.scene:checkObjsDeadState()
	self.curHero:updateSkillState(true)

	self.curBattleRoundAttack = self.curHero:canAttack()

	self.scene:addSummonObj()
	self.scene:onSubModulesNewBattleTurn()
	gRootViewProxy:proxy():flushCurDeferList()
	self.scene:onSubModulesNewBattleTurn2()
	self:autoChoose()
	self.scene:waitNewBattleRoundAniDone()
end

function Gate:newBattleTurnGoon()
	self:checkGuide(function()
		if self.curHero and not self.curHero:isAlreadyDead() then
			self:onceBattle()
		else
			self:checkBattleState()
		end
	end, {
		heroId = self.curHero.seat
	})
end

function Gate:getNextHero()
	self.aidAttackerArray = self:getAidNextHero()

	local delIdx = {}
	local obj

	for idx, v in ipairs(self.nextHeros) do
		obj = self.scene:getObjectExcludeDead(v) or self.scene:getAidObj(v)

		if obj then
			local data = obj.extraRoundData:back()

			obj.curExtraDataIdx = obj.extraRoundData:find(data) or 0

			if data and not obj:checkCanExtraAttack(data) then
				obj.extraRoundData:erase(obj.curExtraDataIdx)
				obj:resetExtraDataIdx()
				table.insert(delIdx, idx)

				obj = nil
			else
				table.insert(delIdx, idx)
			end
		else
			table.insert(delIdx, idx)
		end

		if obj then
			break
		end
	end

	for i = table.length(delIdx), 1, -1 do
		table.remove(self.nextHeros, delIdx[i])
	end

	return obj
end

function Gate:getAidNextHero(force)
	local aidObjs = {}

	for _, v in ipairs(self.nextHeros) do
		local obj = self.scene:getAidObj(v)

		if obj and (not force or obj.force == force) then
			table.insert(aidObjs, obj)
		end
	end

	return aidObjs
end

function Gate:getPreNextHero()
	local objExtraRoundIndex = {}

	for idx, v in ipairs(self.nextHeros) do
		local obj = self.scene:getObjectExcludeDead(v)

		if obj then
			objExtraRoundIndex[obj.id] = objExtraRoundIndex[obj.id] or 1

			local data = obj.extraRoundData:index(objExtraRoundIndex[obj.id])

			if data then
				objExtraRoundIndex[obj.id] = objExtraRoundIndex[obj.id] + 1

				if not obj:checkCanExtraAttack(data) or filterRoundType == 1 then
					obj = nil
				end
			end
		end

		if obj then
			return obj
		end
	end
end

function Gate:setCurHero(nextHero)
	self.curHeroRoundInfo = {}
	self.curHero = nextHero

	if not self.curHero then
		self.curHero = self.attackerArray[1]

		if self.leftHerosFirstIndex then
			self.curHeroRoundInfo = self.roundLeftHeros[self.leftHerosFirstIndex]

			local buffBattleRoundInfo = self.curHero:getOverlaySpecBuffBy(battle.OverlaySpecBuff.buffBattleRound, function(data)
				return data.id == self.curHeroRoundInfo.id
			end)

			if buffBattleRoundInfo then
				buffBattleRoundInfo.isTakeEffect = true

				buffBattleRoundInfo.buff:over()
			end

			table.remove(self.roundLeftHeros, self.leftHerosFirstIndex)

			self.leftHerosFirstIndex = nil
		end

		self.battleTurnInfoTb.nextHero = self.attackerArray[2]
		self.battleTurnInfoTb.nextAttackerHero = self.attackerArray[2]
	else
		self.battleTurnInfoTb.nextHero = self:getPreNextHero() or self.attackerArray[1]
		self.battleTurnInfoTb.nextAttackerHero = self.attackerArray[1]
	end
end

function Gate:isPlaying()
	return self.result == nil
end

function Gate:isMyTurn()
	if self.curHero then
		local controlEnemyData = self.curHero:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.controlEnemy)

		if controlEnemyData then
			return controlEnemyData.buff.caster.force == 1
		end
	end

	return self.curHero and self.curHero.force == 1
end

function Gate:isNowTurnAutoFight()
	if self.scene.autoFight then
		return true
	end

	if not self:isMyTurn() and not self.scene.fullManual then
		return true
	end

	if self.curHero and (self.curHero:isSelfChargeOK() or self.curHero:isNeedAutoFightByBuff()) then
		return true
	end
end

function Gate:beginBattleTurn()
	local canAttack, breakInfo = self.curHero:canAttack()

	log.battle.gate.beginBattleTurn({
		curHero = self.curHero,
		breakInfo = breakInfo
	})

	return canAttack
end

function Gate:runBattleTurn(attack, target)
	self.curHero:toAttack(attack, target)
end

function Gate:isInSkillProcess()
	return self.curHero and self.curHero.curSkill and self.curHero.curSkill.isSpellTo
end

function Gate:endBattleTurn(target)
	local curHero = self.curHero

	gRootViewProxy:proxy():pushDeferList("playInEndBattleTurn")

	if curHero:getEventByKey(battle.ExRecordEvent.attackState) == 1 then
		curHero:addExRecord(battle.ExRecordEvent.attackState, 3)
	end

	for _, obj in ipairs(self.battleTurnTriggerArray) do
		obj:onBattleTurnEnd()
	end

	for _, obj in self.scene:ipairsAllHeros() do
		obj:onBattleTurnEndForce()
	end

	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onBattleTurnEnd)

	local playInEndBattleTurn = gRootViewProxy:proxy():popDeferList("playInEndBattleTurn")

	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndBattleTurn)
		end)
	end)
	self.scene:endBattleTurn()

	if not self.curBattleRoundAttack then
		battleEasy.queueEffect("delay", {
			lifetime = 300
		})
	end

	if not itertools.include(self.roundLeftHeros, function(data)
		return self.curHero and data.obj.id == self.curHero.id
	end) and not itertools.include(self.roundHasAttackedHeros, function(obj)
		return self.curHero and obj.id == self.curHero.id
	end) and not self.scene:isBackHeros(self.curHero) and (not self.curHero or not self.curHero:isExtraObj()) and (not self.curHero or self.curHero.type ~= battle.ObjectType.Aid) then
		self:setHeroIsAttacked(self.curHero)
	end

	if self.curHero and not self.scene:getExtraRoundMode() then
		table.insert(self.roundHasAttackedHistory, {
			id = self.curHero.id,
			force = self.curHero.force
		})
		self.curHero:recordRoundAttackedData(self.extraBattleRoundData)
	end

	if self.curHero then
		local notExistLeftHeros = not itertools.include(self.roundLeftHeros, function(data)
			return data.obj.id == self.curHero.id
		end)
		local notExistHasAttackedHeross = not itertools.include(self.roundHasAttackedHeros, function(obj)
			return obj.id == self.curHero.id
		end)

		if self.curHero.multiShapeTb and (notExistLeftHeros or notExistHasAttackedHeross) then
			local unitID = battleEasy.ifElse(self.curHero.originUnitID % 2 ~= 0, self.curHero.data.role2Data.roleId, self.curHero.originUnitID)

			if not notExistHasAttackedHeross then
				unitID = battleEasy.ifElse(self.curHero.originUnitID % 2 == 0, self.curHero.data.role2Data.roleId, self.curHero.originUnitID)
			end

			local isSecond = self.curHero.multiShapeTb[1] % 2 == self.curHero.originUnitID % 2

			if isSecond and notExistHasAttackedHeross or notExistLeftHeros then
				self:setHeroIsAttacked(self.curHero, unitID)
			end
		end
	end

	curHero.curTargetId = nil
	curHero.isInBattleTurn = false

	self:onTurnEndSupply()
	self:checkBattleState()
end

function Gate:onceBattle(targetId, skillId)
	if self.CommonArgs.AntiMode == battle.GateAntiMode.Operate then
		table.set(self.actionSend, self.groupRound, self.curRound, self.curBattleRound, {
			self.curHero.seat,
			targetId or 0,
			skillId or 0
		})
	end

	return self:_onceBattle(targetId, skillId)
end

function Gate:isWaitInput()
	return (self:isMyTurn() or self.scene.fullManual) and not self.scene.autoFight
end

function Gate:_onceBattle(targetId, skillId)
	self.curHero.handleChooseTarget = nil

	local attack, target

	if self.waitInput or self:beginBattleTurn() then
		if self.curHero and self.curHero:isNeedAutoFightByBuff() then
			attack, target = self:autoAttack()
		elseif self.curHero and self.curHero:isSelfChargeOK() then
			local sId = self.curHero.curSkill.id

			target = self.scene:getObjectExcludeDead(self.curHero.chargeSkillTargetId)

			if not target or target and target:isAlreadyDead() or target:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, {
				fromObj = self.curHero
			}) then
				target = self:autoChoose(sId)
			end

			attack = {
				skill = sId
			}
		elseif self:isWaitInput() then
			self.waitInput = true

			if not targetId or not skillId then
				return
			end

			if targetId == 0 and skillId == 0 then
				attack, target = self:autoAttack()
			else
				attack = {
					skill = skillId
				}
				target = self.scene:getObjectBySeatExcludeDead(targetId)
				self.curHero.handleChooseTarget = target
				self.nowChooseID = targetId
			end
		else
			attack, target = self:autoAttack()
		end

		self.waitInput = nil

		if self.scene.cowEnableCount > 0 then
			cow.proxyWatchBegin()

			self.preCalcLethalDatas = {
				{},
				{}
			}

			self:runBattleTurn(attack, target)

			local lethalDatas = clone(self.preCalcLethalDatas)

			self.preCalcLethalDatas = nil

			local revert = next(lethalDatas[1]) or table.length(lethalDatas[2]) > 0

			cow.proxyWatchEnd(revert)

			if revert then
				for _, objId in ipairs(lethalDatas[2]) do
					local obj = self.scene:getObjectExcludeDead(objId)

					if obj then
						obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLethal)
					end
				end

				self.lethalDatas = lethalDatas[1]

				self:runBattleTurn(attack, target)

				self.lethalDatas = {}
			end
		else
			self:runBattleTurn(attack, target)
		end
	end

	if self.secondAttackFunc then
		self.scene:waitSecondAttack(function()
			if not self.curHero:isAlreadyDead() then
				self.secondAttackFunc()

				self.secondAttackFunc = nil
			end

			self:endBattleTurn(target)
		end)
	else
		self:endBattleTurn(target)
	end
end

function Gate:autoAttack()
	gRootViewProxy:notify("selectedHero")

	local enemyForce = self:isMyTurn() and 2 or 1
	local skillID
	local ret = {}

	for id, skill in self.curHero:iterSkills() do
		if skill.skillType2 ~= battle.MainSkillType.PassiveSkill and skill:canSpell() then
			if not ret[skill.skillType2 + 1] then
				ret[skill.skillType2 + 1] = {}
			end

			table.insert(ret[skill.skillType2 + 1], id)
		end
	end

	if not next(ret) then
		return
	end

	local function skillByPriority(skillTable)
		if not skillTable then
			return
		end

		if table.length(skillTable) == 1 then
			return skillTable[1]
		end

		local curHeroSkills = self.curHero.skills
		local skillPriorityTab = skillTable
		local skillPriority = 0

		for i, skillID in ipairs(skillTable) do
			if curHeroSkills[skillID] and curHeroSkills[skillID].cfg.skillPriority then
				if skillPriority < curHeroSkills[skillID].cfg.skillPriority then
					skillPriorityTab = {}
					skillPriority = curHeroSkills[skillID].cfg.skillPriority

					table.insert(skillPriorityTab, skillID)
				elseif curHeroSkills[skillID].cfg.skillPriority == skillPriority then
					table.insert(skillPriorityTab, skillID)
				end
			end
		end

		return skillPriorityTab[ymrand.random(1, table.length(skillPriorityTab))]
	end

	local controlEnemyData = self.curHero and self.curHero:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.controlEnemy)
	local roundAttackInfo = self.curHero:getEventByKey(battle.ExRecordEvent.roundAttackInfo)

	if controlEnemyData then
		local skillPower = controlEnemyData.triggerSkillType2

		if skillPower and table.length(skillPower) > 0 then
			local skillTable = battleEasy.getItemInPowerMap(ret, skillPower)

			skillID = skillByPriority(skillTable)
		end
	elseif roundAttackInfo and roundAttackInfo.triggerSkillType2 then
		local skillPower = roundAttackInfo.triggerSkillType2
		local skillTable = battleEasy.getItemInPowerMap(ret, skillPower)

		skillID = skillByPriority(skillTable)
	elseif ret[battle.MainSkillType.BigSkill + 1] and table.length(ret[battle.MainSkillType.BigSkill + 1]) > 0 then
		skillID = skillByPriority(ret[battle.MainSkillType.BigSkill + 1])
	elseif ret[battle.MainSkillType.SmallSkill + 1] and table.length(ret[battle.MainSkillType.SmallSkill + 1]) > 0 then
		skillID = skillByPriority(ret[battle.MainSkillType.SmallSkill + 1])
	elseif ret[battle.MainSkillType.NormalSkill + 1] and table.length(ret[battle.MainSkillType.NormalSkill + 1]) > 0 then
		skillID = skillByPriority(ret[battle.MainSkillType.NormalSkill + 1])
	end

	if self.curHero:currentExtraBattleData().exAttackSkillID then
		skillID = self.curHero:currentExtraBattleData().exAttackSkillID
	elseif self.curHero:currentExtraBattleData().skillPowerMap then
		local skillPower = self.curHero:currentExtraBattleData().skillPowerMap

		if skillPower and table.length(skillPower) > 0 then
			local skillTable = battleEasy.getItemInPowerMap(ret, skillPower)

			skillID = skillByPriority(skillTable)
		end
	else
		local newSkillId = self:getExtraBattleRoundData("newSkillId")

		if newSkillId then
			if self.curHero.skillsMap[newSkillId] then
				skillID = newSkillId
			else
				local cfg = csv.skill[newSkillId]
				local skillType2 = cfg and cfg.skillType2

				if skillType2 and ret[skillType2 + 1] then
					skillID = skillByPriority(ret[skillType2 + 1])
				end
			end
		end
	end

	skillID = self.curHero.skillsMap[skillID] or skillID

	if not skillID then
		return {
			skill = skillID
		}
	end

	local target = self:autoChoose(skillID)

	log.battle.gate.autoAttack({
		object = self.curHero,
		target = target,
		skillID = skillID
	})

	return {
		skill = skillID
	}, target
end

local AUTO_CHOOSE_STEP = {
	function(self, skillId, enemyForce, _)
		local lastInfo = self.scene:getSpecialSceneInfo()

		if not lastInfo or not self.curHero then
			return false, enemyForce
		elseif not self.curHero:getExtraRoundMode() then
			return false, enemyForce
		end

		local autoSkill

		if skillId then
			autoSkill = self.curHero.skills[skillId]
		end

		if autoSkill then
			if autoSkill:isSameType(battle.SkillFormulaType.resumeHp) then
				return true, curObj
			end

			local targetTb = lastInfo:autoChoose(self.curHero)
			local len = table.length(targetTb)

			if len > 0 then
				local randIdx = ymrand.random(1, len)

				return true, targetTb[randIdx]
			end
		end

		return true, nil
	end,
	function(self, skillId, enemyForce, _)
		local autoSkill = csv.skill[skillId]

		if skillId and autoSkill then
			if autoSkill.hintTargetType == 0 then
				local sneerAtMeObj
				local curAttackObj = self.curHero

				if curAttackObj then
					sneerAtMeObj = curAttackObj:getSneerObj()

					if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
						fromObj = curAttackObj
					}) then
						sneerAtMeObj = curAttackObj:getCanAttackObjs(sneerAtMeObj.force)

						local retLength = table.length(sneerAtMeObj)

						sneerAtMeObj = retLength > 0 and sneerAtMeObj[ymrand.random(1, retLength)]
					end
				end

				if sneerAtMeObj and not sneerAtMeObj:isAlreadyDead() then
					return true, sneerAtMeObj
				end
			else
				enemyForce = 3 - enemyForce
			end
		end

		return false, enemyForce
	end,
	function(self, skillId, enemyForce, _)
		local curAttackObj = self.curHero
		local extraBattleData = curAttackObj and curAttackObj:currentExtraBattleData()

		if curAttackObj and extraBattleData.extraTargetId then
			local tar = self.scene:getFilterObject(extraBattleData.extraTargetId, {
				fromObj = curAttackObj
			}, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)

			if tar or extraBattleData.cantReselect then
				return true, tar
			end

			enemyForce = extraBattleData.isFixedForce and curAttackObj:currentExtraBattleData().targetForce or enemyForce
		end

		return false, enemyForce
	end,
	function(self, skillId, enemyForce, _)
		local curAttackObj = self.curHero

		if curAttackObj then
			local targetId = self:getExtraBattleRoundData("targetId")
			local tar = self.scene:getFilterObject(targetId, {
				fromObj = curAttackObj
			}, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)

			if tar then
				return true, tar
			end
		end

		return false, enemyForce
	end,
	function(self, skillId, enemyForce, _)
		if skillId then
			local autoSkill = self.curHero.skills[skillId] or self.curHero.passiveSkills[skillId] or self.curHero.curSkill

			if autoSkill then
				if autoSkill.skillFormulaType == battle.SkillFormulaType.fix then
					enemyForce = 3
				end

				local targets = autoSkill:getTargetsHint(autoSkill.cfg.autoHintChoose)

				if not next(targets) then
					targets = autoSkill:getTargetsHint()
				end

				return false, enemyForce, targets
			end
		end

		return false, enemyForce
	end,
	function(self, skillId, enemyForce, targets)
		local autoSkill

		if skillId then
			autoSkill = self.curHero.skills[skillId] or self.curHero.passiveSkills[skillId] or self.curHero.curSkill
		end

		local allCanAttackTargets = self.scene:getFilterObjects(enemyForce, {
			fromObj = self.curHero,
			skillFormulaType = autoSkill and autoSkill.skillFormulaType,
			ignoreBuff = autoSkill and autoSkill.targetIgnoreBuff
		}, battle.FilterObjectType.excludeEnvObj, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)

		if targets then
			local hash = itertools.map(targets, function(_, obj)
				return obj.id, true
			end)

			targets = {}

			for _, obj in ipairs(allCanAttackTargets) do
				if hash[obj.id] then
					table.insert(targets, obj)
				end
			end

			if not itertools.isempty(targets) then
				allCanAttackTargets = targets
			end
		end

		local addAttackRangeObjs = self.curHero and self.curHero:getAddAttackRangeObjs(autoSkill)

		allCanAttackTargets = battleEasy.attackRangeExtension({
			self = self.curHero,
			addAttackRangeObjs = addAttackRangeObjs
		}, allCanAttackTargets)

		return false, enemyForce, allCanAttackTargets
	end
}

function Gate:randomChooseWithPiority(targets)
	local maxPriority = 999999
	local curMaxPriority = -1
	local priorityTargets = {}

	for _, obj in ipairs(targets) do
		local data = obj:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.downPriorityOnAutoChoose)
		local priority = maxPriority - (data and data.priority or 0)

		curMaxPriority = math.max(curMaxPriority, priority)
		priorityTargets[priority] = priorityTargets[priority] or {}

		table.insert(priorityTargets[priority], obj)
	end

	local randIdx = ymrand.random(1, table.length(priorityTargets[curMaxPriority]))
	local target = priorityTargets[curMaxPriority][randIdx]

	return target
end

function Gate:autoChoose(skillId, force)
	local enemyForce = force or self.curHero and self.curHero.force == 1 and 2 or 1

	if self.curHero and self.curHero:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.controlEnemy) then
		enemyForce = 3 - enemyForce
	end

	local flag, targetOrForce, targets

	for _, func in ipairs(AUTO_CHOOSE_STEP) do
		flag, targetOrForce, targets = func(self, skillId, enemyForce, targets)

		if flag == true then
			return targetOrForce
		end

		enemyForce = targetOrForce
	end

	if itertools.isempty(targets) then
		printWarn("%s autoChoose no any target", tostring(skillId))

		self.nowChooseID = 0

		return
	end

	local controlEnemyData = self.curHero and self.curHero:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.controlEnemy)

	if controlEnemyData and skillId then
		local autoSkill = self.curHero.skills[skillId] or self.curHero.passiveSkills[skillId] or self.curHero.curSkill

		if autoSkill then
			local secFunc = {}
			local secTargets = arraytools.filter(targets, function(_, obj)
				return obj.force == self.curHero.force
			end)

			secFunc.input = "secSelected"

			if table.length(secTargets) ~= 0 then
				secFunc.process = controlEnemyData.targetsFunc1
			else
				secTargets = targets
				secFunc.process = controlEnemyData.targetsFunc2
			end

			secTargets = battleTarget.targetFinder(self.curHero, target, secFunc, {
				secSelectObjs = secTargets
			})

			if table.length(secTargets) ~= 0 then
				targets = secTargets
			end
		end
	end

	local target = self:randomChooseWithPiority(targets)

	self.nowChooseID = target.seat

	return target
end

function Gate:checkBothAllRealDead()
	return self:checkForceAllRealDead(1) and self:checkForceAllRealDead(2)
end

function Gate:checkForceAllRealDead(force)
	local forces = self.scene:getHerosMap(force)
	local hasAlive = itertools.include(forces, function(obj)
		return obj and not obj:isRealDeath()
	end)

	hasAlive = hasAlive or itertools.include(self.scene.extraHeros, function(exObj)
		if not exObj.extraObjectCsvCfg.forceAllDeadCheck then
			return false
		end

		if exObj.force ~= force then
			return false
		end

		if exObj:isRealDeath() then
			return false
		end

		return true
	end)

	return not hasAlive
end

function Gate:getRoundLeftHerosCount()
	local n = 0

	for _, nextHero in ipairs(self.nextHeros) do
		if nextHero and (self.scene:getObjectExcludeDead(nextHero) or self.scene:getAidObj(nextHero)) then
			n = n + 1
		end
	end

	for _, roundLeftHero in ipairs(self.roundLeftHeros) do
		if roundLeftHero and roundLeftHero.obj and not roundLeftHero.obj:isRealDeath() then
			n = n + 1
		end
	end

	return n
end

function Gate:checkRoundEnd()
	local n = self:getRoundLeftHerosCount()

	if n <= 0 then
		return true
	end

	return false
end

function Gate:checkWaveEnd()
	if self.curWave < self.waveCount and self:checkForceAllRealDead(2) then
		return true
	end

	return false
end

function Gate:isExceedRoundLimit()
	local allDead = self:checkForceAllRealDead(1) or self:checkForceAllRealDead(2)

	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not allDead then
		return true
	end

	return false
end

local SpecEndRuleCheckFunc = {
	[battle.EndSpecialCheck.ForceNum] = function(self)
		if self:isExceedRoundLimit() then
			local forceNum = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanSpecialCheck(obj) then
					forceNum[obj.force] = forceNum[obj.force] + 1
				end
			end

			if battleEasy.numEqual(forceNum[1], forceNum[2]) then
				return false, "fail"
			end

			local res = battleEasy.ifElse(forceNum[1] > forceNum[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.HpRatioCheck] = function(self)
		if self:isExceedRoundLimit() then
			self.scene:overAssignTypeBuffs("markId")

			local hpRatio = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if self:checkObjCanSpecialCheck(obj) then
					hpRatio[obj.force] = hpRatio[obj.force] + obj:hpForSpecialCheck() / obj:hpMax()

					self:addFullRoundInfo(battle.fullRoundInfoType.object, obj)
					log.battle.gate.endSpecialCheck.hpRatioObj({
						obj = obj,
						hpForSpecialCheck = obj:hpForSpecialCheck(),
						hpMax = obj:hpMax(),
						hpRatio = obj:hpForSpecialCheck() / obj:hpMax()
					})
				end
			end

			self:addFullRoundInfo(battle.fullRoundInfoType.hpRatio, hpRatio)
			log.battle.gate.endSpecialCheck.hpRatio({
				hpRatio = hpRatio
			})

			if battleEasy.numEqual(hpRatio[1], hpRatio[2]) then
				return false, "fail"
			end

			local res = battleEasy.ifElse(hpRatio[1] > hpRatio[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.TotalHpCheck] = function(self)
		if self:isExceedRoundLimit() then
			local totalHp = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanSpecialCheck(obj) then
					totalHp[obj.force] = totalHp[obj.force] + obj:hpForSpecialCheck()

					self:addFullRoundInfo(battle.fullRoundInfoType.object, obj)
					log.battle.gate.endSpecialCheck.totalHpObj({
						obj = obj,
						hpForSpecialCheck = obj:hpForSpecialCheck()
					})
				end
			end

			self:addFullRoundInfo(battle.fullRoundInfoType.totalHp, totalHp)
			log.battle.gate.endSpecialCheck.totalHp(totalHp)

			if battleEasy.numEqual(totalHp[1], totalHp[2]) then
				return false, "fail"
			end

			local res = battleEasy.ifElse(totalHp[1] > totalHp[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.AllHpRatioCheck] = function(self)
		if self:isExceedRoundLimit() then
			self.scene:overAssignTypeBuffs("markId")

			self.enemyDeadHpMaxSum = self.enemyDeadHpMaxSum or 0
			self.myDeadHpMaxSum = self.myDeadHpMaxSum or 0

			local hpMax = {
				self.myDeadHpMaxSum,
				self.enemyDeadHpMaxSum
			}
			local hp = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if self:checkObjCanSpecialCheck(obj) then
					hpMax[obj.force] = hpMax[obj.force] + obj:hpMax()
					hp[obj.force] = hp[obj.force] + obj:hpForSpecialCheck()

					self:addFullRoundInfo(battle.fullRoundInfoType.object, obj)
					log.battle.gate.endSpecialCheck.allHpRatioObj({
						obj = obj,
						hpForSpecialCheck = obj:hpForSpecialCheck(),
						hpMax = obj:hpMax()
					})
				end
			end

			self:addFullRoundInfo(battle.fullRoundInfoType.allHpRatio, {
				hp[1] / hpMax[1],
				hp[2] / hpMax[2]
			})
			log.battle.gate.endSpecialCheck.allHpRatio({
				hp = hp,
				hpMax = hpMax
			})

			local res

			if hpMax[1] == 0 or hpMax[2] == 0 then
				res = battleEasy.ifElse(hpMax[2] == 0, "win", "fail")

				return true, res
			end

			if battleEasy.numEqual(hp[1] / hpMax[1], hp[2] / hpMax[2]) then
				return false, "fail"
			end

			res = battleEasy.ifElse(hp[1] / hpMax[1] > hp[2] / hpMax[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.FightPoint] = function(self)
		if self:isExceedRoundLimit() then
			local fightPointSum = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if self:checkObjCanSpecialCheck(obj) then
					fightPointSum[obj.force] = fightPointSum[obj.force] + obj.fightPoint
				end
			end

			if battleEasy.numEqual(fightPointSum[1], fightPointSum[2]) then
				return false, "fail"
			end

			local res = battleEasy.ifElse(fightPointSum[1] > fightPointSum[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.CumulativeSpeedSum] = function(self)
		if self:isExceedRoundLimit() then
			local speedSum = {
				0,
				0
			}

			for _, obj in self.scene:ipairsAllHeros() do
				if self:checkObjCanSpecialCheck(obj) then
					speedSum[obj.force] = speedSum[obj.force] + obj:speed()
				end
			end

			if battleEasy.numEqual(speedSum[1], speedSum[2]) then
				return false, "fail"
			end

			local res = battleEasy.ifElse(speedSum[1] > speedSum[2], "win", "fail")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.SoloSpecialRule] = function(self)
		if not self.forceToObjId then
			return false
		end

		local me = self.scene:getFieldObject(self.forceToObjId[1])
		local enemy = self.scene:getFieldObject(self.forceToObjId[2])

		if not me or not enemy then
			return false
		end

		if me.markID ~= enemy.markID then
			return false
		end

		local csvData = gCraftSpecialRules[me.markID]

		if not csvData then
			return false
		end

		local specBuffType = csvData.buffType
		local meTriggerTime = me:getEventByKey(battle.ExRecordEvent.soloTriggerBuffTime, specBuffType) or 0
		local enemyTriggerTime = enemy:getEventByKey(battle.ExRecordEvent.soloTriggerBuffTime, specBuffType) or 0

		self:addFullRoundInfo(battle.fullRoundInfoType.soloTriggerTime, {
			meTriggerTime,
			enemyTriggerTime
		})

		local function specialBuffOverlayCountCheck()
			local sign = csvData.sign
			local buffCfgId = csvData.buffCfgId

			if not buffCfgId then
				return false
			end

			local meCount = sign * me:getBuffOverlayCount(buffCfgId)
			local enemyCount = sign * enemy:getBuffOverlayCount(buffCfgId)

			if meCount == enemyCount then
				return false
			end

			local res = battleEasy.ifElse(meCount < enemyCount, "win", "fail")

			return true, res
		end

		if meTriggerTime == enemyTriggerTime or meTriggerTime > 1e-06 and enemyTriggerTime > 1e-06 then
			return specialBuffOverlayCountCheck()
		end

		local res = battleEasy.ifElse(meTriggerTime < enemyTriggerTime, "win", "fail")

		return true, res
	end,
	[battle.EndSpecialCheck.LastWaveTotalDamage] = function(self)
		local totalDamage = {
			0,
			0
		}

		local function recordExtraObjDamage(force)
			local damageTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.unitsDamage, force, self.curWave)

			if not damageTb then
				return
			end

			for _, v in pairs(damageTb) do
				if v.isExtraObj then
					totalDamage[force] = totalDamage[force] + v.damageVal
				end
			end
		end

		recordExtraObjDamage(1)
		recordExtraObjDamage(2)

		for _, obj in self.scene:ipairsAllHeros() do
			if self:checkObjCanCalcDamage(obj) then
				local damage = 0

				for k, v in pairs(battle.DamageFrom) do
					local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(battle.ValueType.normal) or 0

					damage = damage + curDamage
				end

				log.battle.gate.endSpecialCheck.totalDamageObj({
					obj = obj,
					damage = damage - (obj.lastWaveTotalDamage or 0)
				})

				totalDamage[obj.force] = totalDamage[obj.force] + damage - (obj.lastWaveTotalDamage or 0)
			end
		end

		self:addFullRoundInfo(battle.fullRoundInfoType.damage, totalDamage)
		log.battle.gate.endSpecialCheck.totalDamage(totalDamage)

		if battleEasy.numEqual(totalDamage[1], totalDamage[2]) then
			return false, "fail"
		end

		local res = battleEasy.ifElse(totalDamage[1] > totalDamage[2], "win", "fail")

		return true, res
	end,
	[battle.EndSpecialCheck.DirectWin] = function(self)
		local forceNums = {
			{
				0,
				0
			},
			{
				0,
				0
			}
		}

		for _, obj in self.scene:ipairsAllHeros() do
			for _, data in obj:ipairsOverlaySpecBuff("directWin") do
				forceNums[obj.force][data.mode] = forceNums[obj.force][data.mode] + 1
			end
		end

		local res

		if forceNums[1][1] ~= forceNums[2][1] then
			res = battleEasy.ifElse(forceNums[1][1] > forceNums[2][1], "win", "fail")

			return true, res
		end

		if forceNums[1][2] ~= forceNums[2][2] then
			res = battleEasy.ifElse(forceNums[1][2] > forceNums[2][2], "fail", "win")

			return true, res
		end

		return false
	end,
	[battle.EndSpecialCheck.EnemyOnlySummonOrAllDead] = function(self)
		local function isOnlySummonOrAllDead()
			local enemies = self.scene:getHerosMap(2)

			for _, obj in enemies:order_pairs() do
				if obj and not obj:isAlreadyDead() and self:checkObjCanSpecialCheck(obj) then
					return false
				end
			end

			return true
		end

		if (self.curRound >= self.roundLimit and self:checkRoundEnd() or self:checkForceAllRealDead(1)) and isOnlySummonOrAllDead() then
			return true, "win"
		end

		return false
	end,
	[battle.EndSpecialCheck.BothDead] = function(self, result)
		local isLastWave = self.curWave == self.waveCount

		if self:checkBothAllRealDead() then
			result = isLastWave and "win" or "fail"

			return true, result
		end

		return false
	end
}

function Gate:specialEndCheck()
	local func, argsFunc

	for k, typ in ipairs(self:onSpecEndRuleCheckSupply() or self.SpecEndRuleCheck) do
		func = SpecEndRuleCheckFunc[typ]

		if func then
			argsFunc = self.SpecEndRuleCheckArgs[typ] or function()
				return
			end

			local isEnd, result = func(self, argsFunc())

			if isEnd or k == table.length(self.SpecEndRuleCheck) and result then
				return true, result
			end
		end
	end
end

function Gate:bothRealDeadSpecCheck()
	local maxOrderInfo

	for k, v in ipairs(self.scene.realDeathRecordTb) do
		if not maxOrderInfo or maxOrderInfo and maxOrderInfo.order < v.order then
			maxOrderInfo = {
				order = v.order,
				force = v.force,
				id = v.id
			}
		end
	end

	return true, maxOrderInfo.force ~= 1 and "fail" or "win"
end

function Gate:checkBattleEnd()
	local isEnd, result = self:specialEndCheck()

	if isEnd then
		return isEnd, result
	end

	local allDead = self:checkForceAllRealDead(1)
	local enemyAllDead = self:checkForceAllRealDead(2)

	if allDead and enemyAllDead and table.length(self.scene.realDeathRecordTb) > 0 then
		isEnd, result = self:bothRealDeadSpecCheck()

		return isEnd, result
	end

	if allDead then
		return true, "fail"
	end

	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not enemyAllDead then
		return true, "fail"
	end

	if self.curWave > self.waveCount then
		return true, "fail"
	end

	local enemyAllDeadInEnd = self.curWave == self.waveCount and enemyAllDead
	local hasEx, exDone = self:checkExEndConditions()
	local isEnd = not hasEx and enemyAllDeadInEnd or hasEx and exDone
	local allWin = isEnd and (not hasEx or exDone)

	if isEnd then
		return true, allWin and "win" or "fail"
	end

	return false
end

function Gate:checkBattleEndAndRun()
	local isGameOver
	local isEnd, result = self:checkBattleEnd()

	if isEnd then
		isGameOver, result = self:checkGroupRoundEnd(result)

		if isGameOver then
			self:runGameEnd(result)
		else
			self:endGroupRound(result)
		end

		return true
	end

	return isEnd
end

function Gate:objRoundEnd()
	for _, obj in self.scene:ipairsHeros() do
		if not obj:isAlreadyDead() then
			obj:onEndRound()
		end
	end

	local deletedCount = 0

	for _, obj in pairs(self.scene.deadObjsToBeDeleted) do
		self.scene:onObjDel(obj, true)

		deletedCount = deletedCount + 1
	end

	if deletedCount > 0 then
		self.scene.deadObjsToBeDeleted = {}
	end
end

function Gate:checkBattleState()
	local specialRound = self.scene:getSpecialSceneInfo()

	if specialRound then
		specialRound:onBattleTurnEnd()
		self.scene:newBattleTurn()

		return
	end

	if self:checkBattleEndAndRun() then
		gRootViewProxy:notify("updateExtraRoundState")

		return
	elseif self:checkWaveEnd() then
		gRootViewProxy:notify("updateExtraRoundState")
		self:objRoundEnd()

		if not self:checkBattleEndAndRun() then
			battleEasy.queueEffect(function()
				battleEasy.queueNotify("lockLifeBar", {
					isLock = true
				})
			end)

			self.waveResult = self:onWaveResultCheckSupply()

			table.insert(self.waveResultHistory, self.waveResult)

			if self.waveInit.endType then
				local forceTeamInfo = self.groupRoundInit.forceTeams[self.groupRound]

				if self.waveInit.endType == Gate.AfteWaveEndType.WinNext then
					if self.waveResult == battle.Const.Win then
						forceTeamInfo[2].waveIndex = forceTeamInfo[2].waveIndex + 1
					else
						forceTeamInfo[1].waveIndex = forceTeamInfo[1].waveIndex + 1
					end
				elseif self.waveInit.endType == Gate.AfteWaveEndType.AllClear then
					forceTeamInfo[1].waveIndex = forceTeamInfo[1].waveIndex + 1
					forceTeamInfo[2].waveIndex = forceTeamInfo[2].waveIndex + 1
				end
			end

			self:onWaveEndSupply()
			self.scene:newWave()
		end
	elseif self:checkRoundEnd() then
		self:objRoundEnd()

		if not self:checkBattleEndAndRun() then
			self:onRoundEndSupply()
			self.scene:newRound()
		end
	else
		self.scene:newBattleTurn()
	end
end

function Gate:runGameEnd(result)
	self.scene:buffRoundInherit("gameEnd")
	self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRunGameEnd)
	self.scene:checkBackStageObjs()
	self:recordDamageStats()
	self:recordCampDamageStats()
	self:onGroupRoundEnd(result, true)

	self.result = result

	self:onBattleEndSupply()
	self.scene:overAssignTypeBuffs("markId")
	self:checkGuide(function()
		gRootViewProxy:notify("sceneOver", self.result)
		self.scene:over()
	end, {
		round = self.result == "win" and battle.GuideTriggerPoint.Win or battle.GuideTriggerPoint.Fail
	})
end

function Gate:onOver()
	self:onOverSupply()
	self:makeEndViewInfos()
	gRootViewProxy:proxy():runDeferListWithEffect("battleTurn")
	battleEasy.queueEffect(function()
		display.director:getScheduler():setTimeScale(1)
		battleEasy.queueEffect(function()
			self.scene:setAutoFight(false)
			gRootViewProxy:notify("sceneEndPlayAni", self.result)

			if self.endAnimation then
				local args = {
					delay = 0,
					addTolayer = 1,
					screenPos = 0,
					aniloop = false,
					scale = 0.5,
					zorder = 0,
					offsetY = 0,
					offsetX = 0,
					aniName = self.endAnimation.aniName
				}

				battleEasy.queueEffect("effect", {
					effectType = 1,
					faceTo = 1,
					effectRes = self.endAnimation.res,
					effectArgs = args
				})
			end

			battleEasy.queueEffect("delay", {
				lifetime = 1500
			})
		end)
	end)
	self.scene:playEnd()
end

function Gate:onOverSupply()
	return
end

function Gate:addFullRoundInfo(type, data)
	return
end

function Gate:getFullRoundInfo()
	return self.fullRoundInfo
end

local starConditionCheckTb = {
	function(gate, params)
		local c = gate.result == "win"

		return c, c and 1 or 0
	end,
	function(gate, params)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount
		local count = 0

		for _, obj in gate.scene.heros:order_pairs() do
			if obj and not obj:isRealDeath() then
				count = count + 1
			end
		end

		return params >= startCount - count, startCount - count
	end,
	function(gate, params)
		return not gate.isBossBattle or params >= gate.curRound, gate.isBossBattle and gate.curRound or 0
	end,
	function(gate, params)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount

		return startCount <= params, startCount
	end,
	function(gate, params)
		local startCount = gate.scene.forceRecordTb[1].herosStartCount

		return params <= startCount, startCount
	end
}

function Gate:initStarConditions()
	if not self.starConditionTb then
		local starsCfg = self.scene.sceneConf.stars or {}
		local conditionTb = {}

		for _, cfg in csvPairs(starsCfg) do
			table.insert(conditionTb, {
				cfg.key,
				cfg.value
			})

			if table.length(conditionTb) >= 3 then
				self.starConditionTb = conditionTb

				break
			end
		end
	end
end

function Gate:getStarConditions()
	if self.moduleProcess:proxy().StarModule then
		local _, starConditionTb = self.moduleProcess:proxy().StarModule:getGateStar()

		return starConditionTb
	else
		return self.starConditionTb
	end
end

function Gate:getStarConditionsInfo()
	local starsCfg = self.scene.sceneConf.stars or {}
	local conditionTb = {}

	for _, cfg in csvPairs(starsCfg) do
		table.insert(conditionTb, {
			cfg.key,
			cfg.value
		})

		if table.length(conditionTb) >= 3 then
			return conditionTb
		end
	end
end

function Gate:compareRecrodResult(result)
	local ret = self:makeEndViewInfos()

	return ret.result == result
end

function Gate:getGateStar()
	local conditionTb = self.starConditionTb

	if self.moduleProcess:proxy().StarModule then
		local _, starConditionTb = self.moduleProcess:proxy().StarModule:getGateStar()

		conditionTb = starConditionTb
	end

	if not conditionTb then
		return
	end

	local totalCount = 0
	local tb = {
		{
			false,
			0
		},
		{
			false,
			0
		},
		{
			false,
			0
		}
	}

	for i = 1, 3 do
		local infos = conditionTb[i]
		local func = starConditionCheckTb[infos[1]]

		if func then
			tb[i][1], tb[i][2] = func(self, infos[2])
		end

		if tb[i][1] then
			totalCount = totalCount + 1
		end
	end

	return totalCount, tb
end

function Gate:postEndResultToServer(cb)
	cb(self:makeEndViewInfos(), nil)
end

function Gate:checkBulletTimeShow()
	local round = self.totalRoundBattleTurn

	if not self.showedBulletTime then
		battleEasy.deferCallback(function()
			if self.result and round == self.totalRoundBattleTurn then
				gRootViewProxy:proxy():bulletTimeShow()
			end
		end)
		battleEasy.queueEffect(function()
			if self.result and round == self.totalRoundBattleTurn then
				self.showedBulletTime = true

				gRootViewProxy:proxy():onEventEffectQueueFront("delay", {
					lifetime = 900
				})
			end
		end)
	end
end

function Gate:whoHighestDamageFromStats(force, group)
	local maxDmg, maxFightPoint = 0, 0
	local dbID, unitID
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.unitsDamage)

	for k = 1, group or 1 do
		local ret = tb[force][k]

		if ret then
			itertools.each(ret, function(id, t)
				if t.damageVal > maxDmg then
					maxDmg = t.damageVal
					dbID = t.dbID
					unitID = t.originUnitID

					if t.summonerId and ret[t.summonerId] then
						dbID = ret[t.summonerId].dbID
						unitID = ret[t.summonerId].originUnitID
					end
				elseif maxDmg == 0 and t.damageVal == 0 and t.fightPoint > maxFightPoint then
					maxFightPoint = t.fightPoint
					dbID = t.dbID
					unitID = t.originUnitID

					if t.summonerId and ret[t.summonerId] then
						dbID = ret[t.summonerId].dbID
						unitID = ret[t.summonerId].originUnitID
					end
				end
			end)
		end
	end

	return dbID, unitID
end

function Gate:checkExEndConditions()
	local exConditions = self.scene.sceneConf.finishPoint

	if exConditions then
		for key, val in pairs(exConditions) do
			if key == "killNumber" then
				local killNumber = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.killNumber, "Val") or 0

				if val <= killNumber then
					return true, true
				end
			end
		end

		return true, false
	end

	return false, false
end

function Gate:checkObjCanToServer(obj)
	return not obj:isSummonType()
end

function Gate:checkObjCanSpecialCheck(obj)
	local result
	local inField = self.scene:getFieldObject(obj.id)

	if obj:isSummonType() then
		if not inField then
			return false
		end

		result = not obj:effectPowerControl(battle.EffectPowerType.summonSpecialCheck)
	else
		if inField then
			return true
		end

		result = obj:effectPowerControl(battle.EffectPowerType.normalSpecialCheck)
	end

	return result
end

function Gate:checkObjCanCalcDamage(obj)
	if obj:isSummonType() and not obj.summonCalDamage then
		return false
	end

	return true
end

local function getSummonerId(obj)
	if obj:isSummonType() then
		local summoner = obj:getEventByKey(battle.ExRecordEvent.summoner)

		if summoner then
			return summoner.id
		end
	end
end

function Gate:recordDamageStats()
	for _, obj in self.scene:ipairsAllHeros() do
		if self:checkObjCanCalcDamage(obj) then
			local totalDamage = 0

			for k, v in pairs(obj.totalDamage) do
				totalDamage = totalDamage + v:get(battle.ValueType.normal)
			end

			if obj:isDeath() then
				local data2 = {
					dbID = obj.dbID,
					unitID = obj.unitID,
					totalTakeDamage = obj.totalTakeDamage,
					isExtraObj = obj:isExtraObj()
				}

				self.scene.extraRecord:addExRecord(battle.ExRecordEvent.deadTakeDamage, data2, obj.force, self.curWave, obj.id)
			end

			self:recordUnitsDamage(obj, totalDamage, self.curWave)
		end
	end
end

function Gate:recordUnitsDamage(obj, totalDamage, wave)
	self.scene.extraRecord:addExRecord(battle.ExRecordEvent.unitsDamage, {
		dbID = obj.dbID,
		unitID = obj.unitID,
		originUnitID = obj.originUnitID,
		damageVal = totalDamage,
		isExtraObj = obj:isExtraObj(),
		summonerId = getSummonerId(obj),
		fightPoint = obj.fightPoint
	}, obj.force, wave, obj.id)
end

function Gate:recordCampDamageStats()
	local myDamage = 0
	local enemyDamage = 0
	local myDamageTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.unitsDamage, 1)
	local enemyDamageTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.unitsDamage, 2)

	if myDamageTb and enemyDamageTb then
		for _, waveTb in pairs(myDamageTb) do
			for _, v in pairs(waveTb) do
				myDamage = v.damageVal + myDamage
			end
		end

		for _, waveTb in pairs(enemyDamageTb) do
			for _, v in pairs(waveTb) do
				enemyDamage = v.damageVal + enemyDamage
			end
		end
	end

	self.scene.extraRecord:addExRecord(battle.ExRecordEvent.campDamage, myDamage, 1)
	self.scene.extraRecord:addExRecord(battle.ExRecordEvent.campDamage, enemyDamage, 2)
end

function Gate:recordScoreStats(attacker, score)
	return
end

function Gate:onTurnStartSupply()
	return
end

function Gate:onTurnEndSupply()
	return
end

function Gate:onRoundEndSupply()
	return
end

function Gate:onWaveEndSupply()
	return
end

function Gate:onTeamEndSupply(result)
	return
end

function Gate:onBattleEndSupply()
	return
end

function Gate:refreshUIHp()
	self.moduleProcess:notifyAndRun("refreshUIHp", {
		gate = self
	})
end

function Gate:refreshUIMp()
	self.moduleProcess:notifyAndRun("refreshUIMp", {
		gate = self
	})
end

function Gate:getMonsterCsv(sceneId, waveId)
	sceneId = sceneId or self.scene.sceneID

	return battleEasy.getMonsterCsv(sceneId, waveId, self.groupRound)
end

function Gate:getMonsterGuideCsv(sceneId, waveId)
	return gMonsterCsv[sceneId] and self:getMonsterCsv(sceneId, waveId)
end

function Gate:getTotalBattleTurnCurWave()
	return self.totalRoundBattleTurn
end

function Gate:getTotalRounds()
	return self.totalRound
end

function Gate:excutePlayCsv(func_name)
	if self.PlayCsvFunc[func_name] then
		return functools.partial(self.PlayCsvFunc[func_name], self)
	end
end

function Gate:runOneFrame()
	return
end

function Gate:setAttack(seat, skillId)
	self.handleInput = {
		seat,
		skillId
	}

	if seat ~= 0 then
		self.nowChooseID = seat
	end

	log.battle.scene.setAttack({
		seat = seat,
		skillId = skillId
	})
end

function Gate:sendActionParams(isMult)
	local actionSend = self.actionSend
	local groupRoundMax = table.maxn(actionSend)

	if groupRoundMax == 0 then
		groupRoundMax = 1
	end

	for i = 1, groupRoundMax do
		local arr1 = actionSend[i]

		if arr1 == nil then
			actionSend[i] = {}
			arr1 = actionSend[i]
		end

		local roundMax = table.maxn(arr1)

		for j = 1, roundMax do
			local arr2 = arr1[j]

			if arr2 == nil then
				arr1[j] = {}
			else
				local yMax = table.maxn(arr2)

				for z = 1, yMax do
					if arr2[z] == nil then
						arr2[z] = EmptyAction
					end
				end
			end
		end
	end

	if isMult then
		return actionSend
	else
		return actionSend[1]
	end
end

function Gate:checkGuide(func, data)
	self.scene.guide:checkGuide(func, data)
end

function Gate:makeEndViewInfos(data)
	local info = {
		result = self.result
	}

	if data and data.gateStar then
		info.gateStar = 0
		info.conditionTb = self.starConditionTb

		if self.result == "win" then
			if self.moduleProcess:proxy().StarModule then
				local starData, starConditionTb = self.moduleProcess:proxy().StarModule:getGateStar()

				info.gateStar = starData.totalCount
				info.gateStarTb = starData.tb
				info.conditionTb = starConditionTb
			else
				info.gateStar, info.gateStarTb = self:getGateStar()
			end
		end
	end

	return info
end

function Gate:setHeroIsAttacked(hero, attackedSign, isBack)
	if hero then
		for k, v in ipairs(self.roundHasAttackedHeros) do
			if v.addRoundRef and v.object.id == hero.id then
				if not isBack then
					table.remove(self.roundHasAttackedHeros, k)
					table.remove(self.hasAttackedSign, k)

					break
				else
					v.addRoundRef = v.addRoundRef - 1

					if v.addRoundRef == 0 then
						self.roundHasAttackedHeros[k] = hero
						self.hasAttackedSign[k] = v.attackSign

						return
					end
				end
			end
		end
	end

	table.insert(self.roundHasAttackedHeros, hero)

	if attackedSign then
		table.insert(self.hasAttackedSign, attackedSign)
	else
		table.insert(self.hasAttackedSign, hero and 0)
	end
end

function Gate:resetGateAttackRecord(holder, data, isRecord)
	self:addRoundLeftHero(data)

	for k, v in ipairs(self.roundHasAttackedHeros) do
		if v.id == holder.id then
			local obj = v

			if isRecord then
				if not obj.addRoundRef then
					obj = {
						seat = 9998,
						addRoundRef = 0,
						object = v,
						attackSign = self.hasAttackedSign[k]
					}
					self.roundHasAttackedHeros[k] = obj
					self.hasAttackedSign[k] = 0
				end

				obj.addRoundRef = obj.addRoundRef + 1

				break
			end

			table.remove(self.roundHasAttackedHeros, k)
			table.remove(self.hasAttackedSign, k)

			break
		end
	end
end

function Gate:cleanSpecRoundExRoundData(obj, buffID)
	local count = 0

	for idx, data in obj.extraRoundData:pairs() do
		if data.buffID == buffID then
			obj.extraRoundData:erase(idx)

			count = count + 1
		end
	end

	local delT = {}

	for i = 1, table.length(self.nextHeros) do
		if self.nextHeros[i] == obj.id and count > 0 then
			table.insert(delT, i)

			count = count - 1
		end
	end

	for i = table.length(delT), 1, -1 do
		table.remove(self.nextHeros, delT[i])
	end
end

function Gate:cleanExRoundFromAttackList(obj)
	obj.extraRoundData:clear()
	self.scene:cleanObjInExtraRound(obj)
end

function Gate:delFromRoundLeftHeros(objId, isStore)
	local toDelTb = {}

	for id, data in ipairs(self.roundLeftHeros) do
		local obj = data.obj or data

		if obj.id == objId then
			table.insert(toDelTb, id)

			if isStore then
				obj:addExRecord(battle.ExRecordEvent.backStageRoundInfo, data)
			end
		end
	end

	for i = #toDelTb, 1, -1 do
		table.remove(self.roundLeftHeros, toDelTb[i])

		if self.leftHerosFirstIndex and toDelTb[i] < self.leftHerosFirstIndex then
			self.leftHerosFirstIndex = self.leftHerosFirstIndex - 1
		end
	end

	battleEasy.queueEffect(function()
		gRootViewProxy:proxy():onBrawlSpeedChange()
	end, {
		zOrder = battle.EffectZOrder.dead
	})
end

function Gate:checkBrawlEnd()
	local lastInfo = self.scene:getExtraRoundLastInfo(battle.ExtraAttackMode.brawl)

	if not lastInfo then
		return
	end

	local aliveCount = 0
	local leftBrawlCount = 0

	for _, obj in ipairs(lastInfo.targets) do
		if not obj:isRealDeath() then
			aliveCount = aliveCount + 1

			for __, data in obj.extraRoundData:pairs() do
				if data.mode == battle.ExtraAttackMode.brawl then
					leftBrawlCount = leftBrawlCount + 1
				end
			end
		end
	end

	if aliveCount < 2 or leftBrawlCount == 0 then
		self:onBrawlEnd()
	elseif lastInfo.brawlType == battle.BrawlType.Duel then
		if self.curHero then
			lastInfo.roundLeftHeros[self.curHero.id] = true
		end

		local isAllAttacked = true

		for _, obj in self.scene:ipairsHeros() do
			if lastInfo.roundLeftHeros[obj.id] == nil then
				isAllAttacked = false

				return
			end
		end

		if isAllAttacked then
			lastInfo.roundLeftHeros = {}

			self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundStart)
			self.scene:updateBuffEveryTurn(battle.BuffTriggerPoint.onRoundEnd)

			lastInfo.totalRound = lastInfo.totalRound + 1
		end
	end
end

local function popOneRandomFromTable(ret)
	local len = table.length(ret)

	if len > 0 then
		local randIdx = ymrand.random(1, len)

		return table.remove(ret, randIdx)
	end
end

function Gate:onBrawlEnd()
	local lastInfo = self.scene:getExtraRoundLastInfo(battle.ExtraAttackMode.brawl)

	if not lastInfo then
		return
	end

	gRootViewProxy:proxy():pushDeferList("playInEndBrawl")

	local minnVal = -1
	local maxxVal = -1
	local minnObjs = {}
	local maxxObjs = {}

	for _, obj in ipairs(lastInfo.targets) do
		if not obj:isAlreadyDead() then
			local oldDamage = lastInfo.beginTakeDamageTb[obj.id]
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

	local buff = lastInfo.buff

	buff.holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
		cfgId = buff.cfgId,
		buffId = buff.id,
		winnerSeat = minObj and minObj.seat or 0,
		loserSeat = maxObj and maxObj.seat or 0
	})
	self:resetBrawlState()
	buff:over()

	local playInEndBrawl = gRootViewProxy:proxy():popDeferList("playInEndBrawl")

	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndBrawl)
		end)
	end)
end

function Gate:addRoundLeftHero(data)
	if data.obj and data.obj:isExtraObj() then
		errorInWindows("addRoundLeftHero obj: %d is followObject", data.obj.unitID)

		return
	end

	table.insert(self.roundLeftHeros, data)
end

require("battle.models.play.gate_interface")
