globals.ObjectAidModel = class("ObjectAidModel", ObjectModel)

function ObjectAidModel:init(data)
	ObjectModel.init(self, data)

	self.aidCfg = csv.aid.aid_skill[self.cardCfg.aidID]

	for i, cfgId in ipairs(self.aidCfg.buffs) do
		local args = {
			buffValue1 = 0,
			prob = 1,
			lifeRound = 99,
			value = 0,
			cfgId = cfgId
		}

		addBuffToHero(cfgId, self, self, BuffArgs.fromSceneBuff(args))
	end
end

function ObjectAidModel:addObjViewToScene()
	local args = {
		type = battle.SpriteType.Aid
	}

	self.view = gRootViewProxy:getProxy("onSceneAddObj", tostring(self), readOnlyProxy(self, {
		hp = function()
			return self:hp(true)
		end,
		mp1 = function()
			return self:mp1(true)
		end,
		setHP = function(_, v)
			return self:setHP(nil, v)
		end,
		setMP1 = function(_, v)
			return self:setMP1(nil, v)
		end
	}), args)
end

function ObjectAidModel:onInitSkills(skillLevels, additionalPassive)
	self.skills = {}
	self.passiveSkills = {}
	self.tagSkills = {}

	local aidCfg = csv.aid.aid_skill[self.cardCfg.aidID]
	local checkAidSkillID, aidLevelSkillID

	checkAidSkillID = aidCfg.skillID

	if aidCfg.skin2SkillID[self.unitID] then
		aidLevelSkillID = aidCfg.skin2SkillID[self.unitID]
	elseif aidCfg.devSkillID[self.cardCfg.develop] then
		aidLevelSkillID = aidCfg.devSkillID[self.cardCfg.develop]
	else
		aidLevelSkillID = checkAidSkillID
	end

	local aidStageSkillID = battle.Const.AidStageSkillID
	local aidAwakeSkillID = battle.Const.AidAwakeSkillID

	skillLevels = maptools.extend({
		skillLevels,
		additionalPassive
	})
	self.tagSkills[aidStageSkillID] = newSkillModel(self.scene, self, aidStageSkillID, skillLevels[aidStageSkillID] or 1)

	if skillLevels[aidAwakeSkillID] then
		self.tagSkills[aidAwakeSkillID] = newSkillModel(self.scene, self, aidAwakeSkillID, skillLevels[aidAwakeSkillID])
	end

	if checkAidSkillID and skillLevels[checkAidSkillID] then
		self.skills[aidLevelSkillID] = newSkillModel(self.scene, self, aidLevelSkillID, skillLevels[aidLevelSkillID])
		self.aidSkill = self.skills[aidLevelSkillID]
	end

	self:updateSkillsOrder()

	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end
end

function ObjectAidModel:onAidAttack(triggerType, skill)
	if triggerType == battle.aidTriggerType.SpellBigSkill then
		local owner = skill.owner

		if skill.skillType2 ~= battle.MainSkillType.BigSkill then
			return
		end

		if self.force ~= owner.force or self.scene:getExtraRoundMode() then
			return
		end
	end

	local spellSkill = self.aidSkill
	local ret, reason = spellSkill:preCanSpell(triggerType)

	if not ret then
		return
	end

	local data = ExtraAttackArgs.fromAid(spellSkill.id)

	self:addExtraBattleData(data)
	self.scene:addObjToExtraRound(self)
	self:addExRecord(battle.ExRecordEvent.roundAttackTime, 1)

	return true
end

function ObjectAidModel:isLogicStateExit(index, env)
	if index == battle.ObjectLogicState.cantBeSelect or index == battle.ObjectLogicState.cantBeAttack then
		return true
	end

	return ObjectModel.isLogicStateExit(self, index, env)
end

function ObjectAidModel:cantBeAddBuffCheck(env)
	if env.fromObj and env.fromObj.id == self.id then
		return false
	end

	return true
end

function ObjectAidModel:cantBeAttack()
	return true
end
