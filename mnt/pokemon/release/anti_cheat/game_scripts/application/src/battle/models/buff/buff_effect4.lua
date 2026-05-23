-- chunkname: @src.battle.models.buff.buff_effect4

local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

local function reflectBuff(buff, args, cfgId, buffHolder, buffCaster, buffArgs)
	local curObject = buff.holder
	local curObjectForce = curObject.force
	local delayRound = args[4] or 0
	local prob = args[5] or 1
	local once = true
	local reflectBuffCfg = csv.buff[cfgId]
	local reflectBuffGroupPower = reflectBuffCfg.groupPower and csv.buff_group_power[reflectBuffCfg.groupPower]
	local isNeedReflect = false
	local isSuccess = false
	local limitedCasters = args[6] and buff:findTargetsByCfg(args[6]) or nil
	local limitedCastersHash = {}

	itertools.each(limitedCasters, function(idx, obj)
		limitedCastersHash[obj.id] = true
	end)

	local data = {
		triggerRound = buff.lifeRound - delayRound,
		prob = prob
	}

	buff:addExRecord(battle.ExRecordEvent.copyOrTransferBuff, data)

	local isspstructure, buffFilterMap = false

	if args[1].__spstructure == battle.spstructure.BuffFilterMap then
		isspstructure = true
		buffFilterMap = args[1]
	else
		buffFilterMap = arraytools.hash(args[1])
	end

	local function checkBuffCanReflect()
		local filterPassed = false

		if isspstructure then
			filterPassed = battleEasy.BuffFilterTool.filter(buffFilterMap, reflectBuffCfg.cfgId, reflectBuffCfg.group, reflectBuffCfg.buffFlag)
		else
			filterPassed = reflectBuffCfg.group and buffFilterMap[reflectBuffCfg.group]
		end

		if not filterPassed then
			return false
		end

		if reflectBuffGroupPower and reflectBuffGroupPower.beTransfer == 0 then
			return false
		end

		if limitedCasters and not limitedCastersHash[buffCaster.id] then
			return false
		end

		return true
	end

	if checkBuffCanReflect() and data.triggerRound >= buff.lifeRound and data.prob > ymrand.random() then
		isNeedReflect = true

		local holders = {}

		if args[2] == 7 and curObject.curAttackMeObj then
			table.insert(holders, curObject.curAttackMeObj)
		elseif args[2] == battle.copyOrTransferSpecType.eachCaster then
			holders = {
				battle.copyOrTransferSpecType.eachCaster
			}
		else
			holders = buff:findTargetsByCfg(args[2])
		end

		for _, holder in ipairs(holders) do
			if holder == battle.copyOrTransferSpecType.eachCaster then
				holder = buffCaster
			end

			local curBuff, takeEffect, newCurObject

			if holder then
				if buff.csvCfg.specialVal then
					if buff.csvCfg.specialVal[1] == 1 then
						newCurObject = buffCaster
					end

					if not buffArgs.originPriority or buffArgs.originPriority < (buff.csvCfg.specialVal[2] or 1) then
						buffArgs.originPriority = buff.csvCfg.specialVal[2]
					end
				end

				buffArgs.alreadyReflect = true
				curBuff, takeEffect = addBuffToHero(cfgId, holder, newCurObject or curObject, buffArgs)
			end

			if takeEffect then
				if once then
					buff:playTriggerPointEffect()

					once = false
				end

				buff.holder:addExRecord(battle.ExRecordEvent.transferSucessCount, 1)
				buff:addExRecord(battle.ExRecordEvent.transferState, true)
				buff:addExRecord(battle.ExRecordEvent.sucessCount, 1)

				isSuccess = true
			end
		end

		if isSuccess then
			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				obj = buff.holder
			})
		end
	end

	return isNeedReflect
end

local function copyOrTransferBuff(buff, args, isTransferBuff, isCopyGroup, isClassArgs1)
	local curObject = buff.holder
	local curObjectForce = curObject.force
	local limit = args[3]
	local delayRound = args[4] or 0
	local prob = args[5] or 1
	local overlayMode = args[6] == 1
	local followTransferor = false
	local once = true
	local data = {
		triggerRound = buff.lifeRound - delayRound,
		buffTab = {},
		prob = prob,
		isTransferBuff = isTransferBuff
	}

	buff:addExRecord(battle.ExRecordEvent.copyOrTransferBuff, data)

	local buffFilterMap

	if isClassArgs1 then
		buffFilterMap = args[1]
	else
		buffFilterMap = arraytools.hash(args[1])
	end

	local function checkBuff(curBuff)
		local filterPassed

		if isClassArgs1 then
			filterPassed = battleEasy.BuffFilterTool.filter(buffFilterMap, curBuff.cfgId, curBuff:group(), curBuff:buffFlag())
		else
			filterPassed = curBuff:group() and buffFilterMap[curBuff:group()]
		end

		if not filterPassed then
			return false
		end

		if isCopyGroup and curBuff.holder.force ~= curObjectForce then
			return false
		end

		if isTransferBuff and curBuff.csvPower.beTransfer == 0 then
			return false
		end

		if not isTransferBuff and curBuff.csvPower.beCopy == 0 then
			return false
		end

		return true
	end

	local function addArgs2Tab(curBuff)
		if checkBuff(curBuff) == false then
			return
		end

		local newArgs = BuffArgs.fromCopyOrTransfer1(curBuff)

		if overlayMode and not curBuff:isCoexistType() then
			local total = newArgs.overlayCount

			newArgs.overlayCount = 1

			for i = 1, total do
				table.insert(data.buffTab, newArgs)
			end
		else
			table.insert(data.buffTab, newArgs)
		end
	end

	local function makeBuffTab()
		if buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1] then
			local targets = buff:findTargetsByCfg(buff.csvCfg.specialTarget[1])

			if targets then
				for _, obj in ipairs(targets) do
					for __, curBuff in obj:iterBuffs() do
						addArgs2Tab(curBuff)
					end
				end

				followTransferor = true

				return
			end
		end

		local array = isCopyGroup and curObject.scene.allBuffs or curObject.buffs

		for _, curBuff in array:order_pairs() do
			addArgs2Tab(curBuff)
		end
	end

	makeBuffTab()

	local function mergeOverlays(buffTb)
		local argsTb, finalTb, record = {}, {}, {}

		for _, tb in ipairs(buffTb) do
			local id = tb.id

			if not argsTb[id] then
				argsTb[id] = tb
			else
				argsTb[id].overlayCount = argsTb[id].overlayCount + 1
			end
		end

		for _, tb in ipairs(buffTb) do
			if argsTb[tb.id] and not record[tb.id] then
				table.insert(finalTb, argsTb[tb.id])
			end

			record[tb.id] = true
		end

		return finalTb
	end

	local recordTbl = buff:getEventByKey(battle.ExRecordEvent.copyOrTransferBuff) or {}

	for i = table.length(recordTbl), 1, -1 do
		local _data = recordTbl[i]

		if _data.triggerRound >= buff.lifeRound then
			local buffTb = _data.buffTab
			local isTakeEffect = {}

			if _data.prob > ymrand.random() then
				local holders = {}
				local buffRound = buff.csvCfg.specialVal[1]

				if args[2] == 7 and curObject.curAttackMeObj then
					table.insert(holders, curObject.curAttackMeObj)
				elseif args[2] == battle.copyOrTransferSpecType.eachCaster then
					holders = {
						battle.copyOrTransferSpecType.eachCaster
					}
				elseif args[7] ~= 1 then
					holders = buff:findTargetsByCfg(args[2])
				end

				table.sort(buffTb, function(buff1, buff2)
					return buff1.id < buff2.id
				end)

				if next(buffTb) then
					buffTb = random.sample(buffTb, limit, ymrand.random)

					if overlayMode then
						buffTb = mergeOverlays(buffTb)
					end

					local isSuccess = false

					for _, vbuff in ipairs(buffTb) do
						if args[7] == 1 then
							holders = buff:findTargetsByCfg(args[2], nil, {
								inputExtraStr = string.format("sortByBuffOverlayLimit(%s)", vbuff.cfgId)
							})
						end

						for _, holder in ipairs(holders) do
							if holder == battle.copyOrTransferSpecType.eachCaster then
								holder = buff.scene:getFieldObject(vbuff.casterID)
							end

							local curBuff, takeEffect, newCurObject

							if holder then
								if buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] == 1 then
									newCurObject = buff.scene:getFieldObject(vbuff.casterID)
								end

								local newArgs = BuffArgs.fromCopyOrTransfer2(vbuff, buffRound, curObject.curSkill)

								curBuff, takeEffect = addBuffToHero(vbuff.cfgId, holder, newCurObject or curObject, newArgs)
							end

							if takeEffect then
								if once then
									buff:playTriggerPointEffect()

									once = false
								end

								if _data.isTransferBuff then
									buff.holder:addExRecord(battle.ExRecordEvent.transferSucessCount, 1)
									buff:addExRecord(battle.ExRecordEvent.transferState, true)
								else
									buff.holder:addExRecord(battle.ExRecordEvent.copySucessCount, 1)
									buff:addExRecord(battle.ExRecordEvent.copyState, true)
								end

								buff:addExRecord(battle.ExRecordEvent.sucessCount, 1)

								isSuccess = true
							end

							isTakeEffect[vbuff.id] = takeEffect
						end
					end

					_data.buffTab = buffTb

					if isSuccess then
						buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
							obj = buff.holder
						})
					end
				end
			end

			local function overByMode(_obj, _buff)
				local oriBuff = _obj:getBuffByID(_buff.id)

				if not oriBuff then
					return
				end

				if not overlayMode then
					oriBuff:over()

					return
				end

				if oriBuff:isCoexistType() then
					oriBuff:over()
				elseif _buff.overlayCount == oriBuff.overlayLimit then
					oriBuff:over()
				else
					oriBuff:refresh(oriBuff.args, -_buff.overlayCount)
				end
			end

			table.remove(recordTbl, i)

			local function endBuffFromCurObject()
				for _, vbuff in ipairs(_data.buffTab) do
					overByMode(curObject, vbuff)
				end
			end

			local function endBuffFromForce()
				for _, vbuff in ipairs(_data.buffTab) do
					local obj = curObject.scene:getFieldObject(vbuff.holderID)

					if obj then
						overByMode(obj, vbuff)
					end
				end
			end

			local function endBuffFromTransferor()
				for _, vbuff in ipairs(_data.buffTab) do
					local obj = curObject.scene:getFieldObject(vbuff.holderID)

					if isTakeEffect[vbuff.id] and obj then
						overByMode(obj, vbuff)
					end
				end
			end

			if _data.isTransferBuff then
				if followTransferor then
					endBuffFromTransferor()
				elseif isCopyGroup then
					endBuffFromForce()
				else
					endBuffFromCurObject()
				end
			end
		end
	end
end

function BuffEffectFuncTb.keepHpUnChanged(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.triggerTime = args[1]
			old.prob = args[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.updSkillSpellRoundOnce(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		for _, skill in holder:iterSkills() do
			if skill.skillType2 == battle.MainSkillType.SmallSkill then
				local isSelfTurn = false
				local curHero = holder.scene.play.curHero

				if curHero then
					isSelfTurn = curHero.id == holder.id
				end

				local extraBattleRound = isSelfTurn and -1 or 0

				if skill.spellRound == -99 then
					skill.spellRound = holder:getBattleRound(2) - skill.cdRound + extraBattleRound
				end

				skill.spellRound = skill.spellRound - args
			end
		end
	end

	return true
end

function BuffEffectFuncTb.lockHp(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		buff.buffValue[1] = buff.buffValue[1] or 1

		buff:setValue(buff.buffValue)
		holder:addOverlaySpecBuff(buff, function(old)
			old.hasTriggered = false
			old.triggerEndRound = args[2]
			old.mode = args[3]
			old.extraArg = args[4]
			old.priority = args[5] or 0
			old.holdRecord = 0

			if buff.csvCfg.specialVal then
				old.holdRecord = buff.csvCfg.specialVal[2] or old.holdRecord
				old.extraF = buff.csvCfg.specialVal[3]
			end

			old.isPreDelete = false

			if old.mode ~= 1 then
				old.damageMap = {}
			end

			if old.mode == 4 then
				old.extraArg = buff:cfg2Value(old.extraArg)
			end

			function old.checkCondition(_self, attacker, record)
				local canTakeEffect = false

				if not buff.csvCfg.specialVal then
					canTakeEffect = true
				else
					buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
						attacker = attacker,
						record = record
					})
					canTakeEffect = buff:cfg2Value(buff.csvCfg.specialVal[1])

					buff.protectedEnv:resetEnv()
				end

				return canTakeEffect
			end
		end, function(a, b)
			if a.priority == b.priority then
				if a.mode == b.mode then
					return a.buff.id < b.buff.id
				else
					return a.mode > b.mode
				end
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.copyCasterBuffsToHolder(buff, args, isOver)
	if not isOver then
		copyOrTransferBuff(buff, args, false, false, false)
	end

	return true
end

function BuffEffectFuncTb.diffuseBuffToOther(buff, args, isOver)
	if not isOver then
		copyOrTransferBuff(buff, args, false, false, false)
	end

	return true
end

function BuffEffectFuncTb.transferBuffToOther(buff, args, isOver)
	if not isOver then
		copyOrTransferBuff(buff, args, true, false, false)
	end

	return true
end

function BuffEffectFuncTb.transferBuffToOtherWithFilter(buff, args, isOver)
	if not isOver then
		copyOrTransferBuff(buff, args, true, false, true)
	end

	return true
end

function BuffEffectFuncTb.reflectBuffToOther(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local reflectBuff = functools.partial(reflectBuff, buff, args)

		holder:addOverlaySpecBuff(buff, function(old)
			old.reflectBuff = reflectBuff
			old.limit = args[3]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.delayBuff(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.buffIdTb = arraytools.hash(args[1])
			old.buffGroupTb = arraytools.hash(args[2])
			old.buffFlagTb = arraytools.hash(args[3])
			old.priority = args[4] or 0
			old.needDelayBuffTb = {}
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

	return true
end

function BuffEffectFuncTb.copyForceBuffsToOther(buff, args, isOver)
	if not isOver then
		copyOrTransferBuff(buff, args, false, true)
	end

	return true
end

function BuffEffectFuncTb.swapBuffsWithOther(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local target = targetCfg and buff:findTargetsByCfg(targetCfg)[1]

		if not target then
			return
		end

		local swapNums = args[3]
		local lifeRoundRule = args[4]

		local function getLifeRound(_buff)
			if lifeRoundRule == -1 then
				return _buff.args.lifeRound
			end

			if lifeRoundRule == 0 then
				return _buff.lifeRound
			end

			return lifeRoundRule
		end

		local function getCanSwapBuffsByGroups(obj, groups)
			local ret = {}

			for _, group in ipairs(groups) do
				for _, _buff in obj:queryBuffsWithGroup(group):order_pairs() do
					if table.length(ret) == swapNums then
						break
					end

					if not _buff.isOver and _buff.csvPower.beSwap == 1 then
						table.insert(ret, _buff)
					end
				end
			end

			return ret
		end

		local function dealBuffSwap(fromObj, toObj, _buff)
			local newArgs = BuffArgs.fromSwapBuffWithOther(_buff, getLifeRound(_buff))
			local curBuff, takeEffect = addBuffToHero(_buff.cfgId, toObj, fromObj, newArgs)

			_buff:over()
		end

		local holderSwapBuffs = getCanSwapBuffsByGroups(holder, args[1])
		local targetSwapBuffs = getCanSwapBuffsByGroups(target, args[2])
		local realSwapNums = math.min(table.length(holderSwapBuffs), table.length(targetSwapBuffs))

		for k = 1, realSwapNums do
			dealBuffSwap(holder, target, holderSwapBuffs[k])
			dealBuffSwap(target, holder, targetSwapBuffs[k])
		end
	end

	return true
end

function BuffEffectFuncTb.cantDispelBuffRound(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.buffGroupTb = arraytools.hash(args)
			old.buffRound = buff.csvCfg.specialVal[1]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.changeSpeedPriority(buff, args, isOver)
	local isSameForce = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
	local gate = buff.holder.scene.play

	if not isOver then
		if isSameForce == 1 then
			local function buffCheck(buffid)
				if not args[2] then
					return true
				end

				return buffid == args[2]
			end

			table.insert(gate.speedSortRule, {
				id = buff.id,
				sort = function(tbForSort)
					local objId = buff.scene.play:getObjectBaseSpeedRankSortKey(buff.holder)
					local delId, insertId

					for k, v in ipairs(tbForSort) do
						if v.objId == objId and buffCheck(v.buffCfgId) then
							delId = delId or k
						elseif v.force == buff.holder.force then
							if args[1] == 1 then
								insertId = insertId or math.max(1, delId and k - 1 or k)
							else
								insertId = math.min(table.length(tbForSort), delId and k or k + 1)
							end
						end
					end

					if delId and insertId then
						local data = table.remove(tbForSort, delId)

						table.insert(tbForSort, insertId, data)
					end
				end
			})
		else
			local function func(force, arg, val)
				if buff.csvCfg.specialVal and isSameForce == 2 and force == buff.holder.force then
					return val
				end

				local objs = buff.scene:getHerosMap(force)
				local _val = val

				for _, obj in objs:order_pairs() do
					_val = _val or obj.speedPriority
					_val = arg == 1 and math.max(_val, obj.speedPriority) or math.min(_val, obj.speedPriority)
				end

				return _val
			end

			local priority = func(1, args[1], nil)

			priority = func(2, args[1], priority)
			buff.holder.speedPriority = priority + args[1]
		end
	elseif isSameForce == 1 then
		for k, v in ipairs(gate.speedSortRule) do
			if v.id == buff.id then
				table.remove(gate.speedSortRule, k)

				return
			end
		end
	else
		buff.holder.speedPriority = 0
	end
end

function BuffEffectFuncTb.resetBattleRound(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local isRecord = type(args) == "table" and args[1] == 1
		local data = {
			obj = holder,
			id = buff.id,
			reset = buff.id,
			buffCfgId = buff.cfgId
		}

		data.mode = battle.ExtraBattleRoundMode.reset

		holder.scene.play:resetGateAttackRecord(holder, data, isRecord)
	end
end

function BuffEffectFuncTb.atOnceBattleRound(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local isRecord = type(args) == "table" and args[1] == 1
		local data = {
			obj = holder,
			id = buff.id,
			atOnce = buff.id,
			buffCfgId = buff.cfgId
		}

		data.mode = battle.ExtraBattleRoundMode.atOnce

		holder.scene.play:resetGateAttackRecord(holder, data, isRecord)
	end
end

function BuffEffectFuncTb.geminiBattleRound(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local isRecord = type(args) == "table" and args[1] == 1
		local data = {
			another = true,
			obj = holder,
			id = buff.id,
			buffCfgId = buff.cfgId
		}

		data.mode = battle.ExtraBattleRoundMode.gemini

		holder.scene.play:resetGateAttackRecord(holder, data, isRecord)
	end
end

function BuffEffectFuncTb.buffBattleRound(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local roundBuffEffect = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]

		holder:addOverlaySpecBuff(buff, function(old)
			old.isTakeEffect = false
		end, nil)
		BuffEffectFuncTb[roundBuffEffect](buff, {
			1
		}, isOver)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			if not old.isTakeEffect then
				holder.scene.play:setHeroIsAttacked(holder, nil, true)
			end
		end)
	end
end

function BuffEffectFuncTb.stealth(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.cantBeAttackSwitch = args[1] == 0
			old.cantBeAddBuffSwitch = args[2] == 0
			old.cantBeHealHintSwitch = args[3] == 0
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

local function checkBuffFlag(ignoreData, buffData)
	for idx, flag in ipairs(buffData.buff.csvCfg.buffFlag) do
		if ignoreData.flags[flag] then
			return true
		end
	end

	return false
end

function BuffEffectFuncTb.ignoreSpecBuff(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local targets = targetCfg and buff:findTargetsByCfg(targetCfg)

		holder:addOverlaySpecBuff(buff, function(old)
			old.cfgIds = itertools.map(args[1] or {}, function(k, v)
				return v, true
			end)
			old.groupIds = itertools.map(args[2] or {}, function(k, v)
				return v, true
			end)
			old.hasTargetCfg = targetCfg ~= nil

			if targets and table.length(targets) > 0 then
				old.targets = itertools.map(targets, function(k, v)
					return v.id, true
				end)
			end

			old.flags = itertools.map(args[3] or {}, function(k, v)
				return v, true
			end)
			old.specBuffList = itertools.map(buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}, function(k, v)
				return v, true
			end)
			old.filterFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]

			function old.trigger(old_)
				old_.buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
					buffId = old_.buff.id
				})
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.ignoreSpecBuff, "ignoreCheck", function(key, id, data, envExData)
			local function targetCheck(ignoreData)
				if not ignoreData.hasTargetCfg then
					return true
				end

				if not ignoreData.targets then
					return false
				end

				if id and ignoreData.targets[id] then
					return true
				end

				return false
			end

			for _, ignoreData in holder:ipairsOverlaySpecBuff("ignoreSpecBuff") do
				if targetCheck(ignoreData) then
					local isTrigger = false

					if ignoreData.specBuffList[key] then
						isTrigger = true
					end

					if data and (ignoreData.cfgIds[data.cfgId] or ignoreData.groupIds[data.group] or checkBuffFlag(ignoreData, data)) then
						if ignoreData.filterFormula then
							local env = {
								buff = battleCsv.CsvBuff.newWithCache(data.buff),
								envExData = envExData or {}
							}
							local res = battleCsv.doFormula(ignoreData.filterFormula, env)

							if res then
								isTrigger = true
							end
						else
							isTrigger = true
						end
					end

					if isTrigger then
						ignoreData:trigger()

						return true, ignoreData
					end
				end
			end

			return false
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.ignorePriorityBuff(buff, args, isOver)
	local priority = math.floor(helper.argsCheck(buff.buffValue, buff))
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.ignorePriority = priority
			old.ignoreBuffType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.leave(buff, args, isOver)
	if type(args) == "number" then
		args = {
			args
		}
	end

	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.canAttack = args and args[1] == 0
		end, nil)

		buff.isEffect = true
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	holder:onPositionStateChange(isOver, true, true, buff)

	if not isOver then
		holder:onLeaveSeat({
			group = buff:group()
		})
	end
end

function BuffEffectFuncTb.depart(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.cantBeAttackSwitch = args[1] == 0
			old.cantBeAddBuffSwitch = args[2] == 0
			old.cantBeHealHintSwitch = args[3] == 0
			old.leaveSwitch = args[4] == 0
			old.canAttack = args[5] == 0
			old.canProtect = args[6] == 0
		end, nil)

		buff.isEffect = true
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	holder:onPositionStateChange(isOver, args[4] == 0, true, buff)

	if not isOver then
		holder:onLeaveSeat({
			group = buff:group()
		})
	end
end

function BuffEffectFuncTb.bufflink(buff, args, isOver)
	local holder = buff.holder
	local fixValue = args[1]
	local groups = args[2]
	local targets = buff:findTargetsByCfg(args[3])
	local targetIds = {}

	for _, obj in ipairs(targets) do
		table.insert(targetIds, obj.id)
	end

	if not isOver then
		for _, v in ipairs(targetIds) do
			buff.scene.buffGlobalManager:setBuffLinkValue(holder.id, v, fixValue, groups, buff.cfgId)
		end
	else
		buff.scene.buffGlobalManager:onBuffLinkOver(buff.cfgId)
	end

	return true
end

function BuffEffectFuncTb.refreshBuffLifeRound(buff, args, isOver)
	if not isOver then
		for _, buffTb in ipairs(args) do
			local buffRound = buffTb[2]
			local buffLifeRound

			if buffTb[3] then
				local buffGroupId = buffTb[1]

				for _, curBuff in buff.holder:queryBuffsWithGroup(buffGroupId):order_pairs() do
					buffLifeRound = type(buffRound) == "table" and buffRound[curBuff.cfgId] or buffRound
					curBuff.lifeRound = buffLifeRound
				end
			else
				local buffCfgId = buffTb[1]

				for _, targetBuff in buff.holder:iterBuffsWithCsvID(buffCfgId) do
					targetBuff.lifeRound = buffRound
				end
			end
		end
	end

	return true
end

function BuffEffectFuncTb.changeBuffLifeRound(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local buffRound = buff:cfg2Value(args[2])
		local type = args[3] or 0
		local buffKeyTb = {}

		for _, id in ipairs(args[1]) do
			buffKeyTb[id] = buffRound
		end

		local function flagRound(flags)
			for _, flag in ipairs(flags) do
				if buffKeyTb[flag] then
					return buffKeyTb[flag]
				end
			end

			return 0
		end

		local function getExtraRound(buffFlags, groupId, cfgId)
			local ret

			if type == 0 then
				ret = buffKeyTb[cfgId]
			elseif type == 1 then
				ret = buffKeyTb[groupId]
			elseif type == 2 then
				ret = flagRound(buffFlags)
			end

			return ret or 0
		end

		for _, curBuff in holder:iterBuffs() do
			local extraLifeRound = getExtraRound(curBuff:buffFlag(), curBuff:group(), curBuff.cfgId)

			curBuff.lifeRound = curBuff.lifeRound + extraLifeRound

			if curBuff.lifeRound <= 0 then
				curBuff:over()
			end
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.type = type
			old.getExtraRound = getExtraRound
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.mp1OverFlow(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local mpOverflow = math.max(buff.holder:mp1() - buff.holder:mp1Max(), 0)
		local mode = args[1]
		local overFlowMax = args[3]

		if mode == 1 then
			overFlowMax = args[2] * overFlowMax
		end

		holder.mp1Table[3] = cc.clampf(mpOverflow, 0, overFlowMax)

		local extraArgs = {
			affectNormalMpInCharge = false,
			changeMpOverflowInCharge = false,
			affectNormalMpFromBuff = false
		}
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

		if specialArgs then
			extraArgs.changeMpOverflowInCharge = battleEasy.ifElse(specialArgs.changeMpOverflowInCharge, specialArgs.changeMpOverflowInCharge, extraArgs.changeMpOverflowInCharge)
			extraArgs.affectNormalMpInCharge = battleEasy.ifElse(specialArgs.affectNormalMpInCharge, specialArgs.affectNormalMpInCharge, extraArgs.affectNormalMpInCharge)
			extraArgs.affectNormalMpFromBuff = battleEasy.ifElse(specialArgs.affectNormalMpFromBuff, specialArgs.affectNormalMpFromBuff, extraArgs.affectNormalMpFromBuff)
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = mode
			old.rate = args[2]
			old.limit = mode == 1 and args[2] * args[3] or args[3]
			old.cost = args[4]
			old.extraArgs = extraArgs
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.calDmgKeepDefence(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.args = args
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.kill(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local specialVal = buff.csvCfg.specialVal
		local buffDamageArgs = {
			isBeginDamageSeg = true,
			isLastDamageSeg = true,
			from = battle.DamageFrom.buff,
			hideHeadNumber = specialVal and specialVal[1],
			noDamageRecord = specialVal and specialVal[2]
		}
		local attackerCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local attacker = attackerCfg and buff:findTargetsByCfg(attackerCfg)[1] or buff.caster

		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			buffCfgId = buff.cfgId,
			attacker = attacker
		})
		holder:beAttack(attacker, math.ceil(holder:hp()), battle.JumpAllDamageProcessId, buffDamageArgs)
		buff:over()
	end
end

function BuffEffectFuncTb.counterAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.triggerSkillType2 = args[1]
			old.isWeightingType = type(args[1]) == "table"
			old.rate = args[2]
			old.find = functools.partial(buff.findTargetsByCfg, buff, buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1] or 1)
			old.costType = args[3] or 0
			old.mustEnemy = args[4] == 1
			old.cfgId = buff.cfgId
			old.extraSkill = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]

			if buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] == 0 then
				old.extraSkill = buff:cfg2Value(old.extraSkill)
				old.otherProcessBySkillID = old.extraSkill[1]
				old.extraSkill = nil
			end

			old.roundTriggerLimit = buff:cfg2Value(args[5])
			old.buffFlag = buff.csvCfg.buffFlag
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.comboAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.rate = args[1]
			old.roundTriggerLimit = args[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.cancelToAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.deductCd = args[1] == 1
			old.deductMp = args[2] == 1
			old.exAttackTakeEffect = args[3] == 1
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.syncAttack(buff, args, isOver)
	local holder = buff.holder
	local isSyncAttack = buff.csvCfg.easyEffectFunc == "syncAttack"

	local function checkFunc(checkSkillType2, skillType2)
		if checkSkillType2 then
			for k, v in ipairs(checkSkillType2) do
				if v == skillType2 then
					return true
				end
			end
		end

		return not checkSkillType2
	end

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.triggerSkillType2 = args[1]
			old.isWeightingType = type(args[1]) == "table"
			old.rate = args[2]
			old.isTrigger = functools.partial(checkFunc, buff.csvCfg.specialVal and buff.csvCfg.specialVal[1])
			old.otherProcessBySkillID = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
			old.find = functools.partial(buff.findTargetsByCfg, buff, buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1])
			old.costType = args[3] or 0
			old.isFixedForce = args[4] == 1 or false
			old.cfgId = buff.cfgId
			old.roundTriggerLimit = args[6]
			old.buffFlag = buff.csvCfg.buffFlag
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.assistAttack(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local target = targetCfg and buff:findTargetsByCfg(targetCfg)
		local data = {
			triggerSkillType2 = args[1],
			isWeightingType = type(args[1]) == "table",
			rate = args[2],
			costType = args[3] or 0,
			cfgId = buff.cfgId,
			id = buff.id,
			extraSkill = args[4],
			onlyHasTargetRun = args[5] == 1,
			roundTriggerLimit = args[6],
			confusionAttack = args[7] == 1,
			buffFlag = buff.csvCfg.buffFlag
		}

		if buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] == 0 then
			errorInWindows("buff:%d easyEffectFunc is assistAttack, specialVal[1] == 0", buff.cfgId)
		end

		holder:onAssistAttack(target and target[1], data)
	end
end

function BuffEffectFuncTb.inviteAttack(buff, args, isOver)
	return BuffEffectFuncTb.syncAttack(buff, args, isOver)
end

function BuffEffectFuncTb.protection(buff, args, isOver)
	local holder = buff.holder

	if buff.caster.id == buff.holder.id then
		return true
	end

	if not isOver then
		local protectObj = buff.caster

		if protectObj:isAlreadyDead() then
			buff:overClean()
		else
			holder:addOverlaySpecBuff(buff, function(old)
				old.type = args[1]
				old.ratio = args[2]
				old.priority = args[3] or 1000
				old.ignoreControl = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
				old.extraArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
				old.protector = buff.holder:setProtectObj(protectObj)

				function old.checkCondition(_self)
					local canTakeEffect = false

					if not buff.csvCfg.specialVal or not buff.csvCfg.specialVal[3] then
						canTakeEffect = true
					elseif _self.protector then
						buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
							protector = _self.protector
						})
						canTakeEffect = buff:cfg2Value(buff.csvCfg.specialVal[3])

						buff.protectedEnv:resetEnv()
					end

					return canTakeEffect
				end
			end, function(a, b)
				if a.priority == b.priority then
					return a.buff.id < b.buff.id
				else
					return a.priority > b.priority
				end
			end)
		end
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end
