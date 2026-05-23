
local structformat = string.structformat
local assertInWindows = assertInWindows
local switch = device.platform == "windows"
local LocalData = {}
local supper = string.upper
local CheckMode = {
	IncludeList = function(item, data)
		return itertools.include(item.data, data.__value)
	end,
	ExcludeList = function(item, data)
		return itertools.include(item.data, data.__value) == false
	end,
	Function = function(item, data)
		return item.data(data)
	end
}
local RoundTriggerPoint = {
	battle.BuffTriggerPoint.onRoundStart,
	battle.BuffTriggerPoint.onRoundEnd,
	battle.BuffTriggerPoint.onHolderBattleTurnStart,
	battle.BuffTriggerPoint.onHolderBattleTurnStartOther,
	battle.BuffTriggerPoint.onHolderBattleTurnEnd,
	battle.BuffTriggerPoint.onHolderReborn,
	battle.BuffTriggerPoint.onBattleTurnStart,
	battle.BuffTriggerPoint.onHolderAfterEnter,
	battle.BuffTriggerPoint.onBattleTurnEnd
}
local DoEffectCheckMap = {
	triggerPoint = function()
		return {
			desc = "please use other triggerPoint {__value} to doEffect {buff.csvCfg.easyEffectFunc}",
			data = RoundTriggerPoint,
			check = CheckMode.IncludeList,
			getValue = function(self)
				return LocalData.triggerPoint
			end
		}
	end,
	skillLinkCheck = function(getValue)
		return {
			desc = "{buff.cfgId} value {__value} is error",
			data = function(self)
				for _, skillID in ipairs(self.__value) do
					if table.length(self.buff.scene:getCfgSkillProcess(skillID)) == 0 then
						return false
					end
				end

				return true
			end,
			check = CheckMode.Function,
			getValue = getValue
		}
	end,
	
	assertDamageProcessSign = function(signList)
		return {
			desc = " is not support this sign {__value}",
			data = signList,
			check = CheckMode.IncludeList,
			getValue = function(self)
				return self.sign
			end
		}
	end
}
local BattleAssertMap = {
	damageProcess = {
		invincible = DoEffectCheckMap.assertDamageProcessSign({
			"run"
		})
	}
}

globals.BattleAssert = {}

function BattleAssert.clear()
	table.clear(LocalData)
end

local function doCheck(item, data)
	data.__value = item.getValue(data)

	return item.check(item, data), item.desc
end

function BattleAssert.assertInWindows(key, checkKey, data)
	-- if not switch or not BattleAssertMap[key] then
	-- 	return
	-- end

	-- local checkList = BattleAssertMap[key][checkKey]

	-- if not checkList then
	-- 	return
	-- end

	-- local c, s

	-- if table.length(checkList) > 0 then
	-- 	for _, item in ipairs(checkList) do
	-- 		c, s = doCheck(item, data)

	-- 		if not c then
	-- 			break
	-- 		end
	-- 	end
	-- else
	-- 	c, s = doCheck(checkList, data)
	-- end

	-- if c then
	-- 	return
	-- end

	-- return assertInWindows(c, string.format("[%s_%s] %s", supper(key), supper(checkKey), structformat(s, data)))
end

function BattleAssert.checkBuffLoop(cfgId, holder, caster, args)
	local loopKey = string.format("%d_%d_%d", cfgId, holder and holder.seat or 0, caster and caster.seat or 0)

	if not LocalData.buffLoopRecord then
		LocalData.buffLoopRecord = {}
	end

	LocalData.buffLoopRecord[loopKey] = LocalData.buffLoopRecord[loopKey] or 0
	LocalData.buffLoopRecord[loopKey] = LocalData.buffLoopRecord[loopKey] + 1

	if LocalData.buffLoopRecord[loopKey] > 50 then
		errorInWindows("buff:%d cast stack overflow, from skill:%d, source:%s", cfgId, args.fromSkillId or 0, args.source or "")

		return true, loopKey
	end

	return false, loopKey
end

function BattleAssert.popBuffLoop(loopKey)
	LocalData.buffLoopRecord[loopKey] = LocalData.buffLoopRecord[loopKey] - 1
end

local maxCurBattleRound = 0

function BattleAssert.checkBattleTurnLoop(curBattleRound)
	if curBattleRound > 300 then
		if device.platform == "windows" then
			errorInWindows("checkBattleTurnLoop curBattleRound")
		else
			error("checkBattleTurnLoop curBattleRound")
		end
	end
end

local AssertEventMessage = {
	triggerBuffOnPoint = function(triggerPoint)
		LocalData.triggerPointCounter = LocalData.triggerPointCounter or 0

		if LocalData.triggerPointCounter == 0 then
			LocalData.triggerPoint = triggerPoint
		end

		LocalData.triggerPointCounter = LocalData.triggerPointCounter + 1
	end,
	triggerBuffOnPointEnd = function(triggerPoint)
		LocalData.triggerPointCounter = LocalData.triggerPointCounter - 1

		if LocalData.triggerPointCounter == 0 then
			LocalData.triggerPoint = nil
		end
	end
}

function BattleAssert.onEvent(msg, ...)
	if not switch then
		return
	end

	AssertEventMessage[msg](...)
end
