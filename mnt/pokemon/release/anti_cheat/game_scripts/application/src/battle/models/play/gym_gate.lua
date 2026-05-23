-- chunkname: @src.battle.models.play.gym_gate

local GymGate = class("GymGate", battlePlay.Gate)

battlePlay.GymGate = GymGate
GymGate.CommonArgs = {
	AntiMode = battle.GateAntiMode.Operate
}

local function checkBattleEnd1(self)
	local isOnlyOneSelf = not self:hasNextRoleOut(1)
	local isOnlyOneEnemy = not self:hasNextRoleOut(2)
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
		local isEnd, result = battlePlay.Gate.checkBattleEnd(self)

		if result == "win" and isOnlyOneEnemy or result == "fail" and isOnlyOneSelf then
			return isEnd, result
		end
	end

	return false
end

local function onBattleEndSupply1(self)
	local result = self.result

	if result == "win" then
		self.endAnimation.aniName = "effect_l"
	elseif result == "fail" then
		self.endAnimation.aniName = "effect_r"
	end
end

local function getObjTotalDamage(obj)
	local totalDamage = 0

	for k, v in pairs(battle.DamageFrom) do
		local curDamage = obj.totalDamage[v] and obj.totalDamage[v]:get(1) or 0

		totalDamage = totalDamage + curDamage
	end

	return totalDamage
end

local PosByForce = {
	2,
	8
}
local SpecEndRuleCheck1 = {
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.LastWaveTotalDamage
}
local SpecEndRuleCheck2 = {
	battle.EndSpecialCheck.SoloSpecialRule,
	battle.EndSpecialCheck.HpRatioCheck,
	battle.EndSpecialCheck.FightPoint,
	battle.EndSpecialCheck.CumulativeSpeedSum
}

GymGate.OperatorArgs = {
	isAuto = false,
	canSkip = true,
	canSpeedAni = true,
	canPause = true,
	canHandle = true,
	isFullManual = false
}

function GymGate:init(data)
	local sceneID = data.sceneID
	local cfg = csv.gym.gate[sceneID]

	self.deployType = cfg.deployType
	self.historyCard = {
		{},
		{}
	}

	battlePlay.Gate.init(self, data)

	self.forceWaveNum = {
		1,
		1
	}
	self.forceWaveCount = {
		0,
		0
	}
	self.forceToObjId = {
		-1,
		-1
	}
	self.mayBeMeWin = false

	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		self.endAnimation = {
			res = "xianshipvp/jinjichang.skel",
			aniName = ""
		}
	end
end

function GymGate:initWeatherDatas()
	local extra = self.data.extraOut or {
		{},
		{}
	}
	local sceneID = self.data.sceneID
	local cfg = csv.gym.gate[sceneID]

	if cfg.deployType == game.DEPLOY_TYPE.OneByOneType then
		local extraOut

		for force = 1, 2 do
			extraOut = extra[force]

			if extraOut and extraOut.weathers then
				for i, id in ipairs(extraOut.weathers) do
					table.insert(self.weathers[force], id)
				end
			end
		end
	else
		battlePlay.Gate.initWeatherDatas(self)
	end
end

function GymGate:waveAddWeathers(force)
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		local realForce = force == self.operateForce and 1 or 2

		if next(self.weathers[force]) then
			self.scene.buffGlobalManager:setWeatherData(realForce, self.weathers[force][1])
			table.remove(self.weathers[force], 1)
		end
	else
		battlePlay.Gate.waveAddWeathers(self, force)
	end
end

function GymGate:onProcessSupply()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		self.moduleProcess:initModule("UIModule"):initGymOneByOne()
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		self.moduleProcess:initModule("UIModule"):initGymWheel()
	elseif self.deployType == game.DEPLOY_TYPE.MultTwo or self.deployType == game.DEPLOY_TYPE.MultThree then
		self.moduleProcess:initModule("UIModule"):initMultipGroupPVE(self.deployType)
	end
end

function GymGate:onInitGroupRoundSupply()
	if self.deployType == game.DEPLOY_TYPE.GeneralType then
		self:initGroupRound(1, 1, self.waveCount)
	elseif self.deployType == game.DEPLOY_TYPE.OneByOneType then
		local roundLimit = csv.gym.gate[self.data.sceneID].deployCardNumLimit
		local meDatas = self.data.roleOut
		local forceCount = 0

		for i = 1, roundLimit do
			if meDatas[i] then
				forceCount = forceCount + 1
			end
		end

		self:initGroupRound(1, forceCount, math.max(0, self.waveCount + 1 - roundLimit))
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		local leftCount = self.data.roleOut[1] and table.length(self.data.roleOut[1]) or 0
		local rightCount = math.max(0, self.waveCount + 1 - leftCount)

		self:initGroupRound(1, leftCount, rightCount)
	elseif self.deployType == game.DEPLOY_TYPE.MultTwo then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount)
	elseif self.deployType == game.DEPLOY_TYPE.MultThree then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount):initGroupRound(3, 1, self.waveCount)
	end

	self:initAfterWaveEnd(battlePlay.Gate.AfteWaveEndType.WinNext):initGroupRoundCheck(battlePlay.Gate.GroupRoundCheckType.SelfForceNotFail)
end

function GymGate:getFirstRoleOut(force)
	return self.scene:getObjectBySeat(PosByForce[force])
end

function GymGate:hasNextRoleOut(force)
	local waveRoleOutInfo = self.groupRoleOut[self.groupRound]
	local roleDatas = waveRoleOutInfo.waveRoleOut[force][self:getWaveInfo(force).waveIndex + 1]

	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		return roleDatas and roleDatas[PosByForce[force]]
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		return roleDatas and next(roleDatas)
	end
end

function GymGate:onInitRoleOutSupply()
	local waveRoleOutInfo = self.groupRoleOut[self.groupRound]

	if not waveRoleOutInfo then
		self.groupRoleOut[self.groupRound] = {
			waveRoleOut = {
				{},
				{}
			},
			waveRoleOut2 = {
				{},
				{}
			},
			aidRoleOut = self.data.aidRoleOut
		}
		waveRoleOutInfo = self.groupRoleOut[self.groupRound]

		if self.deployType == game.DEPLOY_TYPE.GeneralType or self.deployType == game.DEPLOY_TYPE.MultTwo or self.deployType == game.DEPLOY_TYPE.MultThree then
			if self.data.multipGroup then
				table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut[1][self.groupRound])
				table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2[1][self.groupRound])
			else
				table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut)
				table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2)
			end

			for j = 1, self.waveCount do
				local enemyRoleOut = self:getEnemyRoleOutT(j, self.groupRound)

				table.insert(waveRoleOutInfo.waveRoleOut[2], enemyRoleOut[j])
			end
		elseif self.deployType == game.DEPLOY_TYPE.OneByOneType then
			local roundLimit = csv.gym.gate[self.data.sceneID].deployCardNumLimit

			for i = 1, roundLimit do
				if self.data.roleOut[i] then
					table.insert(waveRoleOutInfo.waveRoleOut[1], {
						[PosByForce[1]] = self.data.roleOut[i]
					})
					table.insert(waveRoleOutInfo.waveRoleOut2[1], {
						[PosByForce[1]] = self.data.roleOut2[i]
					})
				end
			end

			local sceneCsv = csv.scene_conf[self.scene.sceneID]
			local advanceTb = {}

			for _, v in ipairs(sceneCsv.monsters or {}) do
				table.insert(advanceTb, v.advance)
			end

			for _, v in ipairs(sceneCsv.boss or {}) do
				table.insert(advanceTb, v.advance)
			end

			local forceWaveCount2 = math.max(0, self.waveCount + 1 - roundLimit)

			for i = 1, forceWaveCount2 do
				local waveRoleOutT = self:getEnemyRoleOutT(i)
				local objData = waveRoleOutT and waveRoleOutT[i][1 + self.ForceNumber]

				if objData then
					objData.advance = advanceTb[i]
				end

				table.insert(waveRoleOutInfo.waveRoleOut[2], {
					[PosByForce[2]] = objData
				})
				table.insert(waveRoleOutInfo.waveRoleOut2[2], {})
			end
		elseif self.deployType == game.DEPLOY_TYPE.WheelType then
			waveRoleOutInfo.waveRoleOut[1] = self.data.roleOut[1]
			waveRoleOutInfo.waveRoleOut2[1] = self.data.roleOut2[1]

			for i = 1, self:getWaveInfo(2).waveLimit do
				local enemyRoleOut = self:getEnemyRoleOutT(i, self.groupRound)

				table.insert(waveRoleOutInfo.waveRoleOut[2], enemyRoleOut and enemyRoleOut[i] or enemyRoleOut)
				table.insert(waveRoleOutInfo.waveRoleOut2[2], {})
			end
		end
	end
end

function GymGate:createObjectModel(force, seat)
	local obj

	if force == 1 then
		obj = ObjectModel.new(self.scene, seat)
	else
		obj = MonsterModel.new(self.scene, seat)
	end

	return obj
end

function GymGate:doObjsAttrsCorrect(isLeftC, isRightC)
	battlePlay.Gate.doObjsAttrsCorrect(self, isLeftC, isRightC)

	local cfg = csv.gym.gate[self.data.sceneID] or {}

	local function updateAttrs(obj)
		for __, eff in ipairs(cfg.specialEff or {}) do
			local function getBaseAddVal(oriVal)
				local val = eff[4]

				if string.find(val, "%%") then
					val = string.gsub(val, "%%", "")
					val = tonumber(val) / 100 * oriVal
				end

				if eff[3] > 0 then
					val = -val
				end

				return val
			end

			if itertools.include(eff[1], function(nature)
				return nature == obj:getNatureType(1) or nature == obj:getNatureType(2)
			end) then
				local key = game.ATTRDEF_TABLE[eff[2]]

				key = key == "hp" and "hpMax" or key
				key = key == "mp1" and "mp1Max" or key

				local baseVal = getBaseAddVal(obj.attrs.base[key])
				local base2Val = getBaseAddVal(obj.attrs.base2[key])

				if key == "hpMax" then
					baseVal = math.floor(baseVal)
					base2Val = math.floor(base2Val)
				end

				obj.attrs:addBaseAttr(key, baseVal)
				obj.attrs:addBase2Attr(key, base2Val)
				obj:correctHp(obj:hpMax(), obj:hpMax())
			end
		end
	end

	for _, obj in self.scene:ipairsHeros() do
		if isLeftC and obj.force == 1 or isRightC and obj.force == 2 then
			updateAttrs(obj)
		end
	end
end

function GymGate:checkBattleEnd()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		return checkBattleEnd1(self)
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		return checkBattleEnd1(self)
	end

	return battlePlay.Gate.checkBattleEnd(self)
end

function GymGate:onBattleEndSupply()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		onBattleEndSupply1(self)

		return
	end

	return battlePlay.Gate.onBattleEndSupply(self)
end

function GymGate:needExtraRound()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		if self.curRound > self.roundLimit then
			return false
		end

		local me = self.scene:getFieldObject(self.forceToObjId[1])
		local enemy = self.scene:getFieldObject(self.forceToObjId[2])

		if me and me:isFakeDeath() or enemy and enemy:isFakeDeath() then
			return true
		end

		return false
	elseif self.deployType == game.DEPLOY_TYPE.WheelType then
		if self.curRound > self.roundLimit then
			return false
		end

		for _, obj in self.scene:ipairsHeros() do
			if obj:isFakeDeath() then
				return true
			end
		end

		return false
	end

	return false
end

function GymGate:onSpecEndRuleCheckSupply()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
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
			return SpecEndRuleCheck2
		end

		return SpecEndRuleCheck1
	end
end

function GymGate:checkWaveEnd()
	local me = self:checkForceAllRealDead(1)
	local enemy = self:checkForceAllRealDead(2)

	if me and enemy then
		return true, battle.Const.Draw
	elseif me then
		return true, battle.Const.Fail
	elseif enemy then
		return true, battle.Const.Win
	end

	if self.curRound >= self.roundLimit and self:checkRoundEnd() and not self:needExtraRound() then
		local _, result = self:specialEndCheck()

		return true, result or battle.Const.Fail
	end

	return false
end

function GymGate:onWaveResultCheckSupply()
	local _, meWin = self:checkWaveEnd()

	return meWin
end

function GymGate:onWaveEndSupply()
	if self.deployType == game.DEPLOY_TYPE.OneByOneType then
		local me = self.scene:getFieldObject(self.forceToObjId[1])
		local enemy = self.scene:getFieldObject(self.forceToObjId[2])
		local whoToDead

		if self.waveResult == battle.Const.Win then
			whoToDead = self.scene:getHerosMap(2)
		elseif self.waveResult == battle.Const.Fail then
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

		if me then
			me.lastWaveTotalDamage = getObjTotalDamage(me)
		end

		if enemy then
			enemy.lastWaveTotalDamage = getObjTotalDamage(enemy)
		end
	end
end

function GymGate:makeEndViewInfos()
	local dbID, unitID = self:whoHighestDamageFromStats(1)

	return {
		result = self.result,
		dbID = dbID,
		unitID = unitID,
		actions = self:sendActionParams()
	}
end

function GymGate:postEndResultToServer(cb)
	local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage)
	local totalDamage = tb and tb[1]

	totalDamage = totalDamage or 0

	gRootViewProxy:raw():postEndResultToServer("/game/gym/gate/end", {
		cb = function(tb)
			cb(self:makeEndViewInfos(), tb)
		end
	}, self.scene.battleID, self.scene.sceneID, self.result, totalDamage)
end

local GymGateRecord = class("GymGateRecord", GymGate)

battlePlay.GymGateRecord = GymGateRecord
GymGateRecord.OperatorArgs = {
	isAuto = true,
	canSkip = true,
	canSpeedAni = true,
	canPause = true,
	canHandle = false,
	isFullManual = false
}

function GymGateRecord:init(data)
	battlePlay.GymGate.init(self, data)

	self.actionRecv = data.actions
end

function GymGateRecord:getActionRecv()
	local action = table.get(self.actionRecv, self.curRound, self.curBattleRound)

	if action == nil then
		return
	end

	if action[1] == 0 then
		return
	end

	return unpack(action)
end

function GymGateRecord:onceBattle(targetId, skillId)
	local rCurId, rTargetId, rSkillId = self:getActionRecv()

	if (rSkillId or 0) ~= 0 then
		self.scene.autoFight = false

		battlePlay.Gate.onceBattle(self, rTargetId, rSkillId)

		self.scene.autoFight = true

		if self.waitInput then
			error("why input be wait in record")
		end

		return
	end

	battlePlay.Gate.onceBattle(self, targetId, skillId)
end

local GymLeaderGate = class("GymLeaderGate", battlePlay.ArenaGate)

battlePlay.GymLeaderGate = GymLeaderGate

function GymLeaderGate:init(data)
	battlePlay.Gate.init(self, data)
end

function GymLeaderGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/gym/leader/battle/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self.result, gGameModel.battle.gym_id)
end

local CrossGymGate = class("CrossGymGate", battlePlay.GymLeaderGate)

battlePlay.CrossGymGate = CrossGymGate

function CrossGymGate:postEndResultToServer(cb)
	gRootViewProxy:raw():postEndResultToServer("/game/cross/gym/battle/end", function(tb)
		cb(self:makeEndViewInfos(), tb)
	end, self.result, gGameModel.battle.gym_id, gGameModel.battle.pos)
end

local GymLeaderGateRecord = class("GymLeaderGateRecord", battlePlay.ArenaGateRecord)

battlePlay.GymLeaderGateRecord = GymLeaderGateRecord
