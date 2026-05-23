-- chunkname: @src.battle.csv.buff

local CsvBuff = battleCsv.newCsvCls("CsvBuff")

CsvBuff.ignoreModelCheck = {
	getHolder = true,
	getCaster = true
}
battleCsv.CsvBuff = CsvBuff

function CsvBuff:getDispleState()
	return self.model:getEventByKey(battle.ExRecordEvent.dispelSuccess) or false
end

function CsvBuff:getValue()
	return self.model.value
end

function CsvBuff:getMulValue()
	if self.model:isCoexistType() then
		local sumV = 0

		for _, buff in self.model.holder:iterBuffsWithCsvID(self.model.cfgId) do
			sumV = sumV + buff.value
		end

		return sumV
	end

	return self.model.value
end

function CsvBuff:getGroup()
	return self.model.csvCfg.group
end

function CsvBuff:hasFlag(...)
	local tb = {
		...
	}
	local buffFlag = self.model.csvCfg.buffFlag

	for _, v in ipairs(tb) do
		if itertools.include(buffFlag, v) then
			return true
		end
	end

	return false
end

function CsvBuff:getCfgId()
	return self.model.cfgId
end

function CsvBuff:getEasyEffectFunc()
	return self.model.csvCfg.easyEffectFunc
end

function CsvBuff:getRecordDataTab(key, ...)
	local keys = {
		...
	}

	for id, v in ipairs(keys) do
		local typ = type(v)

		if typ ~= "string" and typ ~= "number" then
			keys[id] = v.model and v.model.id or v.id or 0
		end
	end

	return self.model:getEventByKey(battle.ExRecordEvent[key], table.unpack(keys)) or 0
end

function CsvBuff:getModifiyerValue(...)
	local keys = {
		...
	}

	return self.model:getEventByKey(battle.ExRecordEvent.customRecord, table.unpack(keys)) or 0
end

function CsvBuff:getValueIdx(i)
	return self.model.value[i]
end

function CsvBuff:getLifeRound()
	return self.model.args.lifeRound
end

function CsvBuff:getFinalLifeRound()
	return self.model:getLifeRound()
end

function CsvBuff:getOverLayCount()
	return self.model:getOverLayCount()
end

function CsvBuff:getCopyBuffState()
	return self.model:getEventByKey(battle.ExRecordEvent.copyState) or false
end

function CsvBuff:getTransferBuffState()
	return self.model:getEventByKey(battle.ExRecordEvent.transferState) or false
end

function CsvBuff:getOriginPriority()
	return self.model.args.originPriority or 1
end

function CsvBuff:getCaster()
	if not self.model then
		return battleCsv.NilObject
	end

	return battleCsv.CsvObject.newWithCache(self.model.caster)
end

function CsvBuff:getHolder()
	if not self.model then
		return battleCsv.NilObject
	end

	return battleCsv.CsvObject.newWithCache(self.model.holder)
end
