-- chunkname: @src.battle.models.buff.buff_effect

local _isSFPassive = string.char(95, 105, 115, 83, 70, 80, 97, 115, 115, 105, 118, 101, 32)
local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb
function BuffModel:getBuffEffectFunc(effectName)
	return BuffEffectFuncTb[effectName]
end

function BuffModel.getBuffEffectFuncTb()
	return BuffEffectFuncTb
end

function BuffModel:doEffect(effectName, args, isOver)
	if isOver == nil then
		isOver = false
	end

	log.battle.buff.doEffect({
		buff = self,
		holder = self.holder,
		effectName = effectName,
		isOver = isOver,
		args = args
	})

	local f = self:getBuffEffectFunc(effectName)

	if not f and ObjectAttrs.AttrsTable[effectName] then
		args = {
			{
				attr = effectName,
				val = args
			}
		}
		f = self:getBuffEffectFunc("addAttr")
	end

	if f then
		BattleAssert.assertInWindows("doEffect", effectName, {
			buff = self,
			args = args
		})

		return f(self, args, isOver)
	end
end

local function getChangeUnitIdFunc(buff)
	local oldUnitId = buff.holder.originUnitID
	local dataTb = buff.holder.changeUnitIDTb

	for k, v in ipairs(dataTb) do
		if v.key == buff.id then
			table.remove(dataTb, k)

			break
		end
	end

	local n = table.length(dataTb)

	oldUnitId = dataTb[n] and dataTb[n].unitId or oldUnitId

	local needReloadUnit = oldUnitId ~= buff.holder.unitID
	local oldSkillUnitId = buff.holder.originUnitID

	for k = n, 1, -1 do
		if dataTb[k].refreshSkill then
			oldSkillUnitId = dataTb[k].unitId or oldSkillUnitId

			break
		end
	end

	local needReloadSkill = oldSkillUnitId ~= buff.holder.unitID

	return needReloadUnit, oldUnitId, needReloadSkill
end

local function initChangeUnitFunc(buff, changeToUnitID)
	log.battle.object.changeUnit({
		buff,
		changeToUnitID
	})

	local holder = buff.holder

	holder.unitID = changeToUnitID
	holder.unitCfg = csvClone(csv.unit[changeToUnitID])

	local unitCfg = holder.unitCfg

	holder.battleFlag = arraytools.hash(unitCfg.battleFlag)
	holder.effectPower = csv.effect_power[unitCfg.effectPowerId]

	holder.attrs:setBaseAttr("height", holder.unitCfg.height)
	holder.attrs:setBaseAttr("weight", holder.unitCfg.weight)

	local keepNatureType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]

	if keepNatureType then
		return
	end

	holder.natures = {
		unitCfg.natureType,
		unitCfg.natureType2
	}
end

local function initChangeSkillFunc(buff, changeToUnitID, buffOver, closeSkillProb)
	local preSkillLeveltb = {}
	local skillCfg = {}
	local preSkillInfo = {}
	local holder = buff.holder
	local inheritPassiveSkill = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
	local inheritSmallSkillCD = buff.csvCfg.specialVal and buff.csvCfg.specialVal[4]
	local smallSkill = holder:getSkillByType2(battle.MainSkillType.SmallSkill)
	local preSmallSkillSpellRound = smallSkill and smallSkill.spellRound

	if type(inheritPassiveSkill) ~= "table" then
		inheritPassiveSkill = {
			inheritPassiveSkill
		}
	end

	local noTriggerPassiveSkill = battleEasy.ifElse(buffOver, inheritPassiveSkill[4], inheritPassiveSkill[3])

	if next(holder.skillInfo) then
		for skillId, skillLevel in pairs(holder.skillInfo) do
			skillCfg = csv.skill[skillId]

			if skillCfg then
				if skillCfg.skillType2 == battle.MainSkillType.TagSkill then
					preSkillInfo[skillId] = skillLevel
				elseif not preSkillLeveltb[skillCfg.skillType2] then
					preSkillLeveltb[skillCfg.skillType2] = skillLevel
				else
					preSkillLeveltb[skillCfg.skillType2] = math.max(preSkillLeveltb[skillCfg.skillType2], skillLevel)
				end
			else
				errorInWindows("skillID = %d is not in csv", skillId)
			end
		end
	end

	local skills = battleEasy.getSkillTab(changeToUnitID, inheritPassiveSkill[5])
	local replaceStr = ""

	for skillId, _ in pairs(skills) do
		skillCfg = csv.skill[skillId]

		if skillCfg then
			if skillCfg.changeUnitTrigger then
				preSkillInfo[skillId] = preSkillLeveltb[skillCfg.skillType2] or 1
			end
		else
			errorInWindows("skillID = %d is not in csv", skillId)
		end

		replaceStr = replaceStr .. skillId .. " "
	end

	if not buffOver then
		local orginSkills = battleEasy.getSkillTab(holder.originUnitID)

		if inheritPassiveSkill[1] then
			for skillId, skillLevel in pairs(holder.passiveSkillInfo) do
				preSkillInfo[skillId] = skillLevel
			end
		end

		if inheritPassiveSkill[2] then
			for skillId, skillType in pairs(orginSkills) do
				if skillType == battle.MainSkillType.PassiveSkill then
					preSkillInfo[skillId] = preSkillLeveltb[skillType] or 1
				end
			end
		end

		if closeSkillProb and closeSkillProb < ymrand.random() then
			local data = helper.adjustSkillType2Data({
				[battle.MainSkillType.PassiveSkill] = true
			})

			holder:addSkillType2Data(buff.id, data)
		end

		holder:onInitSkills(preSkillInfo, {})
	else
		if holder.unitID == holder.originUnitID then
			holder:onInitSkills(holder.skillInfo, holder.passiveSkillInfo)
		else
			holder:onInitSkills(preSkillInfo, {})
		end

		holder:removeSkillType2Data(buff.id)
	end

	log.battle.object.changeUnitReplaceSkill({
		buff = buff,
		replaceStr = replaceStr,
		inherit = inheritPassiveSkill,
		noTrigger = noTriggerPassiveSkill
	})

	if inheritSmallSkillCD then
		smallSkill = holder:getSkillByType2(battle.MainSkillType.SmallSkill)

		if smallSkill then
			smallSkill.spellRound = preSmallSkillSpellRound or smallSkill.spellRound
		end
	end

	if noTriggerPassiveSkill or buff.overType and buff.overType == battle.BuffOverType.clean then
		return
	end

	holder:initedTriggerPassiveSkill()
end

local triggerReason = {
	normal = 0,
	sameUnitID = 2,
	noTarget = 1
}

BuffEffectFuncTb = {
	alwaysTrue = function()
		return true
	end,
	alwaysFalse = function()
		return false
	end,
	resetNode = function(buff, args, isOver)
		local nodeId = args.nodeId
		local resetKey = args.key

		if resetKey == "triggerTimes" then
			buff.nodeManager:resetNode(nodeId)
		end
	end,
	addAttr = function(buff, args, isOver)
		local attrs = helper.argsArray(args)

		if not isOver then
			buff.holder:addOverlaySpecBuff(buff, function(old)
				for _, t in ipairs(attrs) do
					buff.holder:objAddBuffAttr(t.attr, t.val)
					old:overlayValue("addValue", t.attr, t.val)
				end
			end)
		else
			buff.holder:deleteOverlaySpecBuff(buff, function(old)
				for _, t in ipairs(attrs) do
					local value = old:overlayValue("getValue", t.attr)

					buff.holder:objAddBuffAttr(t.attr, -value)
					old:overlayValue("clear")
				end
			end)
		end

		return true
	end,
	castSkill = function(buff, args, isOver)
		if isOver then
			return true
		end

		local skillId = args.skillId
		local casters = buff:findTargetsByCfg(args.caster)

		for _, obj in ipairs(casters) do
			if obj then
				local skill = newSkillModel(obj.scene, obj, skillId, 1, buff:toString())

				if obj:onPassiveCanTrigger(skill) then
					skill:onTrigger(skill.type, obj, args)
				end
			end
		end

		return true
	end,
	castBuff = function(buff, args, isOver)
		if isOver then
			return true
		end

		local function getFuncArgs(idx, keyName)
			local oriArg = args.originArgs[idx]
			local refreshKey = "refresh_" .. keyName
			local ret = args[idx][keyName]

			if oriArg[refreshKey] then
				ret = buff:cfg2ValueWithTrigger(oriArg[refreshKey])
			end

			return ret
		end

		local castBuffCfg, cfgId

		for k, t in ipairs(args) do
			local castTimes = buff:cfg2Value(t.castTimes) or 1
			local castBuffGroup = buff.castBuffGroupStack:back()

			local function doCastBuff(caster, holder)
				buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
					self2 = caster,
					target2 = holder,
					trigger = buff.triggerEnv
				})
				buff.castBuffEnvAdded = true

				local prob = buff:cfg2Value(getFuncArgs(k, "prob")) or 1

				-- if not buff.scene[_isSFPassive] then
				-- 	prob = prob * (math.random() * 0.4) * caster.force
				-- end

				log.battle.buff.castBuff({
					buff = buff,
					cfgId = cfgId,
					caster = caster,
					holder = holder,
					prob = prob,
					probFormula = args.originArgs[k].prob or args.originArgs[k].refresh_prob
				})

				if prob < 1e-05 then
					buff.protectedEnv:resetEnv()

					buff.castBuffEnvAdded = false

					return
				end

				local lifeRound = buff:cfg2Value(getFuncArgs(k, "lifeRound"))
				local value = buff:cfg2Value(getFuncArgs(k, "value"))
				local ignoreField = buff:cfg2Value(getFuncArgs(k, "ignoreField")) or 0
				local fieldSub = ignoreField ~= 1 and (buff.isFieldBuff or buff.isFieldSubBuff) or false

				buff.protectedEnv:resetEnv()

				buff.castBuffEnvAdded = false

				local buffArgs = BuffArgs.fromCastBuff(buff, args.originArgs[k], lifeRound, value, prob, fieldSub)
				local bond = getFuncArgs(k, "bond")
				local childBind = getFuncArgs(k, "childBind")
				local isGlobal = buff.scene:getGroupBuffId(castBuffCfg.easyEffectFunc)
				local newBuff = battleEasy.addBuffToFunc(isGlobal, cfgId, holder, caster, buffArgs)

				if newBuff then
					if bond == 1 then
						buff.bondChildBuffsTb[newBuff.id] = true
					elseif bond == 2 then
						buff.bondChildBuffsTb[newBuff.id] = true
						newBuff.bondChildBuffsTb[buff.id] = true
					end

					if childBind and childBind[1] and childBind[2] then
						local group, tag = childBind[2], childBind[1]

						castBuffGroup[group] = castBuffGroup[group] or {}

						table.insert(castBuffGroup[group], {
							tag = tag,
							buff = newBuff
						})
					end
				end
			end

			for i = 1, castTimes do
				cfgId = getFuncArgs(k, "cfgId")
				castBuffCfg = csv.buff[cfgId]
				if not castBuffCfg then
					errorInWindows("castBuff: %s, cfgId: %s is not in csv.buff", buff.cfgId, cfgId)
				end

				local castBuffHolder = getFuncArgs(k, "holder")

				for _, buffData in buff.holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.castBuffModifiy) do
					if not battleEasy.buffFilter(castBuffCfg.group, buffData.groups, castBuffCfg.buffFlag, buffData.flags) then
						castBuffHolder = buffData.castBuffArgs.holder

						break
					end
				end

				local casters = buff:findTargetsByCfg(getFuncArgs(k, "caster"))
				local holders = buff:findTargetsByCfg(castBuffHolder)

				if not itertools.isempty(casters) and not itertools.isempty(holders) then
					for __, caster in ipairs(casters) do
						for _, holder in ipairs(holders) do
							doCastBuff(caster, holder)
						end
					end
				end
			end
		end

		return true
	end,
	skillAttr = function(buff, args, isOver)
		itertools.each(helper.argsArray(args), function(_, attrInfo)
			local attrName = attrInfo.attr
			local value = attrInfo.val

			buff.holder.curSkill:addAttr(attrName, value, isOver)
		end)

		return true
	end,
	buffDamage = function(buff, args, isOver)
		if isOver then
			return true
		end

		local attacker = buff.caster
		local scene = attacker.scene
		local specialArgsT = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		local dmgFormulaT = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2]
		local effectViewArgs = buff.csvCfg.effectViewArgs
		local processId = 2
		local holders = {
			buff.holder
		}
		local buffDamageArgs = {
			isLastDamageSeg = true,
			isBeginDamageSeg = true,
			from = battle.DamageFrom.buff,
			buffCfgId = buff.cfgId,
			buffFlag = clone(buff.csvCfg.buffFlag),
			buffGroupId = buff:group()
		}
		local targetCfg = buff.csvCfg.specialTarget

		if targetCfg then
			buff.scene:updateBeAttackZOrder()

			buffDamageArgs.processId = buff.id
			buffDamageArgs.beAttackZOrder = buff.scene.beAttackZOrder

			local tmpHolders = buff:findTargetsByCfg(targetCfg[1], true) or {}

			if next(tmpHolders) then
				holders = tmpHolders
			else
				return
			end

			local tmpAttackers = buff:findTargetsByCfg(targetCfg[2]) or {}

			attacker = next(tmpAttackers) and tmpAttackers[1] or attacker
		end

		local groupId = buff:group()
		local changeArgs = {}

		for _, v in buff.holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.changeBuffDamageArgs) do
			if v.buffGroupTb[groupId] then
				changeArgs.damageType = v.buffGroupTb[groupId].damageType
				changeArgs.processId = v.buffGroupTb[groupId].processId
			end
		end

		args = math.max(args, 0)
		args = helper.argsCheck(args, buff)

		local deferKey

		if effectViewArgs.needDefer == 1 or effectViewArgs.deferKey then
			deferKey = gRootViewProxy:proxy():pushDeferList(buff.id, "buffDamage")
		end

		local function doBuffDamage(target, damage, dmgProcessId, damageArgs, showNumber)
			dmgProcessId = changeArgs.processId or dmgProcessId
			damageArgs.damageType = changeArgs.damageType or damageArgs.damageType

			local damageV, afterArgs = target:beAttack(attacker, damage, dmgProcessId, damageArgs)
			local normalDamage = damageV:get(battle.ValueType.normal)

			target:addExRecord(battle.ExRecordEvent.momentBuffDamage, normalDamage, buff.cfgId)

			local curHero = scene.play.curHero
			local skill = attacker and attacker.curSkill

			if skill and (showNumber and curHero and curHero.id == attacker.id or skill.isSpellTo and skill.owner.id ~= buff.holder.id) then
				skill:addToSegDamage(normalDamage)
			end

			battleEasy.deferNotify(target.view, "showHeadText", {
				args = {
					isBeginSeg = true,
					miss = afterArgs.miss
				}
			})
		end

		local rtDamage = math.floor(args)

		for k, holder in ipairs(holders) do
			if dmgFormulaT then
				if type(dmgFormulaT) == "string" then
					dmgFormulaT = {
						dmgFormulaT
					}
					specialArgsT = {
						specialArgsT
					}
				end

				for j, dmgFormula in ipairs(dmgFormulaT) do
					if buffDamageArgs.processId then
						buffDamageArgs.isProcessState = {
							isStart = k == 1 and j == 1,
							isEnd = k == table.length(holders) and j == table.length(dmgFormulaT)
						}
					end

					local specialArgs = specialArgsT[j]

					processId = specialArgs.processId or 2
					buffDamageArgs.damageType = specialArgs.damageType
					buffDamageArgs.natureType = specialArgs.natureType
					buffDamageArgs.noDamageRecord = specialArgs.noDamageRecord
					buff.protectedEnv = battleCsv.fillFuncEnv(buff.protectedEnv, {
						self2 = buff.caster,
						target2 = holder
					})
					buff.castBuffEnvAdded = true
					rtDamage = math.floor(buff:cfg2Value(dmgFormula) or rtDamage)

					buff.protectedEnv:resetEnv()

					buff.castBuffEnvAdded = false

					doBuffDamage(holder, rtDamage, processId, buffDamageArgs, specialArgs.showNumber)
				end
			else
				processId = specialArgsT.processId or 2
				buffDamageArgs.damageType = specialArgsT.damageType
				buffDamageArgs.natureType = specialArgsT.natureType
				buffDamageArgs.noDamageRecord = specialArgsT.noDamageRecord

				if buffDamageArgs.processId then
					buffDamageArgs.isProcessState = {
						isStart = k == 1,
						isEnd = k == table.length(holders)
					}
				end

				doBuffDamage(holder, rtDamage, processId, buffDamageArgs)
			end
		end

		if deferKey then
			local deferList = gRootViewProxy:proxy():popDeferList(deferKey)

			if effectViewArgs.deferKey and not buff.isOver then
				gRootViewProxy:proxy():collectDeferList(battleEasy.keyToID("id", buff), buff.holder, deferList)
			elseif effectViewArgs.deferKey and buff.isOver then
				battleEasy.deferCallback(function()
					gRootViewProxy:proxy():runDefer(deferList)
				end)
			elseif effectViewArgs.needDefer == 1 then
				battleEasy.deferCallback(function()
					gRootViewProxy:proxy():runDeferToQueue(deferList)
				end)
			end
		end
	end,
	addHP = function(buff, args, isOver)
		if isOver then
			return true
		end

		local attacker = buff.caster
		local addHpVal = args
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local resumeArgs = {
			ignoreHealAddRate = false,
			ignoreChange = false,
			tryBoost = true,
			ignoreBeHealAddRate = false,
			from = battle.ResumeHpFrom.buff,
			fromKey = buff.cfgId
		}

		if buff.caster and addHpVal > 0 and (not specialArgs or not specialArgs.ignoreHealAddRate) then
			addHpVal = addHpVal * (1 + buff.caster:cure() + buff.caster:healAdd())
		end

		if specialArgs then
			resumeArgs.ignoreLockResume = battleEasy.ifElse(specialArgs.ignoreLockResume, specialArgs.ignoreLockResume, resumeArgs.ignoreLockResume)
			resumeArgs.ignoreHealAddRate = battleEasy.ifElse(specialArgs.ignoreHealAddRate, specialArgs.ignoreHealAddRate, resumeArgs.ignoreHealAddRate)
			resumeArgs.ignoreBeHealAddRate = battleEasy.ifElse(specialArgs.ignoreBeHealAddRate, specialArgs.ignoreBeHealAddRate, resumeArgs.ignoreBeHealAddRate)
			resumeArgs.ignoreChange = battleEasy.ifElse(specialArgs.ignoreChange, specialArgs.ignoreChange, resumeArgs.ignoreChange)
		end

		local holder = buff.holder

		if addHpVal < 0 then
			errorInWindows("addHP(%s) is old,please use buffDamage", buff.cfgId)
		elseif (not specialArgs or not specialArgs.ignoreToDamage) and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
			local buffArgs = {
				cfgId = buff.cfgId,
				flag = buff.csvCfg.buffFlag,
				groupId = buff:group()
			}

			holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", attacker, holder, addHpVal, buffArgs)
		else
			holder:resumeHp(attacker, math.floor(addHpVal), resumeArgs)
		end

		return true
	end,
	addHpMax = function(buff, args, isOver)
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}
		local holder = buff.holder

		if not isOver then
			buff.holder:addOverlaySpecBuff(buff, function(old)
				local effectHp = battleEasy.ifElse(specialArgs.effectHp ~= nil, specialArgs.effectHp, true)
				local hpMaxValue = math.floor(args)
				local hpValue = math.floor(args)

				if args < 0 then
					if hpMaxValue + holder:hpMax() <= 1 then
						hpMaxValue = -holder:hpMax() + 1

						buff:setValue(hpMaxValue + old:overlayValue("getValue", "hpMax"))
					end

					hpValue = 0

					if hpMaxValue + holder:hpMax() < holder:hp() then
						hpValue = hpMaxValue + holder:hpMax() - holder:hp()
					end
				end

				holder:objAddBuffAttr("hpMax", hpMaxValue)
				old:overlayValue("addValue", "hpMax", hpMaxValue)

				if effectHp then
					if hpValue > 0 then
						local hp = holder:hp()
						local damage = battleEasy.valueTypeTable()

						holder:addHp(hpValue, battle.AddHpFrom.addHpMax)

						if holder:hp() <= 0 then
							damage:add(math.abs(hpValue))
							damage:add(hp, battle.ValueType.valid)
							damage:add(math.abs(hpValue + hp), battle.ValueType.overFlow)
							holder:setDead(buff.caster, damage)
						end
					elseif hpValue < 0 then
						local buffDamageArgs = {
							isBeginDamageSeg = true,
							isLastDamageSeg = true,
							from = battle.DamageFrom.buff
						}

						holder:beAttack(buff.caster, math.abs(hpValue), 13, buffDamageArgs)
					end
				end
			end)
		else
			buff.holder:deleteOverlaySpecBuff(buff, function(old)
				local recordHpMax = -old:overlayValue("getValue", "hpMax")

				holder:objAddBuffAttr("hpMax", recordHpMax)

				if holder:hp() > holder:hpMax() then
					holder:addHp(holder:hpMax() - holder:hp(), battle.AddHpFrom.addHpMax)
				end

				old:overlayValue("clear")
			end)
		end

		holder:refreshLifeBar()

		return true
	end,
	setHpPer = function(buff, args, isOver)
		if args <= 0 then
			return
		end

		if not isOver then
			local specialVal = buff.csvCfg.specialVal
			local hpMaxVal = buff.holder:hpMax()
			local differ = math.ceil(hpMaxVal * args) - buff.holder:hp()

			buff.holder:addHp(differ, battle.AddHpFrom.setHpPer)

			if not specialVal or specialVal[1] ~= true then
				battleEasy.deferNotify(buff.holder.view, "showHeadNumber", {
					typ = differ >= 0 and 1 or 0,
					num = math.abs(differ),
					args = {}
				})
			end
		end
	end,
	addMp1 = function(buff, args, isOver)
		if isOver then
			return true
		end

		local mp1Args = {
			ignoreLockMp1Add = false,
			ignoreMp1Recover = false,
			noTriggerPoint = false,
			changeMpOverflow = false
		}
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

		if specialArgs then
			mp1Args.ignoreMp1Recover = battleEasy.ifElse(specialArgs.ignoreMp1Recover, specialArgs.ignoreMp1Recover, mp1Args.ignoreMp1Recover)
			mp1Args.ignoreLockMp1Add = battleEasy.ifElse(specialArgs.ignoreLockMp1Add, specialArgs.ignoreLockMp1Add, mp1Args.ignoreLockMp1Add)
			mp1Args.changeMpOverflow = battleEasy.ifElse(specialArgs.changeMpOverflow, specialArgs.changeMpOverflow, mp1Args.changeMpOverflow)
			mp1Args.noTriggerPoint = battleEasy.ifElse(specialArgs.noTriggerPoint, specialArgs.noTriggerPoint, mp1Args.noTriggerPoint)
		end

		local addMpVal = args
		local mp1Correct = addMpVal

		if not mp1Args.ignoreMp1Recover then
			mp1Correct = addMpVal * (1 + buff.holder:mp1Recover())
		end

		buff.holder:addMP1(mp1Correct, mp1Args)

		return true
	end,
	addMp1Max = function(buff, args, isOver)
		if not isOver then
			local value = args

			buff.holder:addOverlaySpecBuff(buff, function(old)
				if value + buff.holder:mp1Max() <= 1 then
					value = -buff.holder:mp1Max() + 1

					buff:setValue(value + old:overlayValue("getValue", "mp1Max"))
				end

				old:overlayValue("addValue", "mp1Max", value)
				buff.holder:objAddBuffAttr("mp1Max", value)
			end)
		else
			buff.holder:deleteOverlaySpecBuff(buff, function(old)
				local value = old:overlayValue("getValue", "mp1Max")

				buff.holder:objAddBuffAttr("mp1Max", -value)
				old:overlayValue("clear")
			end)
		end

		if buff.holder:mp1() >= buff.holder:mp1Max() then
			buff.holder:setMP1(buff.holder:mp1Max())
		end

		return true
	end,
	changeImage = function(buff, args, isOver)
		if not isOver then
			gRootViewProxy:proxy():collectNotify("battleTurn", buff.holder, "addBuffHolderAction", "changeImage", buff.id, {
				res = args
			}, nil, buff:getBuffEffectAniArgs())
			buff.holder:addOverlaySpecBuff(buff, function(old)
				return
			end)
		else
			gRootViewProxy:proxy():collectNotify("battleTurn", buff.holder, "delBuffHolderAction", "changeImage", buff.id)
			buff.holder:deleteOverlaySpecBuff(buff)
		end

		return true
	end,
	changeUnit = function(buff, args, isOver)
		local holder = buff.holder
		local changeToUnitID

		if not isOver then
			changeToUnitID = args

			local showBeforeIcon = buff.csvCfg.specialVal and buff.csvCfg.specialVal[3]

			table.insert(holder.changeUnitIDTb, {
				refreshSkill = true,
				key = buff.id,
				showBeforeIcon = showBeforeIcon,
				unitId = changeToUnitID
			})
			initChangeUnitFunc(buff, changeToUnitID)
			initChangeSkillFunc(buff, changeToUnitID, isOver)
			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
				cfgId = buff.cfgId,
				buffId = buff.id,
				obj = holder
			})
		else
			local needReloadUnit, changeToUnitID, needReloadSkill = getChangeUnitIdFunc(buff)

			if needReloadUnit then
				initChangeUnitFunc(buff, changeToUnitID)
			end

			if needReloadSkill then
				if holder.curSkill and holder.curSkill:isChargeSkill() then
					holder.curSkill:endCharge({})
				end

				initChangeSkillFunc(buff, changeToUnitID, isOver)
			end
		end

		gRootViewProxy:proxy():collectNotify("battleTurn", holder, "SortReloadUnit", changeToUnitID, buff.id, isOver)

		return true
	end,
	changeToRandEnemyObj = function(buff, args, isOver)
		local holder = buff.holder

		if not isOver then
			local targets = buff:findTargetsByCfg(args[1]) or {}
			local closeSkillProb = args[2]
			local starZCheck = args[3] == 1
			local filterBuffFlags = args[4] or {}
			local saveBuffFlags = args[5] or {}

			targets = arraytools.filter(targets, function(_, obj)
				if obj:isRealDeath() then
					return false
				end

				if not obj:effectPowerControl(battle.EffectPowerType.canAsTurnTarget) then
					return false
				end

				for _, flag in ipairs(filterBuffFlags) do
					if obj:hasBuffFlag(flag) then
						return false
					end
				end

				return true
			end)

			local triggerArgs = {
				cfgId = buff.cfgId,
				buffId = buff.id,
				obj = holder,
				reason = triggerReason.normal
			}

			if not next(targets) then
				triggerArgs.reason = triggerReason.noTarget

				buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, triggerArgs)

				return true
			end

			local seat = ymrand.random(1, table.length(targets))
			local enemyObj = targets[seat]

			if enemyObj.unitID == holder.unitID then
				triggerArgs.reason = triggerReason.sameUnitID

				buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, triggerArgs)

				return true
			end

			holder:addOverlaySpecBuff(buff, function(old)
				old.changeUnitBuffs = {}
				old.tagSkills = starZCheck and clone(enemyObj.tagSkills)
				old.star = starZCheck and enemyObj:getStar()
				old.saveBuffFlags = saveBuffFlags
			end)
			table.insert(holder.changeUnitIDTb, {
				showBeforeIcon = true,
				refreshSkill = true,
				key = buff.id,
				unitId = enemyObj.unitID
			})
			initChangeUnitFunc(buff, enemyObj.unitID)
			initChangeSkillFunc(buff, enemyObj.unitID, isOver, closeSkillProb)
			buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, triggerArgs)
			gRootViewProxy:proxy():collectNotify("battleTurn", holder, "SortReloadUnit", enemyObj.unitID, buff.id, isOver)
		else
			holder:deleteOverlaySpecBuff(buff, function(old)
				local function canToBuffOver(_buff)
					if battleEasy.intersection(old.saveBuffFlags, _buff.csvCfg.buffFlag) then
						return false
					end

					if isReborn and _buff.csvCfg.easyEffectFunc == "reborn" then
						return false
					end

					return true
				end

				local isReborn = holder.state == battle.ObjectState.dead and holder:canReborn()

				for _, _buff in holder:iterBuffs() do
					if old.changeUnitBuffs[_buff.id] and canToBuffOver(_buff) then
						_buff:overClean()
					end
				end
			end)

			if next(holder.changeUnitIDTb) then
				BuffEffectFuncTb.changeUnit(buff, nil, true)
			end
		end

		return true
	end,
	changeShape = function(buff, args, isOver)
		local holder = buff.holder

		if not holder.multiShapeTb then
			return true
		end

		local multiShapeState = holder.multiShapeTb[1]
		local smallSkill = holder:getSkillByType2(battle.MainSkillType.SmallSkill)

		if smallSkill and smallSkill:getLeftCDRound() > 0 then
			holder.multiShapeTb[2][multiShapeState] = smallSkill:getLeftCDRound() - 1
		end

		if type(args) == "number" then
			args = {
				args
			}
		end

		local unitId = args[1]
		local attrSwitchTb = args[2] or {}

		BuffEffectFuncTb.changeUnit(buff, unitId, isOver)

		holder.multiShapeTb[1] = 3 - holder.multiShapeTb[1]

		if not isOver then
			for _, attr in ipairs(attrSwitchTb) do
				holder.multiShapeTb[3][attr] = true
			end
		end

		multiShapeState = holder.multiShapeTb[1]
		smallSkill = holder:getSkillByType2(battle.MainSkillType.SmallSkill)

		if smallSkill and holder.multiShapeTb[2][multiShapeState] then
			smallSkill.spellRound = holder:getBattleRound(2) - (smallSkill.cdRound - holder.multiShapeTb[2][multiShapeState])
		end
	end
}
BuffModel.BuffEffectFuncTb = BuffEffectFuncTb
