-- chunkname: @src.battle.models.object_group

local abs = math.abs
local _max = math.max
local _min = math.min
local PassiveSkillTypes = battle.PassiveSkillTypes

globals.GroupObjectModel = class("GroupObjectModel", ObjectModel)

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	GroupObjectModel[attr] = function(self)
		return self.attrs:getFinalAttr(attr)
	end
end

local IDTotalDamage = 0
local IDCounterTag = 200
local hideSelfEffectEventArgFields = {
	sound = {
		"sound"
	},
	shaker = {
		"shaker",
		"segInterval"
	},
	music = {
		"music"
	},
	move = {
		"move"
	},
	hpSeg = {
		"hpSeg",
		"segInterval"
	},
	effect = {
		"effectType",
		"effectRes",
		"effectArgs"
	},
	zOrder = {
		"zOrder"
	},
	follow = {
		"follow"
	},
	jump = {
		"jumpFlag"
	},
	control = {
		"control"
	},
	cutting = {
		"cutting"
	}
}
local hideTargetEffectEventArgFields = {
	damageSeg = {
		"damageSeg",
		"segInterval"
	}
}

function GroupObjectModel:ctor(scene, force)
	self.scene = scene
	self.view = nil
	ObjectModel.IDCounter = ObjectModel.IDCounter + 1
	self.id = ObjectModel.IDCounter
	self.seat = battle.SpecialObjectId.teamShiled + force - 1
	self.force = force
	self.faceTo = self.force == 1 and 1 or -1
	self.attrs = ObjectAttrs.new()
	self.hpTable = {
		0,
		0,
		0
	}
	self.buffsToOther = {}
	self.buffs = self.scene:createBuffCollection()
	self.recordBuffDataTb = {}
	self.overlayCount = 1
	self.protectedEnv = battleCsv.makeProtectedEnv(self)

	battleComponents.bind(self, "Event")
	self:setListenerComparer(BuffModel.BuffCmp)
	battleQuery.objectBindBuff(scene, self, self.buffs)
end

function GroupObjectModel:init()
	self.unitID = 200000
	self.state = battle.ObjectState.none
	self.unitCfg = csvClone(csv.unit[self.unitID])
	self.cardID = self.unitCfg.cardID
	self.hpTable = {
		0,
		0,
		0
	}

	if not self.unitCfg then
		error(string.format("no unit config id = %s", self.unitID))
	end

	self.effectPower = csv.effect_power[self.unitCfg.effectPowerId]
	self.stackPos = 0
	self.totalDamage = {}
	self.targetTotalDamage = {}
	self.targetRateDamage = {}
	self.realBuffDamage = {}
	self.attackerCurSkill = {}
	self.processIdList = CVector.new()
	self.scene.deadObjsToBeDeleted[self.id] = nil
end

function GroupObjectModel:initView()
	local objViewArgs = {
		type = battle.SpriteType.Normal
	}

	self.view = gRootViewProxy:getProxy("onSceneAddObj", tostring(self), readOnlyProxy(self), objViewArgs)

	self.view:proxy():updateLifeBarState(false)
	self.view:proxy():setVisible(false)
	self.view:proxy():setVisibleEnable(false)
end

function GroupObjectModel:reloadUnit(buff)
	local isNeedInitView = self:isDeath()
	local res = self.unitCfg.unitRes
	local cfg

	if buff then
		cfg = buff.csvCfg
		res = cfg.effectResPath or res
	end

	self.unitRes = res
	self.state = battle.ObjectState.normal
	self.attackerCurSkill = {}

	if buff then
		gRootViewProxy:proxy():collectCallBack("battleTurn", function()
			if cfg and cfg.spineEffect.action then
				self.view:proxy():resetActionTab()

				for action, replaceAct in csvMapPairs(cfg.spineEffect.action) do
					self.view:proxy():onPushAction(battle.SpriteActionTable[action], replaceAct)
				end
			end
		end)

		if self.cfgId == nil or self.cfgId ~= buff.cfgId then
			self:hpMax(buff.buffValue)

			isNeedInitView = true
		else
			self:hpMax(math.max(self:hp(), 0) + buff.buffValue)
		end

		self.cfgId = buff.cfgId
		self.effectBuff = buff

		local specailValArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

		self.buffsToOther = specailValArgs.buffs or {}
		self.addBuffsForce = specailValArgs.force
		self.addBuffsNums = specailValArgs.nums
		self.caster = buff.caster

		log.battle.object.groupShieldCreate({
			object = self,
			buff = buff,
			caster = caster,
			hp = self:hp(),
			hpMax = self:hpMax()
		})
	end

	if isNeedInitView then
		if self.scene.deadObjsToBeDeleted[self.id] then
			self.scene.deadObjsToBeDeleted[self.id] = nil
		end

		gRootViewProxy:proxy():collectNotify("battleTurn", self, "PlayGroupShieldEffect", self:counterEffectArgs({
			state = battle.ObjectState.normal,
			unitRes = self.unitRes
		}))
	end
end

function GroupObjectModel:hp(show)
	if not show then
		return self.hpTable[1]
	end
end

function GroupObjectModel:addHp(v)
	local hp = self:hp() + v

	return self:setHP(hp)
end

function GroupObjectModel:setHP(val)
	local hpMax = self:hpMax()
	local _val = val and cc.clampf(val, 0, hpMax)

	if _val then
		self.hpTable[1] = _val
	end

	return self.hpTable[1]
end

function GroupObjectModel:hpMax(val)
	if val then
		self.hpTable[2] = val
		self.hpTable[1] = val
	end

	return self.hpTable[2]
end

function GroupObjectModel:isHit(target, cfg)
	return true
end

function GroupObjectModel:getBattleRound(skillTimePos)
	return self.scene.play.curRound
end

function GroupObjectModel:getBattleRoundAllWave(skillTimePos)
	return self.scene.play.totalRound
end

function GroupObjectModel:pushRecordData(objId, skillId)
	self.stackPos = self.stackPos + 1
	self.targetTotalDamage[self.stackPos] = {}
	self.totalDamage[self.stackPos] = {}
	self.realBuffDamage[self.stackPos] = {}
	self.targetRateDamage[self.stackPos] = {}
end

function GroupObjectModel:popRecordData(objId, skillId)
	self.processIdList:pop_back()

	if self.stackPos > 0 then
		self.targetTotalDamage[self.stackPos] = nil
		self.totalDamage[self.stackPos] = nil
		self.targetRateDamage[self.stackPos] = nil
		self.realBuffDamage[self.stackPos] = nil
		self.stackPos = self.stackPos - 1
	end
end

function GroupObjectModel:syncView(skill, args, isSegProcess)
	local processId = args.process.id
	local effectCfg = skill.processEventCsv[processId]

	args.ignoreEvenet = args.ignoreEvenet or {}
	args.ignoreEvenet[self.id] = hideSelfEffectEventArgFields
	args.otherTargets[self.id] = self

	if self.totalDamage[self.stackPos] and next(self.totalDamage[self.stackPos]) then
		args.viewTargets = {}

		for k, v in ipairs(args.targets) do
			table.insert(args.viewTargets, v)
		end

		args.otherTargets[self.id] = nil

		if isSegProcess then
			if args.process.segType == battle.SkillSegType.damage and self.totalDamage[self.stackPos] and self.totalDamage[self.stackPos][processId] and self.totalDamage[self.stackPos][processId] > 0 then
				args.ignoreEvenet = args.ignoreEvenet or {}

				self:switchToRealDamage(processId)

				for segId, _ in ipairs(effectCfg.segInterval) do
					local isLastSeg = segId == table.length(effectCfg.segInterval)

					self:dealGroupObjectSeg(skill, processId, args, segId, isLastSeg)

					for _, obj in ipairs(args.targets) do
						args.ignoreEvenet[obj.id] = hideTargetEffectEventArgFields
					end
				end

				table.insert(args.viewTargets, self)
			end
		else
			table.insert(args.viewTargets, self)
		end
	end

	if not self:isDeath() and self:hp() <= 0 then
		self:setDead(skill.owner)
	end
end

function GroupObjectModel:dealGroupObjectSeg(skill, processId, args, segId, isLastSeg)
	local damage = self.targetTotalDamage[self.stackPos][processId][self.id]
	local segValue = battleEasy.valueTypeTable()
	local final = skill:getTargetsFinalResult(self.id, battle.SkillSegType.damage)

	if not args.values[self.id] then
		args.values[self.id] = {}
	end

	local effectCfg = skill.processEventCsv[processId]
	local segPer = effectCfg.damageSeg[segId]
	local deferKey = gRootViewProxy:proxy():pushDeferList(skill.id, processId, "groupObjectModel")
	local damageNumInfo = {
		segId = segId,
		isLastSeg = isLastSeg
	}

	segValue:add(math.floor(segPer * damage))

	args.ignoreEvenet[self.id] = hideSelfEffectEventArgFields
	args.values[self.id][segId] = args.values[self.id][segId] or {}
	args.values[self.id][segId].value = segValue
	args.values[self.id][segId].deferList = gRootViewProxy:proxy():popDeferList(deferKey)

	final.real:add(segValue)
end

function GroupObjectModel:switchToRealDamage(processId)
	local totalDamage = self.totalDamage[self.stackPos][IDTotalDamage]
	local shieldbeAttackDamage = totalDamage - (self:hp() < 0 and math.abs(self:hp()) or 0)

	if self:hp() <= 0 then
		for objId, damage in pairs(self.targetTotalDamage[self.stackPos][processId]) do
			self.targetTotalDamage[self.stackPos][processId][objId] = damage / totalDamage * (totalDamage - shieldbeAttackDamage)
		end
	else
		self.targetTotalDamage[self.stackPos][processId] = {}
	end

	self.targetTotalDamage[self.stackPos][processId][self.id] = self.totalDamage[self.stackPos][processId] / totalDamage * shieldbeAttackDamage
end

function GroupObjectModel:beAttack(attacker, target, record)
	local damage = math.floor(record.valueF)
	local damageArgs = record.args

	log.battle.object.groupShieldBeAttack({
		attacker = attacker,
		object = self,
		damage = damage,
		hp = self:hp(),
		finalHp = self:hp() - damage
	})

	if damage > 0 and not self:isDeath() and not damageArgs.ignoreGroupShiled then
		attacker.totalDamage[damageArgs.from]:add(damage, battle.ValueType.normal)

		if self:hp() - damage >= 0 then
			attacker.totalDamage[damageArgs.from]:add(damage, battle.ValueType.valid)
		else
			attacker.totalDamage[damageArgs.from]:add(self:hp(), battle.ValueType.valid)
			attacker.totalDamage[damageArgs.from]:add(damage - self:hp(), battle.ValueType.overFlow)
		end

		local realDamage = damage <= self:hp() and 0 or damage - self:hp()

		self:addHp(-damage)

		if damageArgs.processId then
			if damageArgs.processId ~= self.processIdList:back() then
				self:pushRecordData()
				self.processIdList:push_back(damageArgs.processId)
			end

			self:saveTargetDamage(target.id, damage, damageArgs.processId)
			self:saveProcessDamage(damage, damageArgs.processId)

			if damageArgs.from == battle.DamageFrom.buff then
				self:saveRealBuffProcessDamage(realDamage, damageArgs.processId)
			end
		end

		battleEasy.deferNotifyCantJump(self.view, "showHeadNumber", {
			typ = 0,
			num = damage,
			args = damageArgs
		})

		if damageArgs.from == battle.DamageFrom.skill then
			return damage
		elseif damageArgs.processId then
			if damageArgs.isProcessState.isEnd then
				if self:hp() <= 0 then
					self:setDead(attacker)
				end

				self:popRecordData()
			end

			return damage
		elseif self:hp() + damage > 0 then
			if self:hp() <= 0 then
				self:setDead(attacker)

				return damage + self:hp()
			else
				battleEasy.queueNotifyFor(self.view, "eventEffect", "callback", {
					func = function()
						self.view:proxy():beHit(0, 600)
						self.view:proxy():addActionCompleteListener(function()
							self.view:proxy():onPlayState(battle.SpriteActionTable.standby)
						end)
					end
				})

				return damage
			end
		end
	end
end

function GroupObjectModel:saveTargetDamage(targetId, damage, processId)
	local skillTargetDamages = self.targetTotalDamage[self.stackPos][processId] or {}

	skillTargetDamages[targetId] = skillTargetDamages[targetId] or 0
	skillTargetDamages[targetId] = skillTargetDamages[targetId] + damage
	self.targetTotalDamage[self.stackPos][processId] = skillTargetDamages
	self.targetTotalDamage[self.stackPos][IDTotalDamage] = self.targetTotalDamage[self.stackPos][IDTotalDamage] or {}
	self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] = self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] or 0
	self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] = self.targetTotalDamage[self.stackPos][IDTotalDamage][targetId] + damage
end

function GroupObjectModel:saveProcessDamage(damage, processId)
	local _totalDamage = self.totalDamage[self.stackPos][processId]

	_totalDamage = _totalDamage or 0
	_totalDamage = _totalDamage + damage
	self.totalDamage[self.stackPos][processId] = _totalDamage
	self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] or 0
	self.totalDamage[self.stackPos][IDTotalDamage] = self.totalDamage[self.stackPos][IDTotalDamage] + damage
end

function GroupObjectModel:saveRealBuffProcessDamage(realDamage, processId)
	local tempRealDamage = self.realBuffDamage[self.stackPos][processId]

	tempRealDamage = tempRealDamage or 0
	tempRealDamage = tempRealDamage + realDamage
	self.realBuffDamage[self.stackPos][processId] = tempRealDamage
end

function GroupObjectModel:setDead(attacker)
	if self:isDeath() then
		return
	end

	self.state = battle.ObjectState.realDead
	self.attackMeDeadObj = attacker

	log.battle.object.groupShieldDead({
		attacker = attacker,
		object = self
	})
	self.caster:triggerBuffOnPoint(battle.BuffTriggerPoint.onFullShieldBreak, {
		self = battleCsv.CsvObject.newWithCache(self),
		buff = battleCsv.CsvBuff.newWithCache(self.effectBuff),
		cfgId = self.cfgId,
		attacker = battleCsv.CsvObject.newWithCache(attacker),
		caster = battleCsv.CsvObject.newWithCache(self.caster)
	})
	self.scene:addObjToBeDeleted(self)
	self:dispatchBuffToHeros()
end

function GroupObjectModel:dispatchBuffToHeros()
	local args = {
		buffValue1 = 0,
		prob = 1,
		lifeRound = 1,
		value = {
			self.force,
			self.attackMeDeadObj and self.attackMeDeadObj.seat or 0
		}
	}
	local realDead = gRootViewProxy:proxy():pushDeferList(self.id, "realDead")

	for _, v in ipairs(self.buffsToOther) do
		local count = 0

		for _, obj in self.scene:ipairsHeros() do
			if obj.force == self.force and self.addBuffsForce ~= 2 or obj.force ~= self.force and self.addBuffsForce ~= 1 then
				args.cfgId = v

				local newArgs = BuffArgs.fromSceneBuff(args)
				local buff = addBuffToHero(v, obj, self.caster, newArgs)

				if buff then
					count = count + 1
				end
			end

			if count == self.addBuffsNums then
				break
			end
		end
	end

	gRootViewProxy:proxy():collectDeferList("battleTurn", self, gRootViewProxy:proxy():popDeferList(realDead))
end

function GroupObjectModel:isDeath()
	return self.state == battle.ObjectState.realDead or self.state == battle.ObjectState.none
end

function GroupObjectModel:isInStealth(ignoreParam)
	return false
end

function GroupObjectModel:isAttackableStealth()
	return false
end

function GroupObjectModel:getShieldHp()
	if self:isDeath() then
		return 0
	end

	if self:hp() <= 0 then
		return 0
	end

	return self:hp()
end

function GroupObjectModel:toHumanString()
	return string.format("GroupObjectModel: %s(%s)", self.id, self.seat)
end

local IDCounter = 0

function GroupObjectModel:counterEffectArgs(args)
	args.aniCounter = IDCounter
	IDCounter = IDCounter + 1

	return args
end
