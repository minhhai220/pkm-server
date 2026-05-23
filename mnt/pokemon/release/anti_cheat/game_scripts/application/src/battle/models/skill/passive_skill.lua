-- chunkname: @src.battle.models.skill.passive_skill

local _isSFPassive = string.char(95, 105, 115, 83, 70, 80, 97, 115, 115, 105, 118, 101, 32)
local PassiveSkillTypes = battle.PassiveSkillTypes
local TriggerTypeMap
local PassiveSkillModel = class("PassiveSkillModel", battleSkill.SkillModel)

battleSkill.PassiveSkillModel = PassiveSkillModel

local triggerWithOutDeathCheck = {
	[PassiveSkillTypes.beDeathAttack] = true,
	[PassiveSkillTypes.realDead] = true,
	[PassiveSkillTypes.create] = true
}

function PassiveSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

	self.type = cfg.passiveTriggerType
	self.startRound = cfg.passiveStartRound
	self.skillMuteTimeCheck = nil
	self.isWeather = false
	self.waveTriggered = false

	-- if cfg.id % 10 == 1 and math.floor(cfg.id / 10000000) == 9 then
	-- 	scene[_isSFPassive] = true
	-- end
end

function PassiveSkillModel:canSpell()
	if self.owner:isDeath() and not triggerWithOutDeathCheck[self.type] then
		return false
	end

	if self.costMp1 and self.costMp1 > 0 then
		return self.owner:mp1() >= self.costMp1
	end

	if not self.cfg.alwaysEffective and self.owner:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
		skillType2 = self.skillType2
	}) then
		return false
	end

	self:updateSkillMuteTimeCheck()

	if self.skillMuteTimeCheck == false then
		return false
	end

	return self:getLeftCDRound() < 1
end

function PassiveSkillModel:updateSkillMuteTimeCheck()
	if self.skillMuteTimeCheck ~= nil then
		return
	end

	if self.cfg.allEffectTime and table.length(self.cfg.allEffectTime) > 0 then
		local eventIds = self.scene:getEventByKey(battle.ExRecordEvent.skillEffectLimit, self.id, self.owner.force)
		local time = self.cfg.allEffectTime[1]
		local data

		for i = 2, table.length(self.cfg.allEffectTime) do
			data = self.cfg.allEffectTime[i]

			if self.scene.gateType == data[1] then
				time = data[2]

				break
			end
		end

		if not eventIds or time > table.length(eventIds) then
			if not itertools.include(eventIds, self.owner.id) then
				self.scene:addExRecord(battle.ExRecordEvent.skillEffectLimit, self.owner.id, self.id, self.owner.force)
			end
		else
			self.skillMuteTimeCheck = false

			return
		end
	end

	self.skillMuteTimeCheck = true
end

function PassiveSkillModel:isAttackSkill()
	return false
end

function PassiveSkillModel:_spellTo(target, args)
	if self:trigger(target, args) then
		battleSkill.SkillModel._spellTo(self, target)

		self.waveTriggered = true
	end
end

function PassiveSkillModel:trigger(target, args)
	local f = TriggerTypeMap[self.type]

	args = args or {}
	args.passiveTriggerArg = self.cfg.passiveTriggerArg

	return f(self, target, args)
end

function PassiveSkillModel:onTrigger(typ, target, args)
	if self.type > 0 and typ ~= self.type then
		return
	end

	if not self.owner:effectPowerControl(battle.EffectPowerType.passiveSkill, typ) then
		return
	end

	if self:canSpell() then
		self:spellTo(target, args)
	end
end

function PassiveSkillModel:processBefore(skillBB)
	skillBB.isDeath = self.owner:isDeath()

	battleSkill.SkillModel.processBefore(self, skillBB)
end

function PassiveSkillModel:onSpellView(skillBB)
	if skillBB.isDeath then
		return
	end

	local target, posIdx = skillBB.target, skillBB.lastPosIdx
	local disposeDatasOnSkillStart = self.disposeDatasOnSkillStart
	local disposeDatasOnSkillEnd = self.disposeDatasOnSkillEnd
	local disposeDatasAfterComeBack = self.disposeDatasAfterComeBack
	local getExtraRoundMode = self.scene:getExtraRoundMode()

	battleEasy.deferCallback(function()
		local view = self.owner.view
		local skillCfg = self.cfg
		local moveTime = 0
		local actionTime = skillCfg.actionTime or 0
		local noQueue = true

		gRootViewProxy:proxy():onEventEffect(self.owner, "callback", {
			func = function()
				view:proxy():onMoveToTarget(posIdx, {
					moveTime = skillCfg.moveTime,
					timeScale = getExtraRoundMode and 0.51,
					cameraNear = skillCfg.cameraNear,
					cameraNear_posC = skillCfg.cameraNear_posC,
					posC = skillCfg.posC
				}, noQueue)
				view:proxy():onSkillBefore(disposeDatasOnSkillStart, self.skillType, noQueue, skillBB.sceneTag)
				view:proxy():onPlayAction(skillCfg.spineAction, actionTime, noQueue)
			end,
			delay = moveTime
		})
		gRootViewProxy:proxy():onEventEffect(self.owner, "callback", {
			func = function()
				for i, processCfg in self:ipairsProcess() do
					view:proxy():onProcessDel(processCfg.id)
				end

				view:proxy():onObjSkillEnd(disposeDatasOnSkillEnd, self.skillType, noQueue)
				view:proxy():onComeBack(posIdx, false, {
					moveTime = skillCfg.moveTime,
					timeScale = getExtraRoundMode and 0.51,
					flashBack = skillCfg.flashBack
				})
				view:proxy():onAfterComeBack(disposeDatasAfterComeBack, noQueue)
				view:proxy():onObjSkillOver(noQueue)
			end,
			delay = moveTime + actionTime
		})
	end)
end

function PassiveSkillModel:resetOnNewWave()
	battleSkill.SkillModel.resetOnNewWave(self)

	self.waveTriggered = false
end

function PassiveSkillModel:waveTriggeredCheck()
	if self.isWeather and self.waveTriggered then
		return true
	end

	return false
end

local function defaultFuncTrue(skill, target, args)
	return true
end

local function defaultFuncNil(skill, target, args)
	return
end

TriggerTypeMap = {
	[PassiveSkillTypes.create] = defaultFuncTrue,
	[PassiveSkillTypes.round] = function(skill, target, args)
		return skill.scene.play.curRound == args.passiveTriggerArg
	end,
	[PassiveSkillTypes.cycleRound] = function(skill, target, args)
		local round = skill.scene.play.curRound

		return round > 0 and (round - 1) % (args.passiveTriggerArg + 1) == 0
	end,
	[PassiveSkillTypes.realDead] = defaultFuncTrue,
	[PassiveSkillTypes.fakeDead] = defaultFuncTrue,
	[PassiveSkillTypes.beDeathAttack] = defaultFuncTrue,
	[PassiveSkillTypes.beAttack] = function(skill, target, args)
		return not args.miss
	end,
	[PassiveSkillTypes.enter] = defaultFuncTrue,
	[PassiveSkillTypes.attack] = defaultFuncTrue,
	[PassiveSkillTypes.roundEnd] = function(skill, target, args)
		if not args.passiveTriggerArg then
			return
		end

		return args.roundFlag == args.passiveTriggerArg
	end,
	[PassiveSkillTypes.kill] = defaultFuncTrue,
	[PassiveSkillTypes.beSpecialNatureDamage] = function(skill, target, args)
		return args.natureType == args.passiveTriggerArg
	end,
	[PassiveSkillTypes.beStrike] = function(skill, target, args)
		return args.strike
	end,
	[PassiveSkillTypes.beNatureDamage] = function(skill, target, args)
		return args.natureFlag == "strong"
	end,
	[PassiveSkillTypes.beNonNatureDamage] = function(skill, target, args)
		return args.natureFlag ~= "strong"
	end,
	[PassiveSkillTypes.beDamageIfFullHp] = function(skill, target, args)
		return args.isFullHp
	end,
	[PassiveSkillTypes.beDamage] = function(skill, target, args)
		return args.type == 0
	end,
	[PassiveSkillTypes.beSpecialDamage] = function(skill, target, args)
		return args.type ~= 0
	end,
	[PassiveSkillTypes.hpLess] = function(skill, target, args)
		return skill.owner:hp() / skill.owner:hpMax() < args.passiveTriggerArg / ConstSaltNumbers.wan
	end,
	[PassiveSkillTypes.beSpeciaSelfForce] = defaultFuncNil,
	[PassiveSkillTypes.beWeather] = defaultFuncNil,
	[PassiveSkillTypes.beSpeciaBuff] = defaultFuncNil,
	[PassiveSkillTypes.beToolsComsumed] = defaultFuncNil,
	[PassiveSkillTypes.roundStartAttack] = defaultFuncTrue,
	[PassiveSkillTypes.teamHpLess] = function(skill, target, args)
		for _, obj in args.objs:order_pairs() do
			if obj:hp() / obj:hpMax() < args.passiveTriggerArg / ConstSaltNumbers.wan then
				return true
			end
		end

		return false
	end,
	[PassiveSkillTypes.recoverHp] = function(skill, target, args)
		return args.hpFormula and args.skillType == battle.SkillType.NormalSkill
	end,
	[PassiveSkillTypes.additional] = function(skill, target, args)
		return args.passiveTriggerArg == args.buffCfgId
	end,
	[PassiveSkillTypes.roundStart] = defaultFuncTrue
}
TriggerTypeMap[PassiveSkillTypes.dynamicHpLess] = TriggerTypeMap[PassiveSkillTypes.hpLess]
TriggerTypeMap[PassiveSkillTypes.dynamicTeamHpLess] = TriggerTypeMap[PassiveSkillTypes.teamHpLess]
