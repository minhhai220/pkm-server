local ExtraAttackArgs = {}

globals.ExtraAttackArgs = ExtraAttackArgs

local fromInfoMap = {}

local function check(t, list, args)
	if device.platform ~= "windows" then
		return t
	end

	local catchKey = ""

	for k, v in pairs(fromInfoMap) do
		if args[k] then
			catchKey = v .. args[k]

			break
		end
	end

	for __, key in ipairs(list) do
		assert(t[key] ~= nil, key .. " is nil, " .. catchKey)
	end

	return t
end

local ExtraAttackArgsCheckList = {
	"mode",
	"cfgId"
}
local ExtraAttackArgsCheckList2 = {}
local CounterCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	ExtraAttackArgsCheckList2,
	{}
})

function ExtraAttackArgs.fromCounter(targetID, exAttackSkillID, counterAttackData, counterFixArgs)
	local t = {
		extraTargetId = targetID,
		exAttackSkillID = exAttackSkillID,
		mode = battle.ExtraAttackMode.counter,
		cfgId = counterAttackData.cfgId,
		buffId = counterAttackData.id,
		buffFlag = counterAttackData.buffFlag,
		roundTriggerLimit = counterAttackData.roundTriggerLimit,
		otherProcessBySkillID = counterAttackData.otherProcessBySkillID
	}

	if counterAttackData.isWeightingType then
		t.skillPowerMap = counterFixArgs and counterFixArgs.fixWeightValue or counterAttackData.triggerSkillType2
		t.costType = counterFixArgs and counterFixArgs.fixCostType or counterAttackData.costType
		t.extraSkill = counterAttackData.extraSkill
	end

	return check(t, CounterCheckList, {})
end

local SyncCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	ExtraAttackArgsCheckList2,
	{}
})

function ExtraAttackArgs.fromSync(targetId, target, mode, exAttackSkillID, data, exFixarg)
	local t = {
		extraTargetId = targetId,
		exAttackSkillID = exAttackSkillID,
		mode = mode,
		cfgId = data.cfgId,
		buffId = data.id,
		buffFlag = data.buffFlag,
		roundTriggerLimit = data.roundTriggerLimit,
		otherProcessBySkillID = data.otherProcessBySkillID
	}

	if data.isWeightingType then
		t.skillPowerMap = exFixarg and exFixarg.fixWeightValue or data.triggerSkillType2
		t.costType = exFixarg and exFixarg.fixCostType or data.costType
		t.isFixedForce = data.isFixedForce
		t.targetForce = data.isFixedForce and targetId and target.force
	end

	return check(t, SyncCheckList, {})
end

local AssisCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	ExtraAttackArgsCheckList2,
	{}
})

function ExtraAttackArgs.fromAssis(targetId, exAttackSkillID, data, isWeightingType)
	local t = {
		extraTargetId = targetId,
		exAttackSkillID = exAttackSkillID,
		mode = battle.ExtraAttackMode.assistAttack,
		cfgId = data.cfgId,
		extraSkill = data.extraSkill,
		buffId = data.id,
		buffFlag = data.buffFlag,
		roundTriggerLimit = data.roundTriggerLimit,
		otherProcessBySkillID = data.otherProcessBySkillID
	}

	if data.isWeightingType then
		t.skillPowerMap = data.triggerSkillType2
		t.costType = data.costType
	end

	return check(t, AssisCheckList, {})
end

local ProphetCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	ExtraAttackArgsCheckList2,
	{}
})

function ExtraAttackArgs.fromProphet(targetId, exAttackSkillID, data, counterFixArgs)
	local t = {
		extraTargetId = targetId,
		exAttackSkillID = exAttackSkillID,
		mode = battle.ExtraAttackMode.prophet,
		cfgId = data.cfgId,
		cantReselect = data.cantReselect,
		isFixedForce = data.isFixedForce,
		buffId = data.id,
		buffFlag = data.buffFlag,
		roundTriggerLimit = data.roundTriggerLimit
	}

	if data.isWeightingType then
		t.skillPowerMap = counterFixArgs and counterFixArgs.fixWeightValue or data.triggerSkillType2
		t.costType = counterFixArgs and counterFixArgs.fixCostType or data.costType
	end

	return check(t, ProphetCheckList, {})
end

local ComboCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	ExtraAttackArgsCheckList2,
	{}
})

function ExtraAttackArgs.fromCombo(targetId, exAttackSkillID, data)
	local t = {
		extraTargetId = targetId,
		exAttackSkillID = exAttackSkillID,
		mode = battle.ExtraAttackMode.combo,
		cfgId = data.cfgId,
		buffId = data.id,
		roundTriggerLimit = data.roundTriggerLimit
	}

	return check(t, ComboCheckList, {})
end

local DuelCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	{}
})

function ExtraAttackArgs.fromDuel(buffId, cfgId, closeSkillType2, costType)
	local t = {
		updateBattleRound = true,
		isFixedForce = true,
		mode = battle.ExtraAttackMode.duel,
		cfgId = cfgId,
		closeSkillType2 = closeSkillType2,
		costType = costType or battle.SkillCostType.Normal,
		buffId = buffId
	}

	return check(t, DuelCheckList, {})
end

local BrawlCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	{}
})

function ExtraAttackArgs.fromBrawl(buffId, cfgId, skillPowerMap)
	local t = {
		isFixedForce = true,
		canSpell = true,
		mode = battle.ExtraAttackMode.brawl,
		cfgId = cfgId,
		skillPowerMap = skillPowerMap,
		costType = battle.SkillCostType.IgnoreMpCd,
		buffId = buffId
	}

	return check(t, BrawlCheckList, {})
end

local NormalCheckList = arraytools.merge({
	ExtraAttackArgsCheckList,
	{}
})

function ExtraAttackArgs.fromNormal(buffId, cfgId, extraCfgArgs)
	local t = {
		isFixedForce = true,
		canSpell = false,
		mode = battle.ExtraAttackMode.normal,
		cfgId = cfgId,
		skillPowerMap = extraCfgArgs[3],
		costType = extraCfgArgs[1] or battle.SkillCostType.IgnoreMpCd,
		fullManual = extraCfgArgs[2],
		buffId = buffId
	}

	if extraCfgArgs[4] and extraCfgArgs[4] ~= 0 then
		t.otherProcessBySkillID = extraCfgArgs[4]
	end

	return check(t, NormalCheckList, {})
end

local AidCheckList = arraytools.merge({
	{
		"exAttackSkillID"
	}
})

function ExtraAttackArgs.fromAid(aidSkillID)
	local t = {
		exAttackSkillID = aidSkillID,
		mode = battle.ExtraAttackMode.aid,
		costType = battle.SkillCostType.IgnoreMpCd
	}

	return check(t, AidCheckList, {})
end
