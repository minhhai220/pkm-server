-- chunkname: @src.battle.models.play.craft_gate

local CraftGateRecord = class("CraftGateRecord", battlePlay.Gate)

battlePlay.CraftGateRecord = CraftGateRecord
CraftGateRecord.OperatorArgs = {
	canSkip = true,
	canSpeedAni = true,
	canPause = false,
	canHandle = false,
	isFullManual = false,
	isAuto = true
}
CraftGateRecord.SpecEndRuleCheck1 = {
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.LastWaveTotalDamage
}
CraftGateRecord.SpecEndRuleCheck2 = {
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.HpRatioCheck,
	battle.EndSpecialCheck.FightPoint,
	battle.EndSpecialCheck.CumulativeSpeedSum
}

local function getObjTotalDamage(obj)
	local totalDamage = 0

	for k, v in pairs(battle.DamageFrom) do
		local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(1) or 0

		totalDamage = totalDamage + curDamage
	end

	return totalDamage
end

function CraftGateRecord:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	self.posByForce = {
		2,
		8
	}
	self.score = 0
	self.enemyScore = 0
	self.firstRoleout = {
		{},
		{}
	}
	self.endAnimation = {
		res = "xianshipvp/jinjichang.skel",
		aniName = ""
	}
	self.craftBuffAddTimes = {}
	self.forceToObjId = {
		-1,
		-1
	}
end

function CraftGateRecord:init(data)
	self.isFinal = data.isFinal

	battlePlay.Gate.init(self, data)

	self.backUp = {
		{},
		{}
	}
	self.waveResultList = {}
	self.loserRoleOut = {
		{},
		{}
	}

	if not self.isFinal then
		self.waveCount = 1
	end

	self:playStartAni()
	self:syncBackup()
end

function CraftGateRecord:onProcessSupply()
	self.moduleProcess:initModule("UIModule"):initCarft()
end

function CraftGateRecord:playStartAni()
	if self.isFinal then
		gRootViewProxy:notify("showVsPvpView", 3)
	else
		gRootViewProxy:notify("showVsPvpView", 2)
	end
end

function CraftGateRecord:initWeatherDatas()
	local extra = self.data.extraOut or {
		{},
		{}
	}
	local extraOut

	for force = 1, 2 do
		extraOut = extra[force]

		if extraOut and extraOut.weathers then
			for i, id in ipairs(extraOut.weathers) do
				table.insert(self.weathers[force], id)
			end
		end
	end
end

function CraftGateRecord:waveAddWeathers(force)
	local realForce = force == self.operateForce and 1 or 2

	if next(self.weathers[force]) then
		self.scene.buffGlobalManager:setWeatherData(realForce, self.weathers[force][1])
		table.remove(self.weathers[force], 1)
	end
end

function CraftGateRecord:syncBackup()
	for force = 1, 2 do
		local wavesData = self.data.roleOut
		local wavesData2 = self.data.roleOut2
		local stepNum = force == 1 and 0 or self.ForceNumber
		local count = 0

		for seat = 1 + stepNum, self.ForceNumber + stepNum do
			local roleData = wavesData[seat]

			if roleData then
				if wavesData2 and next(wavesData2) then
					roleData.role2Data = wavesData2[seat]
				end

				table.insert(self.backUp[force], roleData)
			end
		end
	end
end

function CraftGateRecord:getWaveDataFromRoleData(force, roleData)
	local data1, data2

	data1 = {
		[self.posByForce[force]] = roleData
	}
	data2 = {
		[self.posByForce[force]] = roleData.role2Data
	}

	return data1, data2
end

function CraftGateRecord:newWaveAddByBackUp(force)
	if not next(self.backUp[force][1]) then
		return
	end

	local data1, data2 = self:getWaveDataFromRoleData(force, self.backUp[force][1])

	self:waveAddCardRoles(force, nil, data1, data2, true)

	local pre = table.remove(self.backUp[force], 1)

	if table.length(self.backUp[force]) == 0 then
		self.backUp[force][1] = {}
	end

	if self.curWave ~= 1 then
		table.insert(self.loserRoleOut[force], self.firstRoleout[force])
		battleEasy.deferNotify(nil, "changeWave", self.waveResultList[self.curWave - 1])
	end

	self.firstRoleout[force] = pre
end

function CraftGateRecord:newWaveAddObjsStrategy()
	if self.curWave == 1 then
		self:newWaveAddByBackUp(1)
		self:newWaveAddByBackUp(2)
	else
		local whoWin = self.waveResultList[self.curWave - 1]

		if whoWin == 1 then
			self:newWaveAddByBackUp(2)
		elseif whoWin == 2 then
			self:newWaveAddByBackUp(1)
		else
			self:newWaveAddByBackUp(1)
			self:newWaveAddByBackUp(2)
		end
	end

	self:doObjsAttrsCorrect(true, true)
	battlePlay.Gate.newWaveAddObjsStrategy(self)
end

function CraftGateRecord:addCardRoles(force, waveId, roleOutT, roleOutT2, onlyDelDead)
	battlePlay.Gate.addCardRoles(self, force, waveId, roleOutT, roleOutT2, onlyDelDead)

	for _, obj in self.scene:getHerosMap(force):order_pairs() do
		self.forceToObjId[force] = obj.id

		break
	end
end

function CraftGateRecord:checkBattleEnd()
	local isOnlyOneSelf = not self.isFinal or not next(self.backUp[1][1])
	local isOnlyOneEnemy = not self.isFinal or not next(self.backUp[2][1])
	local allDead = self:checkBothAllRealDead()

	if allDead then
		if isOnlyOneSelf and isOnlyOneEnemy and table.length(self.scene.realDeathRecordTb) > 0 then
			return self:bothRealDeadSpecCheck()
		elseif isOnlyOneSelf then
			return true, "fail"
		elseif isOnlyOneEnemy then
			return true, "win"
		end
	end

	if self:checkForceAllRealDead(1) and isOnlyOneSelf then
		return true, "fail"
	end

	if self:checkForceAllRealDead(2) and isOnlyOneEnemy then
		return true, "win"
	end

	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		self:hpChecker()

		local isEnd, result = battlePlay.Gate.checkBattleEnd(self)

		if result == "win" and isOnlyOneEnemy or result == "fail" and isOnlyOneSelf then
			return isEnd, result
		end
	end

	return false
end

function CraftGateRecord:hpChecker()
	local me = self.scene:getFieldObject(self.forceToObjId[1])
	local myHpRatio = 0

	if me then
		myHpRatio = me:hp() / me:hpMax()
	end

	local enemy = self.scene:getFieldObject(self.forceToObjId[2])
	local enemyHpRatio = 0

	if enemy then
		enemyHpRatio = enemy:hp() / enemy:hpMax()
	end

	local ratioBorder = gCommonConfigCsv.craftHpRatioBorder or 1

	if myHpRatio - ratioBorder > 1e-06 and enemyHpRatio - ratioBorder > 1e-06 then
		self.SpecEndRuleCheck = self.SpecEndRuleCheck1

		return
	end

	self.SpecEndRuleCheck = self.SpecEndRuleCheck2
end

function CraftGateRecord:onBattleEndSupply()
	if self.result == "win" then
		self.endAnimation.aniName = "effect_l"
	elseif self.result == "fail" then
		self.endAnimation.aniName = "effect_r"
	end
end

function CraftGateRecord:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)

	if me and enemy then
		return true, 3
	elseif me then
		return true, 2
	elseif enemy then
		return true, 1
	end

	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		self:hpChecker()

		local _, result = self:specialEndCheck()

		return true, result
	end

	return false
end

function CraftGateRecord:onWaveEndSupply()
	local _, meWin = self:checkWaveEnd()

	if meWin == "win" then
		meWin = 1
	elseif meWin == "fail" then
		meWin = 2
	end

	local me = self.scene:getFieldObject(self.forceToObjId[1])
	local enemy = self.scene:getFieldObject(self.forceToObjId[2])
	local whoToDead

	if meWin == 1 then
		whoToDead = self.scene:getHerosMap(2)
	elseif meWin == 2 then
		whoToDead = self.scene:getHerosMap(1)
	end

	if whoToDead then
		for _, obj in whoToDead:order_pairs() do
			obj:setDead(nil, nil, {
				noTrigger = true,
				force = true
			})
		end
	end

	if self.isFinal then
		table.insert(self.waveResultList, meWin)

		if me then
			me.lastWaveTotalDamage = getObjTotalDamage(me)
		end

		if enemy then
			enemy.lastWaveTotalDamage = getObjTotalDamage(enemy)
		end
	end
end

function CraftGateRecord:needExtraRound()
	local me = self.scene:getFieldObject(self.forceToObjId[1])
	local enemy = self.scene:getFieldObject(self.forceToObjId[2])

	if me and me:isFakeDeath() or enemy and enemy:isFakeDeath() then
		return true
	end

	return false
end

function CraftGateRecord:recordScoreStats(attacker, score)
	if attacker and self:checkObjCanCalcDamage(attacker) then
		local key = attacker.force

		self.scene.extraRecord:addExRecord(battle.ExRecordEvent.score, score, key)
	end
end

function CraftGateRecord:makeEndViewInfos()
	local ratio = csv.craft.base[1].damageScoreRatio
	local score, enemyScore = 0, 0
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.score)

	if tb then
		tb[1] = tb[1] or 0
		tb[2] = tb[2] or 0
		score = math.floor(tb[1] / ratio)
		enemyScore = math.floor(tb[2] / ratio)
	end

	self.score = score
	self.enemyScore = enemyScore

	return {
		result = self.result,
		score = self.score
	}
end
