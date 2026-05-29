local AidSkillModel = class("AidSkillModel", battleSkill.SkillModel)

battleSkill.AidSkillModel = AidSkillModel

function AidSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

	local aidID = owner.cardCfg.aidID
	local skillCfg = csv.aid.aid_skill[aidID]

	self.aidCfg = skillCfg
	self.cdRound = skillCfg.cdRound

	local startRound = battleCsv.doFormula(skillCfg.startRound, self.protectedEnv)

	self._startRound = startRound

	local timesLimit = battleCsv.doFormula(skillCfg.timesLimit, self.protectedEnv)

	self._timesLimit = {
		timesLimit,
		timesLimit
	}
	self._triggerTime = 0
	self.roundTimesLimit = skillCfg.roundTimes
	self.roundTriggerTimes = {}
	self._initRound = scene:getRoundAllWave()
	self.formulaConditions = skillCfg.conditions
	self.formulaTriggerType = skillCfg.triggerType

	gRootViewProxy:notify("newAidSkill", owner.force, tostring(owner), owner.unitID, self:timeLimit())
end

function AidSkillModel:timeLimit(isLimit)
	if isLimit then
		return self._timesLimit[2]
	end

	return self._timesLimit[1]
end

function AidSkillModel:checkRound()
	local forceAidTimes = self.scene.play.aidManager:getLeftAidTimes(self.owner.force)

	if forceAidTimes <= 0 or self:timeLimit() <= 0 then
		return false, 2
	end

	local curRound = self.scene:getRoundAllWave() - self._initRound

	if curRound < self._startRound or self:getLeftCDRound() >= 1 then
		return false, 3
	end

	local roundTriggerTimes = self:getRoundTriggerTimes(self.roundTimesLimit[1])

	if roundTriggerTimes >= self.roundTimesLimit[2] then
		return false, 4
	end

	return true
end

function AidSkillModel:preCanSpell(triggerType)
	local myTriggerType = battleCsv.doFormula(self.formulaTriggerType, self.protectedEnv)

	if myTriggerType ~= triggerType then
		return false, 1
	end

	local ret, reason = self:checkRound()

	if not ret then
		return ret, reason
	end

	if self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
		skillType2 = self.skillType2,
		skillId = self.id
	}) then
		return false, 5
	end

	local condition = self.formulaConditions[triggerType]

	condition = battleCsv.doFormula(condition, self.protectedEnv)

	if not condition then
		return false, 6
	end

	self._triggerTime = self._triggerTime + 1

	return true
end

function AidSkillModel:canSpell()
	local round = self.owner:getEventByKey(battle.ExRecordEvent.roundAttackTime)

	if round == self.checkRoundAttackTime then
		return self.isSpellable
	end

	self.checkRoundAttackTime = round

	local breakNum = 0

	self.isSpellable, breakNum = self:_canSpell()

	log.battle.skill.canSpellSkillId({
		round = round,
		skill = self,
		breakNum = breakNum
	})

	return self.isSpellable
end

function AidSkillModel:startDeductMp()
	if self._triggerTime == 0 then
		return
	end

	self._triggerTime = self._triggerTime - 1

	local curRound = self.scene:getRoundAllWave()

	self._timesLimit[1] = self._timesLimit[1] - 1

	self.scene.play.aidManager:updateForceAidTimes(self.owner.force, -1)

	self.roundTriggerTimes[curRound] = (self.roundTriggerTimes[curRound] or 0) + 1

	battleEasy.pushNotifyRootView("updateObjAidTimes", self.owner.force, tostring(self.owner), -1)
	battleEasy.pushNotifyRootView("updateForceAidTimes", self.owner.force, self.scene.play.aidManager:getLeftAidTimes(self.owner.force))
end

function AidSkillModel:_canSpell()
	if self:isNormalSkillType() then
		local tar = self:getTargetsHint()
		local sneerAtMeObj = self.owner:getSneerObj()

		if sneerAtMeObj and sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = self.owner
		}) then
			if self.owner:isBeInDuel() then
				return false, 4
			else
				tar = self.owner:getCanAttackObjs(sneerAtMeObj.force)
			end
		end

		if table.length(tar) == 0 and self.damageFormula and self.owner:isBeInConfusion() then
			local selfSideObjs, enemySideObjs, needSelfForce = self.owner:getConfusionCheckInfos()

			if self.owner:currentExtraBattleData() and self.owner:currentExtraBattleData().targetForce then
				tar = self.owner.force == self.owner:currentExtraBattleData().targetForce and selfSideObjs or enemySideObjs
			elseif needSelfForce then
				tar = selfSideObjs
			else
				tar = table.length(selfSideObjs) > 0 and selfSideObjs or enemySideObjs
			end
		end

		if table.length(tar) == 0 then
			return false, 5
		end
	end

	local ret, reason = self:checkRound()

	if not ret then
		return ret, reason
	end

	return self:getLeftCDRound() < 1, 10
end

function AidSkillModel:getRoundTriggerTimes(round)
	local curRound = self.scene:getRoundAllWave()
	local startRound = math.max(curRound - round + 1, 1)
	local cnt = 0

	for k = startRound, curRound do
		cnt = cnt + (self.roundTriggerTimes[k] or 0)
	end

	return cnt
end

function AidSkillModel:getLeftCDRound()
	if self.cdRound == 0 then
		return 0
	end

	local curRound = self.scene:getRoundAllWave()

	return self.cdRound - (curRound - self.spellRound - 1)
end

function AidSkillModel:startSpell()
	battleSkill.SkillModel.startSpell(self)

	self.spellRound = self.scene:getRoundAllWave()
end

function AidSkillModel:onSpellView(skillBB)
	local target, posIdx = skillBB.target, skillBB.lastPosIdx
	local scene = self.scene
	local view = self.owner.view
	local skillCfg = self.viewCfg
	local targets = self:targetsMap2Array(self.allTargets)
	local lastTarget

	self.owner.flashBack = skillCfg.flashBack

	view:proxy():setSkillJumpSwitch(self.canjumpBigSkill)

	for i, processCfg in self:ipairsProcess() do
		if processCfg.effectEventID then
			local effectCfg = self.processEventCsv[processCfg.id]

			if effectCfg and effectCfg.control then
				battleEasy.queueEffect("control", effectCfg.control)
			end
		end
	end

	local cantMoveIdx, isCantMoveBigSkill

	if self.owner:isCantMoveSkill() then
		if self.skillType2 == battle.MainSkillType.BigSkill then
			isCantMoveBigSkill = true
		else
			cantMoveIdx = battle.AttackPosIndex.selfPos
		end
	end

	if self.skillType2 == battle.MainSkillType.BigSkill then
		local hideHero = self:getBigSkillHideHero(isCantMoveBigSkill)

		battleEasy.queueEffect("sound", {
			delay = 0,
			sound = {
				loop = 0,
				res = "skill2_effect.mp3"
			}
		})
		battleEasy.queueEffect(function()
			gRootViewProxy:notify("aidStageEffect", nil, {
				self.owner
			})
		end)
		battleEasy.queueEffect(function()
			for _, obj in pairs(hideHero) do
				gRootViewProxy:proxy():onEventEffectByObj(obj, "show", {
					show = {
						{
							delay = 500,
							hide = true
						}
					}
				})
			end
		end)
		battleEasy.queueEffect("delay", {
			lifetime = 1200
		})
	end

	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()
		local spz = self.owner.view:proxy():getMovePosZ()
		local pz = math.min(tpz, spz)

		view:proxy():setLocalZOrder(pz + 1)
	end)
	battleEasy.queueEffect(function()
		local tpz = target.view:proxy():getMovePosZ()

		for id, obj in ipairs(targets) do
			tpz = math.max(tpz, obj.view:proxy():getMovePosZ())

			obj.view:proxy():objToHideEff(true)
		end

		battleEasy.queueEffect(function()
			view:proxy():setLocalZOrder(tpz + 1)
		end)
	end)

	if self.counterAttackForView then
		battleEasy.queueNotifyFor(view, "showCounterAttackText", tostring(self.owner), self.owner:getExtraRoundMode())

		self.counterAttackForView = false
	end

	battleEasy.queueNotifyFor(view, "skillBefore", self.disposeDatasOnSkillStart, self.skillType, false, skillBB.sceneTag)
	battleEasy.queueNotifyFor(view, "attacting", true)

	local protectorIDList = {}

	for k, v in ipairs(self.actionSegArgs) do
		if v.target and not lastTarget or lastTarget and lastTarget.id ~= v.target.id then
			battleEasy.queueNotifyFor(view, "moveToTarget", cantMoveIdx or v.posIdx, {
				delayBeforeMove = skillCfg.moveTime[1],
				moveCostTime = skillCfg.moveTime[2],
				timeScale = self.scene:getExtraRoundMode() and 0.51,
				cameraNear = skillCfg.cameraNear,
				cameraNear_posC = skillCfg.cameraNear_posC,
				posC = skillCfg.posC,
				attackFriend = self.owner:needAlterAttackTurn(),
				isCantMoveBigSkill = isCantMoveBigSkill
			}, false, tostring(v.target), self:filterProtectorView(v.target, protectorIDList))
		end

		lastTarget = v.target

		if skillCfg.sound and not self.canjumpBigSkill then
			self.owner.view:proxy():saveCustomEffectInfo(self:getRound(), 1, {
				sound = {
					sound = {
						res = skillCfg.sound.res,
						loop = skillCfg.sound.loop
					},
					delay = skillCfg.sound.delay
				}
			})
		end

		battleEasy.queueNotifyFor(view, "playAction", v.spine, v.lifeTime or false, false, isCantMoveBigSkill)
	end

	if self.canjumpBigSkill then
		local totalDmg, totalResumeHp = self:getTargetsFinalValue()
		local dmg, typ = totalDmg, battle.SkillSegType.damage

		if totalDmg == 0 and self:isSameType(battle.SkillFormulaType.resumeHp) then
			dmg, typ = totalResumeHp, battle.SkillSegType.resumeHp
		end

		local params = {
			delta = dmg,
			skillId = skillCfg.id,
			typ = typ
		}

		battleEasy.queueNotifyFor(view, "ultJumpShowNum", params)
	end

	battleEasy.queueNotifyFor(view, "objSkillEnd", self.disposeDatasOnSkillEnd, self.skillType)
	battleEasy.queueNotifyFor(view, "comeBack", posIdx, false, {
		delayBeforeBack = skillCfg.moveTime[3],
		backCostTime = skillCfg.moveTime[4],
		timeScale = self.scene:getExtraRoundMode() and 0.51,
		flashBack = isCantMoveBigSkill or skillCfg.flashBack,
		attackFriend = self.owner:needAlterAttackTurn()
	}, false, protectorIDList)
	battleEasy.queueNotifyFor(view, "afterComeBack", self.disposeDatasAfterComeBack)
	battleEasy.queueNotifyFor(view, "attacting", false)
	battleEasy.queueNotifyFor(view, "resetPos")
	battleEasy.queueNotifyFor(view, "objSkillOver")
end
