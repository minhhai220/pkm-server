-- chunkname: @src.battle.models.buff.buff_effect2

local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

local function natureDamageAttr(buff, args, isOver)
	local natureType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
	local attrName = game.NATURE_TABLE[natureType]

	if not attrName then
		return
	end

	local funcName = buff.csvCfg.easyEffectFunc

	funcName = string.gsub(funcName, "nature", attrName)
	args = {
		{
			attr = funcName,
			val = args
		}
	}

	return BuffEffectFuncTb.addAttr(buff, args, isOver)
end

function BuffEffectFuncTb.secondAttack(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local target = targetCfg and buff:findTargetsByCfg(targetCfg)[1]

		holder:addOverlaySpecBuff(buff, function(old)
			old.skillId = args[1]
			old.needTarget = args[2] or 0
			old.target = target
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.natureDamageAdd(buff, args, isOver)
	return natureDamageAttr(buff, args, isOver)
end

function BuffEffectFuncTb.natureDamageSub(buff, args, isOver)
	return natureDamageAttr(buff, args, isOver)
end

function BuffEffectFuncTb.natureDamageDeepen(buff, args, isOver)
	return natureDamageAttr(buff, args, isOver)
end

function BuffEffectFuncTb.natureDamageReduce(buff, args, isOver)
	return natureDamageAttr(buff, args, isOver)
end

function BuffEffectFuncTb.pauseBuffEffect(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.buffCfgIDMap = arraytools.hash(args[1])
			old.buffGroupMap = arraytools.hash(args[2])
			old.buffFlagMap = arraytools.hash(args[3] or {})
			old.isBlacklist = args[4] == 1
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.pauseBuffLifeRound(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.buffCfgIDMap = arraytools.hash(args[1])
			old.buffGroupMap = arraytools.hash(args[2])
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.pausePassiveSkillEffect(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.skillCfgIDMap = arraytools.hash(args[1])
			old.isBlacklist = args[2] == 1
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.forceSneer(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local data = helper.adjustSkillType2Data({
			[battle.MainSkillType.SmallSkill] = false,
			[battle.MainSkillType.BigSkill] = false,
			[battle.MainSkillType.NormalSkill] = false
		}, buff.csvCfg.specialVal)
		local forceNumber = buff.scene.play.ForceNumber
		local areaType = args[1] or 0
		local leftSeat = (2 - holder.force) * forceNumber + (areaType == 2 and 4 or 1)
		local rigjtSeat = leftSeat + (areaType == 0 and forceNumber or forceNumber / 2)
		local sneerAreaSeatMap = {}

		for seat = leftSeat, rigjtSeat - 1 do
			sneerAreaSeatMap[seat] = true
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.extraArg = {
				spreadArg1 = args[2],
				spreadArg2 = args[3]
			}
			old.closeSkillType2 = data
			old.cantMoveSkill = args[4] == 1
			old.priority = args[5] or 100
			old.ignorePriority = args[6] or 10
			old.sneerAreaSeatMap = sneerAreaSeatMap

			function old.inSneerArea(obj)
				return old.sneerAreaSeatMap[obj.seat]
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

function BuffEffectFuncTb.controlEnemy(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local data = helper.adjustSkillType2Data({
			[battle.MainSkillType.SmallSkill] = false,
			[battle.MainSkillType.BigSkill] = false,
			[battle.MainSkillType.NormalSkill] = false
		}, buff.csvCfg.specialVal)

		holder:addOverlaySpecBuff(buff, function(old)
			old.triggerSkillType2 = args[1]
			old.isIgnoreConfusion = args[2] == 1
			old.ignoreConfusionGroups = arraytools.hash(args[3] or {})
			old.closeSkillType2 = data
			old.targetsFunc1 = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
			old.targetsFunc2 = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.addAttackRange(buff, args, isOver)
	local holder = buff.holder
	local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
	local targets = targetCfg and buff:findTargetsByCfg(targetCfg) or {}
	local filterFlags = args[1]

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.targets = targets
			old.filterFlags = arraytools.hash(filterFlags)
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

local function addBuffDoFormula(buff, data, cfgId)
	local buffCsv = csv.buff
	local newArgs = {}
	newArgs = clone(data)

	if data.fromProcess == 1 and buff.caster:getCurSkill() then
		local skill = buff.caster:getCurSkill()


		newArgs = BuffArgs.fromOtherSkill(skill, nil, buff.holder, newArgs, buffCsv[cfgId].easyEffectFunc)

		return newArgs
	end

	if data.fromProcess == 0 then
		newArgs = BuffArgs.fromOtherBuff(buff, newArgs, buffCsv[cfgId].easyEffectFunc)

		return newArgs
	end

	return nil
end

local function findBuff(loginfo, targetBuffId, buffs, targetBuffCfgIds, isFind, args, fromProcess, buffCfgIds, buffGroups, skillType, buff)
	if isFind == nil or buffCfgIds == nil or buffGroups == nil then
		if ANTI_AGENT then
			print("findBuff error buff info", loginfo.cfgId, dumps(loginfo.args))

			for _, obj in loginfo.holder.scene:ipairsHeros() do
				print("findBuff error unit info", obj.seat, obj.dbID, obj.unitID)
				print("findBuff error skill info", dumps(itertools.keys(obj.skills)))
				print("findBuff error passiveSkills info", dumps(itertools.keys(obj.passiveSkills)))
			end
		end

		return
	end

	if isFind[targetBuffId] then
		return
	end

	local buffCsv = csv.buff
	isFind[targetBuffId] = true

	local targetBuff = buffCsv[targetBuffId]

	if not targetBuff then
		errorInWindows("id(%s) not in csv.buff", targetBuffId)

		return
	end

	if buffCfgIds[targetBuffId] or buffGroups[targetBuff.group] then
		local newArgs = {}

		newArgs = clone(args)
		newArgs.timePoint = targetBuff.skillTimePos or 1
		newArgs.skillType = skillType
		newArgs.cfgId = newArgs.cfgId and newArgs.cfgId or targetBuffId
		newArgs.group = targetBuff.group
		newArgs.fromProcess = fromProcess and 1 or 0

		table.insert(targetBuffCfgIds, targetBuffId)

		buffs[targetBuffId] = newArgs
	end

	if targetBuff.triggerBehaviors then
		for _, triggerBehaviorsData in csvPairs(targetBuff.triggerBehaviors) do
			if type(triggerBehaviorsData) == "table" and triggerBehaviorsData.funcArgs then
				for _, funcArgsData in csvPairs(triggerBehaviorsData.funcArgs) do
					if funcArgsData[1] and type(funcArgsData[1].cfgId) == "number" then
						if funcArgsData[1].prob == 0 then
							break
						elseif type(funcArgsData[1].prob) == "string" and string.find(funcArgsData[1].prob, "0[%s]?or[%s]?0") then
							break
						end

						findBuff(loginfo, funcArgsData[1].cfgId, buffs, targetBuffCfgIds, isFind, funcArgsData[1], false, buffCfgIds, buffGroups, skillType, buff)
					end
				end
			end
		end
	end
end

local function commandeerIconEffect(holder, cfgIds, isOver)
	local buffCsv = csv.buff
	for cfgId, _ in pairs(cfgIds) do
		if not isOver then
			holder.view:proxy():onDealBuffEffectsMap(buffCsv[cfgId].iconResPath, "commandeer" .. cfgId, battle.iconBoxRes.commandeerBox)
			holder.view:proxy():onShowBuffIcon(buffCsv[cfgId].iconResPath, "commandeer" .. cfgId, 1)
		else
			holder.view:proxy():onDelBuffIcon("commandeer" .. cfgId)
		end
	end
end

function BuffEffectFuncTb.commandeer(buff, args, isOver)
	local holder = buff.holder
	local scene = buff.scene

	if not isOver then
		local unitID = holder.unitID
		local processCsv = csv.skill_process
		local buffCsv = csv.buff
		local holderSkillTb = battleEasy.getSkillTab(unitID)
		local targetSkillType = arraytools.hash(args[1])
		local buffCfgIds = arraytools.hash(args[2] or {})
		local buffGroups = arraytools.hash(args[3] or {})
		local numbers = args[4] or 0
		local isFind = {}
		local targetBuffs = {}
		local targetBuffCfgIds = {}
		local loginfo = {
			holder = holder,
			cfgId = buff.cfgId,
			args = args
		}

		for targetSkillId, skillType in pairs(holderSkillTb) do
			if targetSkillType[skillType] then
				local targetProcessTb = scene:getCfgSkillProcess(targetSkillId)

				for _, targetProcessId in ipairs(targetProcessTb) do
					local targetProcess = processCsv[targetProcessId]
					local buffTb = targetProcess.buffList

					for i, targetBuffId in csvPairs(buffTb) do
						local newArgs = {
							lifeRound = targetProcess.buffLifeRound[i],
							value = targetProcess.buffValue1[i],
							prob = targetProcess.buffProb[i],
							skillCfg = csv.skill[targetSkillId]
						}

						isFind = {}

						findBuff(loginfo, targetBuffId, targetBuffs, targetBuffCfgIds, isFind, newArgs, true, buffCfgIds, buffGroups, skillType, buff)
					end
				end
			end
		end

		local targetBuffCfgIdsorderList = {}

		if numbers > 0 then
			targetBuffCfgIds = random.sample(targetBuffCfgIds, numbers, ymrand.random)

			local ret = {}

			for _, cfgId in ipairs(targetBuffCfgIds) do
				ret[cfgId] = targetBuffs[cfgId]
			end

			targetBuffs = ret
		end

		for cfgId, data in pairs(targetBuffs) do
			table.insert(targetBuffCfgIdsorderList, cfgId)
		end

		table.sort(targetBuffCfgIdsorderList)

		for idx, cfgId in ipairs(targetBuffCfgIdsorderList) do
			local newData = {
				cfgId = cfgId,
				args = targetBuffs[cfgId]
			}

			buff.caster:addExRecord(battle.ExRecordEvent.commandeerAll, newData)
			buff.caster:addExRecord(battle.ExRecordEvent.commandeerCaster, newData, buff.cfgId)
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.targetBuffs = targetBuffs
		end)
	else
		if args[5] == 1 then
			buff.caster:cleanEventByKey(battle.ExRecordEvent.commandeerCaster, buff.buffCfgId)
		end

		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.applyCommandeer(buff, args, isOver)
	local holder = buff.holder
	local caster = buff.caster

	if not isOver then
		local function secondFilter(recordName, keys, conditions)
			local tb = {}

			if table.length(keys) == 0 then
				tb = caster:getEventByKey(battle.ExRecordEvent[recordName]) or {}
			else
				for _, key in ipairs(keys) do
					local temp = caster:getEventByKey(battle.ExRecordEvent[recordName], key) or {}

					for _, data in ipairs(temp) do
						table.insert(tb, data)
					end
				end
			end

			local tb2 = {}

			for _, data in ipairs(tb) do
				local temp = clone(data.args)

				temp = addBuffDoFormula(buff, temp, temp.cfgId)

				if temp and temp.prob ~= 0 or not temp then
					table.insert(tb2, data)
				end
			end

			local skillTypeCdt = arraytools.hash(conditions[1] or {})
			local buffCfgIdCdt = arraytools.hash(conditions[2] or {})
			local groupIdCdt = arraytools.hash(conditions[3] or {})
			local numberCdt = conditions[4] or 0
			local result = {}
			local isInsert = false

			if table.length(skillTypeCdt) > 0 then
				for _, data in ipairs(tb2) do
					local skllType = data.args.skillType

					if skillTypeCdt[skllType] then
						isInsert = true

						table.insert(result, data)
					end
				end
			end

			if table.length(buffCfgIdCdt) > 0 or table.length(groupIdCdt) > 0 then
				for _, data in ipairs(tb2) do
					local buffCfgId = data.args.cfgId
					local groupId = data.args.group

					if buffCfgIdCdt[buffCfgId] or groupIdCdt[groupId] then
						isInsert = true

						table.insert(result, data)
					end
				end
			end

			if not isInsert then
				result = clone(tb2)
			end

			if numberCdt > 0 then
				result = random.sample(result, numberCdt, ymrand.random)
			end

			return result
		end

		local applyToDo = {
			function(tb)
				local result = {}

				for _, data in ipairs(tb) do
					result[data.cfgId] = true
				end

				return result
			end,
			function(tb)
				local result = {}

				for _, data in ipairs(tb) do
					result[data.cfgId] = true
				end

				return result
			end,
			function(tb)
				local result = {}

				for _, data in ipairs(tb) do
					result[data.args.group] = true
				end

				return result
			end,
			function(tb, targets)
				for _, obj in ipairs(targets) do
					for _, data in ipairs(tb) do
						local cfgId = data.cfgId
						local newArgs = clone(data.args)

						newArgs = addBuffDoFormula(buff, newArgs, cfgId)

						if newArgs then
							addBuffToHero(cfgId, obj, buff.holder, newArgs)
						end
					end
				end
			end,
			function(tb, targets, timePoint)
				for _, obj in ipairs(targets) do
					for _, data in ipairs(tb) do
						local cfgId = data.cfgId
						local newArgs = clone(data.args)

						if newArgs.timePoint == timePoint then
							newArgs = addBuffDoFormula(buff, newArgs, cfgId)

							if newArgs then
								addBuffToHero(cfgId, obj, buff.holder, newArgs)
							end
						end
					end
				end
			end
		}
		local howToDo = args[1]
		local whereToGet = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local whatToGet = args[2]
		local filterConditions = args[3] or {}
		local targetCfg = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
		local targets = targetCfg and buff:findTargetsByCfg(targetCfg) or {}
		local filterThenTb = secondFilter(whereToGet, whatToGet, filterConditions)
		local hashTb = {}

		if howToDo <= 3 then
			hashTb = applyToDo[howToDo](filterThenTb)
		elseif howToDo == 4 then
			applyToDo[howToDo](filterThenTb, targets)
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.cfgIdHashTb = howToDo < 3 and hashTb or {}
			old.groupHashTb = howToDo == 3 and hashTb or {}
			old.howToDo = howToDo
			old.func = functools.partial(applyToDo[howToDo], filterThenTb, targets)
			old.finalTb = filterThenTb
			old.targets = targets

			if old.howToDo == 1 then
				commandeerIconEffect(holder, old.cfgIdHashTb, isOver)
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			if old.howToDo == 1 then
				commandeerIconEffect(holder, old.cfgIdHashTb, isOver)
			end
		end)
	end
end

function BuffEffectFuncTb.fieldBuff(buff, args, isOver)
	if not isOver then
		buff.fieldType = battle.FieldType.field

		local weatherOrFieldID = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]

		if weatherOrFieldID then
			local fieldCfg = csv.field_buff_relation[weatherOrFieldID]

			buff:addExRecord(battle.ExRecordEvent.fieldBuffRelation, fieldCfg)

			local type = fieldCfg.type

			buff.fieldType = type

			if type == battle.FieldType.weather then
				buff.holder:addExRecord(battle.ExRecordEvent.weatherLevels, fieldCfg.level)
				buff.scene.buffGlobalManager:setWeatherBuff(buff.holder.force, fieldCfg, buff)
			end

			if type == battle.FieldType.newField then
				buff.scene.fieldManager:addRelationCfg(buff, fieldCfg)
				buff.scene.fieldManager:dealEffectBuff(buff)
			end
		end
	elseif buff.fieldType == battle.FieldType.weather and buff.overType and buff.overType ~= battle.BuffOverType.restrain then
		buff.scene.buffGlobalManager:onWeatherOver(buff.holder.force, buff.scene, buff, {
			overType = buff.overType
		})
	end
end
