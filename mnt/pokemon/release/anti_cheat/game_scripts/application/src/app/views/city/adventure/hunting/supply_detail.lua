-- chunkname: @src.app.views.city.adventure.hunting.supply_detail

local SUPPLY_TITLE = {
	gLanguageCsv.recover,
	[3] = gLanguageCsv.revive
}
local SUPPLY_TYPE = {
	all = 2,
	single = 1,
	resurrect = 3
}

local function getCards(supplyTarget)
	local cards = gGameModel.role:read("cards")

	if supplyTarget == 2 then
		local battleCardIDs = table.deepcopy(gGameModel.role:read("huodong_cards")[game.EMBATTLE_HOUDONG_ID.randomTower], true)

		cards = battleCardIDs or {}
	end

	return cards
end

local function reachCondition(condition, cardState, selectDbId)
	local card = gGameModel.cards:find(selectDbId)

	if card:read("level") < 10 then
		return false
	end

	if condition == SUPPLY_TYPE.single then
		return cardState and cardState[1] > 0 and cardState[1] < 1
	end

	if condition == SUPPLY_TYPE.resurrect then
		return cardState and cardState[1] <= 0
	end

	return true
end

local ViewBase = cc.load("mvc").ViewBase
local HuntingSupplyDetailView = class("HuntingSupplyDetailView", Dialog)

HuntingSupplyDetailView.RESOURCE_FILENAME = "hunting_supply_detail.json"
HuntingSupplyDetailView.RESOURCE_BINDING = {
	textNote = "textNote",
	item = "item",
	subList = "subList",
	["title.textTitle1"] = "textTitle1",
	textNum = "textNum",
	["title.textTitle2"] = "textTitle2",
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
			event = "extend",
			class = "tableview",
			props = {
				asyncPreload = 38,
				columnSize = 7,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onCell = function(list, node, k, v)
					local childs = node:multiget("cardPanel", "mask", "hpBar", "mpBar", "imgDie", "extraCondition2", "gainChance", "btnReward", "btnComplete")

					childs.imgDie:visible(v.hp <= 0)
					childs.hpBar:setPercent(v.hp * 100)

					local mpPercent = v.mp * 100

					if v.hp <= 0 then
						mpPercent = 0
					end

					childs.mpBar:setPercent(mpPercent)

					local size = node:size()

					bind.extend(list, childs.cardPanel, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							rarity = v.rarity,
							dbid = v.dbid,
							star = v.star,
							levelProps = {
								data = v.level
							},
							onNode = function(panel)
								return
							end
						}
					})
					childs.mask:visible(v.selectState)
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick, list:getIdx(k), v)
						}
					})
				end,
				onAfterBuild = function(list)
					list.afterBuild()
				end
			},
			handlers = {
				itemClick = bindHelper.self("onitemClick"),
				afterBuild = bindHelper.self("onAfterBuild")
			}
		}
	},
	btnSure = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnSure")
			}
		}
	}
}

function HuntingSupplyDetailView:onCreate(params)
	self.params = params

	self:initModel()
	self.textNote:text(string.format(gLanguageCsv.selectCardSupply, SUPPLY_TITLE[params.type]))

	self.cardDatas = idlers.new()

	local cardInfos = {}
	local cardState = self.cardStates
	local cards = getCards(params.type)

	for i, cardDbId in pairs(cards) do
		if reachCondition(params.type, cardState[cardDbId], cardDbId) then
			table.insert(cardInfos, self:getCardData(cardDbId))
		end
	end

	table.sort(cardInfos, function(a, b)
		return a.fight > b.fight
	end)
	self.cardDatas:update(cardInfos)

	self.selectIdx = idler.new(0)

	self.textNum:text("0/1")
	self.selectIdx:addListener(function(val, oldval)
		local cardDatas = self.cardDatas:atproxy(val)
		local oldCardDatas = self.cardDatas:atproxy(oldval)

		if oldCardDatas then
			oldCardDatas.selectState = false
		end

		if cardDatas then
			self.textNum:text("1/1")
			adapt.oneLinePos(self.textNote, self.textNum, cc.p(5, 0))

			cardDatas.selectState = true
		end
	end)
	adapt.oneLinePos(self.textNote, self.textNum, cc.p(5, 0))
	adapt.oneLinePos(self.textTitle1, self.textTitle2, cc.p(4, 0))
	Dialog.onCreate(self)
end

function HuntingSupplyDetailView:getCardData(cardDbId)
	local cardState = self.cardStates[cardDbId]
	local hp = 1
	local mp = 0

	if cardState then
		hp = cardState[1]
		mp = cardState[2]
	end

	local card = gGameModel.cards:find(cardDbId)
	local cardData = card:read("card_id", "skin_id", "name", "level", "star", "advance", "fighting_point")
	local cardCsv = csv.cards[cardData.card_id]
	local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)
	local unitCsv = csv.unit[unitId]

	return {
		selectState = false,
		id = cardData.card_id,
		unitId = unitId,
		rarity = unitCsv.rarity,
		level = cardData.level,
		star = cardData.star,
		advance = cardData.advance,
		dbid = cardDbId,
		fight = cardData.fighting_point,
		hp = hp,
		mp = mp
	}
end

function HuntingSupplyDetailView:initModel()
	self.routeInfo = gGameModel.hunting:read("hunting_route")
	self.cardStates = self.routeInfo[self.params.route].card_states
end

function HuntingSupplyDetailView:onitemClick(list, t, v)
	self.selectIdx:set(t.k)
end

function HuntingSupplyDetailView:onBtnSure()
	local cardData = self.cardDatas:atproxy(self.selectIdx:read())

	if not cardData then
		return
	end

	local showOver = {
		false
	}

	gGameApp:requestServerCustom("/game/hunting/supply"):params(self.params.route, self.params.node, self.params.csvId, cardData.dbid):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		self:addCallbackOnExit(self.params.cb)
		ViewBase.onClose(self)
	end)
end

return HuntingSupplyDetailView
