local GlobalBaseEnv

battleCsv.Model2CsvCls = {
	ObjectModel = battleCsv.CsvObject,
	MonsterModel = battleCsv.CsvObject,
	BossModel = battleCsv.CsvObject,
	ObjectExtraModel = battleCsv.CsvObject,
	ObjectAidModel = battleCsv.CsvObject,
	SceneModel = battleCsv.CsvScene,
	SkillModel = battleCsv.CsvSkill,
	BuffSkillModel = battleCsv.CsvSkill,
	PassiveSkillModel = battleCsv.CsvSkill,
	BuffModel = battleCsv.CsvBuff
}

local IgnoreGlobalFuncNames = {
	getDamageStateByTarget = true,
	__newindex = true,
	__index = true,
	getDamageState = true,
	sumBuffOverlayByGroup = true,
	level = true,
	force = true,
	newWithCache = true,
	new = true
}

local function exportFuncForGlobal(objKey, cls)
	for k, f in pairs(cls) do
		if not IgnoreGlobalFuncNames[k] and type(f) == "function" then
			assert(GlobalBaseEnv[k] == nil, string.format("%s `%s` already in protected env", type(cls), k))

			GlobalBaseEnv[k] = function(...)
				local env = GlobalBaseEnv._exEnv

				return f(env[objKey], ...)
			end
		end
	end
end

local function exitInTab(a, tab)
	if tab == nil then
		return false
	end

	for _, v in pairs(tab) do
		if a == v then
			return true
		end
	end

	return false
end

local function more(a, b)
	return b < a
end

local function less(a, b)
	return a < b
end

local function moreE(a, b)
	return b <= a
end

local function lessE(a, b)
	return a <= b
end

local function ifMore(a, b, tv, fv)
	if b < a then
		return tv
	end

	return fv
end

local function ifLess(a, b, tv, fv)
	if a < b then
		return tv
	end

	return fv
end

local function ifMoreE(a, b, tv, fv)
	if b <= a then
		return tv
	end

	return fv
end

local function ifLessE(a, b, tv, fv)
	if a <= b then
		return tv
	end

	return fv
end

local function div(lef, rig, min)
	if rig == 0 then
		return min
	end

	return lef / rig
end

local function to10(v)
	if v == nil or v == false or v == 0 then
		return 0
	end

	return 1
end

local function tobool(v)
	if v == nil or v == false or v == 0 then
		return false
	end

	return true
end

local function exitInArray(array, str)
	return itertools.include(array, battle.CsvStrToMap[str .. "Iter"])
end

local function list(...)
	return {
		...
	}
end

local function listByBool(tb, switch)
	local ret = {}

	for k, v in ipairs(tb) do
		if switch[k] == true then
			table.insert(ret, v)
		end
	end

	return ret
end

local function listWithoutNilAndOrder(...)
	local old = {
		...
	}
	local new = {}

	for _, v in pairs(old) do
		table.insert(new, v)
	end

	return new
end

local function listSub(a, b)
	local ret = {}
	local hashb = arraytools.hash(b)

	for k, v in ipairs(a) do
		if not hashb[k] then
			table.insert(ret, v)
		end
	end

	return ret
end

local function getValueTab(tab, typ)
	if tab and tab.__valueTypeTable then
		return tab:get(typ)
	end

	return 0
end

local function listLen(list)
	return table.length(list)
end

local function makeGlobalBaseEnv(exEnv)
	if GlobalBaseEnv then
		rawset(GlobalBaseEnv, "_exEnv", exEnv)

		return GlobalBaseEnv
	end

	assert(gFormulaConst, "gFormulaConst is nil")

	GlobalBaseEnv = {
		c = gFormulaConst,
		random = function(...)
			return ymrand.random(...)
		end,
		randomChoice = function(...)
			local seq = {
				...
			}

			return seq[ymrand.random(1, table.length(seq))]
		end,
		choice = function(list)
			local i = ymrand.random(1, #list)

			return list[i]
		end,
		select = select,
		min = math.min,
		max = math.max,
		div = div,
		clamp = cc.clampf,
		to10 = to10,
		ifElse = battleEasy.ifElse,
		ifMore = ifMore,
		ifLess = ifLess,
		ifMoreE = ifMoreE,
		ifLessE = ifLessE,
		more = more,
		less = less,
		moreE = moreE,
		lessE = lessE,
		exitInTab = exitInTab,
		intersection = battleEasy.intersection,
		exactSeat = battleEasy.exactSeat,
		getValueTab = getValueTab,
		moreThan = more,
		lessThan = less,
		moreEqualThan = moreE,
		lessEqualThan = lessE,
		list = list,
		listByBool = listByBool,
		listNoNil = listWithoutNilAndOrder,
		listSub = listSub,
		listLen = listLen,
		exitInArray = exitInArray,
		battle = battle,
		_exEnv = exEnv
	}

	local p = GlobalBaseEnv

	for k, v in pairs(battle.ResumeHpFrom) do
		p[k .. "RHpIdx"] = v
	end

	for k, v in pairs(battle.ValueType) do
		p[k .. "ValIdx"] = v
	end

	for k, v in pairs(battle.DamageFrom) do
		p[k .. "DmgIdx"] = v
	end

	exportFuncForGlobal("self", battleCsv.CsvObject)
	exportFuncForGlobal("scene", battleCsv.CsvScene)
	exportFuncForGlobal("skill", battleCsv.CsvSkill)
	exportFuncForGlobal("buff", battleCsv.CsvBuff)

	p.__index = p

	setmetatable(p, {
		__newindex = function(t, k, v)
			error("you could not write in GlobalBaseEnv with " .. k)
		end
	})

	return p
end

function battleCsv.doFormula(strOrTable, env, key)
	if env.fillEnv then
		env:fillEnv(makeGlobalBaseEnv(env))
	else
		setmetatable(env, makeGlobalBaseEnv(env))
	end

	return eval.doFormula(strOrTable, env, key)
end

function battleCsv.doFindFormula(strOrTable, env, globalCsvEnv)
	if env.fillEnv then
		env:fillEnv(makeGlobalBaseEnv(globalCsvEnv))
	else
		setmetatable(env, makeGlobalBaseEnv(env))
	end

	return eval.doFormula(strOrTable, env)
end

assert(ObjectAttrs.AttrsTable, "attrs require order error")

local ImmediateFormulaKeys = {}

for k, _ in pairs(ObjectAttrs.AttrsTable) do
	ImmediateFormulaKeys[k] = true
end

ImmediateFormulaKeys.lastMp1 = true

function battleCsv.doFormulaTable(sOrT, env)
	if not sOrT then
		return
	end

	if type(sOrT) == "table" then
		local ret = {}

		for k, v in csvMapPairs(sOrT) do
			if k == "input" or k == "process" then
				ret[k] = v
			else
				ret[k] = battleCsv.doFormulaTable(v, env)
			end
		end

		return ret
	end

	local v = tonumber(sOrT)

	if v then
		return v
	end

	if ImmediateFormulaKeys[sOrT] then
		return sOrT
	end

	if type(sOrT) == "boolean" then
		return sOrT
	end

	return battleCsv.doFormula(sOrT, env)
end

function battleCsv.makeFindEnv(caster, selectedObj, args)
	local forceNumber = battlePlay.Gate.ForceNumber
	local env = {
		self = caster,
		selectObj = selectedObj,
		skillSegType = args and args.skillSegType,
		skillFixType = args and args.skillFixType,
		skill = args and args.skill,
		force = selectedObj and selectedObj.force or caster.force,
		forceNumber = forceNumber,
		rowNumber = forceNumber / 2,
		getRowAndColumn = battleEasy.getRowAndColumn,
		mirrorSeat = battleEasy.mirrorSeat,
		attackRangeExtension = battleEasy.attackRangeExtension,
		csvSelf = battleCsv.CsvObject.newWithCache(caster),
		csvSelectObj = battleCsv.CsvObject.newWithCache(selectedObj),
		doFormula = eval.doFormula,
		getfenv = getfenv,
		dumps = dumps,
		trigger = args.trigger,
		addAttackRangeObjs = args.addAttackRangeObjs,
		secSelectObjs = args.secSelectObjs,
		extraTargets = args.extraTargets,
		ignoreReplaceData = args and args.ignoreReplaceData,
		getSelectableExObj = args and args.getSelectableExObj,
		inputUseOtherProcess = args and args.inputUseOtherProcess,
		processUseOtherProcess = args and args.processUseOtherProcess
	}

	env.env = env
	env.csvEnv = {
		self = battleCsv.CsvObject.newWithCache(caster),
		scene = battleCsv.CsvScene.newWithCache(caster.scene),
		skill = env.skill and battleCsv.CsvSkill.newWithCache(env.skill) or battleCsv.NilSkill,
		buff = battleCsv.NilBuff
	}

	return env
end

function battleCsv.makeProtectedEnv(obj, skill, buff)
	local scene = obj and obj.scene or scene and scene.scene or buff and buff.scene

	assert(scene, "no scene be contained in params")

	local p = {
		scene = battleCsv.CsvScene.newWithCache(scene)
	}

	p.env = p

	if obj then
		p.self = battleCsv.CsvObject.newWithCache(obj)
	end

	if skill then
		p.skill = battleCsv.CsvSkill.newWithCache(skill)
		p.owner = p.self
	end

	if buff then
		p.buff = battleCsv.CsvBuff.newWithCache(buff)
		p.caster = buff.caster and buff.caster == obj and p.self or battleCsv.CsvObject.newWithCache(buff.caster)
		p.holder = battleCsv.CsvObject.newWithCache(buff.holder)
		p.target = p.holder
		p.fromSkillLevel = buff.fromSkillLevel
		p.buffCfgID = buff.cfgId
	end

	local pp = protectedEnv(p)

	pp:fillEnv(makeGlobalBaseEnv(pp), true)

	return pp
end

function battleCsv.makeDamageProcessEnv(attacker, target, record, attr)
	local scene = attacker and attacker.scene or target and target.scene

	assert(scene, "no scene be contained in params")

	local p = {
		arg = record.args,
		scene = battleCsv.CsvScene.newWithCache(scene),
		processId = record.id
	}

	p.env = p
	p.setBaseAttr = ObjectAttrs.setBaseAttr
	p.addBaseAttr = ObjectAttrs.addBaseAttr
	p.updateMaxBaseAttr = ObjectAttrs.updateMaxBaseAttr
	p.isAttr = functools.partial(function(attrTab, key)
		return attrTab[key] and true or false
	end, ObjectAttrs.AttrsTable)
	p.sceneTag = scene.sceneTag

	local _attr, _args = {}

	for name, v in pairs(attr) do
		if not ObjectAttrs.AttrsTable[name] then
			p[name] = v
		else
			_attr[name] = v
			p[name] = function(self)
				return self.final[name]
			end
		end
	end

	p.base = table.salttable(_attr)
	p.buff = table.salttable(_attr)
	p.final = table.salttable(_attr)
	p.addBuffFlag = functools.partial(function(self, flags)
		if not self.arg.buffFlag then
			self.arg.buffFlag = {}
		end

		local buffFlagHash = arraytools.hash(self.arg.buffFlag)

		for k, v in ipairs(flags) do
			if not buffFlagHash[v] then
				table.insert(self.arg.buffFlag, v)
			end
		end
	end, p)
	p.setValue = functools.partial(function(self, keys, values)
		for idx, key in ipairs(keys) do
			if self.isAttr(key) then
				self:setBaseAttr(key, values[idx])
			else
				self[key] = values[idx]
			end
		end

		return self
	end, p)
	p.setSign = functools.partial(function(self, runProcessIds, jumpProcessIds, signVal, mode)
		local runProcessIdsHash = arraytools.hash(runProcessIds)
		local jmpProcessIdsHash = arraytools.hash(jumpProcessIds)
		local whiteListModeFunc = {
			function()
				if jmpProcessIdsHash[self.processId] then
					return "jump"
				else
					return "run"
				end
			end,
			function()
				if runProcessIdsHash[self.processId] then
					return "run"
				else
					return "jump"
				end
			end
		}

		if mode then
			return whiteListModeFunc[mode]()
		end

		if runProcessIdsHash[self.processId] then
			return signVal or "run"
		end

		if jmpProcessIdsHash[self.processId] then
			return "jump"
		end
	end, p)

	if attacker then
		p.attacker = battleCsv.CsvObject.newWithCache(attacker)
	end

	if target then
		p.target = battleCsv.CsvObject.newWithCache(target)
	end

	return p
end

local function getVarForEnv(protected, args, key)
	local pobj = rawget(protected, key)
	local obj = args[key]

	if obj then
		if pobj then
			assert(pobj.model == obj, string.format("%s not same in protected, %s, %s", key, tostring(pobj.model), tostring(obj)))

			return nil, obj
		else
			local cls = battleCsv.Model2CsvCls[tj.type(obj)]

			if cls then
				return cls.newWithCache(obj), obj
			end

			return obj, obj
		end
	else
		return nil, pobj and pobj.model
	end
end

function battleCsv.fillFuncEnv(protected, args)
	args = args or {}

	local added = {}
	local selfEnv, self = getVarForEnv(protected, args, "self")

	args.self = nil

	if selfEnv then
		added.self = selfEnv
	end

	if self and self.curAttackMeObj then
		added.attackMeObj = battleCsv.CsvObject.newWithCache(self.curAttackMeObj)
	end

	local skillEnv, skill = getVarForEnv(protected, args, "skill")

	args.skill = nil

	if skillEnv then
		added.skill = skillEnv
		added.owner = protected.obj
	end

	added.skillLevel = skill and skill:getLevel() or 1

	local targetEnv, target = getVarForEnv(protected, args, "target")

	added.target = targetEnv
	args.target = nil

	local buffEnv, buff = getVarForEnv(protected, args, "buff")

	args.buff = nil

	if buffEnv then
		added.buff = buffEnv
		added.caster = battleCsv.CsvObject.newWithCache(buff.caster)
		added.holder = battleCsv.CsvObject.newWithCache(buff.holder)
		added.target = added.target or added.holder
		added.fromSkillLevel = buff.fromSkillLevel
	end

	for k, v in pairs(args) do
		args[k] = getVarForEnv(protected, args, k)
	end

	for k, v in pairs(added) do
		assert(args[k] == nil, string.format("`%s` already in args", k))

		args[k] = v
	end

	return protected:fillEnvInFront(args)
end

function battleCsv.makeEnv(args)
	local protected = battleCsv.makeProtectedEnv(args.self, args.skill, args.buff)

	args.self = nil
	args.skill = nil
	args.buff = nil

	return battleCsv.fillFuncEnv(protected, args)
end
