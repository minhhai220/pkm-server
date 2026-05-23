-- chunkname: @src.battle.csv.object

local CsvObjectExport = {
	hasTypeBuff = 0,
	isSelfChargeOK = 0,
	isSelfInCharging = 0,
	getSameBuffCount = 0,
	getBuffOverlayCount = 0
}
local CsvObject = battleCsv.newCsvCls("CsvObject")

CsvObject.ignoreModelCheck = {
	getBuff = true,
	attackerSkill = true,
	curSkill = true,
	selectCsvTarget = true
}
battleCsv.CsvObject = CsvObject

function CsvObject:skillLv(...)
	for _, id in ipairs({
		...
	}) do
		local skill = self.model.skills[id] or self.model.passiveSkills[id]

		if skill then
			return skill:getLevel()
		end
	end

	return 1
end

function CsvObject:selectCsvTarget()
	local targetModel = self.model and self.model:getCurTarget()

	if targetModel then
		return battleCsv.CsvObject.newWithCache(targetModel)
	end

	return battleCsv.NilObject
end

function CsvObject:checkIsSkillTarget()
	local curHero = self.model.scene.play.curHero

	return curHero and self.model.id == curHero.curTargetId
end

function CsvObject:getPossessTarget()
	local target = self.model and self.model:getEventByKey(battle.ExRecordEvent.possessTarget)

	if target then
		return battleCsv.CsvObject.newWithCache(target)
	end

	return battleCsv.NilObject
end

function CsvObject:attackMeDeadObj()
	local target = self.model and self.model.attackMeDeadObj

	if target then
		return battleCsv.CsvObject.newWithCache(target)
	end

	return battleCsv.NilObject
end

function CsvObject:getSummoner()
	local summoner = self.model and self.model:getEventByKey(battle.ExRecordEvent.summoner)

	if summoner then
		return battleCsv.CsvObject.newWithCache(summoner)
	end

	return battleCsv.NilObject
end

function CsvObject:isBeControlled()
	return self.model:isSelfControled() or self.model:isSelfForceConfusionAndNoTarget()
end

function CsvObject:skillCanUse(key)
	local data = key and {
		[key] = true
	} or {
		[battle.MainSkillType.SmallSkill] = true,
		[battle.MainSkillType.BigSkill] = true,
		[battle.MainSkillType.NormalSkill] = true
	}
	local switch = true

	for k, v in pairs(data) do
		if v then
			switch = switch and not self.model:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
				skillType2 = k
			})
		end
	end

	return switch
end

function CsvObject:isSameObj(obj)
	if not obj then
		return false
	end

	local id = obj.model and obj.model.id or obj.id

	return self.model.id == id
end

function CsvObject:nature(idx)
	return self.model:getNatureType(idx or 1)
end

function CsvObject:natureIntersection(natures)
	return self.model:natureIntersection(natures)
end

function CsvObject:id()
	return self.model.seat
end

function CsvObject:specSceneOriginSeat()
	local realSeat = self.model.seat
	local lastInfo = self.model.scene:getSpecialSceneInfo()

	if lastInfo then
		for seat, data in pairs(lastInfo.reserveSeatMap) do
			if data.obj and data.obj.id == self.model.id then
				realSeat = seat

				break
			end
		end
	end

	return realSeat
end

function CsvObject:cardID()
	return self.model.cardID
end

function CsvObject:unitID()
	return self.model.unitID
end

function CsvObject:originUnitId()
	return self.model.originUnitID
end

function CsvObject:markID()
	return self.model.markID
end

function CsvObject:star(isOrigin)
	return self.model:getStar(isOrigin == 1)
end

function CsvObject:rarity()
	return self.model.rarity
end

function CsvObject:flag(...)
	local flags = {
		...
	}

	for k, v in ipairs(flags) do
		if self.model.battleFlag[v] == true then
			return true
		end
	end

	return false
end

function CsvObject:level()
	return self.model.level
end

function CsvObject:force()
	return self.model.force
end

function CsvObject:followMark()
	return self.model.followMark or -1
end

function CsvObject:isRealDeath()
	return self.model:isRealDeath()
end

function CsvObject:isAlreadyDead()
	return self.model:isAlreadyDead()
end

function CsvObject:hp()
	return self.model:hp()
end

function CsvObject:lostHp()
	return math.max(0, self.model:hpMax() - self.model:hp())
end

function CsvObject:mp1()
	return self.model:mp1()
end

function CsvObject:indexInAttackerArray(needSelf, inSelfForce)
	local gate = self.model.scene.play
	local roundHasAttackedHistory = gate.roundHasAttackedHistory

	for _, obj in ipairs(roundHasAttackedHistory) do
		if obj.id == self.model.id then
			return 0
		end
	end

	local curLefts = itertools.filter(gate.roundLeftHeros, function(id, data)
		local obj = data.obj

		if not obj or obj:isRealDeath() then
			return nil
		end

		return data
	end)

	needSelf = needSelf or 0

	if not next(curLefts) then
		if needSelf == 1 then
			return 1
		end

		return 0
	end

	inSelfForce = inSelfForce or 0

	local tbForSort = {}
	local isIncludeSelf = false

	for k, v in ipairs(curLefts) do
		if inSelfForce == 0 or v.obj.force == self.model.force then
			local obj = v.obj
			local relatively = v.another and obj.unitID % 2 == 0

			isIncludeSelf = obj.id == self.model.id

			table.insert(tbForSort, {
				key = k,
				speedPriority = obj.speedPriority,
				speed = gate:getSpeedForRankSort(obj, relatively, v),
				objId = gate:getObjectBaseSpeedRankSortKey(obj),
				reset = v.reset,
				atOnce = v.atOnce,
				prophet = v.prophet,
				buffCfgId = v.buffCfgId,
				force = obj.force,
				geminiSpecialDeal = relatively and 1 or 2
			})
		end
	end

	if isIncludeSelf == false and needSelf == 1 then
		local obj = self.model

		table.insert(curLefts, {
			obj = obj
		})
		table.insert(tbForSort, {
			geminiSpecialDeal = 2,
			key = table.length(tbForSort) + 1,
			speedPriority = obj.speedPriority,
			speed = gate:getSpeedForRankSort(obj, false, v),
			objId = gate:getObjectBaseSpeedRankSortKey(obj),
			force = obj.force
		})
	end

	gate:speedRankSortWithRule(tbForSort)

	for k, v in ipairs(tbForSort) do
		local obj = curLefts[v.key].obj

		if obj.id == self.model.id then
			return k
		end
	end

	return 0
end

function CsvObject:getObjByFormula(oneOnly, input, process)
	local targets = battleTarget.targetFinder(self.model, nil, {
		input = input,
		process = process
	}, {})

	if oneOnly == 1 then
		return battleCsv.CsvObject.newWithCache(targets[1])
	end

	local ret = {}

	itertools.each(targets, function(idx, target)
		table.insert(ret, battleCsv.CsvObject.newWithCache(target))
	end)

	return ret
end

function CsvObject:mp1PointOrValue()
	local mp1PointData = self.model:getFrontOverlaySpecBuff("mp1OverFlow")

	if mp1PointData then
		local mpOverflow = self.model:mpOverflow()

		if mp1PointData.mode == 1 then
			return math.floor(mpOverflow / mp1PointData.rate)
		else
			return mpOverflow
		end
	end

	return 0
end

function CsvObject:curSkill()
	if self.model and self.model.curSkill then
		local skillModel = self.model.curSkill

		return battleCsv.CsvSkill.newWithCache(skillModel)
	end

	return battleCsv.NilSkill
end

function CsvObject:attackerSkill()
	if self.model and self.model.attackerCurSkill then
		local index = table.length(self.model.attackerCurSkill)
		local skillModel = self.model.attackerCurSkill[index]

		if skillModel then
			return battleCsv.CsvSkill.newWithCache(skillModel)
		end
	end

	return battleCsv.NilSkill
end

function CsvObject:getDamageStateByTarget(target, key)
	return self:curSkill():getDamageStateByTarget(target, key)
end

function CsvObject:getDamageState(key)
	for targetID, info in pairs(self.model.curSkill.targetsFinalResult) do
		local v = table.get(info, "args", key)

		if v then
			return v
		end
	end
end

function CsvObject:getDamageStateToMe(key)
	local index = table.length(self.model.attackerCurSkill)

	return table.get(self.model.attackerCurSkill, index, "targetsFinalResult", self.model.id, "args", key)
end

function CsvObject:getDispelSuccessCount()
	return self.model:getEventByKey(battle.ExRecordEvent.dispelSuccessCount) or 0
end

function CsvObject:hasSkill(...)
	for _, id in ipairs({
		...
	}) do
		local skill = self.model.skills[id] or self.model.passiveSkills[id]

		if skill then
			return true
		end
	end

	return false
end

function CsvObject:hasBuff(...)
	for _, id in ipairs({
		...
	}) do
		local buff = self.model:hasBuff(id)

		if buff then
			return true
		end
	end

	return false
end

function CsvObject:countBuff(...)
	local ret = 0

	for _, id in ipairs({
		...
	}) do
		local buff = self.model:hasBuff(id)

		if buff then
			ret = ret + 1
		end
	end

	return ret
end

function CsvObject:hasBuffGroup(...)
	for _, group in ipairs({
		...
	}) do
		if self.model:hasBuffGroup(group) then
			return true
		end
	end

	return false
end

function CsvObject:countBuffGroupClass(...)
	local ret = 0

	for _, group in ipairs({
		...
	}) do
		if self.model:hasBuffGroup(group) then
			ret = ret + 1
		end
	end

	return ret
end

function CsvObject:hasBuffFlag(...)
	for _, flag in ipairs({
		...
	}) do
		if self.model:hasBuffFlag(flag) then
			return true
		end
	end

	return false
end

function CsvObject:getBuff(buffCsvID)
	if self.model then
		local buffModel = self.model:getBuff(buffCsvID)

		if buffModel == nil then
			return battleCsv.NilBuff
		end

		return battleCsv.CsvBuff.newWithCache(buffModel)
	end

	return battleCsv.NilBuff
end

function CsvObject:getSkill(skillCsvID)
	if self.model then
		local skillModel = self.model.skills and self.model.skills[skillCsvID]

		if skillModel == nil then
			return battleCsv.NilSkill
		end

		return battleCsv.CsvSkill.newWithCache(skillModel)
	end

	return battleCsv.NilSkill
end

function CsvObject:sumBuffOverlayByGroup(...)
	local sum = 0

	for _, id in ipairs({
		...
	}) do
		sum = sum + self.model:getBuffGroupArgSum("overlayCount", id)
	end

	return sum
end

function CsvObject:sumBuffLifeRoundByGroup(...)
	local sum = 0

	for _, id in ipairs({
		...
	}) do
		sum = sum + self.model:getBuffGroupFuncSum("getLifeRound", id)
	end

	return sum
end

function CsvObject:frontOrBack()
	return self.model:frontOrBack()
end

function CsvObject:getFullShieldCaster()
	if self.model.caster then
		return battleCsv.CsvObject.newWithCache(self.model.caster)
	end

	return battleCsv.NilObject
end

function CsvObject:shieldHp(...)
	if ... then
		local mark = {}
		local hp = 0

		for _, cfgId in ipairs({
			...
		}) do
			mark[cfgId] = true
		end

		for _, data in self.model:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.shield) do
			if mark[data.cfgId] then
				hp = hp + math.max(data.shieldHp, 0)
			end
		end

		return hp
	else
		return self.model:shieldHp()
	end
end

function CsvObject:shieldHpByGroup(...)
	local shieldGroupList = {
		...
	}

	if next(shieldGroupList) then
		local mark = {}
		local hp = 0

		for _, group in ipairs(shieldGroupList) do
			mark[group] = true
		end

		for _, data in self.model:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.shield) do
			if mark[data.group] then
				hp = hp + math.max(data.shieldHp, 0)
			end
		end

		return hp
	else
		return self.model:shieldHp()
	end
end

function CsvObject:lockHpShieldHp()
	local buffData = self.model:getOverlaySpecBuffData(battle.OverlaySpecBuff.lockHpShield)

	return buffData and buffData.shieldTotal or 0
end

function CsvObject:lockHpShieldHpMax()
	local buffData = self.model:getOverlaySpecBuffData(battle.OverlaySpecBuff.lockHpShield)

	return buffData and buffData.shieldMaxTotal or 0
end

function CsvObject:assimilateDamageHp(...)
	if ... then
		local mark = {}
		local hp = 0

		for _, cfgId in ipairs({
			...
		}) do
			mark[cfgId] = true
		end

		for _, data in self.model:ipairsOverlaySpecBuff("assimilateDamage") do
			if mark[data.cfgId] then
				hp = hp + math.max(data.assimilateDamage, 0)
			end
		end

		return hp
	else
		return self.model:assimilateDamage()
	end
end

function CsvObject:assimilateDamageHpByGroup(...)
	local assimilateDamageGroupList = {
		...
	}

	if next(assimilateDamageGroupList) then
		local mark = {}
		local hp = 0

		for _, group in ipairs(assimilateDamageGroupList) do
			mark[group] = true
		end

		for _, data in self.model:ipairsOverlaySpecBuff("assimilateDamage") do
			if mark[data.group] then
				hp = hp + math.max(data.assimilateDamage, 0)
			end
		end

		return hp
	else
		return self.model:assimilateDamage()
	end
end

local function calcValFilterWithFlag(flagList, recordData)
	local totalVal = 0

	if next(flagList) then
		for cfgId, val in pairs(recordData) do
			local buffFlag = csv.buff[cfgId].buffFlag

			for _, flag in ipairs(flagList) do
				if itertools.include(buffFlag, flag) then
					totalVal = totalVal + val

					break
				end
			end
		end
	else
		for cfgId, val in pairs(recordData) do
			totalVal = totalVal + val
		end
	end

	return totalVal
end

function CsvObject:shieldAbsorbedDamage(...)
	local shieldDamageReocrd = self.model:getEventByKey(battle.ExRecordEvent.shieldAbsorbDamage)

	if not shieldDamageReocrd then
		return 0
	end

	local shieldFlagList = {
		...
	}
	local totalDamage = calcValFilterWithFlag(shieldFlagList, shieldDamageReocrd)

	return totalDamage
end

function CsvObject:assimilateDamageAbsorbedDamage(...)
	local assimilateDamageReocrd = self.model:getEventByKey(battle.ExRecordEvent.assimilateDamageAbsorbDamage)

	if not assimilateDamageReocrd then
		return 0
	end

	local assimilateDamageFlagList = {
		...
	}
	local totalDamage = calcValFilterWithFlag(assimilateDamageFlagList, assimilateDamageReocrd)

	return totalDamage
end

function CsvObject:getImmuneDamageVal(...)
	local immuneDamageRecord = self.model:getEventByKey(battle.ExRecordEvent.immuneDamageVal)

	if not immuneDamageRecord then
		return 0
	end

	local flagList = {
		...
	}
	local totalDamage = calcValFilterWithFlag(flagList, immuneDamageRecord)

	return totalDamage
end

function CsvObject:getDmgAllocateOverflow()
	return self.model:getEventByKey(battle.ExRecordEvent.allocateOverflow) or 0
end

function CsvObject:getCopyBuffCount()
	return self.model:getEventByKey(battle.ExRecordEvent.copySucessCount) or 0
end

function CsvObject:getTransferBuffCount()
	return self.model:getEventByKey(battle.ExRecordEvent.transferSucessCount) or 0
end

function CsvObject:chargeStateBeforeWave()
	return self.model:getEventByKey(battle.ExRecordEvent.chargeStateBeforeWave)
end

function CsvObject:getKillMeDamage(valueKey)
	if self.model.killMeDamageValues then
		return self.model.killMeDamageValues:get(valueKey)
	end

	return 0
end

function CsvObject:getRecordDamage(valueKey, damageKey)
	local total = 0

	for k, v in pairs(self.model.totalDamage) do
		if damageKey then
			if damageKey == k then
				total = total + v:get(valueKey)
			end
		else
			total = total + v:get(valueKey)
		end
	end

	return total
end

function CsvObject:getRecordResumeHp(valueKey, resumeKey)
	local total = 0

	for k, v in pairs(self.model.totalResumeHp) do
		if resumeKey then
			if resumeKey == v then
				total = total + v:get(valueKey)
			end
		else
			total = total + v:get(valueKey)
		end
	end

	return total
end

function CsvObject:getRecordTakeDamage(valueKey, needCurWave)
	return self.model:getTakeDamageRecord(valueKey, needCurWave)
end

function CsvObject:getAllRecordTakeDamage(force, valueKey, needCurWave)
	return self.model:getAllTakeDamageRecord(force, valueKey, needCurWave)
end

function CsvObject:getMomentBuffDamage(buffCsvID, index)
	index = index or 1

	local data = self.model:getEventByKey(battle.ExRecordEvent.momentBuffDamage, buffCsvID)

	return data and data[index] or 0
end

function CsvObject:getRecordData(key)
	return self.model:getEventByKey(battle.ExRecordEvent[key]) or 0
end

function CsvObject:getRealPos()
	return self.model:getRealPos()
end

function CsvObject:getPlaySmallSkillCount()
	return self.model:getEventByKey(battle.MainSkillType.SmallSkill) or 0
end

function CsvObject:getAttackState()
	return self.model:getEventByKey(battle.ExRecordEvent.attackState) or 0
end

function CsvObject:getSkillSpellCountByType(skillType2)
	return self.model:getEventByKey(skillType2) or 0
end

function CsvObject:getSpecBuffSubkeySize(key, subkey, buffIds)
	local length = 0
	local mark = arraytools.hash(buffIds or {})

	for _, v in self.model:ipairsOverlaySpecBuff(key) do
		if (not buffIds or mark[v.cfgId]) and v[subkey] and type(v[subkey]) == "table" then
			length = length + table.length(v[subkey])
		end
	end

	return length
end

function CsvObject:getSpecBuffFuncVal(key, funcName, ...)
	return self.model:doOverlaySpecBuffFunc(key, funcName, ...) or 0
end

function CsvObject:getExAttackMode()
	return self.model:getExtraRoundMode() or 0
end

function CsvObject:getRowNums()
	local row = self.model:frontOrBack()
	local nums = self.model.scene:getRowRemain(self.model.force, row)

	return nums
end

function CsvObject:getRowEmptySeat()
	local row = self.model:frontOrBack()
	local ret = {}
	local range = battle.RowSeatRange[self.model.force][row]

	for seat = range.min, range.max do
		if self.model.scene:isSeatEmpty(seat) then
			table.insert(ret, seat)
		end
	end

	return ret
end

function CsvObject:getColumnNums()
	local column = self.model.seat % 3

	column = column == 0 and 3 or column

	local nums = self.model.scene:getColumnRemain(self.model.force, column)

	return nums
end

function CsvObject:getImmuneVal(buffGroup)
	local immuneVal = 0

	for _, data in self.model:ipairsOverlaySpecBuff("immuneControlVal") do
		immuneVal = data.refreshProb(immuneVal, buffGroup)
	end

	return immuneVal
end

function CsvObject:getFightPoint()
	return self.model.fightPoint
end

function CsvObject:getDelayDamage()
	return self.model:delayDamage()
end

function CsvObject:getSummonGroup()
	return self.model.summonGroup or 0
end

function CsvObject:getType()
	return self.model.type or 0
end

function CsvObject:isBackHeros()
	return self.model.scene:isBackHeros(self.model) ~= nil
end

function CsvObject:getGroupShieldCfgId()
	return self.model.cfgId or 0
end

function CsvObject:getCommandeerDataNum(recordName, keys)
	local result = {}

	if not keys then
		result = self.model:getEventByKey(battle.ExRecordEvent[recordName]) or {}
	else
		for _, key in pairs(keys) do
			local temp = self.model:getEventByKey(battle.ExRecordEvent[recordName], key) or {}

			for _, data in pairs(temp) do
				table.insert(result, data)
			end
		end
	end

	return table.length(result)
end

local flagTypeList = {
	Z = battle.Const.ZSkills
}

for typ, idList in pairs(flagTypeList) do
	for k, v in ipairs(idList) do
		CsvObject["flag" .. typ .. k] = functools.partial(function(id, self, isOrigin)
			return self.model:findTagSkill(id, isOrigin == 1)
		end, v)
	end
end

local flagLevelList = {
	AS = battle.Const.AidStage,
	AA = battle.Const.AidAwake
}

for typ, v in pairs(flagLevelList) do
	local skillId, levelLimit = v[1], v[2]

	for k = 1, levelLimit do
		CsvObject["flag" .. typ .. k] = functools.partial(function(id, level, self, isOrigin)
			local tagSkill = self.model:findTagSkill(id, isOrigin == 1)

			return tagSkill and level <= tagSkill:getLevel()
		end, skillId, k)
	end

	CsvObject["flag" .. typ .. "Lv"] = functools.partial(function(id, self, isOrigin)
		local tagSkill = self.model:findTagSkill(id, isOrigin == 1)

		return tagSkill and tagSkill:getLevel() or 0
	end, skillId)
end

function CsvObject:getControlPerVal(buffGroup)
	local controlPerVal = 0

	for _, data in self.model:ipairsOverlaySpecBuff("controlPerVal") do
		controlPerVal = data.refreshProb(controlPerVal, buffGroup)
	end

	return controlPerVal
end

function CsvObject:atkSkillNature()
	return self:attackerSkill():getNatureType()
end

function CsvObject:eqATKNature(nature)
	return self:attackerSkill():getNatureType() == nature
end

function CsvObject:sTDmg()
	return self:curSkill():getTotalDamage()
end

function CsvObject:combineObj()
	if self.model and self.model.combineObj then
		local objectModel = self.model.combineObj

		return battleCsv.CsvObject.newWithCache(objectModel)
	end

	return battleCsv.NilObject
end

function CsvObject:isCanUseCombineSkill(combinationObjCardId)
	if self.model:checkCanUseSkill() == false then
		return false
	end

	local obj = self.model:getCombineSkillBindObject(combinationObjCardId)

	if obj == nil or obj:checkCanUseSkill() == false then
		return false
	end

	return true
end

function CsvObject:freezeHpMax(...)
	local cfgIds = {
		...
	}

	if not next(cfgIds) then
		return self.model:freezeHpMax()
	end

	cfgIds = arraytools.hash(cfgIds)

	local finalV = 0

	for _, buffData in self.model:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freezeHpMax) do
		if cfgIds[buffData.cfgId] then
			finalV = finalV + buffData:overlayValue("getValue", "freezeHpmax")
		end
	end

	return finalV
end

function CsvObject:freezeHpMaxByGroup(...)
	local groups = {
		...
	}

	if not next(groups) then
		return self.model:freezeHpMax()
	end

	groups = arraytools.hash(groups)

	local finalV = 0

	for _, buffData in self.model:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freezeHpMax) do
		if groups[buffData.group] then
			finalV = finalV + buffData:overlayValue("getValue", "freezeHpmax")
		end
	end

	return finalV
end

function CsvObject:natureDeltaAdd(natureType)
	local objNatureName = game.NATURE_TABLE[natureType]
	local natureDeltaAdd = objNatureName .. "DamageAdd"

	return self.model[natureDeltaAdd](self.model)
end

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	CsvObject["B" .. attr] = function(self)
		return self.model:getBaseAttr(attr)
	end
	CsvObject["A" .. attr] = function(self)
		return self.model.attrs.buff[attr]
	end
	CsvObject["BA" .. attr] = function(self)
		return self.model:getRealFinalAttr(attr)
	end
	CsvObject[attr] = function(self)
		return self.model[attr](self.model)
	end
end

function CsvObject:aidSkillRoundCheck()
	local aidSkill = self.model.aidSkill

	if aidSkill and aidSkill:checkRound() then
		return true
	end
end

battleCsv.exportToCsvCls(CsvObject, CsvObjectExport)
