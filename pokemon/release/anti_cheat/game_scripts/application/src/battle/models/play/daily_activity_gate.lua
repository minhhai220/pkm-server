-- chunkname: @src.battle.models.play.daily_activity_gate

require("battle.app_views.battle.module.include")

local DailyActivityGate = class("DailyActivityGate", battlePlay.Gate)

battlePlay.DailyActivityGate = DailyActivityGate
DailyActivityGate.OperatorArgs = {
	canSkip = true,
	canSpeedAni = true,
	canPause = false,
	canHandle = true,
	isFullManual = false,
	isAuto = false
}

function DailyActivityGate:ctor(scene)
	battlePlay.Gate.ctor(self, scene)

	self.curKillMonsterCount = 0
	self.lastKillMonsterCount = 0
	self.gateStar = 3
	self.totalDeadMonsterHp = 0
end

function DailyActivityGate:endMoreDelayTime()
	return 1500
end

function DailyActivityGate:onProcessSupply()
	gRootViewProxy:proxy():addSpecModule(battleModule.dailyActivityMods)
end

function DailyActivityGate:onInitGroupRoundSupply()
	if self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultTwo then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount)
	elseif self.scene.sceneConf.deployType == game.DEPLOY_TYPE.MultThree then
		self:initGroupRound(1, 1, self.waveCount):initGroupRound(2, 1, self.waveCount):initGroupRound(3, 1, self.waveCount)
	else
		self:initGroupRound(1, 1, self.waveCount)
	end

	self:initAfterWaveEnd(battlePlay.Gate.AfteWaveEndType.WinNext):initGroupRoundCheck(battlePlay.Gate.GroupRoundCheckType.SelfForceNotFail)
end

function DailyActivityGate:onInitRoleOutSupply()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		self.monsterLib = {}

		local monsterRange = self.scene.sceneConf.monsterRange or {}

		for unitID, num in csvPairs(monsterRange) do
			for i = 1, num do
				table.insert(self.monsterLib, unitID)
			end
		end

		table.sort(self.monsterLib)

		local exConditions = self.scene.sceneConf.finishPoint

		self.totalCount = exConditions.killNumber or 0

		if self.totalCount == 0 then
			self.totalCount = table.length(self.monsterLib)
		end

		gRootViewProxy:notify("killCount", {
			curCount = 0,
			totalCount = self.totalCount
		})
	elseif self.scene.gateType == game.GATE_TYPE.dailyGold then
		local monsterCfg = battleEasy.getMonsterCsv(self.scene.sceneID, 1, self.groupRound)

		self.bossLifeTotalCount = monsterCfg.bossLifeCount or 1
		self.bossLastLifeBarsPer = self.bossLifeTotalCount * 100

		local bossId

		for idx, unitId in ipairs(monsterCfg.monsters) do
			if unitId > 0 and monsterCfg.bossMark and monsterCfg.bossMark[idx] == 1 then
				bossId = unitId
			end
		end

		if bossId then
			local unitCfg = csv.unit[bossId]

			gRootViewProxy:notify("initBossLife", {
				name = unitCfg.name,
				headIconRes = unitCfg.icon,
				leftBars = self.bossLifeTotalCount,
				barsLife = self.bossLastLifeBarsPer
			})
		end
	end

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

		if self.data.multipGroup then
			table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut[1][self.groupRound])
			table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2[1][self.groupRound])
		else
			table.insert(waveRoleOutInfo.waveRoleOut[1], self.data.roleOut)
			table.insert(waveRoleOutInfo.waveRoleOut2[1], self.data.roleOut2)
		end

		for j = 1, self.waveCount do
			if self.scene.gateType == game.GATE_TYPE.dailyExp then
				local supplyRoleOutT = {}

				for seat = 7, 12 do
					supplyRoleOutT[seat] = self:getMonsterFromLib()
				end

				table.insert(waveRoleOutInfo.waveRoleOut[2], supplyRoleOutT)
			else
				local enemyRoleOut = self:getEnemyRoleOutT(j, self.groupRound)

				table.insert(waveRoleOutInfo.waveRoleOut[2], enemyRoleOut[j])
			end
		end
	end
end

function DailyActivityGate:setBoss(obj)
	self.curBoss = obj
	self.hpPerRatio = obj:hpMax() / self.bossLastLifeBarsPer
end

function DailyActivityGate:createObjectModel(force, seat)
	if force == 1 then
		return ObjectModel.new(self.scene, seat)
	elseif self.scene.gateType == game.GATE_TYPE.dailyGold then
		return BossModel.new(self.scene, seat)
	else
		return MonsterModel.new(self.scene, seat)
	end

	return obj
end

function DailyActivityGate:onWaveAddObjsStrategySupply()
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		self.hpPerRatio = self.curBoss:hpMax() / self.bossLastLifeBarsPer
	end
end

function DailyActivityGate:getMonsterFromLib()
	if not next(self.monsterLib) then
		return
	end

	local idx = ymrand.random(1, table.length(self.monsterLib))
	local unitID = self.monsterLib[idx]

	table.remove(self.monsterLib, idx)

	local roleData = {
		roleForce = 2,
		advance = 0,
		isMonster = true,
		roleId = unitID,
		level = self.scene.sceneLevel,
		skillLevel = self.scene.skillLevel,
		showLevel = self.scene.showLevel
	}

	return roleData
end

function DailyActivityGate:addMonstersOnBattleTurnEnd()
	local supplyRoleOutT = {}
	local exConditions = self.scene.sceneConf.finishPoint
	local totalCount = exConditions.killNumber or 0
	local createCount = 0

	for seat = 7, 12 do
		local obj = self.scene:getObjectBySeatExcludeDead(seat)

		if not obj and self.scene:isSeatEmpty(seat) then
			createCount = createCount + 1

			if totalCount >= self.curKillMonsterCount + createCount then
				supplyRoleOutT[seat] = self:getMonsterFromLib()
			end
		end
	end

	self:addCardRolesInProcess(2, nil, supplyRoleOutT, nil, true)
end

function DailyActivityGate:calcBossLifeBarsLostHp()
	local boss = self.curBoss
	local curPer = math.ceil(boss:hp() / self.hpPerRatio)
	local lostHpPer = math.max(0, self.bossLastLifeBarsPer - curPer)

	self.bossLastLifeBarsPer = curPer
	self.bossLostLifePer = math.ceil(100 - boss:hp() / boss:hpMax() * 100)

	return lostHpPer
end

function DailyActivityGate:calcBossDrop()
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		local boss = self.curBoss

		if not boss then
			return
		end

		local lastPer = self.curBossLifePer or 1
		local curPer = cc.clampf(boss:hp() / boss:hpMax(), 0, 1)

		self.curBossLifePer = curPer

		local lostPer = cc.clampf(math.floor((lastPer - curPer) * 100), 0, 100)
		local nodePer = cc.clampf(math.floor((1 - curPer) * 100), 0, 100)
		local dropTb = {
			nPer = lostPer,
			nNode = nodePer,
			tostrModel = tostring(boss)
		}

		return dropTb
	end
end

function DailyActivityGate:calcDeathDrop(deathObj)
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		if deathObj.force == 1 then
			return
		end

		local addCount = self.curKillMonsterCount - self.lastKillMonsterCount

		self.lastKillMonsterCount = self.curKillMonsterCount

		local dropTb = {
			nPer = addCount,
			nNode = self.curKillMonsterCount,
			tostrModel = tostring(deathObj)
		}
		local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.totalHp) or {}

		self.totalDeadMonsterHp = self.totalDeadMonsterHp + (tb[deathObj.seat] or 0)

		return dropTb
	end
end

function DailyActivityGate:gateDoOnObjectBeAttacked(objId)
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		local boss = self.curBoss

		if not boss or boss.id ~= objId then
			return
		end

		local lostPer = self:calcBossLifeBarsLostHp()

		battleEasy.deferNotifyCantJump(nil, "bossLostHp", {
			lostHpPer = lostPer
		})
	end
end

function DailyActivityGate:gateDoOnSkillEnd()
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		return self:calcBossDrop()
	end
end

function DailyActivityGate:gateDoOnObjectDead(deathObj)
	if self.scene.gateType == game.GATE_TYPE.dailyExp and deathObj.force == 2 then
		self.scene.extraRecord:addExRecord(battle.ExRecordEvent.killNumber, 1, "Val")

		self.curKillMonsterCount = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.killNumber, "Val") or 0

		local dropTb = self:calcDeathDrop(deathObj)

		if dropTb then
			battleEasy.deferNotify(nil, "dropShow", dropTb)
		end
	end
end

function DailyActivityGate:onTurnStartSupply()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		battleEasy.deferNotify(nil, "killCount", {
			curCount = self.curKillMonsterCount,
			totalCount = self.totalCount
		})
		self:addMonstersOnBattleTurnEnd()
		self:doObjsAttrsCorrect(false, true)
	end
end

function DailyActivityGate:onRoundEndSupply()
	battleEasy.deferNotify(nil, "roundEndDropCollection")
end

function DailyActivityGate:onBattleEndSupply()
	if self.scene.gateType == game.GATE_TYPE.dailyExp then
		battleEasy.deferNotify(nil, "killCount", {
			curCount = self.curKillMonsterCount,
			totalCount = self.totalCount
		})
	end

	battleEasy.deferNotify(nil, "roundEndDropCollection")
end

function DailyActivityGate:makeEndViewInfos()
	local percent = 0
	local score = 0
	local rankNode = 1

	local function getNode(huodongId, curVal)
		huodongId = huodongId or 1

		local cfg = csv.huodong[huodongId] or {}
		local rankShow = cfg.rankShow or {}
		local node = 1

		for i, val in ipairs(rankShow) do
			if curVal < val then
				break
			else
				node = i
			end
		end

		return node
	end

	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		percent = self.bossLostLifePer or 0

		local tb = self.scene.extraRecord:getEvent(battle.ExRecordEvent.campDamage) or {}

		score = tb[1] or 0
		rankNode = getNode(1, percent)
	elseif self.scene.gateType == game.GATE_TYPE.dailyExp then
		percent = self.curKillMonsterCount or 0
		score = self.totalDeadMonsterHp or 0
		rankNode = getNode(2, percent)
	end

	return {
		result = self.result,
		socre = score,
		percent = percent,
		rankNode = rankNode
	}
end

function DailyActivityGate:postEndResultToServer(cb)
	local endInfos = self:makeEndViewInfos()

	gRootViewProxy:raw():postEndResultToServer("/game/huodong/end", function(tb)
		cb(endInfos, tb)
	end, self.scene.battleID, self.scene.sceneID, self.result, self.gateStar, endInfos.percent, endInfos.socre)
end

function DailyActivityGate:endBattleTurn(target)
	if self.scene.gateType == game.GATE_TYPE.dailyGold then
		self.curBoss:playAniAfterBattleTurn()
	end

	local endDelay = 500

	if self.battleTurnInfoTb.hasDeadObj then
		endDelay = 1500
	end

	battleEasy.queueEffect(function()
		battleEasy.queueEffect("delay", {
			lifetime = endDelay
		})
	end)
	battlePlay.Gate.endBattleTurn(self, target)
end
