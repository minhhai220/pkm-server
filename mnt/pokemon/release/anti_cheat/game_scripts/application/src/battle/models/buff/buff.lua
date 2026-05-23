local BuffModel = class("BuffModel")

globals.BuffModel = BuffModel
BuffModel.IDCounter = 0
BuffModel.ObjectSimpleBuffBuffCfgID = 0
BuffModel.ObjectSimpleBuffBuffGroup = 0

local buffOverTypeDesc = {
	[0] = "清理结束",
	"生命周期结束",
	"驱散",
	"叠加/覆盖",
	"天气克制",
	"高等级天气",
	"流程，例如换波，游戏结束"
}
local SpecBuff = {
	reborn = true,
	copyForceBuffsToOther = true,
	transferBuffToOther = true,
	copyCasterBuffsToHolder = true
}
local SpecialOnBuffTrigger = {
	keepHpUnChanged = true,
	lockHp = true
}
local ExtraAttackCheckPointsMap = {
	[battle.BuffTriggerPoint.onHolderBattleTurnStart] = true,
	[battle.BuffTriggerPoint.onHolderBattleTurnEnd] = true,
	[battle.BuffTriggerPoint.onHolderAttackBefore] = true,
	[battle.BuffTriggerPoint.onHolderAttackEnd] = true,
	[battle.BuffTriggerPoint.onHolderFinallyBeHit] = true,
	[battle.BuffTriggerPoint.onHolderBeforeBeHit] = true,
	[battle.BuffTriggerPoint.onHolderKillHandleChooseTarget] = true,
	[battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo] = true,
	[battle.BuffTriggerPoint.onHolderToAttack] = true,
	[battle.BuffTriggerPoint.onHolderBeForeSkillSpellTo] = true,
	[battle.BuffTriggerPoint.onHolderCalcDamageProb] = true
}
local IterAllPointsMap = {
	[battle.BuffTriggerPoint.onHolderBattleTurnStart] = true,
	[battle.BuffTriggerPoint.onHolderBattleTurnStartOther] = true,
	[battle.BuffTriggerPoint.onHolderBattleTurnEnd] = true,
	[battle.BuffTriggerPoint.onRoundStart] = true,
	[battle.BuffTriggerPoint.onRoundEnd] = true,
	[battle.BuffTriggerPoint.onBuffTrigger] = true
}

table.merge(IterAllPointsMap, ExtraAttackCheckPointsMap)

BuffModel.IterAllPointsMap = IterAllPointsMap

local GlobalPointsMap = {
	[battle.BuffTriggerPoint.onBuffTakeEffectSelf] = true
}

function BuffModel.BuffCmp(buff1, buff2)
	local tp1, tp2 = buff1.triggerPriority, buff2.triggerPriority

	if tp1 ~= tp2 then
		return tp1 < tp2
	end

	return buff1.id < buff2.id
end

local function getBuffCsvCfg(cfgId, caster, replaceCfg)
	local buffCfg = csv.buff[cfgId]
	local __supers = {}

	if replaceCfg then
		table.insert(__supers, replaceCfg)
	end

	if buffCfg.skinEffect and caster and buffCfg.skinEffect[caster.originUnitID] then
		local id = buffCfg.skinEffect[caster.originUnitID]
		local skinCfg = csv.skin_effect[id]

		table.insert(__supers, skinCfg)
	end

	local p = {}

	table.insert(__supers, buffCfg)

	function p.__index(t, k)
		for _, _t in ipairs(__supers) do
			local v = _t[k]

			if v ~= nil then
				return v
			end
		end

		return nil
	end

	function p.__newindex(t, k, v)
		error(string.format("buffCfg %s can not be write %s!", tostring(t), k))
	end

	return setmetatable(p, p)
end

function BuffModel:ctor(cfgId, holder, caster, args)
	BuffModel.IDCounter = BuffModel.IDCounter + 1
	self.id = BuffModel.IDCounter
	self.scene = holder.scene
	self.cfgId = cfgId
	self.csvCfg = getBuffCsvCfg(cfgId, caster, args.replaceBuffCfg)
	self.csvPower = csv.buff_group_power[self.csvCfg.groupPower]
	self.caster = caster
	self.holder = holder
	self.extraTargets = {
		[battle.BuffExtraTargetType.lastProcessTargets] = args.lastProcessTargets or {},
		[battle.BuffExtraTargetType.holderBeAttackFrom] = {},
		[battle.BuffExtraTargetType.overLayBuffCaster] = {},
		[battle.BuffExtraTargetType.segProcessTargets] = {}
	}
	self.startRound = 0
	self.nowRound = 0

	self:setStartRound()
	self:setNowRound()

	self.nowWave = self.scene.play.curWave
	self.args = args
	self.lifeRound = args.lifeRound
	self.source = args.source
	self.fromSkillLevel = args.skillLevel
	self.isInited = false
	self.isOver = false
	self.isEffect = false
	self.buffValue = nil
	self.value = nil
	self.doEffectValue = nil
	self.isNumberType = true
	self.triggerPriority = self.csvCfg.triggerPriority or 10
	self.isAuraType = args.isAuraType
	self.lifeRounds = {}
	self.overlayType = self.csvCfg.overlayType
	self.overlayCount = args.overlayCount or 1
	self.overlayLimit = battleEasy.getOverlayLimit(self.caster, self.holder, self.csvCfg)
	self.objThatTriggeringMeNow = nil
	self.objTriggerVec = CVector.new()
	self.triggerEnv = {}
	self.bondChildBuffsTb = {}
	self.bondToOtherBuffsTb = {}
	self.triggerAddAttrTb = {}
	self.buffEffectData = nil
	self.nodeManager = BuffNodeManager.new(self)
	self.exRecordNameTb = {}
	self.protectedEnv = battleCsv.makeProtectedEnv(self.caster, nil, self)
	self.castBuffEnvAdded = false
	self.castBuffGroupStack = CList.new()
	self.buffInitEnhanceVal = nil
	self.isShow = self.csvCfg.isShow
	self.isOnceEffectPlayed = not self.isShow
	self.isFieldBuff = self.csvCfg.easyEffectFunc == "fieldBuff"
	self.isFieldSubBuff = args.fieldSub
	self.gateLimit = self:cfg2Value(self.csvCfg.gateLimit)
	self.lastGroup = nil
	self.lastGroupRefresher = self.scene:getMaxReplaceGroupBuffId()

	self.lastGroupRefresher:setChangedCallback(function()
		self.lastGroup = nil
	end)

	if csvSize(self.csvCfg.dispelBuff) > 0 then
		local h = {}

		for _, cfgId in ipairs(self.csvCfg.dispelBuff) do
			h[cfgId] = true
		end

		self.dispelBuffHash = h
	end
end

function BuffModel:__delete()
	if self.lastGroupRefresher then
		self.lastGroupRefresher:destroy()
	end

	self.lifeRounds = nil
	self.bondChildBuffsTb = nil
	self.bondToOtherBuffsTb = nil
	self.triggerAddAttrTb = nil
	self.exRecordNameTb = nil
	self.nodeManager = nil
	self.csvObject = nil
	self.lastGroupRefresher = nil
	self.extraTargets = nil
	self.objTriggerVec = nil
	self.castBuffGroupStack = nil
	self.protectedEnv = nil
	self.triggerEnv = nil
	self.lastGroup = nil
	self.args = nil
end

function BuffModel:setStartRound()
	if self.csvCfg.lifeRoundType == battle.lifeRoundType.battleTurn then
		self.startRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos)
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.round then
		self.startRound = self.scene.play.totalRound
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.roundNormal then
		self.startRound = self.scene.play.totalRound
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.pureBattleTurn then
		self.startRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos, true)
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.battleTurnNormal then
		self.startRound = self.scene.play.totalRoundBattleTurn
	end
end

function BuffModel:setNowRound()
	if self.csvCfg.lifeRoundType == battle.lifeRoundType.battleTurn then
		self.nowRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos)
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.round then
		self.nowRound = self.scene.play.totalRound
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.roundNormal then
		self.nowRound = self.scene.play.totalRound
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.pureBattleTurn then
		self.nowRound = self.holder:getBattleRoundAllWave(self.csvCfg.skillTimePos, true)
	elseif self.csvCfg.lifeRoundType == battle.lifeRoundType.battleTurnNormal then
		self.nowRound = self.scene.play.totalRoundBattleTurn
	end
end

function BuffModel:checkCanDispelBuff(buff)
	local holder = buff.holder

	for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.cantDispelBuffRound) do
		local buffGroupTb = data.buffGroupTb
		local buffRound = data.buffRound

		if buffGroupTb[buff:group()] then
			local curRound = self.nowRound

			buff.cantDispelBuffRound = {
				curRound,
				buffRound
			}
		end
	end

	if buff.cantDispelBuffRound and next(buff.cantDispelBuffRound) then
		local startRound = buff.cantDispelBuffRound[1]
		local continueRound = buff.cantDispelBuffRound[2]

		if self.nowRound < startRound + continueRound then
			return false
		else
			buff.cantDispelBuffRound = nil
		end
	end

	return true
end

function BuffModel:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)
	if table.length(tobeDispeledBuffs) > 0 then
		table.sort(tobeDispeledBuffs, function(a, b)
			return a.id < b.id
		end)

		local dispelType = self.csvCfg.dispelType[1] or 0
		local dispelAll = self.csvCfg.dispelType[3] or 0
		local dispelCounter = self.csvCfg.dispelType[4] or 1
		local overType = self.csvCfg.dispelType[6] or battle.BuffOverType.dispel

		if dispelType ~= 3 then
			for _, buff in ipairs(tobeDispeledBuffs) do
				if self:checkCanDispelBuff(buff) then
					self:addExRecord(battle.ExRecordEvent.dispelBuffCount, 1)

					if dispelAll > 0 or self.holder:needDispelTimes(buff, dispelCounter) <= 0 then
						log.battle.buff.dispel({
							dispelBuff = self,
							beDispelBuff = buff
						})
						self:triggerByMoment(battle.BuffTriggerPoint.onBuffDispel, {
							buffCfgId = buff.cfgId,
							obj = buff.holder
						})
						buff:beDispel(dispelAll == 0, overType, self)
					end
				end
			end
		else
			local allBuffs = {}
			local id2Buff = {}

			for _, buff in ipairs(tobeDispeledBuffs) do
				if buff:isCoexistType() then
					for _, sameCfgBuff in buff.holder:iterBuffsWithCsvID(buff.cfgId) do
						table.insert(allBuffs, sameCfgBuff.id)

						id2Buff[sameCfgBuff.id] = sameCfgBuff
					end
				elseif buff:isOverlayCountType() then
					for i = 1, buff.overlayCount do
						table.insert(allBuffs, buff.id)
					end

					id2Buff[buff.id] = buff
				else
					table.insert(allBuffs, buff.id)

					id2Buff[buff.id] = buff
				end
			end

			local buffIdTb, needOver

			if dispelAll > 0 and dispelAll < table.length(allBuffs) then
				buffIdTb = random.sample(allBuffs, dispelAll, ymrand.random)
				needOver = false
			else
				buffIdTb = allBuffs
				needOver = true
			end

			local type5Dispeled = {}

			local function dispelProcess(tBuff, needOver)
				if self:checkCanDispelBuff(tBuff) then
					self:addExRecord(battle.ExRecordEvent.dispelBuffCount, 1)

					if self.holder:needDispelTimes(tBuff, dispelCounter) <= 0 then
						log.battle.buff.dispel({
							dispelBuff = self,
							beDispelBuff = tBuff
						})
						self:triggerByMoment(battle.BuffTriggerPoint.onBuffDispel, {
							buffCfgId = tBuff.cfgId,
							obj = tBuff.holder
						})
						tBuff:beDispel(needOver, overType, self)

						if tBuff.overlayType == battle.BuffOverlayType.IndeLifeRound then
							table.insert(type5Dispeled, tBuff)
						end
					end
				end
			end

			for _, id in ipairs(buffIdTb) do
				dispelProcess(id2Buff[id], needOver)
			end

			for _, buff in ipairs(type5Dispeled) do
				if not buff.isOver then
					buff:refreshLerpValue(true)

					if buff.isShow then
						local aniArgs = buff:getBuffEffectAniArgs()

						battleEasy.pushNotifyCantJump(buff.holder.view, "playBuffAniEffect", buff.id, false, aniArgs)
					end
				end
			end
		end

		self:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger)

		hasDispelBuff = true
		tobeDispeledBuffs = {}
	end

	return hasDispelBuff, tobeDispeledBuffs
end

function BuffModel:isOverlayCountType()
	return self.overlayType == battle.BuffOverlayType.Overlay or self.overlayType == battle.BuffOverlayType.IndeLifeRound or self.overlayType == battle.BuffOverlayType.OverlayDrop
end

function BuffModel:setDispeledBuffs(tobeDispeledBuffs, groupRelation, filter)
	local array = self.csvCfg.dispelType
	local dispelType = array[1] or 0
	local dispelNum = array[2] or 0
	local dispelType, dispelNum, dispelAll = dispelType, dispelNum, array[3] or 0
	local dispeledBuffs = {}
	local priorityOrder = {}
	local priorityNum = {}
	local CoexistCfgIds = {}

	local function addBuffToTable(_buff, _priority)
		if not dispeledBuffs[_priority] then
			dispeledBuffs[_priority] = CMap.new(function(buff1, buff2)
				return buff1.id < buff2.id
			end)

			table.insert(priorityOrder, _priority)
		end

		priorityNum[_priority] = priorityNum[_priority] + 1

		dispeledBuffs[_priority]:insert(_buff.id, _buff)
	end

	local function deleteCheck(_priority)
		local isDelete = false

		if dispelNum >= priorityNum[_priority] then
			isDelete = true
		elseif dispelNum > 0 then
			local rate = ymrand.random(0, 1)

			if rate == 1 then
				isDelete = true
			end
		end

		priorityNum[_priority] = priorityNum[_priority] - 1

		if isDelete then
			dispelNum = dispelNum - 1
		end

		return isDelete
	end

	if dispelType ~= nil then
		if dispelType == 2 then
			function addBuffToTable(_buff, _priority)
				if not dispeledBuffs[_priority] then
					dispeledBuffs[_priority] = CMap.new()

					table.insert(priorityOrder, _priority)
				end

				local holderBuffGroup = _buff:group()

				if not dispeledBuffs[_priority]:find(holderBuffGroup) then
					dispeledBuffs[_priority]:insert(holderBuffGroup, CMap.new())

					priorityNum[_priority] = priorityNum[_priority] + 1
				end

				dispeledBuffs[_priority]:find(holderBuffGroup):insert(_buff.id, _buff)
			end
		elseif dispelType == 3 then
			function addBuffToTable(_buff, _priority)
				if not dispeledBuffs[_priority] then
					dispeledBuffs[_priority] = CMap.new(function(buff1, buff2)
						return buff1.id < buff2.id
					end)

					table.insert(priorityOrder, _priority)
				end

				if _buff:isCoexistType() then
					if not CoexistCfgIds[_buff.cfgId] then
						priorityNum[_priority] = priorityNum[_priority] + 1

						dispeledBuffs[_priority]:insert(_buff.id, _buff)

						CoexistCfgIds[_buff.cfgId] = _buff
					end
				else
					priorityNum[_priority] = priorityNum[_priority] + 1

					dispeledBuffs[_priority]:insert(_buff.id, _buff)
				end
			end

			if dispelNum == 0 then
				function deleteCheck(_priority)
					return true
				end
			end
		elseif dispelType == 0 then
			function deleteCheck(_priority)
				return true
			end
		end
	end

	local targets = self.csvCfg.specialTarget and self.csvCfg.specialTarget[1] and self:findTargetsByCfg(self.csvCfg.specialTarget[1]) or {
		self.holder
	}

	for _, holder in ipairs(targets) do
		for priority, dispelGroups in ipairs(groupRelation.dispelGroup) do
			itertools.each(dispelGroups, function(dispelGroup, _)
				for _, holderBuff in holder:queryBuffsWithGroup(dispelGroup):order_pairs() do
					if filter(holderBuff) and self:checkDispelPower(holderBuff) and holderBuff.id ~= self.id then
						priorityNum[priority] = priorityNum[priority] or 0

						addBuffToTable(holderBuff, priority)
					end
				end
			end)
		end

		for priority, dispelFlags in ipairs(groupRelation.dispelFlag) do
			for _, buff in holder.buffs:order_pairs() do
				if battleEasy.intersection(dispelFlags, buff.csvCfg.buffFlag, true) and filter(buff) and self:checkDispelPower(buff) and buff.id ~= self.id then
					priorityNum[priority] = priorityNum[priority] or 0

					addBuffToTable(buff, priority)
				end
			end
		end
	end

	local dispelBuffsMap = {}

	local function addDispleBuff(buff)
		if not dispelBuffsMap[buff.cfgId] then
			dispelBuffsMap[buff.cfgId] = 0
		end

		dispelBuffsMap[buff.cfgId] = dispelBuffsMap[buff.cfgId] + 1

		if dispelAll == 0 or dispelAll > 0 and dispelBuffsMap[buff.cfgId] <= dispelAll then
			table.insert(tobeDispeledBuffs, buff)
		end
	end

	table.sort(priorityOrder)

	for _, priority in ipairs(priorityOrder) do
		local data = dispeledBuffs[priority]

		if data then
			for _, _buffData in data:order_pairs() do
				if deleteCheck(priority) then
					if dispelType and dispelType == 2 then
						for _, _buff in _buffData:order_pairs() do
							addDispleBuff(_buff)
						end
					elseif dispelType and dispelType == 3 then
						table.insert(tobeDispeledBuffs, _buffData)
					else
						addDispleBuff(_buffData)
					end
				end
			end
		end
	end
end

function BuffModel:dispelGroupBuff(filter)
	if not self.isInited then
		return
	end

	filter = filter or function()
		return true
	end
	self.dispelCount = 0

	local dispelBuff = self.csvCfg.dispelBuff
	local dispelCount = dispelBuff[2]
	local tobeDispeledBuffs = {}
	local hasDispelBuff = false
	local groupRelation = gBuffGroupRelationCsv[self:group()]
	local dispelBuffHash = self.dispelBuffHash

	if dispelBuffHash then
		local count = 0

		for _, holderBuff in self.holder:iterBuffs() do
			if filter(holderBuff) and self:checkDispelPower(holderBuff) and holderBuff.id ~= self.id and dispelBuffHash[holderBuff.cfgId] and (not dispelCount or dispelCount and count < dispelCount) then
				table.insert(tobeDispeledBuffs, holderBuff)

				if dispelCount then
					count = count + 1
				end
			end
		end
	end

	hasDispelBuff, tobeDispeledBuffs = self:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)

	if self:group() ~= 0 and groupRelation and groupRelation.dispelGroup then
		self:setDispeledBuffs(tobeDispeledBuffs, groupRelation, filter)
	end

	hasDispelBuff, tobeDispeledBuffs = self:getTobeDispeledBuffs(hasDispelBuff, tobeDispeledBuffs)

	if hasDispelBuff and self.caster and not self.caster:isDeath() then
		self.caster:addExRecord(battle.ExRecordEvent.dispelSuccessCount, 1)
		self:addExRecord(battle.ExRecordEvent.dispelSuccess, true)
	end

	return hasDispelBuff
end

function BuffModel:checkDispelPower(toBeDispeledBuff)
	local selfPowerPriority = self.csvCfg.dispelType[7] or 10

	return selfPowerPriority <= toBeDispeledBuff.csvPower.beDispel
end

function BuffModel:initTriggerEvents()
	for triggerPoint, _ in pairs(self.nodeManager.points) do
		if not IterAllPointsMap[triggerPoint] then
			if GlobalPointsMap[triggerPoint] then
				self:subscribeEvent(self.scene, triggerPoint, "onTriggerGlobalEvent")
			else
				self:subscribeEvent(self.holder, triggerPoint, "onTriggerEvent")
			end
		end
	end
end

function BuffModel:init()
	if self.isOver then
		return
	end

	if self.isInited then
		return
	end

	if self.holder:isRealDeath() then
		return
	end

	self.isInited = true

	self.scene:checkCowWithBuff(self)
	log.battle.buff.init({
		buff = self,
		caster = self.caster,
		holder = self.holder
	})

	self.buffValue = clone(self:cfg2Value(self.args.value))
	self.isNumberType = type(self.buffValue) == "number"

	if self.isNumberType then
		self.buffInitEnhanceVal = self.holder:getBuffEnhance(self:group(), 1)
	end

	self:setValue(self.buffValue)
	battleComponents.bind(self, "Event")
	self.nodeManager:init(self.csvCfg.triggerBehaviors)
	self:initTriggerEvents()

	if self:isCoexistType() then
		if not self.holder.buffOverlayCount[self.cfgId] then
			self.holder.buffOverlayCount[self.cfgId] = 0
		end

		self.holder.buffOverlayCount[self.cfgId] = self.holder.buffOverlayCount[self.cfgId] > 0 and self.holder.buffOverlayCount[self.cfgId] or 1
	end

	log.battle.buff.overlay({
		buff = self
	})
	self.holder:onBuffImmuneChange(self)
	tjprofiler.tBegin("buffInitDispelGroupBuff", self.cfgId)

	local filterType = self.csvCfg.dispelType[5] or 1
	local showDispelEffect

	if filterType == 2 or filterType == 3 then
		local buffIds = self.holder:getEventByKey(battle.ExRecordEvent.skillAddBuffIds) or {}

		showDispelEffect = self:dispelGroupBuff(function(buff)
			return buffIds[buff.id]
		end)
	end

	if not showDispelEffect and (filterType == 1 or filterType == 3) then
		showDispelEffect = self:dispelGroupBuff()
	end

	tjprofiler.tEnd("buffInitDispelGroupBuff", self.cfgId, 1)

	if self.scene:isCraftGateType() then
		if not self.scene.play.craftBuffAddTimes[self.cfgId] then
			self.scene.play.craftBuffAddTimes[self.cfgId] = {
				0,
				0
			}
		end

		self.scene.play.craftBuffAddTimes[self.cfgId][self.holder.force] = self.scene.play.craftBuffAddTimes[self.cfgId][self.holder.force] + 1
	end

	tjprofiler.tBegin("buffInitTrigger", self.cfgId)
	self:triggerByMoment(battle.BuffTriggerPoint.onBuffCreate)

	if self.isFieldBuff then
		self.scene:tirggerFieldBuffs(nil, self)
	end

	tjprofiler.tEnd("buffInitTrigger", self.cfgId, 1)

	if self.isShow and self.isOver == false then
		local aniArgs = self:getBuffEffectAniArgs()

		aniArgs.isAdd = true
		aniArgs.dispel = showDispelEffect
		aniArgs.justRefresh = false

		battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", self.id, false, aniArgs)

		if self.csvCfg.buffshader and csvSize(self.csvCfg.buffshader) > 0 then
			battleEasy.deferNotifyCantJump(self.holder.view, "playBuffShader", {
				buffshader = self.csvCfg.buffshader,
				buffId = self.cfgId
			})
		end

		if self.csvCfg.stageArgs then
			local stageArgs = self.csvCfg.stageArgs

			self.scene:recordSceneAlterBuff(self.id, self.cfgId, stageArgs)

			local bkCsv = getCsv(stageArgs[1].bkCsv)

			battleEasy.deferNotifyCantJump(self.holder.view, "alterBattleScene", {
				restore = false,
				buffId = self.id,
				aniName = bkCsv[1].aniName,
				resPath = bkCsv[1].res,
				x = bkCsv[1].x,
				y = bkCsv[1].y,
				delay = stageArgs[1].delay
			})
		end

		if self.weatherCfgId then
			battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
		end
	end
end

function BuffModel:setDelSelfWhen2()
	self.hadDelSelfWhen2 = 2

	self.scene.allBuffs:update_index("delSelfWhenTriggered", self.id)
end

assert(ObjectAttrs.AttrsTable, "attrs require order error")

local ImmediateFormulaKeys = {}

for k, _ in pairs(ObjectAttrs.AttrsTable) do
	ImmediateFormulaKeys[k] = true
end

ImmediateFormulaKeys.lastMp1 = true

function BuffModel.cfg2ValueWithEnv(sOrT, env, castBuffEnvAdded)
	if not sOrT then
		return
	end

	if type(sOrT) == "table" then
		if sOrT.__spstructure then
			return sOrT
		end

		local ret = {}

		for k, v in csvMapPairs(sOrT) do
			if k == "input" or k == "process" then
				ret[k] = v
			else
				ret[k] = BuffModel.cfg2ValueWithEnv(v, env, castBuffEnvAdded)
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
		if ANTI_AGENT then
			print("cfg2ValueWithEnv sOrT is boolean", env.buffCfgID)
		end

		return sOrT
	end

	if not castBuffEnvAdded and (string.find(sOrT, "target2") or string.find(sOrT, "self2")) then
		return sOrT
	end

	return battleCsv.doFormula(sOrT, env)
end

function BuffModel:cfg2ValueWithTrigger(sOrT)
	self.protectedEnv = battleCsv.fillFuncEnv(self.protectedEnv, {
		trigger = self.triggerEnv
	})

	local value = self:cfg2Value(sOrT)

	self.protectedEnv:resetEnv()

	return value
end

function BuffModel:cfg2Value(sOrT)
	return self.cfg2ValueWithEnv(sOrT, self.protectedEnv, self.castBuffEnvAdded)
end

function BuffModel:overClean(params)
	params = params or {}
	params.endType = battle.BuffOverType.clean

	self:over(params)
end

function BuffModel:overBuffsInTable(tb, params)
	if itertools.isempty(tb) then
		return
	end

	local arr = {}

	for id, _ in pairs(tb) do
		table.insert(arr, id)
	end

	table.sort(arr)

	for _, buffId in ipairs(arr) do
		local buff = self.scene:getBuffByID(buffId)

		if buff then
			buff:over(params)
		end
	end

	table.clear(tb)
end

function BuffModel:addDelayBuff(easyEffectFunc)
	if easyEffectFunc == "delayBuff" then
		for _, data in self.holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.delayBuff) do
			if data.buff.id == self.id then
				for _, delayData in ipairs(data.needDelayBuffTb) do
					addBuffToHero(delayData.cfgId, delayData.holder, delayData.caster, delayData.args)
				end

				break
			end
		end
	end
end

function BuffModel:getEffectValue()
	return self.doEffectValue or 0
end

function BuffModel:over(params)
	if self.isOver then
		return
	end

	self.isOver = true

	self:addDelayBuff(self.csvCfg.easyEffectFunc)

	params = params or {}
	params.endType = params.endType or battle.BuffOverType.normal

	lazylog.battle.buff.over({
		buff = self,
		params = params,
		endType = buffOverTypeDesc[params.endType],
		traceInfo = battleEasy.logTraceInfo(5)
	})

	if self.csvCfg.easyEffectFunc and self.isEffect then
		self.overType = params.endType

		self:doEffect(self.csvCfg.easyEffectFunc, self:getEffectValue(), true)
	end

	if self:isCoexistType() then
		self.holder.buffOverlayCount[self.cfgId] = self.holder.buffOverlayCount[self.cfgId] - 1
	end

	if params.endType ~= battle.BuffOverType.clean then
		self:triggerOnOver(params)
	end

	self:overBuffsInTable(self.bondChildBuffsTb, params)
	self:overBuffsInTable(self.bondToOtherBuffsTb, params)

	if params.endType ~= battle.BuffOverType.clean and self.csvCfg.easyEffectFunc == "reborn" then
		self:triggerByMoment(battle.BuffTriggerPoint.onHolderReborn, {
			buffCfgId = self.cfgId
		})
	end

	if self.isShow then
		local overCsvCfg = self.csvCfg

		battleEasy.pushNotifyCantJump(self.holder.view, "deleteBuffEffect", self.id, true, {
			aniSelectId = self:getEffectAniSelectId(),
			id = self.id,
			cfgId = self.cfgId,
			csvCfg = overCsvCfg,
			tostrModel = tostring(self.holder)
		})

		if self.csvCfg.stageArgs then
			self.scene:recordSceneAlterBuff(self.id, nil)
			battleEasy.deferNotifyCantJump(self.holder.view, "alterBattleScene", {
				restore = true,
				buffId = self.id
			})
		end

		if self.weatherCfgId then
			self.isShow = false

			for _, obj in self.scene:ipairsHeros() do
				if obj and obj:checkOverlaySpecBuffExit("weather") then
					self.isShow = true

					break
				end
			end

			battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
		end

		if self:isCoexistType() then
			local buff = self.holder:getBuff(self.cfgId)
			local buffID = self.id
			local aniArgs = self:getBuffEffectAniArgs()

			if buff then
				aniArgs = buff:getBuffEffectAniArgs()
				buffID = buff.id
			end

			if self.holder.buffOverlayCount[self.cfgId] > 0 then
				battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", buffID, false, aniArgs, {
					"iconEffect",
					"mainEffect"
				})

				if self.overlayType == battle.BuffOverlayType.Coexist then
					battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", buffID, false, aniArgs, {
						"mainEffect"
					})
				end
			end
		end
	end

	for name, _ in pairs(self.exRecordNameTb) do
		self:cleanEventByKey(name)
	end

	self.holder:onBuffImmuneChange(self, true)
	battleComponents.unbindAll(self)
	self.lastGroupRefresher:destroy()

	self.lastGroupRefresher = nil

	self.holder.buffs:erase(self.id)
	self.scene:deleteBuff(self.id)
	self.scene:cleanFieldBuffInfo(self)
	self.scene:checkCowWithBuff(self)
end

local triggerEndTypeTb = {
	battle.BuffTriggerPoint.onBuffOverNormal,
	battle.BuffTriggerPoint.onBuffOverDispel,
	battle.BuffTriggerPoint.onBuffOverlay
}

function BuffModel:triggerOnOver(params)
	if params.triggerCtrlEnd then
		self:triggerByMoment(battle.BuffTriggerPoint.onBuffControlEnd)
	end

	self:triggerByMoment(triggerEndTypeTb[params.endType], {
		buffCfgId = self.cfgId,
		fromBuffCfgId = params.fromBuffCfgId,
		fromBuffGroup = params.fromBuffGroup
	})
	self:triggerByMoment(battle.BuffTriggerPoint.onBuffOverBefore, {
		overType = params.endType,
		triggerCtrlEnd = params.triggerCtrlEnd,
		fromBuffCfgId = params.fromBuffCfgId
	})
	self:triggerByMoment(battle.BuffTriggerPoint.onBuffOver, {
		overType = params.endType,
		fromBuffCfgId = params.fromBuffCfgId
	})

	if not self.holder:isRealDeath() then
		self.holder:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBuffOver, {
			buffCfgId = self.cfgId,
			buffGroupId = self:group(),
			buffFlag = self:buffFlag(),
			overType = params.endType,
			fromBuffCfgId = params.fromBuffCfgId,
			selfOverlayCount = battleEasy.ifElse(self:isCoexistType(), 1, self.overlayCount),
			oriLifeRound = self.args.lifeRound,
			oriValue = clone(self:cfg2Value(self.args.value)),
			buffCaster = self.caster
		})
	end
end

function BuffModel:judgeOver()
	return self:getLifeRound() <= 0
end

local function isNeedUpdateLifeRound(lifeRoundType, triggerPoint, lifeTimeEnd, isSpecScene)
	local isStart = lifeTimeEnd and lifeTimeEnd == 0
	local isEnd = not lifeTimeEnd or lifeTimeEnd == 1
	local isBattleTurnType = not lifeRoundType or lifeRoundType == battle.lifeRoundType.battleTurn or lifeRoundType == battle.lifeRoundType.pureBattleTurn

	if isBattleTurnType then
		local isBattleTurnStart = triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnStart and isStart
		local isBattleTurnEnd = triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnEnd and isEnd

		if isBattleTurnStart or isBattleTurnEnd then
			return true
		end
	end

	if lifeRoundType then
		local isRoundType = lifeRoundType == battle.lifeRoundType.round or lifeRoundType == battle.lifeRoundType.roundNormal

		if isSpecScene and lifeRoundType == battle.lifeRoundType.roundNormal then
			isRoundType = false
		end

		if isRoundType then
			local isRoundStart = triggerPoint == battle.BuffTriggerPoint.onRoundStart and isStart
			local isRoundEnd = triggerPoint == battle.BuffTriggerPoint.onRoundEnd and isEnd

			if isRoundStart or isRoundEnd then
				return true
			end
		end

		local isBattleTurnNormalType = lifeRoundType == battle.lifeRoundType.battleTurnNormal

		if isBattleTurnNormalType then
			local isBattleTurnNormalStart = triggerPoint == battle.BuffTriggerPoint.onBattleTurnStart and isStart
			local isBattleTurnNormalEnd = triggerPoint == battle.BuffTriggerPoint.onBattleTurnEnd and isEnd

			if isBattleTurnNormalStart or isBattleTurnNormalEnd then
				return true
			end
		end
	end

	return false
end

local getCurRoundByLifeRoundType = {
	[battle.lifeRoundType.battleTurn] = function(buff, triggerPoint)
		local index = battle.BuffTriggerPoint.onHolderBattleTurnEnd == triggerPoint and 1 or 2

		return buff.holder:getBattleRoundAllWave(index)
	end,
	[battle.lifeRoundType.round] = function(buff, triggerPoint)
		local isAdd = battle.BuffTriggerPoint.onRoundEnd == triggerPoint and 1 or 0

		return buff.scene:getRoundAllWave(true) + buff.csvCfg.lifeTimeEnd * isAdd
	end,
	[battle.lifeRoundType.pureBattleTurn] = function(buff, triggerPoint)
		local index = battle.BuffTriggerPoint.onHolderBattleTurnEnd == triggerPoint and 1 or 2

		return buff.holder:getBattleRoundAllWave(index, true)
	end,
	[battle.lifeRoundType.battleTurnNormal] = function(buff, triggerPoint)
		local isAdd = battle.BuffTriggerPoint.onBattleTurnEnd == triggerPoint and 1 or 0

		return buff.scene.play.totalRoundBattleTurn + buff.csvCfg.lifeTimeEnd * isAdd
	end,
	[battle.lifeRoundType.roundNormal] = function(buff, triggerPoint)
		local isAdd = battle.BuffTriggerPoint.onRoundEnd == triggerPoint and 1 or 0

		return buff.scene:getRoundAllWave() + buff.csvCfg.lifeTimeEnd * isAdd
	end
}

function BuffModel:setLeftRound(triggerPoint)
	local passRound = 0
	local lifeRoundType = self.csvCfg.lifeRoundType or battle.lifeRoundType.battleTurn

	if lifeRoundType == battle.lifeRoundType.pureBattleTurn then
		local lastInfo = self.scene:getSpecialSceneInfo()

		if (not lastInfo or not lastInfo:isRoundUpdate()) and self.scene:getExtraBattleRoundMode() ~= battle.ExtraBattleRoundMode.normal then
			return
		end
	end

	local curRound = getCurRoundByLifeRoundType[lifeRoundType](self, triggerPoint)

	log.battle.buff.setLeftRound({
		buff = self,
		triggerPoint = triggerPoint,
		lifeRoundType = lifeRoundType,
		curRound = curRound,
		nowRound = self.nowRound
	})

	if curRound > self.nowRound then
		passRound = curRound - self.nowRound

		local pauseLifeRoundData = self.holder:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.pauseBuffLifeRound)

		if pauseLifeRoundData and not pauseLifeRoundData.buffCfgIDMap[self.cfgId] and not pauseLifeRoundData.buffGroupMap[self:group()] then
			return
		end

		local freezeArgs = self:getEventByKey(battle.ExRecordEvent.buffFreezeFlag)

		if freezeArgs and freezeArgs.freezeLifeRound then
			return
		end

		self.lifeRound = self.lifeRound - passRound
		self.nowRound = curRound

		if self:getLifeRound() <= 0 then
			return
		end

		if self.overlayType == 5 then
			local lastOverlayCount = self.overlayCount

			for i, lifeR in maptools.order_pairs(self.lifeRounds) do
				if lifeR > 0 then
					lifeR = lifeR - passRound

					if lifeR <= 0 then
						self.overlayCount = self.overlayCount - 1
						self.overlayCount = math.max(0, self.overlayCount)

						table.remove(self.lifeRounds, i)
					end
				end
			end

			if lastOverlayCount - self.overlayCount > 0 then
				self:refreshLerpValue(true)

				if self.isShow then
					local aniArgs = self:getBuffEffectAniArgs()

					battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", self.id, false, aniArgs)
				end
			end
		end
	end

	if self.weatherCfgId then
		battleEasy.deferNotifyCantJump(self.holder.view, "weatherRefresh", self)
	end
end

function BuffModel:update(triggerPoint, trigger)
	if self.isOver then
		return
	end

	local roundId = self.scene.play.battleRoundTriggerId

	if roundId and gExtraRoundTrigger[roundId] and gExtraRoundTrigger[roundId].forbiddenBuff[triggerPoint] then
		return
	end

	self:triggerBuffValueByNode(triggerPoint)

	if not self.holder then
		self:overClean()

		return
	end

	if self.holder:isDeath() and self.nodeManager:isNoDeathTrigger() and not self.csvCfg.noDelWhenFakeDeath then
		self:over()

		return
	end

	if self.isAuraType and self.caster:isDeath() then
		self:overClean()

		return
	end

	local updateLifeRound = isNeedUpdateLifeRound(self.csvCfg.lifeRoundType, triggerPoint, self.csvCfg.lifeTimeEnd, self.scene:isSpecScene())

	if updateLifeRound then
		self:setLeftRound(triggerPoint)

		if self:getLifeRound() <= 0 then
			self:over()
		end
	end

	if self.nodeManager:isNode0TriggerPoint(triggerPoint) and not self.scene.buffGlobalManager:checkBuffCanAdd(self, self.holder) then
		self:overClean()

		return
	end

	if self:isSpecBuff() and triggerPoint == battle.BuffTriggerPoint.onBuffTrigger then
		if not self.scene.buffGlobalManager:checkBuffCanAdd(self, self.holder) then
			self:overClean()

			return
		end

		self.scene.buffGlobalManager:refreshBuffLimit(self.scene, self)
	end

	if self.csvCfg.easyEffectFunc == battle.OverlaySpecBuff.shield then
		local shieldData = self:effectData()

		if shieldData and shieldData.reduceRate then
			local updateShield = isNeedUpdateLifeRound(shieldData.lifeRoundType, triggerPoint, shieldData.lifeTimeEnd)

			if updateShield then
				local reduceShieldHp = math.floor(shieldData.shieldHp * shieldData.reduceRate)

				shieldData.shieldHp = shieldData.shieldHp - reduceShieldHp
				shieldData.shieldTotal = shieldData.shieldTotal - reduceShieldHp

				battleEasy.deferNotifyCantJump(self.holder.view, "showBuffText", battle.ShowHeadNumberRes.txtShieldReduce)
			end
		end
	end

	self:triggerByMoment(triggerPoint, trigger)
end

function BuffModel:isTrigger(triggerPoint, trigger)
	local roundId = self.scene.play.battleRoundTriggerId or battle.defaultExtraAttackCheckId

	if gExtraRoundTrigger[roundId].limitBuff[triggerPoint] then
		local t = self.nodeManager:getExtraAttack(triggerPoint)
		local extraAttackCheck = true

		if self.scene:getExtraRoundMode() then
			extraAttackCheck = t[2] or t[3]
		else
			extraAttackCheck = not t[3]
		end

		if not extraAttackCheck then
			return false
		end
	end

	if triggerPoint == battle.BuffTriggerPoint.onBuffTrigger then
		local sameBuffId = self.id == trigger.buffId

		if not sameBuffId and SpecialOnBuffTrigger[trigger.easyEffectFunc] and self.nodeManager:isTriggerPointExist(triggerPoint) and trigger.checkEffectFunc == self.csvCfg.easyEffectFunc and trigger.isFirstTrigger then
			return true
		end

		return sameBuffId
	elseif triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnStart or triggerPoint == battle.BuffTriggerPoint.onHolderBattleTurnEnd or triggerPoint == battle.BuffTriggerPoint.onRoundStart or triggerPoint == battle.BuffTriggerPoint.onRoundEnd then
		return true
	end

	return self.nodeManager:isTriggerPointExist(triggerPoint)
end

function BuffModel:isSpecBuff()
	return SpecBuff[self.csvCfg.easyEffectFunc] or false
end

function BuffModel:refresh(buffArgs, delta)
	local overlayType = self.overlayType

	delta = buffArgs.overlayCount or delta or 0

	if overlayType == nil then
		return
	end

	if (overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.CoexistLifeRound) and self:getOverLayCount() == self.overlayLimit and delta >= 0 then
		self.lifeRound = buffArgs.lifeRound

		return
	end

	if delta > 0 and (overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.OverlayDrop or overlayType == battle.BuffOverlayType.CoexistLifeRound) then
		self.lifeRound = buffArgs.lifeRound
	end

	if overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.OverlayDrop or overlayType == battle.BuffOverlayType.CoexistLifeRound or overlayType == battle.BuffOverlayType.IndeLifeRound then
		self.overlayCount = cc.clampf(self.overlayCount + delta, 1, self.overlayLimit)

		if self.isNumberType then
			if overlayType == battle.BuffOverlayType.IndeLifeRound then
				table.insert(self.lifeRounds, self.lifeRound)
			elseif overlayType == battle.BuffOverlayType.Overlay then
				self.buffValue = clone(self:cfg2Value(buffArgs.value))
			end

			self:refreshLerpValue()
		end

		if self.isShow then
			local aniArgs = self:getBuffEffectAniArgs()

			if overlayType == battle.BuffOverlayType.Overlay or overlayType == battle.BuffOverlayType.OverlayDrop then
				battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", self.id, false, aniArgs)
			end
		end
	end
end

function BuffModel:triggerPrecheck()
	if table.get(self, "objThatTriggeringMeNow", "source") == self:toString() then
		return false
	end

	return true
end

function BuffModel:triggerByNode(nodeId)
	if self:triggerPrecheck() and self.nodeManager:check(nodeId) then
		self:takeEffect(nodeId)
	end
end

function BuffModel:triggerBuffValueByNode(triggerPoint)
	self.nodeManager:visitNodeByPoint(triggerPoint, function(nodeId, node)
		if node.buffValueUpdatePoint and node.buffValueUpdatePoint == triggerPoint then
			if self.args.buffValueFormulaEnv then
				self.buffValue = clone(battleCsv.doFormula(self.args.buffValueFormula, self.args.buffValueFormulaEnv)) or self.buffValue
			else
				self.buffValue = clone(self:cfg2Value(self.args.buffValueFormula)) or self.buffValue
			end
		end
	end)
end

function BuffModel:setObjTrigger()
	local triggerPoint, trigger
	local data = self.objTriggerVec:back()

	if data then
		triggerPoint = data.triggerPoint
		trigger = data.trigger
	end

	self.objThatTriggeringMeNow = trigger

	self:fillTriggerEnv(triggerPoint)
end

function BuffModel:triggerByMoment(triggerPoint, trigger)
	local t = {
		triggerPoint = triggerPoint,
		trigger = trigger
	}

	self.objTriggerVec:push_back(t)
	self:setObjTrigger()

	if not self:triggerPrecheck() then
		self.objTriggerVec:pop_back()
		self:setObjTrigger()

		return
	end

	self.nodeManager:visitNodeByPoint(triggerPoint, function(nodeId, node)
		self:triggerByNode(nodeId)
	end)
	self.objTriggerVec:pop_back()
	self:setObjTrigger()
end

local function dealWithCastBonds(group)
	table.sort(group, function(a, b)
		return a.tag > b.tag
	end)

	local n = table.length(group)

	for pre = 1, n do
		local preInfo = group[pre]
		local preBuff = preInfo.buff

		for next = pre + 1, n do
			local nextInfo = group[next]
			local nextBuff = nextInfo.buff

			if preInfo.tag == nextInfo.tag then
				preBuff.bondToOtherBuffsTb[nextBuff.id] = true
				nextBuff.bondToOtherBuffsTb[preBuff.id] = true
			end

			if math.floor(preInfo.tag) - math.floor(nextInfo.tag) == 1 then
				preBuff.bondChildBuffsTb[nextBuff.id] = true
			end
		end
	end
end

function BuffModel:buffFlag()
	return self.csvCfg.buffFlag
end

function BuffModel:takeEffect(nodeId)
	local pauseBuffEffectData = self.holder:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.pauseBuffEffect)

	if pauseBuffEffectData then
		local cfgIdResult = pauseBuffEffectData.buffCfgIDMap[self.cfgId]
		local groupResult = pauseBuffEffectData.buffGroupMap[self:group()]
		local buffFlagReult = false

		for _, flag in ipairs(self:buffFlag()) do
			if pauseBuffEffectData.buffFlagMap[flag] then
				buffFlagReult = true

				break
			end
		end

		if pauseBuffEffectData.isBlacklist then
			if cfgIdResult or groupResult or buffFlagReult then
				return false
			end
		elseif not cfgIdResult and not groupResult and not buffFlagReult then
			return false
		end
	end

	if self:getEventByKey(battle.ExRecordEvent.buffFreezeFlag) or self.holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.freezeBuff, "freezeEffect", self) then
		if nodeId == battle.BuffTriggerPoint.onNodeCall and self.csvCfg.easyEffectFunc then
			self.value = self:getValue()
		end

		return false
	end

	local triggerArgs = self.nodeManager:trigger(nodeId)

	log.battle.buff.takeEffectBefore({
		buff = self
	})
	local makeit

	if nodeId == battle.BuffTriggerPoint.onNodeCall then
		if self.csvCfg.easyEffectFunc then
			self.value = self:getValue()
			self.doEffectValue = clone(self.value)
			makeit = self:doEffect(self.csvCfg.easyEffectFunc, self.value)
			self.isEffect = true

			if self.dispatchEvent then
				self.scene:dispatchEvent(battle.BuffTriggerPoint.onBuffTakeEffectSelf, {
					buffCfgId = self.cfgId,
					buffGroupId = self:group(),
					buffFlag = self:buffFlag(),
					buffCaster = self.caster,
					buffHolder = self.holder
				})
			end
		end
	else
		self.castBuffGroupStack:push_back({})

		for i, funcStr in ipairs(triggerArgs.effectFuncs or {}) do
			local args = self:cfg2ValueWithTrigger(triggerArgs.funcArgs[i])

			args.originArgs = triggerArgs.funcArgs[i]

			local funstr = funcStr == "addAttr" and "addAttrNode" or funcStr

			if funstr == "modifier" then
				self:takeModifier(args)
			else
				log.battle.buff.takeEffectCastbuff({
					buff = self,
					orderId = i,
					funstr = funstr,
					nodeId = nodeId,
					originArgs = triggerArgs.funcArgs[i]
				})

				makeit = self:doEffect(funstr, args)
			end
		end

		for _, castBuffGroup in pairs(self.castBuffGroupStack:back()) do
			dealWithCastBonds(castBuffGroup)
		end

		self.castBuffGroupStack:pop_back()
	end

	log.battle.buff.takeEffectAfter({
		buff = self
	})
	self.nodeManager:onTriggerEnd(nodeId, makeit)

	local explorerID = self.csvCfg.explorerID[1]

	if explorerID then
		local explorerRes = csv.explorer.explorer[explorerID].simpleIcon

		battleEasy.queueNotify("queueExplorer", self.caster.faceTo, explorerRes)
	end

	local heldItemID = self.csvCfg.heldItemID[1]

	if heldItemID then
		battleEasy.deferNotifyCantJump(self.caster.view, "showHeldItemEffect", heldItemID)
	end
end

local ModifiySign = {
	Set = 3,
	Delete = 2,
	Add = 1
}

function BuffModel:takeModifier(args)
	for _, v in ipairs(args) do
		local operateSign, key, value = unpack(v)
		local oldVal = self:getEventByKey(battle.ExRecordEvent.customRecord, key) or 0

		if operateSign == ModifiySign.Add then
			self:addExRecord(battle.ExRecordEvent.customRecord, oldVal + value, key)
		elseif operateSign == ModifiySign.Delete then
			self:addExRecord(battle.ExRecordEvent.customRecord, oldVal - value, key)
		elseif operateSign == ModifiySign.Set then
			self:addExRecord(battle.ExRecordEvent.customRecord, value, key)
		end
	end
end

function BuffModel:onSkillType(typeNum)
	local obj = typeNum > 0 and self.holder or self.caster
	local curSkill = obj.curSkill

	typeNum = math.abs(typeNum)

	if not curSkill then
		return false
	end

	if curSkill.skillType == battle.SkillType.NormalSkill then
		if typeNum == 1 and curSkill.skillType2 == battle.MainSkillType.BigSkill then
			return true
		elseif typeNum == 2 and curSkill.skillType2 == battle.MainSkillType.SmallSkill then
			return true
		elseif typeNum == 3 and curSkill.skillType2 == battle.MainSkillType.NormalSkill then
			return true
		elseif typeNum == 4 then
			return true
		elseif typeNum == 5 and curSkill.skillType2 ~= battle.MainSkillType.BigSkill then
			return true
		end
	end

	return false
end

function BuffModel:onCurHP(valueType, val, compOpt)
	local ret = false
	local curHp = math.floor(self.holder:hp())

	if valueType == 1 then
		local perHp = math.floor(self.holder:hpMax() * val)

		if curHp == perHp then
			return true
		end

		if curHp < perHp then
			ret = true
		end
	elseif valueType == 2 then
		if curHp == val then
			return true
		end

		if curHp < val then
			ret = true
		end
	end

	if compOpt == 1 then
		ret = not ret
	end

	return ret
end

function BuffModel:onSkillDamage(valueType, val, compOpt)
	local ret = false
	local damageValue
	local curAttackMeObj = self.holder.curAttackMeObj

	if curAttackMeObj and curAttackMeObj.curSkill then
		local final = curAttackMeObj.curSkill:getTargetsFinalResult(self.holder.id)

		damageValue = final.damage.real:get(battle.ValueType.normal) - final.resumeHp.real:get(battle.ValueType.normal)
	end

	if not damageValue then
		return ret
	end

	damageValue = math.floor(math.abs(damageValue))

	if valueType == 1 then
		local perHp = math.floor(self.holder:hpMax() * val)

		if damageValue == perHp then
			return true
		end

		if damageValue < perHp then
			ret = true
		end
	elseif valueType == 2 then
		if damageValue == val then
			return true
		end

		if damageValue < val then
			ret = true
		end
	end

	if compOpt == 1 then
		ret = not ret
	end

	return ret
end

function BuffModel:onSomeFlag(valTb)
	local ret = true

	for i, str in ipairs(valTb) do
		ret = ret and self:cfg2ValueWithTrigger(str)

		log.battle.buff.onSomeFlag({
			buff = self,
			checkId = i,
			valTb = valTb,
			str = str,
			ret = ret
		})

		if not ret then
			break
		end
	end

	return ret
end

function BuffModel:refreshExtraTargets(idx, targets)
	self.extraTargets[idx] = targets
end

local fromSkillTriggerPoint = {
	[battle.BuffTriggerPoint.onHolderAttackBefore] = true,
	[battle.BuffTriggerPoint.onHolderBeforeBeHit] = true,
	[battle.BuffTriggerPoint.onHolderAfterBeHit] = true,
	[battle.BuffTriggerPoint.onHolderFinallyBeHit] = true,
	[battle.BuffTriggerPoint.onHolderAttackEnd] = true,
	[battle.BuffTriggerPoint.onHolderKillHandleChooseTarget] = true,
	[battle.BuffTriggerPoint.onHolderKillTarget] = true,
	[battle.BuffTriggerPoint.onHolderMateKilledBySkill] = true,
	[battle.BuffTriggerPoint.onSkillHitTarget] = true
}

function BuffModel:fillTriggerEnv(triggerPoint)
	if fromSkillTriggerPoint[triggerPoint] then
		self.triggerEnv = {
			skill = battleCsv.CsvSkill.newWithCache(self.objThatTriggeringMeNow)
		}
	elseif triggerPoint == battle.BuffTriggerPoint.onBuffBeAdd then
		self.triggerEnv = {
			beAddBuff = battleCsv.CsvBuff.newWithCache(self.objThatTriggeringMeNow)
		}
	else
		self.triggerEnv = self.objThatTriggeringMeNow or {}
	end
end

function BuffModel:playTriggerPointEffect()
	if self.isOver then
		return
	end

	local buffActionEffect = self.csvCfg.buffActionEffect

	if not buffActionEffect or not buffActionEffect.triggerEffect then
		return
	end

	local effect = csvClone(buffActionEffect.triggerEffect)

	if effect.onceEffectResPath then
		self.isOnceEffectPlayed = false
		effect.onceEffectPos = effect.onceEffectPos or 0
		effect.onceEffectOffsetPos = effect.onceEffectOffsetPos or cc.p(0, 0)
	end

	local aniArgs = self:getBuffEffectAniArgs()

	aniArgs.csvCfg = effect

	battleEasy.pushNotifyCantJump(self.holder.view, "playBuffAniEffect", self.id, false, aniArgs, {
		"onceEffect",
		"textEffect"
	})

	if effect.showHeldItem then
		local heldItemID = effect.heldItemID

		battleEasy.deferNotifyCantJump(self.holder.view, "showHeldItemEffect", heldItemID)
	end
end

function BuffModel:getLifeRound()
	return self.lifeRound
end

function BuffModel:getValue()
	if not self.buffValue then
		return
	end

	if self.isNumberType then
		local enhance1 = self.buffInitEnhanceVal or 0
		local enhance2 = self.holder:getBuffEnhance(self:group(), 2)
		local value = self.buffValue * math.max(enhance1 + enhance2 + 1, 0)

		if self.overlayType == battle.BuffOverlayType.Overlay or self.overlayType == battle.BuffOverlayType.OverlayDrop then
			value = value * self:getOverLayCount()
		elseif self.overlayType == battle.BuffOverlayType.IndeLifeRound then
			local ret = itertools.filter(self.lifeRounds, function(i, lifeR)
				return lifeR > 0
			end)

			value = value * (1 + table.length(ret))
		end

		return value
	end

	return self.value or clone(self.buffValue)
end

function BuffModel:setValue(value)
	self.buffValue = value
	self.value = self:getValue()
	self.isNumberType = type(self.buffValue) == "number"
end

function BuffModel:refreshLerpValue(isOver)
	if self:getEventByKey(battle.ExRecordEvent.buffFreezeFlag) then
		self.value = self:getValue()

		return
	end

	if not self.isNumberType or not self.isEffect then
		return
	end

	if self.csvCfg.easyEffectFunc and self.nodeManager:isNode0TriggerPoint(battle.BuffTriggerPoint.onBuffCreate) then
		local oldValue = self:getEffectValue()

		self.value = self:getValue()

		local lerpValue = self.value - oldValue

		self.doEffectValue = self.value

		self:doEffect(self.csvCfg.easyEffectFunc, lerpValue, isOver)
	end
end

function BuffModel:group()
	if self.lastGroup then
		return self.lastGroup
	end

	local group = self.csvCfg.group
	local cache = self.scene:getConvertGroupCache()

	if cache and cache.assignGroup[group] then
		group = cache.convertGroup
	end

	self.lastGroup = group

	return group
end

function BuffModel:addExRecord(eventName, args, ...)
	self.scene.extraRecord:addExRecord(eventName, args, self:getEventMainKey(), ...)

	self.exRecordNameTb[eventName] = true
end

function BuffModel:getEventByKey(eventName, ...)
	return self.scene.extraRecord:getEventByKey(eventName, self:getEventMainKey(), ...)
end

function BuffModel:cleanEventByKey(eventName, ...)
	return self.scene.extraRecord:cleanEventByKey(eventName, self:getEventMainKey(), ...)
end

function BuffModel:getEventMainKey()
	if not self.extraRecordKey then
		self.extraRecordKey = "b" .. self.id .. "o" .. self.holder.id
	end

	return self.extraRecordKey
end

function BuffModel:isCoexistType()
	return self.overlayType == battle.BuffOverlayType.Coexist or self.overlayType == battle.BuffOverlayType.CoexistLifeRound
end

function BuffModel:isNormalCoverType()
	return self.overlayType == battle.BuffOverlayType.Normal or self.overlayType == battle.BuffOverlayType.Cover or self.overlayType == battle.BuffOverlayType.CoverValue or self.overlayType == battle.BuffOverlayType.CoverLifeRound
end

function BuffModel:getOverLayCount()
	if self:isCoexistType() then
		return self.holder.buffOverlayCount[self.cfgId]
	end

	return self.overlayCount
end

function BuffModel:getOverlayLimit()
	return self.overlayLimit
end

function BuffModel:beDispel(all, type, fromBuff)
	local params = {
		endType = type,
		fromBuffCfgId = fromBuff.cfgId,
		fromBuffGroup = fromBuff:group()
	}

	if all or self:isCoexistType() or self:isNormalCoverType() then
		return self:over(params)
	end

	if self.overlayType == battle.BuffOverlayType.Overlay or self.overlayType == battle.BuffOverlayType.OverlayDrop then
		if self.overlayCount == 1 then
			return self:over(params)
		end

		self:refresh(self.args, -1)
	end

	if self.overlayType == battle.BuffOverlayType.IndeLifeRound then
		if self.overlayCount == 1 then
			return self:over(params)
		end

		for i, lifeR in maptools.order_pairs(self.lifeRounds) do
			if lifeR > 0 then
				self.overlayCount = self.overlayCount - 1
				self.overlayCount = math.max(0, self.overlayCount)

				table.remove(self.lifeRounds, i)

				break
			end
		end
	end
end

function BuffModel:getEffectAniSelectId()
	local csvCfg = self.csvCfg

	if csvCfg.effectAniChoose.type == battle.BuffEffectAniType.OverlayCount then
		return csvCfg.effectAniChoose.mapping[self:getOverLayCount()]
	end

	return 1
end

local IDCounter = 0

function BuffModel:counterEffectArgs(args)
	args.aniCounter = IDCounter
	IDCounter = IDCounter + 1

	return args
end

function BuffModel:getBuffEffectAniArgs()
	local isSelfTurn = false
	local curHero = self.holder.scene.play.curHero

	if curHero then
		isSelfTurn = curHero.id == self.holder.id
	end

	local aniArgs = {
		justRefresh = true,
		boxRes = self.csvCfg.iconShowType,
		aniSelectId = self:getEffectAniSelectId(),
		id = self.id,
		cfgId = self.cfgId,
		overlayCount = self:getOverLayCount(),
		overlayLimit = self.overlayLimit,
		csvCfg = self.csvCfg,
		tostrModel = tostring(self.holder),
		tostrCaster = tostring(self.caster),
		isSelfTurn = isSelfTurn,
		isOnceEffectPlayed = self.isOnceEffectPlayed,
		args = self.args
	}

	self.isOnceEffectPlayed = true

	return self:counterEffectArgs(aniArgs)
end

function BuffModel:updateWithTrigger(triggerPoint, trigger)
	log.battle.buff.updateWithTrigger({
		buff = self,
		triggerPoint = triggerPoint
	})
	if triggerPoint == battle.BuffTriggerPoint.onBuffTrigger then
		local sameBuffId = self.id == trigger.buffId

		if sameBuffId then
			self.holder:addExRecord(battle.ExRecordEvent.soloTriggerBuffTime, 1, self.csvCfg.easyEffectFunc)
		end

		self.isEffect = true
	end

	self:update(triggerPoint, trigger)
end

function BuffModel:onTriggerEvent(event)
	local triggerPoint, trigger = event.name, event.args

	if self:isTrigger(triggerPoint, trigger) then
		self:updateWithTrigger(triggerPoint, trigger)
	end
end

function BuffModel:onTriggerGlobalEvent(event)
	self:onTriggerEvent(event)
end

function BuffModel:setCsvObject(obj)
	self.csvObject = obj
end

function BuffModel:getCsvObject()
	return self.csvObject
end

function BuffModel:toHumanString()
	return string.format("BuffModel: %s(%s)", self.id, self.cfgId)
end

function BuffModel:effectData()
	return self.buffEffectData
end

function BuffModel:toString()
	return "Buff_" .. tostring(self.id)
end

function BuffModel:hasBondRelation(id)
	if self.bondChildBuffsTb[id] then
		return true
	end

	if self.bondToOtherBuffsTb[id] then
		return true
	end

	return false
end
