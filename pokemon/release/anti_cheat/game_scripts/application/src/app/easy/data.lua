-- chunkname: @src.app.easy.data

local zawakeTools = require("app.views.city.zawake.tools")
local insert = table.insert
local SPRITE_EVENT_TEXT_TAG = 2408301054
local dataEasy = {}

globals.dataEasy = dataEasy

function dataEasy.stringMapingID(key)
	return game.ITEM_STRING_ENUM_TABLE[key] or key
end

function dataEasy.isFragment(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.EQUIP_CSVID_LIMIT and id <= game.FRAGMENT_CSVID_LIMIT
end

function dataEasy.isFragmentCard(id)
	if dataEasy.isFragment(id) and csv.fragments[id] and csv.fragments[id].type == 1 then
		return true
	end

	return false
end

function dataEasy.isHeldItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.FRAGMENT_CSVID_LIMIT and id <= game.HELD_ITEM_CSVID_LIMIT
end

function dataEasy.isGemItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.HELD_ITEM_CSVID_LIMIT and id <= game.GEM_CSVID_LIMIT
end

function dataEasy.isZawakeFragment(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.GEM_CSVID_LIMIT and id <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT
end

function dataEasy.isChipItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.ZAWAKE_FRAGMENT_CSVID_LIMIT and id <= game.CHIP_CSVID_LIMIT
end

function dataEasy.isFurnitureItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.CHIP_CSVID_LIMIT and id <= game.FURNITURE_CSVID_LIMIT
end

function dataEasy.isTotemItem(id)
	if type(id) ~= "number" then
		return false
	end

	if id > game.ITEM_CSVID_LIMIT then
		return false
	end

	local cfg = csv.items[id]

	return cfg and cfg.type == game.ITEM_TYPE_ENUM_TABLE.totemType
end

function dataEasy.isContractItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.FURNITURE_CSVID_LIMIT and id <= game.CONTRACT_CSVID_LIMIT
end

function dataEasy.isAidAdvanceMaterialItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.CONTRACT_CSVID_LIMIT and id <= game.AID_ADVANCE_MATERIAL_CSVID_LIMIT
end

function dataEasy.isAidAwakeMaterialItem(id)
	if type(id) ~= "number" then
		return false
	end

	return id > game.AID_ADVANCE_MATERIAL_CSVID_LIMIT and id <= game.AID_AWAKE_MATERIAL_CSVID_LIMIT
end

local csvItems = csv.items
local csvEquips = csv.equips
local csvFragments = csv.fragments
local csvHelditems = csv.held_item.items
local csvGem = csv.gem.gem
local csvZawakeFragments = csv.zawake.zawake_fragments
local csvChips = csv.chip.chips
local csvFurniture = csv.town.home_furniture
local csvContract = csv.contract.contract
local csvAidMaterial = csv.aid.material

function dataEasy.getCfgByKey(key)
	local id = dataEasy.stringMapingID(key)

	if not id or type(id) == "string" then
		printError("key(%s) was not in game.ITEM_STRING_ENUM_TABLE", key)

		return
	end

	local cfg

	if id <= game.ITEM_CSVID_LIMIT then
		cfg = csvItems[id]
	elseif id <= game.EQUIP_CSVID_LIMIT then
		cfg = csvEquips[id]
	elseif id <= game.FRAGMENT_CSVID_LIMIT then
		cfg = csvFragments[id]
	elseif id <= game.HELD_ITEM_CSVID_LIMIT then
		cfg = csvHelditems[id]
	elseif id <= game.GEM_CSVID_LIMIT then
		cfg = csvGem[id]
	elseif id <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		cfg = csvZawakeFragments[id]
	elseif id <= game.CHIP_CSVID_LIMIT then
		cfg = csvChips[id]
	elseif id <= game.FURNITURE_CSVID_LIMIT then
		cfg = csvFurniture[id]
	elseif key <= game.CONTRACT_CSVID_LIMIT then
		cfg = csvContract[id]
	elseif key <= game.AID_AWAKE_MATERIAL_CSVID_LIMIT then
		cfg = csvAidMaterial[id]
	end

	if not cfg then
		printError("id(%d) was not in csv", id)
	end

	return cfg
end

function dataEasy.getIconResByKey(key)
	return ui.COMMON_ICON[key] or dataEasy.getCfgByKey(key).icon
end

local specialRoleKey = {
	role_exp = "level_exp",
	vip = "vip_level",
	vip_exp = "vip_sum"
}

local function getNumByKeyType(model, key, _type, params)
	if _type == 1 then
		local count = 0
		local data = gGameModel.role:read(model)

		for _, val in pairs(data) do
			local item = gGameModel[model]:find(val)

			if item:read(params.id) == key then
				count = count + 1
			end
		end

		return count
	end

	if not gGameModel.role:read(model) then
		return 0
	end

	return gGameModel.role:read(model)[key] or 0
end

function dataEasy.getNumByKey(key)
	local str = game.ITEM_STRING_TABLE[key]

	if str then
		errorInWindows("!!! error use item(%s), must use(%s)", key, str)

		return 0
	end

	if type(key) == "string" then
		if key == "gym_talent_point" then
			return gGameModel.role:read("gym_datas").gym_talent_point or 0
		elseif key == "yycoin" then
			return gGameModel.role:getYYCoin()
		else
			key = specialRoleKey[key] or key

			return gGameModel.role:read(key) or 0
		end
	elseif type(key) ~= "number" then
		return 0
	elseif key <= game.EQUIP_CSVID_LIMIT then
		return getNumByKeyType("items", key)
	elseif key <= game.FRAGMENT_CSVID_LIMIT then
		return getNumByKeyType("frags", key)
	elseif key <= game.HELD_ITEM_CSVID_LIMIT then
		return getNumByKeyType("held_items", key, 1, {
			id = "held_item_id"
		})
	elseif key <= game.GEM_CSVID_LIMIT then
		return getNumByKeyType("gems", key, 1, {
			id = "gem_id"
		})
	elseif key <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		return getNumByKeyType("zfrags", key)
	elseif key <= game.CHIP_CSVID_LIMIT then
		return getNumByKeyType("chips", key, 1, {
			id = "chip_id"
		})
	elseif key <= game.FURNITURE_CSVID_LIMIT then
		return getNumByKeyType("furniture", key)
	elseif key <= game.CONTRACT_CSVID_LIMIT then
		return getNumByKeyType("contracts", key, 1, {
			id = "contract_id"
		})
	elseif key <= game.AID_AWAKE_MATERIAL_CSVID_LIMIT then
		return getNumByKeyType("aid_material", key)
	end

	return 0
end

function dataEasy.getListenNumByKey(key)
	local str = game.ITEM_STRING_TABLE[key]

	if str then
		errorInWindows("!!! error use item(%s), must use(%s)", key, str)

		return idler.new(0)
	end

	if type(key) == "string" then
		key = specialRoleKey[key] or key

		if key == "yycoin" then
			return idlereasy.when(gGameModel.role:getIdler("yycoins"), function(_, val)
				return true, gGameModel.role:getYYCoin()
			end)
		end

		return idlereasy.when(gGameModel.role:getIdler(key), function(_, val)
			return true, val or 0
		end)
	elseif type(key) ~= "number" then
		return idler.new(0)
	elseif key <= game.EQUIP_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("items"), function(_, val)
			return true, val[key] or 0
		end)
	elseif key <= game.FRAGMENT_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("frags"), function(_, val)
			return true, val[key] or 0
		end)
	elseif key <= game.ZAWAKE_FRAGMENT_CSVID_LIMIT then
		return idlereasy.when(gGameModel.role:getIdler("zfrags"), function(_, val)
			return true, val[key] or 0
		end)
	end

	return idler.new(0)
end

function dataEasy.getQuality(advance, space)
	local quality = 1

	for i, v in ipairs(game.QUALITY_TO_FITST_ADVANCE) do
		if advance < v then
			break
		end

		quality = i
	end

	local num = advance - game.QUALITY_TO_FITST_ADVANCE[quality]

	if num == 0 then
		return quality, ""
	end

	return quality, string.format("%s+%s", space and " " or "", num)
end

function dataEasy.getCardIdAndStar(idOrTable)
	local cardId, star

	if type(idOrTable) == "table" then
		cardId = idOrTable.id
		star = idOrTable.star
	else
		cardId = idOrTable
	end

	if not star and not csv.cards[cardId] then
		printError("check cardId, %s was not exist in csv.cards", tostring(cardId))
	end

	star = star or csv.cards[cardId].star

	return cardId, star
end

function dataEasy.getRawTable(tb)
	local ret = {}
	local t = tb.view and (tb.view.result or tb.view) or tb
	local extra = tb.view and tb.view.extra or {}
	local specialData = {
		card = {},
		card2frag = {},
		card2mail = {},
		item = {},
		heldItem = {}
	}
	local isHaveCard2Frag = false

	for k, v in pairs(t) do
		if k == "carddbIDs" then
			for _, data in ipairs(v) do
				local card = gGameModel.cards:find(data[1])
				local cardId = card:read("card_id")
				local star = card:read("star")

				insert(specialData.card, {
					specialFlag = "card",
					key = "card",
					num = {
						id = cardId,
						star = star
					},
					dbid = data[1],
					new = data[2]
				})
			end
		elseif k == "card2fragL" then
			isHaveCard2Frag = true
		elseif k == "card2mailL" then
			for _, data in ipairs(v) do
				insert(specialData.card2mail, {
					specialFlag = "card2mail",
					key = "card",
					num = data
				})
			end
		elseif k == "items" then
			for _, data in ipairs(v) do
				if not dataEasy.isChipItem(data[1]) then
					insert(specialData.item, {
						key = data[1],
						num = data[2]
					})
				end
			end
		elseif k == "star_skill_points" then
			for markId, num in pairs(v) do
				insert(ret, {
					key = k .. "_" .. markId,
					num = num
				})
			end
		elseif k == "chipdbIDs" then
			for _, dbId in ipairs(v) do
				local chip = gGameModel.chips:find(dbId)
				local chipId = chip:read("chip_id")

				insert(specialData.item, {
					num = 1,
					key = chipId,
					dbId = dbId
				})
			end
		elseif k == "ret" then
			printWarn("invalid getRawTable %s", dumps(t))
		elseif type(v) == "number" then
			if not dataEasy.isChipItem(k) then
				insert(ret, {
					key = k,
					num = v
				})
			end
		elseif not itertools.include(game.SERVER_RAW_MODEL_KEY, k) then
			if type(v) == "table" then
				for id, num in pairs(v) do
					insert(ret, {
						key = id,
						num = num
					})
				end
			else
				insert(ret, {
					key = k,
					num = v
				})
			end
		end
	end

	local isFull = not itertools.isempty(t.card2mailL)

	return ret, specialData, isFull, isHaveCard2Frag, extra
end

function dataEasy.mergeRawDate(data)
	local ret, specialData, isFull, isHaveCard2Frag, extra = dataEasy.getRawTable(data)
	local flagOrder = {
		"card",
		"card2mail"
	}
	local t = {}

	for _, flag in ipairs(flagOrder) do
		for _, v in ipairs(specialData[flag]) do
			v.specialFlag = flag

			insert(t, v)
		end
	end

	local sortRet = {}
	local mergeRet = {}

	for _, v in ipairs(ret) do
		if type(v.num) == "number" then
			mergeRet[v.key] = mergeRet[v.key] or 0
			mergeRet[v.key] = mergeRet[v.key] + v.num
		end
	end

	for k, v in pairs(mergeRet) do
		table.insert(sortRet, {
			key = k,
			num = v
		})
	end

	table.sort(sortRet, dataEasy.sortItemCmp)
	arraytools.merge_inplace(t, {
		specialData.item,
		sortRet
	})

	local newExtra = {}

	for k, v in pairs(extra) do
		if type(v) == "table" then
			for id, num in pairs(v) do
				table.insert(newExtra, {
					specialKey = "extra",
					key = id,
					num = num
				})
			end
		else
			table.insert(newExtra, {
				specialKey = "extra",
				key = k,
				num = v
			})
		end
	end

	if #newExtra > 0 then
		table.sort(newExtra, dataEasy.sortItemCmp)
		table.sort(newExtra, function(a, b)
			if a.specialKey ~= "extra" and b.specialKey == "extra" then
				return true
			end

			if a.specialKey == "extra" and b.specialKey ~= "extra" then
				return false
			end

			return false
		end)

		local newT = {}

		arraytools.merge_inplace(newT, {
			t,
			newExtra
		})

		t = newT
	end

	return t, isFull, isHaveCard2Frag
end

function dataEasy.getItemData(data, noSort)
	local itemData = {}

	if itertools.isarray(data) then
		if data[1] and itertools.isarray(data[1]) then
			for _, v in ipairs(data) do
				table.insert(itemData, {
					key = v[1],
					num = v[2],
					decomposed = v[3] == 1
				})
			end
		else
			itemData = data
		end
	else
		for k, v in csvMapPairs(data) do
			if k == "cards" then
				for _, id in ipairs(v) do
					table.insert(itemData, {
						key = "card",
						num = id
					})
				end
			elseif not itertools.include(game.SERVER_RAW_MODEL_KEY, k) then
				table.insert(itemData, {
					key = k,
					num = v
				})
			end
		end
	end

	if not noSort then
		table.sort(itemData, dataEasy.sortItemCmp)
	end

	return itemData
end

local function getItemSortKey(a)
	if a.key == 399 then
		return 1000000
	end

	local key = a.key
	local ret = 0

	local function add(v)
		ret = ret * 2 + (v and 1 or 0)
	end

	add(game.ITEM_EXP_HASH[key])
	add(key == "card")
	add(dataEasy.isFragment(key))
	add(game.ITEM_STRING_ENUM_TABLE[key])

	return ret
end

function dataEasy.sortItemCmp(a, b)
	local ia = getItemSortKey(a)
	local ib = getItemSortKey(b)

	if ia ~= ib then
		return ib < ia
	end

	if a.key == "card" and b.key == "card" then
		local cardIdA = dataEasy.getCardIdAndStar(a.num)
		local cardIdB = dataEasy.getCardIdAndStar(b.num)

		return cardIdA < cardIdB
	end

	if type(a.key) == "string" and type(b.key) == "string" and string.find(a.key, "star_skill_points_%d+") and string.find(b.key, "star_skill_points_%d+") then
		local markIdA = tonumber(string.sub(a.key, string.find(a.key, "%d+")))
		local markIdB = tonumber(string.sub(b.key, string.find(b.key, "%d+")))

		return markIdA < markIdB
	end

	local cfgA, cfgB

	if type(a.key) == "string" and string.find(a.key, "star_skill_points_%d+") then
		return true
	else
		cfgA = dataEasy.getCfgByKey(a.key)
	end

	if type(b.key) == "string" and string.find(b.key, "star_skill_points_%d+") then
		return false
	else
		cfgB = dataEasy.getCfgByKey(b.key)
	end

	if not cfgA or not cfgB then
		return false
	end

	if cfgA.quality ~= cfgB.quality then
		return cfgA.quality > cfgB.quality
	end

	return dataEasy.stringMapingID(a.key) < dataEasy.stringMapingID(b.key)
end

function dataEasy.sortHelditemCmp(a, b)
	if a.cfg.quality ~= b.cfg.quality then
		return a.cfg.quality > b.cfg.quality
	end

	if a.isDress ~= b.isDress then
		return a.isDress
	end

	if a.isExc ~= b.isExc then
		return a.isExc
	end

	if a.csvId ~= b.csvId then
		return a.csvId < b.csvId
	end

	if a.advance ~= b.advance then
		return a.advance > b.advance
	end

	if a.lv ~= b.lv then
		return a.lv > b.lv
	end

	return a.num < b.num
end

function dataEasy.getRoleLogoIcon(logoId)
	local cfg = gRoleLogoCsv[logoId]

	if cfg then
		return cfg.icon
	end

	return gRoleLogoCsv[1].icon
end

function dataEasy.getRoleFigureIcon(figureId)
	local cfg = gRoleFigureCsv[figureId]

	if cfg then
		return cfg.res
	end

	return gRoleFigureCsv[1].res
end

function dataEasy.getRoleFrameIcon(frameId)
	local cfg = gRoleFrameCsv[frameId]

	if cfg then
		return cfg.icon
	end

	return gRoleFrameCsv[1].icon
end

function dataEasy.getBuffShow(str)
	if string.find(str, "%%") then
		return str
	else
		return tonumber(str) / 100 .. "%"
	end
end

function dataEasy.getAttrValueString(key, val)
	local hasPercent = string.find(val, "%%")

	if not hasPercent and not game.ATTRDEF_SHOW_NUMBER[key] then
		if not tonumber(val) then
			return tostring(val)
		end

		return tonumber(val) / 100 .. "%"
	end

	return tostring(val)
end

function dataEasy.attrAddition(a, b)
	if not a then
		return b
	end

	local hasPercent = string.find(b, "%%")

	if not hasPercent then
		return a + b
	end

	return string.sub(a, 1, #a - 1) + string.sub(b, 1, #b - 1) .. "%"
end

function dataEasy.attrSubtraction(a, b)
	if not a then
		return -b
	end

	local hasPercent = string.find(b, "%%")

	if not hasPercent then
		return a - b
	end

	return string.sub(a, 1, #a - 1) - string.sub(b, 1, #b - 1) .. "%"
end

function dataEasy.getGateAddition(privilegeType)
	local map = {
		[game.PRIVILEGE_TYPE.HuodongTypeGoldTimes] = "huodongGoldTimes",
		[game.PRIVILEGE_TYPE.HuodongTypeGoldDropRate] = "huodongGoldDropRate",
		[game.PRIVILEGE_TYPE.HuodongTypeGiftTimes] = "huodongGiftTimes",
		[game.PRIVILEGE_TYPE.HuodongTypeGiftDropRate] = "huodongGiftDropRate",
		[game.PRIVILEGE_TYPE.HuodongTypeExpTimes] = "huodongExpTimes",
		[game.PRIVILEGE_TYPE.HuodongTypeExpDropRate] = "huodongExpDropRate",
		[game.PRIVILEGE_TYPE.HuodongTypeFragTimes] = "huodongFragTimes",
		[game.PRIVILEGE_TYPE.HuodongTypeFragDropRate] = "huodongFragDropRate",
		[game.PRIVILEGE_TYPE.HuodongTypeContractTimes] = "huodongContractTimes",
		[game.PRIVILEGE_TYPE.HuodongTypeContractDropRate] = "huodongContractDropRate"
	}
	local monthCardView = require("app.views.city.activity.month_card")
	local extra = monthCardView.getPrivilegeAddition(map[privilegeType])
	local privilegeNum = dataEasy.getPrivilegeVal(privilegeType)

	return privilegeNum + (extra or 0)
end

function dataEasy.getPrivilegeVal(privilegeType, targetType)
	local trainerLevel = gGameModel.role:read("trainer_level")
	local trainerSkills = gGameModel.role:read("trainer_skills")
	local isStaminaGain = privilegeType == game.PRIVILEGE_TYPE.StaminaGain
	local isBattleSkip = privilegeType == game.PRIVILEGE_TYPE.BattleSkip
	local isGateSaoDangTimes = privilegeType == game.PRIVILEGE_TYPE.GateSaoDangTimes

	if not dataEasy.isUnlock(gUnlockCsv.trainer) then
		if isStaminaGain then
			return {}
		elseif isBattleSkip then
			return false
		else
			return 0
		end
	end

	local data = {}
	local allNum = 0
	local saodangTimes = 0

	for i = 1, trainerLevel do
		local privilege, val = csvNext(csv.trainer.trainer_level[i].privilege)

		if privilege == privilegeType then
			if isStaminaGain then
				for i = 1, 4 do
					data[i] = val
				end
			elseif isBattleSkip then
				data[val] = 1
			elseif isGateSaoDangTimes then
				saodangTimes = math.max(val, saodangTimes)
			else
				allNum = allNum + val
			end
		end
	end

	for k, v in pairs(trainerSkills) do
		local cfg = csv.trainer.skills[k]

		if cfg.type == privilegeType then
			if isStaminaGain then
				if v > 0 then
					data[cfg.arg] = (data[cfg.arg] or 0) + cfg.nums[v]
				end
			elseif isBattleSkip then
				data[cfg.nums[1]] = 1
			else
				table.insert(data, {
					cfg = cfg,
					id = k
				})

				local level = trainerSkills[k]
				local num = cfg.nums[level] or 0

				allNum = allNum + num
			end
		end
	end

	if isStaminaGain then
		return data
	end

	if isBattleSkip then
		return targetType and data[targetType] == 1
	end

	if isGateSaoDangTimes then
		return saodangTimes
	end

	return allNum
end

function dataEasy.getStaminaMax(level, trainerLevel)
	local max = gRoleLevelCsv[level].staminaMax
	local monthCardView = require("app.views.city.activity.month_card")
	local extra = monthCardView.getPrivilegeAddition("staminaExtraMax")

	if trainerLevel then
		extra = (extra or 0) + dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.StaminaMax)
	end

	max = max + (extra or 0)

	return max, extra
end

function dataEasy.getStamina()
	local level = gGameModel.role:read("level")
	local stamina = gGameModel.role:read("stamina")
	local staminaLRT = gGameModel.role:read("stamina_last_recover_time")
	local trainerLevel = gGameModel.role:read("trainer_level")
	local max = dataEasy.getStaminaMax(level, trainerLevel)

	if max <= stamina then
		return stamina
	end

	local dt = math.max(time.getTime() - staminaLRT, 0)
	local curStamina = stamina + math.floor(dt / game.STAMINA_COLD_TIME)

	if max <= curStamina then
		return max
	end

	return curStamina
end

function dataEasy.getSkillPointMax(roleLv)
	local max = csv.base_attribute.role_level[roleLv].skillPointMax
	local monthCardView = require("app.views.city.activity.month_card")
	local extra = monthCardView.getPrivilegeAddition("skillPointExtraMax")

	max = max + (extra or 0)

	return max, extra
end

function dataEasy.parsePercentStr(str)
	local pos = string.find(str, "%%")
	local numType, val = game.NUM_TYPE.number, tonumber(str)

	if pos then
		numType = game.NUM_TYPE.percent
		val = string.sub(str, 1, pos - 1)
	end

	return tonumber(val), numType
end

function dataEasy.getPercentStr(num, numType, pow)
	pow = pow or 1

	local str = tostring(num * pow)

	if numType == game.NUM_TYPE.percent then
		str = str .. "%"
	end

	return str
end

function dataEasy.serverOpenDaysLess(day)
	if not game.SERVER_OPENTIME then
		return true
	end

	local d = time.getDate(game.SERVER_OPENTIME)
	local openHour = d.hour
	local t = time.getTimeTable()
	local rawHour = t.hour
	local delta = time.getTimestamp(t, 0) - time.getTimestamp(d, 0)
	local oneday = 86400
	local refreshHour = time.getRefreshHour()

	if openHour < refreshHour then
		delta = delta + oneday
	end

	if rawHour < refreshHour then
		delta = delta - oneday
	end

	if delta / oneday < day - 1 then
		return true, delta / oneday
	end

	return false
end

function dataEasy.isQuitUnionToday()
	local quitTime = gGameModel.role:read("union_quit_time")

	if quitTime == nil then
		return false
	end

	local time2 = time.getTimeTable()
	local time3 = time.getTimestamp(time2, 5)
	local currentTime = time.getTime()

	if currentTime < time3 then
		local time4 = time3 - 86400

		return time4 < quitTime
	else
		return time3 < quitTime
	end
end

function dataEasy.isJoinUnionToday()
	local joinTime = gGameModel.role:read("union_join_time")
	local time2 = time.getTimeTable()
	local time3 = time.getTimestamp(time2, 5)
	local currentTime = time.getTime()

	if currentTime < time3 then
		local time4 = time3 - 86400

		return time4 < joinTime
	else
		return time3 < joinTime
	end
end

function dataEasy.isUnionBuildProtectionTime()
	local createdTime = gGameModel.role:read("created_time")
	local currentTime = time.getTime()
	local time2 = time.getDate(createdTime)
	local protectionTime = gCommonConfigCsv.newbieUnionQuitProtectDays
	local time3 = time.getTimestamp(time2, 5)

	if time2.hour < 5 then
		time3 = time3 - 86400
	end

	return currentTime < time3 + protectionTime * 3600 * 24
end

function dataEasy.notUseUnionBuild()
	return dataEasy.isQuitUnionToday() and dataEasy.isJoinUnionToday() and not dataEasy.isUnionBuildProtectionTime()
end

function dataEasy.canSystemRedPacket()
	local quitTime = gGameModel.role:read("union_quit_time")

	if quitTime == 0 then
		return true
	end

	local time1 = time.getDate(quitTime)
	local day = time1.hour < 19 and time1.day or time1.day + 1
	local time3 = time.getTimestamp(time1, 19)

	return time3 < time.getTime()
end

function dataEasy.isGateFinished(gateId)
	if not gateId or gateId == 0 then
		return true
	end

	local gateStar = gGameModel.role:read("gate_star") or {}

	if gateStar[gateId] and gateStar[gateId].star and gateStar[gateId].star > 0 then
		return true
	end

	return false
end

function dataEasy.getGateFinished(gateId)
	return idlereasy.when(gGameModel.role:getIdler("gate_star"), function()
		return true, dataEasy.isGateFinished(gateId)
	end)
end

function dataEasy.isShow(key)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end

	local cfg = csv.unlock[key]

	if not cfg then
		return false
	end

	local roleLevel = gGameModel.role:read("level") or 0

	return roleLevel >= math.min(cfg.showLevel, cfg.startLevel)
end

function dataEasy.getListenShow(key, cb)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end

	local cfg = csv.unlock[key]

	if not cfg then
		if cb then
			cb(false)
		end

		return idlereasy.assign(idler.new(false))
	end

	local flag
	local roleLevel = gGameModel.role:getIdler("level")

	return idlereasy.when(roleLevel, function()
		local isShow = dataEasy.isShow(key)

		if cb and flag ~= isShow then
			flag = isShow

			cb(isShow)
		end

		return true, isShow
	end)
end

function dataEasy.isUnlock(key)
	globals.XXVERSION = 3
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end

	local cfg = csv.unlock[key]

	if not cfg then
		return false
	end

	local function xxvCheck()
		if cfg.xxv == 0 then
			return false
		end

		if cfg.xxv == 3 then
			return XXVERSION < 3
		end

		return cfg.xxv ~= XXVERSION
	end

	if xxvCheck() then
		return false
	end

	if not dataEasy.isInServer(cfg.feature) then
		return false
	end

	local roleLevel = 0
	local vipLevel = 0

	if gGameModel.role:getRawIdler_() then
		roleLevel = gGameModel.role:read("level") or 0
		vipLevel = gGameModel.role:read("vip_level") or 0
	end

	return roleLevel >= cfg.startLevel and vipLevel >= cfg.startVip and dataEasy.isGateFinished(cfg.startGate)
end

function dataEasy.getListenUnlock(key, cb)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end

	local cfg = csv.unlock[key]

	if not cfg then
		if cb then
			cb(false)
		end

		return idlereasy.assign(idler.new(false))
	end

	local flag
	local roleLevel = gGameModel.role:getIdler("level")
	local vipLevel = gGameModel.role:getIdler("vip_level")
	local gateFinished = dataEasy.getGateFinished(cfg.startGate)

	return idlereasy.any({
		roleLevel,
		vipLevel,
		gateFinished
	}, function()
		local isUnlock = dataEasy.isUnlock(key)

		if cb and flag ~= isUnlock then
			flag = isUnlock

			cb(isUnlock)
		end

		return true, isUnlock
	end)
end

function dataEasy.isTotemUnlock()
	if not gGameModel.town then
		return false
	end

	if not gGameModel.town:read("buildings") then
		return false
	end

	if not dataEasy.isUnlock(gUnlockCsv.totem) then
		return false
	end

	if not gTownBuildingCsv[game.TOWN_BUILDING_ID.EXPLORATION] then
		return false
	end

	local buildCsv = gTownBuildingCsv[game.TOWN_BUILDING_ID.EXPLORATION][1]
	local sign = townDataEasy.getBuildingUnlockStateAll(buildCsv)

	return sign
end

function dataEasy.isTownVisitUnlock()
	if not gGameModel.town then
		return false
	end

	if not gGameModel.town:read("buildings") then
		return false
	end

	if not gTownBuildingCsv[game.TOWN_BUILDING_ID.TERMINAL] then
		return false
	end

	local buildCsv = gTownBuildingCsv[game.TOWN_BUILDING_ID.TERMINAL][1]
	local sign = townDataEasy.getBuildingUnlockStateAll(buildCsv)

	return sign
end

function dataEasy.isTownBuildingUnlock(buildingId)
	if not gGameModel.town then
		return false
	end

	if not gGameModel.town:read("buildings") then
		return false
	end

	if not gTownBuildingCsv[buildingId] then
		return false
	end

	local buildCsv = gTownBuildingCsv[buildingId][1]
	local sign = townDataEasy.getBuildingUnlockStateAll(buildCsv)

	return sign
end

function dataEasy.isTownRelicBuffUnlock()
	if not gGameModel.town then
		return false
	end

	if not gGameModel.town:read("buildings") then
		return false
	end

	if not gGameModel.town:read("relic_buff") then
		return false
	end

	return true
end

function dataEasy.getChapterInfoByGateID(gateID)
	local GATE_TITLE = {
		gLanguageCsv.gateStory,
		gLanguageCsv.gateDifficult,
		gLanguageCsv.gateNightMare
	}
	local type = math.floor(gateID / 10000)
	local chapterId = math.floor(gateID % 10000 / 100)
	local id = gateID % 100

	return type, chapterId, id, GATE_TITLE[type]
end

function dataEasy.getUnlockTip(key)
	if type(key) == "string" then
		key = gUnlockCsv[key]
	end

	local cfg = csv.unlock[key]

	if not cfg then
		return gLanguageCsv.comingSoon
	end

	if not dataEasy.isInServer(cfg.feature) then
		return gLanguageCsv.comingSoon
	end

	if not dataEasy.isGateFinished(cfg.startGate) then
		local _, chapterId, gateId, str = dataEasy.getChapterInfoByGateID(cfg.startGate)

		return string.format(gLanguageCsv.unlockGate, str .. chapterId, gateId, cfg.name)
	end

	local roleLevel = gGameModel.role:read("level") or 0

	if roleLevel < cfg.startLevel then
		return string.format(gLanguageCsv.unlockLevel, cfg.startLevel, cfg.name)
	end

	local vipLevel = gGameModel.role:read("vip_level") or 0

	if vipLevel < cfg.startVip then
		return string.format(gLanguageCsv.unlockVip, uiEasy.getVipStr(cfg.startVip).str, cfg.name)
	end

	return ""
end

function dataEasy.getCardById(cardId)
	for idx, card in gGameModel.cards:pairs() do
		if card:read("card_id") == cardId then
			return idx
		end
	end
end

function dataEasy.getByMarkId(cardMarkID)
	local gggetCard = getCardById

	for develop, data in pairs(gCardsCsv[cardMarkID]) do
		for branch, card in pairs(data) do
			local ret = gggetCard(card.id)

			if ret then
				return ret
			end
		end
	end
end
-- 暂时用老版
-- @desc 获取努力值的上限
function dataEasy.getCardEffortMax(idx, cardId, attr, advance, level)
	level = level or math.huge -- 如果不填level 则默认等级是符合的
	local cfg = csv.cards[cardId]
	local maxVal = 0
	local total = 0
	local advanceTb = gCardEffortAdvance[cfg.effortSeqID]
	advance = advance or 1
	for val,v in orderCsvPairs(advanceTb) do
		if advance == val then
			maxVal = v[attr]
		end
		if advance > val then
			total = total + v[attr]
		end
	end

	local nextTb = advanceTb[advance + 1]
	local levelE = false
	if nextTb and advance < advanceTb[advance].advanceLimit then
		levelE = nextTb.needLevel <= level
	end

	return maxVal, total, nextTb and true or false, levelE
end
-- function dataEasy.getCardEffortMax(cardId, attr, advance, level)
-- 	level = level or math.huge

-- 	local cfg = csv.cards[cardId]
-- 	local maxVal = 0
-- 	local total = 0
-- 	local advanceTb = gCardEffortAdvance[cfg.effortSeqID]

-- 	advance = advance or 1

-- 	for val, v in orderCsvPairs(advanceTb) do
-- 		if advance == val then
-- 			maxVal = v[attr]
-- 		end

-- 		if val < advance then
-- 			total = total + v[attr]
-- 		end
-- 	end

-- 	local nextTb = advanceTb[advance + 1]
-- 	local levelE = false

-- 	if nextTb and advance < advanceTb[advance].advanceLimit then
-- 		levelE = level >= nextTb.needLevel
-- 	end

-- 	return maxVal, total, nextTb and true or false, levelE
-- end

function dataEasy.getCardEffortExtraMax(attr, advance)
	local maxVal = 0
	local total = 0
	local sumVal = 0
	local advanceTb = gCardEffortExtra

	advance = advance or 1

	for val, v in orderCsvPairs(advanceTb) do
		if advance == val then
			maxVal = v[attr]
		end

		if val < advance then
			total = total + v[attr]
		end

		sumVal = sumVal + v[attr]
	end

	local nextTb = advanceTb[advance + 1]
	local nextLv

	if nextTb then
		nextLv = nextTb[attr]
	end

	return maxVal, total, nextTb and true or false, nextLv, sumVal
end

function dataEasy.getRomanNumeral(num)
	local romanNumeral = {
		"I",
		"II",
		"III",
		"IV",
		"V",
		"VI",
		"VII",
		"VIII",
		"IX",
		"X"
	}

	if num <= 10 then
		return romanNumeral[num]
	end

	local number = romanNumeral[num % 10] or romanNumeral[10]

	return romanNumeral[10] .. number
end

function dataEasy.getCardMaxStar(cardMarkID)
	local cards = gGameModel.role:read("cards")
	local myMaxStar = 0
	local existCards = {}
	local dbid

	for k, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star")

		existCards[cardId] = true

		if cardMarkID == csv.cards[cardId].cardMarkID and myMaxStar < star then
			myMaxStar = star
			dbid = v
		end
	end

	return myMaxStar, existCards, dbid
end

function dataEasy.getStarData(star)
	local starData = {}
	local starIdx = star - 6

	for i = 1, 6 do
		local icon = "common/icon/icon_star_d.png"

		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end

		table.insert(starData, {
			icon = icon
		})
	end

	return starData
end

function dataEasy.getTextScrollStrs(strs, verticalSpace)
	if type(strs) == "string" and string.find(strs, "\n", 1, true) then
		local data = string.split(strs, "\n")

		strs = {}

		for i, v in ipairs(data) do
			if i ~= 1 and verticalSpace then
				table.insert(strs, {
					str = "",
					verticalSpace = verticalSpace
				})
			end

			table.insert(strs, {
				str = v
			})
		end
	end

	return strs
end

function dataEasy.getItems(ret, spe, noSort)
	local hasHero = {}
	local items = {}

	for i, v in ipairs(ret) do
		local t = {}

		if v.key == "items" or v.key == "card" then
			for _, v in ipairs(v.num) do
				local data = v

				if v.key == "card" then
					local isNewHero = false
					local card = gGameModel.cards:find(v[1])
					local cardId = card:read("card_id")

					if v[2] and not hasHero[cardId] then
						hasHero[cardId] = true
						isNewHero = true
					end

					data = {
						dbid = v[1],
						new = isNewHero
					}
				end

				table.insert(t, data)
			end
		end

		if #t > 0 then
			table.insert(items, t)
		end
	end

	local t = {}
	local card

	for k, v in pairs(spe) do
		if k == "item" or k == "card" then
			for _, vv in ipairs(v) do
				local data = vv

				if k == "item" then
					data = {
						vv.key,
						vv.num
					}
				else
					local isNewHero = false
					local card = gGameModel.cards:find(data.dbid)
					local cardId = card:read("card_id")

					if data.new and not hasHero[cardId] then
						hasHero[cardId] = true
						isNewHero = true
					end

					data.new = isNewHero
				end

				table.insert(t, data)
			end
		end
	end

	if #t > 0 then
		table.insert(items, t)
	end

	if not noSort then
		for _, datas in ipairs(items) do
			local len = #datas

			if len < 10 then
				break
			end

			for i = 1, 5 do
				local idx1 = math.random(1, len)
				local idx2 = math.random(1, len)

				while idx1 == idx2 do
					idx2 = math.random(1, len)
				end

				datas[idx1], datas[idx2] = datas[idx2], datas[idx1]
			end
		end
	end

	return items
end

local localKey = "redHintTodayCheckTable"

function dataEasy.setTodayCheck(checkKey, dbId)
	if not checkKey or not dbId then
		return
	end

	if checkKey ~= "nvalue" then
		return
	end

	dbId = stringz.bintohex(dbId)

	local today = time.getTodayStr()
	local tb = userDefault.getForeverLocalKey(localKey, {}, {
		rawData = true,
		rawKey = true
	})

	if not tb[today] then
		tb = {
			[today] = {}
		}
	end

	if not tb[today][checkKey] or not tb[today][checkKey][dbId] then
		tb[today][checkKey] = tb[today][checkKey] or {}
		tb[today][checkKey][dbId] = true

		userDefault.setForeverLocalKey(localKey, tb, {
			new = true,
			rawKey = true
		})
	end
end

function dataEasy.isTodayCheck(checkKey, dbId)
	dbId = stringz.bintohex(dbId)

	local today = time.getTodayStr()
	local tb = userDefault.getForeverLocalKey(localKey, {
		[today] = {}
	}, {
		rawData = true,
		rawKey = true
	})

	tb[today] = tb[today] or {}

	return tb[today][checkKey] and tb[today][checkKey][dbId]
end

function dataEasy.calcFightingPoint(id, level, attrs, skills)
	local unitID = csv.cards[id].unitID
	local cfg = csv.fighting_weight[csv.cards[id].fightingWeight]
	local point = level * cfg.level
	local rate = 1

	for attr, val in pairs(attrs) do
		if attr == "strikeDamage" then
			val = val - 15000
		elseif attr == "blockPower" then
			val = val - 3000
		end

		if val > 0 then
			if game.ATTRDEF_ENUM_TABLE[attr] < 14 then
				point = point + cfg[attr] * val
			elseif cfg[attr] then
				rate = rate + cfg[attr] * val
			end
		end
	end

	point = point * rate

	for id, level in pairs(skills) do
		if csv.skill[id] then
			point = point + csv.skill[id].fightingPoint * level
		end
	end

	point = point + csv.unit[unitID].fightingPoint

	return math.floor(point)
end

function dataEasy.isDoubleHuodong(typeIdorStr)
	local typeId = typeIdorStr

	if type(typeIdorStr) == "string" then
		typeId = game.DOUBLE_HUODONG[typeIdorStr]
	end

	if not typeId then
		return false
	end

	local paramMaps = {}

	for _, yyId in ipairs(gGameModel.role:read("yy_open")) do
		local cfg = csv.yunying.yyhuodong[yyId]

		if game.YYHUODONG_TYPE_ENUM_TABLE.doubleDrop == cfg.type then
			local paramMap = cfg.paramMap

			if paramMap.type and paramMap.type == typeId then
				table.insert(paramMaps, paramMap)
			end
		end
	end

	local reunionState, reunionParamMaps, count = dataEasy.isReunionDoubleHuodong(typeId)

	if reunionState then
		if #paramMaps == 0 then
			paramMaps = reunionParamMaps
		else
			local dailyActivity = {
				game.DOUBLE_HUODONG.goldActivity,
				game.DOUBLE_HUODONG.expActivity,
				game.DOUBLE_HUODONG.giftActivity,
				game.DOUBLE_HUODONG.fragActivity,
				game.DOUBLE_HUODONG.contractActivity
			}

			if itertools.include(dailyActivity, typeId) then
				local map = table.deepcopy(paramMaps[1], true)

				map.count = map.count + reunionParamMaps[1].count
				paramMaps[1] = map
			elseif typeId == game.DOUBLE_HUODONG.buyStamina or typeId == game.DOUBLE_HUODONG.buyGold then
				if paramMaps[1].count < reunionParamMaps[1].count then
					paramMaps = reunionParamMaps or paramMaps
				end
			elseif typeId == game.DOUBLE_HUODONG.gateDrop then
				local sceneConf = csv.scene_conf
				local normalDouble = false

				for k, paramMap in pairs(paramMaps) do
					local startId = tonumber(paramMap.start)
					local startConf = sceneConf[startId]
					local gateType = startConf.gateType

					if gateType == game.GATE_TYPE.normal then
						normalDouble = true

						break
					end
				end

				if not normalDouble then
					table.insert(paramMaps, reunionParamMaps[1])
				end
			end
		end
	end

	if #paramMaps == 0 then
		return false
	else
		return true, paramMaps, #paramMaps
	end
end

function dataEasy.isReunionDoubleHuodong(typeId)
	local reunionTypeId = game.NORMAL_TO_REUNION[typeId]
	local reunion = gGameModel.role:read("reunion")

	if not reunionTypeId or not reunion or not reunion.info or reunion.role_type ~= 1 or reunion.info.end_time - time.getTime() <= 0 then
		return false
	end

	local cfg = csv.yunying.yyhuodong[reunion.info.yyID]

	if not cfg or not cfg.paramMap.huodong then
		return false
	end

	local huodongOpen = false

	for k, v in pairs(cfg.paramMap.huodong) do
		if v == "catch" then
			huodongOpen = true
		end
	end

	if not huodongOpen then
		return false
	end

	local startTime = tonumber(time.getStrInClock(math.floor(reunion.info.reunion_time)))
	local curTime = tonumber(time.getTodayStrInClock())
	local paramMaps = {}
	local catchup = reunion.catchup or {}

	for k, v in csvPairs(csv.yunying.reunion_catchup) do
		if v.huodongID == cfg.huodongID and v.params.type == reunionTypeId then
			if v.addType == 2 and catchup[k] then
				if catchup[k] >= v.addNum then
					return false
				end
			elseif v.addType == 1 then
				local endTime = startTime + v.addNum

				if endTime <= curTime then
					return false
				end
			end

			local paramMap = table.deepcopy(v.params, true)

			paramMap.type = typeId

			table.insert(paramMaps, paramMap)
		end
	end

	if #paramMaps == 0 then
		return false
	else
		return true, paramMaps, #paramMaps
	end
end

function dataEasy.isGateIdDoubleDrop(gateId)
	local sceneConf = csv.scene_conf[gateId] or csv.endless_tower_scene[gateId] or csv.abyss_endless_tower.scene[gateId]

	if sceneConf.gateType == game.GATE_TYPE.endlessTower then
		return dataEasy.isDoubleHuodong("endlessSaodang")
	elseif sceneConf.gateType == game.GATE_TYPE.randomTower then
		return dataEasy.isDoubleHuodong("randomGold")
	end

	local state, paramMaps, count = dataEasy.isDoubleHuodong("gateDrop")

	if state then
		for _, paramMap in pairs(paramMaps) do
			local startId = paramMap.start
			local endId = paramMap["end"]

			if gateId <= endId and startId <= gateId then
				return true
			end
		end
	end

	return false
end

function dataEasy.itemStackMax(key)
	if game.ITEM_STRING_ENUM_TABLE[key] then
		return math.huge
	end

	return dataEasy.getCfgByKey(key).stackMax or math.huge
end

function dataEasy.judgeServerOpen(unlockFeature)
	if unlockFeature == nil then
		return true
	end

	for k, v in orderCsvPairs(csv.pvpandpve) do
		if v.unlockFeature == unlockFeature then
			if v.serverDayInfo and v.serverDayInfo.funcType == "less" then
				local day = getCsv(v.serverDayInfo.sevCsv)

				return not dataEasy.serverOpenDaysLess(day), day
			end

			return true
		end
	end

	return true
end

function dataEasy.getUnionFubenCurrentMonth()
	local nowDate = time.getNowDate()
	local year = nowDate.year
	local month = nowDate.month
	local hour = time.getRefreshHour()

	if nowDate.day == 1 and (hour > nowDate.hour or nowDate.wday == 1) or nowDate.day == 2 and nowDate.wday == 2 and hour > nowDate.hour then
		month = month - 1

		if month < 1 then
			month = 12
			year = year - 1
		end
	end

	return year * 100 + month
end
-- 暂时用老的
-- @desc 判断是否有公会副本奖励
function dataEasy.haveUnionFubenReward()
	local currentMonth = dataEasy.getUnionFubenCurrentMonth()
	local unionFbAward = gGameModel.role:read("union_fb_award")
	local unionFubenPassed = gGameModel.role:read("union_fuben_passed")
	local i = 1
	for csvId,_ in orderCsvPairs(csv.union.union_fuben) do
		-- 已通关
		local complete = unionFubenPassed >= i
		i = i + 1
		-- 已领取
		local received = (unionFbAward[csvId] and unionFbAward[csvId][1] == currentMonth and unionFbAward[csvId][2] > 0)
		if complete and not received then
			return true
		end
	end
	return false
end
-- function dataEasy.haveUnionFubenReward()
-- 	local currentMonth = dataEasy.getUnionFubenCurrentMonth()
-- 	local unionFbAward = gGameModel.role:read("union_fb_award")
-- 	local unionFubenPassed = gGameModel.role:read("union_challenge_cleared")
-- 	local i = 1

-- 	for csvId, _ in orderCsvPairs(csv.union.union_fuben) do
-- 		local complete = i <= unionFubenPassed

-- 		i = i + 1

-- 		local received = unionFbAward[csvId] and unionFbAward[csvId][1] == currentMonth and unionFbAward[csvId][2] > 0

-- 		if complete and not received then
-- 			return true
-- 		end
-- 	end

-- 	return false
-- end

function dataEasy.isDisplayReplaceHuodong(typeStr)
	local function getTimestamp(huodongDate, huodongTime)
		local hour, min = time.getHourAndMin(huodongTime)

		return time.getNumTimestamp(huodongDate, hour, min)
	end

	if not typeStr then
		return false
	end

	local nowTime = os.time()

	for id, cfg in csvPairs(csv.huodong_display_replace) do
		local beginTime = getTimestamp(cfg.beginDate, cfg.beginTime)
		local endTime = getTimestamp(cfg.endDate, cfg.endTime)

		if cfg.clientParam[typeStr] and beginTime < nowTime and nowTime < endTime then
			return true, cfg.clientParam[typeStr], id
		end
	end

	return false
end

function dataEasy.getSaoDangState(times)
	local state = {
		canSaoDang = false,
		tip = ""
	}
	local privilegeSweepTimes = dataEasy.getPrivilegeVal(game.PRIVILEGE_TYPE.GateSaoDangTimes)
	local vipLevel = gGameModel.role:read("vip_level")
	local sweepNum = gVipCsv[vipLevel].saodangCountOpen

	if privilegeSweepTimes < times and sweepNum < times then
		state.tip = gLanguageCsv.saodangMultiRoleNotEnough
	else
		state.canSaoDang = true
	end

	return state
end

function dataEasy.fixSaoDangLocalKey(key, timesTab)
	local sweepSelected = userDefault.getForeverLocalKey(key, 1)

	for i = 2, math.min(#timesTab, sweepSelected) do
		local times = timesTab[i]
		local state = dataEasy.getSaoDangState(times)

		if not state.canSaoDang then
			userDefault.setForeverLocalKey(key, i - 1)

			return
		end
	end
end

function dataEasy.getActivityIdInYYOPEN(huodongType)
	for _, yyId in ipairs(gGameModel.role:read("yy_open")) do
		local cfg = csv.yunying.yyhuodong[yyId]

		if cfg.type == huodongType then
			return yyId
		end
	end
end

function dataEasy.getEffortValueAttrData(attr)
	local attrTypeStr = game.ATTRDEF_TABLE[attr]
	local name = gLanguageCsv["attr" .. string.caption(attrTypeStr)]
	local icon = ui.ATTR_LOGO[game.ATTRDEF_TABLE[attr]]

	if attr == game.ATTRDEF_ENUM_TABLE.damage then
		name = gLanguageCsv.attrDoubleAttack
		icon = "common/icon/attribute/icon_sg.png"
	end

	return name, icon
end

function dataEasy.getAttrValueAndNextValue(key, val, nextVal)
	nextVal = dataEasy.getAttrValueString(key, nextVal)
	val = dataEasy.getAttrValueString(key, val)

	local nextHasPercent = string.find(nextVal, "%%")
	local hasPercent = string.find(val, "%%")

	if not hasPercent and nextHasPercent then
		val = val .. "%"
	end

	return val, nextVal
end

local function merge(t)
	local ret = {}

	for _, targ in ipairs(t) do
		for _, v in pairs(targ) do
			table.insert(ret, v)
		end
	end

	return ret
end


-- 暂时用老版
-- 和服务器定义保持统一
-- local USING_CARDS_DATA = {
-- 	{
-- 		-- 1. battle_cards
-- 		key = "battle",
-- 		get = function()
-- 			return gGameModel.role:read("battle_cards")
-- 		end,
-- 	}, {
-- 		-- 2.huodong_cards # 活动副本，PVE玩法会自动下阵，服务器处理
-- 		-- 4.union training
-- 		key = "unionTraining",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").union_training.cards
-- 		end,
-- 	}, {
-- 		-- 3. arena
-- 		key = "arena",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").arena.defence_cards
-- 		end,
-- 	}, {
-- 		-- 4.craft # 报名阶段不能分解，服务器处理
-- 		key = "craft",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").craft.cards
-- 		end,
-- 	}, {
-- 		-- 7.union_fight # 公会战报名阶段不能分解
-- 		key = "unionFight",
-- 		get = function()
-- 			local t = {}
-- 			local modelCard = gGameModel.role:read("card_deployment").union_fight or {}
-- 			for _, v in pairs(modelCard) do
-- 				for _, v1 in pairs(v) do
-- 					table.insert(t, v1)
-- 				end
-- 			end
-- 			return t
-- 		end,
-- 	}, {
-- 		-- 7.crossunionfight # 跨服公会战入选布阵不能分解
-- 		key = "crossunionfight",
-- 		get = function()
-- 			local t = {}
-- 			local modelCard = gGameModel.role:read("card_deployment").cross_union_fight or {}
-- 			for _, v in pairs(modelCard) do
-- 				for _, v1 in pairs(v) do
-- 					table.insert(t, v1)
-- 				end
-- 			end
-- 			return t
-- 		end,
-- 	}, {
-- 		-- 5.clone 元素挑战中不能分解
-- 		key = "cloneBattle",
-- 		get = function()
-- 			return gGameModel.role:read("clone_deploy_card_db_id")
-- 		end,
-- 	}, {
-- 		-- 6.cross craft # 报名阶段不能分解，服务器处理
-- 		key = "crossCraft",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").cross_craft.cards
-- 		end,
-- 	}, {
-- 		-- 8.cross arena # 比赛中不能分解，服务器处理
-- 		key = "crossArena",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").cross_arena.defence_cards
-- 		end,
-- 	}, {
-- 		-- 8.badge guard # 徽章守护中不能分解
-- 		key = "gymBadgeGuard",
-- 		get = function(cards)
-- 			local t = {}
-- 			local allCards = gGameModel.role:read("cards")
-- 			for _, v in ipairs(allCards) do
-- 				local card = gGameModel.cards:find(v)
-- 				if card then
-- 					local cardData = card:read("badge_guard")
-- 					if cardData[1] then
-- 						table.insert(t, v)
-- 					end
-- 				end
-- 			end
-- 			return t
-- 		end,
-- 	}, {
-- 		-- 9.gymLeader # 占领的道馆馆主阵容
-- 		key = "gymLeader",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").gym.cards
-- 		end,
-- 	}, {
-- 		-- 9.crossGymLeader # 占领的跨服道馆馆主
-- 		key = "crossGymLeader",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").gym.cross_cards
-- 		end,
-- 	}, {
-- 		-- 11.crossMine # 商业街的防守阵容
-- 		key = "crossMine",
-- 		get = function()
-- 			return gGameModel.role:read("card_deployment").cross_mine.defence_cards
-- 		end,
-- 	},
-- }
local USING_CARDS_DATA = {
	{
		key = "battle",
		get = function()
			return merge({
				gGameModel.role:read("battle_cards"),
				-- gGameModel.role:read("battle_aid_cards") or {}
			})
		end
	},
	{
		key = "unionTraining",
		get = function()
			return gGameModel.role:read("card_deployment").union_training.cards
		end
	},
	{
		key = "arena",
		get = function()
			return merge({
				gGameModel.role:read("card_deployment").arena.defence_cards,
				-- gGameModel.role:read("card_embattle").arena.defence_aid_cards or {}
			})
		end
	},
	{
		key = "craft",
		get = function()
			return gGameModel.role:read("card_deployment").craft.cards
		end
	},
	{
		key = "unionFight",
		get = function()
			local t = {}
			local modelCard = gGameModel.role:read("card_deployment").union_fight or {}

			for _, v in pairs(modelCard) do
				for _, v1 in pairs(v) do
					table.insert(t, v1)
				end
			end

			return t
		end
	},
	{
		key = "crossunionfight",
		get = function()
			local t = {}
			local modelCard = gGameModel.role:read("card_deployment").cross_union_fight or {}
			for _, v in pairs(modelCard) do
				for _, v1 in pairs(v) do
					table.insert(t, v1)
				end
			end
			return t
		end,
	},
	{
		key = "cloneBattle",
		get = function()
			return gGameModel.role:read("clone_deploy_card_db_id")
		end
	},
	{
		key = "crossCraft",
		get = function()
			return gGameModel.role:read("card_deployment").cross_craft.cards
		end
	},
	{
		key = "crossArena",
		get = function()
			return merge({
				gGameModel.role:read("card_deployment").cross_arena.defence_cards,
				-- gGameModel.role:read("card_embattle").cross_arena.defence_aid_cards or {}
			})
		end
	},
	{
		key = "gymBadgeGuard",
		get = function(cards)
			local t = {}
			local allCards = gGameModel.role:read("cards")

			for _, v in pairs(allCards) do
				local card = gGameModel.cards:find(v)

				if card then
					local cardData = card:read("badge_guard")

					if cardData[1] then
						table.insert(t, v)
					end
				end
			end

			return t
		end
	},
	{
		key = "gymLeader",
		get = function()
			return merge({
				gGameModel.role:read("card_deployment").gym.cards,
				-- gGameModel.role:read("card_embattle").gym.aid_cards or {}
			})
		end
	},
	{
		key = "crossGymLeader",
		get = function()
			return merge({
				gGameModel.role:read("card_deployment").gym.cross_cards,
				-- gGameModel.role:read("card_embattle").gym.cross_aid_cards or {}
			})
		end
	},
	{
		key = "crossMine",
		get = function()
			return merge({
				gGameModel.role:read("card_deployment").cross_mine.defence_cards,
				-- gGameModel.role:read("card_embattle").cross_mine.defence_aid_cards or {}
			})
		end
	},
	-- {
	-- 	key = "crossSupremacy",
	-- 	get = function()
	-- 		local t = {}
	-- 		local defenceCards = gGameModel.role:read("card_deployment").cross_supremacy.defence_cards or {}
	-- 		local eliteCards = gGameModel.role:read("card_deployment").cross_supremacy.elite_cards or {}
	-- 		-- local aidDefenceCards = gGameModel.role:read("card_embattle").cross_supremacy.defence_aid_cards or {}

	-- 		for _, v in pairs(defenceCards) do
	-- 			local card = gGameModel.cards:find(v)

	-- 			if card then
	-- 				table.insert(t, v)
	-- 			end
	-- 		end

	-- 		for _, v in pairs(eliteCards) do
	-- 			local card = gGameModel.cards:find(v)

	-- 			if card then
	-- 				table.insert(t, v)
	-- 			end
	-- 		end

	-- 		-- for _, v in pairs(aidDefenceCards) do
	-- 		-- 	local card = gGameModel.cards:find(v)

	-- 		-- 	if card then
	-- 		-- 		table.insert(t, v)
	-- 		-- 	end
	-- 		-- end

	-- 		return t
	-- 	end
	-- },
	-- {
	-- 	key = "meteorites",
	-- 	get = function(params)
	-- 		local meteorites = gGameModel.role:read("meteorites") or {}
	-- 		local t = {}

	-- 		for _, v in pairs(meteorites) do
	-- 			if v.card then
	-- 				table.insert(t, v.card)
	-- 			end
	-- 		end

	-- 		return t
	-- 	end
	-- },
	-- {
	-- 	key = "meteorSameSprite",
	-- 	get = function(params)
	-- 		local meteorites = gGameModel.role:read("meteorites") or {}
	-- 		local hash = {}
	-- 		local t = {}

	-- 		for k, v in pairs(meteorites) do
	-- 			if v.card then
	-- 				local card = gGameModel.cards:find(v.card)

	-- 				if params.index ~= k then
	-- 					if card then
	-- 						local cardID = card:read("card_id")
	-- 						local hash1 = dataEasy.getHashMarkIDs(cardID)

	-- 						maptools.union_with(hash, hash1)
	-- 					end
	-- 				else
	-- 					table.insert(t, v.card)
	-- 				end
	-- 			end
	-- 		end

	-- 		local allCards = gGameModel.role:read("cards")

	-- 		for _, v in pairs(allCards) do
	-- 			local card = gGameModel.cards:find(v)

	-- 			if card then
	-- 				local cardID = card:read("card_id")
	-- 				local hash1 = dataEasy.getHashMarkIDs(cardID)

	-- 				if not itertools.isempty(maptools.intersection({
	-- 					hash,
	-- 					hash1
	-- 				})) then
	-- 					table.insert(t, v)
	-- 				end
	-- 			end
	-- 		end

	-- 		return t
	-- 	end
	-- },
	-- {
	-- 	key = "starAid",
	-- 	get = function()
	-- 		local fieldSeat = gGameModel.role:read("card_star_swap_fields") or {}
	-- 		local t = {}

	-- 		for _, v in pairs(fieldSeat) do
	-- 			if itertools.size(v.cards) > 0 then
	-- 				for _, v1 in ipairs(v.cards) do
	-- 					table.insert(t, v1)
	-- 				end
	-- 			end
	-- 		end

	-- 		return t
	-- 	end
	-- },
	{
		key = "mergeAB",
		get = function()
			local mergeInfo = dataEasy.getCardMergeInfo()

			return itertools.keys(mergeInfo.mergeAB)
		end
	},
	{
		key = "relieveC",
		get = function()
			local mergeInfo = dataEasy.getCardMergeInfo()

			return itertools.keys(mergeInfo.relieveC)
		end
	},
	-- {
	-- 	key = "crossCircus",
	-- 	get = function()
	-- 		local t = {}
	-- 		local modelCard = gGameModel.role:read("card_embattle").cross_circus or {}

	-- 		for _, v in pairs(modelCard) do
	-- 			for _, v1 in pairs(v) do
	-- 				table.insert(t, v1)
	-- 			end
	-- 		end

	-- 		return t
	-- 	end
	-- },
	-- {
	-- 	key = "crossUnionAdventure",
	-- 	get = function()
	-- 		local t = {}
	-- 		local modelCard = gGameModel.role:read("card_embattle").cross_union_adventure.cards or {}

	-- 		for _, dbid in pairs(modelCard) do
	-- 			table.insert(t, dbid)
	-- 		end

	-- 		return t
	-- 	end
	-- }
}
local AIDING_CARDS_DATA = {
	{
		key = "battle",
		get = function()
			return gGameModel.role:read("battle_aid_cards") or {}
		end
	},
	{
		key = "arena",
		get = function()
			return merge({
				{},
				gGameModel.role:read("card_embattle").arena.defence_aid_cards or {}
			})
		end
	},
	{
		key = "crossArena",
		get = function()
			return merge({
				{},
				gGameModel.role:read("card_embattle").cross_arena.defence_aid_cards or {}
			})
		end
	},
	{
		key = "crossMine",
		get = function(cards)
			return merge({
				{},
				gGameModel.role:read("card_embattle").cross_mine.defence_aid_cards or {}
			})
		end
	},
	{
		key = "crossSupremacy",
		get = function()
			return merge({
				{},
				gGameModel.role:read("card_embattle").cross_supremacy.defence_aid_cards or {}
			})
		end
	},
	{
		key = "crossGymLeader",
		get = function()
			return gGameModel.role:read("card_embattle").gym.cross_aid_cards or {}
		end
	}
}

function dataEasy.inUsingCardsHash()
	local cards = {}

	for _, data in ipairs(USING_CARDS_DATA) do
		if data.key ~= "meteorSameSprite" then
			local modelCards = data.get()

			if type(modelCards) ~= "table" then
				modelCards = {
					modelCards
				}
			end

			for _, v in pairs(modelCards) do
				cards[v] = cards[v] or data.key
			end
		end
	end

	return cards
end

function dataEasy.inAidingCardsHash()
	local cards = {}

	for _, data in ipairs(AIDING_CARDS_DATA) do
		local modelCards = data.get()

		if type(modelCards) ~= "table" then
			modelCards = {
				modelCards
			}
		end

		for _, v in pairs(modelCards) do
			cards[v] = cards[v] or data.key
		end
	end

	return cards
end

function dataEasy.cannotInMeteorCards(index)
	local cannotKey = {
		"arena",
		"craft",
		"unionFight",
		"crossunionfight",
		"cloneBattle",
		"crossCraft",
		"crossArena",
		"gymLeader",
		"crossGymLeader",
		"crossMine",
		"crossSupremacy",
		"meteorites",
		"meteorSameSprite",
		"mergeAB",
		"relieveC",
		"crossCircus"
	}
	local hash = arraytools.hash(cannotKey)
	local cards = {}

	for _, data in ipairs(USING_CARDS_DATA) do
		if hash[data.key] then
			local modelCards = data.get({
				index = index
			})

			if type(modelCards) ~= "table" then
				modelCards = {
					modelCards
				}
			end

			for _, v in pairs(modelCards) do
				cards[v] = cards[v] or data.key
			end
		end
	end

	local battleCards = gGameModel.role:read("battle_cards")

	if itertools.size(battleCards) <= 1 then
		for _, dbid in pairs(battleCards) do
			cards[dbid] = cards[dbid] or "battle"
		end
	end

	return cards
end

function dataEasy.isInServer(key)
	local cfg = csv.unlock[gUnlockCsv[key]]

	if not cfg then
		return false
	end

	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})
	local tag = getServerTag(gameKey)
	local id = getServerId(gameKey, true)

	if cfg.servers[tag] and id >= cfg.servers[tag][1] and id <= cfg.servers[tag][2] then
		return true
	end

	return false
end

function dataEasy.getCrossArenaStageByRank(rank, targetVersion)
	local csvId

	if not targetVersion then
		csvId = game.crossArenaCsvId or gGameModel.cross_arena:read("csvID")

		if not csvId then
			return
		end
	end

	local version = targetVersion or csv.cross.service[csvId].version

	for i, v in orderCsvPairs(csv.cross.arena.stage) do
		if v.version == version and rank >= v.range[1] then
			local stageData = csvClone(v)

			stageData.index = i

			if v.stageID == 19 then
				stageData.rank = rank
			else
				stageData.rank = rank - v.range[1] + 1
			end

			return stageData
		end
	end
end

function dataEasy.getSupremacyServiceData()
	local servOpenDays = csv.cross.supremacy.base[1].servOpenDays
	local gameKey = userDefault.getForeverLocalKey("serverKey", nil, {
		rawKey = true
	})
	local targetTime = time.getNumTimestamp(time.getTodayStrInClock(), time.getRefreshHour())
	local targetDate, targetId

	local function setDateId(id, v)
		if not targetDate or v.date < targetDate then
			targetDate = v.date
			targetId = id
		end
	end

	for id, v in orderCsvPairs(csv.cross.service) do
		if v.service == "crosssupremacy" and targetTime < time.getNumTimestamp(tonumber(v.date), time.getRefreshHour()) then
			local isMergeServers = false

			for _, server in ipairs(v.servers) do
				if isCurServerContainMerge(server) then
					isMergeServers = true

					break
				end
			end

			if itertools.include(v.servers, gameKey) or isMergeServers then
				local delta = time.getNumTimestamp(v.date) - time.getNumTimestamp(time.getTodayStrInClock(0))
				local day = servOpenDays - math.floor(delta / 86400)

				if not dataEasy.serverOpenDaysLess(day) then
					setDateId(id, v)
				end
			end
		end
	end

	if targetId then
		return targetId, csv.cross.service[targetId].servers
	end

	printWarn(string.format("dataEasy.getSupremacyServiceData(%s): the server no find match", "crosssupremacy"))
end

function dataEasy.getCrossServiceData(key, servOpenDays, dt)
	local targetTime = time.getNumTimestamp(time.getTodayStrInClock(), time.getRefreshHour())

	if dt then
		targetTime = dt + targetTime
	end

	local function isOK(v)
		if time.getNumTimestamp(tonumber(v.date), time.getRefreshHour()) < targetTime then
			return false
		end

		if csvSize(v.servers) == 0 and isServerTagInCross(v.cross) then
			return true
		end

		for _, server in ipairs(v.servers) do
			if isCurServerContainMerge(server) then
				return true
			end
		end

		return false
	end

	local targetDate, targetId

	local function setDateId(id, v)
		if not targetDate or v.date < targetDate then
			targetDate = v.date
			targetId = id
		end
	end

	for id, v in orderCsvPairs(csv.cross.service) do
		if v.service == key and isOK(v) then
			if not servOpenDays then
				setDateId(id, v)
			else
				local delta = time.getNumTimestamp(v.date) - time.getNumTimestamp(time.getTodayStrInClock(0))
				local day = servOpenDays - math.floor(delta / 86400)

				if not dataEasy.serverOpenDaysLess(day) then
					setDateId(id, v)
				end
			end
		end
	end

	if targetId then
		return targetId, csv.cross.service[targetId].servers
	end

	printWarn(string.format("dataEasy.getCrossServiceData(%s): the server no find match", tostring(key)))
end

function dataEasy.getCrossCrontabData(key, servOpenDays, params)
	params = params or {}

	local cfg

	local function isOK(v)
		if csvSize(v.servers) == 0 and isServerTagInCross(v.cross) then
			return true, 1
		end

		for _, server in ipairs(v.servers) do
			if isCurServerContainMerge(server) then
				return true, 2
			end
		end

		return false
	end

	for id, v in orderCsvPairs(csv.cross.crontab) do
		if v.service == key then
			local flag, state = isOK(v)

			if flag then
				cfg = v

				if state == 2 then
					break
				end
			end
		end
	end

	if cfg then
		local refreshHour = params.refreshHour or time.getRefreshHour()
		local targetTime = time.getTime()

		if params.dt then
			targetTime = params.dt + targetTime
		end

		if params.dtfunc then
			targetTime = params.dtfunc(cfg) + targetTime
		end

		local startTime = time.getNumTimestamp(cfg.date, refreshHour)

		for i = 1, math.huge do
			if targetTime <= startTime then
				if not servOpenDays then
					return startTime, cfg
				else
					local delta = startTime - time.getNumTimestamp(time.getTodayStrInClock(0), refreshHour)
					local day = servOpenDays - math.floor(delta / 86400)

					if not dataEasy.serverOpenDaysLess(day) then
						return startTime, cfg
					end
				end
			end

			startTime = startTime + cfg.periodDays * 86400
		end
	end

	printWarn(string.format("dataEasy.getCrossCrontabData(%s): the server no find match", tostring(key)))
end

function dataEasy.getWorldLevelExpAdd(gateType)
	local cfg = csv.world_level.base
	local lock = dataEasy.serverOpenDaysLess(cfg[1].servOpenDays)

	if not dataEasy.isUnlock(gUnlockCsv.worldLevel) or lock then
		return
	end

	local worldlevel = gGameModel.global_record:read("world_level") or 0
	local roleLevel = gGameModel.role:read("level")
	local diff = worldlevel - roleLevel

	for id, v in orderCsvPairs(csv.world_level.bonus) do
		if diff >= v.deltaRange[1] and diff <= v.deltaRange[2] then
			if gateType == 1 then
				return v.gateBonus
			elseif gateType == 2 then
				return v.heroGateBonus
			end
		end
	end
end

function dataEasy.onlineFightLoginServer(view, errCb, okCb)
	gGameModel.battle = nil

	gGameApp:requestServer("/game/cross/online/main", function(tb)
		local matchResult = gGameModel.cross_online_fight:read("match_result")

		if not itertools.isempty(matchResult) then
			local t = string.split(matchResult.address, ":")

			if not t[2] then
				gGameUI:showTip(gLanguageCsv.onlineFightBanError)

				if errCb then
					errCb()
				end

				return
			end

			gGameApp.net:doRealtime(t[1], tonumber(t[2]), function(ret, err)
				local function onErrCb()
					gGameApp.net:doRealtimeEnd()

					if errCb then
						errCb()
					end
				end

				if err then
					gGameUI:showTip(gLanguageCsv[err.err] or err.err)
					onErrCb()
				elseif not gGameModel.battle then
					gGameUI:showTip(gLanguageCsv.onlineFightBanError)
					onErrCb()
				else
					local hasResult = false
					local t = idlereasy.when(gGameModel.battle.state, function(_, state)
						if not hasResult and state ~= game.SYNC_SCENE_STATE.start then
							hasResult = true

							if state == game.SYNC_SCENE_STATE.banpick then
								if okCb then
									okCb(function()
										gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {
											full = true
										}, {
											startFighting = dataEasy.onlineFightStartFighting
										})
									end)
								else
									gGameUI:stackUI("city.pvp.online_fight.ban_embattle", nil, {
										full = true
									}, {
										startFighting = dataEasy.onlineFightStartFighting
									})
								end
							elseif state == game.SYNC_SCENE_STATE.waitloading or state == game.SYNC_SCENE_STATE.attack then
								if okCb then
									okCb(dataEasy.onlineFightStartFighting)
								else
									dataEasy.onlineFightStartFighting()
								end
							else
								gGameUI:showTip(gLanguageCsv.onlineFightBanError)
								onErrCb()
							end
						end
					end)

					if view then
						t:anonyOnly(view)
					end
				end
			end, function(data)
				if data then
					local rtt1 = data.server_time - data.client_time
					local rtt2 = socket.gettime() * 1000 - data.client_time

					if CC_SHOW_FPS == true then
						local str = string.format("rtt1: %.2f ms\nrtt2: %.2f ms", rtt1, rtt2)
						local onlineFightText = gGameUI.scene:get("onlineFightText")

						if not onlineFightText then
							onlineFightText = ccui.Text:create("", "font/youmi1.ttf", 40):anchorPoint(cc.p(0, 0)):xy(display.uiOrigin.x - display.uiOriginMax.x + 10, 320):addTo(gGameUI.scene, 1000, "onlineFightText")

							text.addEffect(onlineFightText, {
								color = ui.COLORS.NORMAL.WHITE,
								outline = {
									color = ui.COLORS.NORMAL.DEFAULT
								}
							})
						end

						onlineFightText:text(str):show()
						onlineFightText:stopAllActions()
						performWithDelay(onlineFightText, function()
							onlineFightText:hide()
						end, 5)
					else
						local str = string.format("%.2f ms", rtt2)
						local onlineFightText = gGameUI.scene:get("onlineFightText")

						if not onlineFightText then
							onlineFightText = ccui.Text:create("", "font/youmi.ttf", 30):anchorPoint(cc.p(1, 0)):xy(display.uiOrigin.x - display.uiOriginMax.x + display.sizeInViewRect.width - 20, 20):addTo(gGameUI.scene, 1000, "onlineFightText")

							text.addEffect(onlineFightText, {
								color = ui.COLORS.NORMAL.WHITE,
								outline = {
									color = ui.COLORS.NORMAL.DEFAULT
								}
							})
						end

						onlineFightText:text(str):show()
						onlineFightText:stopAllActions()
						performWithDelay(onlineFightText, function()
							onlineFightText:hide()
						end, 5)
					end
				else
					gGameUI:showTip(gLanguageCsv.onlineFightBanError)
				end
			end)
		else
			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end
	end)
end

function dataEasy.crossUnionAdventureLoginServer(params)
	params = params or {}

	local host, port, roleID, roomID, team

	if params.host then
		host, port, roleID, roomID, team = params.host, params.port, params.roleID, params.roomID, params.team
	else
		local battleInfo = gGameModel.cross_union_adventure:read("battle_info")
		local t = string.split(battleInfo.room_addr, ":")

		host, port = t[1], tonumber(t[2])
		roomID = battleInfo.room_id
		roleID = gGameModel.role:read("id")
		team = 1

		if battleInfo.left and battleInfo.left.union_db_id ~= gGameModel.union:read("id") then
			team = 2
		end
	end

	if not port then
		if params.errCb then
			params.errCb()
		else
			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end

		return
	end

	gGameUI:disableTouchDispatch(nil, false)

	local flag = false

	performWithDelay(gGameUI.scene, function()
		if not flag then
			flag = true

			gGameUI:disableTouchDispatch(nil, true)
		end
	end, 30)
	gGameApp.net:getSessionByService("unionadventure"):init(host, port, roleID, roomID, function(ret, err)
		if not flag then
			flag = true

			gGameUI:disableTouchDispatch(nil, true)
		end

		if not err then
			ret.roleID = roleID
			ret.team = team
			ret.roomID = roomID
			ret.gameOverCb = params.gameOverCb

			if params.cb then
				params.cb(ret)
			else
				gGameUI:stackUI("city.union.cross_union_adventure.view", nil, nil, ret)
			end
		elseif params.errCb then
			params.errCb()
		else
			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end
	end)
end

function dataEasy.onlineChessLoginServer(params)
	params = params or {}

	local host, port, roleID, roomID, team

	if params.host then
		host, port, roleID, roomID, team = params.host, params.port, params.roleID, params.roomID, params.team
	else
		local battleInfo = gGameModel.auto_chess:read("battle")

		if not itertools.isempty(battleInfo) then
			if battleInfo.address == "" then
				jumpEasy.jumpTo("onlineAutoChess")

				return
			else
				local t = string.split(battleInfo.address, ":")

				host, port = t[1], tonumber(t[2])
				roomID = battleInfo.roomID
				roleID = gGameModel.role:read("id")
			end
		else
			jumpEasy.jumpTo("onlineAutoChess")

			return
		end
	end

	if not port then
		if params.errCb then
			params.errCb()
		end

		gGameUI:showTip(gLanguageCsv.onlineFightBanError)

		return
	end

	gGameUI:disableTouchDispatch(nil, false)

	local flag = false

	performWithDelay(gGameUI.scene, function()
		if not flag then
			flag = true

			gGameUI:disableTouchDispatch(nil, true)
		end
	end, 30)
	gGameUI:tryCloseItemDetail()
	gGameApp.net:getSessionByService("onlineautochess"):init(host, port, roleID, roomID, function(ret, err)
		if not flag then
			flag = true

			gGameUI:disableTouchDispatch(nil, true)
		end

		if not err then
			ret.roleID = roleID
			ret.roomID = roomID

			if params.cb then
				params.cb(ret)
			else
				gGameUI:switchUIAndStash("lushi_battle.loading", {
					isMulti = true
				})
			end
		else
			if params.errCb then
				params.errCb()
			end

			gGameUI:showTip(gLanguageCsv.onlineFightBanError)
		end
	end)
end

function dataEasy.onlineFightStartFighting()
	local battleData = gGameModel.battle:getData()

	battleEntrance.battle(battleData, {
		baseMusic = "battle1.mp3"
	}):enter()
end

function dataEasy.checkInRect(posTable, pos)
	for k, xyTable in ipairs(posTable) do
		if dataEasy.getLineIntersection(xyTable, pos) % 2 == 1 then
			return k
		end
	end
end

function dataEasy.getLineIntersection(posTable, pos)
	local count = 0

	for k, pos1 in ipairs(posTable) do
		local pos2 = posTable[k + 1] or posTable[1]

		if not (pos.x < math.min(pos1.x, pos2.x)) and not (pos.x > math.max(pos1.x, pos2.x)) and not (pos.y > math.max(pos1.y, pos2.y)) then
			local y = (pos2.y - pos1.y) / (pos2.x - pos1.x) * (pos.x - pos1.x) + pos1.y

			if y >= pos.y then
				count = count + 1
			end
		end
	end

	return count
end

function dataEasy.getNatureSprite(natureLimit)
	if csvSize(natureLimit) == 0 then
		-- block empty
	end

	local hashMap = itertools.map(natureLimit or {}, function(k, v)
		return v, 1
	end)
	local cards = gGameModel.role:read("cards")
	local data = {}

	for i, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local card_id = card:read("card_id")
		local cardCsv = csv.cards[card_id]
		local unitCsv = csv.unit[cardCsv.unitID]

		if csvSize(natureLimit) == 0 or hashMap[unitCsv.natureType] or hashMap[unitCsv.natureType2] then
			table.insert(data, v)
		end
	end

	return data
end

function dataEasy.isSkipNewbieBattle(okcb, closeCb)
	if dev.GUIDE_CLOSED or FOR_SHENHE or gGameUI.guideManager:checkFinished(-2) or gGameUI.guideManager:checkFinished(-1) then
		if okcb then
			okcb()
		end

		return true
	end

	local cfg = csv.unlock[gUnlockCsv.skipNewbieBattle]

	if not SERVERS_INFO or not cfg or not dataEasy.isInServer(cfg.feature) then
		if closeCb then
			closeCb()
		end

		return false
	end

	local roleInfos = gGameModel.account:read("role_infos")

	for key, _ in pairs(SERVERS_INFO) do
		local data = roleInfos[key]

		if data and data.level >= cfg.startLevel and data.vip >= cfg.startVip then
			if okcb then
				gGameUI:showDialog({
					clearFast = true,
					btnType = 2,
					content = gLanguageCsv.isSkipNewbieBattle,
					cb = okcb,
					closeCb = closeCb,
					dialogParams = {
						clickClose = false
					}
				})
			end

			return true
		end
	end

	if closeCb then
		closeCb()
	end

	return false
end

function dataEasy.forceUsingDiamonds(cb, count, cancleCb, str1)
	local str = string.format(gLanguageCsv.sureUsingDiamonds, count)

	if str1 then
		str = string.format(gLanguageCsv.sureUsingDiamonds2, count) .. " " .. str1
	end

	gGameUI:showDialog({
		isRich = true,
		btnType = 2,
		strs = "#C0x5B545B#" .. str,
		cb = cb,
		closeCb = cancleCb,
		cancelCb = cancleCb,
		dialogParams = {
			clickClose = false
		}
	})
end

function dataEasy.sureUsingDiamonds(cb, count, cancleCb, str1)
	local count = count or ""

	if matchLanguage({
		"kr"
	}) and (type(count) == "number" or type(count) == "string") then
		dataEasy.forceUsingDiamonds(cb, count, cancleCb, str1)
	else
		cb()
	end
end

function dataEasy.tryCallFunc(node, name, ...)
	if node[name] then
		node[name](node, ...)
	end
end

function dataEasy.showDialogToShop()
	if matchLanguage({
		"kr"
	}) then
		local str = gLanguageCsv.showDialogToShop

		gGameUI:showDialog({
			isRich = true,
			strs = "#C0x5B545B#" .. str,
			cb = function()
				cc.Application:getInstance():openURL(JUMP_SHOP_URL)
			end,
			title = gLanguageCsv.evaluation,
			btnStr = gLanguageCsv.goNow,
			dialogParams = {
				clickClose = false
			}
		})
	end
end

local function getTeamBuff(data)
	local attrs = {}

	for _, attr in pairs(data) do
		attrs[attr] = attrs[attr] or 0
		attrs[attr] = attrs[attr] + 1
	end

	local attrsIdx = {}

	for attrId, value in pairs(attrs) do
		table.insert(attrsIdx, value)
	end

	table.sort(attrsIdx, function(a, b)
		return b < a
	end)

	local natureCount = #attrsIdx
	local csvHalo = csv.battle_card_halo
	local teamBuff = {}
	local attrNumBuff = {}
	local haloId = 0

	for id, cfg in csvPairs(csvHalo) do
		local args = cfg.args

		if cfg.type == 1 then
			local size = itertools.size(args)

			if size <= natureCount then
				local check = true

				for i = 1, size do
					if attrsIdx[i] < args[i] then
						check = false

						break
					end
				end

				if check == true then
					local group = cfg.group
					local priority = cfg.priority

					if not teamBuff[group] or not (priority < teamBuff[group].priority) then
						teamBuff[group] = {
							csvId = id,
							priority = priority
						}
					end
				end
			end
		elseif cfg.type == 2 then
			for _, arg in pairs(args) do
				local n = attrs[arg[1]] or 0

				if n >= arg[2] then
					attrNumBuff[id] = arg[1]
				end
			end
		end
	end

	local imgPath = "config/embattle/icon_gh.png"
	local teamBuffs = {}
	local curGroup = -1

	for group, tb in pairs(teamBuff) do
		if curGroup < group then
			curGroup = group
			imgPath = csvHalo[tb.csvId].icon
		end

		teamBuffs[tb.csvId] = true
	end

	for id, attrId in pairs(attrNumBuff) do
		teamBuffs[id] = true
	end

	return {
		imgPath = imgPath,
		teamBuffs = teamBuffs
	}
end

function dataEasy.getTeamBuffBest(data)
	local flags = {
		1,
		1,
		1,
		1,
		1,
		1
	}

	if itertools.size(data) < 6 then
		local buf = getTeamBuff({})

		return {
			buf = buf,
			flags = flags
		}
	end

	local result
	local csvHalo = csv.battle_card_halo

	local function dfs(index)
		if index > 6 then
			local attrs = {}

			for i = 1, 6 do
				table.insert(attrs, data[i][flags[i]])
			end

			local buf = getTeamBuff(attrs)
			local csvId, autoPriority

			for id, _ in pairs(buf.teamBuffs) do
				if csvHalo[id].type == 1 and (not autoPriority or autoPriority < csvHalo[id].autoPriority) then
					csvId = id
					autoPriority = csvHalo[id].autoPriority
				end
			end

			if not result then
				result = {
					csvId = csvId,
					buf = buf,
					flags = clone(flags)
				}
			elseif csvId and (not result.csvId or autoPriority > csvHalo[result.csvId].autoPriority) then
				result = {
					csvId = csvId,
					buf = buf,
					flags = clone(flags)
				}
			end

			return
		end

		flags[index] = 1

		dfs(index + 1)

		if data[index][2] then
			flags[index] = 2

			dfs(index + 1)
		end
	end

	dfs(1)

	return result
end

function dataEasy.isSkinByKey(key)
	local id = dataEasy.stringMapingID(key)

	if not id or type(id) == "string" then
		return false
	end

	local cfg

	if id <= game.ITEM_CSVID_LIMIT then
		cfg = csvItems[id]
	end

	if cfg and cfg.type == game.ITEM_TYPE_ENUM_TABLE.skin then
		return true, cfg.specialArgsMap
	else
		return false
	end
end

function dataEasy.getUnitId(cardid, skinid)
	if skinid == nil or skinid == 0 then
		if csv.cards[cardid] then
			return csv.cards[cardid].unitID
		end

		skinid = cardid
		cardid = nil
	end

	local cfg = gSkinCsv[skinid]

	if not cardid then
		if csvSize(cfg.unitIDs) > 1 then
			local fightingPoint = 0

			for _, v in ipairs(gGameModel.role:read("cards")) do
				local card = gGameModel.cards:find(v)

				if card then
					local tmpCardid = card:read("card_id")

					if cfg.unitIDs[tmpCardid] and csv.cards[tmpCardid].cardMarkID == cfg.markID then
						local val = card:read("fighting_point")

						if fightingPoint < val then
							fightingPoint = val
							cardid = tmpCardid
						end
					end
				end
			end
		end

		cardid = cardid or csvNext(cfg.unitIDs)
	end

	local _, unitId = csvNext(cfg.unitIDs)

	return cfg.unitIDs[cardid] or unitId
end

function dataEasy.getUnitCsv(cardid, skinid)
	local unitId = dataEasy.getUnitId(cardid, skinid)

	return csv.unit[unitId]
end

function dataEasy.getCardSkillList(cardid, skinid)
	if skinid == nil or skinid == 0 then
		return csv.cards[cardid].skillList
	else
		local map = csv.cards[cardid].skinSkillMap

		return map[skinid]
	end

	return nil
end

function dataEasy.getSortCardSkillList(cardid, skinid)
	local skillCsvDatas = dataEasy.getCardSkillList(cardid, skinid)

	if skillCsvDatas == nil then
		return {}
	end

	local matchSkillDatas = {}
	local skillDatas = {}

	for k, v in csvPairs(skillCsvDatas) do
		local skillType = csv.skill[v].skillType

		if skillType == 1 then
			table.insert(matchSkillDatas, v)
		else
			table.insert(skillDatas, v)
		end
	end

	table.sort(skillDatas, function(a, b)
		return a < b
	end)
	table.sort(matchSkillDatas, function(a, b)
		return a < b
	end)

	return arraytools.merge({
		skillDatas,
		matchSkillDatas
	})
end

function dataEasy.isShowSkinIcon(cardid)
	local map = csv.cards[cardid].skinSkillMap
	local sign = false

	for key, data in csvPairs(map) do
		if gSkinCsv[key] and gSkinCsv[key].isOpen then
			sign = true

			break
		end
	end

	return sign
end

function dataEasy.getUnitIdForJJC(id)
	local skinId

	if id > game.SKIN_ADD_NUM then
		skinId = id % game.SKIN_ADD_NUM
		id = nil
	end

	return dataEasy.getUnitId(id, skinId) or 0
end

function dataEasy.isShowDailyActivityIcon()
	local function getTimestamp(huodongDate, huodongTime)
		local hour, min = time.getHourAndMin(huodongTime)

		return time.getNumTimestamp(huodongDate, hour, min)
	end

	local nowTime = time.getTime()

	for k, v in orderCsvPairs(csv.huodong) do
		if csvSize(v.paramMap) > 0 then
			local beginTime = getTimestamp(v.beginDate, v.beginTime)
			local endTime = getTimestamp(v.endDate, v.endTime)

			if beginTime < nowTime and nowTime < endTime then
				return true, v
			end
		end
	end

	return false
end

function dataEasy.isZawakeSkill(skillID, zawakeSkills)
	if not csv.skill[skillID] then
		return false
	end

	local zawakeEffectID = csv.skill[skillID].zawakeEffect[1]

	for _, id in ipairs(zawakeSkills or {}) do
		if zawakeEffectID == id then
			return true
		end
	end

	return false
end

function dataEasy.getPayClientSafeTime()
	do return -1 end

	if APP_CHANNEL == "lp_en" then
		return 600
	end

	if device.platform == "ios" then
		return 3600
	end

	return 600
end

function dataEasy.setPayClientBuyTimes(key, activityId, idx, nowTimes)
	local curTime = time.getTime()
	local userDefaultData = userDefault.getForeverLocalKey(key, {})

	userDefaultData[activityId] = userDefaultData[activityId] or {}

	local data = userDefaultData[activityId][idx] or {
		buyTimes = 0,
		curTime = curTime
	}

	data.buyTimes = math.max(data.buyTimes, nowTimes) + 1
	data.curTime = curTime
	userDefaultData[activityId][idx] = data

	userDefault.setForeverLocalKey(key, userDefaultData, {
		new = true
	})
end

function dataEasy.getPayClientBuyTimes(key, activityId, idx, nowTimes)
	local curTime = time.getTime()
	local clientSafeTime = dataEasy.getPayClientSafeTime()
	local userDefaultData = userDefault.getForeverLocalKey(key, {})

	userDefaultData[activityId] = userDefaultData[activityId] or {}

	local data = userDefaultData[activityId][idx] or {
		buyTimes = 0,
		curTime = curTime
	}

	if clientSafeTime < curTime - data.curTime then
		data.buyTimes = 0
		userDefaultData[activityId][idx] = nil

		userDefault.setForeverLocalKey(key, userDefaultData, {
			new = true
		})

		return nowTimes
	end

	if nowTimes >= data.buyTimes then
		data.buyTimes = 0
		userDefaultData[activityId][idx] = nil

		userDefault.setForeverLocalKey(key, userDefaultData, {
			new = true
		})

		return nowTimes
	end

	return data.buyTimes
end

function dataEasy.getTimeStrByKey(key, state, isVal)
	local data = {
		craft = {
			signUpStart = {
				hour = 10,
				min = 0
			},
			signUpEnd = {
				hour = 19,
				min = 50
			},
			matchStart = {
				hour = 20,
				min = 0
			}
		},
		unionFight = {
			signUpStart = {
				hour = 9,
				min = 30
			},
			signUpEnd = {
				hour = 20,
				min = 50
			},
			matchStart = {
				hour = 21,
				min = 0
			}
		},
		crossCraft = {
			signUpStart = {
				hour = 10,
				min = 0
			},
			signUpEnd = {
				hour = 18,
				min = 50
			},
			matchStart = {
				hour = 19,
				min = 0
			},
			matchEnd = {
				hour = 19,
				min = 46
			}
		},
		onlineFight = {
			matchStart = {
				hour = 12,
				min = 0
			},
			matchEnd = {
				hour = 20,
				min = 0
			},
			over = {
				hour = 22,
				min = 0
			}
		},
		crossMine = {
			mineStart = {
				hour = 10,
				min = 0
			},
			mineEnd = {
				hour = 22,
				min = 0
			}
		}
	}

	if matchLanguageForce({
		"en"
	}) then
		data.craft.signUpStart = {
			hour = 13,
			min = 0
		}
		data.craft.signUpEnd = {
			hour = 21,
			min = 50
		}
		data.craft.matchStart = {
			hour = 22,
			min = 0
		}
		data.unionFight.signUpStart = {
			hour = 11,
			min = 30
		}
		data.unionFight.signUpEnd = {
			hour = 22,
			min = 50
		}
		data.unionFight.matchStart = {
			hour = 23,
			min = 0
		}
		data.crossCraft.signUpStart = {
			hour = 13,
			min = 0
		}
		data.crossCraft.signUpEnd = {
			hour = 21,
			min = 50
		}
		data.crossCraft.matchStart = {
			hour = 22,
			min = 0
		}
		data.crossCraft.matchEnd = {
			hour = 22,
			min = 46
		}
		data.crossMine.mineStart = {
			hour = 12,
			min = 0
		}
		data.crossMine.mineEnd = {
			hour = 23,
			min = 0
		}
	end

	if isVal then
		return data[key][state].hour, data[key][state].min
	end

	return string.format("%02d:%02d", data[key][state].hour, data[key][state].min)
end

function dataEasy.getGemQualityIndex(card)
	local gems = card:read("gems")
	local qualityCsv, gemCsv = csv.gem.quality, csv.gem.gem
	local qualityNum = 0

	for k, dbid in pairs(gems) do
		local gem = gGameModel.gems:find(dbid)
		local level = gem:read("level")
		local gemId = gem:read("gem_id")
		local quality = gemCsv[gemId].quality

		qualityNum = qualityNum + qualityCsv[level]["qualityNum" .. quality]
	end

	return qualityNum
end

function dataEasy.getCitySceneIdx()
	local nowTime = time.getTime()

	for id, cfg in orderCsvPairs(csv.cityscene) do
		if cfg.onlyActivity then
			local beginHour, beginMin = time.getHourAndMin(cfg.beginTime, true)
			local beginTime = time.getNumTimestamp(cfg.beginDate, beginHour, beginMin)
			local endHour, endMin = time.getHourAndMin(cfg.endTime, true)
			local endTime = time.getNumTimestamp(cfg.endDate, endHour, endMin)

			if beginTime < nowTime and nowTime < endTime then
				return id, true
			end
		end
	end

	local idx = gGameModel.role:read("city_scene")

	if csv.cityscene[idx] and csv.cityscene[idx].canChoose then
		return idx
	end

	return 1
end

function dataEasy.getSupremacyStageByRank(score)
	score = math.max(score, 0)

	for i, v in orderCsvPairs(csv.cross.supremacy.grade) do
		if score >= v.score then
			local stageData = csvClone(v)

			stageData.score = score - v.score

			return stageData
		end
	end
end

local function checkSpecialItem(cfg, field, modelKey, modelVal, targetCsv, targetPath)
	local key = cfg.specialArgsMap[field]

	if key then
		if modelVal and gGameModel.role:read(modelKey)[key] == modelVal or not modelVal and gGameModel.role:read(modelKey)[key] then
			return true
		end

		if not targetCsv[key] then
			errorInWindows(string.format("csv.items[%s].specialArgsMap.%s(%s) not open in csv.%s[%s]", cfg.id, field, key, targetPath, key))
		end
	end
end

function dataEasy.checkActiveSpecialLogo(id, cfg, fields)
	cfg = cfg or dataEasy.getCfgByKey(id)
	fields = fields or {
		"skinID",
		"figure",
		"logo",
		"frame",
		"title"
	}

	local flag = false
	local func = {
		skinID = function()
			return checkSpecialItem(cfg, "skinID", "skins", 0, csv.card_skin, "card_skin")
		end,
		figure = function()
			return checkSpecialItem(cfg, "figure", "figures", nil, csv.role_figure, "role_figure")
		end,
		logo = function()
			return checkSpecialItem(cfg, "logo", "logos", nil, csv.role_logo, "role_logo")
		end,
		frame = function()
			return checkSpecialItem(cfg, "frame", "frames", nil, csv.role_frame, "role_frame")
		end,
		title = function()
			return checkSpecialItem(cfg, "title", "titles", nil, csv.title, "title")
		end
	}

	if cfg.specialArgsMap then
		for _, filed in pairs(fields) do
			flag = flag or func[filed]()
		end
	end

	return flag
end

function dataEasy.getLightingNewYearCsvId(yyid)
	local yyhuodongs = gGameModel.role:read("yyhuodongs")
	local yyData = yyhuodongs[yyid] or {}
	local stamps = yyData.stamps or {}
	local stamps1 = yyData.stamps1 or {}
	local nowDate = time.getNowDate()
	local flag = userDefault.getForeverLocalKey("lightingNewYearFlag" .. tostring(nowDate.year), false)

	if itertools.size(stamps1) == 0 and not flag then
		return nil
	end

	local days = yyData.info and yyData.info.days or 0
	local huodongID = csv.yunying.yyhuodong[yyid].huodongID
	local minId = 0

	for i, v in orderCsvPairs(csv.yunying.lighting_new_year) do
		if huodongID == v.huodongID then
			if v.day == days then
				if not stamps1[i] then
					return i
				end
			elseif days > v.day then
				if stamps[v.day] == 0 and not stamps1[i] then
					return i
				end

				if not stamps1[i] and minId == 0 then
					minId = i
				end
			end
		end
	end

	return minId
end

function dataEasy.getInMeteorCardsHash()
	local meteorites = gGameModel.role:read("meteorites") or {}
	local t = {}

	for i, v in pairs(meteorites) do
		if v.card then
			t[v.card] = true
		end
	end

	return t
end

function dataEasy.fixInMeteorCards(cards)
	local hash = dataEasy.getInMeteorCardsHash()
	local t = {}

	for k, hexdbid in pairs(cards) do
		local dbid = stringz.hextobin(hexdbid)

		if not hash[dbid] then
			t[k] = hexdbid
		end
	end

	return t
end

function dataEasy.getInMeteorHelditemsHash()
	local meteorites = gGameModel.role:read("meteorites") or {}
	local t = {}

	for i, v in pairs(meteorites) do
		for _, dbid in pairs(v.helditems or {}) do
			t[dbid] = true
		end
	end

	return t
end

function dataEasy.fixAidCards(cards, aidNum)
	for k, dbid in pairs(cards) do
		if aidNum and aidNum < k then
			cards[k] = nil
		end

		local card = gGameModel.cards:find(dbid)

		if card then
			if not dataEasy.isOpenAid(nil, dbid, true) then
				cards[k] = nil
			end
		else
			cards[k] = nil
		end
	end

	return cards
end

function dataEasy.getDiscountText(discount)
	if matchLanguage({
		"cn",
		"tw"
	}) then
		return string.format(gLanguageCsv.discount, math.ceil(discount * 100) / 10)
	end

	return string.format(gLanguageCsv.discount, 100 - math.ceil(discount * 100))
end

function dataEasy.getIsStarAidState(dbId)
	if not dbId then
		return false
	end

	local fieldSeat = gGameModel.role:read("card_star_swap_fields") or {}

	for _, v in pairs(fieldSeat) do
		if itertools.include(v.cards, dbId) then
			return true
		end
	end

	return false
end

function dataEasy.followSpineBone(node, effect, boneName, params)
	params = params or {}

	node:runAction(cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
		local posx, posy = effect:getPosition()
		local sx, sy = effect:getScaleX(), effect:getScaleY()
		local bxy = effect:getBonePosition(boneName)
		local rotation = effect:getBoneRotation(boneName)
		local scaleX = effect:getBoneScaleX(boneName)
		local scaleY = effect:getBoneScaleY(boneName)

		node:rotate(rotation):scaleX(scaleX * (params.scale or 1)):scaleY(scaleY * (params.scale or 1)):xy(bxy.x * sx + posx + (params.x or 0), bxy.y * sy + posy + (params.y or 0))
	end))))
end

function dataEasy.getTeamWeatherData(cards)
	if not dataEasy.isUnlock(gUnlockCsv.weather) then
		return {}
	end

	local datas = {}

	for i = 1, 6 do
		local dbid = cards[i]
		local card = gGameModel.cards:find(dbid)

		if card then
			local cardData = card:read("card_id", "unit_id", "skin_id", "star", "advance", "level")
			local cardID = cardData.card_id
			local unitCfg = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)
			local star = cardData.star

			datas[i] = {
				dbid = dbid,
				cardID = cardID,
				unitID = unitCfg.id,
				attr1 = unitCfg.natureType,
				attr2 = unitCfg.natureType2,
				star = star,
				advance = cardData.advance,
				level = cardData.level
			}
		end
	end

	return datas
end

local function getTeamWeatherCondition(weatherCfg, params)
	local attrsNum = params.attrsNum
	local cardsNum = params.cardsNum
	local conditions = {}

	for i = 1, math.huge do
		local upgradeType = weatherCfg["upgradeType" .. i]

		if not upgradeType or upgradeType == 0 then
			break
		end

		conditions[i] = true

		local upgradeCondition = weatherCfg["upgradeCondition" .. i]

		if upgradeType == 1 then
			for key, num in csvPairs(upgradeCondition) do
				if not attrsNum[key] or num > attrsNum[key] then
					conditions[i] = false

					break
				end
			end
		elseif upgradeType == 2 then
			for key, num in csvPairs(upgradeCondition) do
				if not cardsNum[key] or num > cardsNum[key] then
					conditions[i] = false

					break
				end
			end
		end
	end

	return conditions
end

function dataEasy.getTeamWeather(cards, orderFlag, params)
	if not dataEasy.isUnlock(gUnlockCsv.weather) then
		return {}
	end

	params = params or {}

	local datas = params.cardsData or dataEasy.getTeamWeatherData(cards)
	local cardIDs = {}

	for i = 1, 6 do
		local t = datas[i]

		if t then
			local cardID = t.cardID

			if not cardIDs[cardID] or cardIDs[cardID].star <= t.star then
				cardIDs[cardID] = datas[i]
			end
		end
	end

	local weather = {}
	local cardsNum = {}
	local attrsNum = {}

	for k, v in pairs(datas) do
		cardsNum[v.cardID] = cardsNum[v.cardID] and cardsNum[v.cardID] + 1 or 1
		attrsNum[v.attr1] = attrsNum[v.attr1] and attrsNum[v.attr1] + 1 or 1

		if v.attr2 then
			attrsNum[v.attr2] = attrsNum[v.attr2] and attrsNum[v.attr2] + 1 or 1
		end
	end

	for _, cfg in orderCsvPairs(csv.weather_system.active) do
		if cardsNum[cfg.cardID] and cardIDs[cfg.cardID].star >= cfg.starRequirement then
			local zawakeID = csv.cards[cfg.cardID].zawakeID
			local stage, level = zawakeTools.getMaxStageLevel(zawakeID)

			if not stage then
				stage = 1
				level = 0
			end

			if params.isTestPlay then
				stage = 0
				level = 0
			end

			if stage * 100 + level >= cfg.zawakeRequirement then
				local weatherID = cfg.weatherID
				local weatherCfg = csv.weather_system.weather[weatherID]
				local conditions = getTeamWeatherCondition(weatherCfg, {
					attrsNum = attrsNum,
					cardsNum = cardsNum
				})

				if itertools.isempty(conditions) or itertools.include(conditions, true) then
					table.insert(weather, {
						weatherID = weatherID,
						cfg = weatherCfg,
						data = cardIDs[cfg.cardID]
					})
				end
			end
		end
	end

	if orderFlag then
		table.sort(weather, function(a, b)
			if a.cfg.advanced ~= b.cfg.advanced then
				return a.cfg.advanced > b.cfg.advanced
			end

			return a.cfg.id < b.cfg.id
		end)
	else
		table.sort(weather, function(a, b)
			if a.cfg.advanced ~= b.cfg.advanced then
				return a.cfg.advanced > b.cfg.advanced
			end

			local attrsNumA = attrsNum[a.cfg.natureType] or 0
			local attrsNumB = attrsNum[b.cfg.natureType] or 0

			return attrsNumB < attrsNumA
		end)
	end

	return weather
end

function dataEasy.getWeatherID(battleCards, selectWeatherID, params)
	if not dataEasy.isUnlock(gUnlockCsv.weather) then
		return 0
	end

	params = params or {}

	local weatherID = selectWeatherID
	local result = params.result or dataEasy.getTeamWeather(battleCards)
	local hasSelectWeather = itertools.include(itertools.map(result, function(k, v)
		return v.weatherID
	end), weatherID)

	if not hasSelectWeather then
		if itertools.size(result) > 0 then
			local _, data = next(result)

			weatherID = data.weatherID
		else
			weatherID = 0
		end
	end

	return weatherID
end

function dataEasy.getAttrStr(attrMap)
	local same6 = false

	if csvSize(attrMap) == 6 then
		same6 = true

		local lastValue

		for attr, value in csvMapPairs(attrMap) do
			if lastValue and value ~= lastValue then
				same6 = false

				break
			end

			lastValue = value
		end
	end

	if not same6 then
		local t = {}
		local attrStr = ""

		for attr, value in csvMapPairs(attrMap) do
			local name = gLanguageCsv["attr" .. string.caption(game.ATTRDEF_TABLE[attr])]

			table.insert(t, string.format("%s #C0x60C456#+%s#C0x5B545B#", name, value))
		end

		return table.concat(t, gLanguageCsv.symbolDot)
	else
		local _, value = csvNext(attrMap)

		return string.format(gLanguageCsv.sixAttrUpTip, value)
	end
end

function dataEasy.deleteStrFormat(str, pattern)
	local p, q

	while true do
		p, q = str:find(pattern, p)

		if p == nil then
			break
		end

		str = str:sub(1, p - 1) .. str:sub(q + 1)
	end

	return str
end

function dataEasy.isTotemInsert(key)
	local TotemTools = require("app.views.city.develop.totem.tools")

	local function activeTotem()
		local insettedTotem = gGameModel.totem:read("totem_insetted")
		local engry = TotemTools.getActivateTotemEnergy(insettedTotem)
		local activeData, allData = {}, {}

		for csvId, v in orderCsvPairs(csv.totem.symbol) do
			local group = v.symbolGroupType

			if csv.totem.symbol_group[group] and engry >= csv.totem.symbol_group[group].unlockEnergy and engry >= csv.totem.symbol_group[group].showEnergy then
				for ii, vv in pairs(v.totemGroup1) do
					if vv == key then
						allData[group] = (allData[group] or 0) + 1

						if insettedTotem[csvId] and insettedTotem[csvId][ii] then
							activeData[group] = (activeData[group] or 0) + 1
						end
					end
				end
			end
		end

		return activeData, allData
	end

	local function upStarTotem()
		local insettedTotem = gGameModel.totem:read("totem_insetted")
		local insettedTotemStar = gGameModel.totem:read("totem_star")
		local engry = TotemTools.getActivateTotemEnergy(insettedTotem)
		local fullStarData, allData = {}, {}

		for csvId, v in orderCsvPairs(csv.totem.symbol) do
			local group = v.symbolGroupType

			if csv.totem.symbol_group[group] and engry >= csv.totem.symbol_group[group].unlockEnergy and engry >= csv.totem.symbol_group[group].showEnergy then
				local isMaxStar = insettedTotemStar[csvId] and insettedTotemStar[csvId] >= itertools.size(gTotemStarIdCsv[v.starSeqID])

				for ii, vv in pairs(v.totemGroup1) do
					if vv == key then
						allData[group] = (allData[group] or 0) + 1

						if isMaxStar then
							fullStarData[group] = (fullStarData[group] or 0) + 1
						end
					end
				end
			end
		end

		return fullStarData, allData
	end

	local activeData, allData = {}, {}

	if dataEasy.isUnlock(gUnlockCsv.totemStar) and TotemTools.isUnlockUse() then
		activeData, allData = upStarTotem()
	else
		activeData, allData = activeTotem()
	end

	local activeSum = 0
	local allSum = 0

	for i, v in pairs(allData) do
		activeSum = (activeData[i] or 0) + activeSum
		allSum = v + allSum
	end

	return activeSum < allSum
end

local NEW_PACKET_TAGS_EN_URL = {
	as_monmaster_gold_aos = {},
	as_mjourney_gold_aos_yidun = {},
	as_battleelf_gold_aos = {},
	as_agorapacelvoh_gold_aos = {},
	com_pyjx_six_lhyq_aos = {},
	com_wrty_teny_avbm_aos = {},
	as_qkny_four_teen_aos = {},
	as_b142_four_teen_aos = {},
	com_bylp_nine_bytl_aos = {},
	as_mobimastevo_gold_aos = {},
	com_jieneilin_aos = {},
	as_elfisland_gold_aos = {},
	as_elfisland_gold_aos_two = {},
	as_evomonlve_gold_aos = {},
	as_ptfts_gold_aos = {},
	as_petrealm_gold_aos_yidun = {},
	as_kzoq_zfif_teen_aos = {},
	as_mondashster_gold_aos = {},
	as_thir_teen_jukp_aos = {},
	as_islandmon_gold_aos = {},
	as_matrascdanorg_gold_aos = {},
	as_safariex_gold_aos = {},
	as_pettamer_gold_aos = {},
	as_hypevoadv_gold_aos = {},
	com_huan_xinli = {},
	com_fengc_hen = {},
	com_ming_weiliang = {},
	as_com_raidios_enmonster = {},
	com_weinong_liang = {},
	as_elfbuddy_gold_yidun = {},
	as_msttriiosevo_gold = {},
	com_fq_ch = {},
	charmers_gold_ios_yidun = {},
	as_com_peten_originios = {}
}
local NEW_PACKET_TAGS_URL = {
	as_mrpq_zsix_teen_aos = "https://play.google.com/store/apps/details?id=com.bkju.elev.enlp",
	kdjxbseven_gold_aos = "https://play.google.com/store/apps/details?id=com.bkju.elev.enlp",
	as_kdjxbseven_gold_aos_yidun = "https://play.google.com/store/apps/details?id=com.bkju.elev.enlp"
}
local KR_ONSTORE_TAGS_USR = {
	as_com_fkdjxkr_base_yidun_v4_onestore2 = {}
}

function dataEasy.getPacketUrl()
	if matchLanguage({
		"kr"
	}) then
		if KR_ONSTORE_TAGS_USR[APP_TAG] then
			return "https://goingamecdn.zufuning.com/apk/com.fkdjxkr.id11sfzf_102.apk"
		end

		return "https://play.google.com/store/apps/details?id=com.cyzq.cyan.aert"
	end

	if matchLanguageForce({
		"en_us"
	}) then
		if device.platform == "ios" then
			return "https://apps.apple.com/app/id6504473326"
		else
			return "http://pokemoncrisp.com/q1y"
		end
	elseif matchLanguageForce({
		"en"
	}) then
		return "https://raocdn.raoovoo.com/gc_file/fkdjxenWebPay/src/views/download.html"
	end

	if not sdk.loginInfo then
		return "https://api.qingshangame.com/link"
	end

	local _aes = require("aes")
	local _msgpack = require("3rd.msgpack")
	local msgpack = _msgpack.pack
	local msgunpack = _msgpack.unpack
	local Hex = _aes.key128Hex
	local encrypt = _aes.encryptCBC
	local decrypt = _aes.dectyptCBC
	local strrep = string.rep
	local t = json.decode(sdk.loginInfo)
	local pad = 0
	local uid = t.userId or ""

	if #uid % 16 ~= 0 then
		pad = 16 - #uid % 16
		uid = uid .. strrep("\x00", pad)
	end

	local InitPwdAES = "tjshuma202112130"
	local InitPwdHexAES = Hex(InitPwdAES)
	local euid = encrypt(uid, InitPwdHexAES)
	local cid = t.channelId or ""

	return string.format("https://api.qingshangame.com/link?uid=%s&cid=%s&plat=%s", stringz.bintohex(euid), cid, device.platform)
end

function dataEasy.deleteStrFormat(str, pattern)
	local p, q

	while true do
		p, q = str:find(pattern, p)

		if p == nil then
			break
		end

		str = str:sub(1, p - 1) .. str:sub(q + 1)
	end

	return str
end

function dataEasy.isSkillChange()
	return true
end

function dataEasy.getSkillDesc(cfg)
	if dataEasy.isSkillChange() then
		return uiEasy.skillDesc2str(cfg.describe1)
	end

	return cfg.describe
end

function dataEasy.getCurMaxStage(dbid)
	local card = gGameModel.cards:find(dbid)
	local zawakeID = csv.cards[card:read("card_id")].zawakeID

	if dataEasy.getIsStarAidState(dbid) then
		local maxStage = itertools.size(gZawakeStagesCsv[zawakeID])

		for i = maxStage, 1, -1 do
			local isUnlock = zawakeTools.isPreUnlockByState(zawakeID, i)

			if isUnlock then
				local zawake = gGameModel.role:read("zawake") or {}
				local data = zawake[zawakeID] or {}

				return i, data[i] or 0
			end
		end
	else
		local stage, level = zawakeTools.getMaxStageLevel(zawakeID)

		return stage or 0, level or 0
	end

	return 0, 0
end

function dataEasy.isChatOpen(unlockKey, noTip, isShowDialog)
	local chatServerDays = gCommonConfigCsv.chatServerDays or 0
	local chatVIP = gCommonConfigCsv.chatVIP or 0
	local vipLevel = gGameModel.role:read("vip_level") or 0

	if chatVIP <= 0 then
		if unlockKey and not dataEasy.isUnlock(unlockKey) then
			if not noTip then
				gGameUI:showTip(dataEasy.getUnlockTip(unlockKey))
			end

			return false
		end

		return true
	end

	if chatVIP <= vipLevel then
		return true
	end

	if dataEasy.serverOpenDaysLess(chatServerDays + 1) then
		if not noTip then
			gGameUI:showTip(gLanguageCsv.chatOpenTip1, chatServerDays, uiEasy.getVipStr(chatVIP).str)
		end

		if isShowDialog then
			gGameUI:showDialog({
				fontSize = 50,
				isRich = true,
				title = gLanguageCsv.changeNoticeTip,
				content = "#C0x5B545B#" .. string.format(gLanguageCsv.chatOpenTip1, chatServerDays, uiEasy.getVipStr(chatVIP).str)
			})
		end

		return false
	end

	if unlockKey and not dataEasy.isUnlock(unlockKey) then
		if not noTip then
			local cfg = csv.unlock[unlockKey]

			gGameUI:showTip(gLanguageCsv.chatOpenTip2, uiEasy.getVipStr(chatVIP).str, cfg.startLevel)
		end

		return false
	end

	return true
end

function dataEasy.searchText(str, targetStr, params)
	if params.filterCS then
		str = string.upper(str)
		targetStr = string.upper(targetStr)
	end

	local function utfCharIdx(str)
		local idxTb = {}
		local currentIndex = 1

		while currentIndex <= #str do
			local char = string.byte(str, currentIndex)
			local charLength = string.utf8charlen(char)
			local t = currentIndex

			currentIndex = currentIndex + charLength

			table.insert(idxTb, {
				startIdx = t,
				endIdx = currentIndex - 1
			})
		end

		return idxTb
	end

	if params.isFuzzy then
		local targetStr1 = ""

		for _, v in ipairs(utfCharIdx(targetStr)) do
			targetStr1 = targetStr1 .. ".*" .. string.sub(targetStr, v.startIdx, v.endIdx)
		end

		targetStr = targetStr1 .. ".*"

		if string.find(str, targetStr) then
			return true
		end
	elseif string.find(str, targetStr, nil, true) then
		return true
	end

	return false
end

function dataEasy.getVipGift2(activityID)
	if not activityID then
		return {}
	end

	local vipLevel = gGameModel.role:read("vip_level")
	local vipGift2 = gGameModel.role:read("vip_gift_2")
	local huodongID = csv.yunying.yyhuodong[activityID].huodongID
	local t = {}

	for id, cfg in orderCsvPairs(csv.yunying.vip_gift_2) do
		if cfg.huodongID == huodongID and vipLevel >= cfg.showVipLevel then
			local hasBuy = vipGift2[id] == 0

			if cfg.rechargeID ~= -1 then
				assert(csv.recharges[cfg.rechargeID], string.format("rechargeID(%s) 在 csv.recharges 中不存在", cfg.rechargeID))
			end

			table.insert(t, {
				id = id,
				cfg = cfg,
				rechargeCfg = csv.recharges[cfg.rechargeID],
				state = cfg.rechargeID == -1 and 1 or 2,
				hasBuy = hasBuy
			})
		end
	end

	table.sort(t, function(a, b)
		if a.cfg.vipLevel ~= b.cfg.vipLevel then
			return a.cfg.vipLevel < b.cfg.vipLevel
		end

		if a.state ~= b.state then
			return a.state < b.state
		end

		return a.cfg.endDate < b.cfg.endDate
	end)

	local nowTime = time.getTime()
	local tmp = {}
	local datas = {}
	local preVip

	for _, v in ipairs(t) do
		if preVip ~= v.cfg.vipLevel then
			preVip = v.cfg.vipLevel

			table.insert(datas, {
				title = v.cfg.vipLevel
			})
		end

		tmp[v.cfg.vipLevel] = tmp[v.cfg.vipLevel] or {}

		local idx = tmp[v.cfg.vipLevel][v.state]

		if not idx then
			table.insert(datas, v)

			tmp[v.cfg.vipLevel][v.state] = #datas
		else
			local data = datas[idx]
			local hour, min = time.getHourAndMin(data.cfg.endTime, true)

			if nowTime >= time.getNumTimestamp(data.cfg.endDate, hour, min) then
				datas[idx] = v
			else
				data.hasNext = true
			end
		end
	end

	return datas
end

function dataEasy.getAidNum(gateType, multi, roleLevel)
	local cfg = csv.unlock[gUnlockCsv.aid]

	if not csv.aid.scene[gateType] or not cfg then
		return 0, {}
	end

	local roleLevel = roleLevel or gGameModel.role:read("level")

	if not dataEasy.isInServer(cfg.feature) or roleLevel < cfg.startLevel then
		return 0, {}
	end

	local cfg = csv.aid.scene[gateType]
	local aidUnlockLevel = cfg.aidUnlockLevel

	if multi == 2 then
		aidUnlockLevel = cfg.aidUnlockLevel2
	elseif multi == 3 then
		aidUnlockLevel = cfg.aidUnlockLevel3
	end

	local aidNum = 0

	for i = 1, csvSize(aidUnlockLevel) do
		if roleLevel >= aidUnlockLevel[i] then
			aidNum = i
		end
	end

	return aidNum, aidUnlockLevel
end

function dataEasy.isOpenAid(cardID, dbid, needActive, onlyShow)
	local aidID

	if cardID then
		aidID = csv.cards[cardID].aidID
	end

	if dbid then
		local card = gGameModel.cards:find(dbid)

		aidID = csv.cards[card:read("card_id")].aidID
	end

	if onlyShow and dataEasy.isShow(gUnlockCsv.aid) and aidID > 0 and csv.aid.aid[aidID] ~= nil then
		return true
	end

	if not dataEasy.isUnlock(gUnlockCsv.aid) then
		return false
	end

	if not needActive then
		return aidID > 0 and csv.aid.aid[aidID] ~= nil
	else
		local activeAid = gGameModel.role:read("active_aid")
		local isActive = activeAid ~= nil and activeAid[aidID] ~= nil and activeAid[aidID].level > 0

		return isActive
	end
end

function dataEasy.isMergeCard(cardID)
	local megaIndex = csv.cards[cardID].megaIndex

	if megaIndex > 0 then
		return csv.card_mega[megaIndex].type == 3
	end

	return false
end

function dataEasy.getCardMarkID(cardID)
	local cardCfg = csv.cards[cardID]

	if dataEasy.isMergeCard(cardID) then
		local combID = csv.fragments[cardCfg.fragID].combID

		cardCfg = csv.cards[combID]
	end

	return cardCfg.cardMarkID
end

function dataEasy.getCardMergeInfo()
	local roleCardMerge = gGameModel.role:read("card_merge") or {}
	local mergeAB, mergeC, relieveC, all = {}, {}, {}, {}

	for markID, data in pairs(roleCardMerge) do
		local mergeCards = data.merge_cards or {}

		if itertools.size(mergeCards) > 0 then
			for _, id in pairs(mergeCards) do
				mergeAB[id] = markID
				all[id] = markID
			end

			if data.id then
				mergeC[data.id] = markID
				all[data.id] = markID
			end
		elseif data.id then
			relieveC[data.id] = markID
			all[data.id] = markID
		end
	end

	return {
		mergeAB = mergeAB,
		mergeC = mergeC,
		relieveC = relieveC,
		all = all
	}
end

function dataEasy.fixEmattleMultiCards(battleCards, noTip)
	local _, data = next(battleCards)

	if type(data) ~= "table" then
		return dataEasy.fixEmattleCards(battleCards, noTip)
	end

	local t = {}
	local fix = false
	local flag

	for i, data in pairs(battleCards) do
		t[i], flag = dataEasy.fixEmattleCards(data, noTip)
		fix = fix or flag
	end

	return t, fix
end

function dataEasy.fixEmattleCards(battleCards, noTip)
	local t = {}
	local mergeInfo = dataEasy.getCardMergeInfo()
	local fix = false

	for i, v in pairs(battleCards) do
		local dbid = type(v) ~= "table" and v or v.dbid

		if not mergeInfo.mergeAB[dbid] and not mergeInfo.relieveC[dbid] then
			t[i] = v
		else
			fix = true
		end
	end

	if fix and not noTip then
		gGameUI:showTip(gLanguageCsv.cardMergeFix1)
	end

	return t, fix
end

function dataEasy.getHashMarkIDs(cardID)
	local cardCfg = csv.cards[cardID]

	if not cardCfg then
		return {}
	end

	if dataEasy.isMergeCard(cardID) then
		local megaCfg = csv.card_mega[cardCfg.megaIndex]
		local t = {}

		for _, v in orderCsvPairs(megaCfg.card) do
			local markID = csv.cards[v[1]].cardMarkID

			t[markID] = true
		end

		return t
	end

	return {
		[cardCfg.cardMarkID] = true
	}
end

function dataEasy.hasSameMarkIDCard(cardID1, cardID2)
	if not cardID1 or not cardID2 then
		return false
	end

	local hash1 = dataEasy.getHashMarkIDs(cardID1)
	local hash2 = dataEasy.getHashMarkIDs(cardID2)
	local t = maptools.intersection_with(hash1, hash2)

	return not itertools.isempty(t)
end

function dataEasy.removeSpriteEventText(params)
	local parent = params.parent or gGameUI.scene

	parent:stopActionByTag(SPRITE_EVENT_TEXT_TAG)
	parent:removeChildByName("_event_effect_")
	parent:removeChildByName("_event_effect_text_")
end

function dataEasy.setSpriteEventTextHandler(params)
	local parent = params.parent or gGameUI.scene

	parent:stopActionByTag(SPRITE_EVENT_TEXT_TAG)

	if not params.effect then
		parent:removeChildByName("_event_effect_")
	end

	params.eventT = params.eventT or {}

	local effect = params.effect or widget.addAnimationByKey(parent, params.effectName, "_event_effect_", params.action, 100):scale(2):alignCenter(parent:size())

	effect:play(params.action)

	local tic = os.clock()

	effect:setSpriteEventHandler(function(event, eventArgs)
		effect:setSpriteEventHandler(nil, sp.EventType.ANIMATION_COMPLETE)
		performWithDelay(parent, function()
			if not params.noDelete then
				parent:removeChildByName("_event_effect_")
				parent:removeChildByName("_event_effect_text_")
			end

			if params.cb then
				params.cb(effect)
			end
		end, 0)
		printInfo("setSpriteAniEventHandler cost time: %s", os.clock() - tic)
	end, sp.EventType.ANIMATION_COMPLETE)
	effect:setSpriteEventHandler(function(event, eventArgs)
		local eventID = eventArgs.eventData.intValue

		parent:stopActionByTag(SPRITE_EVENT_TEXT_TAG)
		parent:removeChildByName("_event_effect_text_")

		local str = params.eventKey and gLanguageCsv[params.eventKey .. eventID] or params.eventT[eventID]

		if str then
			str = string.formatex(str, {
				roleName = gGameModel.role and gGameModel.role:read("name")
			})

			rich.createWithWidth("#L01100011##LOS2#" .. str, 80, 0, 2000, 0, cc.p(0.5, 0)):anchorPoint(0, 0):xy(parent:width() / 2, 100):addTo(parent, 101, "_event_effect_text_")

			if params.delay then
				local action = performWithDelay(parent, function()
					parent:removeChildByName("_event_effect_text_")
				end, params.delay)

				action:setTag(SPRITE_EVENT_TEXT_TAG)
			end
		end

		printInfo("setSpriteAniEventHandler event time: %s eventID:%s %s", os.clock() - tic, eventID, str or "")
	end, sp.EventType.ANIMATION_EVENT)

	return effect
end
