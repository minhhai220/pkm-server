-- chunkname: @src.app.views.city.adventure.clone_battle.choose

local ViewBase = cc.load("mvc").ViewBase
local CloneBattleChooseView = class("CloneBattleChooseView", Dialog)

CloneBattleChooseView.RESOURCE_FILENAME = "clone_battle_sprite.json"
CloneBattleChooseView.RESOURCE_BINDING = {
	item = "item",
	subList = "subList",
	list = {
		varname = "cardList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 3,
				asyncPreload = 12,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				dataOrderCmpGen = bindHelper.self("onSortCardList", true),
				itemAction = {
					isAction = true
				},
				onCell = function(list, node, k, v)
					local children = node:multiget("cardItem", "name", "txtValueTitle", "txtValue", "mask")

					uiEasy.setIconName("card", v.id, {
						space = true,
						node = children.name,
						name = v.name,
						advance = v.advance
					})
					adapt.setTextAdaptWithSize(children.name, {
						vertical = "center",
						horizontal = "left",
						maxLine = 2,
						size = cc.size(300, children.name:height() * 2)
					})
					children.txtValue:text(v.fightPoint)
					adapt.oneLinePos(children.txtValueTitle, children.txtValue, cc.p(15, 0), "left")
					bind.extend(list, children.cardItem, {
						class = "card_icon",
						props = {
							unitId = v.unitId,
							advance = v.advance,
							star = v.star,
							rarity = v.rarity,
							dbid = v.dbid,
							levelProps = {
								data = v.level
							},
							params = {
								starInterval = 12.5,
								starScale = 0.85
							}
						}
					})

					local mergeInfo = dataEasy.getCardMergeInfo()

					children.mask:show()

					local textNote = children.mask:get("textNote"):show()

					uiEasy.addTextEffect1(children.mask:get("textNote"))

					if v.inMeteor then
						textNote:text(gLanguageCsv.inMeteorites)
					elseif mergeInfo.mergeAB[v.dbid] then
						textNote:text(gLanguageCsv.inMerge)
					elseif mergeInfo.relieveC[v.dbid] then
						textNote:text(gLanguageCsv.inRelieve)
					elseif not v.isCur then
						children.mask:hide()
						bind.touch(list, node, {
							methods = {
								ended = functools.partial(list.itemClick, node, k, v)
							}
						})
					end
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemChoose")
			}
		}
	},
	btnClose = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	}
}

function CloneBattleChooseView:onCreate(curId)
	self.curSprId = curId

	self:initModel()

	self.cardDatas = idlers.new()

	local meteorCardsHash = dataEasy.getInMeteorCardsHash()
	local mergeInfo = dataEasy.getCardMergeInfo()

	idlereasy.any({
		self.cards
	}, function(obj, cards)
		local tmpCardDatas = {}

		for k, dbid in ipairs(cards) do
			local cardData = gGameModel.cards:find(dbid):read("card_id", "skin_id", "level", "star", "advance", "name", "fighting_point")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = csv.unit[cardCsv.unitID]
			local unitId = dataEasy.getUnitId(cardData.card_id, cardData.skin_id)

			tmpCardDatas[dbid] = {
				id = cardData.card_id,
				unitId = unitId,
				name = cardCsv.name,
				rarity = unitCsv.rarity,
				level = cardData.level,
				star = cardData.star,
				dbid = dbid,
				advance = cardData.advance,
				fightPoint = cardData.fighting_point,
				isCur = self.curSprId == dbid,
				inMeteor = meteorCardsHash[dbid]
			}
		end

		self.cardDatas:update(tmpCardDatas)
	end)
	Dialog.onCreate(self, {
		clickClose = true
	})
end

function CloneBattleChooseView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
end

function CloneBattleChooseView:onItemChoose(list, node, k, v)
	gGameApp:requestServer("/game/clone/battle/deploy", function(tb)
		self:onClose()
	end, v.dbid)
end

function CloneBattleChooseView:onSortCardList(list)
	return function(a, b)
		if a.isCur then
			return true
		end

		if b.isCur then
			return false
		end

		return a.fightPoint > b.fightPoint
	end
end

return CloneBattleChooseView
