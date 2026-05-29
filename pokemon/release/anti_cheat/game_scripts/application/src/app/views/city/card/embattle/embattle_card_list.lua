-- chunkname: @src.app.views.city.card.embattle.embattle_card_list

local CONDITIONS = {
	{
		attr = "fighting_point",
		name = gLanguageCsv.fighting
	},
	{
		attr = "level",
		name = gLanguageCsv.level
	},
	{
		attr = "rarity",
		name = gLanguageCsv.rarity
	},
	{
		attr = "star",
		name = gLanguageCsv.star
	},
	{
		attr = "getTime",
		name = gLanguageCsv.getTime
	}
}
local PRELOAD_COUNT = 13
local EmbattleCardList = class("EmbattleCardList", cc.load("mvc").ViewBase)

EmbattleCardList.RESOURCE_FILENAME = "common_battle_card_list.json"
EmbattleCardList.RESOURCE_BINDING = {
	item = "item",
	textNotRole = "emptyTxt",
	list = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				padding = 4,
				data = bindHelper.self("allCardDatas"),
				item = bindHelper.self("item"),
				emptyTxt = bindHelper.self("emptyTxt"),
				dataFilterGen = bindHelper.self("onFilterCards", true),
				dataOrderCmpGen = bindHelper.self("onSortCards", true),
				onItem = function(list, node, k, v)
					list.initItem(node, k, v)
				end,
				onBeforeBuild = function(list)
					list.emptyTxt:hide()
				end,
				onAfterBuild = function(list)
					local cardDatas = itertools.values(list.data)

					if #cardDatas == 0 then
						list.emptyTxt:show()
					else
						list.emptyTxt:hide()
					end
				end,
				asyncPreload = PRELOAD_COUNT
			},
			handlers = {
				clickCell = bindHelper.self("onCardItemTouch", true),
				initItem = bindHelper.self("initItem", true)
			}
		}
	},
	btnPanel = {
		varname = "btnPanel",
		binds = {
			event = "extend",
			class = "sort_menus",
			props = {
				expandUp = true,
				data = bindHelper.self("sortDatas"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				onNode = function(node)
					node:xy(-930, -480):z(18)
				end
			}
		}
	},
	aidBtn = {
		varname = "aidBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAidClick")
			}
		}
	}
}

function EmbattleCardList:onCreate(params, bAdaptUi)
	self.params = params
	self.base = params.base
	self.battleCardsData = params.battleCardsData
	self.allCardDatas = params.allCardDatas
	self.clientBattleCards = params.clientBattleCards
	self.aidCards = params.aidCards or idlertable.new({})
	self.originAidCards = params.originAidCards or idlertable.new({})
	self.sortSign = params.sortSign
	self.isTeams = params.isTeams
	self.ignoreFixCards = params.ignoreFixCards
	self.limtFunc = handler(self.base, params.limtFunc)
	self.isMovePanelExist = handler(self.base, params.isMovePanelExist)
	self.createMovePanel = handler(self.base, params.createMovePanel)
	self.deleteMovingItem = handler(self.base, params.deleteMovingItem)
	self.moveMovePanel = handler(self.base, params.moveMovePanel)
	self.onCardClick = handler(self.base, params.onCardClick)
	self.moveEndMovePanel = handler(self.base, params.moveEndMovePanel)

	self.aidBtn:hide()

	if dataEasy.isUnlock(gUnlockCsv.aid) and self.base.aidNum and self.base.aidNum > 0 then
		self.aidBtn:show()
	end

	self:initModel()
	self:initAllCards()
	self:adaptNode(bAdaptUi)
	self:initFilterBtn()

	if not params.skipClientBattleChange then
		self:initClientBattleChange()
	end

	return self
end

function EmbattleCardList:getBattle(idx)
	return math.ceil(idx / 6), (idx - 1) % 6 + 1
end

function EmbattleCardList:getBattleAid(idx)
	local aidNumMax = self.base.aidNumMax or 0

	if self.isTeams and aidNumMax > 0 then
		return math.ceil(idx / aidNumMax), 6 + (idx - 1) % aidNumMax + 1
	end

	return 2, 6 + idx
end

function EmbattleCardList:initClientBattleChange()
	local resortTimes = 0

	idlereasy.any({
		self.clientBattleCards,
		self.aidCards,
		self.sortSign
	}, function()
		resortTimes = resortTimes + 1

		performWithDelay(self, function()
			if resortTimes > 0 then
				resortTimes = 0

				local battle = self.clientBattleCards:read()
				local aidCards = self.aidCards:read()
				local hash = {}
				local hashPos = {}

				for idx, data in pairs(battle) do
					if self.isTeams and type(data) == "table" then
						for pos, data2 in pairs(data) do
							local key = self:getBattleKey(data2)

							if key then
								hash[key] = idx
								hashPos[key] = pos
							end
						end
					else
						local key = self:getBattleKey(data)

						if key then
							local battleIdx, battlePos = self:getBattle(idx)

							hash[key] = battleIdx
							hashPos[key] = battlePos
						end
					end
				end

				for idx, data in pairs(aidCards) do
					if self.isTeams and type(data) == "table" then
						for pos, data2 in pairs(data) do
							local key = self:getBattleKey(data2)

							if key then
								hash[key] = idx
								hashPos[key] = 6 + pos
							end
						end
					else
						local key = self:getBattleKey(data)

						if key then
							local battleIdx, battlePos = self:getBattleAid(idx)

							hash[key] = battleIdx
							hashPos[key] = battlePos
						end
					end
				end

				for _, v in self.allCardDatas:pairs() do
					local data = v:read()
					local battle = hash[self:getKey(data)] or 0

					if data.battle ~= battle then
						v:proxy().battle = battle
					end

					local battlePos = hashPos[self:getKey(data)]

					if data.battlePos ~= battlePos then
						v:proxy().battlePos = battlePos
					end
				end

				dataEasy.tryCallFunc(self.cardList, "filterSortItems", true)
			end
		end, 0)
	end)
end

function EmbattleCardList:getBattleKey(data)
	if type(data) == "table" then
		return data.dbid
	end

	return data
end

function EmbattleCardList:initItem(list, node, k, v, params)
	params = params or {}

	local grayState = v.battle > 0 and 1 or 0

	if params.grayState then
		grayState = params.grayState
	end

	local mergeInfo = dataEasy.getCardMergeInfo()

	if v.inMeteor or mergeInfo.mergeAB[v.dbid] or mergeInfo.relieveC[v.dbid] then
		grayState = 1
	end

	node:setName("item" .. list:getIdx(k))
	bind.extend(list, node, {
		class = "card_icon",
		props = {
			unitId = v.unit_id,
			advance = v.advance,
			rarity = v.rarity,
			dbid = v.dbid,
			star = v.star,
			grayState = grayState,
			levelProps = {
				data = v.level
			},
			onNode = function(panel)
				panel:xy(-4, -4)
			end
		}
	})

	local textNote = node:get("textNote")

	textNote:visible(v.battle >= 1):text(gLanguageCsv.inTheTeam)
	uiEasy.addTextEffect1(textNote)

	if self.isTeams then
		if v.battle > 0 then
			textNote:show()
			textNote:text(gLanguageCsv.team .. gLanguageCsv["symbolNumber" .. v.battle])
		end

		if v.battlePos and v.battlePos > 6 then
			text.deleteEffect(textNote, "all")
			text.addEffect(textNote, {
				color = cc.c4b(155, 242, 62, 255),
				outline = {
					size = 3,
					color = cc.c4b(5, 115, 39, 255)
				}
			})
		end
	elseif v.battle == 2 then
		textNote:text(gLanguageCsv.inAiding):show()
		text.deleteEffect(textNote, "all")
		text.addEffect(textNote, {
			color = cc.c4b(155, 242, 62, 255),
			outline = {
				size = 3,
				color = cc.c4b(5, 115, 39, 255)
			}
		})
	end

	if v.inMeteor then
		textNote:text(gLanguageCsv.inMeteorites)
		textNote:show()
	elseif mergeInfo.mergeAB[v.dbid] then
		textNote:text(gLanguageCsv.inMerge)
		textNote:show()
	elseif mergeInfo.relieveC[v.dbid] then
		textNote:text(gLanguageCsv.inRelieve)
		textNote:show()
	end

	node:onTouch(functools.partial(list.clickCell, v))
end

function EmbattleCardList:getlimtData(dbid, isCheck)
	if isCheck and self.ignoreFixCards then
		return dbid
	end

	local card = gGameModel.cards:find(dbid)

	if card then
		local data = self.allCardDatas:atproxy(dbid)
		local battle = data and data.battle or 0
		local battlePos = data and data.battlePos
		local ret = self.limtFunc({
			dbid = dbid,
			inBattle = battle
		})

		if ret then
			ret.battlePos = battlePos
		end

		return ret
	end
end

function EmbattleCardList:getClientBattleCards()
	local battleCards = {}
	local orignBattleCards = self.battleCardsData:read()
	local multiCards = false

	for k, data in pairs(orignBattleCards) do
		if self.isTeams and type(data) == "table" then
			multiCards = true
			battleCards[k] = {}

			for kk, data2 in pairs(data) do
				local key = self:getBattleKey(data2)

				if self:getlimtData(key, true) then
					battleCards[k][kk] = data2
				end
			end
		else
			local key = self:getBattleKey(data)

			if self:getlimtData(key, true) then
				battleCards[k] = data
			end
		end
	end

	local originAidCards = self.originAidCards:read() or {}
	local aidCards = {}

	for k, data in pairs(originAidCards) do
		if self.isTeams and type(data) == "table" then
			aidCards[k] = {}

			for kk, data2 in pairs(data) do
				local key = self:getBattleKey(data2)

				if self:getlimtData(key, true) then
					aidCards[k][kk] = data2
				end
			end
		else
			local key = self:getBattleKey(data)

			if self:getlimtData(key, true) then
				aidCards[k] = data
			end
		end
	end

	if not self.ignoreFixCards then
		if multiCards then
			battleCards = dataEasy.fixEmattleMultiCards(battleCards)
			aidCards = dataEasy.fixEmattleMultiCards(aidCards)
		else
			battleCards = dataEasy.fixEmattleCards(battleCards)
			aidCards = dataEasy.fixEmattleCards(aidCards)
		end
	end

	return battleCards, aidCards
end

function EmbattleCardList:initAllCards()
	idlereasy.any({
		self.battleCardsData,
		self.cards,
		self.originAidCards
	}, function(_, orignBattleCards, cards, originAidCards)
		local battleCards = orignBattleCards
		local aidCards = originAidCards

		if self.base.from ~= game.EMBATTLE_FROM_TABLE.input then
			battleCards, aidCards = self:getClientBattleCards()
		end

		local all = {}
		local ok

		for k, dbid in ipairs(cards) do
			ok = k == #cards

			local card = gGameModel.cards:find(dbid)
			local cardDatas = card:multigetIdler("card_id", "skin_id", "fighting_point", "level", "star", "advance", "created_time")

			idlereasy.any(cardDatas, function(_, card_id, skin_id, fighting_point, level, star, advance, created_time)
				all[dbid] = self:getlimtData(dbid)

				if ok then
					dataEasy.tryCallFunc(self.cardList, "updatePreloadCenterIndex")
					self.allCardDatas:update(all)
					self.clientBattleCards:set(battleCards, true)
					self.aidCards:set(aidCards, true)
				end
			end):anonyOnly(self, k)
		end
	end)
end

function EmbattleCardList:initAllCardsSimple()
	idlereasy.any({
		self.battleCardsData,
		self.cards,
		self.originAidCards
	}, function(_, orignBattleCards, cards, originAidCards)
		local all = {}

		for k, dbid in ipairs(cards) do
			all[dbid] = self:getlimtData(dbid)
		end

		dataEasy.tryCallFunc(self.cardList, "updatePreloadCenterIndex")
		self.allCardDatas:update(all)

		local battleCards, aidCards = self:getClientBattleCards()

		self.clientBattleCards:set(battleCards, true)
		self.aidCards:set(aidCards, true)
	end)
end

function EmbattleCardList:getKey(data)
	if not data then
		return nil
	end

	return data.dbid
end

function EmbattleCardList:adaptNode(bAdaptUi)
	if not bAdaptUi then
		return
	end

	adapt.centerWithScreen("left", "right", nil, {
		{
			self.cardList,
			"width"
		},
		{
			self.cardList,
			"pos",
			"left"
		},
		{
			self.btnPanel,
			"pos",
			"left"
		}
	})
end

function EmbattleCardList:initFilterBtn()
	self.filterCondition = idlertable.new()
	self.tabOrder = idler.new(true)
	self.seletSortKey = idler.new(1)

	idlereasy.any({
		self.filterCondition,
		self.seletSortKey,
		self.tabOrder
	}, function()
		dataEasy.tryCallFunc(self.cardList, "filterSortItems", false)
	end)

	local needAid = true

	if self.base.aidNum == 0 then
		needAid = false
	end

	local pos = self.btnPanel:parent():convertToWorldSpace(self.btnPanel:box())

	pos = self:convertToNodeSpace(pos)

	local btnPos = gGameUI:getConvertPos(self.btnPanel, self:getResourceNode())

	self.bagFilter = gGameUI:createView("city.card.bag_filter", self.btnPanel):init({
		cb = self:createHandler("onBattleFilter"),
		others = {
			panelOrder = true,
			width = 190,
			height = 122,
			needAid = false,
			x = btnPos.x + 95,
			y = btnPos.y + 61
		}
	}):z(19):xy(-pos.x, -pos.y)

	self.btnPanel:z(5)
end

function EmbattleCardList:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.sortDatas = idlertable.new(arraytools.map(CONDITIONS, function(i, v)
		return v.name
	end))
	self.isSelectAid = idler.new(false)

	local originalPos = self.aidBtn:get("btnImg"):x()

	self.aidBtn:y(self.aidBtn:y() - 40)
	idlereasy.when(self.isSelectAid, function(_, isSelectAid)
		local img = isSelectAid and "city/setting/btn_on.png" or "city/setting/btn_off.png"
		local btnImgPosX = isSelectAid and originalPos + 70 or originalPos

		self.aidBtn:get("btnBg"):texture(img)
		self.aidBtn:get("btnImg"):x(btnImgPosX)
	end)
end

function EmbattleCardList:onFilterCards(list)
	local filterCondition = self.filterCondition:read()
	local condition = {}

	if not itertools.isempty(filterCondition) then
		condition = {
			{
				"rarity",
				filterCondition.rarity < ui.RARITY_LAST_VAL and filterCondition.rarity or nil
			},
			{
				"attr2",
				filterCondition.attr2 < ui.ATTR_MAX and filterCondition.attr2 or nil
			},
			{
				"attr1",
				filterCondition.attr1 < ui.ATTR_MAX and filterCondition.attr1 or nil
			},
			{
				"atkType",
				filterCondition.atkType
			},
			{
				"isHasAid",
				filterCondition.isSelectAid
			}
		}
	end

	local isSelectAid = filterCondition and filterCondition.isSelectAid or false

	local function isOK(data, key, val)
		if data[key] == nil and key ~= "isHasAid" and (key ~= "attr2" or data.attr1 == val) then
			return true
		end

		if key == "atkType" then
			for k, v in ipairs(data.atkType) do
				if val[v] then
					return true
				end
			end

			return false
		end

		if data[key] == val then
			return true
		end

		if key == "isHasAid" then
			if isSelectAid == true then
				local cfg = csv.cards[data.card_id]
				local aidID = cfg.aidID or 0
				local activeAid = gGameModel.role:read("active_aid")
				local isActive = activeAid ~= nil and activeAid[aidID] ~= nil and activeAid[aidID].level > 0

				return isActive
			end

			return true
		end

		return false
	end

	return function(dbid, card)
		for i = 1, #condition do
			local cond = condition[i]

			if cond[2] and not isOK(card, cond[1], cond[2]) then
				return false
			end
		end

		return true, dbid
	end
end

function EmbattleCardList:onSortCards(list)
	local seletSortKey = self.seletSortKey:read()
	local attrName = CONDITIONS[seletSortKey].attr
	local tabOrder = self.tabOrder:read()

	return function(a, b)
		if a.battle ~= b.battle then
			if a.battle ~= 0 and b.battle ~= 0 then
				return a.battle < b.battle
			end

			return a.battle > b.battle
		end

		local isAidA = a.battlePos and a.battlePos > 6
		local isAidB = b.battlePos and b.battlePos > 6

		if isAidA ~= isAidB then
			return isAidB
		end

		local attrA = a[attrName]
		local attrB = b[attrName]

		if attrA ~= attrB then
			if tabOrder then
				return attrB < attrA
			else
				return attrA < attrB
			end
		end

		return a.card_id < b.card_id
	end
end

function EmbattleCardList:onCardItemTouch(list, v, event)
	if v.battle <= 0 then
		if v.inMeteor then
			gGameUI:showTip(gLanguageCsv.cardInMeteorites)

			return
		end

		local mergeInfo = dataEasy.getCardMergeInfo()

		if mergeInfo.mergeAB[v.dbid] then
			gGameUI:showTip(gLanguageCsv.inMerge)

			return
		end

		if mergeInfo.relieveC[v.dbid] then
			gGameUI:showTip(gLanguageCsv.inRelieve)

			return
		end
	end

	if event.name == "began" then
		self.moved = false
		self.touchBeganPos = event

		self.deleteMovingItem()
	elseif event.name == "moved" then
		local deltaX = math.abs(event.x - self.touchBeganPos.x)
		local deltaY = math.abs(event.y - self.touchBeganPos.y)

		if not self.moved and not self.isMovePanelExist() and (deltaX >= ui.TOUCH_MOVED_THRESHOLD or deltaY >= ui.TOUCH_MOVED_THRESHOLD) then
			if deltaY > deltaX * 0.7 then
				self.createMovePanel(v)
			end

			self.moved = true
		end

		self.cardList:setTouchEnabled(not self.isMovePanelExist())
		self.moveMovePanel(event)
	elseif event.name == "ended" or event.name == "cancelled" then
		if self.isMovePanelExist() == false and self.moved == false then
			self.onCardClick(v, true)

			return
		end

		self.moveEndMovePanel(v)
	end
end

function EmbattleCardList:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.tabOrder:modify(function(val)
			return true, not val
		end)
	else
		self.tabOrder:set(true)
	end

	self.seletSortKey:set(k)
end

function EmbattleCardList:onBattleFilter(attr1, attr2, rarity, atkType)
	self.filterCondition:set({
		attr1 = attr1,
		attr2 = attr2,
		rarity = rarity,
		atkType = atkType,
		isSelectAid = self.isSelectAid:read()
	}, true)
end

function EmbattleCardList:onAidClick()
	self.isSelectAid:set(not self.isSelectAid:read())
	self.filterCondition:modify(function(tb)
		tb.isSelectAid = self.isSelectAid:read()

		return true, tb
	end, true)
end

function EmbattleCardList:setTeams(isTeams)
	self.isTeams = isTeams
end

return EmbattleCardList
