-- chunkname: @src.battle.models.object_buff

function ObjectModel:isBeInForceSneer()
	for _, obj in self.scene:ipairsOnSiteHeros() do
		local forceSneerData = obj:getNoIgnoreOverlaySpecBuff(battle.OverlaySpecBuff.forceSneer, self)

		if forceSneerData and forceSneerData.inSneerArea(self) then
			return forceSneerData, obj
		end
	end

	return false
end

function ObjectModel:isBeInSneer()
	if self:isBeInForceSneer() then
		return true
	end

	if self:isBeInObjSneer() then
		return true
	end

	return false
end

function ObjectModel:isBeInObjSneer()
	local data = self:getNoIgnoreOverlaySpecBuff(battle.OverlaySpecBuff.sneer, self)

	if data then
		return data
	end

	return false
end

function ObjectModel:isBeInDuel()
	if not self:isBeInSneer() then
		return
	end

	local curBuffData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.sneer)

	if not curBuffData then
		return
	end

	return curBuffData.mode == battle.SneerType.Duel
end

function ObjectModel:isCantMoveSkill()
	if not self:isBeInSneer() then
		return
	end

	local forceSneerData = self:isBeInForceSneer()

	if forceSneerData then
		return forceSneerData.cantMoveSkill
	end

	local curBuffData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.sneer)

	if not curBuffData then
		return
	end

	return curBuffData.cantMoveSkill
end

function ObjectModel:getSneerObj()
	local forceSneerData, sneerAtMeObj = self:isBeInForceSneer()

	if forceSneerData then
		for _, data in sneerAtMeObj:ipairsOverlaySpecBuffTo("stealth", self) do
			return nil
		end

		return sneerAtMeObj
	end

	local curSneerData = self:getNoIgnoreOverlaySpecBuff(battle.OverlaySpecBuff.sneer, self)

	if curSneerData then
		local sneerAtMeObj = curSneerData.obj

		for _, data in sneerAtMeObj:ipairsOverlaySpecBuffTo("stealth", self) do
			return nil
		end

		return sneerAtMeObj
	end

	return nil
end

function ObjectModel:getDuelData()
	local curSneerData = self:getNoIgnoreOverlaySpecBuff(battle.OverlaySpecBuff.sneer, self)

	if curSneerData and curSneerData.mode == battle.SneerType.Duel then
		local sneerAtMeObj = curSneerData.obj

		for _, data in sneerAtMeObj:ipairsOverlaySpecBuffTo("stealth", self) do
			return nil
		end

		return curSneerData
	end

	return nil
end

function ObjectModel:getSneerExtraArgs(isFirend)
	if not self:isBeInSneer() then
		return nil
	end

	local forceSneerData = self:isBeInForceSneer()

	if forceSneerData then
		return isFirend and forceSneerData.extraArg.spreadArg2 or forceSneerData.extraArg.spreadArg1
	end

	local curSneerData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.sneer)

	if not curSneerData then
		return
	end

	return isFirend and curSneerData.extraArg.spreadArg2 or curSneerData.extraArg.spreadArg1
end

function ObjectModel:setProtectObj(obj)
	if obj:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.protection) then
		return nil
	end

	return obj
end

function ObjectModel:selectTextImmuneInfo(skillID)
	local skillDamageType = csv.skill[skillID].skillDamageType
	local allImmnue = self:hasTypeBuff("immuneAllDamage")

	if allImmnue then
		return "allimmune"
	end

	if skillDamageType == battle.SkillDamageType.Physical then
		local hasPhysicalImmune = self:hasTypeBuff("immunePhysicalDamage")

		if hasPhysicalImmune then
			return "physical"
		end
	elseif skillDamageType == battle.SkillDamageType.Special then
		local hasSpecialImmune = self:hasTypeBuff("immuneSpecialDamage")

		if hasSpecialImmune then
			return "special"
		end
	end

	local immuneText

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.immuneDamage) do
		immuneText = data:getImmuneInfo(immuneText, skillDamageType)

		if immuneText == "allimmune" then
			break
		end
	end

	return immuneText
end

function ObjectModel:processBeHitWakeUp(attacker)
	for _, data in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.sleepy, attacker) do
		data.time = data.time - 1

		if data.time == 0 then
			self:delBuff(data.id, true)
		end
	end
end

function ObjectModel:canReborn(attacker)
	if not attacker then
		return self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.reborn)
	end

	for id, data in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.reborn, attacker) do
		return true
	end

	return false
end

function ObjectModel:processReborn(attacker)
	if self:canReborn(attacker) and self:isFakeDeath() and not self:isRebornState() then
		self.state = battle.ObjectState.reborn

		local ret = true
		local deferKey = gRootViewProxy:proxy():pushDeferList(self.id)

		for _, v in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.reborn, attacker) do
			if v.isFastReborn then
				self:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
					attacker = attacker,
					buffId = v.buff.id
				})

				if self.scene.play:isInSkillProcess() then
					v.rebornTrigger = true
				else
					v.times = v.times - 1

					self:beforeRebornCleanData()

					if v.times <= 0 then
						self:delBuff(v.buff.id)
					end

					self:resetRebornState(v.hp, v.mp, v.buff)
					self:fastRebornResetExtraData()
				end

				ret = false

				break
			end
		end

		if ret then
			self:beforeRebornCleanData()

			local data = self:getNoIgnoreOverlaySpecBuff(battle.OverlaySpecBuff.reborn, attacker)

			data.buff.lifeRound = data.lifeRound

			self:triggerBuffOnPoint(battle.BuffTriggerPoint.onBuffTrigger, {
				attacker = attacker,
				buffId = data.buff.id
			})
		end

		gRootViewProxy:proxy():collectDeferList("battleTurn", self, gRootViewProxy:proxy():popDeferList(deferKey))
	else
		self:processRealDeath(self.deadArgs.beAttackZOrder, self.deadArgs.noTrigger)
	end
end

function ObjectModel:resetRebornState(hp, mp, buff)
	if not self:isRebornState() then
		return
	end

	log.battle.object.reborn({
		object = self,
		buff = buff,
		mp = mp,
		hp = hp
	})

	self.state = battle.ObjectState.normal

	self:resetHp(hp)
	self:resetMP1(mp)
	self.scene.extraRecord:cleanEventByKey(battle.ExRecordEvent.rebornRound, self.id)

	if self:getEventByKey(battle.ExRecordEvent.weatherLevels) then
		self.scene.buffGlobalManager:tryActiveWeather(self.scene, self.id, self.force, self:getEventByKey(battle.ExRecordEvent.weatherLevels))
	end
end

function ObjectModel:isBeInConfusion()
	return self:checkOverlaySpecBuffExit("confusion")
end

function ObjectModel:isNeedAutoFightByBuff()
	local controlEnemyData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.controlEnemy)
	local isIgnoreConfusion = controlEnemyData and controlEnemyData.isIgnoreConfusion

	if self:isBeInSneer() or self:isBeInConfusion() and not isIgnoreConfusion then
		return true
	end

	local roundAttackInfo = self:getEventByKey(battle.ExRecordEvent.roundAttackInfo)

	if roundAttackInfo and roundAttackInfo.isAutoAttack then
		return true
	end

	if self.scene:getExtraRoundMode() then
		if self:currentExtraBattleData().fullManual then
			return false
		end

		return true
	end

	return self.scene.play:getExtraBattleRoundData("targetId")
end

function ObjectModel:getAddAttackRangeObjs(skill)
	if not self:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.addAttackRange) then
		return
	end

	local skillFlags = skill and skill.cfg.skillFlag or {}
	local ret = {}

	local function filter(data)
		for _, flag in ipairs(skillFlags) do
			if data.filterFlags[flag] then
				return true
			end
		end

		return false
	end

	local function filterObj(obj)
		if self.scene:isBackHeros(obj) then
			return false
		end

		return true
	end

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.addAttackRange, filter) do
		local dels = {}

		for i, obj in ipairs(data.targets) do
			if obj:isRealDeath() then
				table.insert(dels, i)
			elseif filterObj(obj) then
				ret[obj.id] = obj
			end
		end

		for i = table.length(dels), 1, -1 do
			table.remove(data.targets, dels[i])
		end
	end

	return ret
end

function ObjectModel:addBuffEnhance(buffGroupID, buffCfgID, value, type)
	if not self.buffGroupEnchance[type][buffGroupID] then
		self.buffGroupEnchance[type][buffGroupID] = {}
	end

	self.buffGroupEnchance[type][buffGroupID][buffCfgID] = value
end

function ObjectModel:delBuffEnhance(buffGroupID, buffCfgID, type)
	if not self.buffGroupEnchance[type][buffGroupID] then
		return
	end

	self.buffGroupEnchance[type][buffGroupID][buffCfgID] = nil
end

function ObjectModel:getBuffEnhance(buffGroupID, type)
	local ret = 0

	if buffGroupID == 0 or not self.buffGroupEnchance[type][buffGroupID] then
		return ret
	end

	for _, v in pairs(self.buffGroupEnchance[type][buffGroupID]) do
		ret = ret + v
	end

	return ret
end

function ObjectModel:isNotReSelect(isProtect)
	if isProtect and self:checkOverlaySpecBuffExit("depart") then
		for _, data in self:ipairsOverlaySpecBuffTo("depart", self) do
			if not data.canProtect then
				return true
			end
		end
	end

	if self.scene:isBackHeros(self) then
		return true
	end

	return self:isAlreadyDead() or self:checkOverlaySpecBuffExit("leave")
end

function ObjectModel:addSkillType2Data(tag, data)
	for _, v in ipairs(self.closeSkillType2) do
		if v.tag == tag then
			v.data = data

			return
		end
	end

	table.insert(self.closeSkillType2, {
		tag = tag,
		data = data
	})
end

function ObjectModel:removeSkillType2Data(tag)
	for k, v in ipairs(self.closeSkillType2) do
		if v.tag == tag then
			table.remove(self.closeSkillType2, k)

			return
		end
	end
end

function ObjectModel:isSKillType2Close(skillType2)
	local switch = false

	for i = table.length(self.closeSkillType2), 1, -1 do
		if self.closeSkillType2[i].data[skillType2] then
			switch = switch or self.closeSkillType2[i].data[skillType2]
		end
	end

	return switch
end

function ObjectModel:getExtraRoundMode()
	if self.curExtraDataIdx == 0 then
		return
	end

	return self:currentExtraBattleData().mode
end

local function getExSkillWeightFixArgs(obj)
	local fixArgs

	for _, weightFixData in obj:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.extraSkillWeightValueFix) do
		if weightFixData.fixType == 0 then
			fixArgs = {
				fixWeightValue = weightFixData.fixValue,
				fixCostType = weightFixData.fixCostType
			}
		end
	end

	return fixArgs
end

local function getBanExAttackArgs(obj, mode)
	local args = {
		canTriggerOthers = true,
		canResponseSelf = true,
		canResponseOthers = true
	}

	for _, data in obj:ipairsOverlaySpecBuff("banExtraAttack") do
		local id = data.banModeTb[mode]

		for k, v in pairs(data.banModeType[id]) do
			args[k] = battleEasy.ifElse(not v, v, args[k])
		end
	end

	return args
end

local function checkExAttackTrigger(trigger, responder, mode)
	local banArgs1 = getBanExAttackArgs(trigger, mode)
	local banArgs2 = getBanExAttackArgs(responder, mode)

	if trigger.id == responder.id and not banArgs2.canResponseSelf then
		return false
	end

	if trigger.id ~= responder.id then
		if not banArgs1.canTriggerOthers then
			return false
		end

		if not banArgs2.canResponseOthers then
			return false
		end
	end

	return true
end

local function extraAttackRoundLimited(obj, extraAttackData)
	local curTimes = obj:getEventByKey(battle.ExRecordEvent.extraAttackRoundLimit, extraAttackData.id)

	if curTimes and curTimes >= extraAttackData.roundTriggerLimit then
		return true
	end

	return false
end

local function initExtraBattleArgsFromBuffData(origin, buffData)
	origin = origin or {}
	origin.buffId = buffData.id
	origin.roundTriggerLimit = buffData.roundTriggerLimit
	origin.otherProcessBySkillID = buffData.otherProcessBySkillID

	return origin
end

function ObjectModel:onComboAttack(skill, target, skillOwner)
	if not skill:isNormalSkillType() then
		return false
	end

	if self.id ~= skillOwner.id then
		return false
	end

	local targetID = target.id

	if target:isAlreadyDead() then
		targetID = nil
	end

	if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
		fromObj = skill.owner
	}) then
		return false
	end

	if self:getExtraRoundMode() then
		return false
	end

	local comboData = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.comboAttack)

	if comboData and ymrand.random() < comboData.rate and not extraAttackRoundLimited(self, comboData) then
		self:addExtraBattleData(ExtraAttackArgs.fromCombo(targetId, skill.id, comboData))

		return true
	end

	return false
end

function ObjectModel:onCounterAttack(skill, target, skillOwner)
	if not skill:isNormalSkillType() then
		return false
	end

	if self.id == skillOwner.id or skillOwner:isAlreadyDead() then
		return false
	end

	if self:isSameForceEx(skillOwner.force) then
		return false
	end

	local existCfgIds = {}

	for _, data in self.extraRoundData:pairs() do
		if data.mode == battle.ExtraAttackMode.counter then
			existCfgIds[data.cfgId] = true
		end
	end

	local counterAttackNum = 0
	local counterFixArgs = getExSkillWeightFixArgs(skillOwner)

	for _, counterAttackData in self:ipairsOverlaySpecBuffTo(battle.OverlaySpecBuff.counterAttack, skillOwner) do
		if not existCfgIds[counterAttackData.cfgId] then
			local assignFriendlyBeAttack = false

			if not counterAttackData.mustEnemy or self.force ~= skillOwner.force and not self:isBeInConfusion() then
				local counterAttackObjs = counterAttackData.find() or {}

				for _, v in ipairs(counterAttackObjs) do
					if (skill.allDamageTargets[v.id] or skill.protectorObjs[v.id]) and checkExAttackTrigger(v, self, battle.ExtraAttackMode.counter) then
						assignFriendlyBeAttack = true

						break
					end
				end
			end

			if ymrand.random() <= counterAttackData.rate and assignFriendlyBeAttack and not extraAttackRoundLimited(self, counterAttackData) then
				counterAttackNum = counterAttackNum + 1

				if counterAttackData.isWeightingType then
					self:addExtraBattleData(ExtraAttackArgs.fromCounter(skillOwner.id, nil, counterAttackData, counterFixArgs))
				else
					local skill = self:getSkillByType2(counterAttackData.triggerSkillType2)

					self:addExtraBattleData(ExtraAttackArgs.fromCounter(skillOwner.id, skill.id, counterAttackData))
				end
			end

			existCfgIds[counterAttackData.cfgId] = true
		end
	end

	return counterAttackNum
end

function ObjectModel:onSyncAttack(skill, target, skillOwner)
	if target:isAlreadyDead() then
		-- block empty
	end

	local targetId = target.id

	local function addExtraDataToHero(obj, data, mode, exFixarg)
		if not obj or obj and obj:isAlreadyDead() then
			return
		end

		if target.force == obj.force and not obj:isBeInConfusion() and not data.isFixedForce then
			return
		end

		if targetId == obj.id then
			return
		end

		if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = obj
		}) then
			return
		end

		if data.rate > ymrand.random() and not extraAttackRoundLimited(self, data) then
			if data.isWeightingType then
				obj:addExtraBattleData(ExtraAttackArgs.fromSync(targetId, target, mode, nil, data, exFixarg))
			else
				local skill = obj:getSkillByType2(data.triggerSkillType2)

				obj:addExtraBattleData(ExtraAttackArgs.fromSync(targetId, target, mode, skill.id, data))
			end

			obj.scene:addObjToExtraRound(obj)
		end
	end

	if self.id == skillOwner.id then
		local inviteFixArgs = getExSkillWeightFixArgs(skillOwner)

		for _, inviteData in skillOwner:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.inviteAttack) do
			if inviteData.isTrigger(skill.skillType2) then
				local inviteObjs = inviteData.find() or {}

				for _, v in ipairs(inviteObjs) do
					if checkExAttackTrigger(skillOwner, v, battle.ExtraAttackMode.inviteAttack) then
						addExtraDataToHero(v, inviteData, battle.ExtraAttackMode.inviteAttack, inviteFixArgs)
					end
				end
			end
		end
	end

	if self.force ~= skillOwner.force then
		return
	end

	if self.id == skillOwner.id then
		return
	end

	if self.id == target.id then
		return
	end

	local syncFixArgs = getExSkillWeightFixArgs(skillOwner)

	for _, syncData in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.syncAttack) do
		if syncData.isTrigger(skill.skillType2) and checkExAttackTrigger(skillOwner, self, battle.ExtraAttackMode.syncAttack) then
			addExtraDataToHero(self, syncData, battle.ExtraAttackMode.syncAttack, syncFixArgs)
		end
	end
end

function ObjectModel:onAssistAttack(target, data)
	local targetId

	if self:isAlreadyDead() then
		return
	end

	if data.onlyHasTargetRun and not target then
		return
	end

	if target and (not target:isAlreadyDead() or true) then
		targetId = target.id

		if self:isSameForceEx(target.force, nil, data.confusionAttack) then
			return
		end

		if target:isLogicStateExit(battle.ObjectLogicState.cantBeSelect, {
			fromObj = self
		}) then
			return
		end
	end

	if data.rate > ymrand.random() and not extraAttackRoundLimited(self, data) then
		if data.isWeightingType then
			self:addExtraBattleData(ExtraAttackArgs.fromAssis(targetId, nil, data))
		else
			local skill = self:getSkillByType2(data.triggerSkillType2)

			self:addExtraBattleData(ExtraAttackArgs.fromAssis(targetId, skill.id, data))
		end

		self.scene:addObjToExtraRound(self)
	end
end

function ObjectModel:onProphetAttack(skill, skillOwner, prophetData)
	if not skill:isNormalSkillType() then
		return false
	end

	if self.id == skillOwner.id or skillOwner:isAlreadyDead() then
		return false
	end

	if self.force == skillOwner.force and (prophetData.mustEnemy or not self:isBeInConfusion()) then
		return false
	end

	if extraAttackRoundLimited(self, prophetData) then
		return false
	end

	for i = 1, prophetData.time do
		local counterFixArgs = getExSkillWeightFixArgs(skillOwner)

		if prophetData.isWeightingType then
			self:addExtraBattleData(ExtraAttackArgs.fromProphet(skillOwner.id, nil, prophetData, counterFixArgs))
		else
			local newSkill = self:getSkillByType2(prophetData.triggerSkillType2)

			self:addExtraBattleData(ExtraAttackArgs.fromProphet(skillOwner.id, newSkill.id, prophetData))
		end

		self.scene:addObjToExtraRound(self)
	end
end

function ObjectModel:extraBattleRoundCantAttack()
	local cantHit = self.scene.play:getExtraBattleRoundData("cantHit")

	if cantHit and cantHit[self.id] then
		return true
	end

	return false
end

function ObjectModel:doShiftPos(effectCfg, buff)
	local lastInfo = self.scene:getSpecialSceneInfo()

	if lastInfo then
		return
	end

	local shiftObjs = {}
	local targetSeat = self.shiftPos
	local target = self.scene:shiftSeat(self, targetSeat)

	for _, exObj in self.scene.extraHeros:order_pairs() do
		if exObj:isBindOwnerWithShiftPos() then
			if target and exObj.seat == target.seat then
				exObj.seat = self.seat

				table.insert(shiftObjs, exObj)
			elseif exObj.seat == self.seat then
				exObj.seat = targetSeat

				table.insert(shiftObjs, exObj)
			end
		end
	end

	if target then
		table.insert(shiftObjs, target)
	end

	table.insert(shiftObjs, self)

	self.shiftPos = nil
	self.shiftPosMode = nil

	local function doShiftPosSpr(obj, effectCfg)
		obj.view:notify("doShiftPos", obj.seat, effectCfg)
		gRootViewProxy:notify("doShiftPos", tostring(obj))
		obj:onPositionStateChange(false, false, true, buff)
	end

	for _, obj in ipairs(shiftObjs) do
		if target and obj.seat == target.seat then
			doShiftPosSpr(obj)
		elseif obj.seat == self.seat then
			doShiftPosSpr(obj, effectCfg)
		end
	end
end

function ObjectModel:checkBuffCanBeAdd(caster, ignoreCaster, ignoreHolder)
	local ignoreHash = arraytools.hash(ignoreCaster)

	if not ignoreHash[1] then
		if caster and caster:checkOverlaySpecBuffExit("leave") and caster.id ~= self.id then
			for _, data in caster:ipairsOverlaySpecBuffTo("leave", self) do
				return false
			end
		end

		if caster and caster:checkOverlaySpecBuffExit("depart") and caster.id ~= self.id then
			for _, data in caster:ipairsOverlaySpecBuffTo("depart", self) do
				if data.leaveSwitch then
					return false
				end
			end
		end
	end

	local ignoreBuffGroup = battleEasy.ifElse(ignoreHolder, battleCsv.doFormula(ignoreHolder, self.protectedEnv), {})

	if ignoreBuffGroup ~= 1 then
		if self:isSpecialDeath() then
			return false
		end

		if self:isLogicStateExit(battle.ObjectLogicState.cantBeAddBuff, {
			fromObj = caster,
			ignoreBuffGroup = battleEasy.ifElse(type(ignoreBuffGroup) == "table", ignoreBuffGroup, {})
		}) then
			return false
		end
	end

	if not ignoreHash[2] and caster and caster:isBeInSneer() then
		local isFriend = self:isSameForce(caster.force)

		if caster:getSneerExtraArgs(isFriend) == battle.SneerArgType.NoSpread or caster:getSneerExtraArgs(isFriend) == battle.SneerArgType.DamageSpread then
			local sneerObj = isFriend and caster:getSneerObj()

			if sneerObj and sneerObj ~= self then
				return false
			end
		end
	end

	return true
end

function ObjectModel:doFrontStage()
	local data = self:getEventByKey(battle.ExRecordEvent.frontStage)

	if not data then
		return
	end

	local seat = data.frontStageTarget

	if seat == nil or self.scene:isSeatEmpty(seat) == false then
		return
	end

	self.scene:addObj(self.force, seat, self)
	self.scene.backHeros:erase(self.id)

	self.seat = seat

	self:addMP1(data.transferMp)

	local play = self.scene.play

	if data.stageRound ~= play.curRound or not data.stageAttacked then
		local roundDatas = self:getEventByKey(battle.ExRecordEvent.backStageRoundInfo)

		if roundDatas then
			for _, rData in ipairs(roundDatas) do
				play:addRoundLeftHero(rData)
			end

			self:cleanEventByKey(battle.ExRecordEvent.backStageRoundInfo)
		else
			play:addRoundLeftHero({
				obj = self
			})
		end
	else
		play:setHeroIsAttacked(self)
	end

	local exAttackDatas = self:getEventByKey(battle.ExRecordEvent.sceneRoundExAttackData)

	if exAttackDatas then
		for _, exData in ipairs(exAttackDatas) do
			self:addExtraBattleData(exData)
		end

		self:cleanEventByKey(battle.ExRecordEvent.sceneRoundExAttackData)
	end

	self:cleanEventByKey(battle.ExRecordEvent.frontStage)
	self:onInitPassData()

	if not data.isBrawl then
		self:initedTriggerPassiveSkill()
	end

	self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderBackStage, {
		obj = self,
		buffCfgId = data.cfgId
	})
	self:onPositionStateChange(true, true)
	gRootViewProxy:getProxy("onAddUnitsInSeat", tostring(self))
	battleEasy.deferNotifyCantJump(self.view, "stageChange", true)

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.followObject) do
		if data.caster:isBindOwnerWithStage() then
			data.caster:doFrontStage()
		end
	end
end

function ObjectModel:clearFieldBuffs()
	for _, buff in self:iterBuffs() do
		if buff.isFieldSubBuff then
			buff:overClean()
		end
	end
end

function ObjectModel:onPositionStateChange(isEnterState, needChangeField, isTrigger, buff)
	if isTrigger then
		self:triggerBuffOnPoint(battle.BuffTriggerPoint.onHolderShiftChange, {
			obj = self,
			buffCfgId = buff.cfgId
		})
	end

	if not needChangeField then
		return
	end

	local isLeave = self:leaveInfluenceBuff()

	if not self.preFieldState then
		self.preFieldState = isLeave and 1 or 2
	end

	local isInFieldState = self.preFieldState == 1

	if isInFieldState == isEnterState then
		return
	end

	log.battle.object.posStateChange({
		object = self,
		isLeave = isLeave,
		isEnterState = isEnterState,
		buff = buff
	})

	if isInFieldState then
		self:clearFieldBuffs()
	else
		self.scene:tirggerFieldBuffs(self)
	end

	self.preFieldState = 3 - self.preFieldState

	self:influenceSceneBuff(battle.InfluenceSceneBuffType.leave, isLeave)
end

function ObjectModel:influenceSceneBuff(itype, state)
	self.scene:influenceSceneBuff(itype, self, state)
end

function ObjectModel:leaveInfluenceBuff()
	local isLeave = false

	if self:checkOverlaySpecBuffExit("leave") then
		isLeave = true
	end

	for _, data in self:ipairsOverlaySpecBuff("depart") do
		if data.leaveSwitch then
			isLeave = true

			break
		end
	end

	if self.scene:isBackHeros(self) then
		isLeave = true
	end

	return isLeave
end

function ObjectModel:dealOpenValueByKey(key, oldValue)
	for _, curBuffData in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.opGameData) do
		if curBuffData and curBuffData.key == key then
			local isTrigger = curBuffData

			if isTrigger ~= true then
				self.protectedEnv:resetEnv()

				local env = battleCsv.fillFuncEnv(self.protectedEnv, {
					oldValue = oldValue
				})

				isTrigger = battleCsv.doFormula(isTrigger, env)
			end

			if isTrigger then
				return curBuffData.op(oldValue, curBuffData.value)
			end
		end
	end

	return oldValue
end

function ObjectModel:addReplaceSkillRecord(oldId, newId, buffId)
	if not self.skillIdToReplaceRecord[oldId] then
		local newIndex = table.length(self.skillReplaceReocrd) + 1

		self.skillReplaceReocrd[newIndex] = {}

		table.insert(self.skillReplaceReocrd[newIndex], {
			skillId = oldId
		})

		self.skillIdToReplaceRecord[oldId] = newIndex
	end

	self.skillIdToReplaceRecord[newId] = self.skillIdToReplaceRecord[oldId]

	table.insert(self.skillReplaceReocrd[self.skillIdToReplaceRecord[newId]], {
		skillId = newId,
		buffId = buffId
	})
end

function ObjectModel:delReplaceSkillRecord(index, buffId)
	for id, data in ipairs(self.skillReplaceReocrd[index]) do
		if data.buffId == buffId then
			table.remove(self.skillReplaceReocrd[index], id)

			break
		end
	end
end

function ObjectModel:getLastSkillRecord(index)
	local lastId = table.length(self.skillReplaceReocrd[index])

	return self.skillReplaceReocrd[index][lastId].skillId
end

function ObjectModel:doReplaceSkill(oldId, newId, args)
	local oldSkill = self.skills[oldId]
	local oldSpellRound = oldSkill.spellRound
	local oldSkillLevel = oldSkill:getLevel()

	self.skills[oldId] = nil

	local skillCfg = csv.skill[newId]
	local newSkill = newSkillModel(self.scene, self, newId, oldSkillLevel)

	self.skills[newId] = newSkill
	newSkill.spellRound = oldSpellRound

	if args and args.replaceView then
		newSkill:initSkillViewArgs(oldSkill)

		newSkill.ignoreViewCheck = true
	end
end

function ObjectModel:afterReplaceSkill()
	self:updateSkillsOrder()
	self:checkSkillCheat()

	for skillID, skill in self:iterSkills() do
		skill:updateStateInfoTb()
	end
end

function ObjectModel:replaceSkill(oldIdList, newIdList, buffId, args)
	local replaceInfo = ""

	for id, oldId in ipairs(oldIdList) do
		local newId = newIdList[id]

		if self.skills[oldId] then
			replaceInfo = replaceInfo .. oldId .. " to " .. newId .. "; "

			self:addReplaceSkillRecord(oldId, newId, buffId)
			self:doReplaceSkill(oldId, newId, args)
		end
	end

	log.battle.object.replaceSkill({
		replaceInfo = replaceInfo,
		object = self,
		cfgId = buffId
	})
	self:afterReplaceSkill()
end

function ObjectModel:resumeSkill(buffId)
	for index, record in ipairs(self.skillReplaceReocrd) do
		local curSkillId = self:getLastSkillRecord(index)

		self:delReplaceSkillRecord(index, buffId)

		local newSkillId = self:getLastSkillRecord(index)

		if newSkillId and newSkillId ~= curSkillId then
			self:doReplaceSkill(curSkillId, newSkillId)
		end
	end

	self:afterReplaceSkill()
end

function ObjectModel:resetReplaceSkillRecord()
	self.skillIdToReplaceRecord = {}
	self.skillReplaceReocrd = {}
end

function ObjectModel:isSelfForceConfusionAndNoTarget()
	local beSelfForceConfusion = false

	for _, data in self:ipairsOverlaySpecBuff("confusion", function(data)
		return not data.needSelfForce
	end) do
		beSelfForceConfusion = true

		break
	end

	if not beSelfForceConfusion then
		return false
	end

	local selfSideObjs = self:getCanAttackObjs(self.force)

	return table.length(selfSideObjs) == 0
end

function ObjectModel:newBuffImmune()
	self.buffImmuneCache = {
		immuneBuff = CMap.new(),
		immuneGroup = CMap.new(),
		powerGroup = CMap.new(),
		immuneFlag = CMap.new(),
		powerFlag = CMap.new()
	}

	for _, buff in self:iterBuffs() do
		if buff.isInited and not buff.isOver then
			self:onBuffImmuneChange(buff)
		end
	end
end

function ObjectModel:onBuffImmuneChange(buff, isOver)
	if not self.buffImmuneCache then
		self:newBuffImmune()
	end

	local function changeData(map, key)
		local data = map:find(key)

		if not data then
			map:insert(key, {})

			data = map:find(key)
		end

		local buffInfo = {
			id = buff.id,
			cfgId = buff.cfgId,
			group = buff:group(),
			flag = buff.csvCfg.buffFlag,
			triggerPriority = buff.triggerPriority
		}

		data[buff.id] = battleEasy.ifElse(isOver, nil, buffInfo)

		if not next(data) then
			map:erase(key)
		end
	end

	local groupRelation = gBuffGroupRelationCsv[buff:group()]

	if groupRelation then
		for _, tb in ipairs(groupRelation.immuneGroup) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.immuneGroup, k)
			end
		end

		for _, tb in ipairs(groupRelation.powerGroup) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.powerGroup, k)
			end
		end

		for _, tb in ipairs(groupRelation.immuneFlag) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.immuneFlag, k)
			end
		end

		for _, tb in ipairs(groupRelation.powerFlag) do
			for k, __ in pairs(tb) do
				changeData(self.buffImmuneCache.powerFlag, k)
			end
		end
	end

	local immuneBuffs = buff.csvCfg.immuneBuff

	for _, immuneBuffId in ipairs(immuneBuffs) do
		changeData(self.buffImmuneCache.immuneBuff, immuneBuffId)
	end
end

function ObjectModel:buffImmuneCheckPower(group, flags)
	local canAdd, reason = true

	if self.buffImmuneCache.powerFlag:size() > 0 then
		canAdd, reason = false, battle.BuffCantAddReason.powerFlag

		if next(flags) then
			for _, flag in ipairs(flags) do
				if self.buffImmuneCache.powerFlag:find(flag) then
					return true
				end
			end
		end
	end

	if self.buffImmuneCache.powerGroup:size() > 0 then
		if self.buffImmuneCache.powerGroup:find(group) then
			return true
		else
			canAdd, reason = false, battle.BuffCantAddReason.powerGroup
		end
	end

	return canAdd, reason
end

function ObjectModel:buffImmuneEffect(cfgId, group, flags, groupPower, caster)
	if not self.buffImmuneCache then
		self:newBuffImmune()
	end

	local ret, sortBuffInfos = true, {}
	local immGroup = self.buffImmuneCache.immuneGroup:find(group)
	local immBuff = self.buffImmuneCache.immuneBuff:find(cfgId)
	local immFlag = {}

	if next(flags) then
		for _, flag in ipairs(flags) do
			local data = self.buffImmuneCache.immuneFlag:find(flag)

			if data and next(data) then
				maptools.union_with(immFlag, data)
			end
		end
	end

	local checkPower, reason = self:buffImmuneCheckPower(group, flags)

	if not checkPower then
		return false, reason
	end

	if not self:checkFilterBuff(cfgId, caster, group, flags) then
		return false, battle.BuffCantAddReason.filter
	end

	for _, data in caster:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.applyCommandeer) do
		if data.cfgIdHashTb[cfgId] and data.howToDo == 1 then
			return false, battle.BuffCantAddReason.commandeer
		end
	end

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.applyCommandeer) do
		if (data.groupHashTb[group] or data.cfgIdHashTb[cfgId]) and (data.howToDo == 2 or data.howToDo == 3) then
			return false, battle.BuffCantAddReason.commandeer
		end
	end

	if groupPower.beImmune == 1 and immGroup and next(immGroup) then
		for k, v in pairs(immGroup) do
			if not battleEasy.loseImmuneEfficacyCheck(self, {
				group = group,
				cfgId = v.cfgId,
				indexGroup = v.group
			}) then
				table.insert(sortBuffInfos, v)

				ret = false
			end
		end
	end

	if groupPower.beImmune == 1 and immBuff and next(immBuff) then
		for k, v in pairs(immBuff) do
			if not battleEasy.loseImmuneEfficacyCheck(self, {
				cfgId = v.cfgId
			}) then
				table.insert(sortBuffInfos, v)

				ret = false
			end
		end
	end

	if groupPower.beImmune == 1 and immFlag and next(immFlag) then
		for k, v in pairs(immFlag) do
			table.insert(sortBuffInfos, v)

			ret = false
		end
	end

	if not ret then
		table.sort(sortBuffInfos, function(buffInfo1, buffInfo2)
			if buffInfo1.triggerPriority ~= buffInfo2.triggerPriority then
				return buffInfo1.triggerPriority < buffInfo2.triggerPriority
			end

			return buffInfo1.id < buffInfo2.id
		end)

		local effectBuff = self.scene:getBuffByID(sortBuffInfos[1].id)

		battleEasy.deferNotifyCantJump(self.view, "showBuffImmuneEffect", group)
		effectBuff:triggerByMoment(battle.BuffTriggerPoint.onBuffTrigger, {
			buffId = effectBuff.id
		})
	end

	return ret, battle.BuffCantAddReason.immune, sortBuffInfos
end

function ObjectModel:clearBuffImmune()
	self.buffImmuneCache = nil
end

function ObjectModel:isPossessAttack(skillType)
	if self:getEventByKey(battle.ExRecordEvent.possessTarget) and self:getExtraRoundMode() == battle.ExtraAttackMode.assistAttack then
		if skillType and skillType ~= battle.SkillType.NormalSkill and skillType ~= battle.SkillType.NormalCombine then
			return false
		end

		return true
	end

	return false
end

function ObjectModel:checkCanRecoverMp(attacker, damageArgs)
	if damageArgs.beAttackCantRecoverMp then
		return false
	end

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.cantRecoverMp) do
		if data.mode == 0 then
			return false
		end

		if data.mode == damageArgs.from then
			if data.mode == battle.DamageFrom.buff then
				if itertools.include(data.buffIds, damageArgs.buffCfgId) then
					return false
				end

				if itertools.include(data.natures, damageArgs.natureType) then
					return false
				end

				local buff = self:getBuff(damageArgs.buffCfgId)

				if buff and itertools.include(data.buffGroups, buff:group()) then
					return false
				end
			end

			if data.mode == battle.DamageFrom.rebound then
				return false
			end

			if data.mode == battle.DamageFrom.skill then
				if itertools.include(data.skillIds, damageArgs.skillId) then
					return false
				end

				if itertools.include(data.natures, damageArgs.natureType) then
					return false
				end
			end
		end
	end

	return true
end

function ObjectModel:checkFilterBuff(cfgId, caster, group, flags)
	if not self:checkOverlaySpecBuffExit("filterGroup") and not self:checkOverlaySpecBuffExit("filterFlag") then
		return true
	end

	for _, data in self:ipairsOverlaySpecBuff("filterGroup") do
		local filterGroupResult = data:checkFilterGroup(caster, group)

		log.battle.object.filterBuffGroup({
			cfgId = cfgId,
			object = self,
			caster = caster,
			group = group,
			data = data,
			filterResult = filterGroupResult
		})

		if filterGroupResult then
			return true
		end
	end

	for _, data in self:ipairsOverlaySpecBuff("filterFlag") do
		local filterFlagsResult = data:checkFilterFlag(caster, flags)

		log.battle.object.filterBuffFlag({
			cfgId = cfgId,
			object = self,
			caster = caster,
			flags = flags,
			data = data,
			filterResult = filterFlagsResult
		})

		if filterFlagsResult then
			return true
		end
	end

	return false
end

function ObjectModel:checkCanExtraAttack(exAtkData)
	local buffCfg = csv.buff[exAtkData.cfgId]
	local flags = {}

	if buffCfg then
		flags = buffCfg.buffFlag
	end

	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.forbiddenExtraAttack) do
		local isInList = false
		local cantAttack = false
		local ret = arraytools.filter(flags, function(_, flag)
			return data.buffFlags[flag]
		end)

		isInList = table.length(ret) > 0

		if data.isBlackMode then
			local modeCheck = false

			if data.modeCheck then
				modeCheck = data.forbiddenModes[exAtkData.mode]
			end

			cantAttack = isInList or modeCheck
		else
			cantAttack = isInList == false
		end

		if cantAttack then
			return false
		end
	end

	return true
end

function ObjectModel:needDispelTimes(buff, dispelCounter)
	for _, data in self:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.needMoreDispel) do
		local mode = data.mode
		local buffMap = data.buffMap
		local flag

		if mode == 1 then
			flag = buffMap[buff.cfgId]
		elseif mode == 2 then
			flag = buffMap[buff:group()]
		else
			for _, buffFlag in ipairs(buff.csvCfg.buffFlag) do
				if buffMap[buffFlag] then
					flag = true

					break
				end
			end
		end

		if flag then
			local dispelMap = data.dispelMap
			local buffId = buff.id

			if not dispelMap[buffId] then
				dispelMap[buffId] = data.dispelTimes
			end

			dispelCounter = dispelCounter or 1
			dispelMap[buffId] = dispelMap[buffId] - dispelCounter

			return dispelMap[buffId]
		end
	end

	return 0
end

function ObjectModel:dealLockMp1(originVal, ignoreLockMp1Add)
	local lockMp1AddData = self:getFrontOverlaySpecBuff("lockMp1Add")
	local lockMp1ReduceData = self:getFrontOverlaySpecBuff("lockMp1Reduce")

	if originVal > self:mp1() and lockMp1AddData and not ignoreLockMp1Add then
		local addDelta = originVal - self:mp1()
		local addLimit = lockMp1AddData.limit - lockMp1AddData.recordVal

		if addLimit == 0 then
			return true
		end

		lockMp1AddData.recordVal = lockMp1AddData.recordVal + math.min(addDelta, addLimit)

		return false, self:mp1() + math.min(addDelta, addLimit)
	end

	if originVal < self:mp1() and lockMp1ReduceData then
		local reduceDelta = self:mp1() - originVal
		local reduceLimit = lockMp1ReduceData.limit - lockMp1ReduceData.recordVal

		if reduceLimit == 0 then
			return true
		end

		lockMp1ReduceData.recordVal = lockMp1ReduceData.recordVal + math.min(reduceDelta, reduceLimit)

		return false, self:mp1() - math.min(reduceDelta, reduceLimit)
	end

	return false, originVal
end

function ObjectModel:isSameForce(force)
	return self.force == force
end

function ObjectModel:isSameForceEx(force, obj, confusionAttack)
	if obj then
		force = obj.force
	end

	if confusionAttack then
		return false
	end

	return self:isSameForce(force) and not self:isBeInConfusion()
end

function ObjectModel:checkCanUseSkill()
	if self:isDeath() then
		return false
	end

	if self:isSelfControled() then
		return false
	end

	if self:isLogicStateExit(battle.ObjectLogicState.cantUseSkill, {
		skillType2 = battle.MainSkillType.BigSkill
	}) then
		return false
	end

	return true
end

function ObjectModel:getCombineSkillBindObject(combinationObjCardId)
	local heros = self.scene:getHerosMap(self.force)

	for _, obj in heros:order_pairs() do
		if obj.id ~= self.id and itertools.include(combinationObjCardId, obj.markID) and obj:checkCanUseSkill() and obj.unitID == obj.originUnitID then
			return obj
		end
	end
end

local function newReocrdBuffData()
	return {
		map = CMap.new(),
		__bindKeys = cow.proxyObject("__bindKeys", {}),
		__globals = cow.proxyObject("__globals", {}),
		__filters = {}
	}
end

local function newOverLayValue()
	return {
		__data = {},
		addValue = function(t, id, k, value)
			t.__data[id] = t.__data[id] or {}
			t.__data[id][k] = value + (t.__data[id][k] or 0)

			return t.__data[id][k]
		end,
		getValue = function(t, id, k)
			return t.__data[id] and t.__data[id][k] or 0
		end,
		clear = function(t, id)
			t.__data[id] = nil
		end
	}
end

local OverlaySpecBuffCodeUse = {
	followObject = true,
	occupiedSeat = true
}

function ObjectModel:addOverlaySpecBuff(buff, refreshFunc, sortFunc)
	local key = buff.csvCfg.easyEffectFunc
	local buffEffetCfg = gBuffEffect[key]

	if not buffEffetCfg and not OverlaySpecBuffCodeUse[key] then
		return errorInWindows("please init %s in buff_effect.csv", key)
	end

	self.recordBuffDataTb[key] = self.recordBuffDataTb[key] or newReocrdBuffData()

	local buffData = self.recordBuffDataTb[key]

	if not refreshFunc then
		errorInWindows("addOverlaySpecBuff must need refresh")
	end

	local index = buffData.map:size() + 1

	if buffData.map:find(buff.id) then
		index = buffData.map:size()
	end

	if buffEffetCfg then
		if buffEffetCfg.overlayType == battle.BuffEffectOverlayType.Normal then
			if index > buffEffetCfg.overlayLimit then
				buff:overClean()

				return
			end
		elseif buffEffetCfg.overlayType == battle.BuffEffectOverlayType.PopTop then
			if index > buffEffetCfg.overlayLimit then
				for _, frontData in buffData.map:order_pairs() do
					local buff = self.buffs:find(frontData.id)

					if buff then
						buff:overClean()
					end

					break
				end
			end
		elseif buffEffetCfg.overlayType == battle.BuffEffectOverlayType.SameMode then
			local count = 0
			local lastBuffId

			for k, v in buffData.map:order_pairs() do
				if v.mode == buff.mode then
					count = count + 1
					lastBuffId = v.id
				end
			end

			if count + 1 > buffEffetCfg.overlayLimit then
				local buff = self.buffs:find(lastBuffId)

				if buff then
					buff:overClean()
				end
			end
		end
	end

	local listData = buffData.map:find(buff.id)
	local needNew = false

	if not listData then
		needNew = true

		local mt = {}

		function mt.__index(t, k)
			local k2 = buffData.__bindKeys[k]

			if k2 then
				return t.buffRef[k2]
			end

			if buffData.__globals[k] then
				return buffData.__globals[k]
			end

			return t.data[k]
		end

		function mt.__newindex(t, k, v)
			local k2 = buffData.__bindKeys[k]

			if k2 then
				t.buffRef[k2] = v
			elseif buffData.__globals[k] then
				buffData.__globals[k] = v
			else
				t.data[k] = v
			end
		end

		listData = setmetatable({
			data = {},
			bind = function(t1, k1, k2)
				if not buffData.__bindKeys[k1] then
					buffData.__bindKeys[k1] = k2
				end
			end,
			setG = function(t1, k1, v1)
				if not buffData.__globals[k1] then
					buffData.__globals[k1] = v1
				end
			end,
			updateData = function(t1, triggerPoint)
				return
			end,
			overlayValue = function(t1, func, k1, v)
				if not buffData.__effectValue then
					buffData.__effectValue = newOverLayValue()
				end

				local tt = buffData.__effectValue

				if not tt[func] or type(tt[func]) ~= "function" then
					error("OverlaySpecBuff overlayValue has not this func " .. func)
				end

				return tt[func](tt, t1.id, k1, v)
			end
		}, mt)

		buffData.map:insert(buff.id, listData)
	end

	listData.buff = buff
	listData.cfgId = buff.cfgId
	listData.id = buff.id
	listData.group = buff:group()
	listData.buffRef = buff.isNumberType and buff or buff:getValue()

	refreshFunc(listData)

	if sortFunc then
		listData:setG("sortFunc", sortFunc)
	end

	buff.buffEffectData = listData

	self:refreshOverlaySpecBuffOrder(key)

	return listData
end

function ObjectModel:getOverlaySpecBuffData(key)
	local buffData = self.recordBuffDataTb[key]

	return buffData and buffData.__globals or {}
end

function ObjectModel:refreshOverlaySpecBuffOrder(key)
	local keys = type(key) == "string" and {
		key
	} or key

	for _, i in ipairs(keys) do
		local buffData = self.recordBuffDataTb[i]

		buffData.order = nil
	end
end

function ObjectModel:getOverlaySpecBuffOrder(key)
	local buffData = self.recordBuffDataTb[key]

	if buffData.order then
		return buffData.order
	end

	local order = {}
	local ret

	for ii, data in buffData.map:order_pairs() do
		ret = true

		for _, f in ipairs(buffData.__filters) do
			if f(data) then
				ret = false

				break
			end
		end

		if ret then
			table.insert(order, ii)
		end
	end

	local firstData = order[1] and buffData.map:find(order[1])
	local sortFunc = firstData and firstData.sortFunc

	if sortFunc then
		table.sort(order, function(a, b)
			local data1 = buffData.map:find(a)
			local data2 = buffData.map:find(b)

			return sortFunc(data1, data2)
		end)
	end

	buffData.order = order

	return order
end

function ObjectModel:addOverlaySpecBuffFilter(key, dataFilter)
	self.recordBuffDataTb[key] = self.recordBuffDataTb[key] or newReocrdBuffData()

	local buffData = self.recordBuffDataTb[key]
	local filter = dataFilter or function()
		return true
	end

	table.insert(buffData.__filters, filter)
	self:refreshOverlaySpecBuffOrder(key)

	return tostring(filter)
end

function ObjectModel:deleteOverlaySpecBuffFilter(key, delFunc)
	local buffData = self.recordBuffDataTb[key]

	for i, f in ipairs(buffData.__filters) do
		if tostring(f) == delFunc then
			table.remove(buffData.__filters, i)

			break
		end
	end

	self:refreshOverlaySpecBuffOrder(key)
end

function ObjectModel:checkOverlaySpecBuffExit(key)
	local buffData = self.recordBuffDataTb[key]

	if not buffData then
		return false
	end

	if table.length(self:getOverlaySpecBuffOrder(key)) == 0 then
		return false
	end

	return true
end

local function emptyIteration()
	return nil
end

function ObjectModel:ipairsOverlaySpecBuff(key, filter)
	if not self:checkOverlaySpecBuffExit(key) then
		return emptyIteration
	end

	local buffData = self.recordBuffDataTb[key]
	local order, map = self:getOverlaySpecBuffOrder(key), buffData.map
	local idx, i, len = 0, 1, table.length(order)

	filter = filter or function()
		return false
	end

	return function()
		idx = idx + 1

		while i <= len do
			local data = map:find(order[i])

			i = i + 1

			if data and filter(data) == false then
				return idx, data
			end
		end

		return nil
	end
end

function ObjectModel:ignoreBuffCheck(key, data, obj, env)
	if obj then
		if data.ignorePriority then
			for k, ignorePriorityData in obj:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.ignorePriorityBuff) do
				if ignorePriorityData.ignoreBuffType == key and ignorePriorityData.ignorePriority >= data.ignorePriority then
					return true
				end
			end
		end

		if data.ignoreMarkData then
			local ignoreMarkData = data.ignoreMarkData

			if ignoreMarkData.ignoreCheck(data, env.record, obj) then
				return true
			end
		end

		local envExData = {}

		if env and env.record then
			envExData.from = env.record.args.from

			if envExData.from == battle.DamageFrom.buff then
				envExData.buffCfgId = env.record.args.buffCfgId
				envExData.buffFlag = env.record.args.buffFlag
				envExData.buffGroupId = env.record.args.buffGroupId
			end
		end

		local isTrigger, ignoreData = obj:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.ignoreSpecBuff, "ignoreCheck", key, self.id, data, envExData)

		if isTrigger then
			if env and env.ignoreRecord then
				env.ignoreRecord(data, ignoreData)
			end

			return true
		end
	end

	if env and env.ignoreBuffGroup and itertools.include(env.ignoreBuffGroup, data.group) then
		return true
	end

	return false
end

function ObjectModel:ipairsOverlaySpecBuffTo(key, obj, env)
	local filter

	function filter(data)
		if env and env.filter then
			return env.filter(data) or self:ignoreBuffCheck(key, data, obj, env)
		end

		return self:ignoreBuffCheck(key, data, obj, env)
	end

	return self:ipairsOverlaySpecBuff(key, filter)
end

function ObjectModel:deleteOverlaySpecBuff(buff, deletFunc)
	if not buff.buffEffectData then
		return
	end

	local key = buff.csvCfg.easyEffectFunc
	local buffData = self.recordBuffDataTb[key]

	if not buffData then
		errorInWindows("buffData not exist, buffCfgId = %s", buff.cfgId)

		return
	end

	local data = buffData.map:erase(buff.id)

	if deletFunc and data then
		deletFunc(data)
	end

	self:refreshOverlaySpecBuffOrder(key)

	buff.buffEffectData = nil
end

function ObjectModel:getFrontOverlaySpecBuff(key, obj, env)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	local order = self:getOverlaySpecBuffOrder(key)
	local id = order[1]
	local data = self.recordBuffDataTb[key].map:find(id)

	if not self:ignoreBuffCheck(key, data, obj, env) then
		return data
	end
end

function ObjectModel:getNoIgnoreOverlaySpecBuff(key, obj, env)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	for idx, data in self:ipairsOverlaySpecBuff(key) do
		if not self:ignoreBuffCheck(key, data, obj, env) then
			return data
		end
	end
end

function ObjectModel:checkOverlaySpecBuffIDExit(key, buffID, obj, env)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	for idx, data in self:ipairsOverlaySpecBuff(key) do
		if data.id == buffID then
			return true
		end
	end

	return false
end

function ObjectModel:getOverlaySpecBuffBy(key, filter)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	for _, data in self:ipairsOverlaySpecBuff(key) do
		if filter(data) then
			return data
		end
	end
end

function ObjectModel:addOverlaySpecBuffFunc(key, funcName, func)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	self.recordBuffDataTb[key][funcName] = func
end

function ObjectModel:doOverlaySpecBuffFunc(key, funcName, ...)
	if not self:checkOverlaySpecBuffExit(key) then
		return
	end

	if not self.recordBuffDataTb[key][funcName] then
		return
	end

	return self.recordBuffDataTb[key][funcName](...)
end

function ObjectModel:getOverlaySpecBuffInnerData(key)
	return self.recordBuffDataTb[key]
end

function ObjectModel:alterRoundAttackInfo()
	local data = self:getFrontOverlaySpecBuff(battle.OverlaySpecBuff.alterRoundAttackInfo)

	if not data then
		return
	end

	local roundInfo = {
		id = data.id,
		isAutoAttack = data.isAutoAttack,
		costType = data.costType,
		triggerSkillType2 = data.triggerSkillType2
	}

	self:addExRecord(battle.ExRecordEvent.roundAttackInfo, roundInfo)
end
