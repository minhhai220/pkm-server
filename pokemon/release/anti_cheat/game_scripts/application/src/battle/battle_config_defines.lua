-- chunkname: @src.battle.battle_config_defines

-- 标记



local PreloadIndexFuncs = {}

local function _readonly(name, t)
	if device.platform == "windows" then
		globals[name] = csvReadOnlyInWindows(t, name)

		printDebug("battle_config_defines - proxy index %s", name)
	end
end

local function _addPreloadGlobalIndex(name, initFunc)
	table.insert(PreloadIndexFuncs, {
		name = name,
		init = function()
			if initFunc == nil then
				if globals[name] then
					local size = itertools.size(globals[name])
				end

				return
			end

			if globals[name] == nil then
				local t = {}

				globals[name] = t

				initFunc(t)

				if name ~= "gFormulaConst" then
					_readonly(name, t)
				end
			end
		end
	})
end

_addPreloadGlobalIndex("gMonsterCsv")
_addPreloadGlobalIndex("gSceneDemonCorrectCsv", function(t)
	for k, v in csvPairs(csv.scene_demon_correct) do
		if t[v.index] == nil then
			t[v.index] = {}
		end

		t[v.index][v.wave] = v
	end
end)
_addPreloadGlobalIndex("gGameEndSpeRuleCsv", function(t)
	for k, v in csvPairs(csv.game_end_special_rule) do
		if t[v.markID] == nil then
			t[v.markID] = {}
		end

		t[v.markID] = v
	end
end)
_addPreloadGlobalIndex("gWeatherActiveCsv", function(t)
	for k, v in csvPairs(csv.weather_system.active) do
		if t[v.weatherID] == nil then
			t[v.weatherID] = {}
		end

		table.insert(t[v.weatherID], v)
	end
end)
_addPreloadGlobalIndex("gProcessEventCsv", function(t)
	for k, v in csvPairs(csv.skill_process) do
		if v.effectEventID then
			t[k] = csv.effect_event[v.effectEventID]
		end
	end
end)
_addPreloadGlobalIndex("gEffectByEventCsv")
_addPreloadGlobalIndex("gEffectOptionCsv")
_addPreloadGlobalIndex("gDealGroup2ExtraObjectCsv", function(t)
	for k, v in csvPairs(csv.extra_object) do
		t[v.dealGroup] = v
	end
end)
_addPreloadGlobalIndex("gFormulaConst", function(t)
	local formulaConst = {}

	for _, v in csvPairs(csv.base_attribute.formula_const) do
		if #v.key > 0 then
			formulaConst[v.key] = v.value
		end
	end

	local function evalData(key)
		local evalEnv = {
			c = gFormulaConst,
			buffFilterCsvMap = battleEasy.newBuffFilterCsvMap,
			tostring = tostring,
			list = function(...)
				return {
					...
				}
			end
		}

		evalEnv.__index = evalEnv

		setmetatable(evalEnv, {
			__newindex = function(_, k, v)
				error("you could not write in gFormulaConst evalEnv with " .. k)
			end
		})

		local s = formulaConst[key]

		assert(s, "no formula const " .. key)

		local v = tonumber(s)

		if v then
			return v
		end

		local f = cache.createFormula(s)

		if f == nil then
			errorInWindows("evalData key:%s, s:%s", tostring(key), tostring(s))
		end

		return eval.doFormula(s, evalEnv)
	end

	setmetatable(t, {
		__index = function(_, k)
			if k == "__proxy" or k == "__immutable" then
				return
			end

			local keys = string.split(k, "_")

			if #keys == 1 then
				local ret = evalData(keys[1])

				if type(ret) ~= "table" then
					return function()
						return ret
					end
				end

				if ret.__spstructure then
					local function retf()
						return ret
					end

					rawset(t, k, retf)

					return retf
				end
			end

			local isUnpack = keys[#keys] == "oc"
			local ret = {}

			for _, key in ipairs(keys) do
				if key == "oc" then
					break
				end

				arraytools.merge_two_inplace(ret, evalData(key))
			end

			local function retf()
				if isUnpack then
					return unpack(ret)
				else
					return ret
				end
			end

			rawset(t, k, retf)

			return retf
		end,
		__newindex = function(_, k, v)
			error("could not write in here " .. k)
		end
	})
end)

local buffGroupEnv

local function buffGroupDoFormula(strOrTable)
	if not buffGroupEnv then
		assert(gFormulaConst, "gFormulaConst is nil")

		buffGroupEnv = {
			c = gFormulaConst,
			list = function(...)
				return {
					...
				}
			end,
			listSub = function(a, b)
				local ret = {}
				local hashB = arraytools.hash(b)

				for _, v in ipairs(a) do
					if not hashB[v] then
						table.insert(ret, v)
					end
				end

				return ret
			end
		}
		buffGroupEnv.__index = buffGroupEnv

		setmetatable(buffGroupEnv, {
			__newindex = function(_, k, v)
				error("you could not write in buffGroupEnv with " .. k)
			end
		})
	end

	local ret

	if type(strOrTable) == "table" then
		ret = {}

		for i, v in ipairs(strOrTable) do
			local data = eval.doFormula(v, buffGroupEnv)

			if type(data) == "table" then
				ret = arraytools.merge_two_inplace(ret, data)
			else
				table.insert(ret, data)
			end
		end
	else
		ret = eval.doFormula(strOrTable, buffGroupEnv)
	end

	return ret
end

_addPreloadGlobalIndex("gBuffGroupRelationCsv", function(t)
	for k, v in csvPairs(csv.buff_group_relation) do
		local _immuneGroup = {}

		for _, v2 in ipairs(v.immuneGroup) do
			_immuneGroup[#_immuneGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _dispelGroup = {}

		for _, v2 in ipairs(v.dispelGroup) do
			_dispelGroup[#_dispelGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _powerGroup = {}

		for _, v2 in ipairs(v.powerGroup) do
			_powerGroup[#_powerGroup + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _immuneFlag = {}

		for _, v2 in ipairs(v.immuneFlag) do
			_immuneFlag[#_immuneFlag + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _dispelFlag = {}

		for _, v2 in ipairs(v.dispelFlag) do
			_dispelFlag[#_dispelFlag + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		local _powerFlag = {}

		for _, v2 in ipairs(v.powerFlag) do
			_powerFlag[#_powerFlag + 1] = arraytools.hash(buffGroupDoFormula(v2))
		end

		t[k] = {
			immuneGroup = _immuneGroup,
			dispelGroup = _dispelGroup,
			powerGroup = _powerGroup,
			immuneFlag = _immuneFlag,
			dispelFlag = _dispelFlag,
			powerFlag = _powerFlag,
			immuneEffect = v.immuneEffect
		}
	end
end)
_addPreloadGlobalIndex("gBuffEffect", function(t)
	for k, v in csvPairs(csv.buff_effect) do
		t[v.easyEffectFunc] = v
	end
end)
_addPreloadGlobalIndex("gSceneAttrCorrect", function(t)
	for k, v in csvPairs(csv.base_attribute.scene_attr_correct) do
		t[v.sceneID] = v
		v.hpMaxC = v.hpC
		v.mp1MaxC = v.mp1C
	end

	return t
end)
_addPreloadGlobalIndex("gCPCorrectionGroups", function(t)
	for k, v in csvPairs(csv.combat_power_correction) do
		t[k] = arraytools.hash(buffGroupDoFormula(v.groupKey))
	end
end)
_addPreloadGlobalIndex("gExtraRoundTrigger", function(t)
	for k, v in csvPairs(csv.extra_round_trigger) do
		t[k] = {
			limitBuff = arraytools.hash(v.limitBuff),
			forbiddenBuff = arraytools.hash(v.forbiddenBuff),
			forbiddenPassiveSkill = arraytools.hash(v.forbiddenPassiveSkill),
			cfgIds = arraytools.hash(v.cfgIds),
			disableBattleState = v.disableBattleState,
			enableActiveSkillMp = v.enableActiveSkillMp
		}
	end
end)
_addPreloadGlobalIndex("gDamageCorrect", function(t)
	for k, v in csvPairs(csv.damage_correct) do
		t[v.type] = t[v.type] or {}

		table.insert(t[v.type], v)
	end
end)

return PreloadIndexFuncs
