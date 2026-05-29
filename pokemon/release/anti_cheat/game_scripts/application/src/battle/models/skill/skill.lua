-- chunkname: @src.battle.models.skill.skill

local SkillAttrsInCsv = {
	"cdRound",
	"skillHit",
	"startRound",
	"skillPower",
	"skillNatureType"
}
local _max = math.max
local _min = math.min
local _insert = table.insert

local function otherEventHasJumpSeg(cfg)
	local otherEventIDs = cfg.otherEventIDs

	if otherEventIDs then
		for _, eventID in ipairs(otherEventIDs) do
			local cfg2 = csv.effect_event[gEffectByEventCsv[eventID]]

			if cfg2.jumpFlag then
				return true
			end
		end
	end

	return false
end

local PassiveSkillTypes = battle.PassiveSkillTypes
local SkillModel = class("Skill")

battleSkill.SkillModel = SkillModel

function SkillModel:ctor(scene, owner, cfg, level, source)
	self.scene = scene
	self.owner = owner
	self.id = cfg.id
	self.level = level or 1
	self.cfg = cfg
	self.viewCfg = {}
	self.chargeArgs = cfg.chargeArgs
	self.source = source
	self.checkRoundAttackTime = -1
	self.chargeRound = nil
	self.spellRound = -99
	self.isSpellable = false
	self.targetsFormulaResult = {}
	self.allTargets = {}
	self.allDamageTargets = {}
	self.allDamagedOrder = {}
	self.protectorObjs = {}
	self.allProcessesTargets = {}
	self.stateInfoTb = {}
	self.targetsFinalResult = {}
	self.targetsProcessResult = {}
	self.skillType = cfg.skillType
	self.skillType2 = cfg.skillType2
	self.skillFormulaType = nil
	self.killedTargetsTb = {}
	self.canjumpBigSkill = false
	self.disposeDatasOnSkillStart = {}
	self.disposeDatasOnSkillEnd = {}
	self.disposeDatasAfterComeBack = {}
	self.buffSputteringData = nil
	self.damageFormula = cfg.damageFormula
	self.hpFormula = cfg.hpFormula
	self.skillCalDamageProcessId = cfg.skillCalDamageProcessId
	self.diffSkillCalDmgProcessId = cfg.diffSkillCalDmgProcessId
	self.processes = {}
	self.realProcess = {}
	self.processEventCsv = {}
	self.actionSegArgs = {}
	self.isSpellTo = false
	self.counterAttackForView = false
	self.ignoreViewCheck = false
	self.nowTargetID = nil

	local hasJumpSeg = false
	local effectCfg, processCfg

	for _, processID in ipairs(self:getCfgSkillProcess()) do
		processCfg = csvClone(csv.skill_process[processID])
		if processCfg == nil then
			printDebug("技能id: %d 过程段id: %d 缺失!!!!!!", self.id, processID)
		end

		_insert(self.processes, processCfg)

		effectCfg = gProcessEventCsv and gProcessEventCsv[processID] or nil

		if effectCfg and (effectCfg.jumpFlag or otherEventHasJumpSeg(effectCfg)) then
			hasJumpSeg = true
		end

		processCfg.isSegProcess = effectCfg and effectCfg.segInterval and true or false
		processCfg.segType = battle.SkillSegType.buff

		if processCfg.isSegProcess then
			processCfg.segType = effectCfg.damageSeg and battle.SkillSegType.damage or battle.SkillSegType.resumeHp
		end

		self.processEventCsv[processID] = effectCfg
	end

	self.canJump = hasJumpSeg

	for _, attrName in ipairs(SkillAttrsInCsv) do
		self[attrName] = self.cfg[attrName] or 0
	end

	self.costMp1 = self.cfg.costMp1 / 1000

	self:initSkillType()

	self.protectedEnv = battleCsv.makeProtectedEnv(self.owner, self)
	self.blockEffect = battleCsv.doFormula(cfg.blockEffect, self.protectedEnv) or {}
	self.blockTriggerPoint = arraytools.hash(self.blockEffect.triggerPoint or {})

	self:initSkillAttrValue()
	self:initSkillArgs()
	self:initSkillViewArgs()
end

function SkillModel:getNowTarget()
	if self.nowTargetID then
		return self.scene:getFieldObject(self.nowTargetID)
	end

	return self.owner:getCurTarget()
end

function SkillModel:initSkillArgs()
	self.targetIgnoreBuff = {}

	if self.cfg.skillArgs and self.cfg.skillArgs[1] then
		self.targetIgnoreBuff = battleCsv.doFormulaTable(self.cfg.skillArgs[1], self.protectedEnv)
	end
end

local function getSkillEffectCfgBySegType(skill, segType, hash)
	for i, ret in ipairs(skill.processes) do
		if skill.processes[i].segType == segType and not hash[i] then
			return skill.processes[i], i
		end
	end
end

function SkillModel:initSkillViewArgs(otherSkill)
	local cfg = self.cfg

	if otherSkill then
		cfg = otherSkill.cfg

		for k, v in pairs(self.processEventCsv) do
			self.processEventCsv[k] = nil
		end

		local effectCfgHash = {}

		for i, ret in ipairs(otherSkill.processes) do
			local processCfg = otherSkill.processes[i]

			if processCfg.effectEventID then
				local effectCfg = otherSkill.processEventCsv[processCfg.id]
				local selfProcessCfg, index = getSkillEffectCfgBySegType(self, processCfg.segType, effectCfgHash)

				if selfProcessCfg == nil then
					errorInWindows("from: %s initSkillViewArgs to: %s error", otherSkill.id, self.id)

					break
				end

				self.processEventCsv[selfProcessCfg.id] = otherSkill.processEventCsv[processCfg.id]
				selfProcessCfg.effectEventID = processCfg.effectEventID

				if effectCfg and (effectCfg.jumpFlag or otherEventHasJumpSeg(effectCfg)) then
					self.canJump = true
				end

				effectCfgHash[index] = true
			end
		end
	end

	table.clear(self.viewCfg)

	self.viewCfg.flashBack = cfg.flashBack
	self.viewCfg.notShowProcedure = cfg.notShowProcedure
	self.viewCfg.moveTime = cfg.moveTime
	self.viewCfg.cameraNear = cfg.cameraNear
	self.viewCfg.cameraNear_posC = cfg.cameraNear_posC
	self.viewCfg.posC = cfg.posC
	self.viewCfg.sound = cfg.sound
	self.viewCfg.id = cfg.id
	self.viewCfg.effectBigName = cfg.effectBigName
	self.viewCfg.effectBigFlip = cfg.effectBigFlip
	self.viewCfg.effectBigPos = cfg.effectBigPos
	self.viewCfg.blankTime = cfg.blankTime
	self.viewCfg.scaleArgs = cfg.scaleArgs
	self.viewCfg.cameraNear_blankTime = cfg.cameraNear_blankTime
	self.viewCfg.cameraNear_scaleArgs = cfg.cameraNear_scaleArgs
	self.viewCfg.skillType = cfg.skillType
	self.viewCfg.posChoose = cfg.posChoose
	self.viewCfg.hintTargetType = cfg.hintTargetType
end

function SkillModel:getCfgSkillProcess()
	return self.scene:getCfgSkillProcess(self.id)
end

function SkillModel:updateStateInfoTb()
	local precent = self.owner:mp1() / self.owner:mp1Max() * self.costMp1
	local leftStartRound = math.max(self.startRound - self.owner:getBattleRound(2), 0)

	if self.skillType2 == battle.MainSkillType.BigSkill and self.owner:checkOverlaySpecBuffExit("noCostMp") then
		precent = 1
	end

	self.stateInfoTb = {
		canSpell = self:canSpell(),
		leftCd = self:getLeftCDRound(),
		leftStartRound = leftStartRound,
		precent = self.costMp1 == 0 and 1 or math.min(precent, 1),
		level = self:getLevel()
	}
end

function SkillModel:initSkillAttrValue()
	for _, attrName in ipairs(SkillAttrsInCsv) do
		self[attrName .. "Attr"] = function(self)
			error(string.format("%s Attr in SkillModel was deprecated", attrName))

			return self.cfg[attrName]
		end
	end
end

function SkillModel:getLevel()
	return _max(self.owner:dealOpenValueByKey("skillLevel" .. self.skillType2, self.level), 1)
end

function SkillModel:resetOnNewRound()
	self.counterAttackForView = false
	self.checkRoundAttackTime = -1
	self.isSpellable = false
end

function SkillModel:waveTriggeredCheck()
	return false
end

function SkillModel:resetOnNewWave()
	if self.chargeRound then
		battleEasy.queueNotifyFor(self.owner.view, "playCharge", {}, true)
	end

	self.checkRoundAttackTime = -1
	self.chargeRound = nil
	self.spellRound = -99
	self.isSpellable = false
end

function SkillModel:_canSpell()
	local curRound = self.owner:getBattleRound(2)
	local ignoreMpAndCd = self.owner:getExtraRoundMode() == battle.ExtraAttackMode.combo and self.owner:currentExtraBattleData().exAttackSkillID == self.id

	ignoreMpAndCd = ignoreMpAndCd or self:needIgnoreMpCd()

	if self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
		skillType2 = self.skillType2,
		skillId = self.id
	}) then
		return false, 1
	end

	if curRound < self.startRound and (not self.scene:getExtraRoundMode() or not self:isNormalSkillType()) then
		return false, 3
	end

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

	if self:isChargeSkill() and self:isChargeOK() then
		return true, 6
	end

	if self.skillType2 == battle.MainSkillType.BigSkill then
		if ignoreMpAndCd then
			return true, 7
		end

		log.battle.skill.costMp1({
			mp1Max = self.owner:mp1Max(),
			curMp1 = self.owner:mp1()
		})

		local ret = self.owner:mp1() / self.owner:mp1Max() >= self.costMp1

		if self.cdRound == 0 then
			return ret, 8
		elseif not ret then
			return false, 9
		end
	end

	return ignoreMpAndCd or self:getLeftCDRound() < 1, 10
end

function SkillModel:canSpell()
	if self.owner:currentExtraBattleData() then
		if self.owner:currentExtraBattleData().canSpell then
			return true
		end

		local skillPower = self.owner:currentExtraBattleData().skillPowerMap

		if skillPower and table.length(skillPower) > 0 and skillPower[self.skillType2 + 1] == 0 then
			return false
		end
	end

	local round = self.owner:getEventByKey(battle.ExRecordEvent.roundAttackTime)

	if round == self.checkRoundAttackTime and self.skillType2 == battle.MainSkillType.BigSkill then
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

function SkillModel:isChargeSkill()
	return self.chargeArgs and self.chargeArgs.round > 0
end

function SkillModel:isCharging()
	local breakChargingData = self.owner:getFrontOverlaySpecBuff("breakCharging")

	if self.chargeRound and not breakChargingData then
		return self.owner:getBattleRound(2) - self.chargeRound < self.chargeArgs.round
	end

	return false
end

function SkillModel:isChargeOK()
	local breakChargingData = self.owner:getFrontOverlaySpecBuff("breakCharging")

	if self.chargeRound then
		if breakChargingData then
			return breakChargingData.mode == 2
		else
			return self.owner:getBattleRound(2) - self.chargeRound >= self.chargeArgs.round
		end
	end

	return false
end

function SkillModel:cleanData()
	self.targetsFormulaResult = {}
	self.targetsFinalResult = {}
	self.targetsProcessResult = {}
	self.allTargets = {}
	self.allDamageTargets = {}
	self.allDamagedOrder = {}
	self.protectorObjs = {}
	self.allProcessesTargets = {}
	self.disposeDatasOnSkillStart = {}
	self.disposeDatasOnSkillEnd = {}
	self.disposeDatasAfterComeBack = {}
	self.killedTargetsTb = {}
	self.actionSegArgs = {}
	self.realProcess = {}
	self.damageFormula = self.cfg.damageFormula
	self.hpFormula = self.cfg.hpFormula
	self.skillCalDamageProcessId = self.cfg.skillCalDamageProcessId
	self.diffSkillCalDmgProcessId = self.cfg.diffSkillCalDmgProcessId
end

function SkillModel:startCharge()
	self.chargeRound = self.owner:getBattleRound(2)
	self.lastSpellRound = self.spellRound
	self.spellRound = self.owner:getBattleRound(2)

	self:startDeductMp()

	self.hadDeductedMp = true

	battleEasy.queueNotifyFor(self.owner.view, "playCharge", self.chargeArgs.action, false)
end

function SkillModel:endCharge(args)
	self.chargeRound = nil

	battleEasy.queueNotifyFor(self.owner.view, "playCharge", args or self.chargeArgs.action, true)
end

function SkillModel:spellBefore()
	if self.chargeRound then
		self:endCharge()
	elseif self:needIgnoreMpCd() then
		if self.spellRound < 1 then
			self.spellRound = -self.cfg.cdRound
		end
	elseif self.owner:currentExtraBattleData().exAttackSkillID ~= self.id then
		self.spellRound = self.owner:getBattleRound(2)
	end
end

function SkillModel:startSpell()
	self.isSpellable = false
	self.isSpellTo = true

	if self.ignoreViewCheck == false then
		self.viewCfg.posChoose = self.cfg.posChoose
	end

	self:spellBefore()
	self:sortRealProcess()
	self:updateSkillDamageProcessId()
	self:useOtherSkillProcess()
end

function SkillModel:updateSkillDamageProcessId()
	local alterProcessId
	local dmgProcessIdFormula = self.diffSkillCalDmgProcessId.formula

	if dmgProcessIdFormula then
		self.protectedEnv:resetEnv()

		local target = self.owner:getCurTarget()
		local env = battleCsv.fillFuncEnv(self.protectedEnv, {
			target = target
		})

		alterProcessId = battleCsv.doFormula(dmgProcessIdFormula, env)
	end

	self.skillCalDamageProcessId = alterProcessId or self.cfg.skillCalDamageProcessId
end

local function isActiveSkill(skillType2)
	local SkillActiveType = {
		[battle.MainSkillType.NormalSkill] = true,
		[battle.MainSkillType.SmallSkill] = true,
		[battle.MainSkillType.BigSkill] = true
	}

	if SkillActiveType[skillType2] then
		return true
	end

	return false
end

function SkillModel:useOtherSkillProcess()
	if not self:isNormalSkillType() then
		return
	end

	local function getOtherProcessBySkillID()
		if self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.replaceExAttackSkill) then
			local buffData = self.owner:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.replaceExAttackSkill)

			if buffData.mode ~= 2 then
				return nil
			end

			if buffData.processMode == 1 then
				return buffData.otherProcessBySkillID
			elseif buffData.processMode == 2 then
				if not isActiveSkill(self.skillType2) then
					return nil
				end

				local skillTb = self.owner:getOriginSkillTb()
				local length = table.length(skillTb[self.skillType2])

				if length > 0 then
					return skillTb[self.skillType2][1]
				end
			end

			return nil
		end

		local sneerData = self.owner:isBeInObjSneer()

		if sneerData and sneerData.otherProcessBySkillID then
			return sneerData.otherProcessBySkillID
		end

		if self.owner:currentExtraBattleData() and self.owner:currentExtraBattleData().otherProcessBySkillID then
			return self.owner:currentExtraBattleData().otherProcessBySkillID
		end
	end

	local otherProcessBySkillID = getOtherProcessBySkillID()

	if otherProcessBySkillID then
		local skillCfg = csv.skill[otherProcessBySkillID]

		self.damageFormula = skillCfg.damageFormula or self.damageFormula
		self.hpFormula = skillCfg.hpFormula or self.hpFormula
		self.skillCalDamageProcessId = skillCfg.skillCalDamageProcessId or self.skillCalDamageProcessId
		self.diffSkillCalDmgProcessId = skillCfg.diffSkillCalDmgProcessId or self.diffSkillCalDmgProcessId

		for _, processCfg in ipairs(self.realProcess) do
			processCfg.buffList = {}
			processCfg.buffProb = {}
			processCfg.buffLevel = {}
			processCfg.buffValue1 = {}
		end

		local skillProcess = self.scene:getCfgSkillProcess(otherProcessBySkillID)

		for _, processID in ipairs(skillProcess) do
			local processCfg = csvClone(csv.skill_process[processID])
			processCfg.isSegProcess = false
			processCfg.segType = battle.SkillSegType.buff
			processCfg.effectEventID = nil

			table.insert(self.realProcess, processCfg)
		end

		log.battle.skill.useOtherSkillProcess({
			skill = self,
			otherProcessBySkillID = otherProcessBySkillID
		})
	end
end

function SkillModel:isJumpBigSkill()
	return self.skillType2 == battle.MainSkillType.BigSkill and self.canJump and userDefault.getForeverLocalKey("mainSkillPass", false)
end

function SkillModel:needIgnoreMpCd()
	local exAttackArgs = self.owner:currentExtraBattleData()

	if exAttackArgs and exAttackArgs.costType == battle.SkillCostType.IgnoreMpCd then
		return true
	end

	local roundAttackInfo = self.owner:getEventByKey(battle.ExRecordEvent.roundAttackInfo)

	if roundAttackInfo and roundAttackInfo.costType == battle.SkillCostType.IgnoreMpCd then
		return true
	end

	if self.skillType2 == battle.MainSkillType.BigSkill then
		for idx, data in self.owner:ipairsOverlaySpecBuff("noCostMp") do
			return true
		end
	end

	return false
end

function SkillModel:startDeductMp(isBack)
	if self.hadDeductedMp then
		self.hadDeductedMp = false

		return
	end

	if self:needIgnoreMpCd() then
		return
	end

	if self.skillType2 == battle.MainSkillType.BigSkill then
		local prob, fix = 1, 1

		if self.cfg.costMp1Args then
			self.protectedEnv:resetEnv()

			local env = battleCsv.fillFuncEnv(self.protectedEnv, {})
			local data = battleCsv.doFormula(self.cfg.costMp1Args, env)

			prob, fix = data[1] or prob, data[2] or fix
		end

		local randret = ymrand.random()
		local cost = self.owner:mp1Max() * self.costMp1

		if randret < prob then
			cost = cost * fix
		end

		self.owner:addMP1(-cost, {
			show = true
		})

		return
	end
end

function SkillModel:cancelSpellTo(deductCd, deductMp)
	if deductCd then
		self:spellBefore()

		self.isSpellTo = false
	end

	if deductMp then
		self:startDeductMp()
	end
end

function SkillModel:ipairsProcess()
	return ipairs(self.realProcess)
end

function SkillModel:isLastProcess(idx)
	return table.length(self.realProcess) == idx
end

function SkillModel:sortRealProcess()
	local effectCfg, lastDmgProcessIdx, prob, processCfg

	self.protectedEnv:resetEnv()

	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = self.owner:getCurTarget()
	})

	for i, ret in ipairs(self.processes) do
		processCfg = self.processes[i]
		effectCfg = self.processEventCsv[ret.id]

		local probArgExit = ret.extraArgs

		prob = probArgExit and battleCsv.doFormula(probArgExit.prob, env) or 1

		if prob > ymrand.random() then
			if probArgExit then
				self.owner:addExRecord(battle.ExRecordEvent.comboProcessTotalNum, 1)

				if probArgExit.lastPosChoose then
					self.viewCfg.posChoose = probArgExit.lastPosChoose
				end
			end

			if effectCfg and effectCfg.damageSeg then
				if lastDmgProcessIdx then
					self.processes[lastDmgProcessIdx].isLastDmgProcess = false
				end

				ret.isLastDmgProcess = true
				lastDmgProcessIdx = i
			end

			table.insert(self.realProcess, csvClone(processCfg))

			ret.isLastProcess = table.length(self.processes) == i
		else
			self.owner.view:proxy():saveIgnoreEffect(self:getRound(), processCfg.id, processCfg.effectEventID)
		end
	end
end

function SkillModel:getProcessArg(index)
	return self.realProcess[index]
end

function SkillModel:initSkillType()
	if self.damageFormula and self.hpFormula then
		self.skillFormulaType = battle.SkillFormulaType.fix

		return
	end

	if self.damageFormula then
		self.skillFormulaType = battle.SkillFormulaType.damage
	elseif self.hpFormula then
		self.skillFormulaType = battle.SkillFormulaType.resumeHp
	end
end

local csvSegType = {
	[battle.SkillSegType.damage] = battle.SkillFormulaType.damage,
	[battle.SkillSegType.resumeHp] = battle.SkillFormulaType.resumeHp,
	[battle.SkillSegType.buff] = battle.SkillFormulaType.fix
}

local function filterNoDeadObjectsToMap(objects)
	local notDeadHash = {}

	for _, obj in ipairs(objects) do
		if obj:hp() > 0 then
			notDeadHash[obj.id] = true
		end
	end

	return notDeadHash
end

function SkillModel:getRound()
	return self.owner.scene.play.totalRoundBattleTurn
end

function SkillModel:processBefore(skillBB)
	if self.cfg.spineAction then
		local round = self:getRound()

		battleEasy.queueEffect(function()
			self.owner.view:proxy():setSpineEffectMapRound(round)
		end)
	end

	local play01 = gRootViewProxy:proxy():pushDeferList(self.id, "play01")

	self:startDeductMp()

	local skillCfg = skillBB.skillCfg
	local skillDamageType = skillCfg.skillDamageType
	local firstSpine = true
	local effectCfg

	skillBB.processArgs = {}

	for i, processCfg in self:ipairsProcess() do
		local args = self:onProcess(processCfg, skillBB.target)

		args.skillId = self.id
		args.values = {}
		args.index = i
		skillBB.processArgs[i] = args

		self:saveProcessTargets(processCfg.id, args.targets, args.buffTargets)

		local extraTarget
		local lastProcessArg = self:getProcessArg(i - 1)

		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id].targets
		end

		local actionArg = {}

		if processCfg.effectEventID then
			actionArg.lifeTime = self.cfg.actionTime
			actionArg.processId = processCfg.id
			effectCfg = self.processEventCsv[processCfg.id]

			local isAction = false

			if effectCfg then
				if effectCfg.effectType == 0 and effectCfg.effectRes then
					self.owner.view:proxy():saveEffectInfo(self:getRound(), effectCfg.effectRes, processCfg.id, processCfg.effectEventID)

					actionArg.spine = effectCfg.effectRes
					isAction = true
				else
					if firstSpine then
						actionArg.spine = self.cfg.spineAction
						firstSpine = false
						isAction = true
					end

					self.owner.view:proxy():saveEffectInfo(self:getRound(), self.cfg.spineAction, processCfg.id, processCfg.effectEventID)
				end
			end

			if isAction then
				table.insert(self.actionSegArgs, actionArg)
			end
		end

		self:processAddBuff(processCfg, args.buffTargets, extraTarget, battle.SkillAddBuffType.Before)
	end

	skillBB.noMissTargetsArray = self:saveAllTargets()

	self:saveAllDamageTargets()

	self.allDamagedOrder = self:targetsMap2Array(self.allDamageTargets)
	self.disposeDatasOnSkillStart.skillStartAddBuffsPlayFuncs = gRootViewProxy:proxy():popDeferList(play01)
	skillBB.sceneTag = self:getSkillSceneTag()
end

function SkillModel:updateRecord()
	if self.skillType2 == battle.MainSkillType.NormalSkill or self.skillType2 == battle.MainSkillType.SmallSkill then
		self.owner:addExRecord(battle.ExRecordEvent.spellSkillTotal, 1)
	end

	if self:isNormalSkillType() and self.owner:getExtraRoundMode() then
		if self.owner:getExtraRoundMode() == battle.ExtraAttackMode.syncAttack then
			self.owner:addExRecord(battle.ExRecordEvent.roundSyncAttackTime, 1)
		end

		local buffId, roundTriggerLimit = self.owner:currentExtraBattleData().buffId, self.owner:currentExtraBattleData().roundTriggerLimit

		if roundTriggerLimit then
			self.owner:addExRecord(battle.ExRecordEvent.extraAttackRoundLimit, 1, buffId)

			local curTimes = self.owner:getEventByKey(battle.ExRecordEvent.extraAttackRoundLimit, buffId)

			if roundTriggerLimit <= curTimes then
				self.scene:cleanExRoundByBuffId(self.owner, buffId)
			end
		end
	end

	self.owner:addExRecord(self.skillType2, 1)

	if self.scene:getExtraRoundMode() and self.skillType2 == battle.MainSkillType.BigSkill then
		self.owner:addExRecord(battle.ExRecordEvent.exAttackSpellBigSkill, 1)
	end
end

function SkillModel:processPlay(skillBB)
	local processArgs, noMissTargetsArray = skillBB.processArgs, skillBB.noMissTargetsArray

	for i, processCfg in self:ipairsProcess() do
		local processTargets = self.allProcessesTargets[processCfg.id] and self.allProcessesTargets[processCfg.id].buffTargets
		local extraTarget
		local lastProcessArg = self:getProcessArg(i - 1)

		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id].targets
		end

		processArgs[i].buffTb = self:processAddBuff(processCfg, processTargets, extraTarget, battle.SkillAddBuffType.InPlay)
	end

	local play02 = gRootViewProxy:proxy():pushDeferList(self.id, "play02")

	if self.scene:getExtraRoundMode() and (self.owner:getExtraRoundMode() == battle.ExtraAttackMode.counter or self.owner:getExtraRoundMode() == battle.ExtraAttackMode.prophet) and self.skillType2 ~= battle.MainSkillType.PassiveSkill then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderCounterAttack, self)
	end

	if self:isNormalSkillType() then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAttackBefore, self)
	end

	for _, obj in ipairs(noMissTargetsArray) do
		if obj:hp() <= 0 then
			self:addObjectToKillTab(obj)
		end
	end

	skillBB.noDeadObjectTb = filterNoDeadObjectsToMap(noMissTargetsArray)

	if self:isSameType(battle.SkillFormulaType.damage) then
		for _, obj in ipairs(self.allDamagedOrder) do
			if self:isNormalSkillType() and not self.blockTriggerPoint[battle.BuffTriggerPoint.onHolderBeforeBeHit] then
				obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeforeBeHit, self)
			end
		end
	end

	self.disposeDatasOnSkillStart.skillStartTriggerBuffsPlayFuncs = gRootViewProxy:proxy():popDeferList(play02)
end

function SkillModel:dealSneer(isDamageType, doFunc)
	if not self.owner:isBeInSneer() then
		return
	end

	local spreadArg = self.owner:getSneerExtraArgs()

	if spreadArg == battle.SneerArgType.NoSpread or spreadArg == battle.SneerArgType.BuffSpread then
		local sneerObj = isDamageType and self.owner:getSneerObj() or self.owner

		if sneerObj then
			doFunc(sneerObj)
		end
	end
end

function SkillModel:dealSneerDuel(isDamageType, args)
	local data = self.owner:getDuelData()

	if not data then
		return
	end

	local duelObj = data.obj
	local spreadArg = data.extraArg.spreadArg1

	if spreadArg == battle.SneerArgType.NoSpread or spreadArg == battle.SneerArgType.BuffSpread then
		duelObj = isDamageType and duelObj or self.owner

		for idx = table.length(args.targets), 1, -1 do
			local _target = args.targets[idx]

			if _target.id ~= duelObj.id then
				table.remove(args.targets, idx)
			end
		end

		if table.length(args.targets) > 0 then
			return
		end

		for _, _target in ipairs(args.oriTargets) do
			if _target and _target.id == duelObj.id then
				table.insert(args.targets, duelObj)

				return
			end
		end
	end
end

function SkillModel:processTarget(skillBB)
	local processArgs = skillBB.processArgs
	local effectCfg

	if self:isNormalSkillType() then
		self.scene:updateBeAttackZOrder()
	end

	for i, processCfg in self:ipairsProcess() do
		local args = processArgs[i]
		local attackInSkill = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id)
		local isLastDmgProcess = args.process and args.process.isLastDmgProcess

		effectCfg = self.processEventCsv[processCfg.id]

		self:updateTarget(processCfg, skillBB.target, args)

		if processCfg.isSegProcess then
			local isDamageType = args.process.segType == battle.SkillSegType.damage

			self:dealSneerDuel(isDamageType, args)

			if self:isNormalSkillType() then
				if self:isSameType(battle.SkillFormulaType.damage) then
					for _, buff in self.owner:iterBuffs() do
						buff:refreshExtraTargets(battle.BuffExtraTargetType.segProcessTargets, args.targets)
					end
				end

				self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterRefreshTargets, {
					skill = self,
					segType = csvSegType[args.process.segType]
				})
			end

			if isDamageType and self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.changeSkillDamageTarget) then
				for _, changeData in self.owner:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeSkillDamageTarget, function(curData)
					return curData.chooseType ~= self.cfg.targetChooseType
				end) do
					local env = battleCsv.fillFuncEnv(self.protectedEnv, {
						toChangeTargets = args.targets,
						sputtering = battleTarget.process.sputtering,
						penetrate = battleTarget.process.penetrate
					})

					battleCsv.doFormula(changeData.targetFormula, env)

					break
				end
			end

			self:preCalcDamage(args)

			for segId, _ in ipairs(effectCfg.segInterval) do
				local isLastSeg = isLastDmgProcess and segId == table.length(effectCfg.segInterval)

				for idx, obj in ipairs(args.targets) do
					local oriObj

					if args.oriTargets[idx] then
						oriObj = args.oriTargets[idx]
					end

					self:onProcessLittleSeg(obj, args, segId, isLastSeg, oriObj, idx)
				end
			end
		end

		local otherTargets = table.shallowcopy(self.allTargets)

		for _, obj in ipairs(args.targets) do
			otherTargets[obj.id] = nil
		end

		otherTargets[self.owner.id] = nil
		args.otherTargets = otherTargets

		self.scene:excuteGroupObjFunc(1, battle.SpecialObjectId.teamShiled, "syncView", self, args, processCfg.isSegProcess)
		self.scene:excuteGroupObjFunc(2, battle.SpecialObjectId.teamShiled, "syncView", self, args, processCfg.isSegProcess)

		if processCfg.isSegProcess and self:isNormalSkillType() and self:isSameType(battle.SkillFormulaType.damage) then
			for _, obj in ipairs(args.targets) do
				if not self.blockTriggerPoint[battle.BuffTriggerPoint.onHolderAfterBeHit] then
					obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterBeHit, self)
				end
			end

			self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterHit, self)
		end

		args.deferList = args.deferList or {}
		args.deferList[processCfg.id] = args.deferList[processCfg.id] or {}
		args.deferList[processCfg.id] = gRootViewProxy:proxy():popDeferList(attackInSkill)

		battleEasy.queueNotifyFor(self.owner.view, "processArgs", processCfg.id, args)
	end

	for _, protector in maptools.order_pairs(self.protectorObjs) do
		if not itertools.include(self.allDamagedOrder, function(obj)
			return obj.id == protector.id
		end) then
			protector:updAttackerCurSkillTab(self, false)
			table.insert(self.allDamagedOrder, protector)
		end
	end

	self.scene:excuteGroupObjFunc(1, battle.SpecialObjectId.teamShiled, "popRecordData", self.owner.id, self.id)
	self.scene:excuteGroupObjFunc(2, battle.SpecialObjectId.teamShiled, "popRecordData", self.owner.id, self.id)
end

function SkillModel:processAfter(skillBB)
	local processArgs = skillBB.processArgs

	skillBB.noMissTargetsArray = self:saveAllTargets()

	local play03 = gRootViewProxy:proxy():pushDeferList(self.id, "play03")

	for _, obj in ipairs(skillBB.noMissTargetsArray) do
		if obj and obj:hp() <= 0 then
			obj:setDead(self.owner)
			self:addObjectToKillTab(obj)
		end
	end

	local mainNumShowType = self:isMainNumShowType() == battle.SkillFormulaType.damage and battle.SkillSegType.damage or battle.SkillSegType.resumeHp

	for i, processCfg in self:ipairsProcess() do
		local processTargets = self.allProcessesTargets[processCfg.id] and self.allProcessesTargets[processCfg.id].buffTargets
		local extraTarget
		local lastProcessArg = self:getProcessArg(i - 1)

		if i > 1 and lastProcessArg and self.allProcessesTargets[lastProcessArg.id] then
			extraTarget = self.allProcessesTargets[lastProcessArg.id].targets
		end

		self:processAddBuff(processCfg, processTargets, extraTarget, battle.SkillAddBuffType.After)

		local args = processArgs[i]

		if processCfg.isSegProcess then
			args.showType = mainNumShowType
		end

		local recordTargets

		if #processTargets > 0 then
			recordTargets = {}

			for _, v in ipairs(processTargets) do
				table.insert(recordTargets, v.seat)
			end
		end

		log.battle.skill.processTargets({
			skill = self,
			processCfg = processCfg,
			recordTargets = recordTargets
		})
		battleEasy.deferNotifyCantJump(self.owner.view, "processDel", processCfg.id)
	end

	self:pushDefreListToSkillEnd("skillEndAddBuffsPlayFuncs", gRootViewProxy:proxy():popDeferList(play03))

	skillBB.noDeadObjectTb = filterNoDeadObjectsToMap(skillBB.noMissTargetsArray)
end

function SkillModel:processAfterObjTrigger(skillBB)
	local skillCfg = self.cfg
	local target, noMissTargetsArray, noDeadObjectTb = skillBB.target, skillBB.noMissTargetsArray, skillBB.noDeadObjectTb
	local play04 = gRootViewProxy:proxy():pushDeferList(self.id, "play04")

	if self:isNormalSkillType() then
		if self:isSameType(battle.SkillFormulaType.damage) and not self.blockTriggerPoint[battle.BuffTriggerPoint.onHolderFinallyBeHit] then
			for _, obj in ipairs(self.allDamagedOrder) do
				obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderFinallyBeHit, self)
			end
		end

		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAttackEnd, self)
	end

	if target and target:isRealDeath() then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderKillHandleChooseTarget, self)
	end

	if next(self.killedTargetsTb) then
		self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderKillTarget, self, {
			killedTargets = self.killedTargetsTb
		})

		self.scene.play.battleTurnInfoTb.hasDeadObj = true
	end

	self:pushDefreListToSkillEnd("skillEndTriggerBuffsPlayFuncs", gRootViewProxy:proxy():popDeferList(play04))

	for _, obj in ipairs(noMissTargetsArray) do
		if noDeadObjectTb[obj.id] and obj:hp() <= 0 then
			self:addObjectToKillTab(obj)
		end
	end

	for _, obj in ipairs(noMissTargetsArray) do
		if noDeadObjectTb[obj.id] and obj:hp() <= 0 and obj.force == target.force then
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMateKilledBySkill, self)
		end
	end

	if self:isNormalSkillType() and self.scene.play.gateDoOnSkillEnd then
		self.disposeDatasOnSkillEnd.skillEndDrops = self.scene.play:gateDoOnSkillEnd()
	end

	local clickTarget = target and {
		target
	} or self.allProcessesTargets[self:getProcessArg(1).id].targets

	for _, obj in maptools.order_pairs(self.allTargets, "id") do
		if clickTarget[1] and clickTarget[1].id == obj.id or obj.id ~= self.owner.id then
			self.owner:onPassive(PassiveSkillTypes.recoverHp, obj, {
				skillType = self.skillType,
				hpFormula = self.hpFormula
			})
		end

		obj:updAttackerCurSkillTab(self, true)
	end

	for k, buff in self.scene:getBuffQuery():group("delSelfWhenTriggered", 2):order_pairs() do
		if buff.args.fromSkillId == self.id and buff.caster.id == self.owner.id then
			buff.nodeManager:onAfterObjTrigger()
		end
	end

	for _, obj in pairs(self.protectorObjs) do
		obj:updAttackerCurSkillTab(self, true)
	end
end

function SkillModel:processAfterDelObj()
	local play05 = gRootViewProxy:proxy():pushDeferList(self.id, "play05")

	for _, obj in ipairs(self.killedTargetsTb) do
		if obj and obj:isRealDeath() then
			self.scene:addObjToBeDeleted(obj)
		end
	end

	self:pushDefreListToSkillEnd("skillEndDeleteDeadObjs", gRootViewProxy:proxy():popDeferList(play05))
end

function SkillModel:isAttackSkill()
	return true
end

function SkillModel:processAfterRefresh(skillBB)
	local skillCfg = skillBB.skillCfg
	local mp1PointData = self.owner:getFrontOverlaySpecBuff("mp1OverFlow")

	if mp1PointData and mp1PointData.mode == 1 and self.skillType2 == battle.MainSkillType.BigSkill then
		local mpOverflow = self.owner:mpOverflow()
		local costMp1Point = cc.clampf(math.floor(mpOverflow / mp1PointData.rate), 0, mp1PointData.cost or math.floor(mp1PointData.limit / mp1PointData.rate))
		local costMp = costMp1Point * mp1PointData.rate

		self.owner.mp1Table[3] = cc.clampf(mpOverflow - costMp, 0, mp1PointData.limit)
	end

	local play06 = gRootViewProxy:proxy():pushDeferList(self.id, "play06")
	local totalSkillUseTimes = self.owner:getEventByKey(battle.ExRecordEvent.spellSkillTotal) or 0
	local canExtraRoundSkillMpAdd = not self.scene:getExtraRoundMode() or gExtraRoundTrigger[self.scene.play.battleRoundTriggerId or battle.defaultExtraAttackCheckId].enableActiveSkillMp

	if canExtraRoundSkillMpAdd then
		if self:isAttackSkill() and totalSkillUseTimes <= self.scene.play.recoverMp2RoundLimit then
			local cfg = self.scene:getSceneAttrCorrect(self.owner:serverForce())

			if cfg and cfg.activeSkillMp1 then
				self.owner:addMP1(cfg.activeSkillMp1)
			end
		end

		if not self.owner:checkOverlaySpecBuffExit("cantRecoverSkillMp") and skillCfg.recoverMp1 and skillCfg.recoverMp1 > 0 then
			log.battle.skill.skillEndRecoerMp1({
				skill = self,
				mp1 = self.owner:mp1(),
				recoverMp1 = skillCfg.recoverMp1
			})

			local mp1Correct = skillCfg.recoverMp1 * (1 + self.owner:mp1Recover())

			self.owner:addMP1(mp1Correct)
		end
	end

	self:pushDefreListAfterComeBack("afterComeBackRecoverMp", gRootViewProxy:proxy():popDeferList(play06))
end

function SkillModel:processAfterRefreshExtra(skillBB)
	local target = skillBB.target

	local function delExtraAttack(obj)
		if not obj then
			return
		end

		if not obj:isAlreadyDead() and self:isSameType(battle.SkillFormulaType.damage) then
			local counterTime = obj:onCounterAttack(self, target, self.owner) or 0

			for i = 1, counterTime do
				self.scene:addObjToExtraRound(obj)
			end

			obj:onSyncAttack(self, target, self.owner)
		end
	end

	if not self.scene:getExtraRoundMode() and self:isNormalSkillType() then
		for _, obj in self.scene:ipairsOnSiteHeros() do
			delExtraAttack(obj)
		end

		if not self.owner:isAlreadyDead() and self.owner:onComboAttack(self, target, self.owner) then
			self.scene:addObjToExtraRound(self.owner, 1)
		end
	end

	if self.scene:getExtraRoundMode() and self:isNormalSkillType() and (self.owner:getExtraRoundMode() == battle.ExtraAttackMode.counter or self.owner:getExtraRoundMode() == battle.ExtraAttackMode.prophet) then
		self.counterAttackForView = true
	end
end

function SkillModel:spellTo(target, args)
	self:_spellTo(target, args)
end

function SkillModel:_spellTo(target)
	log.battle.skill.spellTo({
		skill = self,
		owner = self.owner,
		target = target
	})
	self:cleanData()
	self:startSpell()

	self.canjumpBigSkill = self:isJumpBigSkill()

	self:updateRecord()

	local skillBB = {
		skillCfg = self.cfg,
		target = target
	}

	self:processBefore(skillBB)
	self:processPlay(skillBB)
	self:processTarget(skillBB)
	self:processAfter(skillBB)
	self:processAfterObjTrigger(skillBB)
	self:processAfterDelObj()
	self:processAfterRefresh(skillBB)
	self:processAfterRefreshExtra(skillBB)
	self:spellToOver(skillBB)
	self:onSpellView(skillBB)

	if self:isNormalSkillType() then
		self.scene.extraRecord:refreshEventRecord(battle.TimeIntervalType.mainSkillEnd)
	end
end

function SkillModel:spellToOver(skillBB)
	local target, processArgs = skillBB.target, skillBB.processArgs
	local targets, lastPosIdx = {}

	for k, actionArg in ipairs(self.actionSegArgs) do
		targets = self.allProcessesTargets[actionArg.processId].targets

		local curArg = processArgs[k]
		local viewTargets = {}

		for idx, obj in ipairs(targets) do
			if curArg.oriTargets[idx] then
				table.insert(viewTargets, curArg.oriTargets[idx])
			else
				table.insert(viewTargets, obj)
			end
		end

		actionArg.posIdx = self.owner.view:proxy():getMoveToTargetPos(self.viewCfg.posChoose, self.viewCfg.hintTargetType, viewTargets)
		actionArg.target = viewTargets[1] or self.owner:getCurTarget()
		lastPosIdx = actionArg.posIdx
	end

	if not lastPosIdx then
		targets = {}

		local targetsAdd = {}

		table.insert(targets, target)

		targetsAdd[target.id] = true

		for __, tarMap in maptools.order_pairs(self.allProcessesTargets) do
			for _, obj in ipairs(tarMap.targets) do
				if obj.id ~= self.owner.id and not targetsAdd[obj.id] then
					table.insert(targets, obj)

					targetsAdd[obj.id] = true

					obj:updAttackerCurSkillTab(self, true)
				end
			end
		end

		lastPosIdx = self.owner.view:proxy():getMoveToTargetPos(self.viewCfg.posChoose, self.viewCfg.hintTargetType, targets)
	end

	self.isSpellTo = false
	self.interruptBuffId = nil
	self.nowTargetID = nil

	self:sortViewProcess()

	skillBB.lastPosIdx = lastPosIdx
end

function SkillModel:sortViewProcess()
	self.protectedEnv:resetEnv()

	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = self.owner:getCurTarget()
	})

	for i, processCfg in self:ipairsProcess() do
		if processCfg.extraArgs and processCfg.extraArgs.effectProb then
			local prob = battleCsv.doFormula(processCfg.extraArgs.effectProb, env)

			if prob < ymrand.random() then
				self.owner.view:proxy():saveIgnoreEffect(self:getRound(), processCfg.id, processCfg.effectEventID)
			end
		end
	end
end

function SkillModel:onSpellView(skillBB)
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

	if self.skillType2 == battle.MainSkillType.BigSkill and not skillCfg.notShowProcedure.beforeMainSkill then
		local hideHero = self:getBigSkillHideHero(isCantMoveBigSkill)

		battleEasy.queueEffect("sound", {
			delay = 0,
			sound = {
				res = "skill2_effect.mp3",
				loop = 0
			}
		})
		battleEasy.queueEffect(function()
			gRootViewProxy:notify("ultSkillPreAni1")
			gRootViewProxy:notify("ultSkillPreAni2", tostring(self.owner), skillCfg, hideHero)
			gRootViewProxy:notify("objMainSkill")
		end)
		battleEasy.queueEffect("delay", {
			lifetime = 2000
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

function SkillModel:getTargetsFinalValue()
	local totalDmg, totalResumeHp = 0, 0

	for _, v in pairs(self.targetsFinalResult) do
		totalDmg = totalDmg + v.damage.real:get(battle.ValueType.normal)
		totalResumeHp = totalResumeHp + v.resumeHp.real:get(battle.ValueType.normal)
	end

	return totalDmg, totalResumeHp
end

function SkillModel:getTargets(friendOrEnemy, chooseType, selectedObj, exArgs, inputCfg)
	local params = {
		friendOrEnemy = friendOrEnemy,
		specialChoose = exArgs.specialChoose,
		targetLimit = exArgs.targetLimit,
		allProcessesTargets = exArgs.allProcessesTargets,
		inputExtraStr = exArgs.inputExtraStr,
		skillType = self.skillType,
		skillSegType = exArgs.segType,
		skillFixType = exArgs.fixType,
		skill = self,
		addAttackRangeObjs = self.owner:getAddAttackRangeObjs(self),
		outside = exArgs.outside,
		ignoreReplaceData = exArgs.ignoreReplaceData,
		getSelectableExObj = exArgs.getSelectableExObj
	}
	local targets = newTargetFinder(self.owner, selectedObj, chooseType, params, inputCfg)

	return targets
end

function SkillModel:getBaseSpurtTargets(target)
	local sneerJump = false

	self:dealSneer(true, function(sneerObj)
		sneerJump = true
	end)

	if sneerJump then
		return {}
	end

	local retT = {}
	local search = {
		{
			2,
			4
		},
		{
			1,
			3,
			5
		},
		{
			2,
			6
		},
		{
			1,
			5
		},
		{
			2,
			4,
			6
		},
		{
			3,
			5
		}
	}
	local tarSeat = target.seat > 6 and target.seat - 6 or target.seat

	for _, idx in ipairs(search[tarSeat]) do
		if target.force == 2 then
			idx = idx + 6
		end

		local obj = self.scene:getObjectBySeatExcludeDead(idx)
		local temp = false

		if obj and obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, {
			fromObj = self.owner
		}) then
			temp = true
		end

		if obj and obj:isAlreadyDead() == false and not temp then
			table.insert(retT, obj)
		end
	end

	retT = self:replaceSkillTargets(retT)

	table.sort(retT, function(aObj, bObj)
		return aObj.id < bObj.id
	end)

	return retT
end

function SkillModel:getSpurtTargets(target, allTargets, isColSpurt, oriTargets)
	local function isIdxInAllTargets(idx)
		for _, v in ipairs(allTargets) do
			if idx == v.seat then
				return true
			end
		end

		for _, v in ipairs(oriTargets) do
			if v and v.seat == idx then
				return true
			end
		end

		return false
	end

	local retT = self:getBaseSpurtTargets(target)
	local newRetT = {}

	for _, obj in ipairs(retT) do
		if not isIdxInAllTargets(obj.seat) then
			table.insert(newRetT, obj)
		end
	end

	retT = newRetT

	return retT
end

function SkillModel:getPenetrateTarget(target)
	local sneerJump = false

	self:dealSneer(true, function(sneerObj)
		sneerJump = true
	end)

	if sneerJump then
		return nil
	end

	local backObj
	local rowNum = (math.floor((target.seat + 2) / 3) - 1) % 2 + 1

	if rowNum == 1 then
		local obj = self.scene:getObjectBySeatExcludeDead(target.seat + 3)

		if obj and obj:isAlreadyDead() == false and not obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, {
			fromObj = self.owner
		}) then
			backObj = obj
		end
	end

	local retT = self:replaceSkillTargets({
		backObj
	})

	return retT[1]
end

function SkillModel:getReduceTarget(targets)
	if self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.reduceSkillDamageTarget) then
		targets = self.owner:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.reduceSkillDamageTarget, "reduceTargets", targets, self.id)

		local reduceTargetsForce, effectRes, effectAni
		local map = {}

		for _, target in ipairs(targets) do
			map[target.seat] = true
		end

		reduceTargetsForce = self.owner:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.reduceSkillDamageTarget, "getTargetsForce", self.id)

		for k, data in self.owner:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reduceSkillDamageTarget) do
			effectRes = data.effectRes
			effectAni = data.effectAnimation
		end

		for _, obj in self.scene:ipairsHeros() do
			if not map[obj.seat] and reduceTargetsForce == obj.force then
				gRootViewProxy:notify("reduceTarget", obj.seat, effectRes, effectAni)
			end
		end
	end

	return targets
end

function SkillModel:getTargetsHint(hitFormula)
	local skillCfg = self.cfg
	local sneerAtOwnerObj = self.owner:getSneerObj()
	local cfg = {
		hintChoose = self:getSkillCfgByKey("hintChoose"),
		hintTargetType = skillCfg.hintTargetType
	}

	hitFormula = hitFormula or skillCfg.hitFormula

	local targetCfg = {}

	if hitFormula and csvSize(hitFormula) > 0 then
		self.protectedEnv:resetEnv()

		local env = battleCsv.fillFuncEnv(self.protectedEnv, {})
		local result

		for arg, data in csvMapPairs(hitFormula) do
			result = battleCsv.doFormula(data.key, env) and 1 or 2
			targetCfg[arg] = data.value[result] or targetCfg[arg]
		end
	end

	local args = {
		inputExtraStr = "nobeskillselectedhint",
		specialChoose = skillCfg.specialHintChoose,
		skill = self
	}

	if self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.controlEnemy) then
		cfg.hintTargetType = 1 - cfg.hintTargetType

		if self.skillFormulaType == 1 then
			args.outside = "excludeSelf()"
		end
	end

	if cfg.hintTargetType == 0 and sneerAtOwnerObj and not sneerAtOwnerObj:isAlreadyDead() then
		cfg.hintChoose = 1
	end

	if self:isSameType(battle.SkillFormulaType.fix) and cfg.hintChoose > 100 then
		local tmpHintChoose = cfg.hintChoose

		args.fixType = battle.SkillFormulaType.resumeHp

		local healthChoose = math.floor(tmpHintChoose / 100)
		local healthTargets = self:getTargets(1 - cfg.hintTargetType, healthChoose, sneerAtOwnerObj, args, targetCfg)
		local damageChoose = cfg.hintChoose - healthChoose * 100

		args.fixType = battle.SkillFormulaType.damage

		local damageTargets = self:getTargets(cfg.hintTargetType, damageChoose, sneerAtOwnerObj, args, targetCfg)
		local targets = arraytools.merge({
			healthTargets,
			damageTargets
		})

		targets = self:getReduceTarget(targets)

		return targets
	end

	local targets = self:getTargets(cfg.hintTargetType, cfg.hintChoose, sneerAtOwnerObj, args, targetCfg)

	targets = self:getReduceTarget(targets)

	if self.scene.play.curHero and self.scene.play.curHero.id ~= self.owner.id then
		gRootViewProxy:notify("reduceTarget")
	end

	return targets
end

function SkillModel:autoChoose()
	return self:getTargetsHint(self.cfg.autoHintChoose)
end

function SkillModel:getSkillCfgByKey(key)
	return self.owner:dealOpenValueByKey(key, self.cfg[key])
end

function SkillModel:updateMustHitTargets(processCfg, targets, tmpSneerObjId)
	local exTurnMustHitIds = self.owner.scene.play:getExtraBattleRoundData("mustHit")
	local processCfgId = self.owner.scene.play:getExtraBattleRoundData("processCfgId")

	if processCfg.id == processCfgId and exTurnMustHitIds and table.length(exTurnMustHitIds) > 0 then
		local objHash = arraytools.hash(exTurnMustHitIds)
		local canReplacePos = {}

		for idx, obj in ipairs(targets) do
			if objHash[obj.id] then
				objHash[obj.id] = nil
			elseif obj.id ~= tmpSneerObjId then
				table.insert(canReplacePos, idx)
			end
		end

		local head = 1

		for _, objId in ipairs(exTurnMustHitIds) do
			if not canReplacePos[head] then
				break
			end

			local curObj = self.owner.scene:getFieldObject(objId)

			if objHash[objId] and curObj and not curObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
				fromObj = self.owner
			}) then
				targets[canReplacePos[head]] = curObj
				head = head + 1
			end
		end
	end

	return targets
end

function SkillModel:onProcessGetTargets(processCfg, target)
	if processCfg.targetFormula and csvSize(processCfg.targetFormula) > 0 then
		self.protectedEnv:resetEnv()

		local env = battleCsv.fillFuncEnv(self.protectedEnv, {
			target = target
		})
		local result

		for arg, data in csvMapPairs(processCfg.targetFormula) do
			if data.key then
				result = battleCsv.doFormula(data.key, env) and 1 or 2
			elseif data.keyNum then
				result = battleCsv.doFormula(data.keyNum, env)
			end

			processCfg[arg] = data.value[result] or processCfg[arg]
		end
	end

	local cfg = processCfg.input and {
		input = processCfg.input,
		process = processCfg.process
	}
	local outside

	if self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.reduceSkillDamageTarget) then
		outside = "converged(battle.OverlaySpecBuff.reduceSkillDamageTarget)"
	end

	local inputExtraStr = "nobeskillselected"
	local targetType = processCfg.targetType

	if self.owner:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.controlEnemy) then
		if targetType < 2 then
			targetType = 1 - targetType
		end

		if self.skillFormulaType == 1 then
			if outside then
				outside = "excludeSelf" .. "|" .. outside
			else
				outside = "excludeSelf"
			end
		end
	end

	local ignoreReplaceData = {
		flag = false,
		buffFlags = {},
		objIds = {}
	}
	local targets = self:getTargets(targetType, processCfg.skillTarget, target, {
		getSelectableExObj = true,
		specialChoose = processCfg.specialChoose,
		targetLimit = processCfg.targetLimit,
		allProcessesTargets = self.allProcessesTargets,
		inputExtraStr = inputExtraStr,
		segType = csvSegType[processCfg.segType],
		outside = outside,
		ignoreReplaceData = ignoreReplaceData,
		skill = self
	}, cfg)

	if (not processCfg.extraArgs or not processCfg.extraArgs.targetCanBeEmpty) and table.length(targets) == 0 and processCfg.isSegProcess then
		targets = {
			self.owner:getCurTarget()
		}
	end

	local sneerAtMeObj = self.owner:getSneerObj()
	local tmpSneerObjId

	if sneerAtMeObj and not sneerAtMeObj:isNotReSelect() and not sneerAtMeObj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
		fromObj = self.owner
	}) then
		tmpSneerObjId = sneerAtMeObj.id

		local isHasEnemyForceObj = false

		for _, target in ipairs(targets) do
			if target.force ~= self.owner.force then
				isHasEnemyForceObj = true
			end

			if target.id == sneerAtMeObj.id then
				sneerAtMeObj = nil

				break
			end
		end

		if isHasEnemyForceObj then
			targets[1] = sneerAtMeObj or targets[1]
		end
	end

	targets = self:updateMustHitTargets(processCfg, targets, tmpSneerObjId)

	local backTargets = {}

	for i = table.length(targets), 1, -1 do
		if targets[i] and targets[i]:hasTypeBuff("setTargetsBack") then
			table.insert(backTargets, targets[i])
			table.remove(targets, i)
		end
	end

	for _, v in ipairs(backTargets) do
		table.insert(targets, v)
	end

	return targets, ignoreReplaceData
end

function SkillModel:onProcess(processCfg, target)
	log.battle.skill.process({
		skill = self,
		processCfg = processCfg
	})

	local targets, ignoreReplaceObjs = self:onProcessGetTargets(processCfg, target)
	local newTargets, oriTargets, buffTargets = self:replaceSkillTargets(targets, processCfg, ignoreReplaceObjs)

	for _, target in ipairs(newTargets) do
		if self:isSameType(battle.SkillFormulaType.damage) then
			local final = self:getTargetsFinalResult(target.id)

			if not final.value and not self.owner:isHit(target, self.cfg) then
				final.value = 0
				final.args.skillMiss = true
			end
		end

		target:updAttackerCurSkillTab(self, false)
		target:triggerBuffOnPoint(battle.BuffTriggerPoint.onSkillHitTarget, self)
	end

	return {
		process = processCfg,
		targets = newTargets,
		buffTargets = buffTargets,
		oriTargets = oriTargets
	}
end

function SkillModel:updateTarget(processCfg, target, args)
	if processCfg.extraArgs and processCfg.extraArgs.needUpdateTarget then
		local newArgs = self:onProcess(processCfg, target)

		args.targets = newArgs.targets
		args.oriTargets = newArgs.oriTargets

		self:saveProcessTargets(processCfg.id, newArgs.targets, newArgs.buffTargets)
	end
end

function SkillModel:onProcessLittleSeg(target, args, segId, isLastSeg, oriObj, objIndex)
	self:calcFormulaFinal(target, args)
	self:onTarget(target, args, segId, isLastSeg, oriObj, objIndex)
end

local preCalProbNames = {
	"miss",
	"block",
	"strike",
	"natureFlag",
	"nature",
	"hasCalcDamageProb"
}

function SkillModel:calcFormulaFinal(target, args)
	local skillCfg = self.cfg
	local final = self:getTargetsFinalResult(target.id, args.process.segType)

	if args.process.segType == battle.SkillSegType.resumeHp and not final.value then
		local formHp = self:calcFormula("hp", self.hpFormula, target)
		local skillNatureType = self:getSkillNatureType() or 1
		local objNatureName = game.NATURE_TABLE[skillNatureType]

		formHp = formHp * (1 + self.owner:cure() + self.owner[objNatureName .. "Cure"](self.owner) + self.owner:healAdd())
		final.value = formHp
		final.args = {
			casterId = self.owner.id
		}
	end

	if args.process.segType == battle.SkillSegType.damage and not final.value then
		local formDamage = self:calcFormula("damage", self.damageFormula, target)
		local randFix = self.scene.closeRandFix and 1 or ymrand.random(9000, ConstSaltNumbers.wan) / ConstSaltNumbers.wan

		if not formDamage then
			errorInWindows("skill(%d) formDamage(%s) is nil", self.id, self.damageFormula or "NIL")

			formDamage = 0
		end

		formDamage = formDamage * randFix

		log.battle.skill.damageFormula({
			owner = self.owner,
			formDamage = formDamage,
			skill = self
		})

		local exArgs = {
			skillId = skillCfg.id,
			natureType = self:getSkillNatureType() or 1,
			damageType = skillCfg.skillDamageType or battle.SkillDamageType.Physical,
			skillType2 = skillCfg.skillType2,
			skillPower = skillCfg.skillPower,
			from = battle.DamageFrom.skill,
			beAttackZOrder = self.scene.beAttackZOrder
		}

		if final.args then
			for _, name in ipairs(preCalProbNames) do
				exArgs[name] = final.args[name]
			end
		end

		local damage, damageArgs = target:calcInternalDamage(self.owner, formDamage, self.skillCalDamageProcessId, exArgs)

		final.value = damage
		final.args = damageArgs
	end
end

function SkillModel:preCalcDamageProb(target, args)
	if args.process.segType ~= battle.SkillSegType.damage then
		return
	end

	local final = self:getTargetsFinalResult(target.id, args.process.segType)

	final.value = nil

	local _, damageArgs = battleEasy.runDamageProcess(0, self.owner, target, self.skillCalDamageProcessId, {
		exProcessId = battle.DamageProbProcessId,
		skillId = self.cfg.id,
		natureType = self:getSkillNatureType() or 1
	})

	final.args = damageArgs
	final.args.hasCalcDamageProb = true
	final.probTriggerRecord = final.probTriggerRecord or {}

	local triggerInfo, hasNew = {}, false

	for _, name in ipairs(preCalProbNames) do
		if final.args[name] and not final.probTriggerRecord[name] then
			final.probTriggerRecord[name] = true
			triggerInfo[name] = final.args[name]
			hasNew = true
		end
	end

	if hasNew then
		target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderCalcDamageProb, triggerInfo)
	end
end

function SkillModel:preCalcDamage(args)
	self.buffSputteringData = self.owner:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.buffSputtering)

	for _, obj in ipairs(args.targets) do
		self:preCalcDamageProb(obj, args)
	end
end

function SkillModel:onSputterTarget(target, args, final, damageArgs, skillDamageBB)
	local data = target:getEventByKey(battle.ExRecordEvent.sputtering)

	if data then
		local spurtPer = data.rate

		if spurtPer < 1e-05 then
			return
		end

		local damageLimitFunc = data.func

		if damageArgs.segId == 1 then
			if not args.sputObjs then
				args.sputObjs = {}
			end

			args.sputObjs[target.id] = self:getSpurtTargets(target, args.targets, table.length(args.targets) > 1, args.oriTargets)

			local finalValue = final.value * spurtPer

			if damageLimitFunc then
				local env = battleCsv.fillFuncEnv(self.protectedEnv, {})

				data.spurtDamageMax = battleCsv.doFormula(damageLimitFunc, env)

				if final.value * spurtPer > data.spurtDamageMax then
					data.flagChange = 1
					finalValue = data.spurtDamageMax
				end
			end

			for _, obj in ipairs(args.sputObjs[target.id]) do
				local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)

				_final.value = _final.value or finalValue
			end
		end

		for _, obj in ipairs(args.sputObjs[target.id]) do
			local spurtDamage = skillDamageBB.damage * spurtPer

			if data.flagChange == 1 then
				spurtDamage = data.spurtDamageMax * skillDamageBB.segPer
			end

			spurtDamage = math.floor(spurtDamage)
			damageArgs.beHitNotWakeUp = true

			local _damage, _damageArgs = obj:beAttack(self.owner, spurtDamage, skillDamageBB.damageProcessAfterCal, damageArgs)
			local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)

			_final.real:add(_damage)

			_final.args = _damageArgs

			if _damageArgs.beAttackToDeath then
				self:addObjectToKillTab(obj)
			end

			if not self.canjumpBigSkill then
				self:addToSegDamage(_damage:get(battle.ValueType.normal))
			end
		end

		if skillDamageBB.isLastSeg then
			for _, obj in ipairs(args.sputObjs[target.id]) do
				if obj and obj:hp() <= 0 then
					obj:setDead(self.owner)
				end
			end

			target:cleanEventByKey(battle.ExRecordEvent.sputtering)

			args.sputObjs[target.id] = nil
		end
	end
end

function SkillModel:onPenetrateTarget(target, args, final, damageArgs, skillDamageBB)
	local data = target:getEventByKey(battle.ExRecordEvent.penetrate)

	if data then
		local penetratePer = data.rate

		if damageArgs.segId == 1 then
			args.penetrateObj = self:getPenetrateTarget(target)

			if args.penetrateObj then
				local _final = self:getTargetsFinalResult(args.penetrateObj.id, battle.SkillSegType.damage)

				_final.value = _final.value or final.value * penetratePer
			end
		end

		if args.penetrateObj then
			local penetrateDamage = math.floor(skillDamageBB.damage * penetratePer)

			damageArgs.beHitNotWakeUp = true

			local _damage, _damageArgs = args.penetrateObj:beAttack(self.owner, penetrateDamage, skillDamageBB.damageProcessAfterCal, damageArgs)
			local _final = self:getTargetsFinalResult(args.penetrateObj.id, battle.SkillSegType.damage)

			_final.real:add(_damage)

			_final.args = _damageArgs

			if _damageArgs.beAttackToDeath then
				self:addObjectToKillTab(args.penetrateObj)
			end

			if not self.canjumpBigSkill then
				self:addToSegDamage(_damage:get(battle.ValueType.normal))
			end
		end

		if skillDamageBB.isLastSeg then
			if args.penetrateObj and args.penetrateObj:hp() <= 0 then
				args.penetrateObj:setDead(self.owner)
			end

			target:cleanEventByKey(battle.ExRecordEvent.penetrate)

			args.penetrateObj = nil
		end
	end
end

function SkillModel:onHealToDamageTarget(target, processCfg, final, effectCfg, segId, objIndex)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
		local damageFinal = self:getTargetsFinalResult(target.id, battle.SkillSegType.damage)

		if segId == 1 then
			local toDamageData = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", final.value)
			local allDamage = 0

			for _, v in ipairs(toDamageData) do
				allDamage = allDamage + v.damage
			end

			damageFinal.value = allDamage
			battleEasy.IDCounter = battleEasy.IDCounter + 1
			damageFinal.args = {
				skillId = self.cfg.id,
				damageId = battleEasy.IDCounter
			}
			damageFinal.healToDamageData = toDamageData
		end

		local segPer = effectCfg.hpSeg[segId]

		if segId == 1 then
			damageFinal.attackedDamage[objIndex] = 0
		end

		for k, data in ipairs(damageFinal.healToDamageData) do
			local damage = math.floor(data.damage * segPer)
			local damageArgs = table.deepcopy(damageFinal.args)
			local leftDamage = damageFinal.value - damageFinal.attackedDamage[objIndex]

			damageFinal.attackedDamage[objIndex] = damageFinal.attackedDamage[objIndex] + damage
			damageArgs.processId = processCfg.id
			damageArgs.from = battle.DamageFrom.skill
			damageArgs.segId = segId
			damageArgs.skillDamageId = damageFinal.args.damageId
			damageArgs.isLastDamageSeg = table.length(effectCfg.hpSeg) == segId and table.length(damageFinal.healToDamageData) == k
			damageArgs.isBeginDamageSeg = segId == 1 and k == 1
			damageArgs.leftDamage = leftDamage

			local newSegValue, newDamageArgs = target:beAttack(self.owner, damage, data.processId, damageArgs)

			damageFinal.real:add(newSegValue)
		end

		return false
	end

	return true
end

function SkillModel:handleBuffSputterSegId1(target, args, final)
	args.sputterData = self.buffSputteringData

	if not args.sputterData then
		return false
	end

	if not args.buffSputObjs then
		args.buffSputObjs = {}
	end

	args.buffSputObjs[target.id] = self:getBaseSpurtTargets(target)

	for _, obj in ipairs(args.buffSputObjs[target.id]) do
		local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)

		_final.value = _final.value or final.value * args.sputterData.rate
	end

	return true
end

function SkillModel:onBuffSputterTarget(target, args, final, damageArgs, skillDamageBB)
	if damageArgs.segId == 1 and not self:handleBuffSputterSegId1(target, args, final) then
		return
	end

	if not args.buffSputObjs or not args.buffSputObjs[target.id] then
		return
	end

	for _, obj in ipairs(args.buffSputObjs[target.id]) do
		local spurtDamage = math.floor(skillDamageBB.damage * args.sputterData.rate)
		local newArgs = battleEasy.deepcopy_args(damageArgs)

		newArgs.beHitNotWakeUp = true
		newArgs.beAttackCantRecoverMp = args.sputterData.beAttackCantRecoverMp

		local _damage, _damageArgs = obj:beAttack(self.owner, spurtDamage, skillDamageBB.damageProcessAfterCal, newArgs)
		local _final = self:getTargetsFinalResult(obj.id, battle.SkillSegType.damage)

		_final.real:add(_damage)

		_final.args = _damageArgs

		if _damageArgs.beAttackToDeath then
			self:addObjectToKillTab(obj)
		end

		if not self.canjumpBigSkill then
			self:addToSegDamage(_damage:get(battle.ValueType.normal))
		end
	end

	if skillDamageBB.isLastSeg then
		for _, obj in ipairs(args.buffSputObjs[target.id]) do
			if obj and obj:hp() <= 0 then
				obj:setDead(self.owner)
			end

			obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeBuffSputterHit, {
				buffCfgId = args.sputterData.cfgId
			})
		end

		args.buffSputObjs[target.id] = nil
	end
end

function SkillModel:onProtectTarget(protecter, oldDamageArgs, oldDamage, damageProcessId)
	local damageFinal = self:getTargetsFinalResult(protecter.id, battle.SkillSegType.damage)
	local segId = oldDamageArgs.segId
	local objIndex = 1

	if not damageFinal.args then
		local tempProcessArgs = {
			process = {
				segType = battle.SkillSegType.damage
			}
		}

		self:preCalcDamageProb(protecter, tempProcessArgs)
	end

	if not damageFinal.value then
		damageFinal.value = self:calcFormula("damage", self.damageFormula, protecter)
	end

	self.protectorObjs[protecter.id] = protecter

	if segId == 1 then
		damageFinal.attackedDamage[objIndex] = 0
	end

	local damage = oldDamage
	local effectCfg = self.processEventCsv[oldDamageArgs.processId]
	local segPer = effectCfg and effectCfg.damageSeg and effectCfg.damageSeg[segId]

	if segPer then
		damage = math.floor(damageFinal.value * segPer)
	end

	local skillCfg = self.cfg
	local damageArgs = {
		skillId = self.cfg.id,
		natureType = self:getSkillNatureType() or 1,
		damageType = skillCfg.skillDamageType or battle.SkillDamageType.Physical,
		skillType2 = skillCfg.skillType2,
		skillPower = skillCfg.skillPower
	}

	if damageFinal.args then
		for _, name in ipairs(preCalProbNames) do
			damageArgs[name] = damageFinal.args[name]
		end
	end

	damageFinal.attackedDamage[objIndex] = damageFinal.attackedDamage[objIndex] + damage
	damageArgs.processId = oldDamageArgs.processId
	damageArgs.from = battle.DamageFrom.skill
	damageArgs.segId = segId
	damageArgs.skillDamageId = damageFinal.args.damageId
	damageArgs.isLastDamageSeg = oldDamageArgs.isLastDamageSeg
	damageArgs.isBeginDamageSeg = oldDamageArgs.isBeginDamageSeg
	damageArgs.leftDamage = damageFinal.value - damageFinal.attackedDamage[objIndex]
	damageArgs.fromExtra = oldDamageArgs.fromExtra

	local newSegValue, newDamageArgs = protecter:beAttack(self.owner, damage, damageProcessId, damageArgs)

	damageFinal.real:add(newSegValue)
end

function SkillModel:onTarget(target, args, segId, isLastSeg, oriObj, objIndex)
	local processCfg = args.process
	local effectCfg = self.processEventCsv[processCfg.id]
	local final = self:getTargetsFinalResult(target.id, args.process.segType)
	local segValue

	args.values[target.id] = args.values[target.id] or {}

	local deferKey = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id)

	if args.process.segType == battle.SkillSegType.damage then
		local damageProcessAfterCal = self.skillCalDamageProcessId == 1 and 9999 or self.skillCalDamageProcessId + 1
		local segPer = effectCfg.damageSeg[segId]
		local damage = math.floor(final.value * segPer)
		local damageArgs = table.deepcopy(final.args, true)

		if segId == 1 then
			final.attackedDamage[objIndex] = 0
		end

		local leftDamage = final.value - final.attackedDamage[objIndex]

		final.attackedDamage[objIndex] = final.attackedDamage[objIndex] + damage
		damageArgs.processId = processCfg.id
		damageArgs.from = battle.DamageFrom.skill
		damageArgs.segId = segId
		damageArgs.skillDamageId = final.args.damageId
		damageArgs.isLastDamageSeg = table.length(effectCfg.damageSeg) == segId
		damageArgs.isBeginDamageSeg = segId == 1
		damageArgs.leftDamage = leftDamage
		damageArgs.beAttackCantRecoverMp = self.blockEffect.beAttackRecoverMp or damageArgs.beAttackCantRecoverMp
		damageArgs.skillBlockTriggerPoint = self.blockTriggerPoint
		damageArgs.skillMark = self.owner.id .. self.id .. self.owner:getEventByKey(self.skillType2)
		damage = self.protectorObjs[target.id] and 0 or damage

		local newDamageArgs

		segValue, newDamageArgs = target:beAttack(self.owner, damage, damageProcessAfterCal, damageArgs)

		final.real:add(segValue)

		oriObj = oriObj or target

		local skillDamageBB = {
			isLastSeg = isLastSeg,
			damage = damage,
			damageProcessAfterCal = damageProcessAfterCal,
			segPer = segPer
		}

		self:onSputterTarget(oriObj, args, final, damageArgs, skillDamageBB)
		self:onPenetrateTarget(oriObj, args, final, damageArgs, skillDamageBB)
		self:onBuffSputterTarget(oriObj, args, final, damageArgs, skillDamageBB)

		if newDamageArgs.extraShowValueF then
			segValue:add(newDamageArgs.extraShowValueF)
		end

		if newDamageArgs.beAttackToDeath then
			self:addObjectToKillTab(target)
		end

		if isLastSeg then
			self.scene.play:checkBulletTimeShow()
		end
	end

	if args.process.segType == battle.SkillSegType.resumeHp and self:onHealToDamageTarget(target, processCfg, final, effectCfg, segId, objIndex) then
		local hpArgs = table.deepcopy(final.args)

		hpArgs.from = battle.ResumeHpFrom.skill
		hpArgs.ignoreBeHealAddRate = false
		hpArgs.tryBoost = true

		local segPer = effectCfg.hpSeg[segId]

		segValue = target:resumeHp(self.owner, math.floor(final.value * segPer), hpArgs)

		final.real:add(segValue)
	end

	args.values[target.id][segId] = args.values[target.id][segId] or {}
	args.values[target.id][segId].value = segValue

	if not args.values[target.id][segId].deferList then
		args.values[target.id][segId].deferList = gRootViewProxy:proxy():popDeferList(deferKey)
	else
		local list = gRootViewProxy:proxy():popDeferList(deferKey)

		for _, v in ipairs(list) do
			args.values[target.id][segId].deferList:push_back(v)
		end
	end
end

function SkillModel:addObjectToKillTab(obj)
	if not itertools.include(self.killedTargetsTb, obj) then
		table.insert(self.killedTargetsTb, obj)
	end
end

function SkillModel:getTargetsFinalResult(targetId, segType)
	local final = self.targetsFinalResult[targetId]

	if not final then
		final = {
			[battle.SkillSegType.damage] = {
				real = battleEasy.valueTypeTable(),
				attackedDamage = {}
			},
			[battle.SkillSegType.resumeHp] = {
				real = battleEasy.valueTypeTable(),
				attackedDamage = {}
			}
		}

		local mt

		mt = {
			skillMiss = false,
			__index = function(_, k)
				if final.damage.args then
					return final.damage.args[k]
				elseif final.resumeHp.args then
					return final.resumeHp.args[k]
				end

				return mt[k]
			end
		}
		final.args = setmetatable({}, mt)
		self.targetsFinalResult[targetId] = final
	end

	if segType then
		return final[segType]
	end

	return final
end

function SkillModel:pairsTargetsFinalResult(segType)
	return function(_, k)
		local v

		k, v = next(self.targetsFinalResult, k)

		return k, v and v[segType]
	end, self.targetsFinalResult, nil
end

function SkillModel:getTargetDamage(target)
	if target.ignoreDamageInBattleRound then
		return 0
	end

	return table.get(self.targetsFinalResult, target.id, battle.SkillSegType.damage, "value") or 0
end

function SkillModel:chcekTargetInFinalResult(id)
	return battleEasy.ifElse(self.targetsFinalResult[id], true, false)
end

function SkillModel:calcFormula(key, formula, target)
	local v = table.get(self.targetsFormulaResult, target.id, key)

	if v then
		return v
	end

	self.protectedEnv:resetEnv()

	local env = battleCsv.fillFuncEnv(self.protectedEnv, {
		target = target
	})
	local ret = battleCsv.doFormula(formula, env)

	table.set(self.targetsFormulaResult, target.id, key, ret)

	return ret
end

function SkillModel:beforeAddBuffToTargets(cfgId, noMissTargetsArray, extraTarget, buffValue)
	return
end

function SkillModel:processAddBuff(processCfg, targets, extraTarget, timePoint)
	if itertools.isempty(processCfg.buffList) then
		return
	end

	local buffTb = {}
	local noMissTargetsArray = {}

	for _, obj in ipairs(targets) do
		if obj then
			local skillMiss = table.get(self.targetsFinalResult, obj.id, "args", "skillMiss")

			if not skillMiss then
				table.insert(noMissTargetsArray, obj)
			end
		end
	end

	for i, id in ipairs(processCfg.buffList) do
		local buffCfg = csv.buff[id]
		if not buffCfg then
			errorInWindows("id(%s) not in csv.buff", id)
		elseif buffCfg.skillTimePos == timePoint then
			self:beforeAddBuffToTargets(id, noMissTargetsArray, extraTarget, processCfg.buffValue1[i])

			for _, obj in ipairs(noMissTargetsArray) do
				local deferKey

				if timePoint == battle.SkillAddBuffType.InPlay then
					deferKey = gRootViewProxy:proxy():pushDeferList(self.id, processCfg.id, "buffDelay")
				end

				self:addProcessBuffBefore(id, obj, self.owner, buffCfg)

				local newArgs = BuffArgs.fromSkill(self, extraTarget, obj, processCfg, buffCfg, i)
				local newBuff = self:addProcessBuff(id, obj, self.owner, buffCfg, newArgs)

				log.battle.skill.processAddBuff({
					skill = self,
					caster = self.owner,
					holder = obj,
					cfgId = id,
					prob = buffCfg.prob,
					processCfg = processCfg,
					timePoint = timePoint
				})

				if newBuff then
					obj:onPassive(PassiveSkillTypes.additional, obj, {
						buffCfgId = newBuff.cfgId
					})
				end

				if timePoint == battle.SkillAddBuffType.InPlay then
					buffTb[obj.id] = gRootViewProxy:proxy():popDeferList(deferKey)
				end
			end
		end
	end

	for _, data in self.owner:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.applyCommandeer) do
		if data.howToDo == 5 then
			data.func(timePoint)
		end
	end

	if itertools.isempty(buffTb) then
		return
	end

	return buffTb
end

function SkillModel:addProcessBuffBefore(cfgId, holder, caster, buffCfg)
	return
end

function SkillModel:addProcessBuff(cfgId, holder, caster, buffCfg, args)
	local isGlobal = self.scene:getGroupBuffId(buffCfg.easyEffectFunc)

	return battleEasy.addBuffToFunc(isGlobal, cfgId, holder, caster, args)
end

function SkillModel:getLeftCDRound()
	if self.cdRound == 0 then
		return 0
	end

	local curRound = self.owner:getBattleRound(2)

	return self.cdRound - (curRound - self.spellRound - 1)
end

function SkillModel:getCurChargingRound()
	return _min(self.owner:getBattleRound(2) - self.chargeRound, 3)
end

function SkillModel:saveAllTargets()
	local noMissTargets = {}

	for __, tarMap in maptools.order_pairs(self.allProcessesTargets) do
		for _, obj in ipairs(tarMap.targets) do
			if obj then
				self.allTargets[obj.id] = obj

				local miss = table.get(self.targetsFinalResult, obj.id, "args", "skillMiss")

				if not miss then
					noMissTargets[obj.id] = obj
				end
			end
		end
	end

	return self:targetsMap2Array(noMissTargets)
end

function SkillModel:saveAllDamageTargets()
	local allProcessesDamageTargets = {}

	for k, v in pairs(self.allProcessesTargets) do
		local _effectEventID = csv.skill_process[k]
		_effectEventID = _effectEventID.effectEventID
		local cfg = csv.effect_event[_effectEventID]

		if cfg and cfg.damageSeg then
			allProcessesDamageTargets[k] = v.targets
		end
	end

	for __, targets in maptools.order_pairs(allProcessesDamageTargets) do
		for _, obj in ipairs(targets) do
			if obj then
				self.allDamageTargets[obj.id] = obj
			end
		end
	end

	self:dealSneer(true, function(sneerObj)
		for k, v in pairs(self.allDamageTargets) do
			if sneerObj ~= v then
				self.allDamageTargets[k] = nil
			end
		end
	end)
end

function SkillModel:targetsMap2Array(mapTargets)
	local ret = {}

	for _, obj in maptools.order_pairs(mapTargets, "id") do
		table.insert(ret, obj)
	end

	return ret
end

function SkillModel:interrupt(type, buffId)
	if type == battle.SkillInterruptType.charge then
		self:chargingBeInterrupted()
	end

	self.interruptBuffId = buffId
end

function SkillModel:interruptBuffId()
	return self.interruptBuffId
end

function SkillModel:chargingBeInterrupted()
	if self.chargeRound then
		battleEasy.deferNotifyCantJump(self.owner.view, "playCharge", self.chargeArgs.action, true)
	end

	self.chargeRound = nil
	self.spellRound = self.lastSpellRound

	self:startDeductMp(true)
	self.owner:triggerBuffOnPoint(battle.BuffTriggerPoint.onChargeBeInterrupted)
end

function SkillModel:addAttr(attrName, value, reverse)
	if attrName == "skillNatureType" then
		self[attrName] = reverse and self.cfg[attrName] or value
	else
		self[attrName] = self[attrName] + (reverse and -value or value)
	end
end

function SkillModel:pushDefreListToSkillEnd(event, t)
	if self.disposeDatasOnSkillEnd[event] and t then
		battleEasy.mergeDeferList(self.disposeDatasOnSkillEnd[event], t)
	else
		self.disposeDatasOnSkillEnd[event] = t
	end
end

function SkillModel:pushDefreListAfterComeBack(event, t)
	if self.disposeDatasAfterComeBack[event] and t then
		battleEasy.mergeDeferList(self.disposeDatasAfterComeBack[event], t)
	else
		self.disposeDatasAfterComeBack[event] = t
	end
end

function SkillModel:isSameType(checkType)
	return battleEasy.isSameSkillType(self.skillFormulaType, checkType)
end

function SkillModel:isMainNumShowType()
	if self.skillFormulaType == battle.SkillFormulaType.fix then
		local totalDmg = self:getTargetsFinalValue()

		return totalDmg ~= 0 and battle.SkillFormulaType.damage or battle.SkillFormulaType.resumeHp
	end

	return self.skillFormulaType
end

function SkillModel:isNormalSkillType()
	return self.skillType == battle.SkillType.NormalSkill
end

function SkillModel:replaceSkillTargets(targets, processCfg, ignoreReplaceData)
	if not self:isSameType(battle.SkillFormulaType.damage) then
		return targets, targets, targets
	end

	local uniqueTargetId = {}
	local newTargets, oriTargets, buffTargets = {}, {}, {}
	local deadCantReplace = processCfg and processCfg.extraArgs and processCfg.extraArgs.deadCantReplace
	local forceProtectData = {
		{},
		{}
	}

	for _, obj in self.scene:ipairsOnSiteHeros() do
		for _, data in obj:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.replaceTarget, self.owner) do
			table.insert(forceProtectData[obj.force], data)
		end
	end

	table.sort(forceProtectData[1], function(a, b)
		if a.priority == b.priority then
			return a.id < b.id
		else
			return a.priority > b.priority
		end
	end)
	table.sort(forceProtectData[2], function(a, b)
		if a.priority == b.priority then
			return a.id < b.id
		else
			return a.priority > b.priority
		end
	end)

	for _, target in ipairs(targets) do
		local toObj, aoeTwice
		local replaceTargetTo = 0

		if target.force ~= self.owner.force then
			for _, data in ipairs(forceProtectData[target.force]) do
				if toObj ~= nil then
					break
				end

				if data.toReplaceObj.id ~= target.id or data.toReplaceObj.id == target.id and data.isSelfReplaceSelf == true then
					if data.isReplaceOther then
						toObj, aoeTwice, replaceTargetTo = data.holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.replaceTarget, "holderProtectOther", ignoreReplaceData, self.owner, data, target)
					elseif data.holder.id == target.id then
						toObj, aoeTwice, replaceTargetTo = data.holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.replaceTarget, "casterProtectHolder", ignoreReplaceData, self.owner, data)
					end
				end
			end

			if toObj and toObj:isAlreadyDead() and deadCantReplace and toObj.id ~= target.id then
				toObj = nil
			end
		end

		if toObj then
			if toObj.id ~= target.id and target.id == self.owner.curTargetId then
				self.nowTargetID = toObj.id
			end

			table.insert(newTargets, toObj)

			if replaceTargetTo == 1 then
				table.insert(buffTargets, target)
			else
				table.insert(buffTargets, toObj)
			end

			table.insert(oriTargets, target)

			if aoeTwice == 0 then
				uniqueTargetId[toObj.id] = uniqueTargetId[toObj.id] or 0
			elseif aoeTwice == 2 then
				uniqueTargetId[toObj.id] = uniqueTargetId[toObj.id] or table.length(newTargets)
			end
		elseif not self.protectorObjs[target.id] then
			table.insert(newTargets, target)
			table.insert(buffTargets, target)
			table.insert(oriTargets, false)
		end
	end

	for i = table.length(newTargets), 1, -1 do
		local tar = newTargets[i]

		if uniqueTargetId[tar.id] ~= nil and (uniqueTargetId[tar.id] ~= 0 and uniqueTargetId[tar.id] ~= i or uniqueTargetId[tar.id] == 0 and not oriTargets[i]) then
			table.remove(newTargets, i)
			table.remove(buffTargets, i)
			table.remove(oriTargets, i)
		end
	end

	return newTargets, oriTargets, buffTargets
end

function SkillModel:filterProtectorView(target, protectorIDList)
	if self:isSameType(battle.SkillFormulaType.damage) then
		local effectData = target:getEventByKey(battle.ExRecordEvent.replaceTarget)
		local obj

		if effectData and effectData.cantMove == false then
			obj = effectData.toReplaceObj
		end

		local protectData = target:getEventByKey(battle.ExRecordEvent.protectTarget)

		if obj == nil and protectData and not protectData.isProtector then
			obj = protectData.obj
		end

		if not obj then
			return
		end

		if not itertools.include(protectorIDList, obj.view) then
			table.insert(protectorIDList, obj.view)
		end

		return {
			view = obj.view,
			targetView = target.view
		}
	end
end

function SkillModel:getSkillNatureType()
	local buffData = self.owner:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)
	local type = buffData.skillNatures and buffData.skillNatures[self.id]

	if type then
		return type
	end

	local skillCfg = self.cfg

	type = skillCfg and skillCfg.skillNatureType

	return type
end

function SkillModel:getSkillSceneTag()
	local obj = self.scene.play.curHero

	return {
		isPossessAttack = self.owner:isPossessAttack(self.skillType),
		isPlaySkill = obj and obj.curSkill == self,
		isBigSkill = self.skillType2 == battle.MainSkillType.BigSkill
	}
end

function SkillModel:setCsvObject(obj)
	self.csvObject = obj
end

function SkillModel:getCsvObject()
	return self.csvObject
end

function SkillModel:toHumanString()
	return string.format("SkillModel: %s", self.id)
end

function SkillModel:getBuffDamageAfterSkill(target)
	local function checkTriggerPoint(triggerBehaviors)
		if not triggerBehaviors then
			return true
		end

		for _, v in ipairs(triggerBehaviors) do
			if v.triggerPoint and v.triggerPoint == 1 then
				return true
			end
		end

		return false
	end

	local skillMiss = table.get(self.targetsFinalResult, target.id, "args", "skillMiss")

	if skillMiss then
		return 0
	end

	local damage = 0

	for i, processCfg in self:ipairsProcess() do
		for i, id in ipairs(processCfg.buffList) do
			local buffCfg = csv.buff[id]
			if buffCfg and buffCfg.easyEffectFunc == "buffDamage" and checkTriggerPoint(buffCfg.triggerBehaviors) then
				self.protectedEnv:resetEnv()

				local env = battleCsv.fillFuncEnv(self.protectedEnv, {
					target = target
				})
				local value = battleCsv.doFormula(processCfg.buffValue1[i], env)

				if type(value) == "number" then
					damage = damage + value
				end
			end
		end
	end

	return damage
end

function SkillModel:addToSegDamage(damage)
	if not self:isNormalSkillType() then
		return
	end

	battleEasy.deferNotifyCantJump(nil, "showNumber", {
		delta = math.floor(damage),
		skillId = self.id,
		typ = battle.SkillSegType.damage
	})
end

function SkillModel:saveProcessTargets(id, targets, buffTargets)
	self.allProcessesTargets[id] = {
		targets = targets,
		buffTargets = buffTargets or targets
	}
end

function SkillModel:getBigSkillHideHero(isCantMoveBigSkill)
	local hideHero = {}

	for _, obj in self.scene:ipairsOnSiteHeros() do
		if obj.id ~= self.owner.id and (isCantMoveBigSkill or not self.allTargets[obj.id] and not self.protectorObjs[obj.id]) then
			table.insert(hideHero, tostring(obj))
		end
	end

	return hideHero
end
