-- chunkname: @src.battle.easy.damage

local ValueType = battle.ValueType

battleEasy.IDCounter = 0

local function alterDmgRecordVals(attacker, target)
	local ret = {}

	local function fillAlterRet(typ, alterData, priority)
		ret[typ] = ret[typ] or {}

		for processName, processValue in pairs(alterData) do
			ret[typ][processName] = ret[typ][processName] or {}

			table.insert(ret[typ][processName], {
				data = processValue,
				priority = priority
			})
		end
	end

	for _, data in attacker:ipairsOverlaySpecBuff("alterDmgRecordVal") do
		if data.assignObject == 1 or data.assignObject == 3 then
			fillAlterRet(data.typ, data.alterDmgRecordData, data.priority)
		end
	end

	for _, data in target:ipairsOverlaySpecBuff("alterDmgRecordVal") do
		if data.assignObject == 2 or data.assignObject == 3 then
			fillAlterRet(data.typ, data.alterDmgRecordData, data.priority)
		end
	end

	for _, typeTb in pairs(ret) do
		for _, processTb in pairs(typeTb) do
			table.sort(processTb, function(a, b)
				return a.priority < b.priority
			end)
		end
	end

	return ret[1] or {}, ret[2] or {}, ret[3] or {}
end

local signValRelation = {
	[1] = "run",
	[2] = "jump"
}

battleEasy.DamageProcessFuncs = {}

local function default_func()
	return true
end

local function initProcess(name, fillEnv, calcProb, result)
	battleEasy.DamageProcessFuncs[name] = {
		fillEnv = fillEnv,
		calcProb = calcProb,
		result = result
	}
end

local function initPreCalProcess(name, fillEnv, calcProb, result)
	initProcess(name, fillEnv, calcProb, result)
end

local function initNormalProcess(name, fillEnv, result)
	initProcess(name, fillEnv, default_func, result)
end

local function initEasyProcess(name, result)
	initProcess(name, default_func, default_func, result)
end

battleEasy.initPreCalProcess = initPreCalProcess
battleEasy.initNormalProcess = initNormalProcess
battleEasy.initEasyProcess = initEasyProcess

function battleEasy.getDamageKind(record)
	local args = record.args

	if args.skillMark then
		return battle.DamageKind.skill
	elseif args.isProcessState then
		return battle.DamageKind.aoe
	elseif args.isBeginDamageSeg and args.isLastDamageSeg then
		return battle.DamageKind.single
	else
		return battle.DamageKind.other
	end
end

local function makeProcessMachine(record, attacker, target)
	local machine = {
		record = record,
		attacker = attacker,
		target = target
	}

	function machine:init(sign, name, data)
		self.funcMap = battleEasy.DamageProcessFuncs[name]
		self.sign = sign
		record.preBehaviour = data.preBehaviour[name]
		record.buffBehaviourTb = data.alterValFormulars[name] or {}
		record.buffExtraArgs = data.alterExtraArgs[name] and data.alterExtraArgs[name][1] or {}
	end

	function machine:fillEnv()
		self.funcMap.fillEnv(self.record, self.attacker, self.target, self.sign)

		return self
	end

	function machine:calcProb()
		if not self.record.args.hasCalcDamageProb then
			self.funcMap.calcProb(self.record, self.attacker, self.target, self.sign)
		end

		return self
	end

	function machine:result()
		return self.funcMap.result(self.record, self.attacker, self.target, self.sign)
	end

	return machine
end

local function makeDamageEnv(damage, processId, extraArgs)
	local p = {}

	p.args = extraArgs or {}
	p.valueF = damage
	p.valueBase = damage
	p.id = processId

	function p:showTargetHeadNumber(target, damage)
		local damageTextInfo = {
			miss = self.args.skillMiss or self.args.miss,
			isBeginSeg = self.args.segId == 1
		}
		local damageNumberInfo = {
			strike = self.args.strike,
			miss = damageTextInfo.miss,
			block = self.args.block,
			natureFlag = self.args.natureFlag,
			nature = self.args.nature or 1,
			from = self.args.from,
			segId = self.args.segId,
			isLastSeg = self.args.isLastDamageSeg
		}

		damage = damage or self.valueF + (self.args.recordValue or 0)

		if self:damageFromExtraExit(battle.DamageFromExtra.allocate) or self:damageFromExtraExit(battle.DamageFromExtra.link) then
			damageTextInfo.miss = false
			damageNumberInfo.strike = false
			damageNumberInfo.block = false
			damageNumberInfo.natureFlag = "normal"

			if self.args.from == battle.DamageFrom.rebound and damage > 0 then
				damageNumberInfo.from = battle.DamageFrom.buff
			end
		end

		battleEasy.deferNotifyCantJump(target.view, "showHeadText", {
			args = damageTextInfo
		})

		if not self.args.hideHeadNumber then
			battleEasy.deferNotify(target.view, "showHeadNumber", {
				typ = 0,
				num = damage,
				args = damageNumberInfo
			})
		end
	end

	function p:damageFromExtraExit(fromExtra)
		self.args.fromExtra = self.args.fromExtra or {}

		if not fromExtra then
			return next(self.args.fromExtra)
		end

		if self.args.fromExtra[fromExtra] == nil then
			self.args.fromExtra[fromExtra] = false
		end

		return self.args.fromExtra[fromExtra]
	end

	function p:addDamageSpecialFrom(key, value)
		self.args.specialFrom = self.args.specialFrom or {}
		self.args.specialFrom[key] = value
	end

	function p:fillEnv(env)
		self.__index = env

		return self
	end

	function p:resetEnv()
		self.__index = nil

		return self
	end

	return setmetatable(p, p)
end

local function fillDamageEnv(attacker, target, protected, attr, applyAttr)
	protected:resetEnv()

	local env = {}

	if attr then
		env = battleCsv.makeDamageProcessEnv(attacker, target, protected, attr)
	end

	if protected.preBehaviour then
		battleCsv.doFormula(protected.preBehaviour, env)
	end

	if protected.buffBehaviourTb and next(protected.buffBehaviourTb) then
		for _, behaviour in ipairs(protected.buffBehaviourTb) do
			battleCsv.doFormula(behaviour.data, env)
		end
	end

	if applyAttr and attr then
		for key, value in pairs(attr) do
			protected[key] = env[key] or value
		end
	end

	return protected:fillEnv(env)
end

battleEasy.fillDamageEnv = fillDamageEnv

function battleEasy.calcStrValue(valueF, attacker, target)
	local value = tonumber(valueF)

	value = value or battleCsv.doFormula(valueF, {
		min = math.min,
		max = math.max,
		attacker = attacker,
		target = target,
		sum = function(default, ...)
			local args = {
				...
			}
			local sum = default

			for _, v in ipairs(args) do
				sum = sum + (v and type(v) == "number" and v or 0)
			end

			attacker.scene:applyDamageCorrect(battle.damageCorrectType.damageAdd, sum, attacker, target, target.unitType)

			return sum
		end,
		mutex = function(default, ...)
			local args = {
				...
			}

			for _, v in ipairs(args) do
				if v and type(v) == "number" then
					return v
				end
			end

			return default
		end
	})

	return value
end

function battleEasy.runDamageProcess(damage, attacker, target, processId, extraArgs)
	battleEasy.IDCounter = battleEasy.IDCounter + 1

	local damageCsv = csv.damage_process[processId]
	local exdamageCsv

	if extraArgs and extraArgs.exProcessId then
		exdamageCsv = csv.damage_process[extraArgs.exProcessId]
	end

	if not attacker or not target then
		errorInWindows("attacker(%d) or target(%d) is nil", attacker and attacker.seat or -1, target and target.seat or -1)

		return 0, {}
	elseif not damageCsv then
		errorInWindows("%d to %d damage Process %d is nil", attacker.seat, target.seat, processId)

		return 0, {}
	end

	local preBehaviour = damageCsv.preBehaviour or {}
	local alterValFormulars, alterSigns, alterExtraArgs = alterDmgRecordVals(attacker, target)
	local record = makeDamageEnv(damage, processId, extraArgs)

	record.args.damageId = battleEasy.IDCounter
	record.preBehaviour = preBehaviour.init
	record.buffBehaviourTb = alterValFormulars.init

	fillDamageEnv(attacker, target, record, {
		damageType = record.args.damageType
	}, true)

	local machine = makeProcessMachine(record, attacker, target)

	log.battle.damage.dprocessStart({
		attacker = attacker,
		target = target,
		extraArgs = extraArgs,
		record = record,
		damage = damage
	})

	local continue, sign, prate = true

	for _, processName in ipairs(battle.DamageProcess) do
		tjprofiler.tBegin("runDamageProcess", processName)

		local tempSign, curSign

		if alterSigns[processName] then
			local processIdAndSigns = alterSigns[processName][1].data
			local env = battleCsv.makeDamageProcessEnv(attacker, target, record, {})

			tempSign = battleCsv.doFormula(processIdAndSigns, env)
			curSign = signValRelation[tempSign] or tempSign
		end

		sign = curSign or damageCsv[processName]

		BattleAssert.assertInWindows("damageProcess", processName, {
			sign = sign
		})

		if sign and sign ~= "jump" and (not exdamageCsv or exdamageCsv[processName] == sign) then
			if sign == "out" or not continue then
				break
			end

			machine:init(sign, processName, {
				preBehaviour = preBehaviour,
				alterValFormulars = alterValFormulars,
				alterExtraArgs = alterExtraArgs
			})

			continue, prate = machine:fillEnv():calcProb():result()

			log.battle.damage.dprocess({
				processName = processName,
				record = record,
				prate = prate or "nil"
			})

			if type(record.valueF) == "number" and record.valueF < 0 then
				record.valueF = 0
			end
		end

		tjprofiler.tEnd("runDamageProcess", processName, 1)
	end

	local finalDamage = math.floor(battleEasy.calcStrValue(record.valueF, attacker, target))

	log.battle.damage.dprocessEnd({
		record = record,
		damage = finalDamage
	})

	return finalDamage, record.args
end

local function moreSignFormula(key, sign, valueF, rate, subKey)
	if string.match(valueF, key) then
		return string.gsub(valueF, key, string.format("%s,%s", rate, key))
	end

	return string.format(valueF, string.gsub(sign, subKey .. "%d+%(%w+", function(s)
		return string.format("%s,%s,%s", string.gsub(s, key, subKey), rate, key)
	end))
end

local signPattern = {
	multiply = function(key, sign, valueF, rate)
		rate = rate ~= "nil" and rate or 1

		return string.format("%s*%s", valueF, rate)
	end,
	["mutex%d+"] = function(key, sign, valueF, rate)
		return moreSignFormula(key, sign, valueF, rate, "mutex")
	end,
	["sum%d+"] = function(key, sign, valueF, rate)
		return moreSignFormula(key, sign, valueF, rate, "sum")
	end
}
local updDamageFormula

function updDamageFormula(sign, record, rate)
	local signs = string.split(sign, "|")

	rate = rate or "nil"

	if table.length(signs) > 1 then
		for k, v in ipairs(signs) do
			local isLast = table.length(signs) == k

			updDamageFormula(v, record, isLast and rate or "%s")
		end

		return
	end

	if tonumber(sign) then
		record.valueF = string.format(record.valueF, sign)

		return
	end

	local key

	for pattern, formulaFunc in pairs(signPattern) do
		key = string.match(sign, pattern)

		if key then
			record.valueF = formulaFunc(key, sign, record.valueF, rate)

			break
		end
	end
end

initPreCalProcess("damageHit", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		damageHit = attacker:damageHit(),
		damageDodge = target:damageDodge()
	})
end, function(record, attacker, target, sign)
	local delta = record:damageHit() - record:damageDodge()
	local prob = ymrand.random()

	if delta < prob then
		record.args.miss = true
	end
end, function(record, attacker, target, sign)
	if record.args.miss then
		record.valueF = 0

		return false, 0
	else
		return true, 0
	end
end)
initPreCalProcess("nature", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		natureRestraint = attacker:natureRestraint(),
		natureResistance = target:natureResistance()
	})
end, function(record, attacker, target, sign)
	local nature, natureFlag = 1

	if record.args.skillId then
		local curSkill = attacker.skills[record.args.skillId] or attacker.passiveSkills[record.args.skillId]
		local natureType = curSkill and curSkill:getSkillNatureType()

		natureFlag, nature = skillHelper.natureRestraintType(natureType, target, record:natureRestraint(), record:natureResistance())
	elseif record.args.natureType then
		natureFlag, nature = skillHelper.natureRestraintType(record.args.natureType, target, record:natureRestraint(), record:natureResistance())
	end

	record.args.nature = nature
	record.args.natureFlag = natureFlag
end, function(record, attacker, target, sign)
	local data = record.buffExtraArgs.data or {}

	record.args.nature = data.nature or record.args.nature
	record.args.natureFlag = data.natureFlag or record.args.natureFlag

	updDamageFormula(sign, record, record.args.nature)

	return true, record.args.nature
end)
initNormalProcess("damageAdd", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		damageAdd = attacker:damageAdd(),
		damageSub = target:damageSub(),
		ignoreDamageSub = attacker:ignoreDamageSub()
	})
end, function(record, attacker, target, sign)
	local dmgSub = record:damageAdd() - math.max(record:damageSub() - record:ignoreDamageSub(), 0)

	updDamageFormula(sign, record, dmgSub)

	return true, dmgSub
end)
initNormalProcess("damageDeepen", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		damageDeepen = target:damageDeepen(),
		damageReduce = attacker:damageReduce()
	})
end, function(record, attacker, target, sign)
	local damageDeepen = record:damageDeepen() - record:damageReduce()

	updDamageFormula(sign, record, damageDeepen)

	return true, damageDeepen
end)
initNormalProcess("dmgDelta", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		physicalDamageAdd = attacker:physicalDamageAdd(),
		specialDamageAdd = attacker:specialDamageAdd(),
		trueDamageAdd = attacker:trueDamageAdd(),
		physicalDamageSub = target:physicalDamageSub(),
		specialDamageSub = target:specialDamageSub(),
		trueDamageSub = target:trueDamageSub()
	})
end, function(record, attacker, target, sign)
	if not record.damageType then
		return true
	end

	local dmgDelta

	if record.damageType == battle.SkillDamageType.Physical then
		dmgDelta = record:physicalDamageAdd() - record:physicalDamageSub()
	elseif record.damageType == battle.SkillDamageType.True then
		dmgDelta = record:trueDamageAdd() - record:trueDamageSub()
	else
		dmgDelta = record:specialDamageAdd() - record:specialDamageSub()
	end

	updDamageFormula(sign, record, dmgDelta)

	return true, dmgDelta
end)
initNormalProcess("natureDelta", function(record, attacker, target, sign)
	if record.args.natureType then
		local objNatureName = game.NATURE_TABLE[record.args.natureType]
		local natureDeltaAdd = objNatureName .. "DamageAdd"
		local natureDeltaSub = objNatureName .. "DamageSub"
		local natureDeltaReduce = objNatureName .. "DamageReduce"
		local natureDeltaDeepen = objNatureName .. "DamageDeepen"

		fillDamageEnv(attacker, target, record, {
			natureDeltaAdd = attacker[natureDeltaAdd](attacker),
			natureDeltaSub = target[natureDeltaSub](target),
			natureDeltaReduce = attacker[natureDeltaReduce](attacker),
			natureDeltaDeepen = target[natureDeltaDeepen](target)
		})
	end
end, function(record, attacker, target, sign)
	local natureDelta = 0

	if record.args.natureType then
		natureDelta = record.natureDeltaAdd - record.natureDeltaSub - record.natureDeltaReduce + record.natureDeltaDeepen

		updDamageFormula(sign, record, natureDelta)
	end

	return true, natureDelta
end)
initNormalProcess("gateDelta", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		pvpDamageAdd = attacker:pvpDamageAdd(),
		pvpDamageSub = target:pvpDamageSub()
	})
end, function(record, attacker, target, sign)
	local gateDelta = record:pvpDamageAdd() - record:pvpDamageSub()

	updDamageFormula(sign, record, gateDelta)

	return true, gateDelta
end)
initNormalProcess("reduce", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		defence = target:defence(),
		specialDefence = target:specialDefence(),
		defenceIgnore = attacker:defenceIgnore(),
		specialDefenceIgnore = attacker:specialDefenceIgnore(),
		damage = attacker:damage(),
		specialDamage = attacker:specialDamage()
	})
end, function(record, attacker, target, sign)
	local reduce = 0

	if record.damageType ~= battle.SkillDamageType.True then
		local defence

		if record.damageType == battle.SkillDamageType.Physical then
			defence = record:defence()
		else
			defence = record:specialDefence()
		end

		local data = target:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.calDmgKeepDefence)

		if data then
			if data.args == 1 then
				defence = math.min(record:defence(), record:specialDefence())
			else
				defence = math.max(record:defence(), record:specialDefence())
			end
		end

		local defenceDelta

		if record.damageType == battle.SkillDamageType.Physical then
			defenceDelta = defence * math.max(1 - record:defenceIgnore(), ConstSaltNumbers.dot05)
		else
			defenceDelta = defence * math.max(1 - record:specialDefenceIgnore(), ConstSaltNumbers.dot05)
		end

		defenceDelta = math.max(defenceDelta, 0)

		local damageAttr

		if record.damageType == battle.SkillDamageType.Physical then
			damageAttr = record:damage()
		else
			damageAttr = record:specialDamage()
		end

		reduce = ConstSaltNumbers.one - defenceDelta / math.max(damageAttr, ConstSaltNumbers.dot001)
		reduce = math.max(reduce, ConstSaltNumbers.dot01)

		if reduce > gCommonConfigCsv.reduceLimit then
			reduce = gCommonConfigCsv.reduceLimit
		end

		reduce = attacker.scene:applyDamageCorrect(battle.damageCorrectType.reduce, reduce, attacker, target, target.unitType)

		updDamageFormula(sign, record, reduce)
	end

	return true, reduce
end)
initPreCalProcess("strikeBlock", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		isNeedImmuneStrike = 0,
		strikeResistance = target:strikeResistance(),
		ignoreStrikeResistance = attacker:ignoreStrikeResistance(),
		strike = attacker:strike(),
		strikeDamage = attacker:strikeDamage(),
		strikeDamageSub = target:strikeDamageSub(),
		strikePowerRate = ConstSaltNumbers.one15,
		block = target:block(),
		breakBlock = attacker:breakBlock(),
		blockPower = target:blockPower(),
		blockPowerRate = ConstSaltNumbers.one,
		rate = ConstSaltNumbers.dot96
	})
end, function(record, attacker, target, sign)
	local strikeRate = math.max(record:strike() - math.max(record:strikeResistance() - record:ignoreStrikeResistance(), 0), 0)
	local blockRate = math.max(record:block() - record:breakBlock(), 0)
	local _blockRate = blockRate
	local _strikeRate = strikeRate

	_blockRate = _blockRate * record.blockPowerRate
	_strikeRate = _strikeRate * record.strikePowerRate

	local indicatorStrike = ymrand.random()

	if indicatorStrike < _strikeRate then
		record.args.strike = true
	end

	local indicatorBlock = ymrand.random()

	if indicatorBlock < _blockRate then
		record.args.block = true
	end
end, function(record, attacker, target, sign)
	if record.isNeedImmuneStrike and record.isNeedImmuneStrike == 1 then
		record.valueF = 0

		return false
	end

	local deltaStrike = ConstSaltNumbers.one

	if record.args.strike then
		deltaStrike = math.max(record:strikeDamage() - record:strikeDamageSub(), ConstSaltNumbers.dot01)
	end

	updDamageFormula(sign, record, deltaStrike)

	local deltaBlock = ConstSaltNumbers.one

	if record.args.block then
		deltaBlock = math.max(ConstSaltNumbers.one - record:blockPower(), ConstSaltNumbers.dot01)
	end

	updDamageFormula(sign, record, deltaBlock)

	return true, deltaStrike .. "|" .. deltaBlock
end)
initPreCalProcess("strike", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		isNeedImmuneStrike = 0,
		strikeResistance = target:strikeResistance(),
		ignoreStrikeResistance = attacker:ignoreStrikeResistance(),
		strike = attacker:strike(),
		strikeDamage = attacker:strikeDamage(),
		strikeDamageSub = target:strikeDamageSub(),
		strikePowerRate = ConstSaltNumbers.one15
	})
end, function(record, attacker, target, sign)
	local strikeRate = math.max(record:strike() - math.max(record:strikeResistance() - record:ignoreStrikeResistance(), 0), 0)

	strikeRate = strikeRate * record.strikePowerRate

	local indicatorStrike = ymrand.random()

	if indicatorStrike < strikeRate then
		record.args.strike = true
	end
end, function(record, attacker, target, sign)
	if record.isNeedImmuneStrike and record.isNeedImmuneStrike == 1 then
		record.valueF = 0

		return false
	end

	local deltaStrike = ConstSaltNumbers.one

	if record.args.strike then
		deltaStrike = math.max(record:strikeDamage() - record:strikeDamageSub(), ConstSaltNumbers.dot01)
	end

	updDamageFormula(sign, record, deltaStrike)

	return true, deltaStrike
end)
initPreCalProcess("block", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		block = target:block(),
		breakBlock = attacker:breakBlock(),
		blockPower = target:blockPower(),
		blockPowerRate = ConstSaltNumbers.one
	})
end, function(record, attacker, target, sign)
	local blockRate = math.max(record:block() - record:breakBlock(), 0)

	blockRate = blockRate * record.blockPowerRate

	local indicatorBlock = ymrand.random()

	if indicatorBlock < blockRate then
		record.args.block = true
	end
end, function(record, attacker, target, sign)
	local deltaBlock = ConstSaltNumbers.one
	local scene = attacker.scene

	if record.args.block then
		local deltaBlock1 = math.max(ConstSaltNumbers.one - record:blockPower(), gCommonConfigCsv.blockMin)

		deltaBlock = attacker.scene:applyDamageCorrect(battle.damageCorrectType.block, deltaBlock1, attacker, target)
	end

	updDamageFormula(sign, record, deltaBlock)

	return true, deltaBlock
end)
initEasyProcess("extraAdd", function(record, attacker, target, sign)
	local extraAdd = 0

	updDamageFormula(sign, record, extraAdd)

	return true, extraAdd
end)
initEasyProcess("fatal", function(record, attacker, target, sign)
	local rate = target:hp() / target:hpMax()
	local sumRate = 0

	for _, data in attacker:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.fatal) do
		if rate > data.limit then
			sumRate = sumRate + data.val
		end
	end

	updDamageFormula(sign, record, sumRate)

	return true, sumRate
end)
initEasyProcess("behead", function(record, attacker, target, sign)
	local rate = target:hp() / target:hpMax()
	local sumRate = 0

	for _, data in attacker:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.behead) do
		if rate < data.limit then
			sumRate = sumRate + data.val
		end
	end

	updDamageFormula(sign, record, sumRate)

	return true, sumRate
end)

local function damageByHpRate(buffData, obj)
	local rate = (obj:hpMax() - obj:hp()) / obj:hpMax()

	return math.min(rate, buffData.rateMax) * buffData.rateAdd * 100
end

initEasyProcess("damageByHpRate", function(record, attacker, target, sign)
	local sumRate = 0

	for _, data in attacker:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.damageByHpRate) do
		if data.selectTargetTab[1] == true then
			sumRate = sumRate + damageByHpRate(data, attacker)
		end

		if data.selectTargetTab[2] == true then
			sumRate = sumRate + damageByHpRate(data, target)
		end
	end

	updDamageFormula(sign, record, sumRate)

	return true, sumRate
end)
initEasyProcess("finalSkillAdd", function(record, attacker, target, sign)
	local finalSkillAddRate = attacker:finalSkillAddRate()

	updDamageFormula(sign, record, finalSkillAddRate)

	return true, finalSkillAddRate
end)
initNormalProcess("ultimateAdd", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		ultimateAdd = attacker:ultimateAdd(),
		ultimateSub = target:ultimateSub()
	})
end, function(record, attacker, target, sign)
	local ultimateAdd = 0

	if not record.args.skillType2 then
		return true, ultimateAdd
	end

	if record.args.skillType2 == battle.MainSkillType.BigSkill then
		ultimateAdd = 1 + record:ultimateAdd() - record:ultimateSub()
		ultimateAdd = math.max(ultimateAdd, ConstSaltNumbers.dot05)

		updDamageFormula(sign, record, ultimateAdd)
	end

	return true, ultimateAdd
end)
initEasyProcess("skillPower", function(record, attacker, target, sign)
	local skillPower = 0

	if record.args.skillPower then
		skillPower = record.args.skillPower / ConstSaltNumbers.wan
		skillPower = math.max(skillPower, ConstSaltNumbers.dot05)

		updDamageFormula(sign, record, skillPower)
	end

	return true, skillPower
end)
initNormalProcess("buffAdd", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		damageRateAdd = attacker:damageRateAdd()
	})
end, function(record, attacker, target, sign)
	updDamageFormula(sign, record, record:damageRateAdd())

	return true, record:damageRateAdd()
end)
initEasyProcess("randFix", function(record, attacker, target, sign)
	local randFix = target.scene.closeRandFix and 1 or ymrand.random(9000, ConstSaltNumbers.wan) / ConstSaltNumbers.wan

	updDamageFormula(sign, record, randFix)

	return true, randFix
end)
initEasyProcess("limit", function(record, attacker, target, sign)
	local limitDamage = battleEasy.runDamageProcess(record.valueBase, attacker, target, sign, battleEasy.deepcopy_args(record.args))

	record.valueF = string.format("max(%s,%s)", record.valueF, limitDamage)

	return true, limitDamage
end)
initNormalProcess("calcInternalDamageFinish", function(record, attacker, target, sign)
	record.valueF = battleEasy.calcStrValue(record.valueF, attacker, target)

	fillDamageEnv(attacker, target, record, {
		calFinalDamage = record.valueF
	})
end, function(record, attacker, target, sign)
	record.valueF = record.calFinalDamage

	return true
end)
initEasyProcess("reflexDamage", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit("reflexDamage") then
		local reflexDamage
		local totalDamage = battleEasy.calcStrValue(record.valueF, attacker, target)

		if totalDamage == 0 then
			return true
		end

		for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reflexDamage) do
			local buffFlagTb = record.args.buffFlag or {}

			for _, v in ipairs(buffFlagTb) do
				if data.buffFlagMap[v] then
					return true
				end
			end

			reflexDamage = totalDamage * data.rate
			totalDamage = totalDamage - reflexDamage

			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onReflexDamage, {
				valueSum = reflexDamage,
				damageArgs = record.args,
				damageProcessId = record.id
			})
		end

		record.valueF = totalDamage
	end

	return true
end)
initEasyProcess("ignoreRoundDamage", function(record, attacker, target, sign)
	if target.ignoreDamageInBattleRound then
		record.valueF = 0

		record:showTargetHeadNumber(target)

		return false
	end

	return true
end)
initEasyProcess("leave", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit("leave") then
		record:showTargetHeadNumber(target)

		if record.args.from ~= battle.DamageFrom.buff then
			record.valueF = 0
		end

		return false
	end

	return true
end)
initEasyProcess("immuneDamage", function(record, attacker, target, sign)
	for _, data in target:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.immuneDamage, attacker) do
		for power, time in data:powerTimeOrderPairs() do
			local result, showHeadNum = data.funcMap[power](data, record, attacker)

			if result then
				target:addExRecord(battle.ExRecordEvent.immuneDamageVal, record.valueF, data.cfgId)

				record.valueF = 0

				local buff = data.buff

				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = buff.id,
					easyEffectFunc = buff.csvCfg.easyEffectFunc,
					triggerTime = data.damageMap.count,
					processId = record.id,
					args = record.args
				})

				if data.allTime == 0 then
					buff:over()
				end

				record.args.immune = result

				if showHeadNum then
					record:showTargetHeadNumber(target)
				end

				return false
			end
		end
	end

	return true
end)
initEasyProcess("immuneAllDamage", function(record, attacker, target, sign)
	if target.beInImmuneAllDamageState and target.beInImmuneAllDamageState > 0 then
		record.valueF = 0
		record.args.immune = "all"

		record:showTargetHeadNumber(target)

		return false
	end

	return true
end)
initEasyProcess("immunePhysicalDamage", function(record, attacker, target, sign)
	if record.damageType == battle.SkillDamageType.Physical and target.beInImmunePhysicalDamageState and target.beInImmunePhysicalDamageState > 0 then
		record.valueF = 0
		record.args.immune = "physical"

		record:showTargetHeadNumber(target)

		return false
	end

	return true
end)
initEasyProcess("immuneSpecialDamage", function(record, attacker, target, sign)
	if record.damageType == battle.SkillDamageType.Special and target.beInImmuneSpecialDamageState and target.beInImmuneSpecialDamageState > 0 then
		record.valueF = 0
		record.args.immune = "special"

		record:showTargetHeadNumber(target)

		return false
	end

	return true
end)
initEasyProcess("invincible", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit("invincible") then
		record.valueF = 0

		return false
	end

	return true
end)
initEasyProcess("keepHpUnChanged", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.keepHp) then
		local groupShieldHp = target.scene:excuteGroupObjFunc(target.force, battle.SpecialObjectId.teamShiled, "getShieldHp") or 0
		local shieldHp = target:shieldHp()
		local allHp = target:hp() + shieldHp + groupShieldHp
		local damage = record.valueF

		damage = record.args.from == battle.DamageFrom.skill and attacker.curSkill and not record:damageFromExtraExit() and record.args.leftDamage or damage

		if allHp < damage then
			local buffData

			for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.keepHp) do
				if ymrand.random() <= data.prob then
					buffData = data

					break
				end
			end

			if buffData then
				record.valueF = 0
				buffData.triggerTime = buffData.triggerTime - 1
				target.ignoreDamageInBattleRound = true

				local buff = target:getBuff(buffData.cfgId)

				record:showTargetHeadNumber(target)
				buff:playTriggerPointEffect()

				local triggerState = buff:getEventByKey(battle.ExRecordEvent.keepHpUnChangedTriggerState)

				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					checkEffectFunc = "lockHpAndKeepHpUnChanged",
					attacker = attacker,
					buffId = buff.id,
					buffCfgId = buff.cfgId,
					buffFlag = buff:buffFlag(),
					easyEffectFunc = buff.csvCfg.easyEffectFunc,
					isFirstTrigger = not triggerState
				})
				buff:addExRecord(battle.ExRecordEvent.keepHpUnChangedTriggerState, true)

				if buffData.triggerTime <= 0 then
					buff:over()
				end

				return false
			end
		end
	end

	return true
end)

local function getDmgAdjustData(attacker)
	local dmgAdjustData = attacker:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.dmgAdjustAllocateAndLink)
	local dmgAjustTargetHash, times = {}, 1

	if dmgAdjustData then
		dmgAjustTargetHash = dmgAdjustData.getTargetHash()
		times = dmgAdjustData.times
	end

	return dmgAjustTargetHash, times
end

local function damgeLimitCheck(data, record, attacker)
	local damageFromMap = {
		battle.DamageFrom.skill,
		battle.DamageFrom.buff
	}
	local damageFromCheck = false
	local battleTurnCheck = false

	if data.damageFrom == 0 or record.args.from == damageFromMap[data.damageFrom] then
		damageFromCheck = true
	end

	if data.battleTurnType == 1 or data.battleTurnType == 2 and not attacker.scene:getExtraRoundMode() or data.battleTurnType == 3 and attacker.scene:getExtraRoundMode() then
		battleTurnCheck = true
	end

	return damageFromCheck and battleTurnCheck
end

initNormalProcess("damageAllocate", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {})
end, function(record, attacker, target, sign)
	local buffList = record.buffList

	local function checkFunc()
		return false
	end

	if buffList and table.length(buffList) > 0 then
		local hashBuffList = arraytools.hash(buffList)

		function checkFunc(cfgId)
			return not hashBuffList[cfgId]
		end
	end

	local function canAllocateTarget(data, id)
		if data.canAllocateSelf then
			return true
		end

		if id ~= target.id then
			return true
		end

		return false
	end

	local fromAllocate = record:damageFromExtraExit(battle.DamageFromExtra.allocate)

	for k, data in target:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.allocate, attacker, {
		record = record
	}) do
		local allocateCheck = fromAllocate and (not record.args.allocatePriority or data.priority >= record.args.allocatePriority)
		local checkResult = allocateCheck or checkFunc(data.cfgId)

		if not checkResult and damgeLimitCheck(data, record, attacker) then
			local rate = data.rate
			local buffCfgId = data.cfgId
			local buffCsv = target:getBuff(buffCfgId).csvCfg
			local targetIds = data.targetIds

			if buffCsv.specialVal and buffCsv.specialVal[3] == 1 then
				local damageId = record.args.skillDamageId or record.args.damageId

				if not data.targetIdsList[damageId] then
					data.targetIdsList[damageId] = data.getNewTargetIds()
				end

				targetIds = data.targetIdsList[damageId]

				if record.args.isLastDamageSeg then
					data.targetIdsList[damageId] = nil
				end
			end

			local targets = {}

			for _, id in ipairs(targetIds) do
				if canAllocateTarget(data, id) then
					local obj = target.scene:getObjectExcludeDead(id)

					if obj and not battleEasy.isCompleteLeave(obj) then
						table.insert(targets, obj)
					end
				end
			end

			if table.length(targets) > 0 then
				local function fillAlloArgs(args, dmgAllocated)
					args.fromExtra[battle.DamageFromExtra.allocate] = true
					args.allocatePriority = data.priority
					args.hideHeadNumber = data.hideZeroDmg and dmgAllocated <= 0
				end

				local dmgAllocated = record.valueF

				if rate == -1 then
					record.valueF = math.floor(record.valueF / (table.length(targets) + 1))

					if dmgAllocated > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then
						dmgAllocated = target:hp()
					end
				else
					dmgAllocated = record.valueF * rate
					record.valueF = math.floor(record.valueF * (1 - rate))

					if record.valueF > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then
						dmgAllocated = dmgAllocated * (target:hp() / record.valueF)
					end

					dmgAllocated = math.floor(dmgAllocated / table.length(targets))
				end

				dmgAllocated = math.floor(dmgAllocated * data.damageFix)

				local overFlow = 0

				if data.maxDamage then
					overFlow = dmgAllocated > data.maxDamage and dmgAllocated - data.maxDamage or 0
					dmgAllocated = math.min(dmgAllocated, data.maxDamage)
				end

				local dmgAjustTargetHash, times = getDmgAdjustData(attacker)
				local realAttacker = data.attackByCaster and data.buff.caster or attacker
				local damage = 0

				for _, obj in ipairs(targets) do
					damage = dmgAjustTargetHash[obj.id] and dmgAllocated * times or dmgAllocated

					local dmgArgsAllo = battleEasy.deepcopy_args(record.args)

					fillAlloArgs(dmgArgsAllo, damage)
					obj:addExRecord(battle.ExRecordEvent.allocateOverflow, overFlow)
					target.scene:deferBeAttack(target.id, realAttacker, obj, damage, data.damageMode, dmgArgsAllo, buffCsv.specialVal and buffCsv.specialVal[2])
				end

				record.args.hideHeadNumber = data.hideZeroDmg and record.valueF <= 0
			end
		end
	end

	return true
end)

local function checkLinkEffect(linkRecord, target, record)
	local damageFromMap = {
		battle.DamageFrom.skill,
		battle.DamageFrom.buff,
		battle.DamageFrom.rebound
	}
	local damageFromCheck = false
	local battleTurnCheck = false
	local buffFlagCheck = true
	local fromLimit = linkRecord.fromLimit
	local battleTurnTypeLimit = linkRecord.battleTurnTypeLimit
	local buffFlagLimit = linkRecord.buffFlagLimit

	if fromLimit == 0 or record.args.from == damageFromMap[fromLimit] then
		damageFromCheck = true
	end

	if battleTurnTypeLimit == 1 or battleTurnTypeLimit == 2 and not target.scene:getExtraRoundMode() or battleTurnTypeLimit == 3 and target.scene:getExtraRoundMode() then
		battleTurnCheck = true
	end

	if record.args.from == battle.DamageFrom.buff and not itertools.isempty(buffFlagLimit) then
		buffFlagCheck = battleEasy.intersection(buffFlagLimit, record.args.buffFlag, false)
	end

	return damageFromCheck and battleTurnCheck and buffFlagCheck
end

local function checkTimesBeLink(curRound, linkRecord)
	local args = linkRecord.timesLimit

	if not args then
		return true
	end

	if curRound > args.curRound then
		args.times = 1
		args.curRound = curRound

		return true
	elseif args.times < args.limit then
		args.times = args.times + 1

		return true
	else
		return false
	end
end

local function checkDamageLimitBeLink(damage, damageLimit, record, linkRecord)
	local args = linkRecord.damageLimit

	if record.args.isBeginDamageSeg then
		args.curDamage = 0
	end

	local newDamage = math.min(damageLimit - args.curDamage, damage)

	args.curDamage = args.curDamage + newDamage

	return newDamage
end

initEasyProcess("damageLink", function(record, attacker, target, sign)
	if not record:damageFromExtraExit(battle.DamageFromExtra.link) then
		local globalBuffMgr = target.scene.buffGlobalManager

		for _, linkRecord in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.damageLink) do
			local cfgId = linkRecord.cfgId

			if checkLinkEffect(linkRecord, target, record) then
				local objIDs = globalBuffMgr:getDamageLinkObjs(target.id, cfgId)
				local dmgAjustTargetHash, times = getDmgAdjustData(attacker)

				for k, v in ipairs(objIDs) do
					local obj

					if linkRecord.getObjectType == 1 then
						obj = target.scene:getBackObject(v)
					else
						obj = target.scene:getObjectExcludeDead(v)
					end

					local holderLinkRecord = globalBuffMgr:getDamageLinkRecord(v, cfgId)

					if obj and not obj:isLogicStateExit(battle.ObjectLogicState.cantBeAttack, {
						fromObj = attacker
					}) and checkTimesBeLink(target.scene.play.curRound, holderLinkRecord) then
						local targetBuff = target:getBuff(cfgId)
						local buffCsv = targetBuff.csvCfg
						local damageRatio

						if buffCsv.specialVal and buffCsv.specialVal[4] then
							local damageRatioArgs = buffCsv.specialVal[4]

							targetBuff.protectedEnv = battleCsv.fillFuncEnv(targetBuff.protectedEnv, {
								attacker = attacker
							})
							damageRatio = targetBuff:cfg2Value(damageRatioArgs)

							targetBuff.protectedEnv:resetEnv()
						else
							damageRatio = globalBuffMgr:getDamageLinkValue(v, cfgId)
						end

						local newDamage = record.valueF

						if newDamage > target:hp() and buffCsv.specialVal and buffCsv.specialVal[1] > 0 then
							newDamage = math.max(target:hp(), 0)
						end

						newDamage = math.floor(newDamage * damageRatio)

						if buffCsv.specialVal and buffCsv.specialVal[5] then
							newDamage = checkDamageLimitBeLink(newDamage, targetBuff:cfg2Value(buffCsv.specialVal[5]), record, holderLinkRecord)
						end

						newDamage = dmgAjustTargetHash[obj.id] and newDamage * times or newDamage

						local newDamageArgs = battleEasy.deepcopy_args(record.args)

						newDamageArgs.fromExtra[battle.DamageFromExtra.link] = true

						local newAttacker = attacker

						if buffCsv.specialVal and buffCsv.specialVal[2] == 1 then
							newAttacker = (targetBuff.caster and not targetBuff.caster:isDeath() or nil) and targetBuff.caster
						end

						if newAttacker then
							local processId = holderLinkRecord.processId or linkRecord.processId or record.id
							local needMerge = buffCsv.specialVal and buffCsv.specialVal[3] == 1

							target.scene:deferBeAttack(target.id, newAttacker, obj, newDamage, processId, newDamageArgs, needMerge)
						end
					end
				end
			end
		end
	end

	return true
end)
initEasyProcess("protection", function(record, attacker, target, sign)
	if record:damageFromExtraExit(battle.DamageFromExtra.protect) then
		return true
	end

	local fromSkill = record.args.from == battle.DamageFrom.skill
	local isBeginSeg = record.args.segId == 1
	local isDefer = record.args.isDefer
	local isNeedTrigger = fromSkill and isBeginSeg and not isDefer and attacker.curSkill

	local function filter(protectData)
		if protectData and protectData.protector then
			local protectMeObj = protectData.protector

			if protectMeObj:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.protection) then
				return true
			end

			local protecterEvent = protectMeObj:getEventByKey(battle.ExRecordEvent.protectTarget)
			local targetEvent = target:getEventByKey(battle.ExRecordEvent.protectTarget)

			if protectData.type == 2 then
				if targetEvent and not targetEvent.isProtector and targetEvent.protectType ~= 2 then
					return true
				end
			elseif protectData.type == 1 then
				if record.args.from == battle.DamageFrom.rebound then
					return true
				end

				if protecterEvent then
					if protecterEvent.isProtector then
						return protecterEvent.obj.id ~= target.id
					else
						return true
					end
				elseif record.args.from == battle.DamageFrom.buff then
					return true
				end
			end

			local ignoreControl = protectData.ignoreControl == 1

			if protectMeObj:isAlreadyDead() then
				return true
			end

			if protectMeObj:isNotReSelect(true) then
				return true
			end

			if protectMeObj:isSelfControled() and not ignoreControl then
				return true
			end

			return not protectData:checkCondition()
		end

		return true
	end

	for _, protectData in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.protection, filter) do
		local protector = protectData.protector
		local triggerProtected = true
		local allDamage

		if isNeedTrigger then
			if protectData.type == 1 then
				local lockhpBuffData = target:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.lockHp)

				if lockhpBuffData and lockhpBuffData.mode == 2 and target:hp() > target:hpMax() * lockhpBuffData.extraArg then
					triggerProtected = false
				end

				if not attacker.curSkill:isSameType(battle.SkillFormulaType.damage) then
					triggerProtected = false
				else
					local triggerHp = target:hp() * protectData.extraArgs[1]
					local totalShieldHp = target:shieldHp()
					local buffDamage = attacker.curSkill:getBuffDamageAfterSkill(target)
					local skillDamage = record.args.leftDamage

					if skillDamage + buffDamage < triggerHp + totalShieldHp then
						triggerProtected = false
					end
				end

				if triggerProtected then
					target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
						buffId = protectData.id,
						easyEffectFunc = protectData.buff.csvCfg.easyEffectFunc,
						obj = protector
					})
					protector:addExRecord(battle.ExRecordEvent.protectTarget, {
						isProtector = true,
						obj = target
					})
					target:addExRecord(battle.ExRecordEvent.protectTarget, {
						isProtector = false,
						protectType = protectData.type,
						obj = protector
					})
				end
			else
				target:addExRecord(battle.ExRecordEvent.protectTarget, {
					isProtector = false,
					protectType = protectData.type,
					obj = protector
				})
			end
		end

		triggerProtected = protectData.type ~= 1 or protector:getEventByKey(battle.ExRecordEvent.protectTarget)

		if triggerProtected then
			local newDamage = math.floor(record.valueF * protectData.ratio)
			local newDamageArgs = battleEasy.deepcopy_args(record.args)

			newDamageArgs.fromExtra[battle.DamageFromExtra.protect] = true

			if fromSkill and protectData.type == 1 and not isDefer and attacker.curSkill then
				attacker.curSkill:onProtectTarget(protector, newDamageArgs, newDamage, protectData.extraArgs[2])
			else
				protector:beAttack(attacker, newDamage, protectData.extraArgs and protectData.extraArgs[2] or record.id, newDamageArgs)
			end

			record.valueF = math.floor(record.valueF * (1 - protectData.ratio))
			record.args.extraShowValueF = newDamage
			record.args.hideHeadNumber = protectData.type == 1

			break
		end
	end

	return true
end)
initEasyProcess("groupShield", function(record, attacker, target, sign)
	local costShield = target.scene:excuteGroupObjFunc(target.force, battle.SpecialObjectId.teamShiled, "beAttack", attacker, target, record)

	if not costShield then
		return true
	end

	record.valueF = record.valueF - costShield

	if record.valueF == 0 then
		return false
	end

	return true
end)
initNormalProcess("assimilateDamage", function(record, attacker, target, sign)
	local calcAssimilateDamageList = record.buffExtraArgs.data and record.buffExtraArgs.data.calcList
	local notIgnoreAssimilateDamageList = {}

	for k, data in target:ipairsOverlaySpecBuffTo("assimilateDamage", attacker) do
		table.insert(notIgnoreAssimilateDamageList, data.cfgId)
	end

	calcAssimilateDamageList = arraytools.merge({
		notIgnoreAssimilateDamageList,
		calcAssimilateDamageList or {}
	})

	fillDamageEnv(attacker, target, record, {
		ignoreAssimilateDamagePer = 0,
		assimilateDamageHp = target:assimilateDamage(calcAssimilateDamageList),
		totalAssimilateDamageHp = target:assimilateDamage()
	})
end, function(record, attacker, target, sign)
	if record.assimilateDamageHp and record.assimilateDamageHp > 0 then
		if record.ignoreAssimilateDamagePer > 1 then
			record.ignoreAssimilateDamagePer = 1
		end

		local damageToObj = record.valueF * record.ignoreAssimilateDamagePer

		record.valueF = record.valueF - damageToObj

		local off = record.assimilateDamageHp - record.valueF
		local calcAssimilateDamageList = record.buffExtraArgs.data and record.buffExtraArgs.data.calcList
		local notIgnoreAssimilateDamageList = {}

		for k, data in target:ipairsOverlaySpecBuffTo("assimilateDamage", attacker) do
			table.insert(notIgnoreAssimilateDamageList, data.cfgId)
		end

		calcAssimilateDamageList = arraytools.merge({
			notIgnoreAssimilateDamageList,
			calcAssimilateDamageList or {}
		})

		target:addAssimilateDamage(-record.valueF, {
			filterBuffCfgId = function(cfgId)
				if not calcAssimilateDamageList or itertools.include(calcAssimilateDamageList, cfgId) then
					return true
				end
			end
		}, calcAssimilateDamageList, {
			fromDamage = true
		})

		if off > 0 then
			if damageToObj == 0 then
				record:showTargetHeadNumber(target)
			end

			target:refreshAssimilateDamage()

			local value = record.valueF

			target.scene.play:recordScoreStats(attacker, math.floor(value / 2))

			record.args.recordValue = value
			record.valueF = damageToObj

			if damageToObj > 0 then
				return true
			end

			return false
		else
			target.scene.play:recordScoreStats(attacker, math.floor(record.assimilateDamageHp / 2))

			record.args.recordValue = record.assimilateDamageHp
			record.valueF = damageToObj - off

			target:clearBuff(nil, target:getBuffQuery():group("easyEffectFunc", "assimilateDamage"))
			target:refreshAssimilateDamage()
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderAssimilateDamageBreak, target)
		end
	end

	return true
end)
initEasyProcess("delayDamage", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
		local tempDamage = record.valueF

		for k, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
			local delayVal = math.min(record.valueF * data.delayPer, tempDamage)
			local perVal = math.floor(delayVal / data.time)
			local oneRecord = {}

			for _ = 1, data.time do
				table.insert(oneRecord, perVal)
			end

			table.insert(data.damageTb, oneRecord)

			tempDamage = tempDamage - perVal * data.time

			if tempDamage <= 0 then
				break
			end
		end

		record.valueF = math.max(tempDamage, 0)
	end

	return true
end)
initNormalProcess("damageCounteract", function(record, attacker, target, sign)
	battleEasy.fillDamageEnv(attacker, target, record, {
		dmgCounteractRatio = 1,
		dmgCounteractVal = 0,
		dmgCounteractProb = target:strike()
	})
end, function(record, attacker, target, sign)
	local off = record.dmgCounteractVal

	if record.dmgCounteractProb > ymrand.random() then
		off = off * record.dmgCounteractRatio
	end

	record.valueF = record.valueF - off

	if record.valueF < 0 then
		return false
	end

	return true
end)

local function dealLockShield(record, target)
	if record.totalShieldHp > record.shieldHp then
		return
	end

	if not target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.lockShield) then
		return
	end

	local lockShieldBuffData = target:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.lockShield)

	if record.args.isBeginDamageSeg or not lockShieldBuffData.damageRecord then
		local allDamage = record.args.leftDamage or record.valueF
		local shieldCanReduce

		if lockShieldBuffData.lockType == 1 then
			shieldCanReduce = math.max(record.shieldHp - lockShieldBuffData.lockValue, 0)
		elseif lockShieldBuffData.lockType == 2 then
			shieldCanReduce = math.min(record.shieldHp, lockShieldBuffData.lockValue)
		end

		lockShieldBuffData.damageRecord = shieldCanReduce <= allDamage and shieldCanReduce or allDamage
		lockShieldBuffData.needTriggerPoint = shieldCanReduce < allDamage
	end

	if record.args.isLastDamageSeg then
		record.valueF = lockShieldBuffData.damageRecord
		lockShieldBuffData.damageRecord = nil

		if lockShieldBuffData.needTriggerPoint then
			local triggerState = lockShieldBuffData.triggerState

			lockShieldBuffData.triggerState = true

			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
				buffId = lockShieldBuffData.buff.id,
				buffCfgId = lockShieldBuffData.buff.cfgId,
				easyEffectFunc = lockShieldBuffData.buff.csvCfg.easyEffectFunc,
				actualDamageToShield = record.valueF,
				isFirstTrigger = not triggerState
			})
		end
	else
		record.valueF = 0
	end
end

initNormalProcess("shield", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		ignoreShieldPer = 0,
		shieldHp = target:shieldHp(),
		totalShieldHp = target:shieldHp(),
		ignoreBuffIDs = {},
		ignoreBuffGroups = {},
		ignoreBuffFlags = {}
	})
end, function(record, attacker, target, sign)
	if record.shieldHp and record.shieldHp > 0 then
		if record.ignoreShieldPer > 1 then
			record.ignoreShieldPer = 1
		end

		local damageToObj = record.valueF * record.ignoreShieldPer

		record.valueF = record.valueF - damageToObj

		dealLockShield(record, target)

		local calcShieldList = record.buffExtraArgs.data and record.buffExtraArgs.data.calcList
		local notIgnoreShieldList = {}

		for k, data in target:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.shield, attacker) do
			if battleEasy.buffFilterEasy(data.buff, record.ignoreBuffGroups, record.ignoreBuffFlags, record.ignoreBuffIDs, 2) then
				table.insert(notIgnoreShieldList, data.cfgId)
			end
		end

		calcShieldList = arraytools.merge({
			notIgnoreShieldList,
			calcShieldList or {}
		})

		local afterShieldDamage = target:addShieldHp(-record.valueF, {
			filterBuffCfgId = function(cfgId)
				if not calcShieldList or itertools.include(calcShieldList, cfgId) then
					return true
				end
			end
		}, calcShieldList, {
			fromDamage = true
		})

		if afterShieldDamage < 0 then
			damageToObj = damageToObj - afterShieldDamage
		end

		if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.shield) then
			if damageToObj == 0 then
				record:showTargetHeadNumber(target)
			end

			target:refreshShield()

			local value = record.valueF

			target.scene.play:recordScoreStats(attacker, math.floor(value / 2))

			record.args.recordValue = value
			record.valueF = damageToObj
		else
			target.scene.play:recordScoreStats(attacker, math.floor(record.shieldHp / 2))

			record.args.recordValue = record.shieldHp
			record.valueF = damageToObj

			target:clearBuff(nil, target:getBuffQuery():group("easyEffectFunc", "shield"))
			target:refreshShield()
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderShieldBreak, target)
		end

		if record.valueF <= 0 then
			return false
		end
	end

	return true
end)

local function dealSkillDamage(lockBuffData, afterDamage, damageId, isTrigger, record)
	if afterDamage < record.valueF and not lockBuffData.damageMap[damageId] then
		lockBuffData.damageMap[damageId] = afterDamage
	end

	if lockBuffData.damageMap[damageId] then
		if isTrigger then
			record.valueF = math.min(lockBuffData.damageMap[damageId], afterDamage)
			lockBuffData.damageMap[damageId] = nil

			return true
		else
			record.valueF = 0
		end
	end

	return false
end

initEasyProcess("barrier", function(record, attacker, target, sign)
	local originVauleF = record.valueF

	local function barrierData(cfgId)
		local wave = attacker.scene.play.curWave
		local round = attacker.scene.play:getTotalBattleTurnCurWave()
		local data = {
			cfgId = cfgId,
			breakTurn = wave .. "_" .. round
		}

		return data
	end

	local function addToShowNumber()
		if record.args.from == battle.DamageFrom.skill and attacker.curSkill then
			attacker.curSkill:addToSegDamage(originVauleF)
		end
	end

	local lockData = target:getEventByKey(battle.ExRecordEvent.barrierLockTurn)

	if lockData then
		local curData = barrierData()

		if lockData.breakTurn == curData.breakTurn then
			record.valueF = 0
		else
			target:cleanEventByKey(battle.ExRecordEvent.barrierLockTurn)
		end

		addToShowNumber()

		return true
	end

	for _, data in target:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.barrier, attacker) do
		if data.barrierValue > 0 then
			if originVauleF >= data.barrierValue then
				target:addExRecord(battle.ExRecordEvent.barrierLockTurn, barrierData())
			end

			local dmg2Barrier = math.min(data.barrierValue, record.valueF)

			record.args.barrierDamage = dmg2Barrier
			record.valueF = 0
			data.barrierValue = data.barrierValue - dmg2Barrier

			target:beAttackRecoverMp(attacker, dmg2Barrier, target:hp(), record.args)

			if data.barrierValue <= 0 then
				target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					cfgId = data.cfgId
				})
				data.buff:over()
			end

			addToShowNumber()

			break
		end
	end

	target:refreshBarrierHp()

	return true
end)

local segDeal = {
	[battle.DamageKind.skill] = function(curLockBuffData, curRecord, attacker)
		local curArgs = curRecord.args
		local curType = battleEasy.getDamageKind(curRecord)
		local storedMark = curLockBuffData.ignoreMarkData.mark
		local isIgnore = false

		if curType == battle.DamageKind.skill then
			isIgnore = storedMark == curArgs.skillMark
		else
			local curSkill = attacker.curSkill

			if curSkill and curSkill.isSpellTo then
				local curMark = attacker.id .. curSkill.id .. attacker:getEventByKey(curSkill.skillType2)

				isIgnore = storedMark == curMark
			end
		end

		if not isIgnore then
			curLockBuffData.ignoreMarkData = nil
		end

		return isIgnore
	end
}

local function initLockHpKindData(record)
	local args = record.args
	local kindDatas = {
		[battle.DamageKind.skill] = {
			mark = args.skillMark,
			type = battle.DamageKind.skill
		}
	}
	local ret
	local type = battleEasy.getDamageKind(record)

	if kindDatas[type] then
		ret = kindDatas[type]

		function ret.ignoreCheck(curLockBuffData, curRecord, attacker)
			local storedType = curLockBuffData.ignoreMarkData.type
			local ignore = false

			if segDeal[storedType] then
				ignore = segDeal[storedType](curLockBuffData, curRecord, attacker)
			end

			return ignore
		end
	end

	return ret
end

local lockHpCheckCondition = {
	[0] = function(lockBuffData, target, damageId, isTrigger, record)
		lockBuffData.lockHpTo = type(lockBuffData.extraArg) == "table" and math.ceil(target:getBaseAttr("hpMax") * lockBuffData.extraArg[1] + target:hpMax() * lockBuffData.extraArg[2]) or 1

		return target:hp() < lockBuffData.lockHpTo or record.valueF > target:hp() - lockBuffData.lockHpTo
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		return true
	end,
	[5] = function(lockBuffData, target, damageId, isTrigger, record)
		if lockBuffData.battleTurnRecord and lockBuffData.holdRecord == 0 and lockBuffData.battleTurnRecord ~= target.scene.play.curBattleRound or not lockBuffData.recordDamage then
			if lockBuffData.extraF then
				lockBuffData.recordDamage = lockBuffData.buff:cfg2Value(lockBuffData.extraF)
			else
				lockBuffData.recordDamage = target:hpMax() * lockBuffData.extraArg
			end

			lockBuffData.battleTurnRecord = target.scene.play.curBattleRound
			lockBuffData.isLocked = false
		end

		if lockBuffData.isLocked then
			return true
		end

		if record.valueF >= target:hp() and lockBuffData.recordDamage >= target:hp() then
			return false
		end

		return true
	end
}
local dealLockHpByMode = {
	[0] = function(lockBuffData, target, damageId, isTrigger, record)
		if target:hp() < lockBuffData.lockHpTo then
			record.valueF = 0
		else
			local lockHpVal = math.max(target:hp() - lockBuffData.lockHpTo, 0)

			isTrigger = dealSkillDamage(lockBuffData, lockHpVal, damageId, isTrigger, record) and isTrigger

			if isTrigger then
				record:addDamageSpecialFrom("lockHp", lockBuffData.lockHpTo)
			end
		end

		return isTrigger
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		record.valueF = 0

		return isTrigger
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		if record.args.isBeginDamageSeg or not lockBuffData.recordDamage then
			lockBuffData.recordDamage = target:hpMax() * lockBuffData.extraArg
		end

		isTrigger = dealSkillDamage(lockBuffData, lockBuffData.recordDamage, damageId, isTrigger, record) and isTrigger
		lockBuffData.recordDamage = math.max(lockBuffData.recordDamage - record.valueF, 0)

		return isTrigger
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		if record.args.isBeginDamageSeg or not lockBuffData.recordDamage then
			lockBuffData.recordDamage = 1
		end

		isTrigger = dealSkillDamage(lockBuffData, lockBuffData.recordDamage, damageId, isTrigger, record) and isTrigger

		return isTrigger
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		if record.args.isBeginDamageSeg or not lockBuffData.recordDamage then
			local allDamage = record.args.leftDamage or record.valueF

			if allDamage >= lockBuffData.extraArg then
				lockBuffData.recordDamage = 0
			end
		end

		record.valueF = lockBuffData.recordDamage or record.valueF

		return lockBuffData.recordDamage and isTrigger
	end,
	function(lockBuffData, target, damageId, isTrigger, record)
		if lockBuffData.isLocked then
			record.valueF = 0
		elseif record.valueF > lockBuffData.recordDamage then
			record.valueF = lockBuffData.recordDamage
			lockBuffData.recordDamage = 0
			lockBuffData.isLocked = true
		else
			lockBuffData.recordDamage = lockBuffData.recordDamage - record.valueF
		end

		return lockBuffData.isLocked
	end
}

initEasyProcess("lockHp", function(record, attacker, target, sign)
	if target:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.lockHp) then
		local isTrigger
		local damageId = record.args.skillDamageId or record.args.damageId
		local triggeredList = {}
		local operateList = {}

		if record.args.isBeginDamageSeg then
			local totalDamage = record.args.leftDamage or record.valueF

			target:addExRecord(battle.ExRecordEvent.lockHpTotalDamage, totalDamage)
		end

		record.lockHpOriginValue = record.valueF

		local function filter(curLockBuffData)
			local condition = false

			if lockHpCheckCondition[curLockBuffData.mode] then
				condition = not lockHpCheckCondition[curLockBuffData.mode](curLockBuffData, target, damageId, record.args.isLastDamageSeg, record)
			end

			condition = condition or not curLockBuffData:checkCondition(attacker, record)
			condition = condition or battleEasy.ifElse(triggeredList[curLockBuffData.cfgId], true, false)

			return condition
		end

		local function ignoreRecord(curLockBuffData)
			if curLockBuffData.ignoreMarkData then
				local ignoreMarkData = curLockBuffData.ignoreMarkData

				if ignoreMarkData.ignoreCheck(curLockBuffData, record, attacker) then
					return
				end
			end

			curLockBuffData.ignoreMarkData = initLockHpKindData(record)
		end

		for _, curLockBuffData in target:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.lockHp, attacker, {
			filter = filter,
			ignoreRecord = ignoreRecord,
			record = record
		}) do
			local buff = curLockBuffData.buff

			buff:addExRecord(battle.ExRecordEvent.lockHpDamage, record.valueF)

			isTrigger = dealLockHpByMode[curLockBuffData.mode](curLockBuffData, target, damageId, record.args.isLastDamageSeg, record)

			if (curLockBuffData.mode == 0 or curLockBuffData.mode == 2) and curLockBuffData.isAlreadyTrigger == true or curLockBuffData.mode == 1 then
				target.scene:deleteBeAttackDefer(target.id, battle.DamageFromExtra.allocate, record.args.damageId)
			end

			if isTrigger then
				curLockBuffData.isAlreadyTrigger = true
				triggeredList[curLockBuffData.cfgId] = true

				buff:playTriggerPointEffect()

				if curLockBuffData.isPreDelete then
					if curLockBuffData.mode == 0 or curLockBuffData.mode == 1 then
						record.valueF = 0

						break
					end
				else
					if not curLockBuffData.hasTriggered then
						if curLockBuffData.triggerEndRound ~= 0 then
							buff.lifeRound = curLockBuffData.triggerEndRound

							buff:setNowRound()
						else
							curLockBuffData.isPreDelete = true
						end

						curLockBuffData.hasTriggered = true
					end

					local wave = attacker.scene.play.curWave
					local round = attacker.scene.play:getTotalBattleTurnCurWave()

					curLockBuffData.lastTriggerRound = wave .. "_" .. round

					table.insert(operateList, {
						buff = buff,
						isDelete = curLockBuffData.isPreDelete
					})
				end
			end

			if curLockBuffData.mode == 0 or curLockBuffData.mode == 1 or curLockBuffData.mode == 2 and record.valueF < target:hp() then
				break
			end
		end

		for _, data in ipairs(operateList) do
			local triggerState = data.buff:getEventByKey(battle.ExRecordEvent.lockHpTriggerState)
			local totalDamage = target:getEventByKey(battle.ExRecordEvent.lockHpTotalDamage) or 0

			data.buff:addExRecord(battle.ExRecordEvent.lockHpTriggerState, true)
			target:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
				checkEffectFunc = "lockHpAndKeepHpUnChanged",
				attacker = attacker,
				buffId = data.buff.id,
				buffCfgId = data.buff.cfgId,
				buffFlag = data.buff:buffFlag(),
				easyEffectFunc = data.buff.csvCfg.easyEffectFunc,
				isFirstTrigger = not triggerState,
				lockHpTotalDamage = totalDamage
			})

			if data.isDelete then
				data.buff:over()
			end
		end
	end

	return true
end)
initEasyProcess("freeze", function(record, attacker, target, sign)
	if target.freezeHp and target.freezeHp > 0 and record.valueF >= 1 then
		local off = target.freezeHp - record.valueF
		local tempDamage = record.valueF
		local delBuffList = {}

		for _, data in target:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freeze) do
			if tempDamage <= 0 then
				break
			end

			if tempDamage > data.freezeHp then
				data.freezeHp = 0
				tempDamage = tempDamage - data.freezeHp
				delBuffList[data.id] = true
			else
				data.freezeHp = data.freezeHp - tempDamage
				tempDamage = 0
			end
		end

		target:delBuff(delBuffList, true)

		if off > 0 then
			target.freezeHp = off

			target:refreshShield()
		end
	end

	return true
end)
initNormalProcess("suckblood", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		suckBlood = attacker:suckBlood(),
		isSuck = record.args.from == battle.DamageFrom.skill and record.args.skillType ~= battle.SkillType.NormalCombine
	})
end, function(record, attacker, target, sign)
	if attacker and record.isSuck then
		local attackerSuckBloodVal = record:suckBlood()

		if attackerSuckBloodVal > 0 then
			local suckHp = math.floor(attackerSuckBloodVal * record.valueF)

			attacker:resumeHp(attacker, suckHp, {
				ignoreLockResume = true,
				ignoreBeHealAddRate = true,
				from = battle.ResumeHpFrom.suckblood
			})
		end
	end

	return true
end)
initNormalProcess("rebound", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		reboundFixed = 0,
		reboundMax = 0,
		rebound = target:rebound()
	})
end, function(record, attacker, target, sign)
	if attacker and attacker.force ~= target.force and record.args.from == battle.DamageFrom.skill and record.args.skillType ~= battle.SkillType.NormalCombine then
		local selfReboundVal = record:rebound()

		if selfReboundVal > 0 then
			selfReboundVal = selfReboundVal + record.reboundFixed

			local limitHp = math.max(attacker:hp(), 1)
			local damage = record.args.barrierDamage or record.valueF

			if record.lockHpOriginValue then
				damage = damage + (record.lockHpOriginValue - damage) * gCommonConfigCsv.reboundFix
			end

			local reboundDmg = math.min(math.floor(selfReboundVal * damage), limitHp - 1)
			local reboundMax = math.floor(record.reboundMax > 0 and record.reboundMax or battleCsv.doFormula(gFormulaConst.reboundMax(), target.protectedEnv))

			reboundDmg = math.min(reboundDmg, reboundMax)

			target.scene:deferBeAttack(target.id, target, attacker, reboundDmg, 2, {
				isBeginDamageSeg = true,
				isLastDamageSeg = true,
				from = battle.DamageFrom.rebound,
				fromExtra = record.args.fromExtra or {},
				beAttackZOrder = record.args.beAttackZOrder
			})
		end
	end

	if record.args.barrierDamage then
		return false
	end

	return true
end)
initNormalProcess("finalRate", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		finalDamageAdd = attacker:finalDamageAdd(),
		finalDamageReduce = attacker:finalDamageReduce(),
		finalDamageSub = target:finalDamageSub(),
		finalDamageDeepen = target:finalDamageDeepen()
	})
end, function(record, attacker, target, sign)
	local finalRate = math.max(record:finalDamageAdd() - record:finalDamageReduce() - record:finalDamageSub() + record:finalDamageDeepen() + ConstSaltNumbers.one, ConstSaltNumbers.dot05)

	record.valueF = record.valueF * finalRate

	return true
end)
initNormalProcess("lockHpShield", function(record, attacker, target, sign)
	local buffData = target:getOverlaySpecBuffData(battle.OverlaySpecBuff.lockHpShield)
	local lockHpShield = buffData.shieldTotal or 0

	fillDamageEnv(attacker, target, record, {
		lockHpShield = lockHpShield,
		costHp = target:hp() - 1
	})
end, function(record, attacker, target, sign)
	if record.lockHpShield > 0 and record.costHp < record.valueF then
		local damage = record.valueF - record.costHp

		damage = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.lockHpShield, "costShield", damage)
		record.valueF = damage + record.costHp
	end

	return true
end)
initNormalProcess("result", function(record, attacker, target, sign)
	fillDamageEnv(attacker, target, record, {
		ignoreFakeDeath = record.args.ignoreFakeDeath or 0
	})
end, function(record, attacker, target, sign)
	if not record:damageFromExtraExit() then
		record.args.ignoreFakeDeath = battleEasy.ifElse(record.ignoreFakeDeath == 0, false, true)
	end

	record:showTargetHeadNumber(target)

	return false
end)

function battleEasy.valueTypeTable()
	local tb = {}

	tb = {
		__valueTypeTable = true,
		value = table.salttable({}),
		__tostring = function()
			if device.platform == "windows" then
				return string.format("%s/%s/%s", tb:get(ValueType.normal), tb:get(ValueType.overFlow), tb:get(ValueType.valid))
			end
		end
	}

	function tb:get(key)
		key = key or ValueType.normal

		return self.value[key]
	end

	function tb:set(key, value)
		key = key or ValueType.normal
		self.value[key] = math.floor(value)
	end

	function tb:add(data, key)
		if type(data) == "table" then
			for _, v in pairs(ValueType) do
				self:set(v, self:get(v) + (data.__valueTypeTable and data:get(v) or data[v]))
			end
		else
			key = key or ValueType.normal

			self:set(key, self:get(key) + data)
		end
	end

	function tb:addTable(data, ...)
		if type(data) ~= "table" or not data.__valueTypeTable then
			errorInWindows("valueTypeTable addTable type error, data is %s, need __valueTypeTable", data)
		end

		local keys = {
			...
		}

		keys = table.length(keys) > 0 and keys or ValueType

		for _, key in pairs(keys) do
			self:set(key, self:get(key) + data:get(key))
		end
	end

	for _, v in pairs(ValueType) do
		tb.value[v] = 0
	end

	return tb
end
