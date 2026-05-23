-- chunkname: @src.battle.models.buff.buff_effect5

local helper = require("battle.models.buff.helper")
local opMap = {
	function(oldValue, value)
		return value
	end,
	function(oldValue, value)
		return oldValue + value
	end
}
local recordOpMap = {
	function(target)
		return target:getTakeDamageRecord(battle.ValueType.normal)
	end,
	function(target)
		return target:getDamageRecord(battle.ValueType.valid)
	end
}
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

local function getTransformCfgId(args, cfgId, group, flags)
	local function safeGet(cfgId)
		if csv.buff[cfgId] then
			return csv.buff[cfgId].easyEffectFunc
		end
		errorInWindows("getTransformCfgId getEasyEffectFunc %d is not in csv", cfgId)

		return "buff1"
	end

	for _, data in ipairs(args) do
		local idx = itertools.first(data[1][1], group)

		if idx == nil and battleEasy.intersection(data[1][2], flags) then
			idx = 1
		end

		if idx then
			local rateIdx, toBuffCfgId
			local out = data[2]
			local otherArgs = data[3]

			if otherArgs[1] == 1 then
				toBuffCfgId = out[idx] or cfgId
				rateIdx = idx
			elseif otherArgs[1] == 2 and table.length(out) > 0 then
				rateIdx = ymrand.random(1, table.length(out))
				toBuffCfgId = out[rateIdx]
			end

			local rate
			local rateType = type(otherArgs[2])

			if rateType == "number" then
				rate = otherArgs[2] or 1

				local effectFunc1, effectFunc2 = safeGet(cfgId), safeGet(toBuffCfgId)

				rate = string.format("((%s/%s)*%s)", getAttrTransformRate(effectFunc2), getAttrTransformRate(effectFunc1), rate)
			else
				rate = otherArgs[2][rateIdx] or 1
			end

			local mode = data[6] or 0

			if mode == 2 then
				rate = otherArgs[2]
			end

			local exArg = {
				limit = data[4],
				targetType = data[5],
				otherBuffMode = mode
			}

			return toBuffCfgId, rate, rateType, exArg
		end
	end

	return cfgId
end

function BuffEffectFuncTb.forbiddenSpecBuff(buff, args, isOver)
	local funcList = buff.csvCfg.specialVal or {}
	local holder = buff.holder
	local filter

	funcList = type(funcList[1]) == "table" and funcList[1].easyEffectFunc or {}
	buff.__temp = buff.__temp or {}

	for i, key in ipairs(funcList) do
		filter = nil

		if not isOver then
			if args and type(args) == "table" and table.length(args[1]) > 0 then
				function filter(data)
					if itertools.include(args[1], data.cfgId) then
						return true
					end

					if itertools.include(args[2], data.group) then
						return true
					end
				end
			end

			buff.__temp[key] = holder:addOverlaySpecBuffFilter(key, filter)
		else
			holder:deleteOverlaySpecBuffFilter(key, buff.__temp[key])
		end
	end
end

function BuffEffectFuncTb.banExtraAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local banModeTb = {}
		local banModeType = {}

		if buff.csvCfg.specialVal then
			for k, v in ipairs(buff.csvCfg.specialVal) do
				banModeTb[v] = k
			end
		end

		if args then
			for k, v in ipairs(args) do
				banModeType[k] = {}
				banModeType[k].canResponseSelf = v[1] == 1
				banModeType[k].canTriggerOthers = v[2] == 1
				banModeType[k].canResponseOthers = v[3] == 1
			end
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.banModeTb = banModeTb
			old.banModeType = banModeType
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.transformAttrBuff(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local refreshCfgId = functools.partial(getTransformCfgId, args)
		local isSelfCaster = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] == 1
		local effectType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]

		effectType = effectType or battle.TransformBuffEffectType.holder

		holder:addOverlaySpecBuff(buff, function(old)
			old.refreshCfgId = refreshCfgId
			old.isSelfCaster = isSelfCaster
			old.effectType = effectType
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.delayDamage(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.delayPer = args[1]
			old.time = args[2]
			old.damageTb = {}
			old.isNotShowDelayHp = args[3] and args[3] == 0
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.delayDamage, "getRoundDamage", function(buffIds)
			local totalDamage = 0

			if holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
				for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
					if not buffIds or itertools.include(buffIds, data.cfgId) then
						for i = table.length(data.damageTb), 1, -1 do
							totalDamage = totalDamage + data.damageTb[i][1]

							table.remove(data.damageTb[i], 1)

							if table.length(data.damageTb[i]) <= 0 then
								table.remove(data.damageTb, i)
							end
						end
					end
				end
			end

			return totalDamage
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.reduceDelayDamage(buff, args, isOver)
	local holder = buff.holder
	local reduceBuffIds = buff.csvCfg.specialVal

	if not isOver and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.delayDamage) then
		local toReduceDamage = args
		local allClear = false
		local index = 1

		while toReduceDamage > 0 and not allClear do
			allClear = true

			for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayDamage) do
				if not reduceBuffIds or itertools.include(reduceBuffIds, data.cfgId) then
					for _, oneRecord in ipairs(data.damageTb) do
						if oneRecord[index] then
							allClear = false

							if toReduceDamage > oneRecord[index] then
								toReduceDamage = toReduceDamage - oneRecord[index]
								oneRecord[index] = 0
							else
								oneRecord[index] = oneRecord[index] - toReduceDamage
								toReduceDamage = 0
							end
						end
					end
				end
			end

			index = index + 1
		end

		holder:refreshLifeBar()
	end
end

function BuffEffectFuncTb.extraSkillWeightValueFix(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.fixType = args[1]
			old.fixValue = args[2]
			old.fixCostType = args[3]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.damgeMustHit(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			return
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.alterDmgRecordVal(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.assignObject = args[1]
			old.priority = args[2]
			old.typ = args[3] or 1
			old.alterDmgRecordData = buff.csvCfg.specialVal[1]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

local function shiftCheckSeat(seat, bb)
	if seat == bb.holder.seat then
		return false
	end

	local obj = bb.objMap[seat]
	local buff = bb.buff

	if bb.specialCheck and obj then
		buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
			shiftObj = obj
		})

		local cantShift = buff:cfg2Value(bb.specialCheck)

		buff.protectedEnv:resetEnv()

		local needIgnore = obj:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.ignoreSpecBuff, "ignoreCheck", "shiftPos", bb.holder.id)

		if needIgnore then
			cantShift = true
		end

		if cantShift then
			return false
		end
	end

	if bb.seatMode == 1 then
		return bb.holder.scene:isSeatEmpty(seat)
	elseif bb.seatMode == 2 then
		return obj ~= nil
	elseif bb.seatMode == 3 then
		return true
	end
end

local function shiftGetRow(filter, bb)
	local ret = {}
	local forceNumber = bb.forceNumber
	local rowNumber = forceNumber / 2
	local s, e = 1, forceNumber
	local force = bb.holder.force

	if bb.needEmemy then
		force = 3 - force
	end

	if force ~= 1 then
		s, e = s + forceNumber, e + forceNumber
	end

	if bb.rowMode == 1 then
		s = s + rowNumber
	elseif bb.rowMode == 2 then
		e = e - rowNumber
	end

	for i = s, e do
		if not filter or filter(i) then
			table.insert(ret, i)
		end
	end

	return ret
end

local shiftSearchFuncs

shiftSearchFuncs = {
	function(bb)
		local seat = bb.holder.seat

		if bb.frontOrBack == 1 then
			seat = seat + 3
		else
			seat = seat - 3
		end

		if shiftCheckSeat(seat, bb) then
			return {
				seat
			}
		else
			return {}
		end
	end,
	function(bb)
		return shiftGetRow(function(seat)
			return shiftCheckSeat(seat, bb)
		end, bb)
	end,
	function(bb)
		local ret = shiftSearchFuncs[1](bb)

		if ret[1] and bb.objMap[ret[1]] then
			return ret
		else
			return {}
		end
	end,
	function(bb)
		return shiftGetRow(function(seat)
			return shiftCheckSeat(seat, bb) and bb.objMap[seat]
		end, bb)
	end
}

function BuffEffectFuncTb.backStage(buff, args, isOver)
	if isOver then
		return
	end

	local function delFromAttackArr(array, objId)
		for i = table.length(array), 1, -1 do
			local obj = array[i].obj or array[i]

			if obj.id == objId then
				table.remove(array, i)
			end
		end
	end

	local holder = buff.holder

	if buff.updateWithTrigger then
		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			obj = holder
		})
	end

	local isBackFollowObj = args[1] ~= 0

	buff.scene:eraseObj(holder)
	buff.scene:addBackStageObj(holder)
	holder:onPositionStateChange(false, true)

	local isStore = false

	if type(args) == "table" then
		isStore = args[2] == 1
	end

	buff.scene.play:delFromRoundLeftHeros(holder.id, isStore)
	delFromAttackArr(buff.scene.play.roundHasAttackedHeros, holder.id)
	buff.scene.play:cleanExRoundFromAttackList(holder)
	holder:onLeaveSeat()
	battleEasy.deferNotifyCantJump(holder.view, "stageChange", false)

	if isBackFollowObj then
		for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
			if data.caster:isBindOwnerWithStage() then
				data.caster:backStage()
			end
		end
	end
end

function BuffEffectFuncTb.frontStage(buff, args, isOver)
	if isOver then
		return
	end

	local holder = buff.holder
	local needEmemy = args[1] == 99
	local seat, unitId = needEmemy and 0 or args[1], args[2]
	local transferMp = (args[3] or 0) * holder:mp1()
	local isSaveAttackOrder = args[4] == 1
	local isNeedRandom = args[5] == 1
	local specialVal = buff.csvCfg.specialVal
	local frontPriority = specialVal and specialVal[1] or battle.FrontStagePriority.defaultPriority
	local condition = specialVal and specialVal[2]
	local isFailDelete = specialVal and specialVal[3] or 0
	local seatType = specialVal and specialVal[4] or battle.FrontStageSeatType.real

	if not unitId then
		return
	end

	if not seat then
		return
	end

	local play = buff.scene.play
	local roundMark = play.curWave * 1000 + play.totalRoundBattleTurn
	local targetObj

	local function checkCanSelect(obj, mode)
		if mode == 1 and obj.summonGroup == holder.summonGroup and unitId == obj.originUnitID then
			return true
		end

		if mode == 2 and obj.id == holder.id and unitId == obj.originUnitID then
			return true
		end

		return false
	end

	for _, obj in buff.scene.backHeros:order_pairs() do
		if checkCanSelect(obj, args[6] or 1) then
			local tmpData = obj:getEventByKey(battle.ExRecordEvent.frontStage)

			if not tmpData or roundMark > tmpData.roundMark then
				targetObj = obj

				break
			end
		end
	end

	if not targetObj then
		return
	end

	local function makeVirtualEnv()
		local p = {
			scene = battleCsv.CsvScene.newWithCache(buff.scene),
			self = battleCsv.CsvObject.newWithCache(buff.caster)
		}

		p.env = p

		return p
	end

	local env = makeVirtualEnv()

	local function checkCanComeIn()
		local result = true

		if condition then
			result = battleCsv.doFormula(condition, env)
		end

		return result
	end

	local function findSeat()
		if checkCanComeIn() == false then
			return nil
		end

		local scene = buff.scene

		if seat ~= 0 then
			if scene:isSeatEmptyWithFollowType(seatType, seat, targetObj) then
				return seat
			end

			if isNeedRandom == false then
				return nil
			end
		end

		local rtSeat
		local bb = {}

		bb.rowMode = 3
		bb.forceNumber = play.ForceNumber
		bb.holder = holder
		bb.needEmemy = needEmemy

		local ret = shiftGetRow(function(_seat)
			return scene:isSeatEmptyWithFollowType(seatType, _seat, targetObj)
		end, bb)
		local len = table.length(ret)

		if len > 0 then
			local idx = ymrand.random(1, len)

			rtSeat = ret[idx]
		end

		return rtSeat
	end

	local data = {
		transferMp = transferMp,
		cfgId = buff.cfgId,
		roundMark = roundMark,
		frontPriority = frontPriority,
		frontStageTargetFormula = findSeat,
		isFailDelete = isFailDelete == 1,
		seatType = seatType
	}

	if isSaveAttackOrder then
		data.stageRound = play.curRound
		data.stageAttacked = not itertools.include(play.roundLeftHeros, function(data)
			return data.obj.id == buff.holder.id
		end)
	end

	targetObj:addExRecord(battle.ExRecordEvent.frontStage, data)
end

function BuffEffectFuncTb.shiftPos(buff, args, isOver)
	if isOver then
		return
	end

	if buff.scene:isBackHeros(buff.holder) then
		buff:overClean()

		return
	end

	local specTb = buff.csvCfg.specialVal or {}
	local isOneceBuff, effectCfgId, specialCheck = specTb[1], specTb[2], specTb[3]
	local effectCfg = csv.buff[effectCfgId]
	local seatMode, rowMode, searchRule, targetSeat = args[1], args[2], args[3], args[4]
	local holder = buff.holder
	local frontOrBack = holder:frontOrBack()

	local function checkClean()
		if isOneceBuff and isOneceBuff == 1 then
			buff:overClean()
		end
	end

	local oldSeat = holder.seat

	local function doTriggerEvent()
		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			buffId = buff.id,
			seat = oldSeat
		})
	end

	if holder.seat < 0 or frontOrBack + rowMode == 3 then
		return
	end

	local objMap = {}
	local heros = buff.holder.scene:getHerosMap(buff.holder.force)

	for id, obj in heros:order_pairs() do
		if obj and not obj:isRealDeath() then
			objMap[obj.seat] = obj
		end
	end

	local bb = {}

	bb.objMap = objMap
	bb.seatMode = seatMode
	bb.rowMode = rowMode
	bb.forceNumber = holder.scene.play.ForceNumber
	bb.holder = holder
	bb.frontOrBack = frontOrBack
	bb.specialCheck = specialCheck
	bb.buff = buff

	if targetSeat then
		if shiftCheckSeat(targetSeat, bb) then
			buff.holder.shiftPos = targetSeat

			buff.holder:doShiftPos(effectCfg, buff)
			doTriggerEvent()
			buff:over()
		else
			checkClean()
		end

		return
	end

	for _, id in ipairs(searchRule) do
		local seatList = shiftSearchFuncs[id](bb)

		if table.length(seatList) > 0 then
			local idx = ymrand.random(1, table.length(seatList))

			buff.holder.shiftPos = seatList[idx]

			buff.holder:doShiftPos(effectCfg, buff)
			doTriggerEvent()
			buff:over()

			return
		end
	end

	checkClean()
end

function BuffEffectFuncTb.escape(buff, args, isOver)
	if isOver then
		return
	end

	local holder = buff.holder

	battleEasy.deferNotifyCantJump(holder.view, "escape", {
		delayMove = args and args[1],
		costTime = args and args[2]
	})
	holder:setDead(holder, nil, {
		force = true
	})
end

function BuffEffectFuncTb.atOnceTransformAttrBuff(buff, args, isOver)
	if not isOver then
		local mainHolder = buff.holder
		local toBeTransformTb = {}
		local buffRoundCfg = buff.csvCfg.specialVal[1]
		local newBuffCfg = buff.csvCfg.specialVal[2] or {}
		local isSelfCaster = buff.csvCfg.specialVal[3] == 1
		local limit = 0
		local newValue

		for _, curBuff in mainHolder.buffs:order_pairs() do
			local _cfgId, rate, rateType, exArgs = getTransformCfgId(args, curBuff.cfgId, curBuff:group(), curBuff:buffFlag())

			if not curBuff.isOver and curBuff.csvPower.beChange == 1 and _cfgId ~= curBuff.cfgId and rate and exArgs and exArgs.limit and exArgs.targetType then
				if rateType == "number" then
					newValue = string.format("(%s)*%s", curBuff.args.buffValueFormula, rate)
				else
					newValue = string.format("%s", rate)
				end

				if exArgs.otherBuffMode == 1 then
					local effectFunc = csv.buff[_cfgId].easyEffectFunc
					newValue = string.format("(%s)*%s", gBuffEffect[effectFunc].value, rate)
				elseif exArgs.otherBuffMode == 2 then
					if table.length(rate) == 0 then
						newValue = curBuff:getEffectValue()
					else
						newValue = rate
					end
				end

				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					oldBuff = curBuff
				})

				local buffRound = buff:cfg2Value(buffRoundCfg)

				buff.protectedEnv:resetEnv()

				local newArgs = BuffArgs.fromAtOnceTransform1(curBuff, _cfgId, newValue, exArgs.targetType, buffRound, newBuffCfg)

				table.insert(toBeTransformTb, newArgs)

				limit = exArgs.limit
			end
		end

		toBeTransformTb = random.sample(toBeTransformTb, limit, ymrand.random)

		for _, data in ipairs(toBeTransformTb) do
			data.oldBuff:overClean()
		end

		local isSuccess = false

		for _, data in ipairs(toBeTransformTb) do
			local holders = buff:findTargetsByCfg(data.targetType)

			for _, holder in ipairs(holders) do
				local newArgs = BuffArgs.fromAtOnceTransform2(data)
				local caster = isSelfCaster and buff.caster or data.oldHolder
				local curBuff, takeEffect = addBuffToHero(data.cfgId, holder, caster, newArgs)

				isSuccess = isSuccess or takeEffect
			end
		end

		if isSuccess then
			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				obj = buff.holder
			})
		end
	end
end

function BuffEffectFuncTb.transformBuff(buff, args, isOver)
	if not isOver then
		local groups = args[1][1]
		local flags = args[1][2]
		local num = args[2]
		local prob = args[3] or 1
		local transType = args[4] or 1
		local buffList = {}
		local cfgId2Idx = {}

		for _, curBuff in buff.holder.buffs:order_pairs() do
			local idx = itertools.first(groups, curBuff:group())

			if idx == nil and battleEasy.intersection(flags, curBuff:buffFlag()) then
				idx = 1
			end

			if idx and curBuff.csvPower.beChange == 1 and (prob == 1 or prob > ymrand.random()) then
				if transType == 2 and not curBuff:isCoexistType() then
					for i = 1, curBuff:getOverLayCount() do
						table.insert(buffList, curBuff)
					end
				else
					table.insert(buffList, curBuff)
				end

				cfgId2Idx[curBuff.cfgId] = idx
			end
		end

		buffList = random.sample(buffList, num, ymrand.random)

		for _, oldBuff in ipairs(buffList) do
			local oldArgs = BuffArgs.fromTransform(oldBuff)

			oldBuff:beDispel(false, battle.BuffOverType.clean, buff)
			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				buffId = buff.id,
				easyEffectFunc = buff.csvCfg.easyEffectFunc,
				obj = buff.holder,
				idx = cfgId2Idx[oldArgs.cfgId],
				oldArgs = oldArgs
			})
		end
	end
end

function BuffEffectFuncTb.specialRecord(buff, args, isOver)
	if isOver then
		return
	end

	local specialVal = buff.csvCfg.specialVal

	if not buff.specialRecordFunc then
		buff.specialRecordFunc = functools.partial(function(targets, dataType, calcType)
			local curTotalValue, retValue = 0, 0

			for _, target in ipairs(targets) do
				local curVal = recordOpMap[dataType] and recordOpMap[dataType](target)

				if type(curVal) == "number" then
					curTotalValue = curTotalValue + curVal
				end
			end

			retValue = curTotalValue

			if calcType == 1 then
				buff.specialRecordDiffVal = buff.specialRecordDiffVal or curTotalValue
				retValue = curTotalValue - buff.specialRecordDiffVal
			elseif calcType == 2 then
				retValue = curTotalValue - (buff.specialRecordDiffVal or 0)
				buff.specialRecordDiffVal = curTotalValue
			end

			return retValue
		end, buff:findTargetsByCfg(specialVal[2]))
	end

	buff:setValue(buff.specialRecordFunc(specialVal[1], specialVal[3]))
end

function BuffEffectFuncTb.directWin(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args or 1
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.mp1Point(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local mp1PointData = holder:getFrontOverlaySpecBuff("mp1OverFlow")

		if mp1PointData then
			local val = cc.clampf(mp1PointData.mp1Point + args, 0, mp1PointData.limit)

			mp1PointData.mp1Point = val
		end
	end
end

function BuffEffectFuncTb.opGameData(buff, args, isOver)
	local holder = buff.holder
	local indexToStrMap = {
		"hintChoose",
		"skillLevel0",
		"skillLevel1",
		"skillLevel2",
		"skillLevel3"
	}

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.key = indexToStrMap[args[1]]
			old.op = opMap[args[2]]
			old.value = args[3]
			old.checkFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or true
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.changeScaleAttrs(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local specialVal = buff.csvCfg.specialVal
		local normalAttrRate = specialVal and buff:cfg2Value(specialVal[1]) or 1
		local otherAttrRate = specialVal and buff:cfg2Value(specialVal[2]) or 1
		local specialAttrTb = specialVal and specialVal[3] or {}
		local attrsRecordTb = {}

		for attr, _ in pairs(ObjectAttrs.AttrsTable) do
			local changeAttrValue = holder:getBaseAttr(attr)

			if specialAttrTb[attr] then
				changeAttrValue = changeAttrValue * (1 - specialAttrTb[attr])
			elseif ObjectAttrs.SixDimensionAttrs[attr] then
				changeAttrValue = changeAttrValue * (1 - normalAttrRate)
			else
				changeAttrValue = changeAttrValue * (1 - otherAttrRate)
			end

			if changeAttrValue ~= 0 then
				holder:objAddBuffAttr(attr, -changeAttrValue)

				attrsRecordTb[attr] = changeAttrValue
			end
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.attrsRecordTb = attrsRecordTb
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			for attr, value in pairs(old.attrsRecordTb) do
				holder:objAddBuffAttr(attr, value)

				if attr == "hpMax" and value > 0 then
					local hpValue = holder:hpMax() - holder:hp()

					holder:addHp(hpValue, battle.AddHpFrom.changeScaleAttrs)
				end
			end
		end)
	end
end

function BuffEffectFuncTb.finalAttrLimit(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if not old.finalAttr then
				old:setG("finalAttr", {})
			end

			if not old.needSort then
				old:setG("needSort", {})
			end

			old:setG("getAttr", function(buffData, attr, value)
				local data = buffData.finalAttr[attr]

				if not data or data:empty() then
					return value
				end

				if old.needSort[attr] then
					old.needSort[attr] = false

					data:sort(function(a, b)
						return a.priority > b.priority
					end)
				end

				for i, buffV in data:ipairs() do
					value = value + (buffV.buff:cfg2Value(buffV.valAdd) or 0)
				end

				local front = data:front()

				if front.upperLimit and value > front.upperLimit then
					value = front.upperLimit
				end

				if front.lowerLimit and value < front.lowerLimit then
					value = front.lowerLimit
				end

				return value
			end)

			old.priority = args[1] or 10
			old.upperLimit = args[2]
			old.lowerLimit = args[3]

			local attrAdd = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

			for attr, _ in pairs(ObjectAttrs.AttrsTable) do
				if old.upperLimit[attr] or old.lowerLimit[attr] or attrAdd[attr] then
					old.finalAttr[attr] = old.finalAttr[attr] or CVector.new()
					old.needSort[attr] = true

					old.finalAttr[attr]:push_back({
						upperLimit = old.upperLimit[attr],
						lowerLimit = old.lowerLimit[attr],
						valAdd = attrAdd[attr],
						priority = old.priority,
						buff = buff
					})
				end
			end
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			for attr, _ in pairs(ObjectAttrs.AttrsTable) do
				if old.finalAttr[attr] then
					for index, value in old.finalAttr[attr]:ipairs() do
						if value.buff.id == buff.id then
							old.finalAttr[attr]:erase(index)

							old.needSort[attr] = true

							break
						end
					end
				end
			end
		end)
	end
end

function BuffEffectFuncTb.healTodamage(buff, args, isOver)
	local holder = buff.holder
	local spValue1 = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.formula = args[1]
			old.processId = args[2] or 401

			function old.calcDamage(healthNum)
				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					healthNum = healthNum
				})

				local damageNum = buff:cfg2Value(old.formula)

				buff.protectedEnv:resetEnv()

				return damageNum
			end
		end, nil)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", function(healthNum)
			local ret, ids = {}, {}

			for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.healTodamage) do
				local processId = data.processId

				if not ret[processId] then
					ret[processId] = 0

					table.insert(ids, processId)
				end

				ret[processId] = ret[processId] + data.calcDamage(healthNum)
			end

			local data = {}

			for _, id in ipairs(ids) do
				table.insert(data, {
					processId = id,
					damage = ret[id]
				})
			end

			return data
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", function(attacker, target, damage, buffArgs)
			local toDamageData = target:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "getDamage", damage)

			for k, data in ipairs(toDamageData) do
				local damage = math.floor(data.damage)
				local buffDamageArgs = {
					isLastDamageSeg = true,
					isBeginDamageSeg = true,
					from = battle.DamageFrom.buff,
					buffCfgId = buffArgs.cfgId,
					buffFlag = buffArgs.flag,
					buffGroupId = buffArgs.groupId,
					beAttackZOrder = buff.scene.beAttackZOrder,
					isProcessState = {
						isStart = k == 1,
						isEnd = k == table.length(toDamageData)
					}
				}

				buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = buff.id,
					easyEffectFunc = buff.csvCfg.easyEffectFunc
				})

				local damage, damageArgs = target:beAttack(attacker, damage, data.processId, buffDamageArgs)
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.replaceSkill(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local initArgs = args[3] or {
			0
		}

		holder:replaceSkill(args[1], args[2], buff.id, {
			replaceView = initArgs[1] == 1
		})
	else
		holder:resumeSkill(buff.id)
	end
end

function BuffEffectFuncTb.breakCharging(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args[1]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.changeObjNature(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if not old.typeList then
				old:setG("typeList", CVector.new())
			end

			old:setG("getType", function(buffData, idx)
				idx = idx or 1

				local data = buffData.typeList and buffData.typeList:front()

				return data and data[idx]
			end)
			old.typeList:push_front(args)
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.typeList:pop_front(args)
		end)
	end
end

function BuffEffectFuncTb.changeSkillNature(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if not old.skillNatures then
				old:setG("skillNatures", {})
			end

			old.mode = args[1]
			old.args = args[2] or {}

			function old.refreshSkills(skillsOrder)
				old.skillNatures = {}

				if old.mode == 0 then
					local hasEx = table.length(skillsOrder) > 3

					for i, skillID in ipairs(skillsOrder) do
						local idxInArgs = i

						if hasEx and i == 3 then
							idxInArgs = 4
						end

						if hasEx and i == 4 then
							idxInArgs = 3
						end

						local newType = old.args[idxInArgs]

						if newType and newType > 0 then
							old.skillNatures[skillID] = newType
						end
					end
				elseif old.mode == 1 then
					for i, skillID in ipairs(skillsOrder) do
						local cfg = csv.skill[skillID]
						local oldType = cfg and cfg.skillNatureType
						local name = game.NATURE_TABLE[oldType]
						local newType = old.args[name]

						if newType and newType > 0 then
							old.skillNatures[skillID] = newType
						end
					end
				end
			end

			old:setG("refreshAll", function()
				for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeSkillNature) do
					data.refreshSkills(holder.skillsOrder)

					break
				end
			end)
		end)

		local buffData = holder:getOverlaySpecBuffData(battle.OverlaySpecBuff.changeSkillNature)

		buffData.refreshAll()
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.skillNatures = {}
		end)
	end
end

function BuffEffectFuncTb.possess(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local target = targetCfg and buff:findTargetsByCfg(targetCfg)[1]
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

		if not target then
			return
		end

		local possessArgs = {
			casterKey = tostring(holder),
			targetKey = tostring(target),
			targetSeat = target.seat,
			offsetPos = cc.p(specialArgs.x, specialArgs.y),
			res = specialArgs.res,
			type = battle.SpriteType.Possess
		}

		holder:addExRecord(battle.ExRecordEvent.possessTarget, target)
		gRootViewProxy:proxy():collectCallBack("battleTurn", functools.partial(function(holder_, args_)
			if gRootViewProxy:call("isObjExisted", args_.targetKey) then
				gRootViewProxy:call("onSceneAddObj", "possess" .. tostring(holder_), readOnlyProxy(holder_), args_)
			end
		end, holder, possessArgs))
	else
		holder:cleanEventByKey(battle.ExRecordEvent.possessTarget)
		gRootViewProxy:proxy():collectNotify("battleTurn", nil, "SceneDelObj", "possess" .. tostring(holder))
	end
end

function BuffEffectFuncTb.prophet(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			function old.getProb(_self, attacker)
				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					attacker = attacker
				})

				local prob = buff:cfg2Value(buff.args.buffValueFormula[1])

				buff.protectedEnv:resetEnv()

				return prob
			end

			function old.targetFilter(_self, attacker, target)
				if _self.specialTargetFind == nil then
					return true
				end

				local targets = _self.specialTargetFind() or {}

				for _, tar in ipairs(targets) do
					if tar.id == target.id then
						return true
					end
				end

				return false
			end

			old.triggerId = args[2]
			old.triggerSkillType2 = args[3]
			old.isWeightingType = type(args[3]) == "table"
			old.costType = args[4] or 0
			old.mustEnemy = args[5] == 1
			old.cantReselect = args[6] == 1
			old.cfgId = args[7]
			old.time = args[8] or 1
			old.priority = args[9] or 10
			old.isFixedForce = args[10] or false
			old.roundTriggerLimit = args[11]
			old.buffFlag = buff.csvCfg.buffFlag
			old.specialTargetFind = nil

			if buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1] ~= nil then
				old.specialTargetFind = functools.partial(buff.findTargetsByCfg, buff, buff.csvCfg.specialTarget[1])
			end
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.changeSkillDamageTarget(buff, args, isOver)
	if not isOver then
		local formula, chooseType = ""

		if buff.csvCfg.specialVal then
			chooseType = buff.csvCfg.specialVal[1] or ""

			if type(buff.csvCfg.specialVal[2]) == "string" then
				local str = buff.csvCfg.specialVal[2]

				formula = str:sub(1, -2) .. ",toChangeTargets)"
			end
		end

		buff.holder:addOverlaySpecBuff(buff, function(old)
			old.chooseType = chooseType
			old.targetFormula = formula
			old.priority = args or 0
		end, function(a, b)
			if a.priority == b.priority then
				return a.buff.id < b.buff.id
			else
				return a.priority > b.priority
			end
		end)
	else
		buff.holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.reduceSkillDamageTarget(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.reduceNum = args[1]
			old.force = args[2]
			old.priority = args[3] or 0
			old.effectRes = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
			old.effectAnimation = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
			old.reduceTargets = {}
			old.reduceRandom = {}
			old.targets = {}

			for i = 1, old.reduceNum do
				table.insert(old.reduceRandom, ymrand.random(1, 12))
			end
		end, function(a, b)
			if a.priority == b.priority then
				return a.buff.id < b.buff.id
			else
				return a.priority > b.priority
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.reduceSkillDamageTarget, "reduceTargets", function(targets, skillId)
			for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reduceSkillDamageTarget) do
				if not data.reduceTargets[skillId] then
					data.reduceTargets[skillId] = {}

					local tempTargets, reduceForce

					if data.force == 0 then
						reduceForce = 0
						tempTargets = targets
					else
						reduceForce = battleEasy.ifElse(data.force == 1, holder.force, 3 - holder.force)
						tempTargets = arraytools.filter(targets, function(_, obj)
							return obj.force == reduceForce
						end)
					end

					if table.length(tempTargets) == 0 then
						return targets
					end

					for i, num in pairs(data.reduceRandom) do
						if table.length(tempTargets) == 1 then
							return targets
						end

						local temp = num % table.length(tempTargets)

						temp = battleEasy.ifElse(temp == 0, table.length(tempTargets), temp)

						table.insert(data.reduceTargets[skillId], tempTargets[temp])

						targets = arraytools.filter(targets, function(_, obj)
							return obj.force ~= tempTargets[temp].id
						end)

						table.remove(tempTargets, temp)
					end
				else
					for i, objR in pairs(data.reduceTargets[skillId]) do
						for j, objT in pairs(targets) do
							if objT.id == objR.id then
								table.remove(targets, j)

								break
							end
						end
					end
				end

				data.targets[skillId] = targets
			end

			return targets
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.reduceSkillDamageTarget, "getTargetsForce", function(skillId)
			local targets = {}
			local force = {
				0,
				0
			}
			local flag

			for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reduceSkillDamageTarget) do
				force[data.force] = 1

				if data.targets[skillId] then
					targets = data.targets[skillId]
				end
			end

			if force[1] == 1 and force[2] == 1 or force[0] == 1 then
				flag = 0
			elseif force[1] == 1 then
				flag = holder.force
			elseif force[2] == 1 then
				flag = 3 - holder.force
			end

			force = {
				0,
				0
			}

			for _, obj in pairs(targets) do
				force[obj.force] = 1
			end

			if force[1] == 1 and force[2] == 1 and flag == 0 then
				return 0
			elseif force[1] == 1 and flag ~= 2 then
				return 1
			elseif force[2] == 1 and flag ~= 1 then
				return 2
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.reduceSkillDamageTarget, "getTargets", function(targetsForce, skillId)
			local targets = {}

			for k, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.reduceSkillDamageTarget) do
				if (data.force == 0 or data.force == 1 and targetsForce[holder.force] == 1 or data.force == 2 and targetsForce[3 - holder.force] == 1) and data.targets[skillId] then
					targets = data.targets[skillId]
				end
			end

			return targets
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

local function getRoundMark(play)
	return string.format("%sw%sr", play.curWave, play.totalRoundBattleTurn)
end

local function tryProtect(beReplaceTarget, attacker, play, buffData, ptype, ignoreData)
	local function ignoreReplaceFilter(data)
		if not ignoreData or not ignoreData.flag then
			return false
		end

		local whiteflags = ignoreData.buffFlags
		local buffCfgId = data.cfgId
		local buffCfg = csv.buff[buffCfgId]
		local buffFlag = buffCfg.buffFlag

		if battleEasy.intersection(whiteflags, buffFlag) then
			return false
		end

		if ignoreData.objIds[beReplaceTarget.id] then
			return true
		end

		return false
	end

	local function ignoreAttackerFilter()
		if buffData.attackerCfg then
			local allowAttackers = buffData.buff:findTargetsByCfg(buffData.attackerCfg)

			for _, atker in ipairs(allowAttackers) do
				if atker.id == attacker.id then
					return false
				end
			end

			return true
		end

		return false
	end

	if ignoreReplaceFilter(buffData) then
		return
	end

	if ignoreAttackerFilter() then
		return
	end

	local effectData = beReplaceTarget:getEventByKey(battle.ExRecordEvent.replaceTarget)
	local tpyeHash = {}

	if effectData then
		if effectData.takeEffectRound == getRoundMark(play) and effectData.tpyeHash[buffData.cfgId] == true then
			return effectData.toReplaceObj, effectData.aoeTwice, effectData.objectTo
		end

		tpyeHash = effectData.tpyeHash
	end

	tpyeHash[buffData.cfgId] = true

	if buffData:checkToReplaceObj(beReplaceTarget) then
		beReplaceTarget:addExRecord(battle.ExRecordEvent.replaceTarget, {
			takeEffectRound = getRoundMark(play),
			toReplaceObj = buffData.toReplaceObj,
			aoeTwice = buffData.aoeTwice,
			cantMove = buffData.cantMove,
			tpyeHash = tpyeHash
		})
		buffData.buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			buffId = buffData.id,
			easyEffectFunc = buffData.buff.csvCfg.easyEffectFunc,
			obj = buffData.toReplaceObj,
			beReplaceObj = beReplaceTarget
		})

		return buffData.toReplaceObj, buffData.aoeTwice, buffData.objectTo
	end

	beReplaceTarget:addExRecord(battle.ExRecordEvent.replaceTarget, {
		takeEffectRound = getRoundMark(play),
		tpyeHash = tpyeHash
	})
end

function BuffEffectFuncTb.replaceTarget(buff, args, isOver)
	local holder = buff.holder
	local play = holder.scene.play

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.aoeTwice = args[2]
			old.ignoreControl = args[3] == 1
			old.prob = buff.args.buffValueFormula[4] or 1
			old.cantMove = args[5] == 1
			old.timeLimit = args[6]
			old.priority = args[7] or 10
			old.canOnBack = args[8]
			old.ignorePriority = args[9] or 10
			old.isReplaceOther = (buff.csvCfg.specialVal[1] or 0) == 1
			old.objectTo = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 0
			old.isSelfReplaceSelf = (buff.csvCfg.specialVal[3] or 0) == 1

			if buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1] then
				old.attackerCfg = buff.csvCfg.specialTarget[1]
			end

			old.holder = holder

			if old.isReplaceOther then
				old.beReplaceTargetFormula = args[1]
				old.toReplaceObj = holder
			else
				old.toReplaceObj = buff:findTargetsByCfg(args[1])[1]
			end

			function old.checkToReplaceObj(_self, beReplaceTarget)
				local toReplaceObj = _self.toReplaceObj
				local isCanReplace = false

				if _self.isReplaceOther then
					local targets = _self.buff:findTargetsByCfg(_self.beReplaceTargetFormula)

					for _, obj in ipairs(targets) do
						if obj.id == beReplaceTarget.id then
							isCanReplace = true

							break
						end
					end
				else
					isCanReplace = toReplaceObj ~= nil
				end

				if isCanReplace == false then
					return false
				end

				local onBack = not buff.scene:getFieldObject(toReplaceObj.id)

				if not _self.canOnBack and onBack then
					return false
				end

				if toReplaceObj:isNotReSelect(true) then
					return false
				end

				if toReplaceObj:isSelfControled() and not _self.ignoreControl then
					return false
				end

				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					beReplaceObj = beReplaceTarget
				})

				local prob = buff:cfg2Value(_self.prob)

				buff.protectedEnv:resetEnv()

				if prob < ymrand.random() then
					return false
				end

				local data = toReplaceObj:getEventByKey(battle.ExRecordEvent.replaceTargetTime)
				local curRound = getRoundMark(play)
				local newData = {
					time = 1,
					takeEffectRound = curRound
				}
				local isCurRoundData = data and data.takeEffectRound == curRound

				if _self.timeLimit and isCurRoundData and data.time >= _self.timeLimit then
					return false
				end

				if isCurRoundData then
					newData.time = data.time + 1
				end

				toReplaceObj:addExRecord(battle.ExRecordEvent.replaceTargetTime, newData)

				return true
			end
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.replaceTarget, "holderProtectOther", function(ignoreData, attacker, buffData, target)
			return tryProtect(target, attacker, play, buffData, "holderProtectOther", ignoreData)
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.replaceTarget, "casterProtectHolder", function(ignoreData, attacker, buffData)
			return tryProtect(holder, attacker, play, buffData, "casterProtectHolder", ignoreData)
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.filterGroup(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local speVal = buff.csvCfg.specialVal[1]

		holder:addOverlaySpecBuff(buff, function(old)
			old.selfForce = itertools.map(speVal and speVal.selfForce or {}, function(k, v)
				return v, true
			end)
			old.enemyForce = itertools.map(speVal and speVal.enemyForce or {}, function(k, v)
				return v, true
			end)
			old.allForce = itertools.map(speVal and speVal.allForce or {}, function(k, v)
				return v, true
			end)
			old.self = itertools.map(speVal and speVal.self or {}, function(k, v)
				return v, true
			end)
			old.otherRow = itertools.map(speVal and speVal.otherRow or {}, function(k, v)
				return v, true
			end)

			function old.checkFilterGroup(_self, caster, group)
				local isSameObj = (caster and caster.id) == holder.id
				local isSameForce = (caster and caster.force) == holder.force
				local map1 = _self.allForce
				local map2 = isSameForce and _self.selfForce or _self.enemyForce
				local map3 = _self.self
				local map4 = _self.otherRow
				local holderRow = battleEasy.getRowAndColumn(holder)
				local casterRow = battleEasy.getRowAndColumn(caster)

				if isSameObj and next(map3) then
					return map3[group] or map3.all
				end

				if isSameForce and holderRow ~= casterRow and next(map4) then
					return map4[group] or map4.all
				end

				if next(map1) or next(map2) then
					return map1[group] or map1.all or map2[group] or map2.all
				end

				return true
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.filterFlag(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local speVal = buff.csvCfg.specialVal[1]

		holder:addOverlaySpecBuff(buff, function(old)
			old.selfForce = itertools.map(speVal and speVal.selfForce or {}, function(k, v)
				return v, true
			end)
			old.enemyForce = itertools.map(speVal and speVal.enemyForce or {}, function(k, v)
				return v, true
			end)
			old.allForce = itertools.map(speVal and speVal.allForce or {}, function(k, v)
				return v, true
			end)
			old.self = itertools.map(speVal and speVal.self or {}, function(k, v)
				return v, true
			end)
			old.otherRow = itertools.map(speVal and speVal.otherRow or {}, function(k, v)
				return v, true
			end)

			function old.checkFilterFlag(_self, caster, flags)
				local isSameObj = (caster and caster.id) == holder.id
				local isSameForce = (caster and caster.force) == holder.force
				local map1 = _self.allForce
				local map2 = isSameForce and _self.selfForce or _self.enemyForce
				local map3 = _self.self
				local map4 = _self.otherRow
				local holderRow = battleEasy.getRowAndColumn(holder)
				local casterRow = battleEasy.getRowAndColumn(caster)

				if isSameObj and next(map3) then
					if map3.all then
						return true
					end

					for _, flag in ipairs(flags) do
						if map3[flag] then
							return true
						end
					end

					return false
				end

				if isSameForce and holderRow ~= casterRow and next(map4) then
					if map4.all then
						return true
					end

					for _, flag in ipairs(flags) do
						if map4[flag] then
							return true
						end
					end

					return false
				end

				if next(map1) or next(map2) then
					if map1.all or map2.all then
						return true
					end

					for _, flag in ipairs(flags) do
						if map1[flag] or map2[flag] then
							return true
						end
					end

					return false
				end

				return true
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.buffRecord(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local key = buff:cfg2ValueWithTrigger(buff.csvCfg.specialVal[1])
		local val = buff:cfg2ValueWithTrigger(buff.csvCfg.specialVal[2])

		key = key or buff.csvCfg.specialVal[1]

		local typ = type(key)

		if typ ~= "string" and typ ~= "number" then
			key = key.model and key.model.id or key.id or 0
		elseif typ == "number" then
			key = key .. (buff.caster and buff.caster.id)
		end

		buff:addExRecord(battle.ExRecordEvent.buffRecord, val, key)
	end
end

function BuffEffectFuncTb.summon(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local specialVal = buff.csvCfg.specialVal or {}
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local summoner = targetCfg and buff:findTargetsByCfg(targetCfg)[1] or holder
		local summonForce = specialVal[1] == 1 and 3 - summoner.force or summoner.force
		local belongForce = specialVal[2] == 1 and 3 - summoner.force or summoner.force
		local stepNum = summonForce == 1 and 0 or holder.scene.play.ForceNumber
		local summonNum = args[5] or 1
		local summonPos

		summonPos = battleEasy.ifElse(args[2] ~= -1 and summonNum > 1, 0, args[2])
		summonPos = args[2] == 99 and holder.seat or summonPos

		local posTargetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[2]

		if posTargetCfg then
			local posTarget = buff:findTargetsByCfg(posTargetCfg)[1]

			summonPos = posTarget and posTarget.seat

			if not summonPos then
				return
			end
		end

		local summonBackStage = summonPos == -1
		local replaceObj = args[10] == 1
		local summonGroupIdFrom = specialVal[3]
		local summonGroupId = summoner.summonGroup

		if summonGroupIdFrom == 2 then
			summonGroupId = holder.summonGroup
		elseif summonGroupIdFrom == 3 then
			summonGroupId = buff.caster.summonGroup
		end

		for i = 1, summonNum do
			if summonPos == 0 then
				for seat = 1 + stepNum, holder.scene.play.ForceNumber + stepNum do
					if holder.scene:isSeatEmpty(seat) then
						summonPos = seat

						break
					end
				end
			end

			if summonPos ~= 0 then
				local roleOut = battleEasy.getSummonRoleOut(args, summoner)

				roleOut.summonGroup = summonGroupId
				roleOut.force = belongForce

				local newTarget

				newTarget, summonBackStage = holder.scene.play:addCardRole(summonPos, roleOut, summonBackStage, belongForce, replaceObj, summoner)

				if newTarget then
					buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
						obj = newTarget,
						buffId = buff.id,
						easyEffectFunc = buff.csvCfg.easyEffectFunc
					})

					if summonBackStage == false then
						table.insert(holder.scene.play.summonHeros, {
							obj = newTarget
						})
						newTarget:initedTriggerPassiveSkill()
						holder.scene:tirggerFieldBuffs(newTarget)
					end

					newTarget:addExRecord(battle.ExRecordEvent.summoner, summoner)
				end

				if not summonBackStage then
					summonPos = 0
				end
			end
		end
	end
end

function BuffEffectFuncTb.templateSummon(buff, args, isOver)
	if isOver then
		return
	end

	local holder = buff.holder
	local caster = buff.caster
	local targetFindFormula = buff.csvCfg.specialTarget[1]
	local findTargets

	if targetFindFormula then
		if type(targetFindFormula) == "table" and targetFindFormula.process == nil then
			if targetFindFormula.input == "caster" then
				findTargets = {
					caster
				}
			elseif targetFindFormula.input == "holder" then
				findTargets = {
					holder
				}
			end
		else
			findTargets = buff:findTargetsByCfg(targetFindFormula)
		end
	end

	if findTargets == nil then
		findTargets = {
			holder
		}
	end

	local summoner = findTargets[1]
	local unitID = args[1]
	local extraObjectCfgID = args[3]
	local initCfg = csv.extra_object[extraObjectCfgID]
	local exportData = battleEasy.initRoleOut(buff, findTargets):fillSeat(args[4]):fillForce(args[5]):fillAttrs(initCfg.extendAttr):exportAsSummon(unitID, summoner, args[2], extraObjectCfgID, args[6])

	if exportData.seat == nil then
		return
	end

	local summonTarget, isBackStage = holder.scene.play:addSummonRole(exportData.seat, exportData.roleOut, exportData.seat == -1, exportData.force, nil, summoner)

	if summonTarget then
		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			obj = summonTarget,
			buffId = buff.id
		})

		if isBackStage == false then
			table.insert(holder.scene.play.summonHeros, {
				obj = summonTarget
			})
			summonTarget:initedTriggerPassiveSkill()
			holder.scene:tirggerFieldBuffs(summonTarget)
		end

		summonTarget:addExRecord(battle.ExRecordEvent.summoner, summoner)
	end
end

function BuffEffectFuncTb.buffSputtering(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local rate = args[1]
		local priority = args[2] or 10
		local beAttackCantRecoverMp = args[3] == 1 and true or false

		holder:addOverlaySpecBuff(buff, function(old)
			old.rate = rate
			old.beAttackCantRecoverMp = beAttackCantRecoverMp
			old.priority = priority
		end, function(a, b)
			if a.priority == b.priority then
				return a.buff.id < b.buff.id
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.swapSpeed(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.sortKey = ymrand.random()
			old.groupKey = string.format("c%d_b%d", buff.caster.id, buff.cfgId)
			old.oriSpeed = -1
			old.newSpeed = -1
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			holder.scene.extraRecord:addExRecord(battle.ExRecordEvent.swapSpeedRefresh, old.groupKey, 1)
		end)
	end
end

function BuffEffectFuncTb.changeBuffDamageArgs(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local buffGroupIds = args[1]
		local buffGroupTb = {}

		for _, id in ipairs(buffGroupIds) do
			buffGroupTb[id] = {
				processId = args[2],
				damageType = args[3]
			}
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.buffGroupTb = buffGroupTb
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.reboundBuff(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if args[1] == nil then
				errorInWindows("buff:%s args[1] is nil", buff.cfgId)

				old.groups = {}
			else
				old.groups = arraytools.hash(args[1])
			end

			old.groups = arraytools.hash(args[1])
			old.forceLimit = args[2] or 0
			old.newHolder = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
			old.newBuffRound = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 0
			old.getNewHolder = functools.partial(function(_buff, str, caster)
				return newTargetFinder(caster, _buff.holder, nil, {}, str)[1]
			end, buff, old.newHolder)
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.reflexDamage(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.rate = args[1]
			old.buffFlagMap = arraytools.hash(args[2] or {})
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.forbiddenExtraAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.buffFlags = arraytools.hash(args[1] or {})
			old.isBlackMode = args[2] == 1
			old.modeCheck = args[3]
			old.forbiddenModes = arraytools.hash(args[3] or {})
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.needMoreDispel(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args[1]
			old.buffMap = arraytools.hash(args[2] or {})
			old.dispelTimes = args[3]
			old.dispelMap = {}
		end, function(a, b)
			if a.dispelTimes == b.dispelTimes then
				return a.id < b.id
			else
				return a.dispelTimes > b.dispelTimes
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.changeTreatment(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.rate = args[1]
			old.mode = args[2] or 1
			old.isFromCaster = args[3] == 1
			old.targetFunc = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
			old.maxFunc = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
			old.timesLimit = {
				curRound = -1,
				times = 0,
				limit = args[4] or 99999
			}
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.changeTreatment, "change", function(resumeHpVal, resumeArgs, fromObj)
			local finalResume = resumeHpVal

			for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeTreatment) do
				local curRound = holder.scene.play.curRound
				local timesArgs = data.timesLimit

				if curRound > timesArgs.curRound or timesArgs.times < timesArgs.limit then
					if curRound > timesArgs.curRound then
						timesArgs.curRound = curRound
						timesArgs.times = 0
					end

					timesArgs.times = timesArgs.times + 1

					local resumeVal = math.floor(finalResume * data.rate)
					local targets = data.buff:findTargetsByCfg(data.targetFunc)
					local maxTreat = data.buff:cfg2Value(data.maxFunc)

					if maxTreat then
						resumeVal = math.min(resumeVal, maxTreat)
					end

					finalResume = finalResume - resumeVal

					if data.mode == 2 then
						resumeVal = math.floor(resumeVal / table.length(targets))
					end

					local newArgs = {
						ignoreChange = true,
						from = battle.ResumeHpFrom.buff,
						ignoreLockResume = resumeArgs.ignoreLockResume,
						ignoreHealAddRate = resumeArgs.ignoreHealAddRate,
						ignoreBeHealAddRate = resumeArgs.ignoreBeHealAddRate,
						fromKey = data.buff.cfgId
					}
					local fromWho = data.isFromCaster and data.buff.caster or fromObj

					for _, obj in ipairs(targets) do
						obj:resumeHp(fromWho, resumeVal, newArgs)
					end
				end
			end

			return finalResume
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.brawl(buff, args, isOver)
	local holder = buff.holder
	local caster = buff.caster
	local scene = holder.scene
	local play = scene.play
	local lastInfo = scene:getSpecialSceneInfo()

	if not isOver then
		if lastInfo or scene.specialRound:isIdleWaitEffect() then
			buff:overClean()

			return
		end

		local isDuel = args[4] == 1

		assert(gFormulaConst, "gFormulaConst is nil")

		local groups = gFormulaConst.canattack() or {}
		local ignoreGroups = arraytools.hash(groups)
		local buffNames = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local forbiddenBuffs = arraytools.hash(buffNames or {})
		local whiteList = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
		local buffFlagMap = arraytools.hash(whiteList or {})
		local cfgID = buff.cfgId
		local casterID = buff.caster.id

		if isDuel then
			local casterSkillBaned = helper.adjustSkillType2Data({
				[battle.MainSkillType.NormalSkill] = false,
				[battle.MainSkillType.SmallSkill] = false,
				[battle.MainSkillType.BigSkill] = true
			}, args[5] and args[5][1])
			local targetSkillBaned = helper.adjustSkillType2Data({
				[battle.MainSkillType.NormalSkill] = false,
				[battle.MainSkillType.SmallSkill] = true,
				[battle.MainSkillType.BigSkill] = true
			}, args[5] and args[5][2])
			local costType = args[6]

			scene.specialRound:init(buff, {
				isSoloWithCaster = true,
				ignoreGroups = ignoreGroups,
				forbiddenBuffs = forbiddenBuffs,
				buffFlagMap = buffFlagMap,
				mode = battle.ExtraAttackMode.duel,
				extraAttackArgsGet = function(obj)
					if obj.id == casterID then
						return ExtraAttackArgs.fromDuel(buff.id, cfgID, casterSkillBaned, costType)
					else
						return ExtraAttackArgs.fromDuel(buff.id, cfgID, targetSkillBaned, costType)
					end
				end
			}, {
				timeScale = args[3],
				changeViewSeat = args[9] and args[9] == 1
			})
			scene.specialRound:setRoundOverCondition(args[1], 0, 0)
			scene.specialRound:setSiteTargets(nil, buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1])
			scene.specialRound:setRoundUpdate(true)
		else
			local triggerSkillType2 = args[2]

			scene.specialRound:init(buff, {
				ignoreGroups = ignoreGroups,
				forbiddenBuffs = forbiddenBuffs,
				buffFlagMap = buffFlagMap,
				mode = battle.ExtraAttackMode.brawl,
				extraAttackArgsGet = function(obj)
					return ExtraAttackArgs.fromBrawl(buff.id, cfgID, triggerSkillType2)
				end
			}, {
				timeScale = args[3]
			})
			scene.specialRound:setRoundOverCondition(0, 0, args[1])
			scene.specialRound:setSiteTargets(buff:findTargetsByCfg(buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]))
			scene.specialRound:setAutoChoose(1)
		end

		scene.specialRound:setAttackRule(args[8])
		scene.specialRound:setSeatEmpty(true)
	elseif lastInfo and lastInfo.buff.id == buff.id then
		lastInfo:resetState()
	end
end

function BuffEffectFuncTb.forbiddenAddHP(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.isAll = args[1] == 1
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.lockShield(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.lockValue = args[1] or 1
			old.priority = args[2] or 0
			old.lockType = args[3] or 1
			old.triggerState = false
			old.needTriggerPoint = false
		end, function(buffA, buffB)
			if buffA.priority == buffB.priority then
				if buffA.lockValue == buffB.lockValue then
					return buffA.id < buffB.id
				else
					return buffA.lockValue > buffB.lockValue
				end
			else
				return buffA.priority > buffB.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.invincible(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			return
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.noCostMp(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			return
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.castBuffModifiy(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.groups = args[1][1]
			old.flags = args[1][2]
			old.castBuffArgs = args[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.addAuraAttr(buff, args, isOver)
	for _, t in ipairs(helper.argsArray(args)) do
		local attrName = t.attr
		local value = t.val

		if not isOver then
			buff.holder:objAddAuraAttr(attrName, value)

			buff.triggerAddAttrTb[attrName] = buff.triggerAddAttrTb[attrName] and buff.triggerAddAttrTb[attrName] + value or value
		else
			value = -(buff.triggerAddAttrTb[attrName] or 0)

			buff.holder:objAddAuraAttr(attrName, value)

			buff.triggerAddAttrTb[attrName] = nil
		end
	end

	return true
end

function BuffEffectFuncTb.healBoost(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.hpRatelimit = args[1]
			old.boostRate = args[2] or 0
		end, function(a, b)
			if a.hpRatelimit == b.hpRatelimit then
				return a.id < b.id
			else
				return a.hpRatelimit > b.hpRatelimit
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.healBoost, "boost", function(resumeHpVal, target)
			local finalResume = resumeHpVal
			local finalboost = 0
			local hpRate = target:hp() / target:hpMax()

			for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.healBoost) do
				if hpRate < data.hpRatelimit then
					finalboost = finalboost + data.boostRate
				end
			end

			finalResume = finalResume * (1 + finalboost)

			return finalResume
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.forceMaxHpLimit(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local limit = args[1]

		holder:addOverlaySpecBuff(buff, function(old)
			old.maxHpLimit = math.ceil(limit)
		end, function(buffA, buffB)
			if buffA.maxHpLimit == buffB.maxHpLimit then
				return buffA.id < buffB.id
			else
				return buffA.maxHpLimit < buffB.maxHpLimit
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end
