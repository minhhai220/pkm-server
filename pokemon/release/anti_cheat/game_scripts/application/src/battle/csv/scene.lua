local CsvScenetExport = {
	isSeatEmpty = 0,
	getForceNum = 0
}
local CsvScene = battleCsv.newCsvCls("CsvScene")

battleCsv.CsvScene = CsvScene

local FakeDeathGroup = 99999
local FakeDeathFlag = 99999

local function filterCheck(obj, force, includeFakeDeath)
	if obj.force ~= force then
		return false
	end

	if obj:isRealDeath() then
		return false
	end

	if obj:isFakeDeath() and not includeFakeDeath then
		return false
	end

	return true
end

local function filterByForce(scene, force, f, onSiteAll, includeFakeDeath)
	local pairsFunc = onSiteAll and scene.ipairsOnSiteHeros or scene.ipairsHeros

	for _, obj in pairsFunc(scene) do
		if filterCheck(obj, force, includeFakeDeath) then
			f(obj)
		end
	end
end

local function filterByForceWithNature(scene, force, f, includeFakeDeath)
	for _, obj in scene:ipairsNatureCountHeros() do
		if filterCheck(obj, force, includeFakeDeath) then
			f(obj)
		end
	end
end

local function filterBackByForce(scene, force, f)
	for _, obj in scene.backHeros:order_pairs() do
		if filterCheck(obj, force) then
			f(obj)
		end
	end
end

local function filterByExcludeBuffGroup(scene, force, groupList, f, onSiteAll)
	filterByForce(scene, force, function(obj)
		local func = f

		for _, group in ipairs(groupList) do
			if group == FakeDeathGroup and obj:isAlreadyDead() or obj:hasBuffGroup(group) then
				func = nil

				break
			end
		end

		if func then
			func(obj)
		end
	end, onSiteAll, true)
end

battleCsv.filterByExcludeBuffGroup = filterByExcludeBuffGroup

local function filterByExcludeBuffFlag(scene, force, flagList, f, onSiteAll)
	filterByForce(scene, force, function(obj)
		local func = f

		for _, flag in ipairs(flagList) do
			if flag == FakeDeathFlag and obj:isAlreadyDead() or obj:hasBuffFlag(flag) then
				func = nil

				break
			end
		end

		if func then
			func(obj)
		end
	end, onSiteAll, true)
end

battleCsv.filterByExcludeBuffFlag = filterByExcludeBuffFlag

function CsvScene:getObjInAttackerArrayId(seat, isInAllForce)
	local attackerArray = self.model.play.attackerArray
	local roundHasAttackedHistory = self.model.play.roundHasAttackedHistory
	local _obj = self.model:getObjectBySeat(seat)

	if not _obj then
		return 0
	end

	local force = _obj.force
	local forceIndex = 0
	local allIndex = 0
	local objFlag = {}

	for _, obj in ipairs(roundHasAttackedHistory) do
		if not objFlag[obj.id] then
			if obj.force == force then
				forceIndex = forceIndex + 1
			end

			allIndex = allIndex + 1
			objFlag[obj.id] = true
		end

		if obj.id == _obj.id then
			if isInAllForce == 1 then
				return allIndex
			elseif isInAllForce == 0 then
				return forceIndex
			end

			return
		end
	end

	for _, obj in ipairs(attackerArray) do
		if not objFlag[obj.id] then
			if obj.force == force then
				forceIndex = forceIndex + 1
			end

			allIndex = allIndex + 1
			objFlag[obj.id] = true
		end

		if obj.id == _obj.id then
			if isInAllForce == 1 then
				return allIndex
			elseif isInAllForce == 0 then
				return forceIndex
			end

			return
		end
	end

	return 0
end

function CsvScene:getGateType()
	return self.model.gateType
end

function CsvScene:extraBattleRoundMode()
	return self.model:getExtraBattleRoundMode()
end

function CsvScene:extraBattleRoundId()
	return self.model.play:getExtraBattleRoundData("buffCfgId") or 0
end

function CsvScene:countNatureTypeCount(force, nature1Switch, nature2Switch)
	local count = 0
	local recordMap = {}
	local nature1 = nature1Switch and 1 or nil
	local nature2 = nature2Switch and 2 or nil

	local function recordFunc(idx, obj)
		if idx then
			local nature = obj:getNatureType(idx)

			if nature and not recordMap[nature] then
				recordMap[nature] = true
				count = count + 1
			end
		end
	end

	filterByForceWithNature(self.model, force, function(obj)
		if nature1 ~= nil or nature2 ~= nil then
			recordFunc(nature1, obj)
			recordFunc(nature2, obj)
		else
			for _, nature in obj:ipairsNature() do
				if not recordMap[nature] then
					recordMap[nature] = true
					count = count + 1
				end
			end
		end
	end)

	return count
end

function CsvScene:countObjByBuffExGroup(force, buffCfgIDs, buffGroupIDs, ExBuffGroupIDs)
	local nofilterOver = false
	local count = 0

	filterByExcludeBuffGroup(self.model, force, ExBuffGroupIDs, function(obj)
		for _, buffCfgID in pairs(buffCfgIDs) do
			if obj:hasBuff(buffCfgID, noFilterOver) then
				count = count + 1

				return
			end
		end

		for _, buffGroupID in pairs(buffGroupIDs) do
			if obj:hasBuffGroup(buffGroupID, noFilterOver) then
				count = count + 1

				return
			end
		end
	end)

	return count
end

function CsvScene:countObjByBuffExFlag(force, buffCfgIDs, buffFlags, exBuffFlags)
	local nofilterOver = false
	local count = 0

	filterByExcludeBuffFlag(self.model, force, exBuffFlags, function(obj)
		for _, buffCfgID in pairs(buffCfgIDs) do
			if obj:hasBuff(buffCfgID, noFilterOver) then
				count = count + 1

				return
			end
		end

		for _, buffFlag in pairs(buffFlags) do
			if obj:hasBuffFlag(buffFlag, noFilterOver) then
				count = count + 1

				return
			end
		end
	end)

	return count
end

function CsvScene:countObjByBuff(force, buffCfgIDs, buffGroupIDs, filterOver)
	if type(buffCfgIDs) ~= "table" then
		buffCfgIDs = {
			buffCfgIDs
		}
	end

	if type(buffGroupIDs) ~= "table" then
		buffGroupIDs = {
			buffGroupIDs
		}
	end

	local count = 0
	local noFilterOver = not filterOver

	filterByForce(self.model, force, function(obj)
		for _, buffCfgID in pairs(buffCfgIDs) do
			if obj:hasBuff(buffCfgID, noFilterOver) then
				count = count + 1

				return
			end
		end

		for _, buffGroupID in pairs(buffGroupIDs) do
			if obj:hasBuffGroup(buffGroupID, noFilterOver) then
				count = count + 1

				return
			end
		end
	end)

	return count
end

function CsvScene:countObjByBuffFlag(force, buffCfgIDs, buffFlags, filterOver)
	if type(buffCfgIDs) ~= "table" then
		buffCfgIDs = {
			buffCfgIDs
		}
	end

	if type(buffFlags) ~= "table" then
		buffFlags = {
			buffFlags
		}
	end

	local count = 0
	local noFilterOver = not filterOver

	filterByForce(self.model, force, function(obj)
		for _, buffCfgID in pairs(buffCfgIDs) do
			if obj:hasBuff(buffCfgID, noFilterOver) then
				count = count + 1

				return
			end
		end

		for _, buffFlag in pairs(buffFlags) do
			if obj:hasBuffFlag(buffFlag, noFilterOver) then
				count = count + 1

				return
			end
		end
	end)

	return count
end

function CsvScene:countBackObjByBuffFlag(force, buffCfgIDs, buffFlags, filterOver)
	if type(buffCfgIDs) ~= "table" then
		buffCfgIDs = {
			buffCfgIDs
		}
	end

	if type(buffFlags) ~= "table" then
		buffFlags = {
			buffFlags
		}
	end

	local count = 0
	local noFilterOver = not filterOver

	filterBackByForce(self.model, force, function(obj)
		for _, buffCfgID in pairs(buffCfgIDs) do
			if obj:hasBuff(buffCfgID, noFilterOver) then
				count = count + 1

				return
			end
		end

		for _, buffFlag in pairs(buffFlags) do
			if obj:hasBuffFlag(buffFlag, noFilterOver) then
				count = count + 1

				return
			end
		end
	end)

	return count
end

function CsvScene:countObjByNature(force, natureIdx, nature)
	local count = 0

	filterByForceWithNature(self.model, force, function(obj)
		if obj:getNatureType(natureIdx or 1) == nature then
			count = count + 1
		end
	end)

	return count
end

function CsvScene:countObjByNatureExit(force, nature)
	local count = 0

	filterByForceWithNature(self.model, force, function(obj)
		for _, _nature in obj:ipairsNature() do
			if _nature == nature then
				count = count + 1

				break
			end
		end
	end)

	return count
end

function CsvScene:countForceNumExGroup(force, ExBuffGroupIDs)
	local count = 0

	filterByExcludeBuffGroup(self.model, force, ExBuffGroupIDs, function(obj)
		count = count + 1
	end)

	return count
end

function CsvScene:countForceNumExFlag(force, exBuffFlags)
	local count = 0

	filterByExcludeBuffFlag(self.model, force, exBuffFlags, function(obj)
		count = count + 1
	end)

	return count
end

function CsvScene:countForceNum(force)
	return self.model:getForceNum(force)
end

function CsvScene:countForceFilterNum(force, csvObj, ...)
	local tars = self.model:getFilterObjects(force, csvObj and {
		fromObj = csvObj.model
	}, ...)

	return table.length(tars)
end

function CsvScene:getMaxNatureInForce(force)
	local data = {
		nature = -1,
		count = 0
	}
	local countArray = {}

	filterByForceWithNature(self.model, force, function(obj)
		local nature = obj:getNatureType(1)

		countArray[nature] = countArray[nature] or 0
		countArray[nature] = countArray[nature] + 1

		if countArray[nature] > data.count or countArray[nature] == data.count and nature > data.nature then
			data.count = countArray[nature]
			data.nature = nature
		end
	end)

	return data.nature
end

function CsvScene:countObjByFlag(force, flag)
	local count = 0

	filterByForce(self.model, force, function(obj)
		if obj.battleFlag[flag] then
			count = count + 1
		end
	end)

	return count
end

function CsvScene:sumBuffOverlayByGroupInForce(force, groupList, ...)
	local sum = 0
	local buffIDs = {
		...
	}

	filterByExcludeBuffGroup(self.model, force, groupList, function(obj)
		for _, id in ipairs(buffIDs) do
			sum = sum + obj:getBuffGroupArgSum("overlayCount", id)
		end
	end)

	return sum
end

function CsvScene:sumBuffOverlayByGroupInForceAll(force, groupList, ...)
	local sum = 0
	local buffIDs = {
		...
	}

	filterByExcludeBuffGroup(self.model, force, groupList, function(obj)
		for _, id in ipairs(buffIDs) do
			sum = sum + obj:getBuffGroupArgSum("overlayCount", id)
		end
	end, true)

	return sum
end

function CsvScene:countHPSumByForce(force)
	local sum = 0

	filterByForce(self.model, force, function(obj)
		sum = sum + obj:hp()
	end)

	return sum
end

function CsvScene:countHPMaxSumByForce(force)
	local sum = 0

	filterByForce(self.model, force, function(obj)
		sum = sum + obj:hpMax()
	end)

	return sum
end

function CsvScene:countBuffAddBy(force, allWave, mode, keys)
	local curWave = self.model.play.curWave
	local st = allWave and 1 or curWave

	keys = keys or {}

	local eventKey = battle.ExRecordEvent.campBuffAddByCfgId

	if mode == 2 then
		eventKey = battle.ExRecordEvent.campBuffAddByGroup
	end

	if mode == 3 then
		eventKey = battle.ExRecordEvent.campBuffAddByFlag
	end

	local sum = 0

	for wave = st, curWave do
		for _, key in ipairs(keys) do
			sum = sum + (self.model.extraRecord:getEventByKey(eventKey, wave, force, key) or 0)
		end
	end

	return sum
end

function CsvScene:getNowWave()
	return self.model.play.curWave
end

function CsvScene:getNowRound()
	return self.model.play.curRound
end

function CsvScene:getNowBattleRound()
	return self.model.play.curBattleRound
end

function CsvScene:getSpecBuffSpecResult(force, buffType, cfgIds)
	local overlaySpecBuff = battle.OverlaySpecBuff

	local function getSpecBuffData(obj, cfgId, key)
		local ret = -1

		if obj:checkOverlaySpecBuffExit(buffType) then
			for _, data in obj:ipairsOverlaySpecBuff(buffType) do
				ret = data.cfgId == cfgId and data[key] or ret
			end
		end

		return ret
	end

	local buffTypeFunc = {
		[overlaySpecBuff.lockHp] = function(objs, ret)
			local wave = self.model.play.curWave
			local round = self.model.play:getTotalBattleTurnCurWave()
			local roundRes = wave .. "_" .. round

			for _, obj in ipairs(objs) do
				local res = false

				for _, cfgId in ipairs(cfgIds) do
					local tmpRes = getSpecBuffData(obj, cfgId, "lastTriggerRound") == roundRes

					res = res or tmpRes
				end

				ret = ret and res
			end

			return ret
		end
	}

	if not buffTypeFunc[buffType] then
		return false
	end

	local function filterObjCheck(obj)
		if obj:isRealDeath() then
			return false
		end

		if obj.force ~= force then
			return false
		end

		for _, cfgId in ipairs(cfgIds) do
			if obj:hasBuff(cfgId) then
				return true
			end
		end

		return false
	end

	local ret = false
	local objs = {}

	for _, obj in self.model:ipairsHeros() do
		if filterObjCheck(obj) then
			table.insert(objs, obj)

			ret = true
		end
	end

	ret = buffTypeFunc[buffType](objs, ret)

	return ret
end

function CsvScene:specialObjExit(force, objId)
	if self.model.forceRecordObject[force] then
		local obj = self.model.forceRecordObject[force][objId]

		if obj and not obj:isDeath() then
			return true
		end
	end

	return false
end

function CsvScene:getNextHero(filterRoundType)
	local obj

	if filterRoundType == 1 then
		obj = self.model.play.battleTurnInfoTb.nextAttackerHero
	elseif filterRoundType == 2 then
		obj = self.model.play.battleTurnInfoTb.nextHero
	else
		errorInWindows("getNextHero filterRoundType:%s", filterRoundType)
	end

	if obj then
		return battleCsv.CsvObject.newWithCache(obj)
	end

	return battleCsv.NilObject
end

local posMap = {
	left = {
		{
			y = 1,
			x = 2
		},
		{
			y = 2,
			x = 2
		},
		{
			y = 3,
			x = 2
		},
		{
			y = 1,
			x = 1
		},
		{
			y = 2,
			x = 1
		},
		{
			y = 3,
			x = 1
		}
	},
	right = {
		[7] = {
			y = 1,
			x = 1
		},
		[8] = {
			y = 2,
			x = 1
		},
		[9] = {
			y = 3,
			x = 1
		},
		[10] = {
			y = 1,
			x = 2
		},
		[11] = {
			y = 2,
			x = 2
		},
		[12] = {
			y = 3,
			x = 2
		}
	}
}
local pos = {
	left = {
		{
			4,
			5,
			6
		},
		{
			1,
			2,
			3
		}
	},
	right = {
		{
			7,
			8,
			9
		},
		{
			10,
			11,
			12
		}
	}
}
local NeighbourXY = {
	{
		0,
		1
	},
	{
		1,
		0
	},
	{
		0,
		-1
	},
	{
		-1,
		0
	}
}

function CsvScene:getObjNearCount(selectObj)
	local selectObj = selectObj.model
	local targets = self.model:getHerosMap(selectObj.force)
	local isLeft = selectObj.seat <= 6
	local positionMap = isLeft and posMap.left or posMap.right
	local position = isLeft and pos.left or pos.right
	local selfIdx = positionMap[selectObj.seat]
	local seatMap = {}

	for _, xy in ipairs(NeighbourXY) do
		local x = xy[1] + selfIdx.x
		local y = xy[2] + selfIdx.y

		if x > 0 and x <= 2 and y > 0 and y <= 3 then
			seatMap[position[x][y]] = true
		end
	end

	local count = 0

	filterByForce(self.model, selectObj.force, function(obj)
		if seatMap[obj.seat] then
			count = count + 1
		end
	end)

	return count
end

function CsvScene:getNatureCount(force, ...)
	local calNatureTypeTab = {
		...
	}
	local natures = {}
	local count = 0

	filterByForceWithNature(self.model, force, function(obj)
		if table.length(calNatureTypeTab) == 0 then
			for _, nature in obj:ipairsNature() do
				if not natures[nature] then
					count = count + 1
					natures[nature] = true
				end
			end
		else
			local typ

			for id, beCollect in ipairs(calNatureTypeTab) do
				if beCollect then
					typ = obj:getNatureType(id)

					if not natures[typ] then
						count = count + 1
						natures[typ] = true
					end
				end
			end
		end
	end, true)

	return count
end

function CsvScene:getSpellCountBySeatAndType(seat, skillType2)
	local obj = self.model:getObjectBySeat(seat)
	local key = obj and obj.id

	return self.model.extraRecord:getEventByKey(skillType2, key) or 0
end

function CsvScene:excutePlayCsv(func_name, ...)
	local gate = self.model.play
	local func = gate:excutePlayCsv(func_name)

	if not func then
		return
	end

	return func(...)
end

function CsvScene:getNowRoundInfo(paramName)
	local data = self.model.play.curHeroRoundInfo

	return data and data[paramName]
end

function CsvScene:getEnemyForce(csvObj)
	return csvObj:force() == 1 and 2 or 1
end

function CsvScene:getExtraRoundMode()
	return self.model.play.battleTurnInfoTb.extraRoundMode or 0
end

function CsvScene:getExtraRoundId()
	return self.model.play.battleTurnInfoTb.extraRoundId or 0
end

function CsvScene:checkExtraRoundBuffFlag(...)
	local extraRoundBuffFlag = self.model.play.battleTurnInfoTb.extraRoundBuffFlag

	if not extraRoundBuffFlag then
		return false
	end

	local buffFlags = {
		...
	}

	for idx, flag in pairs(buffFlags) do
		local checkResult = itertools.include(extraRoundBuffFlag, flag)

		if checkResult then
			return true
		end
	end

	return false
end

function CsvScene:getGroupObj(force, seat)
	local objectModel = self.model:getGroupObj(force, seat)

	if objectModel then
		return objectModel:getCsvObject()
	end

	return battleCsv.NilObject
end

function CsvScene:isLastBattleRound()
	return self.model.play:checkRoundEnd()
end

function CsvScene:forceSpellBigSkillTimes(force, natureList, includeExAttack)
	local cnt = 0
	local all = force == 3
	local natureHash = arraytools.hash(natureList)

	includeExAttack = includeExAttack == 1

	for _, obj in self.model:ipairsHeros() do
		if (all or obj.force == force) and (natureHash[obj.natureType] or natureHash[obj.natureType2]) then
			local allTimes = obj:getEventByKey(battle.MainSkillType.BigSkill) or 0
			local exAttackTimes = obj:getEventByKey(battle.ExRecordEvent.exAttackSpellBigSkill) or 0

			cnt = cnt + allTimes

			if not includeExAttack then
				cnt = cnt - exAttackTimes
			end
		end
	end

	return cnt
end

function CsvScene:isSoloFightType()
	return self.model.gateType == game.GATE_TYPE.craft or self.model.gateType == game.GATE_TYPE.crossCraft or self.model.gateType == game.GATE_TYPE.gym and self.model.play.deployType == game.DEPLOY_TYPE.OneByOneType
end

function CsvScene:isBrawlMode(brawlType, force)
	local lastInfo = self.model:getSpecialSceneInfo()
	local BrawlType = {
		Duel = 1,
		Brawl = 0
	}

	if brawlType == BrawlType.Brawl then
		brawlType = battle.ExtraAttackMode.brawl
	elseif brawlType == BrawlType.Duel then
		brawlType = battle.ExtraAttackMode.duel
	end

	if not lastInfo then
		return false
	end

	if lastInfo.data.mode == brawlType then
		if force and force > 0 then
			return lastInfo.buff.caster.force == force
		end

		return true
	end

	return false
end

function CsvScene:getAttrOfObjectWithBuff(force, cfgIds, attr, minOrMax)
	local objs = {}

	filterByForce(self.model, force, function(obj)
		for _, cfgId in ipairs(cfgIds) do
			if obj:hasBuff(cfgId) then
				table.insert(objs, obj)

				break
			end
		end
	end)

	local length = table.length(objs)

	if length == 0 then
		return 0
	end

	table.sort(objs, function(objA, objB)
		return objA[attr](objA) < objB[attr](objB)
	end)

	local idx = minOrMax == 1 and length or 1
	local obj = objs[idx]

	return obj[attr](obj)
end

function CsvScene:countObjBy(force, fromObj, inputs, output)
	local inputMap = {
		front = function(obj)
			return obj.seat >= 1 and obj.seat <= 3 or obj.seat >= 7 and obj.seat <= 9
		end,
		back = function(obj)
			return obj.seat >= 4 and obj.seat <= 6 or obj.seat >= 10 and obj.seat <= 12
		end,
		excludeRealDead = function(obj)
			return not obj:isRealDeath()
		end,
		filterLevevl1 = function(obj)
			if self.model:getFilterObject(obj.id, {
				fromObj = fromObj and fromObj.model
			}, battle.FilterObjectType.excludeObjLevel1) then
				return true
			end

			return false
		end
	}
	local outputMap = {
		allWithBuff = function(obj, data)
			return itertools.include(obj:iterBuffs(), function(buff)
				return buff.cfgId == data[2]
			end) and 1 or "returnZero"
		end
	}
	local count = 0

	for _, obj in self.model:getHerosMap(force):order_pairs() do
		local result = true

		for _, inputKey in ipairs(inputs) do
			result = result and inputMap[inputKey](obj)
		end

		result = (inputMap.excludeRealDead or not obj:isAlreadyDead()) and result

		if result then
			local switch = outputMap[output[1]] and outputMap[output[1]](obj, output) or 1

			if switch == "returnZero" then
				return 0
			elseif switch == "return" then
				return count
			else
				count = count + switch
			end
		end
	end

	return count
end

function CsvScene:countSuckMpByForce(force)
	local sum = 0
	local herosMap = self.model:getHerosMap(force)

	for _, hero in herosMap:order_pairs() do
		local mp = hero:getEventByKey(battle.ExRecordEvent.mpFromSuckMp) or 0

		sum = sum + mp
	end

	return sum
end

function CsvScene:getForceEmptySeatCount(force)
	return self.model:getForceEmptySeatCount(force)
end

local conditionFunc = {
	function(obj, cmp, value)
		cmp = cmp or value - 1

		if cmp < value then
			return true
		end

		return false
	end,
	function(obj, cmp, value)
		cmp = cmp or value + 1

		if value < cmp then
			return true
		end

		return false
	end
}

local function getAttrObjectFuncByCondi(attr, from)
	return function(self, force, ...)
		local value
		local funcTab = {}

		for _, v in ipairs({
			...
		}) do
			funcTab[table.length(funcTab) + 1] = conditionFunc[v]
		end

		for _, obj in self.model:getHerosMap(force):order_pairs() do
			local temp = obj.attrs[from][attr]

			for i, f in ipairs(funcTab) do
				if not f(obj, value, temp) then
					break
				end

				if i == table.length(funcTab) then
					value = temp
				end
			end
		end

		return value
	end
end

for attr, _ in pairs(ObjectAttrs.AttrsTable) do
	CsvScene["getB" .. attr] = getAttrObjectFuncByCondi(attr, "base")
	CsvScene["getA" .. attr] = getAttrObjectFuncByCondi(attr, "buff")
	CsvScene["get" .. attr] = getAttrObjectFuncByCondi(attr, "final")
end

battleCsv.exportToCsvCls(CsvScene, CsvScenetExport)
