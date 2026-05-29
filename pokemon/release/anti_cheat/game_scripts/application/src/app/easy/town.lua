-- chunkname: @src.app.easy.town

local UNLOCK_TYPE = game.UNLOCK_TYPE
local townDataEasy = {}

globals.townDataEasy = townDataEasy

function townDataEasy.getSkillCfg(skillID, advance, star)
	advance = advance or 0
	star = star or 0

	if skillID == 0 then
		return nil, skillID
	end

	if gTownSkillCsv[skillID] then
		local skillCsv = gTownSkillCsv[skillID][1]

		if advance < skillCsv.needAdvance or star < skillCsv.needStar then
			return nil, skillID
		end

		for i = table.nums(gTownSkillCsv[skillID]), 1, -1 do
			local cfg = gTownSkillCsv[skillID][i]

			if advance >= cfg.needAdvance and star >= cfg.needStar then
				return cfg
			end
		end
	end

	return nil
end

function townDataEasy.getCardSkillEffect(skillCfg, factoryID, factoryType, energyCur, num)
	local productEffect = 0
	local inventoryEffect = 0
	local normalEnergyReduce = 0
	local orderEnergyCost = 0
	local orderTimeReduce = 0
	local level = gGameModel.town:read("buildings")[factoryID].level or 1
	local factoryCfg = gTownFactoryCsv[factoryID][level]
	local t = {}

	for i = 1, math.huge do
		local skillType = skillCfg and skillCfg["effect" .. i]

		if skillType then
			t[skillType] = i
		else
			break
		end
	end

	for skillType = 1, itertools.size(game.TOWN_SKILL_EFFECT) do
		if t[skillType] then
			if skillType == game.TOWN_SKILL_EFFECT.A_SPEED_UP then
				local key, val = csvNext(skillCfg["params" .. t[skillType]])
				local n, info = dataEasy.parsePercentStr(val)

				productEffect = info == 0 and productEffect + factoryCfg.efficient * n / 100 or productEffect + n
			elseif skillType == game.TOWN_SKILL_EFFECT.A_INVEOTORY_ADD then
				local key, val = csvNext(skillCfg["params" .. t[skillType]])
				local n, info = dataEasy.parsePercentStr(val)

				inventoryEffect = info == 0 and inventoryEffect + factoryCfg.inventory * n / 100 or inventoryEffect + n
			elseif skillType == game.TOWN_SKILL_EFFECT.A_ENERGY_COST_SUB then
				local key, val = csvNext(skillCfg["params" .. t[skillType]])
				local n, info = dataEasy.parsePercentStr(val)
				local energy = info == 0 and factoryCfg.energyExpend * n / 100 or n

				normalEnergyReduce = math.max(energy, normalEnergyReduce)
			elseif skillType == game.TOWN_SKILL_EFFECT.B_ENERGY_COST_SUB and factoryType == 2 then
				local key, val = csvNext(skillCfg["params" .. t[skillType]])
				local n, info = dataEasy.parsePercentStr(val)

				orderEnergyCost = info == 0 and factoryCfg.energyExpend * n / 100 or n
			elseif skillType == game.TOWN_SKILL_EFFECT.B_TIME_COST_SUB and factoryType == 2 then
				local key, val = csvNext(skillCfg["params" .. t[skillType]])
				local n = dataEasy.parsePercentStr(val)
				local canUpTime = energyCur / (factoryCfg.energyExpend - orderEnergyCost) * 3600
				local useTime = math.min(canUpTime, factoryCfg.orderCostTime * num)

				orderTimeReduce = orderTimeReduce + useTime * n / 100
			end
		end
	end

	local t = {
		productEffect = productEffect,
		inventoryEffect = inventoryEffect,
		normalEnergyReduce = normalEnergyReduce,
		orderEnergyCost = orderEnergyCost,
		orderTimeReduce = orderTimeReduce
	}

	return t
end

function townDataEasy.getExplorerLevel(exploresId)
	local explorers = gGameModel.role:read("explorers")

	if explorers[exploresId] then
		return explorers[exploresId].advance or 0
	end

	return 0
end

function townDataEasy.getExplorerTownSkillLevel(exploresId)
	local explorers = gGameModel.role:read("explorers")

	if explorers[exploresId] then
		return explorers[exploresId].town_skill_level or 0
	end

	return 0
end

function townDataEasy.getExplorerSkillCfg(exploresId)
	local level = townDataEasy.getExplorerTownSkillLevel(exploresId)
	local exploreCsv = csv.explorer.explorer[exploresId]

	return gTownSkillCsv[exploreCsv.townSkill][level]
end

function townDataEasy.getExploreSkillInfo(exploresId)
	local skillEfffect = {}

	if exploresId and exploresId ~= 0 then
		local skillInfo = townDataEasy.getExplorerSkillCfg(exploresId)

		if skillInfo then
			for index = 1, math.huge do
				if skillInfo["effect" .. index] and skillInfo["effect" .. index] ~= 0 then
					table.insert(skillEfffect, {
						type = skillInfo["effect" .. index],
						param = skillInfo["params" .. index]
					})
				else
					break
				end
			end
		end
	end

	return skillEfffect
end

function townDataEasy.getCardEnergy(cardID, advance, star)
	local cardCsv = csv.cards[cardID]
	local unitCsv = csv.unit[cardCsv.unitID]
	local energyCfg = gTwonEnergyCsv[unitCsv.rarity]

	return cardCsv.energy + (energyCfg.advanceAdd * advance + energyCfg.starAdd * star) * cardCsv.energyCorrection
end

function townDataEasy.getCostNum(id)
	local data = gGameModel.town:read("buildings")[id]
	local level = math.min(data.level + 1, itertools.size(gTownBuildingCsv[id]))
	local countTime = cc.clampf(data.finish_time - time.getTime(), 0, gTownBuildingCsv[id][level].levelUpCostTime)
	local rmbCost = math.ceil(countTime / (gCommonConfigCsv.buildingCompletionInterval * 60)) * gCommonConfigCsv.buildingCompletionCost

	return rmbCost
end

function townDataEasy.onBuildingLevelUpTip(id, canFree, callFunc)
	if canFree then
		gGameApp:requestServer("/town/building/finish/atonce", function(tb)
			if callFunc then
				callFunc(tb.view)
			end
		end, id)
	else
		local endTime = gGameModel.town:read("buildings")[id].finish_time

		gGameUI:stackUI("city.town.building_level_up_tip", nil, nil, {
			cb = function()
				local rmb = gGameModel.role:read("rmb")
				local rmbCost = townDataEasy.getCostNum(id)

				if rmb < rmbCost then
					uiEasy.showDialog("rmb")
				else
					gGameApp:requestServer("/town/building/finish/atonce", function(tb)
						if callFunc then
							callFunc(tb.view)
						end
					end, id)
				end
			end,
			finishCb = function()
				gGameApp:requestServer("/town/building/refresh", nil, id)
			end,
			closeTime = endTime,
			buildingId = id
		})
	end
end

function townDataEasy.getBuildingLevelUnlockState(idx, level, isTip, eventual)
	local buildID = next(gTownBuildingTypeCsv[idx])
	local csvInfo = gTownBuildingCsv[buildID][1]
	local buildLevel = 0

	for k, v in pairs(gTownBuildingTypeCsv[idx]) do
		local buildData = gGameModel.town:read("buildings")[k] or {}
		local curLevel = buildData.level or 0

		if buildLevel < curLevel then
			buildLevel = curLevel
			csvInfo = gTownBuildingCsv[k][buildLevel]
		end
	end

	local sign = level <= buildLevel
	local str = string.format(sign and gLanguageCsv.townHomeUnlockTip04 or gLanguageCsv.townHomeUnlockTip05, csvInfo.name, buildLevel, level)

	if isTip then
		str = string.format(gLanguageCsv.townHomeUnlockTip01, csvInfo.name, level)

		if not eventual or eventual == 0 then
			str = str .. gLanguageCsv.townHomeUnlockTipFollow01
		end
	end

	return sign, str
end

function townDataEasy.getTownHomeFurnCountUnlockState(num, _, isTip)
	local homeInfo = gGameModel.town:read("home") or {}
	local placedNum = homeInfo.furniture_placed_num or 0
	local sign = num <= placedNum
	local str = string.format(sign and gLanguageCsv.townHomeUnlockTip06 or gLanguageCsv.townHomeUnlockTip07, placedNum, num)

	if isTip then
		str = string.format(gLanguageCsv.townHomeUnlockTip02, num)
	end

	return sign, str
end

function townDataEasy.getExplorationLevelUnlockState(idx, stage, isTip)
	local adventureInfo = gGameModel.town:read("adventure").areas[idx] or {}
	local adventureStage = adventureInfo.stage or 0
	local csvInfo = csv.town.adventure_area[idx]

	return stage <= adventureStage, string.format(gLanguageCsv.townHomeUnlockTip03, csvInfo.name, stage, csv.town.adventure_stage[stage].stageName)
end

function townDataEasy.getWishTimesUnlockState(num, _, isTip)
	local total = gGameModel.town:read("wish").total
	local sign = num <= total
	local str = string.format(sign and gLanguageCsv.townHomeUnlockTip09 or gLanguageCsv.townHomeUnlockTip10, total, num)

	if isTip then
		str = string.format(gLanguageCsv.townHomeUnlockTip08, total, num)
	end

	return sign, str
end

function townDataEasy.getBuildingUnlockState(typ, param, isTip, eventual)
	local funcs = {
		[UNLOCK_TYPE.BUILDING_LEVEL] = townDataEasy.getBuildingLevelUnlockState,
		[UNLOCK_TYPE.HOME_FURN_COUNT] = townDataEasy.getTownHomeFurnCountUnlockState,
		[UNLOCK_TYPE.EXPLORATION_STAGE] = townDataEasy.getExplorationLevelUnlockState,
		[UNLOCK_TYPE.WISH_TIMES] = townDataEasy.getWishTimesUnlockState
	}

	return funcs[typ](param[1], param[2], isTip, eventual)
end

function townDataEasy.getBuildingUnlockStateAll(csvInfo, isTip)
	local sign = true
	local failList = {}
	local successList = {}

	if csvInfo.open and not townDataEasy.judgeBuildOpen(csvInfo.buildID) then
		sign = false

		table.insert(failList, gLanguageCsv.comingSoon)

		return sign, failList
	end

	for index = 1, math.huge do
		if csvInfo["unlockType" .. index] and csvInfo["unlockType" .. index] ~= 0 then
			local tempSign, info = townDataEasy.getBuildingUnlockState(csvInfo["unlockType" .. index], csvInfo["unlockParams" .. index], isTip, csvInfo["unlockType" .. index + 1])

			if not tempSign then
				sign = false

				table.insert(failList, info)
			else
				table.insert(successList, info)
			end
		else
			break
		end
	end

	if gTownBuildingCsv[csvInfo.buildID] and gTownBuildingCsv[csvInfo.buildID][2] and sign and not gGameModel.town:read("buildings")[csvInfo.buildID] then
		sign = false

		table.insert(failList, gLanguageCsv.comingSoon)
	end

	return sign, failList, successList
end

function townDataEasy.nextLevelUnlockBuilding(level)
	local t = {}

	for k, v in orderCsvPairs(csv.town.building) do
		if v.level == 1 and v.unlockType1 == 1 and v.unlockParams1[2] == level + 1 then
			table.insert(t, string.format("[%s]", v.name))
		end
	end

	return table.concat(t, ",")
end

function townDataEasy.buildingCanLevelUp(buildingId)
	local data = gGameModel.town:read("buildings")[buildingId] or {}
	local maxLevel = itertools.size(gTownBuildingCsv[buildingId])

	if not data.level or maxLevel <= data.level then
		return false, false
	end

	if data.finish_time ~= 0 then
		return false, false
	end

	local buildCsv = gTownBuildingCsv[buildingId][data.level + 1]
	local conditionState = true
	local itemState = true
	local sign, failInfo, successInfo = townDataEasy.getBuildingUnlockStateAll(buildCsv)

	if not sign then
		conditionState = false
	end

	for k, v in csvMapPairs(buildCsv.levelUpCost) do
		local num = dataEasy.getNumByKey(k)

		if num < v then
			itemState = false

			break
		end
	end

	return conditionState, itemState, failInfo, successInfo
end

function townDataEasy.checkExploreSkillUp(skillId, level)
	local skillCfg = gTownSkillCsv[skillId][level + 1]

	if skillCfg then
		for key, value in csvMapPairs(skillCfg.cost) do
			if value > dataEasy.getNumByKey(key) then
				return false
			end
		end
	else
		return false
	end

	return true
end

function townDataEasy.noCardCanbeClick()
	local townCards = gGameModel.town:read("cards")

	for dbId, card in gGameModel.cards:pairs() do
		local cardDatas = card:read("card_id", "level", "star", "advance", "name", "fighting_point")
		local cardCfg = csv.cards[cardDatas.card_id]
		local unitId = cardCfg.unitID
		local unitCsv = csv.unit[unitId]
		local energyMax = 0

		if townCards[dbId] then
			energyMax = townCards[dbId].max_energy
		else
			energyMax = math.floor(townDataEasy.getCardEnergy(cardDatas.card_id, cardDatas.advance, cardDatas.star))
		end

		local skillCfg = townDataEasy.getSkillCfg(cardCfg.townSkill, cardDatas.advance, cardDatas.star)

		if skillCfg and cardCfg.townSkill ~= 0 and energyMax ~= 0 then
			return true
		end
	end

	return false
end

function townDataEasy.getHomeUnlockTipInfo(level)
	local AREA_NAME = {
		gLanguageCsv.homeFloorInfo01,
		gLanguageCsv.homeFloorInfo04,
		gLanguageCsv.homeFloorInfo02,
		gLanguageCsv.homeFloorInfo03
	}
	local curHomeInfo = csv.town.home[level]
	local preHomeInfo = csv.town.home[level - 1]
	local str = ""

	if curHomeInfo.unLockArea ~= preHomeInfo.unLockArea then
		str = str .. string.format(gLanguageCsv.townHomeAreaUnlockTip03, AREA_NAME[curHomeInfo.unLockArea])
	end

	if curHomeInfo.defaultIDs.yard ~= preHomeInfo.defaultIDs.yard then
		str = str .. gLanguageCsv.townHomeAreaUnlockTip05
	end

	if curHomeInfo.isNewFurn then
		str = str .. gLanguageCsv.townHomeAreaUnlockTip02
	end

	str = str .. curHomeInfo.notice1 .. "," .. curHomeInfo.notice2

	return str
end

function townDataEasy.explorationBox()
	local data = gGameModel.town:read("buildings")[game.TOWN_BUILDING_ID.EXPLORATION]
	local adventureInfo = gGameModel.town:read("adventure") or {}
	local missions = adventureInfo.missions or {}
	local areas = adventureInfo.areas

	for i, v in pairs(missions) do
		if v.end_time < time.getTime() then
			return true
		end
	end

	return false
end

function townDataEasy.explorationReward()
	local data = gGameModel.town:read("buildings")[game.TOWN_BUILDING_ID.EXPLORATION]
	local taskInfo = gGameModel.town:read("tasks").stamp or {}

	for i, v in pairs(taskInfo) do
		if v == 1 then
			return true
		end
	end

	return false
end

function townDataEasy.explorationSkillCanUp()
	for k, v in orderCsvPairs(csv.explorer.explorer) do
		local level = townDataEasy.getExplorerTownSkillLevel(k)

		if level ~= 0 then
			local flag = townDataEasy.checkExploreSkillUp(v.townSkill, level)

			if flag then
				return true
			end
		end
	end

	return false
end

function townDataEasy.judgeBuildOpen(id)
	local cfg = gTownBuildingCsv[id][1]

	if not cfg then
		return false
	end

	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})
	local tag = getServerTag(gameKey)
	local id = getServerId(gameKey, true)

	if cfg.open == 3 and tag == "dev" then
		return true
	end

	if cfg.open == 1 and (tag == "dev" or tag == "cn" and id >= 1 and id <= 5) then
		return true
	end

	if cfg.open == 0 then
		return true
	end

	return false
end

function townDataEasy.isPartyOpen(rooms)
	if gGameModel.role:read("cross_town_party_round") == "closed" then
		return false
	end

	local partyTime = csv.town.party[rooms.party_id].time * 60
	local nowTime = time.getTime()
	local cutDown = partyTime - (nowTime - rooms.create_time)

	return cutDown > 0, cutDown, partyTime
end

function townDataEasy.getPartyUID()
	local uid = userDefault.getForeverLocalKey("townPartyUID")

	if uid == 0 then
		return 0
	end

	local data = townDataEasy.findParty(uid)

	if data then
		local open = townDataEasy.isPartyOpen(data)

		if open then
			return uid
		end
	end

	local datas = townDataEasy.getOpenParty()

	for i = #datas, 1, -1 do
		local open = townDataEasy.isPartyOpen(datas[i].model)

		if open then
			return datas[i].model.room_uid
		end
	end

	return 0
end

function townDataEasy.findParty(uid)
	if gGameModel.role:read("cross_town_party_round") == "closed" then
		return
	end

	local partyInfo = gGameModel.town:read("party") or {}
	local roleInfo = partyInfo.role_info or {}

	for k, v in ipairs(roleInfo.rooms or {}) do
		if v.room_uid == uid then
			return v
		end
	end
end

function townDataEasy.getOpenParty()
	if gGameModel.role:read("cross_town_party_round") == "closed" then
		return {}
	end

	local partyDatas = {}
	local partyInfo = gGameModel.town:read("party") or {}
	local roleInfo = partyInfo.role_info or {}

	for k, v in ipairs(roleInfo.rooms or {}) do
		local t = {}
		local open, cutDown, partyTime = townDataEasy.isPartyOpen(v)

		if open then
			table.insert(partyDatas, {
				model = v,
				cutDown = cutDown,
				allTime = partyTime
			})
		end
	end

	return partyDatas
end

function townDataEasy.onPartyEnergyUse(cb, roomID)
	local partyInfo = gGameModel.town:read("party_room").party_roles or {}
	local data = partyInfo[gGameModel.role:read("id")] or {}
	local used = townDataEasy.onPartyRecoverUsed(data)

	if not used and roomID ~= 0 then
		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			cb = function()
				gGameApp:requestServer("/game/town/party/room/change", cb, roomID)
			end,
			content = gLanguageCsv.partyEffectUnusedTips
		})

		return
	end

	cb()
end

function townDataEasy.onPartyRecoverUsed(data)
	if data.recover_used == 1 then
		return true
	end

	return false
end

function townDataEasy.hasPartyTimes()
	local cfg = csv.town.party_base[1]
	local partyInfo = gGameModel.role:read("town_home")
	local townPartyRound = gGameModel.role:read("cross_town_party_round")

	if townPartyRound == "closed" then
		return false
	end

	if not dataEasy.isTownBuildingUnlock(game.TOWN_BUILDING_ID.PARTY) then
		return false
	end

	if not partyInfo or not partyInfo.party_join_count or not partyInfo.party_create_count then
		return false
	end

	if time.getTime() - (partyInfo.party_last_join_time or 0) < cfg.joinCD * 60 then
		return false
	end

	if partyInfo.party_join_count < cfg.joinCount or partyInfo.party_create_count < cfg.createCount then
		return true
	end

	return false
end

function townDataEasy.homeFriends(data)
	if data then
		townDataEasy.__friendDatas = data
	else
		return townDataEasy.__friendDatas or {}
	end
end

function townDataEasy.getSortData()
	local roleData = gGameModel.town:read("party_room").party_roles
	local mydbid = gGameModel.role:read("id")
	local orderTab = {}

	for dbid, v in pairs(roleData) do
		local temp = v

		if mydbid == dbid then
			temp = table.deepcopy(v, true)
			temp.isSelf = true
		end

		if temp.dart.dart_use_num > 0 then
			table.insert(orderTab, temp)
		end
	end

	table.sort(orderTab, function(a, b)
		if a.dart.evaluate ~= b.dart.evaluate then
			return a.dart.evaluate > b.dart.evaluate
		end

		if a.dart.score ~= b.dart.score then
			return a.dart.score > b.dart.score
		end

		return a.dart.last_time < b.dart.last_time
	end)

	return orderTab
end

function townDataEasy.ctorHomeFriendData(tb)
	local data = {}

	for _, v in ipairs(tb.view.roles) do
		if v.town_home_visit then
			local homeData = {
				liked = 0,
				decorativeness = v.town_home_decorativeness,
				town_db_id = v.town_home_visit
			}

			table.insert(data, {
				town_home = homeData,
				role = {
					level = v.level,
					frame = v.frame,
					id = v.id,
					logo = v.logo,
					name = v.name,
					vip_level = v.vip_level
				},
				town_home_layout_version = v.town_home_layout_version
			})
		end
	end

	return data
end
