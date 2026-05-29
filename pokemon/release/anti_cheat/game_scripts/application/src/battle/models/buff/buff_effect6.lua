-- chunkname: @src.battle.models.buff.buff_effect6

local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

function BuffEffectFuncTb.buildScene(buff, args, isOver)
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

		assert(gFormulaConst, "gFormulaConst is nil")

		local groups = gFormulaConst.canattack() or {}
		local ignoreGroups = arraytools.hash(groups)
		local buffNames = args[4]
		local forbiddenBuffs = arraytools.hash(buffNames or {})
		local whiteList = args[5]
		local buffFlagMap = arraytools.hash(whiteList or {})
		local backStageStoreRound = args[6]
		local cfgID = buff.cfgId

		scene.specialRound:init(buff, {
			isSoloWithCaster = true,
			ignoreWithCaster = true,
			ignoreGroups = ignoreGroups,
			forbiddenBuffs = forbiddenBuffs,
			buffFlagMap = buffFlagMap,
			backStageStoreRound = backStageStoreRound,
			extraAttackArgsGet = function(obj)
				return ExtraAttackArgs.fromNormal(buff.id, cfgID, args[3])
			end
		}, {
			timeScale = buff.csvCfg.specialVal[1][1]
		})
		scene.specialRound:setRoundOverCondition(args[2][1], args[2][2], args[2][3])
		scene.specialRound:setSiteTargets(nil, buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1])
		scene.specialRound:setAttackRule(args[1])
	elseif lastInfo and lastInfo.buff.id == buff.id then
		lastInfo:resetState()
	end
end

function BuffEffectFuncTb.assimilateDamage(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		buff.value = math.floor(helper.argsCheck(buff.value, buff))

		holder:addOverlaySpecBuff(buff, function(old)
			if not old.assimilateDamageMaxTotal then
				old:setG("assimilateDamageMaxTotal", 0)
			end

			if not old.assimilateDamageTotal then
				old:setG("assimilateDamageTotal", 0)
			end

			local _assimilateDamageMax = old.assimilateDamageMax or 0
			local _assimilateDamage = old.assimilateDamage or 0

			old.assimilateDamageMax = buff.value
			old.assimilateDamage = buff.value
			old.assimilateDamageMaxTotal = old.assimilateDamageMaxTotal + old.assimilateDamageMax - _assimilateDamageMax
			old.assimilateDamageTotal = old.assimilateDamageTotal + old.assimilateDamage - _assimilateDamage
			old.priority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or 1000
		end, function(a, b)
			return a.priority > b.priority
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.assimilateDamageMaxTotal = old.assimilateDamageMaxTotal - old.assimilateDamageMax
			old.assimilateDamageTotal = old.assimilateDamageTotal - old.assimilateDamage
		end)
	end

	buff.holder:refreshAssimilateDamage()

	return true
end

function BuffEffectFuncTb.addNature(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if not old.natureTotal then
				old:setG("natureTotal", {})
			end

			old.natureTb = args[1]

			local natureHash = arraytools.hash(args[1])

			for _, data in ipairs(old.natureTotal) do
				if natureHash[data.nature] then
					natureHash[data.nature] = false
					data.ref = data.ref + 1
				end
			end

			for _, nature in ipairs(old.natureTb) do
				if natureHash[nature] then
					table.insert(old.natureTotal, {
						ref = 1,
						nature = nature
					})
				end
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			local natureHash = arraytools.hash(old.natureTb)

			for i = table.length(old.natureTotal), 1, -1 do
				local data = old.natureTotal[i]

				if natureHash[data.nature] then
					data.ref = data.ref - 1

					if data.ref == 0 then
						table.remove(old.natureTotal, i)
					end
				end
			end
		end)
	end

	return true
end

function BuffEffectFuncTb.editBuffPriority(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local buffName = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local cfgId = args[1]
		local priority = args[2]
		local sortFunc
		local noPriorityMark = false

		local function filter(data)
			if not data.priority then
				noPriorityMark = true

				return true
			end

			if data.cfgId == cfgId then
				return false
			end

			return true
		end

		local function defaultSort(a, b)
			if a.priority == b.priority then
				return a.buff.id < b.buff.id
			else
				return a.priority > b.priority
			end
		end

		if holder:checkOverlaySpecBuffExit(buffName) then
			for _, buffData in holder:ipairsOverlaySpecBuff(buffName, filter) do
				if not sortFunc and buffData.sortFunc then
					sortFunc = buffData.sortFunc
				end

				buffData.priority = priority or buffData.priority
			end

			if not noPriorityMark then
				sortFunc = sortFunc or defaultSort

				local buffData = holder:getOverlaySpecBuffInnerData(buffName)

				buffData:setG("sortFunc", sortFunc)
				holder:refreshOverlaySpecBuffOrder(buffName)
			end
		end
	end

	return true
end

function BuffEffectFuncTb.replaceExAttackSkill(buff, args, isOver)
	local holder = buff.holder
	local specialVal = buff.csvCfg.specialVal

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args[1] or 1
			old.priority = args[2] or 0
			old.processMode = args[3] or 1
			old.extraSkill = specialVal and specialVal[1]
			old.otherProcessBySkillID = specialVal and specialVal[2]
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			end

			return a.priority > b.priority
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.randomCastBuff(buff, args, isOver)
	if isOver then
		return true
	end

	local holder = buff.holder
	local caster = buff.caster
	local buffList = args[1]
	local randCnt = args[2]
	local lifeRounds = args[3]
	local oldArgs = buff.args
	local indexList = {}

	for index = 1, #buffList do
		if buffList[index] then
			table.insert(indexList, index)
		end
	end

	if #indexList == 0 then
		return
	end

	if randCnt < #indexList then
		for i = 1, #indexList - randCnt do
			local index = ymrand.random(1, #indexList)

			table.remove(indexList, index)
		end
	end

	for _, index in ipairs(indexList) do
		local cfgId = buffList[index]
		local castBuffCfg = csv.buff[cfgId]
		local buffArgs = BuffArgs.fromCastBuff(buff, {
			value = oldArgs.buffValueFormula
		}, lifeRounds[index], oldArgs.value, 1)

		addBuffToHero(cfgId, holder, caster, buffArgs)
	end
end

function BuffEffectFuncTb.freezeBuff(buff, args, isOver)
	local holder = buff.holder

	local function doFreezeBuff(buffData, curBuff)
		curBuff.isEffect = false

		table.insert(buffData.freezeBuffList, curBuff)

		buffData.freezeIDMap[curBuff.id] = true

		local freezeArgs = curBuff:getEventByKey(battle.ExRecordEvent.buffFreezeFlag)

		if freezeArgs then
			freezeArgs.num = freezeArgs.num + 1
		else
			freezeArgs = {
				num = 1,
				freezeLifeRound = buffData.freezeLifeRound
			}

			battleEasy.pushNotifyCantJump(curBuff.holder.view, "dealBuffIconBox", curBuff.id, false, curBuff.cfgId, "freezeBox", battle.iconBoxRes.freezeBox, false)

			if curBuff.buffEffectData then
				curBuff:doEffect(curBuff.csvCfg.easyEffectFunc, curBuff:getEffectValue(), true)
			end
		end

		curBuff:addExRecord(battle.ExRecordEvent.buffFreezeFlag, freezeArgs)
	end

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			local buffCfgIDMap = arraytools.hash(args[1][1])
			local buffGroupMap = arraytools.hash(args[1][2])
			local buffFlagMap = arraytools.hash(args[1][3])
			local filteIDMap = arraytools.hash(args[2][1])
			local filteGroupMap = arraytools.hash(args[2][2])
			local filteFlagMap = arraytools.hash(args[2][3])

			old.freezeLifeRound = args[3] == 0

			function old.buffFilter(buffData, id, cfgId, group, flags)
				if buffData.freezeOne then
					return id == buffData.freezeOne
				end

				return buffCfgIDMap[cfgId] and not filteIDMap[cfgId] or buffGroupMap[group] and not filteGroupMap[group] or battleEasy.intersection(buffFlagMap, flags, true) and not battleEasy.intersection(filteFlagMap, flags, true)
			end

			old.freezeBuffList = {}
			old.freezeIDMap = {}

			local checkBuffList = {}
			local priorityFlag = 0
			local isFreezeOne = args[4] == 1
			local freezeNums = args[5] or -1

			local function buffFilter(curBuff, filter)
				filter = filter or function()
					return true
				end

				if old:buffFilter(curBuff.id, curBuff.cfgId, curBuff:group(), curBuff:buffFlag()) and filter() then
					if isFreezeOne and not curBuff:getEventByKey(battle.ExRecordEvent.buffFreezeFlag) then
						table.insert(checkBuffList, 1, curBuff)

						priorityFlag = priorityFlag + 1
					else
						table.insert(checkBuffList, curBuff)
					end
				end
			end

			if isFreezeOne then
				for _, curBuff in holder.scene.allBuffs:order_pairs() do
					buffFilter(curBuff, function()
						buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
							tryFreezeBuff = curBuff
						})

						local result = buff:cfg2Value(buff.csvCfg.specialVal[1]) or true

						buff.protectedEnv:resetEnv()

						return result
					end)
				end

				if #checkBuffList > 1 then
					local index = 1

					if priorityFlag > 1 then
						index = ymrand.random(1, priorityFlag)
					elseif priorityFlag == 0 then
						index = ymrand.random(1, #checkBuffList)
					end

					old.freezeOne = checkBuffList[index].id
					checkBuffList = {
						checkBuffList[index]
					}
				end
			else
				for _, curBuff in holder:iterBuffs() do
					buffFilter(curBuff)
				end

				if freezeNums > 0 and freezeNums < #checkBuffList then
					local freezeList = random.sample(checkBuffList, freezeNums, ymrand.random)

					checkBuffList = freezeList
				end
			end

			for _, curBuff in ipairs(checkBuffList) do
				doFreezeBuff(old, curBuff)

				local bindArr = {}

				for id, _ in itertools.chain({
					curBuff.bondChildBuffsTb,
					curBuff.bondToOtherBuffsTb
				}) do
					table.insert(bindArr, id)
				end

				table.sort(bindArr)

				for _, buffId in ipairs(bindArr) do
					local bindBuff = holder.scene:getBuffByID(buffId)

					if bindBuff and not old.freezeIDMap[bindBuff.id] then
						doFreezeBuff(old, bindBuff)
					end
				end
			end

			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				result = table.length(old.freezeBuffList) > 0
			})
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.freezeBuff, "freezeEffect", function(buff)
			if buff:getEventByKey(battle.ExRecordEvent.buffFreezeFlag) then
				return true
			end

			for _, buffData in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freezeBuff) do
				if buffData:buffFilter(buff.id, buff.cfgId, buff:group(), buff:buffFlag()) then
					doFreezeBuff(buffData, buff)

					return true
				end
			end

			return false
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			for _, curBuff in ipairs(old.freezeBuffList) do
				if curBuff.isOver then
					return
				end

				local freezeArgs = curBuff:getEventByKey(battle.ExRecordEvent.buffFreezeFlag)

				if not freezeArgs then
					return
				end

				freezeArgs.num = freezeArgs.num - 1

				if freezeArgs.num > 0 then
					curBuff:addExRecord(battle.ExRecordEvent.buffFreezeFlag, freezeArgs)
				else
					curBuff:cleanEventByKey(battle.ExRecordEvent.buffFreezeFlag)

					curBuff.isEffect = true

					battleEasy.pushNotifyCantJump(curBuff.holder.view, "dealBuffIconBox", curBuff.id, false, curBuff.cfgId, "freezeBox", battle.iconBoxRes.freezeBox, true)

					curBuff.doEffectValue = clone(curBuff.value)

					if curBuff.buffEffectData then
						curBuff:doEffect(curBuff.csvCfg.easyEffectFunc, curBuff:getEffectValue() or 0, false)
					end
				end
			end
		end)
	end
end

function BuffEffectFuncTb.barrier(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			if not old.barrierTotal then
				old:setG("barrierTotal", 0)
			end

			if not old.opacity then
				old:setG("opacity", 255)
			end

			old.type = args[1]
			old.barrierValue = args[2]
			old.barrierTotal = old.barrierTotal + old.barrierValue
			old.priority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or 1000

			local tmpOpacity = math.floor(255 * (buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 1))

			old.opacity = math.max(old.opacity, tmpOpacity)
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.barrierTotal = old.barrierTotal - old.barrierValue
		end)
	end

	buff.holder:refreshBarrierHp()

	return true
end

function BuffEffectFuncTb.freezeHpMax(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			local freezeHpMax = math.floor(args[1])
			local hasFreezeHpMax = holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.freezeHpMax, "freezeHpMax") or 0

			if holder:hpMax() - hasFreezeHpMax - freezeHpMax < 1 then
				freezeHpMax = holder:hpMax() - hasFreezeHpMax - 1

				buff:setValue(freezeHpMax + old:overlayValue("getValue", "freezeHpmax"))
			end

			old:overlayValue("addValue", "freezeHpmax", freezeHpMax)

			local effectHpMax = -(hasFreezeHpMax + freezeHpMax)

			if holder:hpMax() + effectHpMax < holder:hp() then
				local effectHp = holder:hpMax() + effectHpMax - holder:hp()

				holder:addHp(effectHp, battle.AddHpFrom.freezeHpMax)
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.freezeHpMax, "freezeHpMax", function()
			local finalV = 0

			for _, buffData in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freezeHpMax) do
				finalV = finalV + buffData:overlayValue("getValue", "freezeHpmax")
			end

			return finalV
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old:overlayValue("clear")
		end)
	end
end

function BuffEffectFuncTb.addFreezeHpMaxValue(buff, args, isOver)
	if isOver then
		return
	end

	local holder = buff.holder
	local groups = arraytools.hash(args[1] or {})
	local value = args[2] or 0

	if value == 0 then
		return
	end

	local filteredDatas = {}

	for _, buffData in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freezeHpMax) do
		if itertools.isempty(groups) or groups[buffData.group] then
			table.insert(filteredDatas, buffData)
		end
	end

	if itertools.isempty(filteredDatas) then
		return
	end

	if value > 0 then
		local num = table.length(filteredDatas)
		local avg = math.floor(value / num)

		for _, buffData in ipairs(filteredDatas) do
			buffData:overlayValue("addValue", "freezeHpmax", avg)
		end
	else
		local defList = {}

		for _, buffData in ipairs(filteredDatas) do
			local dataValue = buffData:overlayValue("getValue", "freezeHpmax")
			local leftValue = value + dataValue
			local modifyValue = leftValue <= 0 and -dataValue or value

			buffData:overlayValue("addValue", "freezeHpmax", modifyValue)

			value = leftValue

			if value <= 0 then
				table.insert(defList, buffData)
			end

			if value >= 0 then
				break
			end
		end

		for _, buffData in ipairs(defList) do
			buffData.buff:over()
		end
	end

	holder:refreshLifeBar()

	return true
end

function BuffEffectFuncTb.doBuffDamageRandom(buff, args, isOver)
	if isOver then
		return
	end

	local filterGroup = arraytools.hash(args[1])
	local allLayers = args[2]
	local isBomb = args[3] == 1
	local isClear = args[4] == 1
	local triggerBuffList = {}

	for _, curBuff in buff.holder.buffs:order_pairs() do
		if filterGroup[curBuff:group()] then
			if curBuff.csvCfg.easyEffectFunc ~= "buffDamage" then
				errorInWindows("curBuff(%s)'s effect(%s) is not buffDamage", curBuff.cfgId, curBuff.csvCfg.easyEffectFunc)
			end

			if curBuff:getOverLayCount() > 1 and not curBuff:isCoexistType() then
				for i = 1, curBuff:getOverLayCount() do
					table.insert(triggerBuffList, curBuff)
				end
			else
				table.insert(triggerBuffList, curBuff)
			end
		end
	end

	triggerBuffList = random.sample(triggerBuffList, allLayers, ymrand.random)

	for _, curBuff in ipairs(triggerBuffList) do
		if not curBuff.isOver then
			local isCoexistType = curBuff:isCoexistType()
			local curOverlayCount = curBuff:getOverLayCount()
			local effectValue = curBuff:getValue()

			effectValue = isCoexistType and effectValue or effectValue / curOverlayCount

			local times = isBomb and curBuff:getLifeRound() or 1

			for i = 1, times do
				if not curBuff.isOver then
					BuffEffectFuncTb.buffDamage(curBuff, effectValue, false)
				end
			end

			if isBomb and isClear and not curBuff.isOver then
				if isCoexistType or curOverlayCount == 1 then
					curBuff:over({
						endType = battle.BuffOverType.clean
					})
				else
					curBuff:refresh({
						value = curBuff.args.value
					}, -1)
				end
			end
		end
	end
end

function BuffEffectFuncTb.alterRoundAttackInfo(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.isAutoAttack = args[1] == 1
			old.costType = args[2] or 0
			old.triggerSkillType2 = args[3]
			old.priority = args[4] or 10
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
end

function BuffEffectFuncTb.multiplyOverlays(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local times = math.floor(args[1] or 2)
		local cfgIds = arraytools.hash(args[2] or {})
		local groups = arraytools.hash(args[3] or {})
		local flags = arraytools.hash(args[4] or {})
		local searchNums = args[5] or 1

		if times <= 1 then
			return
		end

		local filterTypes = {
			[battle.BuffOverlayType.Overlay] = {},
			[battle.BuffOverlayType.Coexist] = {},
			[battle.BuffOverlayType.CoexistLifeRound] = {}
		}
		local orderByTimeLine = {
			[battle.BuffOverlayType.Overlay] = {},
			[battle.BuffOverlayType.Coexist] = {},
			[battle.BuffOverlayType.CoexistLifeRound] = {}
		}

		local function filter(_buff, overlayType, cfgId, curBuffNums)
			if not filterTypes[overlayType] then
				return false
			end

			if filterTypes[overlayType][cfgId] then
				return true
			end

			if curBuffNums >= searchNums then
				return false
			end

			if cfgIds[cfgId] then
				return true
			end

			if groups[_buff:group()] then
				return true
			end

			if battleEasy.intersection(flags, _buff:buffFlag(), true) then
				return true
			end

			return false
		end

		local overlayType, cfgId
		local curBuffNums = 0

		for _, _buff in holder:iterBuffs() do
			overlayType = _buff.overlayType
			cfgId = _buff.cfgId

			if filter(_buff, overlayType, cfgId, curBuffNums) then
				if not filterTypes[overlayType][cfgId] then
					curBuffNums = curBuffNums + 1

					table.insert(orderByTimeLine[overlayType], cfgId)

					filterTypes[overlayType][cfgId] = {}
				end

				table.insert(filterTypes[overlayType][cfgId], _buff)
			end
		end

		if next(filterTypes[battle.BuffOverlayType.Overlay]) then
			for _, _cfgId in ipairs(orderByTimeLine[battle.BuffOverlayType.Overlay]) do
				local tb = filterTypes[battle.BuffOverlayType.Overlay][_cfgId]
				local _buff = tb[1]
				local num = _buff:getOverLayCount() * (times - 1)
				local newArgs = BuffArgs.fromMultiplyOverlays(_buff)

				for i = 1, num do
					addBuffToHero(_buff.cfgId, _buff.holder, _buff.caster, newArgs)
				end
			end
		end

		local function addBuffByABC(buffTb)
			local num = times - 1

			for i = 1, num do
				for _, _buff in ipairs(buffTb) do
					local newArgs = BuffArgs.fromMultiplyOverlays(_buff)

					addBuffToHero(_buff.cfgId, _buff.holder, _buff.caster, newArgs)
				end
			end
		end

		if next(filterTypes[battle.BuffOverlayType.Coexist]) then
			for _, _cfgId in ipairs(orderByTimeLine[battle.BuffOverlayType.Coexist]) do
				addBuffByABC(filterTypes[battle.BuffOverlayType.Coexist][_cfgId])
			end
		end

		if next(filterTypes[battle.BuffOverlayType.CoexistLifeRound]) then
			for _, _cfgId in ipairs(orderByTimeLine[battle.BuffOverlayType.CoexistLifeRound]) do
				addBuffByABC(filterTypes[battle.BuffOverlayType.CoexistLifeRound][_cfgId])
			end
		end
	end

	return true
end

function BuffEffectFuncTb.dmgAdjustAllocateAndLink(buff, args, isOver)
	local holder = buff.holder
	local targetFormula = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.times = args[1] or 1
			old.priority = args[2] or 10

			function old.getTargetHash()
				local targets = targetFormula and buff:findTargetsByCfg(targetFormula) or {}
				local targetHash = {}

				for _, obj in ipairs(targets) do
					targetHash[obj.id] = true
				end

				return targetHash
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
end

function BuffEffectFuncTb.universalBar(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			local defaultPath = battle.universalBarRes.default

			old.curValFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
			old.curTotalFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
			old.totalFormula = buff.csvCfg.specialVal and buff.csvCfg.specialVal[3]
			old.resPath = buff.csvCfg.specialVal and buff.csvCfg.specialVal[4] or defaultPath
			old.time = buff.csvCfg.specialVal and buff.csvCfg.specialVal[5] or 0.8
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.universalBar, "calcValue", function(data)
			if not data.curValFormula or not data.curTotalFormula or not data.totalFormula then
				return 0, 0, 0
			end

			local curVal = buff:cfg2Value(data.curValFormula)
			local curTotal = buff:cfg2Value(data.curTotalFormula)
			local total = buff:cfg2Value(data.totalFormula)
			local time = data.time

			return curVal, curTotal, total, time
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	holder:refreshLifeBar()
end

function BuffEffectFuncTb.updateBuffLifeRound(buff, args, isOver)
	if isOver then
		return
	end

	local ids = args[1]
	local newLifeRound = args[2]
	local needOrigin = args[2] == -1
	local isGroup = args[3] == 1
	local numLimit = args[4]
	local buffCfgIds, buffCfgIdHash = {}, {}

	for _, id in ipairs(ids) do
		if numLimit and numLimit <= 0 then
			break
		end

		local hasBuff = false

		for _, curBuff in buff.holder:queryBuffsWithGroup(id):order_pairs() do
			if isGroup then
				hasBuff = true
				curBuff.lifeRound = needOrigin and curBuff.args.lifeRound or newLifeRound
			elseif not buffCfgIdHash[curBuff.cfgId] then
				buffCfgIdHash[curBuff.cfgId] = true

				table.insert(buffCfgIds, curBuff.cfgId)
			end
		end

		if numLimit and hasBuff then
			numLimit = numLimit - 1
		end
	end

	if not isGroup then
		local len = table.length(buffCfgIds)

		if numLimit then
			len = math.min(len, numLimit)
		end

		for i = 1, len do
			for _, targetBuff in buff.holder:iterBuffsWithCsvID(buffCfgIds[i]) do
				targetBuff.lifeRound = needOrigin and targetBuff.args.lifeRound or newLifeRound
			end
		end
	end

	return true
end

function BuffEffectFuncTb.lockHpShield(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		buff.value = math.floor(helper.argsCheck(buff.value, buff))

		holder:addOverlaySpecBuff(buff, function(old)
			if not old.shieldMaxTotal then
				old:setG("shieldMaxTotal", 0)
			end

			if not old.shieldTotal then
				old:setG("shieldTotal", 0)
			end

			local _shieldHpMax = old.shieldHpMax or 0
			local _shieldHp = old.shieldHp or 0

			old.shieldHpMax = buff.value
			old.shieldHp = buff.value
			old.shieldMaxTotal = old.shieldMaxTotal + old.shieldHpMax - _shieldHpMax
			old.shieldTotal = old.shieldTotal + old.shieldHp - _shieldHp
			old.priority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or 1000
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.lockHpShield, "costShield", function(value)
			local delBuffList = {}
			local gData = holder:getOverlaySpecBuffData(battle.OverlaySpecBuff.lockHpShield)

			for _, buffData in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.lockHpShield) do
				local shieldV = buffData.shieldHp

				if shieldV <= value then
					value = value - shieldV
					gData.shieldTotal = gData.shieldTotal - shieldV
					gData.shieldMaxTotal = gData.shieldMaxTotal - buffData.shieldHpMax
					buffData.shieldHp = 0
					buffData.shieldHpMax = 0

					table.insert(delBuffList, buffData.buff)
				else
					buffData.shieldHp = buffData.shieldHp - value
					gData.shieldTotal = gData.shieldTotal - value
					value = 0
				end
			end

			for _, buff in ipairs(delBuffList) do
				buff:over()
			end

			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				buffId = buff.id,
				easyEffectFunc = buff.csvCfg.easyEffectFunc,
				obj = buff.holder
			})

			return value
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.shieldMaxTotal = old.shieldMaxTotal - old.shieldHpMax
			old.shieldTotal = old.shieldTotal - old.shieldHp
		end)
	end

	return true
end

function BuffEffectFuncTb.registerBuffs(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local buffFilterMap = args[1]
		local recordBuffIds = {}
		local registedBuffInfos = {}

		local function filterBuffCheck(_buff)
			if _buff.isOver then
				return false
			end

			if _buff.id == buff.id then
				return false
			end

			if _buff.isAuraType then
				return false
			end

			if _buff.isFieldSubBuff then
				return false
			end

			if not battleEasy.BuffFilterTool.filter(buffFilterMap, _buff.cfgId, _buff:group(), _buff:buffFlag()) then
				return false
			end

			local fromBuffID = _buff.args.fromBuffID
			local fromBuff = holder.scene:getBuffByID(fromBuffID)

			if fromBuff then
				if fromBuff.csvCfg.easyEffectFunc == battle.OverlaySpecBuff.aura then
					recordBuffIds[_buff.id] = true

					return false
				end

				local isSameHolder = fromBuff.holder.id == holder.id

				if fromBuff:hasBondRelation(_buff.id) and (not isSameHolder or recordBuffIds[fromBuffID]) then
					recordBuffIds[_buff.id] = true

					return false
				end
			end

			return true
		end

		for _, curBuff in holder:iterBuffs() do
			if filterBuffCheck(curBuff) then
				local info = BuffArgs.fromRegisterBuff(curBuff)

				recordBuffIds[curBuff.id] = true

				table.insert(registedBuffInfos, info)
			end
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.registedBuffInfos = registedBuffInfos
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.applyRegistedBuffs(buff, args, isOver)
	if isOver then
		return
	end

	local holder = buff.holder
	local filterCfgIds = arraytools.hash(args[1] or {})

	for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.registerBuffs) do
		if filterCfgIds[data.cfgId] then
			for _, buffInfo in ipairs(data.registedBuffInfos) do
				local cfgId, _caster, _holder = buffInfo.cfgId, buffInfo.caster, buffInfo.holder
				local newArgs = BuffArgs.fromApplyRegisterBuff(buffInfo)

				addBuffToHero(cfgId, _holder, _caster, newArgs)
			end
		end
	end
end
