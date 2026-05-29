-- chunkname: @src.battle.csv.skill

local CsvSkillExport = {
	interruptBuffId = 0
}
local CsvSkill = battleCsv.newCsvCls("CsvSkill")

CsvSkill.ignoreModelCheck = {
	owner = true
}
battleCsv.CsvSkill = CsvSkill

function CsvSkill:level()
	return self.model:getLevel()
end

function CsvSkill:getId()
	return self.model.id
end

function CsvSkill:getKilledTargets()
	return self.model.killedTargetsTb or {}
end

function CsvSkill:getDamageStateByTarget(target, key)
	return table.get(self.model.targetsFinalResult, target.model.id, "args", key)
end

function CsvSkill:getProcessTargetsCount(processId)
	return table.length(self.model.allProcessesTargets[processId].targets)
end

function CsvSkill:checkProcessTargetsState(processId, state)
	local checkFunc = {}

	if state == "nodead" then
		function checkFunc(targets)
			for _, obj in ipairs(targets) do
				if obj:isAlreadyDead() then
					return false
				end
			end

			return true
		end
	end

	return checkFunc(self.model.allProcessesTargets[processId].targets)
end

function CsvSkill:getDamageState(key, val)
	if not self.model then
		return false
	end

	local compVal = val or true

	for _, info in pairs(self.model.targetsFinalResult) do
		local v = table.get(info, "args", key)

		if v == compVal then
			return true
		end
	end
end

function CsvSkill:getTotalDamage(key, isResumeHp)
	if not self.model.cfg then
		return 0
	end

	key = key or battle.ValueType.normal

	local mapKey = (isResumeHp or 0) == 0 and battle.SkillSegType.damage or battle.SkillSegType.resumeHp
	local totalDamage = 0

	for _, args in self.model:pairsTargetsFinalResult(mapKey) do
		totalDamage = totalDamage + args.real:get(key)
	end

	return totalDamage
end

function CsvSkill:getTargetTotalDamage(target, key, isResumeHp)
	if not target.model or not self.model:chcekTargetInFinalResult(target.model.id) then
		return 0
	end

	if not self.model.cfg then
		return 0
	end

	key = key or battle.ValueType.normal
	isResumeHp = isResumeHp or 0

	local totalDamage, real = 0

	if isResumeHp == 0 and self.model:isSameType(battle.SkillFormulaType.damage) then
		real = self.model.targetsFinalResult[target.model.id].damage.real
		totalDamage = totalDamage + real:get(key)
	end

	if isResumeHp == 1 and self.model:isSameType(battle.SkillFormulaType.resumeHp) then
		real = self.model.targetsFinalResult[target.model.id].resumeHp.real
		totalDamage = totalDamage + real:get(key)
	end

	return totalDamage
end

function CsvSkill:getSkillDamageType()
	return self.model.cfg.skillDamageType
end

function CsvSkill:getNatureType()
	return self.model:getSkillNatureType()
end

function CsvSkill:getSkillType()
	return self.model.cfg.skillType or 0
end

function CsvSkill:getSkillType2()
	return self.model.cfg.skillType2 or 0
end

function CsvSkill:getSkillFormulaType()
	return self.model.skillFormulaType
end

function CsvSkill:owner()
	if self.model and self.model.owner then
		local objectModel = self.model.owner

		return battleCsv.CsvObject.newWithCache(objectModel)
	end

	return battleCsv.NilObject
end

function CsvSkill:preCalSkillDamageCsvTarget(csvTarget, csvSelectTarget)
	local target = csvTarget.model
	local curSkill = self.model
	local selectTarget = csvSelectTarget.model
	local result = false

	if target and curSkill and selectTarget then
		curSkill.allProcessesTargets = {}

		for i = 1, table.length(curSkill.processes) do
			local processCfg = curSkill.processes[i]
			local args = curSkill:onProcess(processCfg, selectTarget)

			curSkill:saveProcessTargets(processCfg.id, args.targets)

			result = result or itertools.include(args.targets, function(obj)
				return obj.id == target.id
			end)

			if result then
				break
			end
		end
	end

	return result
end

function CsvSkill:targetType()
	return self.model.cfg.targetChooseType or "other"
end

function CsvSkill:getCdRound()
	return self.model.cfg.cdRound
end

function CsvSkill:getCurCdRound()
	return self.model:getLeftCDRound()
end

function CsvSkill:isSpellTo()
	return self.model.isSpellTo
end

function CsvSkill:specialRatio()
	return self.model.cfg.specialRatio
end

function CsvSkill:skillFlag(...)
	local flag = {
		...
	}

	for _, v in ipairs(flag) do
		for _, data in ipairs(self.model.cfg.skillFlag) do
			if v == data then
				return true
			end
		end
	end

	return false
end

battleCsv.exportToCsvCls(CsvSkill, CsvSkillExport)
