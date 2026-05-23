-- chunkname: @src.app.views.city.card.star_swap.tools

local StarTools = {}

StarTools.SPROPKEY = 9000
StarTools.SPLUSPROPKEY = 9001
StarTools.SNOUSEPROPKEY = 9002
StarTools.SPLUSNOUSEPROPKEY = 9003

function StarTools.isCardAid(dbId, curSelDbId, rarity)
	local card = gGameModel.cards:find(dbId)
	local cardCsv = csv.cards[card:read("card_id")]
	local unitCsv = csv.unit[cardCsv.unitID]

	if not dataEasy.getIsStarAidState(dbId) then
		if curSelDbId then
			local selectCard = gGameModel.cards:find(curSelDbId)
			local selectCardCsv = csv.cards[selectCard:read("card_id")]
			local selectUnitCsv = csv.unit[selectCardCsv.unitID]

			if unitCsv.rarity == selectUnitCsv.rarity and selectCard:read("star") ~= card:read("star") then
				return true
			end
		elseif itertools.include(rarity, unitCsv.rarity) then
			return true
		end
	end

	return false
end

function StarTools.isCardExchange(dbId, curSelDbId)
	local card = gGameModel.cards:find(dbId)

	if not dataEasy.getIsStarAidState(dbId) then
		local cardCsv = csv.cards[card:read("card_id")]
		local unitCsv = csv.unit[cardCsv.unitID]

		if curSelDbId then
			local cardStar = card:read("star")
			local selectCard = gGameModel.cards:find(curSelDbId)
			local selectCardStar = selectCard:read("star")
			local selectCardCsv = csv.cards[selectCard:read("card_id")]
			local selectUnitCsv = csv.unit[selectCardCsv.unitID]
			local miniStar = gCommonConfigCsv.cardStarSwapMinimumStarNumber

			if unitCsv.rarity == selectUnitCsv.rarity and selectCardStar ~= cardStar and (selectCardStar < miniStar and miniStar <= cardStar or miniStar <= selectCardStar) then
				return true
			end
		else
			local rarity = {
				3,
				4
			}

			if itertools.include(rarity, unitCsv.rarity) then
				local preExchangeNum = gGameModel.role:read("card_star_swap_times")
				local sPropCount = dataEasy.getNumByKey(StarTools.SPROPKEY) + dataEasy.getNumByKey(StarTools.SNOUSEPROPKEY)
				local sPlusPropCount = dataEasy.getNumByKey(StarTools.SPLUSPROPKEY) + dataEasy.getNumByKey(StarTools.SPLUSNOUSEPROPKEY)

				if preExchangeNum[3] then
					local exchangeTimeCd = gGameModel.role:read("card_star_swap_times_cd")
					local cdCount = math.floor(math.max(0, time.getTime() - exchangeTimeCd[3]) / (gCommonConfigCsv.cardStarSwapRaritySTimesCD * 3600))

					sPropCount = sPropCount + preExchangeNum[3] + cdCount
				else
					sPropCount = sPropCount + gCommonConfigCsv.cardStarSwapRaritySDefaultTimes
				end

				if unitCsv.rarity == 3 and sPropCount > 0 or unitCsv.rarity == 4 and sPlusPropCount > 0 then
					return true
				end

				return false
			end
		end
	end

	return false
end

function StarTools.getSelectCard(from, selDbIds, curSelDbId, seatRarity)
	local result = {}
	local csvTab = csv.cards
	local unitTab = csv.unit
	local cards = gGameModel.role:read("cards")
	local mergeInfo = dataEasy.getCardMergeInfo()

	for _, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local cardCsv = csvTab[cardId]
		local unitCsv = unitTab[cardCsv.unitID]

		if not mergeInfo.all[v] and not itertools.include(selDbIds, v) and cardCsv.megaIndex <= 0 and cardCsv.cardType ~= 2 and (from == 2 and StarTools.isCardExchange(v, curSelDbId) or from == 1 and StarTools.isCardAid(v, curSelDbId, seatRarity)) then
			local skinId = card:read("skin_id")
			local unitId = dataEasy.getUnitId(cardId, skinId)

			table.insert(result, {
				isSel = false,
				id = cardId,
				unitId = unitId,
				rarity = unitCsv.rarity,
				fight = card:read("fighting_point"),
				level = card:read("level"),
				star = card:read("star"),
				advance = card:read("advance"),
				skinId = skinId,
				dbid = v,
				markId = cardCsv.cardMarkID,
				cardType = cardCsv.cardType
			})
		end
	end

	return result
end

function StarTools.getAidCardData(dbId)
	local card = gGameModel.cards:find(dbId)

	if not card then
		return {}
	end

	local cardId = card:read("card_id")
	local csvTab = csv.cards
	local unitTab = csv.unit
	local cardCsv = csvTab[cardId]
	local unitCsv = unitTab[cardCsv.unitID]
	local skinId = card:read("skin_id")
	local unitId = dataEasy.getUnitId(cardId, skinId)
	local t = {
		isSel = false,
		id = cardId,
		unitId = unitId,
		rarity = unitCsv.rarity,
		fight = card:read("fighting_point"),
		level = card:read("level"),
		star = card:read("star"),
		advance = card:read("advance"),
		skinId = skinId,
		dbid = dbId,
		markId = cardCsv.cardMarkID,
		cardType = cardCsv.cardType
	}

	return t
end

function StarTools.getCostList(type, rarity, maxStar)
	type = type == 2 and 0 or 1

	local csvData = csv.card_star_swap_cost
	local data = {}
	local costTip = {}
	local isEnough = true

	for _, v in orderCsvPairs(csvData) do
		if v.type == type and v.rarity == rarity and maxStar == v.reachStar then
			for k, v1 in csvMapPairs(v.costItem) do
				local num = dataEasy.getNumByKey(k)

				table.insert(data, {
					key = k,
					targetNum = v1,
					num = num
				})

				if num < v1 then
					isEnough = false

					table.insert(costTip, dataEasy.getCfgByKey(k).name .. "*" .. v1)
				end
			end
		end
	end

	return data, isEnough, costTip
end

function StarTools.getStarData(star)
	local tb = {}
	local starIdx = star - 6

	for i = 1, 6 do
		local icon = "city/card/star_swap/icon_star_xjzh.png"

		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end

		table.insert(tb, {
			icon = icon
		})
	end

	return tb
end

function StarTools.getReceiveCount(hadReceived)
	hadReceived = hadReceived or gGameModel.role:read("card_star_swap_times_deliver_record")

	local count = 0
	local count2 = 0

	for id, v in orderCsvPairs(csv.card_star_swap_times_deliver) do
		if not hadReceived or not hadReceived[id] then
			local hour, min = time.getHourAndMin(v.time)
			local effectTime = time.getNumTimestamp(v.date, hour, min)
			local hourEnd, minEnd = time.getHourAndMin(v.endTime)
			local endTime = time.getNumTimestamp(v.endDate, hourEnd, minEnd)
			local vipLevel = gGameModel.role:read("vip_level")
			local roleLevel = gGameModel.role:read("level")
			local realTime = time.getTime()
			local createTime = gGameModel.role:read("created_time")
			local startRoleTime = time.getNumTimestamp(v.validRoleCreatedEarliestDate)
			local endRoleTime = time.getNumTimestamp(v.validRoleCreatedLatestDate)

			if matchLanguageForce(v.languages) and effectTime <= realTime and realTime <= endTime and (v.type ~= 3 or createTime <= endRoleTime and startRoleTime <= createTime) and ((v.type == 3 or v.type == 2) and roleLevel >= v.param or v.type == 1 and vipLevel >= v.param) then
				count = count + 1

				if v.type == 2 then
					count2 = count2 + 1
				end
			end
		end
	end

	return count, count2
end

return StarTools
