-- chunkname: @src.battle.models.buff.buff_effect3

local helper = require("battle.models.buff.helper")
local BuffEffectFuncTb = BuffModel.BuffEffectFuncTb

function BuffEffectFuncTb.lockMp1Add(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.recordVal = 0
			old.limit = args or 0
		end, function(a, b)
			if a.limit == b.limit then
				return a.id < b.id
			else
				return a.limit < b.limit
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.lockMp1Reduce(buff, args, isOver)
	BuffEffectFuncTb.lockMp1Add(buff, args, isOver)
end

function BuffEffectFuncTb.transformMpchange(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args[1] or 1
			old.transformMpCount = args[2] or 1
			old.transformMpPer = args[3] or 1
		end)
		buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			obj = holder,
			buffId = buff.id
		})
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.transferMp(buff, args, isOver)
	local holder = buff.holder
	local target = buff.caster

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.target = target
			old.percent = args[1] or 1
			old.priority = args[2] or 1
		end, function(buffA, buffB)
			if buffA.priority == buffB.priority then
				return buffA.id < buffB.id
			else
				return buffA.priority > buffB.priority
			end
		end)
		holder:addOverlaySpecBuffFunc(battle.OverlaySpecBuff.transferMp, "checkCanTransfer", function(mpValue, args)
			if target:isDeath() then
				return false
			end

			if battleEasy.isCompleteLeave(target) then
				return false
			end

			if buff.scene:isBackHeros(target) then
				return false
			end

			if args.transferChainIds and args.transferChainIds[target.id] then
				return false
			end

			if mpValue <= 0 then
				return false
			end

			return true
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.lockResumeHp(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			return
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.cantRecoverMp(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.mode = args[1] or 0
			old.buffGroups = args[2] or {}
			old.buffIds = args[3] or {}
			old.skillIds = args[4] or {}
			old.natures = args[5] or {}
		end, function(a, b)
			if a.mode == b.mode then
				return a.id < b.id
			else
				return a.mode < b.mode
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.cantRecoverSkillMp(buff, args, isOver)
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

function BuffEffectFuncTb.suckMp(buff, args, isOver)
	if not isOver then
		local subMpValue = args[1]
		local addMpRate = args[2]
		local beSuckMpValue = subMpValue < buff.holder:mp1() and subMpValue or buff.holder:mp1()
		local suckMpValueCorrect = beSuckMpValue * addMpRate * (1 + buff.caster:mp1Recover())
		local setMp1Args = {
			recoverfromSuckMp = true,
			casterID = buff.caster.id
		}

		buff.holder:addMP1(-beSuckMpValue, setMp1Args)
		buff.caster:addMP1(suckMpValueCorrect, setMp1Args)
	end

	return true
end

function BuffEffectFuncTb.shield(buff, args, isOver)
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
			old.showType = buff.csvCfg.specialVal and buff.csvCfg.specialVal[2] or 0
			old.ignorePriority = buff.csvCfg.specialVal and buff.csvCfg.specialVal[3] or 10

			local timeArray = buff.csvCfg.specialVal and buff.csvCfg.specialVal[4]

			if timeArray then
				old.lifeRoundType = timeArray[1]
				old.lifeTimeEnd = timeArray[2]
				old.reduceRate = timeArray[3]
			end
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			old.shieldMaxTotal = old.shieldMaxTotal - old.shieldHpMax
			old.shieldTotal = old.shieldTotal - old.shieldHp
		end)
	end

	buff.holder:refreshShield()

	return true
end

function BuffEffectFuncTb.addShield(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local changeShieldBuffGroupList = arraytools.hash(args[1])
		local changeShieldValue = args[2] or 0

		holder:addShieldHp(changeShieldValue, {
			filterBuffGroups = function(buffGroup)
				if not changeShieldBuffGroupList or changeShieldBuffGroupList[buffGroup] then
					return true
				end
			end
		})
		holder:refreshShield()
	end

	return true
end

function BuffEffectFuncTb.freeze(buff, args, isOver)
	local changeHpVal = args
	local holder = buff.holder

	if not isOver then
		changeHpVal = math.min(changeHpVal, holder:hp() - (holder.freezeHp or 0))
		holder.freezeHp = (holder.freezeHp or 0) + changeHpVal

		holder:addOverlaySpecBuff(buff, function(old)
			old.cfgId = buff.cfgId
			old.freezeHp = changeHpVal
		end, nil)
	else
		local delHp = 0

		for _, data in holder:ipairsOverlaySpecBuff(battle.OverlaySpecBuff.freeze) do
			if data.cfgId == buff.cfgId then
				delHp = data.freezeHp

				break
			end
		end

		holder:deleteOverlaySpecBuff(buff)

		holder.freezeHp = holder.freezeHp - delHp

		if holder.freezeHp <= 0 or not holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.freeze) then
			holder.freezeHp = 0
		end
	end

	return true
end

function BuffEffectFuncTb.stun(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			return
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.sleepy(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		buff:setValue(args or 1)
		holder:addOverlaySpecBuff(buff, function(old)
			old:bind("time", "value")
		end, nil)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.immunePhysicalDamage(buff, args, isOver)
	if not isOver then
		buff.holder.beInImmunePhysicalDamageState = buff.holder.beInImmunePhysicalDamageState and buff.holder.beInImmunePhysicalDamageState + 1 or 1
	else
		buff.holder.beInImmunePhysicalDamageState = buff.holder.beInImmunePhysicalDamageState and buff.holder.beInImmunePhysicalDamageState - 1 or 0
		buff.holder.beInImmunePhysicalDamageState = math.max(buff.holder.beInImmunePhysicalDamageState, 0)
	end

	return true
end

local immunePower = {
	special = 4,
	physical = 2,
	all = 1,
	buff = 16,
	real = 32,
	skill = 8
}

local function getDamageType(record)
	local extraData = record.buffExtraArgs.data or {}
	local damageType = extraData.useEnvDamageType and record.damageType or record.args.damageType

	return damageType
end

local immunePowerFuncs = {}

immunePowerFuncs[immunePower.skill] = function(_self, record, attacker)
	if record.args.skillDamageId then
		if not _self:dealSpecialFlag(record, attacker) then
			return
		end

		if not _self:dealTime(record.args.skillDamageId, immunePower.skill, record.args.isLastDamageSeg) then
			return
		end

		return "skillImmune", false
	end
end
immunePowerFuncs[immunePower.buff] = function(_self, record, attacker)
	if record.args.from == battle.DamageFrom.buff then
		if not _self:dealSpecialFlag(record, attacker) then
			return
		end

		if not _self:dealTime(record.args.damageId, immunePower.buff, record.args.isLastDamageSeg) then
			return
		end

		return "buffImmune", false
	end
end
immunePowerFuncs[immunePower.physical] = function(_self, record)
	local damageType = getDamageType(record)

	if damageType == battle.SkillDamageType.Physical then
		if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.physical, record.args.isLastDamageSeg) then
			return
		end

		return "physical", true
	end
end
immunePowerFuncs[immunePower.all] = function(_self, record)
	if not _self:dealSpecialFlag(record, attacker) then
		return
	end

	if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.all, record.args.isLastDamageSeg) then
		return
	end

	return "all", true
end
immunePowerFuncs[immunePower.special] = function(_self, record)
	local damageType = getDamageType(record)

	if damageType == battle.SkillDamageType.Special then
		if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.special, record.args.isLastDamageSeg) then
			return
		end

		return "special", true
	end
end
immunePowerFuncs[immunePower.real] = function(_self, record)
	local damageType = getDamageType(record)

	if damageType == battle.SkillDamageType.True then
		if not _self:dealTime(record.args.skillDamageId or record.args.damageId, immunePower.real, record.args.isLastDamageSeg) then
			return
		end

		return "real", true
	end
end

function BuffEffectFuncTb.immuneDamage(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local easyEffectFunc = buff.csvCfg.easyEffectFunc

		holder:addOverlaySpecBuff(buff, function(old)
			if not old.funcMap then
				old:setG("funcMap", immunePowerFuncs)
				old:setG("dealTime", function(_self, damageId, powerType, isLastDamageSeg)
					if _self.isForever then
						if isLastDamageSeg then
							_self.damageMap.count = _self.damageMap.count + 1
						end

						return true
					end

					if not _self.damageMap.data[damageId] then
						if _self.powerTime[powerType] == 0 then
							return false
						end

						_self.damageMap.data[damageId] = true
						_self.powerTime[powerType] = _self.powerTime[powerType] - 1
					end

					if isLastDamageSeg then
						_self.allTime = _self.allTime - 1
						_self.damageMap.count = _self.damageMap.count + 1
					end

					return true
				end)
				old:setG("dealSpecialFlag", function(_self, record, attacker)
					local buff = _self.buff
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
				end)
				old:setG("getImmuneInfo", function(_self, immuneText, damageType)
					if _self.powerTime[immunePower.all] and _self.powerTime[immunePower.all] > 0 then
						return "allimmune"
					elseif damageType == battle.SkillDamageType.Physical and _self.powerTime[immunePower.physical] and _self.powerTime[immunePower.physical] > 0 then
						return battleEasy.ifElse(immuneText == "special", "allimmune", "physical")
					elseif damageType == battle.SkillDamageType.Special and _self.powerTime[immunePower.special] and _self.powerTime[immunePower.special] > 0 then
						return battleEasy.ifElse(immuneText == "physical", "allimmune", "special")
					end
				end)
				old:setG("powerTimeOrderPairs", function(_self)
					local idx, i = 1, 1

					return function()
						while i <= immunePower.real do
							local data = _self.powerTime[i]

							idx = i
							i = i * 2

							if data then
								return idx, data
							end
						end

						return nil
					end
				end)
			end

			old.powerTime = {}
			old.allTime = 0
			old.damageMap = {
				count = 0,
				data = {}
			}

			local power = immunePower.real
			local immuneValue = args[1]

			while immuneValue ~= 0 do
				if immuneValue - power >= 0 then
					immuneValue = immuneValue - power
					old.powerTime[power] = (old.powerTime[power] or 0) + (args[2] or 1)
					old.allTime = old.allTime + old.powerTime[power]
				end

				power = math.floor(power / 2)
			end

			old.isForever = args[2] == nil
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.immuneSpecialDamage(buff, args, isOver)
	if not isOver then
		buff.holder.beInImmuneSpecialDamageState = buff.holder.beInImmuneSpecialDamageState and buff.holder.beInImmuneSpecialDamageState + 1 or 1
	else
		buff.holder.beInImmuneSpecialDamageState = buff.holder.beInImmuneSpecialDamageState and buff.holder.beInImmuneSpecialDamageState - 1 or 0
		buff.holder.beInImmuneSpecialDamageState = math.max(buff.holder.beInImmuneSpecialDamageState, 0)
	end

	return true
end

function BuffEffectFuncTb.immuneAllDamage(buff, args, isOver)
	if not isOver then
		buff.holder.beInImmuneAllDamageState = buff.holder.beInImmuneAllDamageState and buff.holder.beInImmuneAllDamageState + 1 or 1
	else
		buff.holder.beInImmuneAllDamageState = buff.holder.beInImmuneAllDamageState and buff.holder.beInImmuneAllDamageState - 1 or 0
		buff.holder.beInImmuneAllDamageState = math.max(buff.holder.beInImmuneAllDamageState, 0)
	end

	return true
end

function BuffEffectFuncTb.immuneAllAttrsDown(buff, args, isOver)
	if not isOver then
		buff.holder.beInImmuneAllAttrsDownState = buff.holder.beInImmuneAllAttrsDownState and buff.holder.beInImmuneAllAttrsDownState + 1 or 1
	else
		buff.holder.beInImmuneAllAttrsDownState = buff.holder.beInImmuneAllAttrsDownState and buff.holder.beInImmuneAllAttrsDownState - 1 or 0
		buff.holder.beInImmuneAllAttrsDownState = math.max(buff.holder.beInImmuneAllAttrsDownState, 0)
	end

	return true
end

function BuffEffectFuncTb.silence(buff, args, isOver)
	if not isOver then
		local data = {}
		local closeSkill = {}

		if buff.csvCfg.specialVal == nil then
			if args then
				local argsType = type(args)

				if argsType == "table" then
					for _, silenceSkillId in ipairs(args or {}) do
						closeSkill[silenceSkillId] = true
					end
				elseif argsType == "number" then
					closeSkill[args] = true
				end
			end
		else
			data = helper.adjustSkillType2Data({
				[battle.MainSkillType.SmallSkill] = true,
				[battle.MainSkillType.BigSkill] = true,
				[battle.MainSkillType.NormalSkill] = false
			}, buff.csvCfg.specialVal)
		end

		buff.holder:addOverlaySpecBuff(buff, function(old)
			old.closeSkill = closeSkill
			old.closeSkillType2 = data
		end)
	else
		buff.holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.seal(buff, args, isOver)
	if not isOver then
		local data = {}

		if buff.csvCfg.specialVal then
			data = helper.adjustSkillType2Data({
				[battle.MainSkillType.SmallSkill] = true,
				[battle.MainSkillType.BigSkill] = true,
				[battle.MainSkillType.NormalSkill] = false
			}, buff.csvCfg.specialVal)
		end

		local closeSkill = {}

		for _, sealSkillId in ipairs(args[1]) do
			closeSkill[sealSkillId] = true
		end

		local tipStrType = args[2]
		local tipStr = tipStrType == 2 and gLanguageCsv.skillUnlocked
		local setGray = args[3] == 1
		local hide = args[4] == 1

		buff.holder:addOverlaySpecBuff(buff, function(old)
			old.showInfo = {
				tipStr = tipStr,
				setGray = setGray,
				hide = hide
			}
			old.closeSkill = closeSkill
			old.closeSkillType2 = data
		end)
	else
		buff.holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.sneer(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local sneerAtMeObj = buff.caster

		if sneerAtMeObj:isAlreadyDead() then
			buff:overClean()

			return true
		end

		if args and type(args) ~= "table" then
			args = {
				0,
				3,
				3
			}
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.buffID = buff.id
			old.mode = args[1]
			old.obj = buff.caster
			old.extraArg = {
				spreadArg1 = args[2],
				spreadArg2 = args[3]
			}
			old.cantMoveSkill = args[4] == 1
			old.priority = args[5] or 100 * (old.mode + 1)
			old.ignorePriority = args[6] or 10
			old.otherProcessBySkillID = args[7]

			if old.mode == battle.SneerType.Duel or old.mode == battle.SneerType.Normal and not holder:isBeInDuel() then
				local data = helper.adjustSkillType2Data({
					[battle.MainSkillType.SmallSkill] = true,
					[battle.MainSkillType.BigSkill] = true,
					[battle.MainSkillType.NormalSkill] = false
				}, buff.csvCfg.specialVal)

				holder:addSkillType2Data(buff.csvCfg.easyEffectFunc, data)
			end
		end, function(a, b)
			if a.priority == b.priority then
				return a.id < b.id
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			holder:removeSkillType2Data(buff.csvCfg.easyEffectFunc)

			if old.mode == battle.SneerType.Duel then
				local sneerBuffId
				local buffData = holder:getOverlaySpecBuffInnerData("sneer")
				local dataMap = buffData and buffData.map

				if buffData and buffData.map then
					for _, data in buffData.map:order_pairs() do
						if data.mode == battle.SneerType.Normal then
							sneerBuffId = data.id

							break
						end
					end
				end

				if sneerBuffId then
					local holderBuff = holder:getBuffByID(sneerBuffId)

					if holderBuff then
						local data = helper.adjustSkillType2Data({
							[battle.MainSkillType.SmallSkill] = true,
							[battle.MainSkillType.BigSkill] = true,
							[battle.MainSkillType.NormalSkill] = false
						}, holderBuff.csvCfg.specialVal)

						holder:addSkillType2Data(holderBuff.csvCfg.easyEffectFunc, data)
					end
				end
			end
		end)
	end

	return true
end

function BuffEffectFuncTb.confusion(buff, args, isOver)
	local holder = buff.holder
	local baseProb, needSelfForce, alterSelfForce

	if not args or type(args) == "number" then
		baseProb = args
	else
		baseProb = args[1]
		needSelfForce = args[2] == 1
		alterSelfForce = args[3] and args[3] == 1
	end

	local confusionProb = math.min(math.max(0, baseProb or 0.5), 1)

	if not isOver then
		local data = helper.adjustSkillType2Data({
			[battle.MainSkillType.SmallSkill] = true,
			[battle.MainSkillType.BigSkill] = true,
			[battle.MainSkillType.NormalSkill] = false
		}, buff.csvCfg.specialVal)

		holder:addOverlaySpecBuff(buff, function(old)
			old.prob = confusionProb
			old.closeSkillType2 = data
			old.needSelfForce = needSelfForce
			old.alterSelfForce = alterSelfForce
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.reborn(buff, args, isOver)
	local holder = buff.holder
	local lifeRound = args[1]
	local isFastReborn = lifeRound == 0 and true or false

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.isFastReborn = isFastReborn
			old.lifeRound = lifeRound
			old.rebornTrigger = false
			old.hp = math.ceil(args[2] or 1)
			old.mp = args[3] or 0
			old.priority = args[4] or 0
			old.times = args[5] or 1
		end, function(a, b)
			if a.priority == b.priority then
				if a.isFastReborn == b.isFastReborn then
					return a.buff.id < b.buff.id
				end

				return a.isFastReborn or false
			else
				return a.priority > b.priority
			end
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			holder:beforeRebornCleanData()
			holder:resetRebornState(old.hp, old.mp, buff)
		end)
	end

	return true
end

function BuffEffectFuncTb.removeObj(buff, args, isOver)
	if not isOver then
		local holder = buff.holder
		local attacker = buff.caster
		local deadArgs = {}

		deadArgs.force = args[1] == 1
		deadArgs.noTrigger = args[2] == 0

		holder:setDead(attacker, nil, deadArgs)
	end

	return true
end

function BuffEffectFuncTb.weather(buff, args, isOver)
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

function BuffEffectFuncTb.fatal(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.limit = args[1]
			old.val = args[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.behead(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.limit = args[1]
			old.val = args[2]
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

function BuffEffectFuncTb.damageByHpRate(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		holder:addOverlaySpecBuff(buff, function(old)
			old.rateMax = args[3] or 1
			old.rateAdd = args[2] or 1
			old.selectTargetTab = {
				false,
				false
			}
			old.selectTargetTab[args[1] or 1] = true
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end

	return true
end

local function controlOrImmuneBuff(buff, args, isOver)
	local holder = buff.holder

	if not isOver then
		local func = functools.partial(function(checkGroups, value, prob, group, flags)
			if not checkGroups then
				return prob
			end

			local groupRelation

			for k, v in ipairs(checkGroups) do
				groupRelation = gBuffGroupRelationCsv[v]

				if battleCsv.hasImmnueConfiguration(v, group, flags) then
					return prob + value, groupRelation.immuneEffect and v or nil
				end
			end

			return prob
		end, buff.csvCfg.specialVal or {
			999999
		}, args)

		holder:addOverlaySpecBuff(buff, function(old)
			old.refreshProb = func
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.immuneControlAdd(buff, args, isOver)
	controlOrImmuneBuff(buff, args, isOver)

	return true
end

function BuffEffectFuncTb.controlPerAdd(buff, args, isOver)
	controlOrImmuneBuff(buff, args, isOver)

	return true
end

function BuffEffectFuncTb.immuneControlVal(buff, args, isOver)
	if args and type(args) == "number" then
		args = args / ConstSaltNumbers.wan
	end

	controlOrImmuneBuff(buff, args, isOver)

	return true
end

function BuffEffectFuncTb.controlPerVal(buff, args, isOver)
	if args and type(args) == "number" then
		args = args / ConstSaltNumbers.wan
	end

	controlOrImmuneBuff(buff, args, isOver)

	return true
end

function BuffEffectFuncTb.loseImmuneEfficacy(buff, args, isOver)
	local holder = buff.holder
	local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1] or {}

	if not isOver then
		local loseEfficacyGroups = {}

		for _, group in pairs(args[2]) do
			loseEfficacyGroups[group] = {}

			local tempTb = {}
			local groupRelation = gBuffGroupRelationCsv[group]

			if groupRelation then
				for _, tb in ipairs(groupRelation.immuneGroup) do
					for k, __ in pairs(tb) do
						tempTb[k] = true
					end
				end

				for k, _ in pairs(tempTb) do
					if itertools.include(specialArgs, k) or not next(specialArgs) then
						table.insert(loseEfficacyGroups[group], k)
					end
				end
			end
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.buffCfgId = args[1]
			old.buffType = args[3]
			old.attr = args[4]
			old.buffGroups = loseEfficacyGroups
		end)
	else
		holder:deleteOverlaySpecBuff(buff)
	end
end

function BuffEffectFuncTb.damageCapped(buff, args, isOver)
	local holder = buff.holder
	local attacker = buff.caster
	local skill = attacker and attacker.curSkill

	if isOver then
		local _buff = attacker.damageCappedBuff

		if attacker.damageCappedBuff then
			if holder:isDeath() == false then
				local damage = _buff.damage
				local rate = _buff.args[_buff.index]
				local damageArgs = {
					isBeginDamageSeg = true,
					isLastDamageSeg = true,
					from = battle.DamageFrom.buff,
					skillDamageType = battle.SkillDamageType.Special
				}
				local switchToPlay05 = gRootViewProxy:proxy():pushDeferList(skill and skill.id, "switchToPlay05")

				buff.holder:beAttack(attacker, math.floor(damage * rate), 5, damageArgs)

				if skill and skill.isSpellTo and skill.owner.id ~= holder.id then
					skill:addToSegDamage(damage)
				end

				local t = gRootViewProxy:proxy():popDeferList(switchToPlay05)

				if skill then
					skill:pushDefreListToSkillEnd("skillEndDeleteDeadObjs", t)

					if holder:isDeath() then
						skill:addObjectToKillTab(buff.holder)
					end
				end

				attacker.damageCappedBuff.index = attacker.damageCappedBuff.index + 1
			end

			if attacker.damageCappedBuff.index > table.length(_buff.args) then
				attacker.damageCappedBuff = nil
			end
		end
	elseif holder:isDeath() then
		attacker.damageCappedBuff = {
			index = 1,
			damage = math.abs(holder.hpTable[3]),
			args = args
		}
	end

	return true
end

function BuffEffectFuncTb.damageAllocate(buff, args, isOver)
	local holder = buff.holder
	local cfgId = buff.cfgId
	local specialVal = buff.csvCfg.specialVal

	if not isOver then
		local targets = buff:findTargetsByCfg(args[2])
		local targetIds = {}

		for _, obj in ipairs(targets) do
			table.insert(targetIds, obj.id)
		end

		holder:addOverlaySpecBuff(buff, function(old)
			old.rate = args[1]
			old.targetIds = targetIds
			old.damageMode = args[3] or 1
			old.priority = args[4] or 10
			old.damageFix = args[5] or 1

			function old.getNewTargetIds()
				local objs = buff:findTargetsByCfg(args[2])
				local ret = {}

				for _, obj in ipairs(objs) do
					table.insert(ret, obj.id)
				end

				return ret
			end

			old.targetIdsList = {}
			old.attackByCaster = args[6] == 1
			old.ignorePriority = args[7] or 10
			old.damageFrom = args[8] or 0
			old.battleTurnType = args[9] or 1
			old.maxDamage = args[10]
			old.canAllocateSelf = args[11] == 1
			old.hideZeroDmg = specialVal and specialVal[4] == 1
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

function BuffEffectFuncTb.damageLink(buff, args, isOver)
	local holder = buff.holder
	local objId = holder.id
	local cfgId = buff.cfgId

	if not isOver then
		local value = buff:cfg2Value(args[1])
		local oneWayKey = args[2]
		local casterId = args[3] == 1 and buff.caster.id or nil
		local damageFromLimit = args[4] or 0
		local battleTurnTypeLimit = args[5] or 1
		local timesLimit = args[6] or 0
		local processId = args[7]
		local getObjectType = args[8] or 0
		local buffData = holder:addOverlaySpecBuff(buff, function(old)
			old.value = value
			old.oneWay = oneWayKey
			old.casterId = casterId
			old.fromLimit = damageFromLimit
			old.battleTurnTypeLimit = battleTurnTypeLimit
			old.damageLimit = {
				curDamage = 0
			}

			local var_87_0

			var_87_0 = timesLimit ~= 0 and {
				curRound = -1,
				times = 0,
				limit = timesLimit
			}
			old.timesLimit = var_87_0
			old.processId = processId
			old.getObjectType = getObjectType
			old.buffFlagLimit = args[9] or {}

			buff.scene.buffGlobalManager:setDamageLinkRecord(objId, cfgId, old)
		end)
	else
		holder:deleteOverlaySpecBuff(buff, function(old)
			buff.scene.buffGlobalManager:cleanDamageLinkRecord(objId, cfgId)
		end)
	end
end

function BuffEffectFuncTb.selfDamageToHpRate(buff, args, isOver)
	if not isOver then
		local rate = args
		local holderSkill = buff.objThatTriggeringMeNow
		local holder = buff.holder
		local addHpVal = 0
		local specialArgs = buff.csvCfg.specialVal and buff.csvCfg.specialVal[1]
		local resumeArgs = {
			ignoreBeHealAddRate = true,
			from = battle.ResumeHpFrom.buff
		}

		holder.lastRealTotalDamage = holder.lastRealTotalDamage or 0

		if holderSkill:isNormalSkillType() then
			local totalDamage = 0

			for _, v in holderSkill:pairsTargetsFinalResult(battle.SkillSegType.damage) do
				totalDamage = totalDamage + v.real:get(battle.ValueType.normal)
			end

			holder.lastRealTotalDamage = totalDamage
		end

		if specialArgs then
			resumeArgs.ignoreLockResume = battleEasy.ifElse(specialArgs.ignoreLockResume, specialArgs.ignoreLockResume, resumeArgs.ignoreLockResume)
			resumeArgs.ignoreBeHealAddRate = battleEasy.ifElse(specialArgs.ignoreBeHealAddRate, specialArgs.ignoreBeHealAddRate, resumeArgs.ignoreBeHealAddRate)
		end

		addHpVal = holder.lastRealTotalDamage

		if rate then
			addHpVal = addHpVal * rate
		end

		if addHpVal ~= 0 then
			if (not specialArgs or not specialArgs.ignoreToDamage) and holder:checkOverlaySpecBuffExit(battle.OverlaySpecBuff.healTodamage) then
				local buffArgs = {
					cfgId = buff.cfgId,
					flag = buff.csvCfg.buffFlag,
					groupId = buff:group()
				}

				holder:doOverlaySpecBuffFunc(battle.OverlaySpecBuff.healTodamage, "doBuffDamage", holder, holder, addHpVal, buffArgs)
			else
				holder:resumeHp(holder, math.floor(addHpVal), resumeArgs)
			end
		end
	end

	return true
end

function BuffEffectFuncTb.otherBuffEnhance(buff, args, isOver)
	local group = args[1]
	local percent = args[2]
	local holder = buff.holder
	local ignoreBuffEffect = {
		buffDamage = true
	}

	args[3] = args[3] or 1

	if not isOver then
		if args[3] == 1 then
			for k, v in ipairs(group) do
				holder:addBuffEnhance(v, buff.cfgId, percent, args[3])
			end
		elseif args[3] == 2 then
			for k, v in ipairs(group) do
				holder:addBuffEnhance(v, buff.cfgId, percent, args[3])

				for _, haveBuff in holder:queryBuffsWithGroup(v):order_pairs() do
					if haveBuff.isNumberType and not ignoreBuffEffect[haveBuff.csvCfg.easyEffectFunc] then
						haveBuff:refreshLerpValue()
					end
				end
			end
		end
	elseif args[3] == 1 or args[3] == 2 then
		for k, v in ipairs(group) do
			holder:delBuffEnhance(v, buff.cfgId, args[3])

			if args[3] == 2 then
				for _, haveBuff in holder:queryBuffsWithGroup(v):order_pairs() do
					if haveBuff.isNumberType and not ignoreBuffEffect[haveBuff.csvCfg.easyEffectFunc] then
						haveBuff:refreshLerpValue()
					end
				end
			end
		end
	end
end
