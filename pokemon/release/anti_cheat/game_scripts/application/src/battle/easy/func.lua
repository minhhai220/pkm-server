function battleEasy.randomGetByArray(datas, limit, judge, switch)
	local ret = {}
	local count = table.length(datas)

	switch = switch or function(v)
		return v
	end
	judge = judge or function()
		return ymrand.random() > 0.5
	end

	for i = 1, table.length(datas) do
		if count <= limit or judge(datas[i]) then
			limit = limit - 1

			table.insert(ret, switch(datas[i], table.length(ret) + 1))
		end
	end

	return ret
end

function battleEasy.groupRelationInclude(t, v)
	for _, tb in ipairs(t) do
		if tb[v] then
			return true
		end
	end

	return false
end

function battleEasy.intersection(s1, s2, hashed)
	if not s1 or not s2 then
		return false
	end

	if type(s1) ~= "table" or type(s2) ~= "table" then
		errorInWindows("please check afferent set s1:%s, s2:%s", type(s1), type(s2))

		return false
	end

	local s1Map = s1

	if not hashed then
		s1Map = arraytools.hash(s1)
	end

	for _, v in ipairs(s2) do
		if s1Map[v] then
			return true
		end
	end

	return false
end

function battleEasy.numEqual(num1, num2)
	return math.abs(num1 - num2) < 1e-05
end

function battleEasy.ifElse(pred, tv, fv)
	if pred then
		return tv
	end

	return fv
end

function battleEasy.getSkillTab(unitId, passPassiveSkill)
	local unitCfg = csv.unit[unitId]
	local skill = csv.skill
	local skillMap = {}

	if not unitCfg then
		errorInWindows("getSkillTab %d unitCfg exit nil", unitId)
	end

	if unitCfg then
		for _, skillId in ipairs(unitCfg.skillList) do
			skillMap[skillId] = skill[skillId].skillType2
		end

		if passPassiveSkill then
			return skillMap
		end

		for _, skillId in ipairs(unitCfg.passiveSkillList) do
			skillMap[skillId] = battle.MainSkillType.PassiveSkill
		end

		for _, skillId in ipairs(unitCfg.fakePassiveSkillList) do
			skillMap[skillId] = battle.MainSkillType.PassiveSkill
		end
	end

	return skillMap
end

function battleEasy.checkSkillMatch(unitID, spellSkillID)
	local unitCfg = csv.unit[unitID]
	local cardCfg = csv.cards[unitCfg.cardID]

	if not unitCfg then
		errorInWindows("checkSkillMatch %d unitCfg exit nil", unitID)
	end

	if unitCfg then
		for _, skillId in ipairs(unitCfg.skillList) do
			if spellSkillID == skillId then
				return true
			end
		end

		for _, skillId in ipairs(unitCfg.extraSkillList) do
			if spellSkillID == skillId then
				return true
			end
		end

		local aidID = cardCfg and cardCfg.aidID or 0

		if aidID ~= 0 and (csv.aid.aid_skill[aidID].skillID == spellSkillID or csv.aid.aid_skill[aidID].skin2SkillID[unitID] == spellSkillID or csv.aid.aid_skill[aidID].devSkillID[cardCfg.develop] == spellSkillID) then
			return true
		end
	end

	return false
end

function battleEasy.getItemInPowerMap(ret, powerRet)
	local sum = 0

	for i, v in pairs(powerRet) do
		if v and ret[i] then
			sum = sum + v
		end
	end

	local num = ymrand.random()
	local radio = 0

	for i = 1, table.length(powerRet) do
		if ret[i] then
			radio = powerRet[i] / sum

			if num <= radio then
				return ret[i]
			else
				num = num - radio
			end
		end
	end
end

function battleEasy.isSameSkillType(typ1, typ2)
	if typ1 == battle.SkillFormulaType.fix then
		return true
	end

	if typ2 == battle.SkillFormulaType.fix then
		return true
	end

	return typ1 == typ2
end

function battleEasy.isCompleteLeave(obj)
	for _, data in obj:ipairsOverlaySpecBuff("leave") do
		return true
	end

	for _, data in obj:ipairsOverlaySpecBuff("depart") do
		if data.leaveSwitch then
			return true
		end
	end

	return false
end

function battleEasy.getUnifyBuffArgs(type, data, exArgs, env)
	local args = {
		buffValueFormulaEnv = env
	}

	if type == "skill_process" then
		args.buffValueFormula = data.buffValue1[exArgs.index]
	elseif type == "buff" then
		args.value = data.value
		args.buffValueFormula = data.buffValueFormula
		args.skillCfg = data.skillCfg
	end

	for k, v in pairs(exArgs) do
		args[k] = v
	end

	return args
end

function battleEasy.getRoundTriggerId(cfgId)
	for k, v in pairs(gExtraRoundTrigger) do
		if v.cfgIds[cfgId] then
			return k
		end
	end
end

function battleEasy.getOverlayLimit(caster, holder, buffCfg)
	local ret = buffCfg.overlayLimit
	local extraOverlayLimit = buffCfg.extraOverlayLimit
	local trigger = extraOverlayLimit.trigger == 1 and caster or holder

	if not csvNext(extraOverlayLimit) or not trigger then
		return ret
	end

	local star = extraOverlayLimit.star

	if star and trigger.star >= star[1] then
		ret = ret + star[2]
	end

	local zawake = extraOverlayLimit.zawake

	if zawake then
		for k = 79000 + zawake[1], 79004 do
			if trigger.tagSkills[k] then
				ret = ret + zawake[2]

				break
			end
		end
	end

	return ret
end

function battleEasy.getSummonAttr(summoner, data, specialChange)
	local value = data

	if specialChange >= 0 then
		value = value * specialChange
	else
		value = 0

		for _, obj in summoner.scene:getHerosMap(summoner.force):order_pairs() do
			for _, buff in obj:iterBuffsWithEasyEffectFunc("buffRecord") do
				local recordList = buff:getEventByKey(battle.ExRecordEvent.buffRecord) or {}

				if recordList[specialChange .. summoner.id] then
					value = value + recordList[specialChange .. summoner.id]
				end
			end
		end
	end

	return value
end

function battleEasy.getSummonRoleOut(summonArgs, summoner)
	local summonUnitId = summonArgs[1]
	local noPassive = summonArgs[11] == 1
	local summonLevel = battleEasy.ifElse(summonArgs[3] > 0, summonArgs[3], summoner:getSummonerLevel())
	local csvData = csv.unit[summonUnitId]
	local modeArgs = summonArgs[8] or {}
	local effectSeatType = modeArgs.posType or 1
	local data = {
		noAddWeather = true,
		skills = {},
		passiveSkills = {},
		cardId = csvData.cardID,
		roleId = summonUnitId,
		level = summonLevel,
		skillLevel = summonLevel,
		fightPoint = summoner.fightPoint,
		star = summoner.star,
		type = battle.ObjectClass.Summon,
		mode = summonArgs[7] or battle.ObjectType.Normal,
		modeArgs = modeArgs,
		waveGoonDel = summonArgs[9] == 1,
		isFollowObject = effectSeatType == 1,
		viewCfg = {
			effectSeatType = effectSeatType,
			offsetPos = cc.p(0, 0)
		}
	}

	data.followMark = modeArgs.followMark or 1
	data.selectEnable = modeArgs.isNormalSelectable == 1
	data.noPassive = noPassive

	if data.mode ~= battle.ObjectType.Normal then
		data.viewCfg.offsetPos = cc.p(modeArgs.x or -100, modeArgs.y or 100)
	end

	local ownerAttr = summoner.attrs:cloneFinalAttr()
	local summonAttrRate = summonArgs[4]
	local summonSpecialRate = summonArgs[6] or {}

	for attr, v in pairs(ownerAttr) do
		data[attr] = v

		if summonSpecialRate[attr] then
			data[attr] = battleEasy.getSummonAttr(summoner, v, summonSpecialRate[attr])
		elseif ObjectAttrs.SixDimensionAttrs[attr] then
			data[attr] = data[attr] * summonAttrRate
		elseif summonSpecialRate.specialDefault then
			data[attr] = data[attr] * summonSpecialRate.specialDefault
		end
	end

	data.hp = data.hpMax
	data.mp1 = data.mp1Max
	data.hpScale = summoner.hpScale
	data.mp1Scale = summoner.mp1Scale

	local function inheritZawake(skillId)
		local skillCfg = csv.skill[skillId]
		local zawakeID = skillCfg.zawakeEffect[1]

		if zawakeID and summoner.tagSkills[zawakeID] then
			data.skills[zawakeID] = summonLevel
		end
	end

	for _, v in ipairs(csvData.skillList) do
		data.skills[v] = summonLevel

		inheritZawake(v)
	end

	if not noPassive then
		for _, v in ipairs(csvData.passiveSkillList) do
			data.passiveSkills[v] = summonLevel

			inheritZawake(v)
		end

		for id, v in pairs(summoner.passiveSkills) do
			local skillCfg = csv.skill[id]

			if skillCfg and skillCfg.summonInherit then
				data.skills[id] = summonLevel

				inheritZawake(id)
			end
		end
	end

	return data
end

function battleEasy.loseImmuneEfficacyCheck(holder, buffInfo, attrInfo)
	local loseEfficacy = holder:getFrontOverlaySpecBuff("loseImmuneEfficacy")

	if not loseEfficacy then
		return false
	end

	local buffGroup = loseEfficacy.buffGroups[buffInfo.indexGroup] or {}

	if itertools.include(loseEfficacy.buffCfgId, buffInfo.cfgId) or itertools.include(loseEfficacy.buffType, buffInfo.type) or itertools.include(buffGroup, buffInfo.group) then
		return true
	end

	if attrInfo then
		for _, attr in pairs(attrInfo) do
			if itertools.include(loseEfficacy.attr, attr) then
				return true
			end
		end
	end

	return false
end

function battleEasy.attackRangeExtension(env, originRet)
	if not env.addAttackRangeObjs then
		return originRet
	end

	local ret = {}

	itertools.each(env.addAttackRangeObjs, function(_, obj)
		if not obj:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = env.self
		}) then
			table.insert(ret, obj)
		end
	end)
	table.sort(ret, function(a, b)
		return a.id < b.id
	end)

	for _, obj in ipairs(originRet) do
		if not env.addAttackRangeObjs[obj.id] then
			table.insert(ret, obj)
		end
	end

	return ret
end

function battleEasy.deepcopy_args(args)
	local _args = table.deepcopy(args, true)

	_args.specialFrom = nil

	return _args
end

function battleEasy.addBuffToFunc(isGlobal, id, holder, caster, args)
	local addBuffFunc = isGlobal and addBuffToScene or addBuffToHero

	return addBuffFunc(id, holder, caster, args)
end

function battleEasy.keyToID(key, model)
	if key == "id" then
		return model.id
	end

	return key
end

local function _checkBuffGroup(buffGroup, groups)
	if buffGroup and groups and table.length(groups) > 0 and itertools.include(groups, buffGroup) then
		return true
	end

	return false
end

local function _checkBuffFlags(buffFlags, flags)
	if buffFlags and flags and table.length(flags) > 0 and battleEasy.intersection(flags, buffFlags) then
		return true
	end

	return false
end

local function _checkBuffCfgIds(buffCfgID, ids)
	if buffCfgID and ids and table.length(ids) > 0 and itertools.include(ids, buffCfgID) then
		return true
	end

	return false
end

function battleEasy.buffFilter(buffGroup, checkGroups, buffFlags, checkFlags, buffCfgID, checkIds, mixType)
	mixType = mixType or 1

	local results = {
		_checkBuffGroup(buffGroup, checkGroups),
		_checkBuffFlags(buffFlags, checkFlags),
		_checkBuffCfgIds(buffCfgID, checkIds)
	}
	local ret = false

	for _, r in ipairs(results) do
		if mixType == 1 then
			if r then
				return true
			end
		elseif mixType == 2 then
			ret = true

			if r then
				return false
			end
		end
	end

	return ret
end

function battleEasy.checkAidData(aidData)
	local unitCfg = csv.unit[aidData.roleId]
	local cardCfg = csv.cards[unitCfg and unitCfg.cardID]
	local aidCfg = csv.aid.aid_skill[cardCfg and cardCfg.aidID]
	local aidSkillID

	if aidCfg then
		aidSkillID = aidCfg.skillID

		if aidData.skills[aidSkillID] or aidData.passive_skills[aidSkillID] then
			return true
		end
	end

	errorInWindows("aidData check failed unitID(%s) aidID(%s) skillID(%s)", aidData.roleId, cardCfg and cardCfg.aidID, aidSkillID)

	return false
end

function battleEasy.buffFilterEasy(buff, checkGroups, checkFlags, checkIds, mixType)
	return battleEasy.buffFilter(buff:group(), checkGroups, buff:buffFlag(), checkFlags, buff.cfgId, checkIds, mixType)
end

function battleEasy.makeMultBattleConfig(csvCfg, fixedIndex, multKeyHash)
	if not csvCfg then
		return
	end

	local cfg = {}
	local inputIndex

	function cfg.__index(t, k)
		local rawKey = k
		local index = inputIndex or fixedIndex

		if multKeyHash[k] and index then
			if index == 3 then
				rawKey = rawKey .. 3
			elseif index == 2 then
				rawKey = rawKey .. 2
			end
		end

		inputIndex = nil

		return csvCfg[rawKey]
	end

	function cfg.multAt(t, i)
		inputIndex = i

		return t
	end

	function cfg.multFixed(t, i)
		fixedIndex = i

		return t
	end

	function cfg.__newindex(t, k, v)
		error(string.format("cfg %s can not be write %s!", tostring(t), k))
	end

	return setmetatable(cfg, cfg)
end

local MonsterCsvKeyHash = {
	damageC = true,
	speedC = true,
	hpC = true,
	posAdjust = true,
	bossMark = true,
	monsters = true,
	specialDefenceC = true,
	defenceC = true,
	specialDamageC = true
}

function battleEasy.getMonsterCsv(sceneId, waveId, groupRound)
	return battleEasy.makeMultBattleConfig(gMonsterCsv[sceneId][waveId], groupRound, MonsterCsvKeyHash)
end

local SceneConfCsvKeyHash = {
	demonCorrectSelf = true,
	demonCorrect = true,
	skillLevel = true,
	sceneLevel = true,
	showLevel = true,
	roundLimit = true,
	sceneCount = true,
	sceneLevelCorrect = true
}

function battleEasy.getSceneConfCsv(sceneId, groupRound)
	return battleEasy.makeMultBattleConfig(csv.scene_conf[sceneId], groupRound, SceneConfCsvKeyHash)
end

local EndlessTowerSceneCsvKeyHash = {
	showLevel = true,
	roundLimit = true,
	sceneCount = true,
	sceneLevel = true
}

function battleEasy.getEndlessTowerSceneCsv(isAbyss, sceneId, groupRound)
	-- if isAbyss then
		-- return battleEasy.makeMultBattleConfig(csv.abyss_endless_tower.scene[sceneId], groupRound, EndlessTowerSceneCsvKeyHash)
	-- else
		return battleEasy.makeMultBattleConfig(csv.endless_tower_scene[sceneId], groupRound, EndlessTowerSceneCsvKeyHash)
	-- end
end

local function buildRoleOutEnv(self, funcs)
	local ret = {
		targets = self.targets,
		BB = self.BB,
		exportData = self.exportData
	}

	for k, f in pairs(funcs) do
		ret[k] = f
	end

	ret.__index = ret

	function ret.__newindex(t, k, v)
		error(string.format("protected env %s can not be write %s!", tostring(t), k))
	end

	return ret
end

local RoleOutPack = {}

RoleOutPack.__index = RoleOutPack
RoleOutPack.targets = {}
RoleOutPack.BB = {}
RoleOutPack.exportData = {}

function battleEasy.initRoleOut(buff, inputTargets)
	RoleOutPack.targets = {}
	RoleOutPack.BB = {}
	RoleOutPack.exportData = {
		roleOut = {}
	}

	if inputTargets then
		for _, tar in ipairs(inputTargets) do
			table.insert(RoleOutPack.targets, tar)
		end
	end

	if buff then
		table.insert(RoleOutPack.targets, buff.holder)
		table.insert(RoleOutPack.targets, buff.caster)
	end

	RoleOutPack.BB.target = RoleOutPack.targets[1]
	RoleOutPack.BB.doFormula = functools.partial(buff.cfg2Value, buff)

	return buildRoleOutEnv(RoleOutPack, {
		fillSeat = RoleOutPack.fillSeat
	})
end

function RoleOutPack:fillSeat(index)
	local seat

	if type(index) == "number" then
		if index == 0 then
			for i = 1, self.BB.target.scene.play.ObjectNumber do
				if self.BB.target.scene:isSeatEmpty(i) then
					seat = i

					break
				end
			end
		end

		if seat == nil then
			seat = index
		end
	elseif type(index) == "table" then
		local target = self.targets[index[1]]

		if index[2] == 1 then
			seat = target.seat
		elseif index[2] == 2 then
			local stepNum = target.force == 1 and 0 or target.scene.play.ForceNumber
			local endNum = target.scene.play.ForceNumber + stepNum

			for i = 1 + stepNum, endNum do
				if target.scene:isSeatEmpty(i) then
					seat = i

					break
				end
			end
		elseif index[2] == 3 then
			local stepNum = 3 - target.force == 1 and 0 or target.scene.play.ForceNumber
			local endNum = target.scene.play.ForceNumber + stepNum

			for i = 1 + stepNum, endNum do
				if target.scene:isSeatEmpty(i) then
					seat = i

					break
				end
			end
		end
	end

	self.exportData.seat = seat

	return buildRoleOutEnv(RoleOutPack, {
		fillForce = RoleOutPack.fillForce
	})
end

function RoleOutPack:fillForce(index)
	local force

	if table.length(index) == 1 then
		force = index[1]
	else
		local target = self.targets[index[1]]

		if index[2] == 1 then
			force = target.force
		elseif index[2] == 2 then
			force = 3 - target.force
		end
	end

	if force ~= 1 and force ~= 2 and force ~= 3 then
		errorInWindows("buffFindForce index(%s) is not exit", dumps(index))
	end

	self.exportData.force = force

	return buildRoleOutEnv(RoleOutPack, {
		fillAttrs = RoleOutPack.fillAttrs
	})
end

local function calcAttrRate(formula, doFormula)
	if type(formula) == "string" then
		return doFormula(formula)
	end

	return formula
end

function RoleOutPack:fillAttrs(extendAttr)
	local commonFix = extendAttr[1]
	local anchorObj = self.targets[commonFix[2]]
	local finalAttr = anchorObj.attrs:cloneFinalAttr(commonFix[1])
	local otherDefaultFix, sixDimensionFix
	local specifyFix = {}

	for i = 2, table.length(extendAttr) do
		local attrData = extendAttr[i]
		local anchorObj_ = self.targets[attrData[3]] or anchorObj

		if attrData[1] == "otherDefault" then
			otherDefaultFix = anchorObj_.attrs:getSelfFinalAttr(attr) * calcAttrRate(attrData[2], self.BB.doFormula)
		elseif attrData[1] == "sixDimension" then
			sixDimensionFix = anchorObj_.attrs:getSelfFinalAttr(attr) * calcAttrRate(attrData[2], self.BB.doFormula)
		elseif attrData[3] == 4 then
			for _, obj in self.BB.target.scene:getHerosMap(self.BB.target.force):order_pairs() do
				for _, buff in obj:iterBuffsWithEasyEffectFunc("buffRecord") do
					local recordList = buff:getEventByKey(battle.ExRecordEvent.buffRecord) or {}

					if recordList[attrData[2] .. self.BB.target.id] then
						specifyFix[attr] = finalAttr[attr] + recordList[attrData[2] .. self.BB.target.id]
					end
				end
			end
		else
			local attr = attrData[1]

			specifyFix[attr] = anchorObj_.attrs:getSelfFinalAttr(attr) * calcAttrRate(attrData[2], self.BB.doFormula)
		end
	end

	for attr, v in pairs(finalAttr) do
		if ObjectAttrs.SixDimensionAttrs[attr] then
			if sixDimensionFix then
				self.exportData.roleOut[attr] = sixDimensionFix
			end
		elseif otherDefaultFix then
			self.exportData.roleOut[attr] = otherDefaultFix
		end

		if specifyFix[attr] then
			self.exportData.roleOut[attr] = specifyFix[attr]
		end

		if not self.exportData.roleOut[attr] then
			self.exportData.roleOut[attr] = v
		end
	end

	self.exportData.roleOut.hp = finalAttr.hpMax
	self.exportData.roleOut.mp1 = finalAttr.mp1Max

	return buildRoleOutEnv(RoleOutPack, {
		exportAsSummon = RoleOutPack.exportAsSummon,
		exportAsRole = RoleOutPack.exportAsRole
	})
end

local function inheritZawake(data, skillId, anchorObj, level)
	local skillCfg = csv.skill[skillId]
	local zawakeID = skillCfg.zawakeEffect[1]

	if zawakeID and anchorObj.tagSkills[zawakeID] then
		data.skills[zawakeID] = level
	end
end

function RoleOutPack:exportAsSummon(unitID, summoner, summonType, extraObjectCfgID, args)
	local exportData = self:exportAsRole(unitID)
	local roleOut = exportData.roleOut
	local unitCfg = csv.unit[unitID]

	roleOut.fightPoint = summoner.fightPoint
	roleOut.star = summoner.star

	local extraCfg = csv.extra_object[extraObjectCfgID]

	roleOut.followMark = extraCfg.followMark
	roleOut.selectEnable = extraCfg.selectEnable == 1
	roleOut.noPassive = extraCfg.noPassive == 1
	roleOut.noAddWeather = extraCfg.noAddWeather == 1
	roleOut.waveGoonDel = extraCfg.waveGoonDel == 1
	roleOut.type = battle.ObjectClass.Summon
	roleOut.mode = summonType
	roleOut.isFollowObject = extraCfg.effectSeatType == 1
	roleOut.extraObjectCfgID = extraObjectCfgID
	roleOut.viewCfg = {
		effectSeatType = extraCfg.effectSeatType,
		offsetPos = cc.p(extraCfg.effectSeatOffsetPos[1], extraCfg.effectSeatOffsetPos[2])
	}
	roleOut.hpScale = summoner.hpScale
	roleOut.mp1Scale = summoner.mp1Scale

	local summonLevel = battleEasy.ifElse(args[1] > 0, args[1], summoner:getSummonerLevel())

	roleOut.level = summonLevel
	roleOut.skillLevel = summonLevel

	for _, v in ipairs(unitCfg.skillList) do
		roleOut.skills[v] = summonLevel

		inheritZawake(roleOut, v, summoner, summonLevel)
	end

	if extraCfg.noPassive == 1 then
		for _, v in ipairs(unitCfg.passiveSkillList) do
			roleOut.passiveSkills[v] = summonLevel

			inheritZawake(roleOut, v, summoner, summonLevel)
		end

		for id, v in pairs(summoner.passiveSkills) do
			local skillCfg = csv.skill[id]

			if skillCfg and skillCfg.summonInherit then
				roleOut.skills[id] = summonLevel

				inheritZawake(roleOut, id, summoner, summonLevel)
			end
		end
	end

	roleOut.summonGroup = self.targets[args[2]].summonGroup

	return exportData
end

function RoleOutPack:exportAsRole(unitID)
	local unitCfg = csv.unit[unitID]
	local exportData = self.exportData

	exportData.roleOut.skills = {}
	exportData.roleOut.passiveSkills = {}
	exportData.roleOut.cardId = unitCfg.cardID
	exportData.roleOut.roleId = unitID
	exportData.roleOut.type = battle.ObjectClass.Normal
	exportData.roleOut.mode = battle.ObjectType.Normal
	exportData.roleOut.level = 0
	exportData.roleOut.skillLevel = 0
	exportData.roleOut.fightPoint = 0
	exportData.roleOut.star = 0

	return exportData
end
