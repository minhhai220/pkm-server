local function newBuffData_(buff, args)
	local buffData = {
		buff = buff,
		cfgId = buff.cfgId,
		id = buff.id,
		holder = buff.holder,
		force = buff.holder.force
	}

	return buffData
end

local SceneBuffRecordModel = class("SceneBuffRecordModel")

function SceneBuffRecordModel:ctor(scene)
	self.scene = scene
	self.buffList = {}
end

function SceneBuffRecordModel:init()
	return
end

function SceneBuffRecordModel:sort()
	return
end

function SceneBuffRecordModel:newBuffData(buff, args)
	errorInWindows("%s Undefined newBuffData", tostring(self))
end

function SceneBuffRecordModel:updateEffectBuff(buffData, isOver)
	errorInWindows("%s Undefined updateEffectBuff", tostring(self))
end

function SceneBuffRecordModel:influenceSceneBuff(type, obj, isOver)
	errorInWindows("%s Undefined influenceSceneBuff", tostring(self))
end

function SceneBuffRecordModel:order_pairs()
	local i, k, v = 0, 0

	return function()
		while i < #self.buffList do
			i = i + 1
			v = self.buffList[i]

			if v ~= nil and self:filter_order_item(v) then
				k = k + 1

				return k, v
			end
		end
	end
end

function SceneBuffRecordModel:filter_order_item(v)
	return true
end

function SceneBuffRecordModel:addSceneBuff(buff, args)
	local index = 0

	for k, data in ipairs(self.buffList) do
		if data.id == buff.id then
			index = k

			break
		end
	end

	if index == 0 then
		local buffData = self:newBuffData(buff, args)

		table.insert(self.buffList, buffData)
		self:sort()
		self:updateEffectBuff(buffData, false)
	end
end

function SceneBuffRecordModel:delSceneBuff(buff)
	for k, data in ipairs(self.buffList) do
		if data.id == buff.id then
			local buffData = table.remove(self.buffList, k)

			self:updateEffectBuff(buffData, true)

			break
		end
	end
end

local OccupiedSeatRecord = class("OccupiedSeatRecord", SceneBuffRecordModel)

function OccupiedSeatRecord:init()
	self.forceUseSeat = {
		0,
		0
	}
	self.seats = {}
end

function OccupiedSeatRecord:newBuffData(buff, args)
	local buffData = {}

	if args[1] == 1 then
		buffData.seat = buff.holder.seat
		buffData.num = 0
	elseif args[1] == 2 then
		buffData.num = args[2]
	end

	buffData.holder = buff.holder
	buffData.tag = nil
	buffData.id = buff.id

	return buffData
end

function OccupiedSeatRecord:updateEffectBuff(buffData, isOver)
	local ret = battleEasy.ifElse(isOver, -1, 1)

	if buffData.tag == ret then
		return
	end

	if buffData.seat then
		self.seats[buffData.seat] = self.seats[buffData.seat] or 0
		self.seats[buffData.seat] = self.seats[buffData.seat] + ret
	else
		self.forceUseSeat[buffData.holder.force] = self.forceUseSeat[buffData.holder.force] + buffData.num * ret
	end

	buffData.tag = ret
end

function OccupiedSeatRecord:updateBuffEffectOnLeave(buffData, isOver)
	if not isOver and buffData.seat then
		buffData.seat = buffData.holder.seat
	end

	self:updateEffectBuff(buffData, isOver)
end

function OccupiedSeatRecord:influenceSceneBuff(type, obj, isOver)
	for _, buffData in ipairs(self.buffList) do
		if buffData.holder.id == obj.id then
			if type == battle.InfluenceSceneBuffType.leave then
				self:updateBuffEffectOnLeave(buffData, isOver)
			else
				self:updateEffectBuff(buffData, isOver)
			end
		end
	end
end

function OccupiedSeatRecord:sum(force)
	return self.forceUseSeat[force]
end

function OccupiedSeatRecord:isSeatExitObj(seat)
	if not self.seats[seat] then
		self.seats[seat] = 0
	end

	return self.seats[seat] > 0
end

local ReplaceBuffHolderRecord = class("ReplaceBuffHolderRecord", SceneBuffRecordModel)

function ReplaceBuffHolderRecord:init()
	self.effectBuff = {}
end

function ReplaceBuffHolderRecord:newBuffData(buff, args)
	local buffData = newBuffData_(buff, args)
	local scene = self.scene

	function buffData:f(cfgId, holder, caster, args)
		if scene:isBackHeros(self.holder) then
			return false, holder
		end

		if caster and not self.holder:isSameForce(caster.force) and self.holder:isSameForce(holder.force) then
			local buffCfg = csv.buff[cfgId]
			local function casterFilter()
				if self.casterCfg then
					local targets = self.buff:findTargetsByCfg(self.casterCfg)

					for _, target in ipairs(targets) do
						if caster.id == target.id then
							return true
						end
					end

					return false
				else
					return true
				end
			end

			if not battleEasy.buffFilter(buffCfg.group, self.groups, buffCfg.buffFlag, self.flags) and casterFilter() then
				return true, self.holder
			end
		end

		return false, holder
	end

	buffData.groups = args[1][1]
	buffData.flags = args[1][2]

	if buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1] then
		buffData.casterCfg = buff.csvCfg.specialTarget[1]
	end

	return buffData
end

function ReplaceBuffHolderRecord:updateEffectBuff(buffData, isOver)
	if not isOver and self.scene:getFieldObject(buffData.holder.id) then
		self.effectBuff[buffData.id] = buffData
	else
		self.effectBuff[buffData.id] = nil
	end
end

function ReplaceBuffHolderRecord:influenceSceneBuff(type, obj, isOver)
	for _, buffData in ipairs(self.buffList) do
		if buffData.holder.id == obj.id then
			if isOver then
				self.effectBuff[buffData.id] = nil
			else
				self.effectBuff[buffData.id] = buffData
			end
		end
	end
end

function ReplaceBuffHolderRecord:filter_order_item(v)
	return self.effectBuff[v.id] ~= nil
end

local AuraRecord = class("AuraRecord", SceneBuffRecordModel)

function AuraRecord:init()
	self.effectAura = {
		{},
		{}
	}
end

function AuraRecord:newBuffData(buff, args)
	local buffData = newBuffData_(buff, args)

	buffData.once = args[1] == 1
	buffData.level = args[2] or 10
	buffData.specialTargetFormula = buff.csvCfg.specialTarget and buff.csvCfg.specialTarget[1]
	buffData.count = 0
	buffData.forceTarget = {}

	return buffData
end

function AuraRecord:sort()
	table.sort(self.buffList, function(buffA, buffB)
		if buffA.holder.force == buffB.holder.force then
			if buffA.level == buffB.level then
				return buffA.id < buffB.id
			else
				return buffA.level > buffB.level
			end
		end

		return buffA.id < buffB.id
	end)
end

function AuraRecord:updateEffectBuff(buffData, isOver)
	local selfForce = buffData.holder.force
	local cfgId = buffData.cfgId

	local function checkForceEffecData(data)
		if data.cfgId == cfgId and data.holder.force == selfForce and self.scene:getFieldObject(data.holder.id) then
			return true
		else
			return false
		end
	end

	if not isOver then
		for _, data in ipairs(self.buffList) do
			if checkForceEffecData(data) then
				if data.id == buffData.id then
					self:updateEffectAura(buffData)
				end

				break
			end
		end
	else
		local effectBuffData = self.effectAura[selfForce][cfgId]

		if effectBuffData and effectBuffData.id == buffData.id then
			local isUpdate = false

			for _, data in ipairs(self.buffList) do
				if checkForceEffecData(data) then
					self:updateEffectAura(data)

					isUpdate = true

					break
				end
			end

			if not isUpdate then
				self.effectAura[selfForce][cfgId] = nil

				for _, obj in ipairs(buffData.forceTarget) do
					self:updateAuraChildBuff(buffData, obj, true)
				end
			end
		end
	end
end

function AuraRecord:updateEffectAura(buffData)
	local force = buffData.holder.force
	local cfgId = buffData.cfgId

	if self.effectAura[force][cfgId] ~= nil then
		local lastBuffData = self.effectAura[force][cfgId]

		if lastBuffData.id ~= buffData.id then
			for _, obj in ipairs(lastBuffData.forceTarget) do
				self:updateAuraChildBuff(lastBuffData, obj, true)
			end
		end
	end

	if buffData.count > 0 and buffData.once == true then
		return
	end

	buffData.count = buffData.count + 1
	self.effectAura[force][cfgId] = buffData

	local targetHash = {}
	local forceTarget = buffData.forceTarget

	buffData.forceTarget = {}

	if buffData.specialTargetFormula then
		local targets = buffData.buff:findTargetsByCfg(buffData.specialTargetFormula)

		for _, obj in ipairs(targets) do
			targetHash[obj.id] = true

			table.insert(buffData.forceTarget, obj)
			self:updateAuraChildBuff(buffData, obj, false)
		end
	else
		for _, obj in buffData.buff.scene:getHerosMap(buffData.holder.force):order_pairs() do
			targetHash[obj.id] = true

			table.insert(buffData.forceTarget, obj)
			self:updateAuraChildBuff(buffData, obj, false)
		end
	end

	for _, obj in ipairs(forceTarget) do
		if not targetHash[obj.id] then
			self:updateAuraChildBuff(buffData, obj, true)
		end
	end
end

function AuraRecord:updateAuraChildBuff(buffData, obj, isOver)
	if isOver then
		for _, buff in obj:iterBuffs() do
			if buff.args.fromBuffID == buffData.id then
				buff:overClean()
			end
		end
	else
		buffData.buff:updateWithTrigger(battle.BuffTriggerPoint.onBuffTrigger, {
			obj = obj
		})
	end
end

function AuraRecord:influenceSceneBuff(type, obj, isOver)
	if type == battle.InfluenceSceneBuffType.leave then
		for _, buffData in self:order_pairs() do
			if buffData.holder.id == obj.id then
				for _, obj in ipairs(buffData.forceTarget) do
					self:updateAuraChildBuff(buffData, obj, isOver)
				end

				self.effectAura[obj.force][buffData.cfgId] = nil
			else
				for _, tar in ipairs(buffData.forceTarget) do
					if tar.id == obj.id then
						self:updateAuraChildBuff(buffData, obj, isOver)
					end
				end
			end
		end
	end
end

function AuraRecord:onAuraEffect()
	local checkMap = {
		{},
		{}
	}

	for _, buffData in ipairs(self.buffList) do
		local force = buffData.holder.force
		local cfgId = buffData.cfgId

		if not checkMap[force][cfgId] and self.scene:getFieldObject(buffData.holder.id) then
			checkMap[force][cfgId] = true

			self:updateEffectAura(buffData, false)
		end
	end
end

function AuraRecord:filter_order_item(v)
	local cfgId, buffId = v.cfgId, v.id

	if self.effectAura[1][cfgId] and buffId == self.effectAura[1][cfgId].id then
		return true
	elseif self.effectAura[2][cfgId] and buffId == self.effectAura[2][cfgId].id then
		return true
	else
		return false
	end

	return false
end

local SceneBuffRecordMap = {
	replaceBuffHolder = ReplaceBuffHolderRecord,
	aura = AuraRecord,
	occupiedSeat = OccupiedSeatRecord
}
local SceneBuffRecordManager = class("SceneBuffRecordManager")

function SceneBuffRecordManager:ctor(scene)
	self.scene = scene
	self.record = {}

	for k, record in maptools.order_pairs(SceneBuffRecordMap) do
		self.record[k] = record.new(self.scene)

		self.record[k]:init()
	end
end

function SceneBuffRecordManager:getRecord(type)
	return self.record[type]
end

function SceneBuffRecordManager:influenceSceneBuff(iType, obj, state)
	for k, record in maptools.order_pairs(SceneBuffRecordMap) do
		self.record[k]:influenceSceneBuff(iType, obj, state)
	end
end

return SceneBuffRecordManager
