-- chunkname: @src.battle.models.buff.buff_global

globals.BuffGlobalModel = class("BuffGlobalModel")

local BuffLimitType = {
	object = 1,
	holderForce = 2
}

function BuffGlobalModel:ctor()
	self.triggerType3Record = {
		{},
		{}
	}
	self.damageLinkRecord = {}
	self.buffLinkRecord = {}
	self.weatherData = {
		{},
		{}
	}
	self.weathers = {}
	self.weatherBuffInfos = {
		{},
		{}
	}
	self.weatherRelation = battle.WeatherRelation.coexist
	self.triggerLimitRecordTb = {}

	for k, v in pairs(BuffLimitType) do
		self.triggerLimitRecordTb[v] = {}
	end

	self.cfgIdToLimitType = {}
	self.effectToBuffs = {}
end

function BuffGlobalModel:initWeahterData(operateForce, extraOut)
	local extra = extraOut or {}

	if extra[1] and next(extra[1]) or extra[2] and next(extra[2]) then
		if extra[1].weather or extra[2].weather then
			local weather = extra[1] and extra[1].weather
			local defenceWeather = extra[2] and extra[2].weather

			self:setWeatherData(1, operateForce == 1 and weather or defenceWeather)
			self:setWeatherData(2, operateForce == 1 and defenceWeather or weather)
		else
			local weathers = {
				{},
				{}
			}

			for i = 1, 2 do
				for _, forceExtra in ipairs(extra[i]) do
					if forceExtra.weather then
						table.insert(weathers[i], forceExtra.weather)
					end
				end
			end

			for i = 1, table.length(weathers[1]) do
				self:setWeatherData(operateForce, weathers[1][i])
			end

			for i = 1, table.length(weathers[2]) do
				self:setWeatherData(3 - operateForce, weathers[2][i])
			end
		end
	end
end

function BuffGlobalModel:enterTimePiontChosen(scene, force)
	local ret = {}
	local reset = false

	self:pickForceWeahter(force, scene, ret)

	if ret[force] then
		local curBuff = self.weathers[force] and self.weathers[force].buff

		if curBuff then
			local curConfig = self.weathers[force].config

			if curConfig.buffCfgId ~= ret[force].cfgId and ret[force].level >= curConfig.level then
				reset = true
			end
		else
			reset = true
		end

		if reset then
			local holder = scene:getObject(ret[force].holderId)
			local caster = scene:getObject(ret[force].casterId)
			local newBuff, canTakeEffect = addBuffToHero(ret[force].cfgId, holder, caster, ret[force].buffArgs)
		end
	end
end

function BuffGlobalModel:setWeatherData(force, cfgId)
	if not cfgId or cfgId == 0 then
		return
	end

	local weatherID = csv.field_buff_relation[cfgId].weatherType

	for _, v in ipairs(gWeatherActiveCsv[weatherID]) do
		local cardID = v.cardID
		local newData = {
			cfgId = cfgId,
			cfg = csv.field_buff_relation[cfgId],
			cardID = cardID,
			skillId = csv.weather_system.weather[weatherID].skillId
		}

		self.weatherData[force][cardID] = newData
	end
end

function BuffGlobalModel:getWeatherData(force, cardID)
	return self.weatherData[force][cardID]
end

function BuffGlobalModel:makeWeatherArgs(scene)
	local args = {}
	local curW, weatherCfg

	for i = 1, 2 do
		self:cleanBuffInfos(i, scene)

		curW = self.weathers[i]

		if curW then
			weatherCfg = csv.weather_system.weather[curW.config.fieldCfg.weatherType]
			args[i] = {
				cfg = weatherCfg,
				holderIcon = curW.config.holderIcon,
				lifeRound = curW.buff and curW.buff.lifeRound or 0
			}
		end
	end

	args.relation = self.weatherRelation

	return args
end

local function getBuffInfo(levelBuffs, holderId, buffCfgId)
	local ret = {}

	if levelBuffs then
		for idx, buffInfo in ipairs(levelBuffs) do
			if buffInfo.holderId == holderId then
				if buffCfgId and buffInfo.cfgId == buffCfgId then
					return idx, buffInfo
				else
					table.insert(ret, buffInfo)
				end
			end
		end
	end

	return ret
end

local function saveWeatherBuffInfo(buff, forceBuffs)
	local fieldCfg = buff:getEventByKey(battle.ExRecordEvent.fieldBuffRelation)
	local buffInfo = {
		buffArgs = BuffArgs.weatherCopyArgs(buff),
		cfgId = buff.cfgId,
		holderId = buff.holder.id,
		casterId = buff.caster.id,
		isDeath = buff.holder:isDeath(),
		level = fieldCfg.level
	}

	forceBuffs[fieldCfg.level] = forceBuffs[fieldCfg.level] or {}

	local idx, existBuffInfo = getBuffInfo(forceBuffs[fieldCfg.level], buff.holder.id, buff.cfgId)

	if existBuffInfo then
		table.remove(forceBuffs[fieldCfg.level], idx)
	end

	table.insert(forceBuffs[fieldCfg.level], buffInfo)
end

function BuffGlobalModel:tryActiveWeather(scene, objId, force, levels)
	local existBuffInfo = {}

	for _, level in ipairs(levels) do
		local temp = getBuffInfo(self.weatherBuffInfos[force][level], objId)

		arraytools.merge_two_inplace(existBuffInfo, temp)
	end

	local needActive = false

	if next(existBuffInfo) then
		local data = existBuffInfo[ymrand.random(1, table.length(existBuffInfo))]

		if self.weathers[force] and self.weathers[force].buff then
			if data.level > self.weathers[force].config.level then
				self.weathers[force].buff:over({
					endType = battle.BuffOverType.level
				})

				needActive = true
			end
		else
			needActive = true
		end

		if needActive then
			local holder = scene:getObject(data.holderId)
			local caster = scene:getObject(data.casterId)
			local newBuff, canTakeEffect = addBuffToHero(data.cfgId, holder, caster, data.buffArgs)
		end
	end
end

function BuffGlobalModel:setWeatherBuff(force, fieldCfg, buff)
	local reset = false
	local curBuff = self.weathers[force] and self.weathers[force].buff

	if curBuff then
		local curConfig = self.weathers[force].config

		if curConfig.buffCfgId ~= buff.cfgId then
			if fieldCfg.level >= curConfig.level then
				self.weathers[force].buff:over({
					endType = battle.BuffOverType.level
				})

				reset = true
			else
				saveWeatherBuffInfo(buff, self.weatherBuffInfos[force])
				buff:over({
					endType = battle.BuffOverType.level
				})

				return
			end
		end
	else
		reset = true
	end

	if reset then
		self.weathers[force] = {
			buff = buff,
			config = {
				holderIcon = buff.holder.unitCfg.icon,
				fieldCfg = fieldCfg,
				level = fieldCfg.level,
				buffCfgId = buff.cfgId,
				holderId = buff.holder.id
			}
		}
	end

	saveWeatherBuffInfo(buff, self.weatherBuffInfos[force])

	local function relationCheck(cfg_1, cfg_2)
		if cfg_1.level == cfg_2.level then
			local hash_1 = arraytools.hash(cfg_1.restrain)
			local hash_2 = arraytools.hash(cfg_2.restrain)

			if hash_1[cfg_2.id] then
				return battle.WeatherRelation.inEffectL
			elseif hash_2[cfg_1.id] then
				return battle.WeatherRelation.inEffectR
			else
				return battle.WeatherRelation.coexist
			end
		else
			return cfg_1.level > cfg_2.level and battle.WeatherRelation.inEffectL or battle.WeatherRelation.inEffectR
		end
	end

	if self.weathers[3 - force] then
		local result = relationCheck(self.weathers[1].config.fieldCfg, self.weathers[2].config.fieldCfg)

		self.weatherRelation = result
	else
		self.weatherRelation = battle.WeatherRelation.coexist
	end

	if self.weatherRelation ~= battle.WeatherRelation.coexist then
		self:restrainDelWeather(3 - self.weatherRelation)
	end
end

function BuffGlobalModel:cleanBuffInfos(force, scene)
	local levels = {}

	for l, list in pairs(self.weatherBuffInfos[force]) do
		table.insert(levels, l)
	end

	table.sort(levels, function(a, b)
		return b < a
	end)

	for _, level in ipairs(levels) do
		local length = table.length(self.weatherBuffInfos[force][level])

		for i = length, 1, -1 do
			local data = self.weatherBuffInfos[force][level][i]
			local holder = scene:getObject(data.holderId)

			if not holder then
				local curConfig = self.weathers[force] and self.weathers[force].config
				local curBuffCfgId = curConfig and curConfig.buffCfgId
				local curHolder = curConfig and curConfig.holderId

				if data.cfgId == curBuffCfgId and data.holderId == curHolder then
					self.weathers[force].config = nil
					self.weathers[force] = nil
					self.weatherRelation = battle.WeatherRelation.coexist
				end

				table.remove(self.weatherBuffInfos[force][level], i)
			else
				data.isDeath = holder:isDeath()
			end
		end
	end

	return levels
end

function BuffGlobalModel:pickForceWeahter(force, scene, ret)
	local levels = self:cleanBuffInfos(force, scene)
	local finalLv
	local filteredLv = {}

	for _, level in ipairs(levels) do
		if table.length(self.weatherBuffInfos[force][level]) > 0 then
			for idx, data in ipairs(self.weatherBuffInfos[force][level]) do
				if not data.isDeath then
					table.insert(filteredLv, idx)
				end
			end

			if table.length(filteredLv) > 0 then
				finalLv = level

				break
			end
		end
	end

	if finalLv then
		local idx = random.sample(filteredLv, 1, ymrand.random)
		local finalIdx = idx[1]

		ret[force] = self.weatherBuffInfos[force][finalLv][finalIdx]
	end
end

function BuffGlobalModel:onWeatherOver(force, scene, buff, args)
	local levelOver = args.overType == battle.BuffOverType.level

	if not levelOver then
		local fieldCfg = buff:getEventByKey(battle.ExRecordEvent.fieldBuffRelation)
		local idx, dataInfo = getBuffInfo(self.weatherBuffInfos[force][fieldCfg.level], buff.holder.id, buff.cfgId)

		if dataInfo then
			table.remove(self.weatherBuffInfos[force][fieldCfg.level], idx)
		end
	end

	local needReChosen = false
	local curWeather = self.weathers[force]

	if curWeather then
		if curWeather.config and curWeather.config.buffCfgId == buff.cfgId and curWeather.config.holderId == buff.holder.id then
			curWeather.config = nil
		end

		if curWeather.buff and buff.id == curWeather.buff.id then
			self.weathers[force].buff = nil
		end

		if not curWeather.config and not curWeather.buff then
			self.weathers[force] = nil

			if not levelOver then
				needReChosen = true
			end
		end
	end

	local datas = {}

	if needReChosen then
		self:pickForceWeahter(force, scene, datas)
	end

	if self.weatherRelation ~= battle.WeatherRelation.coexist then
		self:cleanBuffInfos(3 - force, scene)

		local config = self.weathers[3 - force] and self.weathers[3 - force].config

		if config then
			local idx, existBuffInfo = getBuffInfo(self.weatherBuffInfos[3 - force][config.level], config.holderId, config.buffCfgId)

			if existBuffInfo then
				datas[3 - force] = existBuffInfo
			else
				self:pickForceWeahter(3 - force, scene, datas)
			end
		else
			self:pickForceWeahter(3 - force, scene, datas)
		end
	end

	for i = 1, 2 do
		if datas[i] then
			local holder = scene:getObject(datas[i].holderId)
			local caster = scene:getObject(datas[i].casterId)
			local newBuff, canTakeEffect = addBuffToHero(datas[i].cfgId, holder, caster, datas[i].buffArgs)
		end
	end
end

function BuffGlobalModel:restrainDelWeather(force)
	if not self.weathers[force].buff then
		return
	end

	local buff = self.weathers[force].buff

	self.weathers[force].buff = nil

	local params = {
		endType = battle.BuffOverType.restrain
	}

	buff:over(params)
end

function BuffGlobalModel:setDamageLinkRecord(objID, cfgID, damageLinkArgs)
	if not self.damageLinkRecord[cfgID] then
		self.damageLinkRecord[cfgID] = {}
	end

	self.damageLinkRecord[cfgID][objID] = damageLinkArgs
end

function BuffGlobalModel:getDamageLinkRecord(objID, cfgID)
	if self.damageLinkRecord[cfgID] and self.damageLinkRecord[cfgID][objID] then
		return self.damageLinkRecord[cfgID][objID]
	end

	return nil
end

function BuffGlobalModel:cleanDamageLinkRecord(objID, cfgID)
	self.damageLinkRecord[cfgID][objID] = nil
end

function BuffGlobalModel:getDamageLinkObjs(objID, cfgID)
	if not self.damageLinkRecord[cfgID] then
		return {}
	end

	if self.damageLinkRecord[cfgID][objID].oneWay == 1 then
		return {}
	end

	local casterId = self.damageLinkRecord[cfgID][objID].casterId
	local ret = {}

	for k, v in pairs(self.damageLinkRecord[cfgID]) do
		if k ~= objID and v.casterId == casterId and v.oneWay ~= 2 then
			table.insert(ret, k)
		end
	end

	table.sort(ret)

	return ret
end

function BuffGlobalModel:getDamageLinkValue(objID, cfgID)
	if not self.damageLinkRecord[cfgID] then
		return nil
	end

	return self.damageLinkRecord[cfgID][objID].value
end

function BuffGlobalModel:setBuffLinkValue(srcObjID, dstObjID, fixValue, groups, cfgId)
	if not self.buffLinkRecord[srcObjID] then
		self.buffLinkRecord[srcObjID] = {}
	end

	self.buffLinkRecord[srcObjID][dstObjID] = {
		fixValue = fixValue,
		groups = groups,
		cfgId = cfgId
	}
end

function BuffGlobalModel:getAllBuffLinkValue(srcObjID)
	return self.buffLinkRecord[srcObjID]
end

function BuffGlobalModel:onBuffLinkOver(cfgId)
	local toDelTb = {}

	for k, v in pairs(self.buffLinkRecord) do
		for k2, v2 in pairs(v) do
			if v.cfgId == cfgId then
				table.insert(toDelTb, {
					srcObjID = k,
					dstObjID = k2
				})
			end
		end
	end

	table.sort(toDelTb, function(a, b)
		if a.srcObjID ~= b.srcObjID then
			return a.srcObjID < b.srcObjID
		else
			return a.dstObjID < b.dstObjID
		end
	end)

	for k, v in ipairs(toDelTb) do
		self.buffLinkRecord[v.srcObjID][v.dstObjID] = nil
	end
end

function BuffGlobalModel:initBuffCfgLimit(cfgId, data)
	local ret = {
		type = data.type,
		limit = data.limit
	}

	return ret
end

function BuffGlobalModel:refreshBuffLimit(scene, buff)
	if not buff.gateLimit then
		return
	end

	if not self.cfgIdToLimitType[buff.cfgId] then
		self.cfgIdToLimitType[buff.cfgId] = true

		for _, v in ipairs(buff.gateLimit) do
			if v.scenes then
				if itertools.include(v.scenes, scene.gateType) then
					self.cfgIdToLimitType[buff.cfgId] = self:initBuffCfgLimit(buff.cfgId, v)
				end
			else
				self.cfgIdToLimitType[buff.cfgId] = self:initBuffCfgLimit(buff.cfgId, v)
			end
		end
	end

	if self.cfgIdToLimitType[buff.cfgId] == true then
		return
	end

	local def = self.cfgIdToLimitType[buff.cfgId]

	if def.absForce and def.absForce ~= buff.holder.force and (def.type == BuffLimitType.object or def.type == BuffLimitType.holderForce) then
		self.cfgIdToLimitType[buff.cfgId] = true

		return
	end

	local ret

	if not self.triggerLimitRecordTb[def.type][buff.cfgId] then
		self.triggerLimitRecordTb[def.type][buff.cfgId] = {}
	end

	ret = self.triggerLimitRecordTb[def.type][buff.cfgId]

	local record
	local holder = buff.holder

	if def.type == BuffLimitType.object then
		ret[holder.id] = ret[holder.id] or {
			time = 0,
			limit = def.limit
		}
		record = ret[holder.id]
	elseif def.type == BuffLimitType.holderForce then
		ret[holder.force] = ret[holder.force] or {
			time = 0,
			limit = def.limit
		}
		record = ret[holder.force]
	end

	if record.time < record.limit then
		record.time = record.time + 1
	else
		record.time = record.limit
	end
end

function BuffGlobalModel:refreshBuffEffectNums(buff, limitNum)
	local easyEffectFunc = buff.csvCfg.easyEffectFunc

	if not self.effectToBuffs[easyEffectFunc] then
		self.effectToBuffs[easyEffectFunc] = CVector.new()
	end

	while limitNum <= self.effectToBuffs[easyEffectFunc]:size() do
		local ovreBuff = self.effectToBuffs[easyEffectFunc]:pop_front()

		ovreBuff:over()
	end

	self.effectToBuffs[easyEffectFunc]:push_back(buff)
end

function BuffGlobalModel:checkBuffCanAdd(buff, holder)
	local def = self.cfgIdToLimitType[buff.cfgId]

	if not buff.csvCfg.gateLimit then
		return true
	end

	if not def or def == true then
		return true
	end

	local data = self.triggerLimitRecordTb[def.type][buff.cfgId]

	if not data then
		return true
	end

	if def.type == BuffLimitType.object then
		if not data[holder.id] then
			return true
		end

		return data[holder.id].time < data[holder.id].limit
	elseif def.type == BuffLimitType.holderForce then
		if not data[holder.force] then
			return true
		end

		return data[holder.force] and data[holder.force].time < data[holder.force].limit
	end

	return true
end
