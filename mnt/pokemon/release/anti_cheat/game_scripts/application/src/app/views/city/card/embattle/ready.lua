-- chunkname: @src.app.views.city.card.embattle.ready

local CardEmbattleView = require("app.views.city.card.embattle.base")
local ViewBase = cc.load("mvc").ViewBase
local CardEmbattleReady = class("CardEmbattleReady", Dialog)

CardEmbattleReady.RESOURCE_FILENAME = "card_embattle_ready.json"
CardEmbattleReady.RESOURCE_BINDING = {
	item = "item",
	btnClose = {
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
			class = "listview",
			event = "extend",
			props = {
				asyncPreload = 4,
				data = bindHelper.self("battleDatas"),
				item = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				aidNum = bindHelper.self("aidNum"),
				aidNumMax = bindHelper.self("aidNumMax"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("list", "node", "name", "btnGHimg", "power", "powerText", "btnChangeName", "btnSure", "btnFormation", "btnClear", "aidItem", "aidList")

					childs.name:text(v.name)

					local weatherCfg = csv.weather_system.weather[v.extra.weather]

					if weatherCfg then
						node:get("btnWeather"):show()
						node:get("btnWeather.icon"):texture(weatherCfg.iconRes)
					else
						node:get("btnWeather"):hide()
					end

					bind.extend(list, childs.btnGHimg, {
						class = "buff_arms",
						props = {
							noListener = true,
							battleCards = v.cards,
							arms = v.extra.arms or {},
							sceneType = v.sceneType,
							onNode = function(node)
								node:scale(0.8)
							end
						}
					})
					childs.powerText:text(v.getFightSumNum)
					adapt.oneLinePos(childs.power, childs.powerText, cc.p(0, 0))
					childs.btnClear:setTouchEnabled(v.state)
					childs.btnSure:setTouchEnabled(v.state)
					text.deleteAllEffect(childs.btnSure:get("textNote"))

					if v.state then
						cache.setShader(childs.btnClear, false, "normal")
						cache.setShader(childs.btnSure, false, "normal")
						text.addEffect(childs.btnSure:get("textNote"), {
							color = ui.COLORS.NORMAL.WHITE,
							glow = {
								color = ui.COLORS.GLOW.WHITE
							}
						})
					else
						cache.setShader(childs.btnClear, false, "hsl_gray")
						cache.setShader(childs.btnSure, false, "hsl_gray")
						text.addEffect(childs.btnSure:get("textNote"), {
							color = ui.COLORS.DISABLED.WHITE
						})
					end

					childs.list:removeAllItems()
					childs.list:setScrollBarEnabled(false)

					for i = 1, 6 do
						local icon = childs.node:clone()

						icon:visible(true)
						icon:setTouchEnabled(true)
						bind.touch(list, icon, {
							methods = {
								ended = functools.partial(list.formationClickCell, k, v)
							}
						})

						if v.cardsData[i] then
							local unitId = dataEasy.getUnitId(v.cardsData[i]:read("card_id"), v.cardsData[i]:read("skin_id"))

							bind.extend(list, icon, {
								class = "card_icon",
								props = {
									unitId = unitId,
									advance = v.cardsData[i]:read("advance"),
									rarity = v.cardsData[i]:read("rarity"),
									star = v.cardsData[i]:read("star"),
									dbid = v.cardsData[i]:read("id"),
									levelProps = {
										data = v.cardsData[i]:read("level")
									}
								}
							})
							icon:get("bg"):visible(false)
						end

						childs.list:pushBackCustomItem(icon)
					end

					if dataEasy.isUnlock(gUnlockCsv.aid) then
						for i = 1, list.aidNumMax do
							local icon = childs.aidItem:clone()

							icon:visible(true)
							icon:setTouchEnabled(true)
							bind.touch(list, icon, {
								methods = {
									ended = functools.partial(list.formationClickCell, k, v)
								}
							})

							if v.aidData[i] then
								local card = gGameModel.cards:find(v.aidData[i])
								local unitId = dataEasy.getUnitId(card:read("card_id"), card:read("skin_id"))
								local unitCfg = csv.unit[unitId]

								icon:get("add"):texture(unitCfg.iconSimple):scale(2):opacity(255)
							elseif i <= list.aidNum then
								icon:get("add"):texture("city/friend/btn_add.png"):scale(1)
							else
								icon:get("add"):texture("common/btn/btn_zz_lock.png"):scale(1)
							end

							childs.aidList:pushBackCustomItem(icon)
						end
					end

					bind.touch(list, childs.btnClear, {
						methods = {
							ended = functools.partial(list.clearClickCell, k, v)
						}
					})
					bind.touch(list, childs.btnFormation, {
						methods = {
							ended = functools.partial(list.formationClickCell, k, v)
						}
					})
					bind.touch(list, childs.btnSure, {
						methods = {
							ended = functools.partial(list.sureClickCell, k, v)
						}
					})
					bind.touch(list, childs.btnChangeName, {
						methods = {
							ended = functools.partial(list.changeNameClickCell, k, v)
						}
					})
				end
			},
			handlers = {
				sureClickCell = bindHelper.self("onSureClick"),
				clearClickCell = bindHelper.self("onClearClick"),
				formationClickCell = bindHelper.self("onFormationClick"),
				changeNameClickCell = bindHelper.self("onChangeNameClick")
			}
		}
	}
}

function CardEmbattleReady:onCreate(params)
	self.params = params
	self.aidNum = params.aidNum or 0
	self.aidUnlockLevel = params.aidUnlockLevel or {}
	self.aidNumMax = csvSize(self.aidUnlockLevel)

	self:initModel()
	self:updatePanel()

	self.battleDatas = idlers.newWithMap({})

	idlereasy.when(self.ready_cards, function(_, ready_cards)
		local datas = {}

		for i = 1, gCommonConfigCsv.embattleReadyMax do
			local cardsData = {}
			local empty = true
			local name = gLanguageCsv["team" .. i]
			local getFightSumNum = 0
			local cards = ready_cards[i] and ready_cards[i].cards or {}
			local aidCards = ready_cards[i] and ready_cards[i].aid_cards or {}

			cards = dataEasy.fixInMeteorCards(cards)
			aidCards = dataEasy.fixAidCards(aidCards, self.aidNum)

			if ready_cards[i] then
				for idx, id in pairs(cards) do
					empty = false
					cardsData[idx] = self:getCardAttr(id)
				end

				getFightSumNum = self:getFightSumNum(cards, aidCards)

				if ready_cards[i].name and ready_cards[i].name ~= "" then
					name = ready_cards[i].name
				end
			end

			table.insert(datas, {
				cards = cards,
				cardsData = cardsData,
				name = name,
				state = not empty,
				getFightSumNum = getFightSumNum,
				sceneType = params.sceneType,
				extra = ready_cards[i] and ready_cards[i].extra or {},
				aidData = aidCards
			})
		end

		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndex")
		self.battleDatas:update(datas)
	end)
	Dialog.onCreate(self)
end

function CardEmbattleReady:initModel()
	self.ready_cards = gGameModel.role:getIdler("ready_cards")
end

function CardEmbattleReady:updatePanel()
	local item = self.item

	if self.aidNum > 0 then
		item:height(360)
		item:get("bg"):height(360)
		item:get("bg.img"):scaleY(2.55):y(180)
		item:get("name"):y(item:get("name"):y() + 40)
		item:get("power"):y(item:get("power"):y() - 40)
		item:get("powerText"):y(item:get("powerText"):y() - 40)
		item:get("btnGHimg"):scale(1):x(item:get("btnGHimg"):x() + 20)
		item:get("btnWeather"):scale(1.5):x(item:get("btnWeather"):x() + 60)
		item:get("text"):show()
		item:get("text1"):show()
		item:get("aidList"):setItemsMargin(34):show()
		item:get("btnClear"):xy(item:get("btnClear"):x() + 10, item:get("btnClear"):y() + 10)
		item:get("btnFormation"):xy(item:get("btnClear"):x() + 200, item:get("btnClear"):y())
		item:get("btnSure"):xy(item:get("btnSure"):x() - 40, item:get("btnSure"):y() - 80)
		item:get("list"):xy(item:get("list"):x() + 120, item:get("list"):y() + 70)
		item:get("node"):scale(0.89)
		item:get("btnChangeName"):y(item:get("btnChangeName"):y() + 45)
	end
end

function CardEmbattleReady:getFightSumNum(battle, aidCards)
	return CardEmbattleView.getFightSumNum(self, battle, aidCards)
end

function CardEmbattleReady:getCardAttr(cardId, attrString)
	if attrString then
		return gGameModel.cards:find(cardId):read(attrString)
	else
		return gGameModel.cards:find(cardId)
	end
end

function CardEmbattleReady:onSureClick(list, k, v)
	local function closeView()
		gGameUI:showTip(gLanguageCsv.teamSaveSuccess)
		ViewBase.onClose(self)
	end

	local cards = table.deepcopy(v.cards, true)
	local extra = table.deepcopy(v.extra, true)
	local aid = table.deepcopy(v.aidData, true)

	if self.params.from == game.EMBATTLE_FROM_TABLE.onlineFight then
		local startDate = gGameModel.cross_online_fight:read("start_date")
		local day = math.floor((time.getTime() - time.getNumTimestamp(startDate, 5, 0, 0)) / 60 / 60 / 24) + 1
		local cfg = {}
		local hasBanCard = false
		local unlimitedBanCards = {}

		for k, v in csvPairs(csv.cross.online_fight.theme_open) do
			if v.day == day then
				cfg = v

				break
			end
		end

		if itertools.size(cfg.invalidMarkIDs or {}) ~= 0 or itertools.size(cfg.invalidMegaCardIDs or {}) ~= 0 then
			for idx, dbid in pairs(cards) do
				local card = gGameModel.cards:find(dbid)
				local cardID = card:read("card_id")

				if itertools.include(cfg.invalidMarkIDs, csv.cards[cardID].cardMarkID) or itertools.include(cfg.invalidMegaCardIDs, csv.cards[cardID].cardMarkID) then
					hasBanCard = true
					cards[idx] = nil
				end
			end
		end

		if hasBanCard then
			local function dialogCb()
				self.params.cb(cards, closeView, extra, aid)
			end

			if itertools.size(cards) == 0 then
				function dialogCb()
					gGameUI:showTip(gLanguageCsv.readTeamNoneCard)
				end
			end

			gGameUI:showDialog({
				btnType = 2,
				clearFast = true,
				cb = dialogCb,
				content = gLanguageCsv.readTeamHasBanCard
			})

			return
		end
	end

	self.params.cb(cards, closeView, extra, aid)
end

function CardEmbattleReady:onClearClick(list, k, v)
	gGameUI:showDialog({
		btnType = 2,
		content = gLanguageCsv.teamClear,
		cb = function()
			gGameApp:requestServer("/game/ready/card/deploy", function(tb)
				gGameUI:showTip(gLanguageCsv.positionSave)
			end, k, {}, nil, {})
		end
	})
end

function CardEmbattleReady:onFormationClick(list, k, v)
	gGameUI:stackUI("city.card.embattle.base", nil, {
		full = true
	}, {
		sceneType = self.params.sceneType,
		from = game.EMBATTLE_FROM_TABLE.ready,
		inputCards = idlertable.new(v.cards),
		readyIdx = k,
		inputExtra = v.extra,
		inputAidCards = idlertable.new(v.aidData),
		aidNum = self.aidNum,
		aidUnlockLevel = self.aidUnlockLevel
	})
end

function CardEmbattleReady:onChangeNameClick(list, k, v)
	gGameUI:stackUI("city.card.changename", nil, nil, {
		maxFontCount = 7,
		cost = 0,
		typ = "ready",
		name = v.name,
		titleTxt = gLanguageCsv.changeReadyName,
		requestParams = {
			k
		},
		cb = function(name)
			self.battleDatas:atproxy(k).name = name
		end
	})
end

return CardEmbattleReady
