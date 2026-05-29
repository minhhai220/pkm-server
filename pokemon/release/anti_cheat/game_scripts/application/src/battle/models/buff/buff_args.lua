local BuffArgs = {}

globals.BuffArgs = BuffArgs

local BuffBaseCheckList = {
	"value",
	"buffValueFormula"
}
local CorTBuff1CheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"cfgId",
		"overlayCount",
		"id",
		"holderID",
		"casterID"
	}
})
local CastBuffCheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"prob",
		"lifeRound"
	}
})
local CorTBuff2CheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"prob",
		"lifeRound",
		"overlayCount"
	}
})
local AtOnceTransform1CheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"value",
		"overlayCount",
		"cfgId",
		"oldBuff",
		"oldHolder",
		"targetType",
		"lifeRound"
	}
})
local AtOnceTransform2CheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"prob",
		"lifeRound",
		"overlayCount"
	}
})
local TransformCheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"cfgId",
		"value",
		"lifeRound",
		"overlayCount"
	}
})
local SkillCheckList = {
	"buffValueFormula",
	"value",
	"fromSkillId",
	"skillLevel",
	"lifeRound",
	"prob",
	"index",
	"skillCfg"
}
local SceneCheckList = {
	"lifeRound",
	"prob",
	"value",
	"buffValue1"
}
local SwapBuffWithOtherCheckList = arraytools.merge({
	BuffBaseCheckList,
	{
		"prob",
		"lifeRound",
		"overlayCount"
	}
})
local fromInfoMap = {
	cfgId = "from buff cfgId = ",
	skillId = "from skillId = ",
	processId = "from skill processId = "
}

local function getCatchKey(args)
	for k, v in pairs(fromInfoMap) do
		if args[k] then
			return v .. args[k]
		end
	end

	return ""
end

local function check(t, list, args)
	if device.platform ~= "windows" then
		return t
	end

	local catchKey = getCatchKey(args)

	for __, key in ipairs(list) do
		assert(t[key] ~= nil, key .. " is nil, " .. catchKey)
	end

	return t
end

local function addEnv(t, env, args)
	assertInWindows(type(env) == "table", "env is not table," .. getCatchKey(args))

	t.buffValueFormulaEnv = env

	return t
end

function BuffArgs.fromCopyOrTransfer1(_buff)
	local t = {
		value = _buff.args.value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		cfgId = _buff.cfgId,
		overlayCount = _buff:getOverLayCount(),
		id = _buff.id,
		holderID = _buff.holder.id,
		casterID = _buff.caster.id,
		lifeRound = _buff:getLifeRound()
	}

	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _buff.cfgId
	})

	return check(t, CorTBuff1CheckList, {
		cfgId = _buff.cfgId
	})
end

function BuffArgs.fromCopyOrTransfer2(copyOrTransfer1Args, _lifeRound, _curSkill)
	if _lifeRound == 0 then
		_lifeRound = copyOrTransfer1Args.lifeRound
	end

	local t = {
		prob = 1,
		value = copyOrTransfer1Args.value,
		buffValueFormula = copyOrTransfer1Args.buffValueFormula,
		skillCfg = copyOrTransfer1Args.skillCfg,
		lifeRound = _lifeRound,
		overlayCount = copyOrTransfer1Args.overlayCount,
		curSkill = _curSkill
	}

	t = addEnv(t, copyOrTransfer1Args.buffValueFormulaEnv, {
		cfgId = copyOrTransfer1Args.cfgId
	})

	return check(t, CorTBuff2CheckList, {
		cfgId = copyOrTransfer1Args.cfgId
	})
end

function BuffArgs.weatherCopyArgs(_buff)
	local t = {
		prob = 1,
		value = _buff.args.value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		lifeRound = _buff.lifeRound,
		overlayCount = _buff:getOverLayCount(),
		isAuraType = _buff.isAuraType
	}

	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _buff.cfgId
	})

	return t
end

function BuffArgs.fromAtOnceTransform1(_buff, _cfgId, _value, _targetType, buffRound, newBuffCfg)
	local t = {
		value = _value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		overlayCount = _buff:getOverLayCount(),
		cfgId = _cfgId,
		oldBuff = _buff,
		oldHolder = _buff.holder,
		targetType = _targetType,
		lifeRound = buffRound
	}
	local replaceBuffCfg = {}

	for _, attr in ipairs(newBuffCfg) do
		replaceBuffCfg[attr] = _buff.csvCfg[attr]
	end

	t.replaceBuffCfg = replaceBuffCfg
	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _cfgId
	})

	return check(t, AtOnceTransform1CheckList, {
		cfgId = _cfgId
	})
end

function BuffArgs.fromAtOnceTransform2(data)
	local t = {
		prob = 1,
		value = data.value,
		buffValueFormula = data.buffValueFormula,
		skillCfg = data.skillCfg,
		replaceBuffCfg = data.replaceBuffCfg,
		lifeRound = data.lifeRound,
		overlayCount = data.overlayCount
	}

	t = addEnv(t, data.buffValueFormulaEnv, {
		cfgId = data.cfgId
	})

	return check(t, AtOnceTransform2CheckList, {
		cfgId = data.cfgId
	})
end

function BuffArgs.fromTransform(_buff)
	local t = {
		cfgId = _buff.cfgId,
		value = _buff.value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		overlayCount = _buff:getOverLayCount(),
		lifeRound = _buff:getLifeRound()
	}

	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _buff.cfgId
	})

	return check(t, TransformCheckList, {
		cfgId = _buff.cfgId
	})
end

function BuffArgs.fromSwapBuffWithOther(_buff, _lifeRound)
	local t = {
		prob = 1,
		value = _buff.value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		cfgId = _buff.cfgId,
		lifeRound = _lifeRound,
		overlayCount = _buff.overlayCount
	}

	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _buff.cfgId
	})

	return check(t, SwapBuffWithOtherCheckList, {
		cfgId = _buff.cfgId
	})
end

function BuffArgs.fromOtherBuff(_buff, args, effectFuncName)
	_buff.protectedEnv = battleCsv.fillFuncEnv(_buff.protectedEnv, {
		self2 = _buff.caster,
		target2 = _buff.holder,
		trigger = _buff.triggerEnv
	})
	_buff.castBuffEnvAdded = true
	args.buffValueFormulaEnv = _buff.protectedEnv
	args.buffValueFormula = args.value

	local ret

	if args.prob and (string.find(args.prob, "star()") or string.find(args.prob, "flagZ")) then
		ret, args.prob = xpcall(function()
			return _buff:cfg2Value(args.prob)
		end, function(error)
			return gBuffEffect[effectFuncName].prob or 1
		end)
	else
		args.prob = 1
	end

	ret, args.lifeRound = xpcall(function()
		return _buff:cfg2Value(args.lifeRound)
	end, function(error)
		return gBuffEffect[effectFuncName].lifeRound or 1
	end)
	ret, args.value = xpcall(function()
		return _buff:cfg2Value(args.value)
	end, function(error)
		local buffEffetCfg = gBuffEffect[effectFuncName]

		return #buffEffetCfg.value > 0 and _buff:cfg2Value(buffEffetCfg.value) or 0
	end)

	_buff.protectedEnv:resetEnv()

	_buff.castBuffEnvAdded = false

	return args
end

function BuffArgs.fromOtherSkill(_skill, _extraTarget, _obj, args, effectFuncName)
	local extra

	if _extraTarget then
		extra = _extraTarget[1]
	end

	_skill.protectedEnv:resetEnv()

	local env = battleCsv.fillFuncEnv(_skill.protectedEnv, {
		lastMp1 = "lastMp1",
		target = _obj,
		extraTarget = extra or _skill.owner:getCurTarget()
	})
	local prob = 1
	local lifeRound, values, ret

	ret, lifeRound = xpcall(function()
		return battleCsv.doFormula(args.lifeRound, env)
	end, function(error)
		return gBuffEffect[effectFuncName].lifeRound or 1
	end)

	if string.find(args.prob, "star()") or string.find(args.prob, "flagZ") then
		ret, prob = xpcall(function()
			return battleCsv.doFormula(args.prob, env)
		end, function(error)
			return gBuffEffect[effectFuncName].prob or 1
		end)
	end

	ret, values = xpcall(function()
		return battleCsv.doFormula(args.value, env)
	end, function(error)
		local buffEffetCfg = gBuffEffect[effectFuncName]

		return #buffEffetCfg.value > 0 and battleCsv.doFormula(buffEffetCfg.value, env) or 0
	end)

	local t = {
		buffValueFormula = args.value,
		value = values,
		fromSkillId = _skill.id,
		skillLevel = _skill:getLevel(),
		lifeRound = lifeRound,
		prob = prob,
		lastProcessTargets = _extraTarget,
		skillCfg = args.skillCfg or _skill.cfg
	}

	if t.skillCfg.skillType == battle.SkillType.PassiveAura then
		t.isAuraType = true
	end

	t = addEnv(t, env, {
		skillId = _skill.id
	})

	return t
end

function BuffArgs.fromSkill(_skill, _extraTarget, _obj, _processCfg, _buffCfg, _i)
	local extra

	if _extraTarget then
		extra = _extraTarget[1]
	end

	_skill.protectedEnv:resetEnv()

	local env = battleCsv.fillFuncEnv(_skill.protectedEnv, {
		lastMp1 = "lastMp1",
		target = _obj,
		extraTarget = extra or _skill.owner:getCurTarget()
	})
	local lifeRound = battleCsv.doFormula(_processCfg.buffLifeRound[_i], env)
	local prob = battleCsv.doFormula(_processCfg.buffProb[_i], env)
	local values = battleCsv.doFormula(_processCfg.buffValue1[_i], env)
	local needChange = _buffCfg.easyEffectFunc == "changeImage" or _buffCfg.easyEffectFunc == "changeUnit"

	if type(values) == "table" and needChange then
		values = values[ymrand.random(1, table.length(values))]
	end

	local t = {
		buffValueFormula = _processCfg.buffValue1[_i],
		value = values,
		fromSkillId = _skill.id,
		skillLevel = _skill:getLevel(),
		lifeRound = lifeRound,
		prob = prob,
		lastProcessTargets = _extraTarget,
		index = _i,
		skillCfg = _skill.cfg
	}

	if t.skillCfg.skillType == battle.SkillType.PassiveAura then
		t.isAuraType = true
	end

	t = addEnv(t, env, {
		processId = _processCfg.id
	})

	return check(t, SkillCheckList, {
		processId = _processCfg.id
	})
end

function BuffArgs.fromSceneBuff(data)
	local t = {
		isSceneBuff = true,
		lifeRound = data.lifeRound,
		prob = data.prob,
		value = data.value,
		buffValue1 = data.buffValue1
	}

	return check(t, SceneCheckList, {
		cfgId = data.cfgId
	})
end

local AuraCasterBuff = {
	"auraBuff"
}

function BuffArgs.fromCastBuff(buff, originArgs, lifeRound, value, prob, fieldSub)
	local t = {
		skillCfg = buff.args.skillCfg,
		skillLevel = buff.fromSkillLevel,
		lifeRound = lifeRound,
		fromSkillId = buff.args.fromSkillId,
		fromBuffID = buff.id,
		value = value,
		buffValueFormula = originArgs.refresh_value or originArgs.value,
		buffValueFormulaEnv = buff.protectedEnv,
		prob = prob,
		source = buff:toString(),
		fieldSub = fieldSub,
		reboundBuffId = buff.args.reboundBuffId
	}

	if buff.csvCfg.easyEffectFunc == "auraBuff" or buff.args.isAuraType then
		t.isAuraType = true
	end

	return check(t, CastBuffCheckList, {
		cfgId = buff.cfgId
	})
end

function BuffArgs.fromRegisterBuff(buff)
	local t = {
		prob = 1,
		cfgId = buff.cfgId,
		caster = buff.caster,
		holder = buff.holder,
		overlayCount = buff:getOverLayCount(),
		lifeRound = buff:getLifeRound(),
		value = buff:getValue(),
		fromSkillId = buff.args.fromSkillId,
		fromBuffID = buff.args.fromBuffID,
		buffValueFormula = buff.args.buffValueFormula,
		source = buff.source
	}

	t = addEnv(t, buff.args.buffValueFormulaEnv, {
		cfgId = buff.cfgId
	})

	return t
end

function BuffArgs.fromApplyRegisterBuff(args)
	local t = {
		prob = 1,
		overlayCount = args.overlayCount,
		lifeRound = args.lifeRound,
		value = args.value,
		fromSkillId = args.fromSkillId,
		fromBuffID = args.fromBuffID,
		buffValueFormula = args.buffValueFormula,
		source = args.source,
		fieldSub = args.isFieldSubBuff,
		isAuraType = args.isAuraType
	}

	t = addEnv(t, args.buffValueFormulaEnv, {
		cfgId = args.cfgId
	})

	return t
end

function BuffArgs.fromMultiplyOverlays(_buff)
	local t = {
		prob = 1,
		overlayCount = 1,
		value = _buff.value,
		buffValueFormula = _buff.args.buffValueFormula,
		skillCfg = _buff.args.skillCfg,
		lifeRound = _buff.args.lifeRound,
		isAuraType = _buff.isAuraType
	}

	t = addEnv(t, _buff.args.buffValueFormulaEnv, {
		cfgId = _buff.cfgId
	})

	return check(t, CorTBuff2CheckList, {
		cfgId = _buff.cfgId
	})
end
