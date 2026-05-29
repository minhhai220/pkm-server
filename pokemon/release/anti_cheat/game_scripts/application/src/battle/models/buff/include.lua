require("battle.models.buff.helper")
require("battle.models.buff.buff_node")
require("battle.models.buff.buff_global")
require("battle.models.buff.buff")
require("battle.models.buff.buff_effect")
require("battle.models.buff.buff_effect2")
require("battle.models.buff.buff_effect3")
require("battle.models.buff.buff_effect4")
require("battle.models.buff.buff_effect5")
require("battle.models.buff.buff_effect6")
require("battle.models.buff.buff_scene")
require("battle.models.buff.buff_target")
require("battle.models.buff.buff_args")
require("battle.models.buff.spec.aura_buff")

local immuneControlGroupId = 999999
local BREAK_MARK = true
local blackBoard = {}
local BuffCantAddReason = {
	"holder死亡",
	"光环buff且caster死亡",
	"holder无法被加上",
	"场景限制(gateLimit)",
	"概率计算失败",
	"场景限制(craftTriggerLimit)",
	"乱斗禁止buff添加",
	"免疫(log打开buffImmuneEffect)",
	"叠加类型"
}
local BuffImmuneReason = {
	"权限组",
	"过滤flag或group(log打开filterBuffGroup和filterBuffFlag)",
	"夺取",
	"免疫buff",
	nil,
	"权限flag"
}
local AddBuffToHeroReasonIndex = {
	DelayBuff = 9,
	Success = 10,
	AddFail = 8,
	InfluenceCanAdd = 7,
	AuraBuff = 6,
	InfluenceCanTakeEffect = 5,
	LifeRound = 4,
	Prob = 3,
	Miss = 2,
	Loop = 1
}
local AddBuffToHeroReason = {
	[AddBuffToHeroReasonIndex.Loop] = "死循环",
	[AddBuffToHeroReasonIndex.Miss] = "buff添加闪避",
	[AddBuffToHeroReasonIndex.Prob] = "buff概率失败",
	[AddBuffToHeroReasonIndex.LifeRound] = "调整生命周期",
	[AddBuffToHeroReasonIndex.InfluenceCanTakeEffect] = "influenceCanTakeEffect",
	[AddBuffToHeroReasonIndex.AuraBuff] = "isAuraType",
	[AddBuffToHeroReasonIndex.InfluenceCanAdd] = "influenceCanAdd",
	[AddBuffToHeroReasonIndex.AddFail] = "添加失败",
	[AddBuffToHeroReasonIndex.DelayBuff] = "延迟添加",
	[AddBuffToHeroReasonIndex.Success] = "添加成功"
}
local OverlayTypeConditions

OverlayTypeConditions = {
	[battle.BuffOverlayType.Normal] = function(holderBuff, buffCfg)
		return BREAK_MARK, false, false
	end,
	[battle.BuffOverlayType.Cover] = function(holderBuff, buffCfg)
		if holderBuff.isAuraType then
			return BREAK_MARK, false, true
		end

		return BREAK_MARK, true, true
	end,
	[battle.BuffOverlayType.Overlay] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < blackBoard.overlayLimit then
			return BREAK_MARK, false, true
		end

		return BREAK_MARK, false, true, battle.BuffCantAddReason.overlayLimit
	end,
	[battle.BuffOverlayType.OverlayDrop] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < blackBoard.overlayLimit then
			return BREAK_MARK, false, true
		end

		return BREAK_MARK, false, false, battle.BuffCantAddReason.overlayLimit
	end,
	[battle.BuffOverlayType.CoverValue] = function(holderBuff, buffCfg)
		local args = blackBoard.args
		local value = args.value
		local oldVal = holderBuff.args.value

		if type(value) == "number" and type(oldVal) == "number" then
			if math.abs(value) <= math.abs(oldVal) then
				return BREAK_MARK, false, false
			end

			return BREAK_MARK, true, true
		else
			errorInWindows("buff check overlay %d, old %s, new %s", buffCfg.overlayType, value, oldVal)
		end
	end,
	[battle.BuffOverlayType.CoverLifeRound] = function(holderBuff, buffCfg)
		local args = blackBoard.args
		local round = args.lifeRound
		local oldRound = holderBuff.args.lifeRound

		if type(round) == "number" and type(oldRound) == "number" then
			if round <= oldRound then
				return BREAK_MARK, false, false
			end

			return BREAK_MARK, true, true
		else
			errorInWindows("buff check overlay %d, old %s, new %s", buffCfg.overlayType, round, oldRound)
		end
	end,
	[battle.BuffOverlayType.IndeLifeRound] = function(holderBuff, buffCfg)
		if holderBuff:getOverLayCount() < blackBoard.overlayLimit then
			return BREAK_MARK, false, true
		end

		return BREAK_MARK, false, false, battle.BuffCantAddReason.overlayLimit
	end,
	[battle.BuffOverlayType.Coexist] = function(holderBuff, buffCfg)
		if OverlayTypeConditions.CoexistLessCheck(buffCfg) then
			return BREAK_MARK, true, true
		end

		return BREAK_MARK, false, false, battle.BuffCantAddReason.overlayLimit
	end,
	[battle.BuffOverlayType.CoexistLifeRound] = function(holderBuff, buffCfg)
		if OverlayTypeConditions.CoexistLessCheck(buffCfg) then
			return BREAK_MARK, true, true
		end

		return BREAK_MARK, false, true, battle.BuffCantAddReason.overlayLimit
	end,
	CoexistLessCheck = function(buffCfg)
		local cfgId = blackBoard.cfgId
		local holder = blackBoard.holder

		if holder.buffOverlayCount[cfgId] < blackBoard.overlayLimit then
			return true
		end
	end
}
BuffModel.OverlayTypeConditions = OverlayTypeConditions

local BuffConditions = {
	function(holder, buffCfg)
		if not holder or holder:isRealDeath() then
			return BREAK_MARK, false, false
		end
	end,
	function(holder, buffCfg)
		local caster = blackBoard.caster
		local args = blackBoard.args

		if args.isAuraType and (not caster or caster:isDeath()) then
			return BREAK_MARK, false, false
		end
	end,
	function(holder, buffCfg)
		if not holder:checkBuffCanBeAdd(blackBoard.caster, buffCfg.ignoreCaster, buffCfg.ignoreHolder) then
			return BREAK_MARK, false, false
		end
	end,
	function(holder, buffCfg)
		local cfgId = blackBoard.cfgId

		if not holder.scene.buffGlobalManager:checkBuffCanAdd({
			csvCfg = buffCfg,
			cfgId = cfgId
		}, holder) then
			return BREAK_MARK, false, false
		end
	end,
	function(holder, buffCfg)
		local caster = blackBoard.caster
		local args = blackBoard.args
		local prob = args.prob
		local immuneRate = 0
		local immuneVal = 0
		local controlRate = 0
		local controlVal = 0
		local updateControlRateGroup

		local function getControlOverlayVal(type, startVal, obj)
			local val, _group = startVal

			if buffCfg.ignoreControlVal == 1 then
				return val
			end

			for _, data in obj:ipairsOverlaySpecBuff(type) do
				if not battleEasy.loseImmuneEfficacyCheck(holder, {
					type = type
				}) then
					val, _group = data.refreshProb(val, buffCfg.group, buffCfg.buffFlag)
					updateControlRateGroup = updateControlRateGroup or _group
				end
			end

			return val
		end

		local isControlType = battleEasy.groupRelationInclude(gBuffGroupRelationCsv[immuneControlGroupId].immuneGroup, buffCfg.group)

		if isControlType then
			immuneVal = battleEasy.loseImmuneEfficacyCheck(holder, {}, {
				"immuneControl"
			}) and 0 or holder:immuneControl()
		end

		immuneVal = getControlOverlayVal("immuneControlVal", immuneVal, holder)
		immuneRate = getControlOverlayVal("immuneControlAdd", immuneRate, holder)

		if caster then
			if isControlType then
				controlVal = battleEasy.loseImmuneEfficacyCheck(holder, {}, {
					"controlPer"
				}) and 0 or caster:controlPer()
			end

			controlVal = getControlOverlayVal("controlPerVal", controlVal, caster)
			controlRate = getControlOverlayVal("controlPerAdd", controlRate, caster)
		end

		prob = prob > 0 and (prob + controlVal - immuneVal) * (1 + controlRate - immuneRate) or 0
		prob = math.max(math.min(prob, 1), 0)

		if prob < 1 then
			local randret = ymrand.random()

			if prob < randret then
				if updateControlRateGroup then
					battleEasy.deferNotifyCantJump(holder.view, "showBuffImmuneEffect", updateControlRateGroup)
				end

				return BREAK_MARK, false, false, battle.BuffCantAddReason.prob
			end
		end
	end,
	function(holder, buffCfg)
		local cfgId = blackBoard.cfgId
		local scene = holder.scene
		local play = scene.play

		if scene:isCraftGateType() then
			local addTimes = play.craftBuffAddTimes[cfgId] and play.craftBuffAddTimes[cfgId][holder.force] or 0
			local limitType, limitTimes = scene.gateType

			if buffCfg.craftTriggerLimit then
				for _, limitArg in ipairs(buffCfg.craftTriggerLimit) do
					if type(limitArg) == "number" then
						limitTimes = limitArg
					else
						limitType, limitTimes = limitArg[1], limitArg[2]
					end

					if limitType == scene.gateType and addTimes and addTimes >= (limitTimes or math.huge) then
						return BREAK_MARK, false, false
					end
				end
			end
		end
	end,
	function(holder, buffCfg)
		local lastInfo = holder.scene:getSpecialSceneInfo()

		if lastInfo and lastInfo.data.forbiddenBuffs[buffCfg.easyEffectFunc] then
			for _, flag in ipairs(buffCfg.buffFlag) do
				if lastInfo.data.buffFlagMap[flag] then
					return
				end
			end

			return BREAK_MARK, false, false
		end
	end,
	function(holder, buffCfg)
		local cfgId = blackBoard.cfgId
		local args = blackBoard.args
		local caster = blackBoard.caster
		local buffGroupPower = csv.buff_group_power[buffCfg.groupPower]

		args.effectBuffs = {}

		local immuneResult, reason, sortBuffInfos = holder:buffImmuneEffect(cfgId, buffCfg.group, buffCfg.buffFlag, buffGroupPower, caster)

		lazylog.battle.buff.buffImmuneEffect({
			immuneResult = immuneResult,
			reason = BuffImmuneReason[reason],
			holder = holder,
			buffCfg = buffCfg,
			blackBoard = blackBoard,
			buffs = battleEasy.logImmuneInfos(immuneResult, reason, cfgId, buffCfg.group, buffCfg.buffFlag, buffGroupPower, holder, caster, sortBuffInfos)
		})

		if not immuneResult then
			return BREAK_MARK, false, false, reason
		end

		for _, buff in holder:iterBuffsWithCsvID(cfgId) do
			if buff.isOver == false then
				blackBoard.holderBuff = blackBoard.holderBuff or buff

				table.insert(args.effectBuffs, buff)
			end
		end
	end,
	function(holder, buffCfg)
		if blackBoard.holderBuff then
			return OverlayTypeConditions[buffCfg.overlayType](blackBoard.holderBuff, buffCfg)
		end
	end
}

BuffModel.BuffConditions = BuffConditions

local function checkBuffAddConditions(cfgId, holder, caster, args)
	local buffCfg = csv.buff[cfgId]
	-- 标记
	local overlayLimit = battleEasy.getOverlayLimit(caster, holder, buffCfg)

	if not buffCfg then
		return false
	end

	if args.isSceneBuff then
		return true
	end

	blackBoard = {
		cfgId = cfgId,
		holder = holder,
		caster = caster,
		args = args,
		overlayLimit = overlayLimit
	}

	for id, func in ipairs(BuffConditions) do
		local needBreak, canAdd, canTakeEffect, cantAddReason = func(holder, buffCfg)

		if needBreak then
			log.battle.buff.addCondition({
				cfgId = cfgId,
				holder = holder,
				caster = caster,
				info = BuffCantAddReason[id],
				canAdd = canAdd,
				canTakeEffect = canTakeEffect
			})

			return canAdd, canTakeEffect, cantAddReason
		end
	end

	return true, true
end

local OverlayTypeRefreshFuncs = {
	[battle.BuffOverlayType.Cover] = function(buff, holder, args, upv)
		if buff.isAuraType then
			upv.over = true

			return
		end

		buff:over({
			endType = battle.BuffOverType.overlay
		})
	end,
	[battle.BuffOverlayType.Overlay] = function(buff, holder, args, upv)
		if buff:getOverLayCount() < blackBoard.overlayLimit then
			buff:refresh(args, 1)

			upv.hasFull = false
		elseif buff:getOverLayCount() == blackBoard.overlayLimit then
			buff:refresh(args)
		end

		upv.triggerBuff = upv.triggerBuff or buff
	end,
	[battle.BuffOverlayType.CoverValue] = function(buff, holder, args, upv)
		local value = args.value
		local oldVal = buff.args.value

		if type(value) == "number" and buff.isNumberType and math.abs(value) > math.abs(oldVal) then
			buff:over({
				endType = battle.BuffOverType.overlay
			})
		end
	end,
	[battle.BuffOverlayType.CoverLifeRound] = function(buff, holder, args, upv)
		local round = args.lifeRound
		local oldRound = buff.args.lifeRound

		if type(round) == "number" and type(oldRound) == "number" and oldRound < round then
			buff:over({
				endType = battle.BuffOverType.overlay
			})
		end
	end,
	[battle.BuffOverlayType.IndeLifeRound] = function(buff, holder, args, upv)
		upv.hasFull = false

		buff:refresh(args, 1)

		upv.triggerBuff = upv.triggerBuff or buff
	end,
	[battle.BuffOverlayType.Coexist] = function(buff, holder, args, upv)
		local cfgId = upv.cfgId

		if holder.buffOverlayCount[cfgId] < blackBoard.overlayLimit and upv.isFirst then
			upv.hasFull = false
			holder.buffOverlayCount[cfgId] = holder.buffOverlayCount[cfgId] + 1
		end
	end,
	[battle.BuffOverlayType.CoexistLifeRound] = function(buff, holder, args, upv)
		if upv.isFirst then
			local cfgId = upv.cfgId

			if holder.buffOverlayCount[cfgId] < blackBoard.overlayLimit then
				holder.buffOverlayCount[cfgId] = holder.buffOverlayCount[cfgId] + 1
				upv.hasFull = false
			else
				upv.triggerBuff = upv.triggerBuff or buff
			end
		end

		buff:refresh(args, 1)
	end
}

OverlayTypeRefreshFuncs[battle.BuffOverlayType.OverlayDrop] = OverlayTypeRefreshFuncs[battle.BuffOverlayType.Overlay]
BuffModel.OverlayTypeRefreshFuncs = OverlayTypeRefreshFuncs

local function refreshHolderBuff(cfgId, holder, caster, args)
	local effectBuffs = args.effectBuffs

	args.effectBuffs = nil

	if not effectBuffs then
		return
	end

	local buffCfg = csv.buff[cfgId]
	local upv = {
		isFirst = true,
		over = false,
		hasFull = true,
		cfgId = cfgId
	}

	for _, buff in ipairs(effectBuffs) do
		if not buff.isOver then
			OverlayTypeRefreshFuncs[buffCfg.overlayType](buff, holder, args, upv)

			upv.isFirst = false
		end

		if upv.over then
			break
		end
	end

	local triggerBuff = upv.triggerBuff
	local over = upv.over

	if over then
		return
	end

	if triggerBuff then
		triggerBuff.holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffOverlayRefresh, {
			beAddBuff = battleCsv.CsvBuff.newWithCache(triggerBuff),
			hasFull = upv.hasFull
		})
	end
end

local function checkBuffLinkCond(holder, cfgId, group)
	local allBuffLinkVal = holder.scene.buffGlobalManager:getAllBuffLinkValue(holder.id)

	if not allBuffLinkVal or not next(allBuffLinkVal) then
		return {}
	end

	local sortedBuffLinkVal = {}

	for k, v in pairs(allBuffLinkVal) do
		if v.cfgId == cfgId and (type(v.groups) == "number" or itertools.include(v.groups, group)) then
			table.insert(sortedBuffLinkVal, {
				key = k,
				val = v
			})
		end
	end

	table.sort(sortedBuffLinkVal, function(a, b)
		return a.key < b.key
	end)

	return sortedBuffLinkVal
end

local function changeBuffModel(cfgId, holder, caster, args, transEffectType, transBuffHolder)
	local buffCfg = csv.buff[cfgId]
	local buffGroupPower = csv.buff_group_power[buffCfg.groupPower]

	if buffGroupPower.beChange == 0 then
		return cfgId, caster
	end

	local hasTransBuff = transBuffHolder:getOverlaySpecBuffBy(battle.OverlaySpecBuff.transformAttrBuff, function(data)
		return data.effectType == transEffectType
	end)

	if not hasTransBuff then
		return cfgId, caster
	end

	local mark = {}
	local _cfgId, _caster = cfgId, caster
	local rate, rateType, exArgs
	local canAdd, transformSuc = false, false

	local function filter(data)
		return data.effectType ~= transEffectType
	end

	while true do
		transformSuc = false

		for _, data in transBuffHolder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.transformAttrBuff, filter) do
			if not mark[data.cfgId] then
				_cfgId, rate, rateType, exArgs = data.refreshCfgId(_cfgId, buffCfg.group, buffCfg.buffFlag)

				if _cfgId ~= cfgId and rate then
					local newValue = args.value

					if rateType == "number" then
						newValue = string.format("(%s)*%s", args.value, rate)
					else
						newValue = string.format("%s", rate)
					end

					if exArgs.otherBuffMode == 1 then
						local buffCfg = csv.buff[_cfgId]
						local effectFunc = buffCfg.easyEffectFunc

						newValue = string.format("(%s)*%s", gBuffEffect[effectFunc].value, rate)
					elseif exArgs.otherBuffMode == 2 then
						if table.length(rate) == 0 then
							newValue = args.value
						else
							newValue = rate
						end
					end

					args.value = newValue
					_caster = data.isSelfCaster and data.buff.caster or _caster
					mark[data.cfgId] = true
					transformSuc = true

					data.buff:addExRecord(battle.ExRecordEvent.transformBuffTriggerCount, 1)
					data.buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
						cfgId = data.cfgId
					})

					break
				end
			end
		end

		if transformSuc then
			canAdd = checkBuffAddConditions(_cfgId, holder, _caster, args)

			if not canAdd then
				return nil, nil
			end
		else
			break
		end

		cfgId = _cfgId
		caster = _caster
		buffCfg = csv.buff[cfgId]
		buffGroupPower = csv.buff_group_power[buffCfg.groupPower]
	end

	return cfgId, caster
end

local function transformBuffModel(cfgId, holder, caster, args)
	local _cfgId, _caster, effectType = cfgId, caster

	effectType = battle.TransformBuffEffectType.caster
	_cfgId, _caster = changeBuffModel(_cfgId, holder, _caster, args, effectType, caster)

	if not _cfgId then
		return _cfgId, _caster
	end

	effectType = battle.TransformBuffEffectType.holder
	_cfgId, _caster = changeBuffModel(_cfgId, holder, _caster, args, effectType, holder)

	return _cfgId, _caster
end

local function reflectBuffModel(cfgId, holder, caster, args)
	if holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.reflectBuffToOther) then
		for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reflectBuffToOther) do
			if data.limit > 0 then
				local res = data.reflectBuff(cfgId, holder, caster, args)

				if res then
					data.limit = data.limit - 1

					return true
				end
			end
		end
	end
end

local function newBuffModel(cfgId, holder, caster, args)
	if args.isAuraType then
		return AuraBuffModel.new(cfgId, holder, caster, args)
	end

	return BuffModel.new(cfgId, holder, caster, args)
end

local buffValueNames = {
	"value",
	"buffValueFormula"
}

local function alterBuffArgs(cfgId, holder, caster, args, isCheckAfter)
	if not args.skillCfg or not args.skillCfg.isCombat then
		return
	end

	local otherForce = 3 - caster.force
	local casterForceTotalCP = holder.scene.forceRecordTb[caster.force].totalFightPoint
	local otherForceTotalCP = holder.scene.forceRecordTb[otherForce].totalFightPoint
	local fightPointRate = 1
	local maxTotalCP

	if casterForceTotalCP and otherForceTotalCP and otherForceTotalCP ~= 0 then
		fightPointRate = casterForceTotalCP / otherForceTotalCP
		maxTotalCP = math.max(casterForceTotalCP, otherForceTotalCP)
	end

	if fightPointRate >= 1 then
		return
	end

	local buffCfg = csv.buff[cfgId]
	local function checkStatus(k, v)
		if fightPointRate >= v.fightPointRate[1] or fightPointRate < v.fightPointRate[2] then
			return false
		end

		if itertools.include(v.excludeBuffID, cfgId) then
			return false
		end

		local cpCorrectGroups = gCPCorrectionGroups[k]

		if not cpCorrectGroups[buffCfg.group] then
			return false
		end

		local combatPowerLimit = v.combatPowerLimit[holder.scene.gateType] or math.huge

		if combatPowerLimit > maxTotalCP then
			return false
		end

		return true
	end

	for k, v in orderCsvPairs(csv.combat_power_correction) do
		if checkStatus(k, v) then
			local buffValueCorrect = v.buffValueRate
			local buffProbCorrect = v.buffProbRate

			args.prob = battleEasy.ifElse(args.prob < 1, buffProbCorrect, 0) + args.prob

			if isCheckAfter then
				for _, name in ipairs(buffValueNames) do
					if args[name] and type(args[name]) ~= "table" then
						args[name] = string.format("(%s)*%s", args[name], buffValueCorrect)
					end
				end
			end

			break
		end
	end
end

local function updateLifeRoundArg(cfgId, holder, args)
	local extraLifeRound = 0
	local buffCfg = csv.buff[cfgId]
	for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeBuffLifeRound) do
		extraLifeRound = extraLifeRound + data.getExtraRound(buffCfg.buffFlag, buffCfg.group, cfgId)
	end

	args.lifeRound = args.lifeRound + extraLifeRound

	return extraLifeRound ~= 0 and args.lifeRound <= 0
end

local function dealReboundBuff(cfgId, holder, caster, args)
	if not caster or not holder then
		return
	end

	if holder.id == caster.id then
		return
	end

	local buffCfg = csv.buff[cfgId]
	for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reboundBuff) do
		if data.groups[buffCfg.group] and not args.reboundBuffId and (data.forceLimit ~= 1 or caster.force ~= holder.force) or args.reboundBuffId == data.id then
			args.reboundBuffId = data.id
			args.prob = 1

			if data.newBuffRound ~= 0 then
				args.lifeRound = data.newBuffRound
			end

			local newHolder = data.getNewHolder(caster)
			local reboundBuff, reboundTakeEffect

			if newHolder then
				if newHolder.id == holder.id then
					errorInWindows("reboundBuff: %s to holder(%s) is same", data.buff.cfgId, dumps(data.newHolder))

					return
				end

				reboundBuff, reboundTakeEffect = addBuffToHero(cfgId, newHolder, caster, args)
			end

			data.buff:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger)

			return true, reboundBuff, reboundTakeEffect
		end
	end
end

local function influenceCanTakeEffect(cfgId, holder, caster, args, canAdd, canTakeEffect)
	local isRebound = dealReboundBuff(cfgId, holder, caster, args)

	if isRebound then
		return true, false
	end

	if canAdd and canTakeEffect then
		if not args.isAuraType then
			cfgId, caster = transformBuffModel(cfgId, holder, caster, args)

			if not cfgId then
				return true, true
			end
		end

		if not args.alreadyReflect then
			local res = reflectBuffModel(cfgId, holder, caster, args)

			if res then
				return true, true
			end
		end
	end

	return false, nil, cfgId, caster
end

local function influenceCanAdd(cfgId, holder, caster, args, canAdd, canTakeEffect)
	return false
end

local function recordExtraInfo(holder, caster, buff)
	if caster and caster.curSkill and caster.curSkill.isSpellTo then
		holder:addExRecord(battle.ExRecordEvent.skillAddBuffIds, buff.id)
	end

	local changeToEnemyData = holder:getFrontOverlaySpecBuff("changeToRandEnemyObj")

	if caster and changeToEnemyData and caster.id == holder.id and changeToEnemyData.changeUnitBuffs then
		changeToEnemyData.changeUnitBuffs[buff.id] = true
	end

	local scene = holder.scene
	local curWave = scene.play.curWave

	scene.extraRecord:addExRecord(battle.ExRecordEvent.campBuffAddByCfgId, 1, curWave, holder.force, buff.cfgId)
	scene.extraRecord:addExRecord(battle.ExRecordEvent.campBuffAddByGroup, 1, curWave, holder.force, buff:group())

	for _, flag in ipairs(buff.csvCfg.buffFlag) do
		scene.extraRecord:addExRecord(battle.ExRecordEvent.campBuffAddByFlag, 1, curWave, holder.force, flag)
	end
end

local function _addBuffToHero(cfgId, holder, caster, args)
	local isBreak, loopKey = BattleAssert.checkBuffLoop(cfgId, holder, caster, args)

	if isBreak then
		BattleAssert.popBuffLoop(loopKey)

		return _, false, AddBuffToHeroReasonIndex.Loop
	end

	if args.miss then
		BattleAssert.popBuffLoop(loopKey)

		return _, false, AddBuffToHeroReasonIndex.Miss
	end

	if args.prob == nil then
		errorInWindows("buff(%d) prob is nil", cfgId)

		args.prob = 0
	end

	if args.prob < 1e-05 then
		BattleAssert.popBuffLoop(loopKey)

		return _, false, AddBuffToHeroReasonIndex.Prob
	end

	alterBuffArgs(cfgId, holder, caster, args)

	if updateLifeRoundArg(cfgId, holder, args) then
		BattleAssert.popBuffLoop(loopKey)

		return _, false, AddBuffToHeroReasonIndex.LifeRound
	end

	tjprofiler.tBegin("checkBuffAddConditions", cfgId)

	local canAdd, canTakeEffect, cantAddReason = checkBuffAddConditions(cfgId, holder, caster, args)

	tjprofiler.tEnd("checkBuffAddConditions", cfgId, 1)
	log.battle.buff.canAddCheck({
		cfgId = cfgId,
		holder = holder,
		caster = caster,
		canAdd = canAdd,
		canTakeEffect = canTakeEffect,
		cantAddReason = cantAddReason
	})

	local influence, takeEffectState, newCfgId, newCaster = influenceCanTakeEffect(cfgId, holder, caster, args, canAdd, canTakeEffect)

	if influence then
		BattleAssert.popBuffLoop(loopKey)

		return _, takeEffectState, AddBuffToHeroReasonIndex.InfluenceCanTakeEffect
	end

	cfgId = newCfgId
	caster = newCaster

	if canTakeEffect then
		alterBuffArgs(cfgId, holder, caster, args, true)
		refreshHolderBuff(cfgId, holder, caster, args)
	end

	if args.isAuraType and holder:hasBuff(cfgId) then
		BattleAssert.popBuffLoop(loopKey)

		return _, canTakeEffect, AddBuffToHeroReasonIndex.AuraBuff
	end

	influence = influenceCanAdd(cfgId, holder, caster, args, canAdd, canTakeEffect)

	if influence then
		BattleAssert.popBuffLoop(loopKey)

		return _, canTakeEffect, AddBuffToHeroReasonIndex.InfluenceCanAdd
	end

	if canAdd then
		local buff = newBuffModel(cfgId, holder, caster, args)

		holder.scene.allBuffs:insert(buff.id, buff)

		if buff.isFieldBuff then
			holder.scene.fieldBuffs:insert(buff.id, buff)
		end

		holder.buffs:insert(buff.id, buff)
		recordExtraInfo(holder, caster, buff)
		buff:init()
		holder:onBuffEffectedHolder(buff)
		holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffBeAdd, buff)

		local buffLinkInfo = checkBuffLinkCond(holder, cfgId, buff:group())
		local valOrigin = args.value

		for _, v in ipairs(buffLinkInfo) do
			local value = valOrigin * v.val.fixValue
			local obj = holder.scene:getObjectExcludeDead(v.key)

			if obj then
				args.value = value

				_addBuffToHero(cfgId, obj, caster, args)
			end
		end

		BattleAssert.popBuffLoop(loopKey)

		return buff, canTakeEffect, AddBuffToHeroReasonIndex.Success
	elseif cantAddReason then
		local buffCfg = csv.buff[cfgId]
		holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffCantAdd, {
			reason = cantAddReason,
			holder = holder,
			caster = caster,
			buffCfgId = cfgId,
			group = buffCfg.group,
			buffFlag = buffCfg.buffFlag
		})
	end

	BattleAssert.popBuffLoop(loopKey)

	return _, canTakeEffect, AddBuffToHeroReasonIndex.AddFail
end

local function dealDelayBuff(cfgId, holder, caster, args)
	local buffCfg = csv.buff[cfgId]
	local needDelay = false

	for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayBuff) do
		local flag = false

		for _, buffFlag in ipairs(buffCfg.buffFlag) do
			if data.buffFlagTb[buffFlag] then
				flag = true

				break
			end
		end

		if data.buffIdTb[cfgId] or data.buffGroupTb[buffCfg.group] or flag then
			if not args.delay then
				args.delay = true

				local temp = {
					cfgId = cfgId,
					holder = holder,
					caster = caster,
					args = args
				}

				table.insert(data.needDelayBuffTb, temp)

				needDelay = true
			end

			break
		end
	end

	return needDelay
end

function globals.addBuffToHero(cfgId, holder, caster, args)
	blackBoard = nil

	local isBreak, rholder
	local sceneBuffRecord = holder.scene.recordBuffManager:getRecord("replaceBuffHolder")

	for _, buffData in sceneBuffRecord:order_pairs() do
		isBreak, rholder = buffData.f(buffData, cfgId, holder, caster, args)

		if isBreak then
			holder = rholder

			break
		end
	end

	local continue = true
	local buff, canTakeEffect, reasonIndex

	if holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayBuff) and dealDelayBuff(cfgId, holder, caster, args) then
		reasonIndex = AddBuffToHeroReasonIndex.DelayBuff
		continue = false
	end

	if continue then
		buff, canTakeEffect, reasonIndex = _addBuffToHero(cfgId, holder, caster, args)
	end

	log.battle.buff.addBuffToHero({
		cfgId = cfgId,
		holder = holder,
		caster = caster,
		reason = AddBuffToHeroReason[reasonIndex]
	})

	blackBoard = nil

	return buff, canTakeEffect
end

function globals.addAuraBuffToHero(cfgId, holder, caster, args)
	args.isAuraType = true

	local buff = addBuffToHero(cfgId, holder, caster, args)

	if buff and caster and not caster:isDeath() then
		caster.auraBuffs:insert(buff.id, buff)
	end

	return buff
end

function globals.addBuffToScene(cfgId, holder, caster, args)
	local prob = args.prob

	if prob < 1 then
		local randret = ymrand.random()

		if prob < randret then
			return
		end
	end

	local buff = newBuffModel(cfgId, holder, caster, args)

	if not holder.scene.buffGlobalManager:checkBuffCanAdd(buff, holder) then
		return
	end

	buff.isInited = true
	buff.buffValue = clone(buff:cfg2Value(buff.args.value))
	buff.showDispelEffect = false

	holder.scene.buffGlobalManager:refreshBuffLimit(holder.scene, buff)
	holder.scene:initGroupObj(buff)
end
