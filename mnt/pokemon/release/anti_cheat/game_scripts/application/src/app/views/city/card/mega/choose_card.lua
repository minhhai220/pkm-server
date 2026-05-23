-- chunkname: @src.app.views.city.card.mega.choose_card

local ViewBase = cc.load("mvc").ViewBase
local MegaChooseCardView = class("MegaChooseCardView", Dialog)

MegaChooseCardView.RESOURCE_FILENAME = "card_mega_choose_card.json"
MegaChooseCardView.RESOURCE_BINDING = {
	["tipPanel.textTip"] = "textTip",
	innerList = "innerList",
	item = "item",
	["down.textNote"] = "textNote",
	["down.textNum"] = "textNum",
	["title.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	list = {
		varname = "list",
		binds = {
			class = "tableview",
			event = "extend",
			props = {
				asyncPreload = 12,
				columnSize = 3,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onCell = function(list, node, k, v)
					bind.extend(list, node:get("head"), {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							dbid = v.dbid,
							star = v.star,
							rarity = v.rarity,
							levelProps = {
								data = v.level
							}
						}
					})

					if ui.CARD_USING_TXTS[v.battleType] then
						node:get("txt"):text(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]]):show()
						node:get("imgTick"):visible(false)
						node:get("imgMask"):visible(true)
					else
						node:get("txt"):hide()
						node:get("imgTick"):visible(v.isSel)
						node:get("imgMask"):visible(v.isSel)
					end

					node:get("textName"):text(csv.cards[v.id].name)
					node:get("textFightPoint"):text(v.fight)
					uiEasy.addTextEffect1(node:get("txt"))
					node:get("imgLock"):visible(v.lock)
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, list:getIdx(k), v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onCellClick")
			}
		}
	},
	down = {
		binds = {
			event = "visible",
			idler = bindHelper.self("isShowDown")
		}
	},
	["down.btnOk"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSure")
			}
		}
	},
	tipPanel = {
		binds = {
			event = "visible",
			idler = bindHelper.self("showTip")
		}
	}
}

function MegaChooseCardView:onCreate(data, cb)
	self.data = data
	self.cb = cb
	self.cardDatas = idlers.new({})
	self.showTip = idler.new(false)

	local needNum = 1
	local limitStar = true

	if data.key == "main" then
		limitStar = false

		if data.chooseIdx then
			local cfg = csv.card_mega[data.megaIndex]

			needNum = cfg.costCards.num or 1
		end
	end

	self.needNum = idler.new(needNum)
	self.chooseNum = 0

	idlereasy.when(gGameModel.role:getIdler("cards"), function(_, cards)
		local cardMegaData = {}
		local hash = dataEasy.inUsingCardsHash()
		local mergeInfo = dataEasy.getCardMergeInfo()

		for k, dbid in ipairs(cards) do
			if not mergeInfo.all[dbid] then
				local card = gGameModel.cards:find(dbid)
				local cardDatas = card:read("card_id", "skin_id", "level", "star", "advance", "name", "fighting_point", "locked")
				local cardCsv = csv.cards[cardDatas.card_id]
				local unitID = cardCsv.unitID
				local unitCsv = csv.unit[unitID]
				local skinUnitID = dataEasy.getUnitId(cardDatas.card_id, cardDatas.skin_id)
				local rarity, cardMarkID = unitCsv.rarity, cardCsv.cardMarkID
				local isOK = false
				local isSel = false
				local battleType = hash[dbid]
				local locked = cardDatas.locked
				local cardType = 0

				if data.key == "main" then
					isOK, isSel, battleType, locked = self:mainCard(dbid, battleType)
				else
					local cfg = csv.card_mega_convert[data.csvId]

					if cardCsv.cardType ~= 2 then
						for i = 1, math.huge do
							local data = cfg["needCards" .. i]

							if not data or csvSize(data) <= 0 then
								break
							end

							if rarity == data[1] and (data[2] == -1 or unitCsv.natureType == data[2] or unitCsv.natureType2 == data[2]) then
								isOK = true

								break
							end
						end
					else
						cardType = 1
					end

					if dbid == data.selectId then
						isSel = true
					end

					for _, cardId in csvPairs(cfg.needSpecialCards) do
						if cardId == cardDatas.card_id then
							isOK = true

							break
						end
					end
				end

				if limitStar and (cardCsv.megaIndex > 0 or cardDatas.star > cardCsv.star) then
					isOK = false
				end

				if data.key == "key" and itertools.include(csv.card_mega_convert[data.csvId].roriCards, cardDatas.card_id) then
					isOK = false
				end

				if isOK then
					table.insert(cardMegaData, {
						dbid = dbid,
						id = cardDatas.card_id,
						unitId = skinUnitID,
						fight = cardDatas.fighting_point,
						name = cardDatas.name,
						level = cardDatas.level,
						star = cardDatas.star,
						advance = cardDatas.advance,
						rarity = rarity,
						isSel = isSel,
						battleType = battleType,
						lock = locked,
						mega = cardCsv.megaIndex > 0,
						cardType = cardType
					})
				end
			end
		end

		table.sort(cardMegaData, function(a, b)
			local hasTxtA = ui.CARD_USING_TXTS[a.battleType] ~= nil
			local hasTxtB = ui.CARD_USING_TXTS[b.battleType] ~= nil

			if hasTxtA ~= hasTxtB then
				return hasTxtB
			end

			if a.cardType ~= b.cardType then
				return a.cardType > b.cardType
			end

			if a.id ~= b.id then
				return a.id < b.id
			end

			return a.fight < b.fight
		end)
		self.cardDatas:update(cardMegaData)
		self.showTip:set(#cardMegaData == 0)
		self.needNum:notify()
	end)
	idlereasy.when(self.needNum, function(_, num)
		local chooseNum = 0

		for _, v in self.cardDatas:ipairs() do
			if v:read().isSel then
				chooseNum = chooseNum + 1
			end
		end

		self.chooseNum = chooseNum

		self.textNum:text(chooseNum .. "/" .. num)
	end)
	self.textTip:text(gLanguageCsv.spriteNotNum)
	Dialog.onCreate(self, {
		clickClose = true
	})
end

function MegaChooseCardView:onChangeData(idx, v)
	self.cardDatas:atproxy(idx).lock = gGameModel.cards:find(v.dbid):read("locked")
end

function MegaChooseCardView:mainCard(dbid, battleType)
	local card = gGameModel.cards:find(dbid)
	local cardDatas = card:read("card_id", "skin_id", "level", "star", "advance", "name", "fighting_point", "locked")
	local cardCsv = csv.cards[cardDatas.card_id]
	local unitID = cardCsv.unitID
	local unitCsv = csv.unit[unitID]
	local rarity, cardMarkID = unitCsv.rarity, cardCsv.cardMarkID
	local isOK = false
	local isSel = false
	local locked = cardDatas.locked
	local cfg = csv.card_mega[self.data.megaIndex]

	if self.data.chooseIdx then
		if cardMarkID == cfg.costCards.markID and cardDatas.star >= cfg.costCards.star or rarity == cfg.costCards.rarity and cardDatas.star >= cfg.costCards.star then
			isOK = true
		end

		if self.data.subCardData[dbid] then
			isSel = true
		end

		if dbid == self.data.cardDbid then
			isOK = false
		end
	else
		if not dataEasy.getIsStarAidState(dbid) then
			battleType = nil
		end

		locked = false

		local cardIds = self.data.cardId

		if type(self.data.cardId) ~= "table" then
			cardIds = {
				cardIds
			}
		end

		local needStar = self.data.idx and cfg.card[self.data.idx][2] or cfg.card[2]

		if itertools.include(cardIds, cardDatas.card_id) and needStar <= cardDatas.star then
			isOK = true
		end

		if dbid == self.data.cardDbid then
			isSel = true
		end

		if self.data.subCardData[dbid] then
			isOK = false
		end
	end

	return isOK, isSel, battleType, locked
end

function MegaChooseCardView:onCellClick(list, t, v)
	if v.lock then
		gGameUI:showDialog({
			clearFast = true,
			btnType = 2,
			cb = function()
				gGameUI:stackUI("city.card.strengthen", nil, {
					full = true
				}, 1, v.dbid, self:createHandler("onChangeData", t.k, v))
			end,
			content = string.format(gLanguageCsv.gotoUnLock, gLanguageCsv.change)
		})

		return true
	end

	if ui.CARD_USING_TXTS[v.battleType] then
		gGameUI:showTip(gLanguageCsv[ui.CARD_USING_TXTS[v.battleType]])

		return
	end

	local isSel = self.cardDatas:atproxy(t.k).isSel

	local function cb()
		if not isSel and self.chooseNum >= self.needNum:read() then
			for _, v in self.cardDatas:pairs() do
				if v:proxy().isSel then
					v:proxy().isSel = false

					break
				end
			end
		end

		self.cardDatas:atproxy(t.k).isSel = not isSel

		self.needNum:notify()
	end

	if not isSel and (self.data.key ~= "main" or self.data.chooseIdx) then
		local str
		local cardCfg = csv.cards[v.id]

		if v.mega then
			str = gLanguageCsv.megaOk
		elseif v.star > cardCfg.star then
			str = gLanguageCsv.selectCardMaterialsMega
		elseif v.level > 1 or v.advance > 1 then
			str = gLanguageCsv.selectCardMaterialsMega
		end

		if str then
			gGameUI:showDialog({
				btnType = 2,
				fontSize = 50,
				isRich = true,
				title = gLanguageCsv.spaceTips,
				content = str,
				cb = cb
			})

			return
		end
	end

	cb()
end

function MegaChooseCardView:onSure()
	local t = {}

	for _, v in self.cardDatas:ipairs() do
		if v:read().isSel then
			t[v:read().dbid] = true
		end
	end

	if self.data.key == "main" then
		if self.data.chooseIdx then
			self.data.subCardData = t
		else
			self.data.cardDbid = next(t)
		end
	else
		self.data.selectId = next(t)
	end

	self:addCallbackOnExit(self.cb)
	ViewBase.onClose(self)
end

return MegaChooseCardView
