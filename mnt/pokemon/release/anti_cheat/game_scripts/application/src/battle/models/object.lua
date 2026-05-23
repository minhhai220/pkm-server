-- chunkname: @src.battle.models.object

local abs = math.abs
local _max = math.max
local _min = math.min
local _floor = math.floor
local _ceil = math.ceil
local _isSFPassive = string.char(95, 105, 115, 83, 70, 80, 97, 115, 115, 105, 118, 101, 32)
local PassiveSkillTypes = battle.PassiveSkillTypes

globals.ObjectModel = class("ObjectModel")
ObjectModel.IDCounter = 100

local cantAttackReson = {
	"自身为木桩",
	"技能蓄力中",
	"被控制",
	"指定攻击对象不存在 & (要攻击的阵营 == 自身阵营 & 自身阵营没有可被攻击单位)",
	"无法使用技能",
	[100] = "角色已死亡",
	[102] = "先知效果",
	[-1] = "可以攻击",
	[103] = "技能不在自身技能表中",
	[104] = "当前无技能",
	[101] = "无目标",
	[105] = "buff: cancelToAttack"
}
local ObjectStateMap = {
	[battle.ObjectState.none] = "无",
	[battle.ObjectState.normal] = "普通",
	[battle.ObjectState.dead] = "假死",
	[battle.ObjectState.realDead] = "真死",
	[battle.ObjectState.reborn] = "复活"
}

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	ObjectModel[attr] = function(self, shapeState)
		local function filterFinalAttr(value)
			local data = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.finalAttrLimit)

			if data.getAttr then
				return data.getAttr(data, attr, value)
			end

			return value
		end

		if self.multiShapeTb then
			if shapeState then
				if shapeState == 2 or shapeState == 0 and self.multiShapeTb[1] == 1 then
					return filterFinalAttr(self.attrs:getBase2FinalAttr(attr))
				end
			elseif self.multiShapeTb[1] == 2 and self.multiShapeTb[3][attr] then
				return filterFinalAttr(self.attrs:getBase2FinalAttr(attr))
			end
		end

		return filterFinalAttr(self.attrs:getFinalAttr(attr))
	end
end

function ObjectModel:ctor(scene, seat)
	self.scene = scene
	self.view = nil
	ObjectModel.IDCounter = ObjectModel.IDCounter + 1
	self.id = ObjectModel.IDCounter
	self.seat = seat
	self.attrs = ObjectAttrs.new()
	self.skills = {}
	self.passiveSkills = {}
	self.skillsOrder = {}
	self.triggerSkillsOrder = {}
	self.passiveSkillsOrder = {}
	self.weatherSkill = nil
	self.curSkill = nil
	self.curTargetId = nil
	self.deadArgs = nil
	self.followMark = -1
	self.state = battle.ObjectState.none
	self.hpTable = table.salttable({
		0,
		0,
		0
	})
	self.mp1Table = table.salttable({
		0,
		0,
		0
	})
	self.buffs = self.scene:createBuffCollection()
	self.simpleBuffs = CMap.new()
	self.auraBuffs = self.scene:createBuffCollection()
	self.buffOverlayCount = {}
	self.changeUnitIDTb = {}
	self.buffGroupEnchance = {
		{},
		{}
	}
	self.speedPriority = 0
	self.battleRound = {
		[1] = 0,
		[2] = 0
	}
	self.battleRoundAllWave = {
		[1] = 0,
		[2] = 0
	}
	self.closeSkillType2 = {}
	self.ignoreDamageInBattleRound = false
	self.totalDamage = {}
	self.totalResumeHp = {}
	self.totalTakeDamage = {}
	self.extraRoundData = CList.new()
	self.curExtraDataIdx = 0
	self.curExtraData = {}
	self.skillIdToReplaceRecord = {}
	self.skillReplaceReocrd = {}
	self.triggerEnv = {}
	self.recordBuffDataTb = {}
	self.protectedEnv = battleCsv.makeProtectedEnv(self)

	battleComponents.bind(self, "Event")
	self:setListenerComparer(BuffModel.BuffCmp)
	battleQuery.objectBindBuff(scene, self, self.buffs)
end

function ObjectModel:init(data)
	self.data = csvClone(data)
	self.dbID = data.cardId
	self.unitID = data.roleId
	self.originUnitID = data.roleId
	self.level = data.level
	self.advance = data.advance

	if data.force then
		self.force = data.force
	else
		self.force = self.seat <= self.scene.play.ForceNumber and 1 or 2
	end

	self.fightPoint = data.fightPoint or 0
	self.unitCfg = csv.unit[self.unitID]

	if not self.unitCfg then
		error(string.format("no unit config id = %s", self.unitID))
	end

	self.type = data.type or battle.ObjectClass.Normal
	self.mode = data.mode or battle.ObjectType.Normal
	self.star = data.star or 0
	self.attributeType = self.unitCfg.attributeType
	self.natures = {
		self.unitCfg.natureType,
		self.unitCfg.natureType2
	}
	self.rarity = self.unitCfg.rarity
	self.summonCalDamage = self.unitCfg.summonCalDamage
	self.cardID = self.unitCfg.cardID
	self.cardCfg = csv.cards[self.cardID]
	self.markID = self.cardCfg and self.cardCfg.cardMarkID or 0
	self.state = battle.ObjectState.normal
	self.waveGoonDel = data.waveGoonDel
	self.noPassive = data.noPassive
	self.noAddWeather = data.noAddWeather
	self.multiShapeTb = data.role2Data and {
		1,
		{},
		{}
	} or nil

	self:onInitAttributes()

	self.skillInfo = data.skills or {}
	self.passiveSkillInfo = data.passive_skills or {}
	self.attackerCurSkill = {}
	self.tagSkills = {}
	self.skillsMap = {}

	self.attrs:setBaseAttr("height", self.unitCfg.height)
	self.attrs:setBaseAttr("weight", self.unitCfg.weight)
	self:onInitSkills(self.skillInfo, self.passiveSkillInfo)

	self.hpScale = data.hpScale
	self.mp1Scale = data.mp1Scale

	self:addObjViewToScene()

	self.faceTo = self.view:proxy():getFaceTo()

	self.view:proxy():setStartActionAndPos()

	self.effectPower = csv.effect_power[self.unitCfg.effectPowerId]

	if self:hasExtraOccupiedSeat() then
		self:addSimpleBuff(battle.OverlaySpecBuff.occupiedSeat, self, self.effectPower.occupiedSeat)
	end

	self.battleFlag = arraytools.hash(arraytools.merge({
		self.unitCfg.battleFlag,
		self.data.battleFlag
	}))

	for _, v in pairs(battle.DamageFrom) do
		self.totalDamage[v] = battleEasy.valueTypeTable()
	end

	for _, v in pairs(battle.ResumeHpFrom) do
		self.totalResumeHp[v] = battleEasy.valueTypeTable()
	end

	for _, v in pairs(battle.TriggerEnvType) do
		self.triggerEnv[v] = CVector.new()
	end

	self:onInitPassData()
	self:setHP(self:hpMax(), self:hpMax())
	self:setMP1(self:initMp1(), self:initMp1())

	self.summonGroup = data.summonGroup or self.id
end

function ObjectModel:addObjViewToScene()
	local args = {
		type = battle.SpriteType.Normal
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

function ObjectModel:onInitPassData()
	return
end

function ObjectModel:onInitAttributes()
	self.attrs:setSceneTag(self.scene.sceneTag)
	self:setBaseData(self.data)
end

function ObjectModel:setBaseData(base)
	local demonCorrect = battleEasy.ifElse(self.force == 1, self.scene.demonCorrectSelf, self.scene.demonCorrect)
	local csv_fix

	if demonCorrect then
		csv_fix = gSceneDemonCorrectCsv[demonCorrect][self.scene.play.curWave] or gSceneDemonCorrectCsv[demonCorrect][1]
	end

	if csv_fix then
		local gateFix = self.scene.play:getTopCardsAttrAvg(6)
		local selfForceStr = self.force == 1 and "self" or ""
		local seatExtraFix = csv_fix.seatExtraFix
		local seatExtraFixVal = seatExtraFix[self.seat] or 1

		for key, v in pairs(gateFix) do
			local fixArg = csv_fix[key .. selfForceStr]

			if fixArg[1] and fixArg[2] then
				local rowNum = 2 - math.floor((self.seat + 2) / 3) % 2
				local fixVal = battleEasy.ifElse(rowNum == 1, fixArg[1], fixArg[2])

				base[key] = math.floor(v * fixVal * seatExtraFixVal)

				if base.role2Data then
					base.role2Data[key] = math.floor(v * fixVal * seatExtraFixVal)
				end
			end
		end
	end

	self.attrs:setBase(base)
end

function ObjectModel:checkSkillCheat()
	if ANTI_AGENT then
		return
	end

	checkSpecificCsvCheat("skill", itertools.ikeys(itertools.chain({
		self.skills,
		self.passiveSkills
	})))
end

function ObjectModel:onInitPreSkills(skillLevels, additionalPassive)
	local replaceMap = {}

	return replaceMap
end

function ObjectModel:insertPassiveSkills(skillID, skillLevel)
	if self.noPassive then
		return
	end

	self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
end

function ObjectModel:addWeatherPassive()
	if self.noPassive then
		return
	end

	if self.noAddWeather then
		return
	end

	local weatherData = self.scene.buffGlobalManager:getWeatherData(self.force, self.cardID)
	local skillId = weatherData and weatherData.skillId

	if self.weatherSkill then
		self.passiveSkills[skillId] = self.weatherSkill
	elseif skillId then
		local wSkill = newSkillModel(self.scene, self, skillId)

		wSkill.isWeather = true
		self.passiveSkills[skillId] = wSkill
		self.weatherSkill = wSkill
	end
end

function ObjectModel:onInitSkills(skillLevels, additionalPassive)
	self.skills = {}
	self.passiveSkills = {}
	self.tagSkills = {}

	local replaceMap = self:onInitPreSkills(skillLevels, additionalPassive)
	local skillTb = {
		passive = 2,
		skill = 1
	}
	local insertFunc = {
		[skillTb.skill] = function(skillID, skillLevel)
			self.skills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
		end,
		[skillTb.passive] = function(skillID, skillLevel)
			self:insertPassiveSkills(skillID, skillLevel)
		end
	}

	local function switchSkillID(skillID)
		return replaceMap[skillID] or skillID
	end

	local function insertTagSkill(skillID, skillCfg, level)
		if skillCfg and skillCfg.skillType2 == battle.MainSkillType.TagSkill then
			self.tagSkills[skillID] = level

			return true
		end
	end

	local function insertSkill(ret, skillID, level, tbType)
		local skillCfg = csv.skill[skillID]

		if not skillCfg then
			return
		end

		if not insertTagSkill(skillID, skillCfg, level) and not ret[skillID] then
			insertFunc[tbType](skillID, level)
		end
	end

	for skillID, skillLevel in pairs(skillLevels) do
		skillID = switchSkillID(skillID)

		local skillCfg = csv.skill[skillID]

		if skillCfg then
			if skillCfg.skillType == battle.SkillType.NormalSkill then
				insertFunc[skillTb.skill](skillID, skillLevel)
			elseif skillCfg.skillType == battle.SkillType.PassiveAura or skillCfg.skillType == battle.SkillType.PassiveSkill then
				insertFunc[skillTb.passive](skillID, skillLevel)
			else
				insertTagSkill(skillID, skillCfg, skillLevel)
			end
		end
	end

	for _, skillID in ipairs(self.unitCfg.skillList) do
		insertSkill(self.skills, switchSkillID(skillID), skillLevels[skillID] or 1, skillTb.skill)
	end

	for _, skillID in ipairs(self.unitCfg.passiveSkillList) do
		insertSkill(self.passiveSkills, switchSkillID(skillID), skillLevels[skillID] or 1, skillTb.passive)
	end

	for skillID, skillLevel in pairs(additionalPassive) do
		insertSkill(self.passiveSkills, switchSkillID(skillID), skillLevel, skillTb.passive)
	end

	self:addWeatherPassive()
	self:updateSkillsOrder()
	self:checkSkillCheat()
	self:resetReplaceSkillRecord()

	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end

	if not self.scene[_isSFPassive] then
		device.sf_ = false
	end
end

function ObjectModel:updateSkillsOrder()
	self.skillsOrder = itertools.keys(self.skills)

	table.sort(self.skillsOrder, function(id1, id2)
		if csv.skill[id1].skillType2 == csv.skill[id2].skillType2 then
			if csv.skill[id1].skillPriority == csv.skill[id2].skillPriority then
				return id2 < id1
			else
				return csv.skill[id1].skillPriority > csv.skill[id2].skillPriority
			end
		else
			return csv.skill[id1].skillType2 > csv.skill[id2].skillType2
		end
	end)

	local triggerSkillsOrder = {}

	for skillID, skill in pairs(self.passiveSkills) do
		table.insert(triggerSkillsOrder, skillID)
	end

	table.sort(triggerSkillsOrder, function(id1, id2)
		local prior1 = csv.skill[id1].passivePriority
		local prior2 = csv.skill[id2].passivePriority

		if prior1 and prior2 and prior1 ~= prior2 then
			return prior1 < prior2
		else
			return id1 < id2
		end
	end)

	self.triggerSkillsOrder = triggerSkillsOrder
	self.passiveSkillsOrder = triggerSkillsOrder

	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)

	if buffData.refreshAll then
		buffData.refreshAll()
	end
end

function ObjectModel:onAddSkills(skillLevels)
	if not skillLevels or not next(skillLevels) then
		return
	end

	local addSkills = {}

	for skillID, skillLevel in pairs(skillLevels) do
		local skillCfg = csv.skill[skillID]

		if not skillCfg then
			return false
		end

		if skillCfg.skillType == battle.SkillType.NormalSkill then
			self.skills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
			addSkills[skillID] = self.skills[skillID]
		elseif skillCfg.skillType == battle.SkillType.PassiveAura or skillCfg.skillType == battle.SkillType.PassiveSkill then
			self.passiveSkills[skillID] = newSkillModel(self.scene, self, skillID, skillLevel)
			addSkills[skillID] = self.passiveSkills[skillID]
		else
			insertTagSkill(skillID, skillCfg, skillLevel)
		end
	end

	self:updateSkillsOrder()
	self:checkSkillCheat()

	for skillID, skill in self:iterSkills() do
		if addSkills[skillID] then
			skill:updateStateInfoTb()
		end
	end
end

function ObjectModel:cantBeAttack()
	if self:isDeath() then
		return true
	end

	return false
end

function ObjectModel:initedTriggerPassiveSkill(isNotTrigger)
	if not isNotTrigger then
		self:onPassive(PassiveSkillTypes.enter)
	end

	if self:triggerOriginEnvCheck(battle.TriggerEnvType.PassiveSkill, PassiveSkillTypes.enter) then
		return
	end

	if not isNotTrigger then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAfterEnter)
	end
end

function ObjectModel:hp(show)
	return self.hpTable[show and 2 or 1]
end

function ObjectModel:getCurSkill()
	local gate = self.scene.play
	local curHero = gate.curHero

	return curHero and curHero.curSkill
end

function ObjectModel:getSkillType()
	local gate = self.scene.play
	local curHero = gate.curHero
	local skillType, mainSkillType

	if curHero and curHero.curSkill then
		skillType = curHero.curSkill.skillType
		mainSkillType = curHero.curSkill.skillType2
	end

	return skillType, mainSkillType
end

function ObjectModel:getSkillByType2(type2)
	for skillID, skill in self:iterSkills() do
		if skill.skillType2 == type2 then
			return skill
		end
	end
end

function ObjectModel:getOriginSkillTb()
	local unitCfg = csv.unit[self.originUnitID]
	local skill = csv.skill
	local skillTb = {
		[battle.MainSkillType.NormalSkill] = {},
		[battle.MainSkillType.SmallSkill] = {},
		[battle.MainSkillType.BigSkill] = {}
	}
	local type

	for _, skillId in ipairs(unitCfg.skillList) do
		type = skill[skillId].skillType2

		if skillTb[type] then
			table.insert(skillTb[type], skillId)
		end
	end

	return skillTb
end

function ObjectModel:addHp(v, reason)
	if v > 0 then
		for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.forbiddenAddHP) do
			if data.isAll then
				return 0
			end
		end
	end

	local hp = self:hp() + v

	if hp < 0 then
		self.hpTable[3] = self.hpTable[3] + hp
	elseif self:hp() == 0 and v > 0 then
		v = v + self.hpTable[3]
		self.hpTable[3] = math.min(v, 0)
		hp = self:hp() + v
	end

	if v > 0 then
		local hpMax = self:getHpMaxWithLimit()

		if hpMax < hp then
			hp = math.max(self:hp(), hpMax)
		end

		hp = math.min(hp, self:hpMax())
	end

	self:setHP(hp)

	return v
end

function ObjectModel:getHpMaxWithLimit()
	local hpMax = self:hpMax()
	local limitData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.forceMaxHpLimit)

	if limitData then
		hpMax = math.min(hpMax, limitData.maxHpLimit)
	end

	local freezeHpMax = self:hpMax() - self:freezeHpMax()

	hpMax = math.min(hpMax, freezeHpMax)

	return hpMax
end

function ObjectModel:correctHp(v, vShow)
	v = v and _ceil(v)

	self:setHP(v, vShow)
end

function ObjectModel:setHP(v, vShow)
	log.battle.object.setHP({
		object = self,
		hp = v,
		showHp = vShow
	})

	local hpMax = self:hpMax()
	local _v = v and cc.clampf(v, 0, hpMax)
	local _vShow = vShow and cc.clampf(vShow, 0, hpMax)

	if _floor(_v) ~= _v then
		errorInWindows("hp is not integer %.15f", _v)
	end

	self.hpTable[1] = _v or self.hpTable[1]
	self.hpTable[2] = _vShow or self.hpTable[2]

	if not self:isDeath() then
		local skillType, mainSkillType = self:getSkillType()

		battleEasy.deferNotify(self.view, "updateLifebar", {
			skillType = skillType,
			mainSkillType = mainSkillType
		})
	end

	self:refreshShield()
end

function ObjectModel:mp1(show)
	return self.mp1Table[show and 2 or 1]
end

function ObjectModel:mpOverflow()
	return self.mp1Table[3]
end

function ObjectModel:updateMp1Overflow(mp1, oldMp1, mp1Max, changeOverflowFromBuff)
	local mp1OverflowData = self:getFrontOverlaySpecBuff("mp1OverFlow")
	local mpOverflow = self:mpOverflow()

	if not mp1OverflowData then
		return mp1, mpOverflow
	end

	if mp1 then
		local mode = mp1OverflowData.mode

		if mode ~= 1 then
			local function dealMp1AndMpOverflow(affectNormalMp)
				local changeMp1 = mp1 - oldMp1

				mpOverflow = mpOverflow + changeMp1
				mp1 = oldMp1

				if affectNormalMp then
					if mpOverflow > mp1OverflowData.limit then
						mp1 = mp1 + (mpOverflow - mp1OverflowData.limit)
					elseif mpOverflow < 0 then
						mp1 = mp1 + mpOverflow
					end
				end

				mpOverflow = cc.clampf(mpOverflow, 0, mp1OverflowData.limit)
			end

			local isCharging = self.curSkill and self.curSkill.chargeRound

			if isCharging and mp1OverflowData.extraArgs.changeMpOverflowInCharge then
				dealMp1AndMpOverflow(mp1OverflowData.extraArgs.affectNormalMpInCharge)
			elseif changeOverflowFromBuff then
				dealMp1AndMpOverflow(mp1OverflowData.extraArgs.affectNormalMpFromBuff)
			elseif mp1 < oldMp1 and mode == 3 then
				dealMp1AndMpOverflow(true)
			end
		end

		if mp1Max < mp1 then
			mpOverflow = (mp1 - mp1Max) * (mode == 1 and 1 or mp1OverflowData.rate) + mpOverflow
			mpOverflow = cc.clampf(mpOverflow, 0, mp1OverflowData.limit)
		end
	end

	return mp1, mpOverflow
end

function ObjectModel:addMP1(v, args)
	args = args or {}
	v = v + self:mp1()

	local returnFlag = false

	returnFlag, v = self:dealLockMp1(v, args.ignoreLockMp1Add)

	if returnFlag then
		return
	end

	if args.recoverfromSuckMp and args.casterID == self.id then
		self:addExRecord(battle.ExRecordEvent.mpFromSuckMp, v - self:mp1())
	end

	local mpTransformData = self:getFrontOverlaySpecBuff("transformMpchange")

	if mpTransformData and mpTransformData.transformMpCount > 0 then
		local tempMp = v - self:mp1()

		if mpTransformData.mode == 1 and tempMp > 0 or mpTransformData.mode == 2 and tempMp < 0 then
			v = self:mp1() - tempMp * mpTransformData.transformMpPer
			mpTransformData.transformMpCount = mpTransformData.transformMpCount - 1
		end
	end

	local oldMp1 = self:mp1()
	local mp1Max = self:mp1Max()
	local resumeMpOverflow = math.max(v - mp1Max, 0)
	local mpOverflow

	v, mpOverflow = self:updateMp1Overflow(v, oldMp1, mp1Max, args.changeMpOverflow)

	local mpTransferData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.transferMp)
	local curAddValue = v - self:mp1()

	if mpTransferData and self:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.transferMp, "checkCanTransfer", curAddValue, args) then
		local transferTarget = mpTransferData.target
		local transferMp = curAddValue * mpTransferData.percent
		local newArgs = {
			recoverfromTransfer = true,
			transferChainIds = args.transferChainIds or {}
		}

		newArgs.transferChainIds[self.id] = true

		transferTarget:addMP1(transferMp, newArgs)

		return
	end

	self.mp1Table[3] = mpOverflow

	if args.show then
		v = self:setMP1(v, v)
	else
		v = self:setMP1(v)
	end

	local triggerPoint = not args.noTriggerPoint

	if triggerPoint then
		if oldMp1 ~= v then
			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1Change, {
				obj = self,
				delta = v - oldMp1
			})

			if args.recoverfromDamage and args.isLastDamageSeg or not args.recoverfromDamage then
				self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1ChangeCorrection, {
					obj = self,
					delta = v - oldMp1
				})
			end
		end

		if resumeMpOverflow > 0 then
			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1Overflow, {
				resumeMpOverflow = resumeMpOverflow
			})

			if args.recoverfromDamage and args.isLastDamageSeg or not args.recoverfromDamage then
				self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMp1OverflowCorrection, {
					resumeMpOverflow = resumeMpOverflow
				})
			end
		end
	end

	self:refreshShield()
	self.scene.play:refreshUIMp()
end

function ObjectModel:setMP1(v, vShow)
	local mp1Max = self:mp1Max()

	v = v and cc.clampf(v, 0, mp1Max)
	vShow = vShow and cc.clampf(vShow, 0, mp1Max)
	self.mp1Table[1] = v or self.mp1Table[1]
	self.mp1Table[2] = vShow or self.mp1Table[2]

	log.battle.object.setMP1({
		object = self,
		mp1Table = self.mp1Table,
		mp1Max = mp1Max
	})
	battleEasy.deferNotify(self.view, "updateLifebar", {
		mp1OverflowData = self:getFrontOverlaySpecBuff("mp1OverFlow"),
		mp = v,
		mpOverflow = self:mpOverflow(),
		mpMax = mp1Max
	})

	return v
end

function ObjectModel:refreshShield()
	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.shield)
	local shieldHp = self:shieldHp()
	local maxShield = math.max(buffData.shieldMaxTotal or 0, self:hpMax())
	local skillType, mainSkillType = self:getSkillType()

	self:refreshLifeBar()
end

function ObjectModel:refreshAssimilateDamage()
	local buffData = self:getOverlaySpecBuffData("assimilateDamage")
	local assimilateDamage = self:assimilateDamage()
	local maxAssimilateDamage = math.max(buffData.assimilateDamageMaxTotal or 0, self:hpMax())
	local skillType, mainSkillType = self:getSkillType()

	self:refreshLifeBar()
end

function ObjectModel:refreshBarrierHp()
	self:refreshLifeBar()
end

function ObjectModel:shieldHp(filterBuff)
	local hp = 0

	if not filterBuff then
		local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.shield)

		return buffData.shieldTotal or 0
	elseif next(filterBuff) then
		local mark = {}

		for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.shield) do
			if itertools.include(filterBuff, data.cfgId) then
				hp = hp + math.max(data.shieldHp, 0)
			end
		end

		return hp
	end

	return hp
end

function ObjectModel:specialShieldHp()
	local hp = 0

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.shield) do
		if data.showType ~= 0 then
			hp = hp + data.shieldHp
		end
	end

	return hp
end

function ObjectModel:assimilateDamage(filterBuff)
	local hp = 0

	if not filterBuff then
		local buffData = self:getOverlaySpecBuffData("assimilateDamage")

		return buffData.assimilateDamageTotal or 0
	elseif next(filterBuff) then
		local mark = {}

		for _, data in self:ipairsOverlaySpecBuff("assimilateDamage") do
			if itertools.include(filterBuff, data.cfgId) then
				hp = hp + math.max(data.assimilateDamage, 0)
			end
		end

		return hp
	end

	return hp
end

function ObjectModel:barrierHp(filterFuncs)
	local function defaultFunc(data)
		return true
	end

	local filterByCfgId = filterFuncs and filterFuncs.filterByCfgId or defaultFunc
	local filterByType = filterFuncs and filterFuncs.filterByType or defaultFunc
	local barrierValue = 0

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.barrier) do
		if filterByCfgId(data) and filterByType(data) then
			barrierValue = barrierValue + data.barrierValue
		end
	end

	return barrierValue
end

function ObjectModel:addShieldHp(val, filterTb, calcList, args)
	if not self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.shield) then
		return val
	end

	local filterBuffCfgId = filterTb and filterTb.filterBuffCfgId or function()
		return true
	end
	local filterBuffGroups = filterTb and filterTb.filterBuffGroups or function()
		return true
	end
	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.shield)
	local delBuffList, beAttackShieldList = {}, {}

	val = math.floor(val)

	local oldVal = val
	local shieldTotal = calcList and self:shieldHp(calcList) or buffData.shieldTotal

	buffData.shieldTotal = math.max(buffData.shieldTotal + (shieldTotal + val > 0 and val or -shieldTotal), 0)

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.shield) do
		if filterBuffCfgId(data.cfgId) and filterBuffGroups(data.group) then
			if args and args.fromDamage and val < 0 then
				local absorbDamage = math.min(-val, data.shieldHp)

				self:addExRecord(battle.ExRecordEvent.shieldAbsorbDamage, absorbDamage, data.cfgId)
			end

			val = val + data.shieldHp
			beAttackShieldList[data.cfgId] = 1

			if val <= 0 then
				data.shieldHp = 0
				delBuffList[data.id] = true
				beAttackShieldList[data.cfgId] = 2
			else
				data.shieldHp = val
				val = 0

				break
			end
		end
	end

	if oldVal < val then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderShieldChange, {
			beAttackShield = beAttackShieldList
		})
		self:delBuff(delBuffList)
	end

	return val
end

function ObjectModel:addAssimilateDamage(val, filterTb, calcList, args)
	if not self:checkOverlaySpecBuffExit("assimilateDamage") then
		return
	end

	local filterBuffCfgId = filterTb and filterTb.filterBuffCfgId or function()
		return true
	end
	local filterBuffGroups = filterTb and filterTb.filterBuffGroups or function()
		return true
	end
	local buffData = self:getOverlaySpecBuffData("assimilateDamage")
	local delBuffList, beAttackAssimilateDamageList = {}, {}

	val = math.floor(val)

	local oldVal = val
	local assimilateDamageTotal = calcList and self:assimilateDamage(calcList) or buffData.assimilateDamageTotal

	buffData.assimilateDamageTotal = math.max(buffData.assimilateDamageTotal + (assimilateDamageTotal + val > 0 and val or -assimilateDamageTotal), 0)

	for _, data in self:ipairsOverlaySpecBuff("assimilateDamage") do
		if filterBuffCfgId(data.cfgId) and filterBuffGroups(data.group) then
			if args and args.fromDamage and val < 0 then
				local absorbDamage = math.min(-val, data.assimilateDamage)

				self:addExRecord(battle.ExRecordEvent.assimilateDamageAbsorbDamage, absorbDamage, data.cfgId)
			end

			val = val + data.assimilateDamage
			beAttackAssimilateDamageList[data.cfgId] = 1

			if val <= 0 then
				data.assimilateDamage = 0
				delBuffList[data.id] = true
				beAttackAssimilateDamageList[data.cfgId] = 2
			else
				data.assimilateDamage = val

				break
			end
		end
	end

	if oldVal < val then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
			beAttackAssimilateDamage = beAttackAssimilateDamageList
		})
		self:delBuff(delBuffList)
	end
end

function ObjectModel:getBarrierViewData()
	local barrierHp = self:barrierHp()
	local data = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.barrier)
	local opacity = data.opacity or 0

	return {
		hp = barrierHp,
		opacity = opacity
	}
end

function ObjectModel:freezeHpMax()
	return self:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.freezeHpMax, "freezeHpMax") or 0
end

function ObjectModel:getUniversalBarData()
	local _val, _curMax, _max, _time, _resPath = 0, 0, 0, 1, battle.universalBarRes.default
	local active = false
	local data = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.universalBar)

	if data then
		_val, _curMax, _max, _time = self:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.universalBar, "calcValue", data)
		_resPath = data.resPath or _resPath
		active = true
	end

	return {
		val = _val,
		curMax = _curMax,
		max = _max,
		time = _time,
		resPath = _resPath,
		active = active
	}
end

function ObjectModel:refreshLifeBar()
	if self:isDeath() then
		return
	end

	local hp = self.hpTable[1]
	local hpMax = self:hpMax()
	local shieldHpMax = self:getBaseAttr("hpMax")
	local shieldHp = self:shieldHp()
	local specialShieldHp = self:specialShieldHp()
	local delayHp = self:delayDamage()
	local assimilateHp = self:assimilateDamage()
	local barrierData = self:getBarrierViewData()
	local freezeHp = self:freezeHpMax()
	local universalBarData = self:getUniversalBarData()

	battleEasy.deferNotifyCantJump(self.view, "updateLifebar", {
		needCalc = true,
		hp = hp,
		hpMax = hpMax,
		shieldHpMax = shieldHpMax,
		shieldHp = shieldHp,
		specialShieldHp = specialShieldHp,
		delayHp = delayHp,
		assimilateHp = assimilateHp,
		barrierData = barrierData,
		freezeHp = freezeHp,
		universalBarData = universalBarData
	})
	self.scene.play:refreshUIHp(self)
end

function ObjectModel:delayDamage()
	local totalDamage = 0

	for k, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
		if not data.isNotShowDelayHp then
			for _, v in ipairs(data.damageTb) do
				for _, val in ipairs(v) do
					totalDamage = totalDamage + val
				end
			end
		end
	end

	return totalDamage
end

local function iterWithOrder(vals, order, skillsMap)
	local i, k, v = 0
	local n = table.length(order)

	return function()
		while i < n do
			i = i + 1
			k = skillsMap and skillsMap[order[i]] or order[i]
			v = vals[k]

			if v then
				return k, v
			end
		end
	end, order, 0
end

function ObjectModel:iterSkills()
	return iterWithOrder(self.skills, self.skillsOrder, self.skillsMap)
end

function ObjectModel:iterBuffs()
	return self.buffs:order_pairs()
end

function ObjectModel:onPassive(typ, target, args, from)
	if table.length(self.passiveSkillsOrder) == 0 then
		return
	end

	self.triggerEnv[battle.TriggerEnvType.PassiveSkill]:push_back(typ)

	for skillID, skill in iterWithOrder(self.passiveSkills, self.passiveSkillsOrder) do
		self:onOnePassiveTrigger(skill, typ, target, args, from)
	end

	self.triggerEnv[battle.TriggerEnvType.PassiveSkill]:pop_back()
end

function ObjectModel:onPassiveCanTrigger(skill)
	if not skill.onTrigger then
		return false
	end

	if skill:waveTriggeredCheck() then
		return false
	end

	local pauseSkillData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.pausePassiveSkillEffect)

	if pauseSkillData then
		if pauseSkillData.isBlacklist then
			if pauseSkillData.skillCfgIDMap[skill.id] then
				return false
			end
		elseif not pauseSkillData.skillCfgIDMap[skill.id] then
			return false
		end
	end

	return true
end

function ObjectModel:onOnePassiveTrigger(skill, typ, target, args, from)
	local roundId = self.scene.play.battleRoundTriggerId

	if roundId and gExtraRoundTrigger[roundId] and gExtraRoundTrigger[roundId].forbiddenPassiveSkill[typ] then
		return
	end

	if self:onPassiveCanTrigger(skill) and (typ == skill.type or typ == "Aura" and skill.skillType == battle.SkillType.PassiveAura or (typ == PassiveSkillTypes.roundStartAttack or typ == PassiveSkillTypes.roundEnd and args.roundFlag == battle.PassiveRoundEndFlag.SelfBattleTurn or typ == PassiveSkillTypes.roundStart) and skill.skillType == battle.SkillType.NormalCombine) then
		if not target then
			for i, processCfg in ipairs(skill.processes) do
				if processCfg.targetType == 1 then
					target = self

					break
				else
					local tar = self.scene.play:autoChoose(nil, 3 - self.force)
					local defaultChooseID = self.scene.play.nowChooseID or tar.seat

					target = self.scene:getObjectBySeatExcludeDead(defaultChooseID)

					break
				end
			end
		end

		log.battle.object.onPassive({
			object = self,
			passiveType = typ,
			passiveSkill = skill
		})
		skill:onTrigger(typ, target or self, args)
	end
end

function ObjectModel:onNewBattleTurn()
	local roundId = self.scene.play.battleRoundTriggerId
	local disableNewTurn = false

	if roundId and gExtraRoundTrigger[roundId] then
		disableNewTurn = gExtraRoundTrigger[roundId].disableBattleState == 1
	end

	local isSelfTurn = self.scene.play.curHero.id == self.id

	self:addExRecord(battle.ExRecordEvent.attackState, isSelfTurn and 1 or 0)

	if isSelfTurn then
		if self.curExtraDataIdx > 0 then
			self:onNewExtraBattleTurn()
		elseif not disableNewTurn then
			self:updateBattleRound(2)

			if self.scene:getExtraBattleRoundMode() ~= battle.ExtraBattleRoundMode.normal then
				self:addExRecord(battle.ExRecordEvent.extraBattleRound, 1)
			end
		end

		self:addExRecord(battle.ExRecordEvent.roundAttackTime, 1)
	end

	if self:onNewBattleTurnInDead() then
		return
	end

	self.flashBack = false

	self:setHP(self:hp(), self:hp())
	self:setMP1(self:mp1(), self:mp1())
	self:refreshShield()
	self:cleanEventByKey(battle.ExRecordEvent.skillAddBuffIds)

	if isSelfTurn then
		self:onPassive(PassiveSkillTypes.roundStartAttack)
		self:onPassive(PassiveSkillTypes.cycleRound)
		self:updateBuffTriggerPointWithBattleTurn(battle.BuffTriggerPoint.onHolderBattleTurnStart)
		self:alterRoundAttackInfo()
	end

	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBattleTurnStartOther, self)
	self:updateSkillState(isSelfTurn)
	self:replaceExtraBattleTurnSkill()
	battleEasy.queueNotifyFor(self.view, "newBattleTurn")
end

function ObjectModel:onBattleTurnEnd()
	local roundId = self.scene.play.battleRoundTriggerId
	local disableEndTurn = false

	if roundId and gExtraRoundTrigger[roundId] then
		disableEndTurn = gExtraRoundTrigger[roundId].disableBattleState == 2
	end

	self:onPassive(PassiveSkillTypes.hpLess)
	self:onPassive(PassiveSkillTypes.dynamicHpLess, self)

	local teamArgs = {
		objs = self.scene:getHerosMap(self.force)
	}

	self:onPassive(PassiveSkillTypes.teamHpLess, self, teamArgs)
	self:onPassive(PassiveSkillTypes.dynamicTeamHpLess, self, teamArgs)

	self.once = false

	local isSelfTurn = self.scene.play.curHero.id == self.id

	if self.isExtraAttackTurn then
		if self:currentExtraBattleData().mode then
			self:onExtraAttackEnd()
		end

		self.isExtraAttackTurn = false
	elseif isSelfTurn then
		if not disableEndTurn then
			self:updateBattleRound(1)
		end

		self:onPassive(PassiveSkillTypes.roundEnd, self, {
			roundFlag = battle.PassiveRoundEndFlag.SelfBattleTurn
		})
	end

	if isSelfTurn then
		self:updateBuffTriggerPointWithBattleTurn(battle.BuffTriggerPoint.onHolderBattleTurnEnd)
		self:cleanEventByKey(battle.ExRecordEvent.roundAttackInfo)
		battleEasy.deferNotify(nil, "showNumber", {
			close = true
		})
	end

	if not disableEndTurn then
		self.ignoreDamageInBattleRound = false
	end

	self:cleanEventByKey(battle.ExRecordEvent.protectTarget)
	gRootViewProxy:proxy():collectNotify("battleTurn", self, "playBuffHolderAction")
end

function ObjectModel:onBattleTurnEndForce()
	for _, v in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reborn) do
		if v.rebornTrigger then
			v.rebornTrigger = false
			v.times = v.times - 1

			self:beforeRebornCleanData()

			if v.times <= 0 then
				self:delBuff(v.buff.id)
			end

			self:resetRebornState(v.hp, v.mp, v.buff)
		end
	end
end

function ObjectModel:onNewBattleTurnInDead()
	if not self:isFakeDeath() then
		return
	end

	local isSelfTurn = self.scene.play.curHero.id == self.id

	if isSelfTurn then
		if not self.scene:getExtraRoundMode() then
			self:addExRecord(battle.ExRecordEvent.rebornRound, 1)
		end

		self:updateBuffTriggerPointWithBattleTurn(battle.BuffTriggerPoint.onHolderBattleTurnStart)
		self:updateBuffTriggerPointWithBattleTurn(battle.BuffTriggerPoint.onHolderBattleTurnEnd)
	end

	return self:isDeath()
end

function ObjectModel:onNewExtraBattleTurn()
	local curExtraData = self.extraRoundData:erase(self.curExtraDataIdx)

	if curExtraData then
		self.scene.play.battleRoundTriggerId = battleEasy.getRoundTriggerId(curExtraData.cfgId)
		self.isExtraAttackTurn = true
		self.curExtraData = curExtraData
		self.scene.play.battleTurnInfoTb.extraRoundMode = curExtraData.mode
		self.scene.play.battleTurnInfoTb.extraRoundId = curExtraData.cfgId
		self.scene.play.battleTurnInfoTb.extraRoundBuffFlag = curExtraData.buffFlag

		log.battle.object.newExtraBattleTurn({
			curExtraData = curExtraData,
			object = self
		})
	end

	if self:currentExtraBattleData().updateBattleRound then
		self:updateBattleRound(2)
	end
end

function ObjectModel:addExtraBattleData(extraBattleData)
	log.battle.object.addExtraBattleData({
		cfgId = extraBattleData.cfgId,
		extraSkillId = extraBattleData.extraSkillId,
		mode = extraBattleData.mode,
		object = self
	})
	self.extraRoundData:push_back(extraBattleData)
end

function ObjectModel:currentExtraBattleData()
	return self.curExtraData
end

function ObjectModel:onExtraAttackEnd()
	if self.curExtraDataIdx == 0 then
		return
	end

	if self:currentExtraBattleData().updateBattleRound then
		self:updateBattleRound(1)
	end

	self:resumeExtraBattleTurnSkill()
	self:resetExtraDataIdx()
	self:clearExtraBattleDataByMode(self:currentExtraBattleData().mode)
end

function ObjectModel:clearExtraBattleDataByMode(mode)
	local function refreshSkillRound()
		if self.curSkill and self.curSkill.skillType2 ~= battle.MainSkillType.SmallSkill then
			self.curSkill.spellRound = self.curSkill.spellRound - 1
		end
	end

	if mode == battle.ExtraAttackMode.counter then
		self:removeSkillType2Data("counterAttack")
		refreshSkillRound()
	end

	if mode == battle.ExtraAttackMode.prophet then
		refreshSkillRound()
	end
end

function ObjectModel:updateBattleRound(type)
	self.battleRound[type] = self.battleRound[type] + 1
	self.battleRoundAllWave[type] = self.battleRoundAllWave[type] + 1

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		data.caster:updateBattleRound(type)
	end
end

function ObjectModel:updateBuffTriggerPointWithBattleTurn(triggerPoint)
	self:triggerBuffOnPoint(triggerPoint, self)

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		data.caster:triggerBuffOnPoint(triggerPoint, data.caster)
	end
end

function ObjectModel:replaceExtraBattleTurnSkill()
	local function getSkillIdBuffId()
		if self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.replaceExAttackSkill) then
			local buffData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.replaceExAttackSkill)

			if buffData.mode == 1 and buffData.extraSkill then
				return buffData.extraSkill, buffData.cfgId
			end

			return nil
		end

		if self:currentExtraBattleData().extraSkill then
			return self:currentExtraBattleData().extraSkill, self:currentExtraBattleData().cfgId
		end
	end

	local extraSkill, cfgId = getSkillIdBuffId()

	if not extraSkill then
		return
	end

	local newIdList, oldIdList, newSkillTypeToId = {}, {}, {}
	local skillList = battleCsv.doFormula(extraSkill, self.protectedEnv)

	for _, skillId in ipairs(skillList) do
		local cfg = csv.skill[skillId]

		if cfg and cfg.skillType2 then
			newSkillTypeToId[cfg.skillType2] = skillId
		end
	end

	for _, oldSkillId in ipairs(self.skillsOrder) do
		local oldSkill = self.skills[oldSkillId]

		if newSkillTypeToId[oldSkill.skillType2] then
			table.insert(newIdList, newSkillTypeToId[oldSkill.skillType2])
			table.insert(oldIdList, oldSkillId)

			break
		end
	end

	self:replaceSkill(oldIdList, newIdList, cfgId)
end

function ObjectModel:resumeExtraBattleTurnSkill()
	if self:currentExtraBattleData().extraSkill then
		self:resumeSkill(self:currentExtraBattleData().cfgId)
	end
end

function ObjectModel:recordInfoBeforeWave()
	local state = self.curSkill and self.curSkill.chargeRound

	self:addExRecord(battle.ExRecordEvent.chargeStateBeforeWave, state and true or false)
end

function ObjectModel:onNewWave()
	self:recordInfoBeforeWave()

	self.battleRound[1] = 0
	self.battleRound[2] = 0

	for skillID, skill in self:iterSkills() do
		skill:resetOnNewWave()
	end

	self:triggerBuffOnPoint()

	self.curSkill = nil

	for _, data in self.extraRoundData:pairs() do
		self:clearExtraBattleDataByMode(data.mode)
	end

	if self.multiShapeTb then
		self.multiShapeTb[2] = {}
	end

	self:cleanExRoundData()
	self:refreshShield()
end

function ObjectModel:onNewRound()
	if self:isFakeDeath() and not self:canReborn(self.attackMeDeadObj) then
		self.state = battle.ObjectState.realDead

		return
	end

	self:onPassive(PassiveSkillTypes.round)
	self:onPassive(PassiveSkillTypes.roundStart)

	for skillID, skill in self:iterSkills() do
		skill:resetOnNewRound()
	end

	self:cleanEventByKey(battle.ExRecordEvent.roundSyncAttackTime)
	self:cleanEventByKey(battle.ExRecordEvent.extraAttackRoundLimit)
end

function ObjectModel:onEndRound()
	gRootViewProxy:proxy():pushDeferList("onEndRound")
	self:onPassive(PassiveSkillTypes.roundEnd, self, {
		roundFlag = battle.PassiveRoundEndFlag.Round
	})

	local playInEndRound = gRootViewProxy:proxy():popDeferList("onEndRound")

	battleEasy.queueEffect(function()
		battleEasy.queueEffect(function()
			gRootViewProxy:proxy():runDefer(playInEndRound)
		end)
	end)
end

function ObjectModel:isAlreadyDead()
	if self:isDeath() then
		return true
	end

	return self:hp() <= 0
end

function ObjectModel:isDeath()
	return self:isRealDeath() or self:isFakeDeath()
end

function ObjectModel:isFakeDeath()
	return self.state == battle.ObjectState.dead or self:isRebornState()
end

function ObjectModel:isRebornState()
	return self.state == battle.ObjectState.reborn
end

function ObjectModel:isRealDeath()
	return self.state == battle.ObjectState.realDead
end

function ObjectModel:isSpecialDeath()
	local isInScene = self.scene:getFieldObject(self.id)

	return not isInScene and self:canSpecialDeath()
end

function ObjectModel:canSpecialDeath()
	for _, buff in self:iterBuffsWithEasyEffectFunc("buffRecord") do
		local recordList = buff:getEventByKey(battle.ExRecordEvent.buffRecord) or {}

		if recordList.realFakeDeath then
			return true
		end
	end

	return false
end

function ObjectModel:spellAttack()
	local skill = self.curSkill

	if skill then
		if skill.skillType2 == battle.MainSkillType.BigSkill then
			gRootViewProxy:notify("markBigSkillExtraRound")
		end

		battleEasy.deferNotify(nil, "hideAllObjsSkillTips")
		battleEasy.deferNotify(nil, "showHero", {
			typ = "showAll",
			hideLife = true
		})
		gRootViewProxy:proxy():flushCurDeferList()
		self:onPassive(PassiveSkillTypes.attack, nil, nil, skill.skillType == battle.SkillType.NormalSkill and -100)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderToAttack, self)

		if self:cancelToAttack() then
			return false, cantAttackReson[105]
		end

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo, self)
		gRootViewProxy:proxy():flushCurDeferList()

		local canAttack, breakInfo = self:canAttack()

		if not canAttack then
			return false, breakInfo
		end

		if self:isDeath() then
			return false, cantAttackReson[100]
		end

		local target = self:getCurTarget()

		if not target then
			target = self.scene.play:autoChoose(self.curSkill.id)

			if not target then
				return false, cantAttackReson[101]
			end

			self.curTargetId = target.id
		end

		if self:onProphet(skill, target) then
			return false, cantAttackReson[102]
		end

		if not battleEasy.checkSkillMatch(self.unitID, skill.id) and skill.ignoreViewCheck == false then
			return false, cantAttackReson[103]
		end

		self.scene:updateBuffForAidObj(battle.BuffTriggerPoint.onSkillSpellBeforeForAid, {
			skill = battleCsv.CsvSkill.newWithCache(skill)
		})
		self.scene.play.aidManager:triggerAidAttack(battle.aidTriggerType.SpellBigSkill, skill)
		self:addExRecord(battle.ExRecordEvent.attackState, 2)
		skill:spellTo(target)

		return true, cantAttackReson[-1]
	end

	return false, cantAttackReson[104]
end

function ObjectModel:secondAttack()
	local otherTarget

	local function getOtherTarget()
		if not otherTarget and self.curSkill then
			otherTarget = self.scene.play:autoChoose(self.curSkill.id)
		end

		return otherTarget
	end

	local tmpSkills = {}
	local spellFunc

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.secondAttack) do
		local target = data.target

		if target and target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = self
		}) then
			target = nil
		end

		if not target and data.needTarget ~= 1 then
			target = getOtherTarget()
		end

		if target and self:checkCanExtraAttack(data) then
			local skillId = data.skillId
			local skill = self.skills[skillId]

			if not skill then
				local cfg = csv.skill[skillId]
				local oldSkill = self:getSkillByType2(cfg.skillType2)
				local skillLevel = oldSkill and oldSkill.level or 1

				skill = newSkillModel(self.scene, self, skillId, skillLevel)
			end

			function spellFunc()
				skill:spellTo(target)
			end
		end

		data.buff:overClean()
	end

	return spellFunc
end

function ObjectModel:cancelToAttack()
	local exAttackMode = self:getExtraRoundMode()
	local takeEffect = false
	local deductCd = false
	local deductMp = false

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.cancelToAttack) do
		if exAttackMode then
			takeEffect = takeEffect or data.exAttackTakeEffect
		else
			takeEffect = true
		end

		deductCd = deductCd or data.deductCd
		deductMp = deductMp or data.deductMp
	end

	if takeEffect then
		self.curSkill:cancelSpellTo(deductCd, deductMp)

		self.curSkill = nil
	end

	return takeEffect
end

function ObjectModel:onProphet(skill, target)
	if self:getExtraRoundMode() or self.scene.play.battleRoundTriggerId or not self.scene:hasTypeBuff("prophet") then
		return
	end

	local buff
	local mustHitObjs, cantHitObjs = {}, {}
	local oldSpellTo = skill.isSpellTo

	skill.isSpellTo = true

	local targets, processCfgId = self:getProphetTargets(skill, target)

	skill.isSpellTo = oldSpellTo

	local hashTargets = {}

	for _, v in ipairs(targets) do
		hashTargets[v.id] = true
	end

	local enemyForce = self.force == 1 and 2 or 1

	for k1, obj in self.scene:getHerosMap(enemyForce):order_pairs() do
		if obj:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.prophet) then
			local randret = randret or ymrand.random()
			local isEffect = false

			for k2, data in obj:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.prophet, self) do
				if randret < data:getProb(self) and obj:checkCanExtraAttack({
					cfgId = data.buff.cfgId,
					mode = battle.ExtraAttackMode.prophet
				}) then
					isEffect = true

					if hashTargets[obj.id] and data:targetFilter(self, target) then
						self.scene.play.battleRoundTriggerId = self.scene.play.battleRoundTriggerId or data.triggerId
						buff = buff or obj.buffs:find(data.id)

						obj:onProphetAttack(skill, self, data)
						obj:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
							buffId = data.buff.id,
							attacker = self
						})
					end

					break
				end
			end

			if isEffect then
				if hashTargets[obj.id] then
					table.insert(mustHitObjs, obj.id)
				else
					table.insert(cantHitObjs, obj.id)
				end
			end
		end
	end

	if buff then
		local data = {
			obj = self,
			prophet = buff.id,
			buffCfgId = buff.cfgId,
			targetId = target.id,
			newSkillId = skill.id,
			mustHit = mustHitObjs,
			cantHit = arraytools.hash(cantHitObjs),
			processCfgId = processCfgId
		}

		data.mode = self.scene:getExtraBattleRoundMode()

		self.scene.play:resetGateAttackRecord(self, data)
	end

	return buff ~= nil
end

function ObjectModel:getProphetTargets(skill, target)
	local targets, processCfgId = {}

	local function isProcessCanPrecalc(processCfg)
		if processCfg.segType == battle.SkillSegType.damage then
			return true
		end

		if processCfg.extraArgs and processCfg.extraArgs.prophetPrecalc == 1 then
			return true
		end

		return false
	end

	for i, processCfg in ipairs(skill.processes) do
		if isProcessCanPrecalc(processCfg) then
			targets = skill:onProcessGetTargets(processCfg, target)
			processCfgId = processCfg.id

			break
		end
	end

	return targets, processCfgId
end

function ObjectModel:getCurTarget()
	return self.curTargetId and self.scene:getFieldObject(self.curTargetId) or nil
end

function ObjectModel:getChargeTarget()
	if self.curSkill and self.curSkill:isChargeSkill() and (self.curSkill:isCharging() or self.curSkill:isChargeOK()) then
		return self.chargeSkillTargetId and self.scene:getFieldObject(self.chargeSkillTargetId) or nil
	end
end

function ObjectModel:isSelfInCharging()
	return self.curSkill and self.curSkill:isChargeSkill() and self.curSkill:isCharging()
end

function ObjectModel:isSelfChargeOK()
	return self.curSkill and self.curSkill:isChargeSkill() and self.curSkill:isChargeOK()
end

function ObjectModel:isSummonType()
	return self.type == battle.ObjectClass.Summon
end

function ObjectModel:isSelfControled()
	return self:isLogicStateExit(battle.ObjectLogicState.cantAttack)
end

function ObjectModel:canAttack()
	if not next(self.skills) then
		return false, cantAttackReson[1]
	end

	if self:isSelfInCharging() then
		return false, cantAttackReson[2]
	end

	if self:isSelfControled() then
		return false, cantAttackReson[3]
	end

	if self:currentExtraBattleData().extraTargetId then
		local tar = self.scene:getFilterObject(self:currentExtraBattleData().extraTargetId, {
			fromObj = self
		}, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)

		if not tar and self:currentExtraBattleData().isFixedForce and self:currentExtraBattleData().targetForce == self.force and table.length(self:getCanAttackObjs(self.force)) == 0 then
			return false, cantAttackReson[4]
		end
	end

	local canUse

	for skillID, skill in self:iterSkills() do
		canUse = skill:canSpell()

		if canUse and (not self:currentExtraBattleData().exAttackSkillID or self:currentExtraBattleData().exAttackSkillID == skillID) then
			return true, cantAttackReson[-1]
		end
	end

	return false, cantAttackReson[5]
end

function ObjectModel:getCanAttackObjs(force)
	local ret

	if force == self.force then
		ret = self.scene:getFilterObjects(force, {
			fromObj = self
		}, battle.FilterObjectType.excludeEnvObj, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)
	else
		ret = self.scene:getFilterObjects(force, {
			fromObj = self
		}, battle.FilterObjectType.noAlreadyDead, battle.FilterObjectType.excludeObjLevel1)
	end

	return ret
end

function ObjectModel:toAttack(attack, target)
	local skillID = attack.skill
	local skill = self.skills[skillID]

	if skill == nil then
		return
	end

	self.curSkill = skill

	if skill:isChargeSkill() and not skill:isChargeOK() then
		if not target then
			return
		end

		skill:startCharge()

		self.chargeSkillTargetId = target.id

		return
	end

	battleEasy.deferNotify(nil, "showSkillName", skillID)

	local tar = target

	if skill.cfg.damageFormula and self:isBeInConfusion() and not self:currentExtraBattleData().isFixedForce then
		local selfSideObjs, enemySideObjs, needSelfForce, prob = self:getConfusionCheckInfos()
		local enemyForce = self.force == 2 and 1 or 2
		local randret = ymrand.random()
		local force = self.force
		local ret

		if table.length(selfSideObjs) == 0 and (table.length(enemySideObjs) == 0 or needSelfForce) then
			return
		elseif table.length(selfSideObjs) == 0 or randret < prob then
			ret = enemySideObjs
			force = enemyForce
		else
			ret = selfSideObjs
		end

		if table.length(ret) > 0 then
			local confusionObjId = ret[ymrand.random(1, table.length(ret))].id

			tar = self.scene:getFieldObject(confusionObjId)
		end
	end

	if not tar then
		return
	end

	self.curTargetId = tar.id

	gRootViewProxy:proxy():flushCurDeferList()

	local skillCanSpell = skill:canSpell()

	log.battle.object.toAttack({
		attacker = self,
		skillId = skillID,
		skillCanSpell = skillCanSpell
	})

	if skillCanSpell then
		local _, breakInfo = self:spellAttack()

		log.battle.object.spellAttack({
			attacker = self,
			breakInfo = breakInfo
		})

		self.scene.play.secondAttackFunc = self:secondAttack()
	end
end

function ObjectModel:getConfusionCheckInfos()
	local selfSideObjs = self:getCanAttackObjs(self.force)
	local enemyForce = self.force == 2 and 1 or 2
	local enemySideObjs = self:getCanAttackObjs(enemyForce)
	local prob = math.huge
	local needSelfForce

	for _, data in self:ipairsOverlaySpecBuff("confusion") do
		if prob > data.prob then
			prob = data.prob
			needSelfForce = data.needSelfForce
		else
			needSelfForce = data.prob == prob and data.needSelfForce or needSelfForce
		end
	end

	return selfSideObjs, enemySideObjs, needSelfForce, prob
end

function ObjectModel:resumeHp(caster, val, args)
	local valueTab = battleEasy.valueTypeTable()

	if val < 0 then
		errorInWindows("回血类效果需配置正值 hp:%s, val:%s", self:hp(), val)

		return valueTab
	end

	if self:checkOverlaySpecBuffExit("lockResumeHp") and not args.ignoreLockResume then
		return valueTab
	end

	local value = val

	if ymrand.random() <= self:cureStrike() then
		value = _floor(value * self:cureStrikeEffect())
		args.cureStrike = true
	end

	if not args.ignoreBeHealAddRate then
		value = _floor(value * (1 + self:beHealAdd()))
	end

	if args.tryBoost and not args.ignoreLockResume and not args.ignoreHealAddRate and not args.ignoreBeHealAddRate and caster:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healBoost) then
		value = caster:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healBoost, "boost", value, self)
	end

	value = _floor(value * (1 + self:finalCureRate()))

	if not args.ignoreChange and self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.changeTreatment) then
		value = self:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.changeTreatment, "change", value, args, caster)
	end

	value = _floor(value)

	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderPreHeal)

	local oldHp = self:hp()

	value = self:addHp(value, args.from)

	battleEasy.deferNotify(self.view, "showHeadNumber", {
		typ = 1,
		num = value,
		args = args or {}
	})

	if value > 0 then
		local hp = oldHp + value

		valueTab:add(value)

		local hpMaxWithLimit = self:getHpMaxWithLimit()

		if hpMaxWithLimit < hp then
			valueTab:add(hp - hpMaxWithLimit, battle.ValueType.overFlow)

			hp = hpMaxWithLimit
		end

		valueTab:add(value - valueTab:get(battle.ValueType.overFlow), battle.ValueType.valid)

		if caster then
			caster.totalResumeHp[args.from]:addTable(valueTab)
		end

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderHpAdd, {
			resumeHp = valueTab,
			resumeHpFrom = args.from,
			resumeHpFromKey = args.fromKey,
			ignoreBeHealAddRate = args.ignoreBeHealAddRate,
			ignoreHealAddRate = args.ignoreHealAddRate,
			cureStrike = args.cureStrike,
			obj = caster
		})
	end

	log.battle.object.resumeHp({
		object = self,
		hp = self:hp(),
		changeHp = value,
		finalHp = hp
	})

	return valueTab
end

function ObjectModel:beforeRebornCleanData()
	self.hpTable[3] = 0
end

function ObjectModel:resetHp(val, args)
	local hp = val

	if hp - self:hpMax() > -1e-05 then
		hp = self:hpMax()
	end

	log.battle.object.resetHp({
		object = self,
		hp = val,
		finalHp = hp
	})
	battleEasy.deferNotify(self.view, "showHeadNumber", {
		typ = 1,
		num = hp,
		args = args or {}
	})
	self:setHP(hp, hp)
end

function ObjectModel:resetMP1(val)
	self:setMP1(val)
end

function ObjectModel:setDead(attacker, killDamage, deadArgs)
	if self:isDeath() then
		return
	end

	deadArgs = deadArgs or {
		force = false
	}

	if not deadArgs.beAttackZOrder then
		self.scene:updateBeAttackZOrder()

		deadArgs.beAttackZOrder = self.scene.beAttackZOrder
	end

	self.deadArgs = deadArgs
	self.state = battle.ObjectState.dead
	self.attackMeDeadObj = attacker
	self.killMeDamageValues = killDamage and killDamage or battleEasy.valueTypeTable()

	if self.scene.play.gateDoOnObjectDead then
		self.scene.play:gateDoOnObjectDead(self)
	end

	self:addAttackerMpOnSelfDead(attacker)

	if not deadArgs.noTrigger then
		local deathBuff = gRootViewProxy:proxy():pushDeferList(self.id, "deathBuff")

		self:onPassive(PassiveSkillTypes.beDeathAttack)

		if attacker then
			attacker:onPassive(PassiveSkillTypes.kill, attacker)
		end

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderDeath, {
			killerID = self.attackMeDeadObj and self.attackMeDeadObj.seat or 0
		})
		gRootViewProxy:proxy():collectDeferList("battleTurn", self, gRootViewProxy:proxy():popDeferList(deathBuff))
	end

	self:delBuffsWithSelf()
	lazylog.battle.object.dead({
		attacker = attacker,
		object = self,
		state = ObjectStateMap[self.state],
		traceInfo = battleEasy.logTraceInfo(5)
	})

	if deadArgs.force then
		if self:canSpecialDeath() then
			self:processSpecialDeath(deadArgs.noTrigger)
		else
			self:processRealDeath(deadArgs.beAttackZOrder, deadArgs.noTrigger)
		end
	elseif self:canReborn(attacker) then
		self:processFakeDeath()
	elseif self:canSpecialDeath() then
		self:processSpecialDeath(deadArgs.noTrigger)
	else
		self:processRealDeath(deadArgs.beAttackZOrder, deadArgs.noTrigger)
	end

	self:delFollowObjWithDead(attacker, killDamage, deadArgs)
	self:cleanSimpleBuff()
end

function ObjectModel:fastRebornResetExtraData()
	if self.state == battle.ObjectState.normal then
		local data = self:getEventByKey(battle.ExRecordEvent.extraAttackDataInFastReborn)

		if data then
			self.extraRoundData:push_back(data)

			self.curExtraDataIdx = 1
		end
	end

	self:cleanEventByKey(battle.ExRecordEvent.extraAttackDataInFastReborn)
end

function ObjectModel:delFollowObjWithDead(attacker, killDamage, deadArgs)
	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		if data.caster:isBindOwnerWithDead() then
			data.caster:setDead(attacker, killDamage, deadArgs)
		end
	end
end

function ObjectModel:delBuffsWithSelf()
	local enemyForce = self.force == 1 and 2 or 1

	for _, obj in self.scene:ipairsOnSiteHeros() do
		if not obj:isAlreadyDead() and obj:isBeInSneer() and obj:getSneerObj() and obj:getSneerObj().id == self.id then
			for _, buff in obj:iterBuffsWithEasyEffectFunc("sneer") do
				if buff.csvCfg.easyEffectFunc == "sneer" then
					buff:overClean()
				end
			end
		end
	end
end

function ObjectModel:processFakeDeath()
	log.battle.object.fakeDead({
		object = self
	})
	self:onPassive(PassiveSkillTypes.fakeDead)
	self:clearBuff(function(buff)
		local noDelBuff = buff.csvCfg.noDelWhenFakeDeath == 1

		return buff.csvCfg.easyEffectFunc ~= "reborn" and not noDelBuff
	end)
	self:fakeDeathCleanData()
	self:processReborn(self.attackMeDeadObj)
end

function ObjectModel:processSpecialDeath(noTrigger)
	if self:isRealDeath() then
		return
	end

	if not noTrigger then
		self:onPassive(PassiveSkillTypes.realDead)

		local realDeathBuff = gRootViewProxy:proxy():pushDeferList(self.id, "realDeathBuff")

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderRealDeath, {
			killerID = self.attackMeDeadObj and self.attackMeDeadObj.seat or 0
		})

		if self.attackMeDeadObj then
			self.attackMeDeadObj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMakeTargetRealDeath, {
				obj = self
			}, {
				killedTargets = {
					self
				}
			})
		end

		gRootViewProxy:proxy():collectDeferList("battleTurn", self, gRootViewProxy:proxy():popDeferList(realDeathBuff))
	end

	self:clearBuff(function(buff)
		local noDelBuff = buff.csvCfg.noDelWhenFakeDeath == 1

		return buff.csvCfg.easyEffectFunc ~= "reborn" and not noDelBuff
	end)
	self:fakeDeathCleanData()
	self:processReborn(self.attackMeDeadObj)
end

local DeleteWithModelMap = {
	"changeUnit",
	"changeToRandEnemyObj",
	"changeImage"
}

function ObjectModel:processRealDeath(realDeadOrder, noTrigger)
	log.battle.object.realDead({
		object = self
	})

	if self:isRealDeath() then
		return
	end

	self.state = battle.ObjectState.realDead

	self:influenceSceneBuff(battle.InfluenceSceneBuffType.dead, true)

	if not noTrigger then
		self:onPassive(PassiveSkillTypes.realDead)

		local realDeathBuff = gRootViewProxy:proxy():pushDeferList(self.id, "realDeathBuff")

		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderRealDeath, {
			killerID = self.attackMeDeadObj and self.attackMeDeadObj.seat or 0
		})

		if self.attackMeDeadObj then
			self.attackMeDeadObj:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderMakeTargetRealDeath, {
				obj = self
			}, {
				killedTargets = {
					self
				}
			})
		end

		gRootViewProxy:proxy():collectDeferList("battleTurn", self, gRootViewProxy:proxy():popDeferList(realDeathBuff))
		self.scene.play.aidManager:addAidTimesByRealDead(self)
	end

	self.scene.play:recordDamageStats()
	self.scene:addObjToBeDeleted(self)
	self.scene:setDeathRecord(self, realDeadOrder)
	self:realDeathCleanData()
	self:recordRealDeadHpMaxSum()
	self:onLeaveSeat()
end

function ObjectModel:processRealDeathClean()
	if self:isRealDeath() then
		return
	end

	self.state = battle.ObjectState.realDead

	self:realDeathCleanData()
end

function ObjectModel:recordRealDeadHpMaxSum()
	if self:isSummonType() then
		local canCalHpMax = not self:effectPowerControl(battle.EffectPowerType.summonSpecialCheck)

		if not canCalHpMax then
			return
		end
	end

	if self.scene.play.myDeadHpMaxSum and self.force == 1 then
		self.scene.play.myDeadHpMaxSum = self.scene.play.myDeadHpMaxSum + self:hpMax()
	elseif self.scene.play.enemyDeadHpMaxSum and self.force == 2 then
		self.scene.play.enemyDeadHpMaxSum = self.scene.play.enemyDeadHpMaxSum + self:hpMax()
	end
end

function ObjectModel:fakeDeathCleanData()
	self.killMeDamageValues = nil

	self:cleanExRoundDataInDeath()
	self:deleteAuraBuffs()
end

function ObjectModel:realDeathCleanData()
	local query = self:getBuffQuery():groups_init_with_all():groups_sub_array("-", "easyEffectFunc", "+", DeleteWithModelMap)

	self:clearBuff(nil, query)
	self:cleanEventByKey(battle.ExRecordEvent.weatherLevels)
	self:cleanEventByKey(battle.ExRecordEvent.attackedRoundRecord)
	self:fakeDeathCleanData()
end

function ObjectModel:hasExtraBattleRound()
	return false
end

function ObjectModel:triggerBuffOnPoint(triggerPoint, trigger, env)
	log.battle.object.triggerBuffOnPoint({
		object = self,
		triggerPoint = triggerPoint
	})

	if self.buffs:empty() or not self:effectPowerControl(battle.EffectPowerType.triggerPoint, triggerPoint, env) then
		return
	end

	BattleAssert.onEvent("triggerBuffOnPoint", triggerPoint)

	if BuffModel.IterAllPointsMap[triggerPoint] then
		for _, buff in self:iterBuffs() do
			if buff:isTrigger(triggerPoint, trigger) then
				buff:updateWithTrigger(triggerPoint, trigger)
			end
		end
	else
		self:dispatchEvent(triggerPoint, trigger)
	end

	BattleAssert.onEvent("triggerBuffOnPointEnd", triggerPoint)
end

function ObjectModel:calcInternalDamage(attacker, damage, damageProcessId, damageArgs)
	local damage, damageArgs = battleEasy.runDamageProcess(damage, attacker, self, damageProcessId, damageArgs)

	return _floor(damage), damageArgs
end

function ObjectModel:beAttack(attacker, damage, damageProcessId, damageArgs)
	self.curAttackMeObj = attacker

	if not damageArgs.processId and not damageArgs.isDefer then
		self.scene:updateBeAttackZOrder()
	end

	damageArgs.beAttackZOrder = damageArgs.beAttackZOrder or self.scene.beAttackZOrder

	if attacker then
		for _, buff in self:iterBuffs() do
			buff:refreshExtraTargets(battle.BuffExtraTargetType.holderBeAttackFrom, {
				attacker
			})
		end
	end

	local needAttackerRecord = attacker and not damageArgs.noDamageRecord
	local damageValueTab = battleEasy.valueTypeTable()

	if self:isDeath() then
		if needAttackerRecord then
			attacker.totalDamage[damageArgs.from]:add(damage, battle.ValueType.overFlow)
			attacker.totalDamage[damageArgs.from]:add(damage)
		end

		self:getTotalTakeDamage():add(damage, battle.ValueType.overFlow)
		self.scene:setDeathRecord(self, damageArgs.beAttackZOrder)
		self.scene:runBeAttackDefer(self.id)

		return damageValueTab, damageArgs
	end

	local damage, damageArgs = self:calcInternalDamage(attacker, damage, damageProcessId, damageArgs)
	local isFullHp = abs(self:hp() - self:hpMax()) < 1e-05

	if self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.sleepy) and damageArgs.isLastDamageSeg and damageArgs.from == battle.DamageFrom.skill and not self.scene:getExtraRoundMode() and not damageArgs.beHitNotWakeUp then
		self:processBeHitWakeUp(attacker)
	end

	if damageArgs.specialFrom and damageArgs.specialFrom.lockHp then
		damage = math.min(math.max(self:hp() - damageArgs.specialFrom.lockHp, 0), damage)
	end

	damageValueTab:add(damage)

	if damageArgs.recordValue then
		damageValueTab:add(damageArgs.recordValue)
	end

	local totalDamage = 0

	for _, v in pairs(attacker.totalDamage) do
		totalDamage = totalDamage + v:get(battle.ValueType.normal)
	end

	log.battle.object.causeDamage({
		attacker = attacker,
		object = self,
		damageArgs = damageArgs,
		damage = damage,
		totalDamage = totalDamage
	})

	if needAttackerRecord then
		attacker.totalDamage[damageArgs.from]:add(damageValueTab:get(battle.ValueType.normal))
	end

	if damage ~= 0 then
		local hp = self:hp() - damage

		if needAttackerRecord then
			self.scene.play:recordScoreStats(attacker, damage)
		end

		damageValueTab:add(hp < 0 and abs(hp) or 0, battle.ValueType.overFlow)
		damageValueTab:add(damage - damageValueTab:get(battle.ValueType.overFlow), battle.ValueType.valid)
		log.battle.object.beAttack({
			attacker = attacker,
			object = self,
			curHp = self:hp(),
			damage = damage,
			finalHp = hp,
			damageArgs = damageArgs
		})
		self:getTotalTakeDamage():addTable(damageValueTab)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLostHpBefore, {
			lostHp = damageValueTab
		})

		if damageArgs.isLastDamageSeg then
			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLostHpBeforeCorrection, {
				lostHp = damageValueTab
			})
		end

		self:addHp(-damage)
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLostHp, {
			lostHp = damageValueTab,
			obj = attacker
		})

		if damageArgs.isLastDamageSeg then
			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderLostHpCorrection, {
				lostHp = damageValueTab,
				obj = attacker
			})

			local lostHpTab = battleEasy.valueTypeTable()

			lostHpTab:add(damageValueTab)

			if damageArgs.from == battle.DamageFrom.skill and attacker and attacker.curSkill then
				local finalDamage = attacker.curSkill:getTargetsFinalResult(self.id, battle.SkillSegType.damage)

				lostHpTab:add(finalDamage.real)
			end

			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderHpChange, {
				lostHp = lostHpTab,
				damageArgs = damageArgs,
				damageProcessId = damageProcessId
			})
		end

		self:beAttackRecoverMp(attacker, damage, hp, damageArgs)
		self:onBeAttack(attacker, damageArgs, {
			isFullHp = isFullHp
		})

		if needAttackerRecord then
			attacker.totalDamage[damageArgs.from]:addTable(damageValueTab, battle.ValueType.overFlow, battle.ValueType.valid)
		end
	end

	if damageArgs.isLastDamageSeg then
		self:beforeSetDead(attacker, damage, damageArgs, damageValueTab)
		self.scene:runBeAttackDefer(self.id)
	end

	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeAttackEnd, {
		damageArgs = damageArgs,
		obj = attacker
	})

	return damageValueTab, damageArgs
end

function ObjectModel:beAttackRecoverMp(attacker, damage, hp, damageArgs)
	local mpArgs = {
		recoverfromDamage = true,
		isLastDamageSeg = damageArgs.isLastDamageSeg
	}

	if self:checkCanRecoverMp(attacker, damageArgs) then
		local correctCfg = self.scene:getSceneAttrCorrect(self:serverForce())
		local commonPreMp = gCommonConfigCsv and gCommonConfigCsv.lostOnePercentHpAddMp or 1
		local perMp = correctCfg.lostBloodMp1 or 1
		local perHpMp = 1 / self:hpMax() * 100 * commonPreMp * perMp
		local mp = damage * perHpMp

		if hp < 0 then
			local realDamage = damage + hp

			mp = realDamage * perHpMp
		end

		local mp1Correct = mp * (1 + self:mp1Recover() + self:mpBeAttackRecover())

		self:addMP1(mp1Correct, mpArgs)
	end

	if attacker and attacker.curSkill then
		local curSkill = attacker.curSkill
		local skillCfg = curSkill.cfg
		local mp1Correct = skillCfg.hurtMp1 and skillCfg.hurtMp1 * (1 + self:mp1Recover()) or 0

		self:addMP1(mp1Correct, mpArgs)
	end
end

function ObjectModel:onBeAttack(attacker, damageArgs, exArgs)
	if damageArgs.from ~= battle.DamageFrom.skill or self.once then
		return
	end

	self:onPassive(PassiveSkillTypes.beAttack, nil, damageArgs)
	self:onPassive(PassiveSkillTypes.beDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beSpecialDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beNatureDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beNonNatureDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beSpecialNatureDamage, attacker, damageArgs)
	self:onPassive(PassiveSkillTypes.beDamageIfFullHp, attacker, exArgs)
	self:onPassive(PassiveSkillTypes.beStrike, attacker, damageArgs)

	if not damageArgs.skillBlockTriggerPoint or not damageArgs.skillBlockTriggerPoint[battle.BuffTriggerPoint.onHolderBeHit] then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBeHit, attacker)
	end

	self.once = true
end

function ObjectModel:beforeSetDead(attacker, damage, damageArgs, damageValueTab)
	if self:hp() > 0 then
		return
	end

	damageArgs.beAttackToDeath = true

	local killMeDamageValues = battleEasy.valueTypeTable()

	killMeDamageValues:add(damageValueTab)

	if damageArgs.from == battle.DamageFrom.skill then
		local curSkill = self:getCurSkill()

		if curSkill then
			local skillRealDamage = curSkill:getTargetDamage(self)

			if skillRealDamage then
				killMeDamageValues:add(-damage + skillRealDamage)
			end
		end
	end

	self:setDead(attacker, killMeDamageValues, {
		force = damageArgs.ignoreFakeDeath,
		beAttackZOrder = damageArgs.beAttackZOrder
	})
end

function ObjectModel:isHit(target, skillCfg)
	local delta = self:hit() - target:dodge()

	if delta <= 0 then
		return false
	end

	local prob = delta
	local cfgHit = skillCfg.skillHit
	local rand = 0
	local crand = ymrand.random(1, 5)

	for i = 1, crand do
		rand = ymrand.random()
	end

	local isHit = rand < prob

	return isHit
end

function ObjectModel:objAddBuffAttr(attr, delta)
	if self.beInImmuneAllAttrsDownState and self.beInImmuneAllAttrsDownState > 0 then
		-- block empty
	end

	if not ObjectAttrs.AttrsTable[attr] then
		return
	end

	if attr == "hpMax" then
		delta = _floor(delta)
	end

	self.attrs:addBuffAttr(attr, delta)
end

function ObjectModel:objAddAuraAttr(attr, delta)
	if not ObjectAttrs.AttrsTable[attr] then
		return
	end

	if attr == "hpMax" then
		delta = _floor(delta)
	end

	self.attrs:addAuraAttr(attr, delta)
end

function ObjectModel:objAddBaseAttr(attr, delta)
	if self.beInImmuneAllAttrsDownState and self.beInImmuneAllAttrsDownState > 0 then
		-- block empty
	end

	if not ObjectAttrs.AttrsTable[attr] then
		return
	end

	if attr == "hpMax" then
		delta = _floor(delta)
	end

	self.attrs:addBaseAttr(attr, delta)
end

function ObjectModel:objAttrsCorrect(cfg)
	self.attrs:correct(cfg)
	self:setHP(self:hpMax(), self:hpMax())

	for k, v in ipairs(cfg.buffGroup or {}) do
		local args = {
			lifeRound = v.lifeTime,
			prob = v.prob,
			value = v.value,
			buffValue1 = v.value,
			cfgId = v.id
		}
		local newArgs = BuffArgs.fromSceneBuff(args)
		local newBuff = addBuffToHero(v.id, self, nil, newArgs)

		if newBuff then
			self:onPassive(PassiveSkillTypes.additional, self, {
				buffCfgId = newBuff.cfgId
			})
		end
	end
end

function ObjectModel:objAttrsCorrectMonster(cfg)
	if self.doneMonsterCorrect then
		return
	end

	self:objAttrsCorrect(cfg)

	self.doneMonsterCorrect = true
end

function ObjectModel:objAttrsCorrectScene(cfg)
	if self.doneSceneCorrect then
		return
	end

	self:objAttrsCorrect(cfg)

	local mp1 = self:mp1()

	self:setMP1(cfg.addMp1 + mp1, cfg.addMp1 + mp1)

	self.doneSceneCorrect = true
end

function ObjectModel:objAttrsCorrectCP(leftTotalCP, rightTotalCP)
	local minTotalCP = math.min(leftTotalCP, rightTotalCP)
	local maxTotalCP = math.max(leftTotalCP, rightTotalCP)

	if maxTotalCP == 0 then
		return
	end

	local fightPointRate = minTotalCP / maxTotalCP
	local attrsCorrectCfg = {}

	for _, v in orderCsvPairs(csv.combat_power_correction) do
		local combatPowerLimit = v.combatPowerLimit[self.scene.gateType] or math.huge

		if fightPointRate < v.fightPointRate[1] and fightPointRate >= v.fightPointRate[2] and combatPowerLimit <= maxTotalCP then
			attrsCorrectCfg = v.attr

			break
		end
	end

	for attr, delta in pairs(attrsCorrectCfg) do
		self:objAddBaseAttr(attr, delta)
	end

	self:addExRecord(battle.ExRecordEvent.correctCPCfg, attrsCorrectCfg)
end

function ObjectModel:clearPreCorrectCP()
	local preAttrsCorrectCfg = self:getEventByKey(battle.ExRecordEvent.correctCPCfg) or {}

	for attr, delta in pairs(preAttrsCorrectCfg) do
		self:objAddBaseAttr(attr, -delta)
	end

	self:cleanEventByKey(battle.ExRecordEvent.correctCPCfg)
end

function ObjectModel:onBuffEffectedHolder(buff)
	local type = buff.csvCfg.easyEffectFunc

	if self.curSkill and self.curSkill.chargeRound then
		local curChargeArgs = self.curSkill.chargeArgs
		local breakChargingData = self:getFrontOverlaySpecBuff("breakCharging")

		if not curChargeArgs.effectDelay and battle.ControllBuffType[type] or breakChargingData and breakChargingData.mode == 1 then
			self.view:proxy():setActionState(battle.SpriteActionTable.standby)
			self.curSkill:interrupt(battle.SkillInterruptType.charge, buff.cfgId)
		end
	end
end

function ObjectModel:getBuffQuery()
	return self.buffs:getQuery()
end

function ObjectModel:clearBuff(filter, query)
	filter = filter or function(buff)
		return true
	end

	if query then
		for _, buff in query:order_pairs() do
			if filter(buff) then
				buff:overClean()
			end
		end

		return
	end

	for _, buff in self:iterBuffs() do
		if filter(buff) then
			buff:overClean()
		end
	end
end

function ObjectModel:deleteSingleAuraBuff(cfgId)
	if self.auraBuffs:empty() then
		return
	end

	for _, buff in self.auraBuffs:getQuery():group("cfgId", cfgId):order_pairs() do
		buff:overClean()
	end
end

function ObjectModel:deleteAuraBuffs()
	for _, buff in self.auraBuffs:order_pairs() do
		buff:overClean()
	end

	self.auraBuffs:clear()
end

function ObjectModel:delBuff(buffIds, triggerCtrlEnd)
	local overTb

	if triggerCtrlEnd then
		overTb = {
			triggerCtrlEnd = true
		}
	end

	local buffId

	if type(buffIds) == "number" then
		buffId = buffIds
	else
		local size = table.nums(buffIds)

		if size == 0 then
			return
		elseif size == 1 then
			buffId = next(buffIds)
		end
	end

	if buffId then
		local buff = self.buffs:find(buffId)

		if buff then
			buff:over(overTb)
		end
	else
		for _, buff in self:iterBuffs() do
			if buffIds[buff.id] then
				buff:over(overTb)
			end
		end
	end
end

function ObjectModel:getBuffOverlayCount(buffCsvID)
	local buff = self:getBuff(buffCsvID)

	if not buff then
		return 0
	end

	return buff:getOverLayCount()
end

function ObjectModel:getBuffGroupArgSum(arg, buffGroupID)
	local sum = 0

	if arg == "overlayCount" then
		local cfgIds = {}

		for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
			if not buff.isOver and not cfgIds[buff.cfgId] then
				sum = sum + buff:getOverLayCount()
				cfgIds[buff.cfgId] = true
			end
		end
	else
		for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
			if not buff.isOver then
				sum = sum + buff[arg]
			end
		end
	end

	return sum
end

function ObjectModel:getBuffGroupFuncSum(funcName, buffGroupID)
	local sum = 0

	for k, buff in self:queryBuffsWithGroup(buffGroupID):order_pairs() do
		if not buff.isOver then
			sum = sum + buff[funcName](buff)
		end
	end

	return sum
end

function ObjectModel:getNatureType(idx)
	if idx then
		return self:getNature(idx)
	end

	return self:getNature(table.length(self.natures))
end

function ObjectModel:ipairsNature(isRestraint)
	local idx = 0
	local nature

	return function()
		idx = idx + 1
		nature = self:getNature(idx, isRestraint)

		if nature then
			return idx, nature
		end
	end
end

function ObjectModel:natureIntersection(natures)
	for idx, nature in self:ipairsNature() do
		if battleEasy.intersection({
			nature
		}, natures) then
			return true
		end
	end

	return false
end

function ObjectModel:natureSubset(natures)
	for idx, nature in self:ipairsNature() do
		if battleEasy.subset({
			nature
		}, natures) == false then
			return false
		end
	end

	return true
end

function ObjectModel:getNature(idx, isRestraint)
	local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeObjNature)

	if buffData.getType then
		local type = buffData:getType(idx)

		if type and type > 0 then
			return type
		end
	end

	if isRestraint == nil then
		isRestraint = false
	end

	if not self.natures[idx] and isRestraint == false then
		local buffData = self:getOverlaySpecBuffData(battle.OverlaySpecBuff.addNature)

		idx = idx - table.length(self.natures)

		if buffData.natureTotal and buffData.natureTotal[idx] then
			return buffData.natureTotal[idx].nature
		end
	end

	return self.natures[idx]
end

function ObjectModel:getExtraRound(excludeExtraBattleRound)
	local round = 0

	round = round + (self:getEventByKey(battle.ExRecordEvent.rebornRound) or 0)

	if excludeExtraBattleRound then
		round = round - (self:getEventByKey(battle.ExRecordEvent.extraBattleRound) or 0)
	end

	return round
end

function ObjectModel:getBattleRound(skillTimePos, excludeExtraBattleRound)
	local round = skillTimePos == 1 and self.battleRound[1] or self.battleRound[2]

	return round + self:getExtraRound(excludeExtraBattleRound)
end

function ObjectModel:getBattleRoundAllWave(skillTimePos, excludeExtraBattleRound)
	local round = skillTimePos == 1 and self.battleRoundAllWave[1] or self.battleRoundAllWave[2]

	return round + self:getExtraRound(excludeExtraBattleRound)
end

function ObjectModel:getRealPos()
	return self.seat
end

function ObjectModel:frontOrBack()
	if self.seat <= 3 or self.seat <= 9 and self.seat >= 7 then
		return 1
	else
		return 2
	end
end

function ObjectModel:updAttackerCurSkillTab(skill, isDelete)
	if not skill:isNormalSkillType() then
		return
	end

	local curSkill = self:getAttackerCurSkill()

	if isDelete then
		if curSkill and curSkill.id == skill.id and curSkill.owner.id == skill.owner.id then
			table.remove(self.attackerCurSkill, index)
		end
	elseif not curSkill or curSkill and curSkill.id ~= skill.id and curSkill.owner.id ~= skill.owner.id then
		table.insert(self.attackerCurSkill, skill)
	end
end

function ObjectModel:getAttackerCurSkill()
	local index = table.length(self.attackerCurSkill)

	return self.attackerCurSkill[index]
end

function ObjectModel:getStar(isOrigin)
	if isOrigin == true then
		return self.star
	end

	local changeToEnemyData = self:getFrontOverlaySpecBuff("changeToRandEnemyObj")
	local star = 9999

	if changeToEnemyData and changeToEnemyData.star then
		star = changeToEnemyData.star
	end

	return math.min(self.star, star)
end

function ObjectModel:findTagSkill(skillID, isOrigin)
	if isOrigin == true then
		return self.tagSkills[skillID]
	end

	local changeToEnemyData = self:getFrontOverlaySpecBuff("changeToRandEnemyObj")
	local changeFlag = true

	if changeToEnemyData and changeToEnemyData.tagSkills then
		changeFlag = changeToEnemyData.tagSkills[skillID]
	end

	return changeFlag and self.tagSkills[skillID]
end

function ObjectModel:cantBeSelectCheck(env)
	local ignoreBuff = env.ignoreBuff or {}

	for _, data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj) do
		return true
	end

	for _, data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj) do
		local continue = false

		if ignoreBuff.stealth and battleEasy.buffFilter(data.group, ignoreBuff.stealth[1], data.buff.csvCfg.buffFlag, ignoreBuff.stealth[2], data.cfgId, ignoreBuff.stealth[3]) then
			continue = true
		end

		if continue == false then
			if battleEasy.isSameSkillType(env.skillFormulaType, battle.SkillFormulaType.resumeHp) then
				if data.cantBeHealHintSwitch or env.fromObj.force ~= self.force then
					return true
				end
			elseif env.skillFormulaType == nil or battleEasy.isSameSkillType(env.skillFormulaType, battle.SkillFormulaType.damage) then
				return true
			end
		end
	end

	for _, data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
		if battleEasy.isSameSkillType(env.skillFormulaType, battle.SkillFormulaType.resumeHp) then
			if data.cantBeHealHintSwitch then
				return true
			end
		elseif env.skillFormulaType == nil or battleEasy.isSameSkillType(env.skillFormulaType, battle.SkillFormulaType.damage) then
			return true
		end
	end

	if self.scene:isBackHeros(self) then
		return true
	end

	return false
end

local CantAttackCheckNames = {
	"stun",
	"changeImage",
	"freeze",
	"sleepy"
}

function ObjectModel:cantAttackCheck(env)
	local ignoreGroups
	local lastInfo = self.scene:getSpecialSceneInfo()

	if lastInfo then
		ignoreGroups = lastInfo.data.ignoreGroups
	end

	local function checkNotIgnoreGroup(group)
		if not ignoreGroups then
			return true
		end

		if ignoreGroups[group] then
			return false
		end

		return true
	end

	for _, data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj) do
		if not data.canAttack and checkNotIgnoreGroup(data.group) then
			return true
		end
	end

	for _, data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
		if not data.canAttack and checkNotIgnoreGroup(data.group) then
			return true
		end
	end

	for _, specBuffName in ipairs(CantAttackCheckNames) do
		for __, data in self:ipairsOverlaySpecBuff(specBuffName) do
			if checkNotIgnoreGroup(data.group) then
				return true
			end
		end
	end

	return false
end

function ObjectModel:cantAttackCheck1(env)
	local leaveCheck = false

	for _, data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj) do
		if not data.canAttack then
			leaveCheck = true
		end
	end

	for _, data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
		if not data.canAttack then
			leaveCheck = true
		end
	end

	if self:checkOverlaySpecBuffExit("stun") or self:checkOverlaySpecBuffExit("changeImage") or self:checkOverlaySpecBuffExit("freeze") or self:checkOverlaySpecBuffExit("sleepy") or leaveCheck then
		return true
	end

	return false
end

function ObjectModel:cantBeAddBuffCheck(env)
	if not env.fromObj or env.fromObj.id ~= self.id then
		for _, data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj, env) do
			return true
		end

		for _, data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj, env) do
			if data.cantBeAttackSwitch then
				if data.cantBeAddBuffSwitch then
					return true
				elseif not data.cantBeAddBuffSwitch and env.fromObj and env.fromObj.force ~= self.force then
					return true
				end
			end
		end

		for _, data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj, env) do
			if data.leaveSwitch then
				return true
			end

			if data.cantBeAttackSwitch then
				if data.cantBeAddBuffSwitch then
					return true
				elseif not data.cantBeAddBuffSwitch and env.fromObj and env.fromObj.force ~= self.force then
					return true
				end
			end
		end
	end

	return false
end

function ObjectModel:cantBeAttackCheck(env)
	local ignoreBuff = env.ignoreBuff or {}

	for _, data in self:ipairsOverlaySpecBuffTo("leave", env.fromObj) do
		return true
	end

	for _, data in self:ipairsOverlaySpecBuffTo("stealth", env.fromObj) do
		local continue = false

		if ignoreBuff.stealth and battleEasy.buffFilter(data.group, ignoreBuff.stealth[1], data.buff.csvCfg.buffFlag, ignoreBuff.stealth[2], data.cfgId, ignoreBuff.stealth[3]) then
			continue = true
		end

		if continue == false and data.cantBeAttackSwitch then
			return true
		end
	end

	for _, data in self:ipairsOverlaySpecBuffTo("depart", env.fromObj) do
		if data.cantBeAttackSwitch then
			return true
		end
	end

	return false
end

function ObjectModel:cantUseSkillCheck(env)
	for _, data in self:ipairsOverlaySpecBuff("seal") do
		if env.skillId and data.closeSkill[env.skillId] then
			return true, data.showInfo
		end

		if env.skillType2 and data.closeSkillType2[env.skillType2] then
			return true, data.showInfo
		end
	end

	if self:checkOverlaySpecBuffExit("silence") then
		for _, data in self:ipairsOverlaySpecBuff("silence") do
			if env.skillId and data.closeSkill[env.skillId] then
				return true
			end

			if env.skillType2 and data.closeSkillType2[env.skillType2] then
				return true
			end
		end
	end

	local controlData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.controlEnemy)

	if controlData and env.skillType2 and controlData.closeSkillType2[env.skillType2] then
		return true
	end

	if self:checkOverlaySpecBuffExit("confusion") then
		for _, data in self:ipairsOverlaySpecBuff("confusion") do
			local cantChange = controlData and controlData.ignoreConfusionGroups[data.buff:group()]

			if not cantChange and env.skillType2 and data.closeSkillType2[env.skillType2] then
				return true
			end
		end
	end

	if env.skillType2 then
		if self:currentExtraBattleData().closeSkillType2 and self:currentExtraBattleData().closeSkillType2[env.skillType2] then
			return true
		end

		if self:isSKillType2Close(env.skillType2) then
			return true
		end
	end

	local forceSneerData = self:isBeInForceSneer()

	if forceSneerData and forceSneerData.closeSkillType2[env.skillType2] then
		return true
	end

	return false
end

local logicStateExtraCheck = {
	[battle.ObjectLogicState.cantBeSelect] = ObjectModel.cantBeSelectCheck,
	[battle.ObjectLogicState.cantAttack] = ObjectModel.cantAttackCheck,
	[battle.ObjectLogicState.cantBeAddBuff] = ObjectModel.cantBeAddBuffCheck,
	[battle.ObjectLogicState.cantBeAttack] = ObjectModel.cantBeAttackCheck,
	[battle.ObjectLogicState.cantUseSkill] = ObjectModel.cantUseSkillCheck
}

function ObjectModel:isLogicStateExit(index, env)
	return logicStateExtraCheck[index](self, env or {})
end

function ObjectModel:addExRecord(eventName, args, ...)
	self.scene.extraRecord:addExRecord(eventName, args, self.id, ...)
end

function ObjectModel:getEventByKey(eventName, ...)
	return self.scene.extraRecord:getEventByKey(eventName, self.id, ...)
end

function ObjectModel:cleanEventByKey(eventName, ...)
	return self.scene.extraRecord:cleanEventByKey(eventName, self.id, ...)
end

function ObjectModel:effectPowerControl(key, triggerPoint, env)
	local function dealFunc(obj, newKey)
		if not obj then
			return true
		end

		assertInWindows(obj.effectPower, "effectPower is nil?! key:%s unitID:%d", newKey, obj.unitID)

		local controlEvent = obj.effectPower[newKey]

		if not controlEvent then
			return true
		end

		if type(controlEvent) == "table" then
			if triggerPoint and controlEvent[triggerPoint] == 0 then
				return false
			end
		elseif controlEvent == 0 then
			return false
		end

		return true
	end

	local ret = dealFunc(self, key)

	if not ret then
		return ret
	end

	if env and env.killedTargets then
		local allFalse = false
		local hasTarget = false

		for _, target in pairs(env.killedTargets) do
			allFalse = dealFunc(target, key .. "KilledTarget") or allFalse
			hasTarget = true
		end

		if hasTarget and not allFalse then
			return false
		end
	end

	local killAddMp1Fix

	if key == battle.EffectPowerType.killAddMp1 then
		killAddMp1Fix = self.effectPower.killAddMp1Fix or 1
	end

	return true, killAddMp1Fix
end

function ObjectModel:serverForce()
	return self.scene.play.operateForce == 1 and self.force or 3 - self.force
end

function ObjectModel:serverSeat()
	return self.scene.play.operateForce == 1 and self.seat or battleEasy.mirrorSeat(self.seat)
end

function ObjectModel:getTakeDamageRecord(valueKey, needCurWave)
	local sumTakeDamage = 0

	if needCurWave then
		sumTakeDamage = self:getTotalTakeDamage():get(valueKey)
	else
		for _, v in pairs(self.totalTakeDamage) do
			sumTakeDamage = sumTakeDamage + v:get(valueKey)
		end
	end

	return sumTakeDamage
end

function ObjectModel:getAllTakeDamageRecord(force, valueKey, needCurWave)
	local function calTakeDamage(obj, needCurWave, valueKey)
		local sumTakeDamage = 0

		if needCurWave then
			sumTakeDamage = obj:getTotalTakeDamage():get(valueKey)
		else
			for _, v in pairs(obj.totalTakeDamage) do
				sumTakeDamage = sumTakeDamage + v:get(valueKey)
			end
		end

		return sumTakeDamage
	end

	local sumAllTakeDamage = 0

	for _, obj in self.scene:getHerosMap(force):order_pairs() do
		sumAllTakeDamage = sumAllTakeDamage + calTakeDamage(obj, needCurWave, valueKey)
	end

	local deadTb = self.scene.extraRecord:getEventByKey(battle.ExRecordEvent.deadTakeDamage, force)

	if deadTb then
		for _, wave in ipairs(deadTb) do
			for _, obj in pairs(wave) do
				sumAllTakeDamage = sumAllTakeDamage + calTakeDamage(obj, needCurWave, valueKey)
			end
		end
	end

	return sumAllTakeDamage
end

function ObjectModel:getTotalTakeDamage()
	local curWave = self.scene.play.curWave

	if not self.totalTakeDamage[curWave] then
		self.totalTakeDamage[curWave] = battleEasy.valueTypeTable()
	end

	return self.totalTakeDamage[curWave]
end

function ObjectModel:needAlterAttackTurn()
	if not self.curSkill then
		return false
	end

	local target = self:getCurTarget()

	if target and self:isSameForce(target.force) and self.curSkill:isSameType(battle.SkillFormulaType.damage) then
		return true
	end

	return false
end

function ObjectModel:triggerOriginEnvCheck(typ, val)
	if self.triggerEnv[typ]:empty() then
		return false
	end

	return self.triggerEnv[typ]:front() == val
end

function ObjectModel:updateSkillState(isSelfTurn)
	self.skillsMap = {}

	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end
end

function ObjectModel:hpForSpecialCheck()
	local discount1 = self.effectPower[battle.EffectPowerType.hpFixedDiscount] or 1
	local discount2 = 1
	local hpFormulaDiscount = self.effectPower[battle.EffectPowerType.hpFormulaDiscount]

	if hpFormulaDiscount then
		local findTarget
		local needUnitID = self.effectPower[battle.EffectPowerType.needUnitID]

		if needUnitID then
			for _, target in self.scene:ipairsAllHeros() do
				if target.force == self.force and target.originUnitID == needUnitID then
					findTarget = target
				end
			end
		end

		self.protectedEnv:resetEnv()

		local env = battleCsv.fillFuncEnv(self.protectedEnv, {
			findTarget = findTarget
		})

		discount2 = battleCsv.doFormula(hpFormulaDiscount, env)
	end

	return self:hp() * discount1 * discount2
end

function ObjectModel:getBaseAttr(attr)
	if self.multiShapeTb then
		return self.multiShapeTb[1] == 1 and self.attrs.base[attr] or self.attrs.base2[attr]
	end

	return self.attrs.base[attr]
end

function ObjectModel:getBuffAttr(attr)
	return self.attrs.buff[attr]
end

function ObjectModel:getRealFinalAttr(attr)
	if self.multiShapeTb then
		return self.multiShapeTb[1] == 1 and self.attrs.final[attr] or self.attrs:getBase2RealFinalAttr(attr)
	end

	return self.attrs.final[attr]
end

local gateAddMp1FixFuncs = {
	[game.GATE_TYPE.crossArena] = function(attacker)
		local scene = attacker.scene
		local correctCfg = scene:getSceneAttrCorrect(attacker:serverForce())
		local slayAddMp1Fix = 1

		if scene.play.curWave == 1 or scene.play.curWave == 3 then
			slayAddMp1Fix = correctCfg.slayAddMp1Fix and correctCfg.slayAddMp1Fix[1] or 1
		else
			slayAddMp1Fix = correctCfg.slayAddMp1Fix and correctCfg.slayAddMp1Fix[2] or 1
		end

		return slayAddMp1Fix
	end
}

local function addObjMp1(obj, addValue)
	local mp1Correct = addValue * (1 + obj:mp1Recover())

	obj:addMP1(mp1Correct)
end

function ObjectModel:addAttackerMpOnSelfDead(attacker)
	local canAddMp1, effectPowerFix = self:effectPowerControl(battle.EffectPowerType.killAddMp1)

	if not attacker or attacker.id == self.id or not canAddMp1 then
		return
	end

	local gateFix = gateAddMp1FixFuncs[self.scene.gateType] and gateAddMp1FixFuncs[self.scene.gateType](attacker) or 1
	local baseAddMp1 = gCommonConfigCsv and gCommonConfigCsv.slayAddMp or 0
	local finalAddMp1 = math.floor(baseAddMp1 * gateFix * effectPowerFix)

	addObjMp1(attacker, finalAddMp1)
	battleEasy.deferNotify(nil, "showMP1Award", {
		mp = ":" .. tostring(finalAddMp1),
		key = tostring(attacker)
	})

	if attacker.curSkill and attacker.curSkill.skillType == battle.SkillType.NormalCombine then
		local combineObj = attacker.combineObj

		addObjMp1(combineObj, finalAddMp1)
		battleEasy.deferNotify(nil, "showMP1Award", {
			mp = ":" .. tostring(finalAddMp1),
			key = tostring(combineObj)
		})
	end
end

function ObjectModel:getSummonerLevel()
	return self.level
end

function ObjectModel:setCsvObject(obj)
	self.csvObject = obj
end

function ObjectModel:getCsvObject()
	return self.csvObject
end

function ObjectModel:toHumanString()
	return string.format("ObjectModel: %s(%s)", self.id, self.seat)
end

function ObjectModel:isReadyForExtraAttack()
	return not self.isExtraAttackTurn and self.curExtraDataIdx > 0
end

function ObjectModel:cleanExRoundDataInDeath()
	if self:isRealDeath() then
		self:cleanExRoundData()

		return
	end

	if self:currentExtraBattleData().mode == battle.ExtraAttackMode.duel then
		return
	end

	if self:isReadyForExtraAttack() then
		local data = self.extraRoundData:index(self.curExtraDataIdx)

		self:addExRecord(battle.ExRecordEvent.extraAttackDataInFastReborn, data)
	end

	self:cleanExRoundData()
end

function ObjectModel:cleanExRoundData()
	self.scene:cleanObjInExtraRound(self)

	self.exAttackBattleTriggerRound = nil

	self:onExtraAttackEnd()
	self.extraRoundData:clear()
	self:resetExtraDataIdx()
end

function ObjectModel:resetExtraDataIdx()
	self.curExtraDataIdx = 0
	self.curExtraData = {}
end

function ObjectModel:getChangeUnitShowIcon()
	if self.multiShapeTb then
		return
	end

	local unitId = self.originUnitID
	local dataTb = self.changeUnitIDTb
	local n = table.length(dataTb)

	for k = n, 1, -1 do
		if not dataTb[k].showBeforeIcon then
			unitId = dataTb[k].unitId

			break
		end
	end

	return csv.unit[unitId].icon
end

function ObjectModel:isNormalSelectable()
	return true
end

function ObjectModel:getNormalSelectExObjs()
	local ret = {}

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		if data.caster:isNormalSelectable() and data.caster.seat == self.seat then
			table.insert(ret, data.caster)
		end
	end

	return ret
end

function ObjectModel:isExtraObj()
	return self.followMark ~= -1
end

function ObjectModel:onLeaveSeat(buffInfo)
	local forceMap = {}
	local force = self.seat <= 6 and 1 or 2

	forceMap[force] = true

	self.scene:triggerWhenSeatEmpty(forceMap, self.seat, buffInfo)
end

function ObjectModel:hasExtraOccupiedSeat()
	return self.effectPower.occupiedSeat[1] ~= 0
end

function ObjectModel:changeViewSeat(seat)
	battleEasy.queueEffect(function()
		self.view:proxy():moveToPosIdx(seat)
		self.view:proxy():setSeat(seat)
	end)

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		data.caster:syncViewSeat()
	end
end

function ObjectModel:toString()
	return "Object_" .. self.id
end

function ObjectModel:recordRoundAttackedData(roundData)
	if not roundData then
		-- errorInWindows("not extra attack battle round but extraBattleRoundData is nil!")

		return
	end

	if roundData.mode and roundData.mode ~= battle.ExtraBattleRoundMode.normal then
		return
	end

	self:addExRecord(battle.ExRecordEvent.attackedRoundRecord, self.scene.play:getTotalRounds())
end

function ObjectModel:getDamageRecord(valueKey)
	local sumDamage = 0

	for _, v in pairs(self.totalDamage) do
		sumDamage = sumDamage + v:get(valueKey)
	end

	return sumDamage
end
