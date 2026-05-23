-- chunkname: @src.battle.models.skill.immediate_skill

local BuffSkillModel = class("BuffSkillModel", battleSkill.SkillModel)

battleSkill.BuffSkillModel = BuffSkillModel

function BuffSkillModel:ctor(scene, owner, cfg, level)
	battleSkill.SkillModel.ctor(self, scene, owner, cfg, level)

	self.type = cfg.passiveTriggerType

	if assertInWindows(self.type == battle.PassiveSkillTypes.enter, string.format("BuffSkillModel type not equal to 7, is %d", self.type)) then
		self.type = nil
	end

	self.cantShowText = false
	self.buffValues = {}
	self.lastTimeTargets = {}
	self.castedAuraBuffs = {}
end

function BuffSkillModel:initSkillArgs()
	local skillArgs = self.cfg.skillArgs or {}

	self.effectOnce = battleEasy.ifElse(skillArgs[1] ~= nil, skillArgs[1], false)
	self.isFixValue = battleEasy.ifElse(skillArgs[2] ~= nil, skillArgs[2], true)
end

function BuffSkillModel:canSpell()
	return not self.owner:isDeath()
end

function BuffSkillModel:onTrigger(typ, target, args)
	if self.skillType ~= battle.SkillType.PassiveAura or typ ~= "Aura" and typ ~= self.type then
		return
	end

	if self.owner:leaveInfluenceBuff() then
		return
	end

	if self:canSpell() then
		self:spellTo(target, args)

		self.cantShowText = true
	end
end

function BuffSkillModel:isAttackSkill()
	return false
end

function BuffSkillModel:_spellTo(target, args)
	battleSkill.SkillModel._spellTo(self, target)
end

function BuffSkillModel:beforeAddBuffToTargets(cfgId, noMissTargetsArray, extraTarget, buffValue)
	local needDel = csv.buff[cfgId].delRefreshMode[1] == 1
	local needRefresh = csv.buff[cfgId].delRefreshMode[2] == 1
	local newTargets = {}

	for _, target in ipairs(noMissTargetsArray) do
		newTargets[target.id] = target
	end

	local oldTargets = self.lastTimeTargets[cfgId]

	self.lastTimeTargets[cfgId] = newTargets

	if needDel then
		self.owner:deleteSingleAuraBuff(cfgId)
	else
		if not needRefresh then
			return
		end

		if not oldTargets then
			return
		end

		for id, target in maptools.order_pairs(oldTargets, "id") do
			local buff = self:getSelfCastBuff(cfgId, target)

			if not newTargets[id] and not target:isDeath() and buff then
				local env = battleCsv.fillFuncEnv(self.protectedEnv, {
					lastMp1 = "lastMp1",
					target = target,
					extraTarget = extraTarget or self.owner:getCurTarget()
				})
				local value = battleCsv.doFormula(buffValue, env)

				buff:alterAuraBuffValue(value)
			end
		end
	end
end

function BuffSkillModel:getSelfCastBuff(cfgId, holder)
	if not self.castedAuraBuffs[cfgId] then
		return
	end

	local objAndBuffTb = self.castedAuraBuffs[cfgId]
	local data, buff
	local length = table.length(objAndBuffTb)

	for i = length, 1, -1 do
		data = objAndBuffTb[i]

		if data.holderId == holder.id then
			buff = holder:getBuffByID(data.buffId)

			if buff and not buff.isOver then
				return buff
			else
				table.remove(objAndBuffTb, i)

				return
			end
		end
	end
end

function BuffSkillModel:addProcessBuffBefore(cfgId, holder, caster, buffCfg)
	local buff = self:getSelfCastBuff(cfgId, holder)

	if buff then
		buff:clearAuraBuffValue()
	end
end

function BuffSkillModel:addProcessBuff(cfgId, holder, caster, buffCfg, args)
	if self.effectOnce then
		args.value = self.buffValues[holder.id] or args.value
	end

	args.cantShowText = self.cantShowText
	args.isFixValue = self.isFixValue

	local buff, canTakeEffect = addBuffToHero(cfgId, holder, caster, args)

	if buff then
		self.castedAuraBuffs[cfgId] = self.castedAuraBuffs[cfgId] or {}

		local data = {
			holderId = holder.id,
			buffId = buff.id
		}

		table.insert(self.castedAuraBuffs[cfgId], data)
	end

	local _buff = buff or holder:getBuff(cfgId)

	if canTakeEffect then
		if self.effectOnce and not self.buffValues[holder.id] then
			self.buffValues[holder.id] = args.value
		end

		if _buff and _buff.isAuraType then
			_buff:addCaster(self.owner)
			self.owner.auraBuffs:insert(_buff.id, _buff)
		end
	end

	local needRefresh = csv.buff[cfgId].delRefreshMode[2] == 1

	if _buff and needRefresh and not assertInWindows(_buff.alterAuraBuffValue, "not aura buff skill:%d, buff:%d", self.id, _buff.cfgId) then
		_buff:alterAuraBuffValue(args.value)
	end

	return buff
end

function BuffSkillModel:onSpellView(skillBB)
	local view = self.owner.view

	battleEasy.queueNotifyFor(view, "skillBefore", self.disposeDatasOnSkillStart, self.skillType)
	battleEasy.queueNotifyFor(view, "objSkillEnd", self.disposeDatasOnSkillEnd, self.skillType)
	battleEasy.queueNotifyFor(view, "afterComeBack", self.disposeDatasAfterComeBack)
	battleEasy.queueNotifyFor(view, "objSkillOver")
end

function BuffSkillModel:toHumanString()
	return string.format("BuffSkillModel: %s", self.id)
end
