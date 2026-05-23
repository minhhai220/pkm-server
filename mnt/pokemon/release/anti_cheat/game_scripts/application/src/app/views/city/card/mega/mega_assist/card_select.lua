-- chunkname: @src.app.views.city.card.mega.mega_assist.card_select

local ViewBase = cc.load("mvc").ViewBase
local MegaAssistCardSelectView = class("MegaAssistCardSelectView", Dialog)

MegaAssistCardSelectView.RESOURCE_FILENAME = "mega_assist_card_select.json"
MegaAssistCardSelectView.RESOURCE_BINDING = {
	innerList = "innerList",
	item = "item",
	panel = "panel",
	tipPanel = "tipPanel",
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
				columnSize = 4,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("head", "textName", "imgMask", "imgTick", "txt")

					text.deleteEffect(childs.txt, {
						outLine = {
							color = cc.c3b(255, 84, 0)
						}
					})
					text.addEffect(childs.txt, {
						outLine = {
							color = cc.c3b(255, 84, 0)
						}
					})

					local cardCfg = csv.cards[v.cardID]
					local unitCfg = csv.unit[cardCfg.unitID]

					childs.textName:text(cardCfg.name)
					bind.extend(list, node:get("head"), {
						class = "card_icon",
						props = {
							unitId = cardCfg.unitID,
							rarity = unitCfg.rarity,
							star = v.maxStar,
							onNode = function(node)
								return
							end
						}
					})
					childs.txt:visible(not v.hasCard)

					if v.isSelect then
						childs.imgMask:show()
						childs.imgTick:show()
					else
						childs.imgMask:hide()
						childs.imgTick:hide()
					end

					if not v.hasCard then
						childs.imgMask:show()
					end

					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, list:getIdx(k), v)
						}
					})

					if v.isSelect then
						node:setTouchEnabled(false)
					else
						node:setTouchEnabled(true)
					end

					local size = childs.imgMask:size()
					local mask = ccui.Scale9Sprite:create()

					mask:initWithFile(cc.rect(60, 60, 1, 1), "common/box/mask_panel_exercise.png")
					mask:size(size.width, size.height):alignCenter(size)

					local offX = 0
					local offY = 0
					local sp = cc.Sprite:create(unitCfg.cardShow)
					local spSize = sp:size()
					local scale = 1.2 * unitCfg.cardShowScale
					local soff = cc.p(unitCfg.cardShowPosC.x / scale - offX, -unitCfg.cardShowPosC.y / scale + offY)
					local ssize = cc.size(size.width / scale, size.height / scale)
					local rect = cc.rect((spSize.width - ssize.width) / 2 - soff.x, (spSize.height - ssize.height) / 2 - soff.y, ssize.width, ssize.height)

					sp:alignCenter(size):scale(scale):setTextureRect(rect)
					cache.setShader(sp, false, "hsl_gray_white")
					sp:opacity(36)
					node:removeChildByName("clippingBg")
					cc.ClippingNode:create(mask):setAlphaThreshold(0.1):size(size):alignCenter(node:size()):add(sp):addTo(node, 1, "clippingBg")
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
	["down.btnLook"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onLookClick")
			}
		}
	},
	["down.btnTip"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onTipClick")
			}
		}
	}
}

function MegaAssistCardSelectView:onCreate(activityID, selectID, cb)
	Dialog.onCreate(self)

	self.cb = cb
	self.selectID = selectID or 0

	self:initPanelTouchEvent()

	self.activityID = activityID

	self:initData()
	self:initTipPanel()
end

function MegaAssistCardSelectView:initPanelTouchEvent()
	self.panel:setSwallowTouches(false)
	self.panel:onTouch(function(event)
		if event.name == "began" then
			self.tipPanel:hide()
		end
	end)
end

function MegaAssistCardSelectView:initData()
	self.cardDatas = idlers.new()

	local yyCfg = csv.yunying.yyhuodong[self.activityID]
	local cards = gGameModel.role:read("cards")

	local function getCardMaxStar(cardMarkID)
		local maxStar = 0

		for k, v in ipairs(cards) do
			local card = gGameModel.cards:find(v)
			local cardId = card:read("card_id")
			local star = card:read("star_original")

			if cardMarkID == csv.cards[cardId].cardMarkID and maxStar < star then
				maxStar = star
			end
		end

		return maxStar
	end

	local tb = {}

	for cardID, _ in csvPairs(yyCfg.paramMap.markID) do
		local hasCard = false
		local cardCfg = csv.cards[cardID]
		local cardMarkID = cardCfg.cardMarkID
		local maxStar, hasCards, dbid = dataEasy.getCardMaxStar(cardMarkID)

		hasCard = maxStar > 0

		local isMega = false

		for cardId, _ in pairs(hasCards) do
			local cfg = csv.cards[cardId]

			if cfg.cardMarkID == cardMarkID and gCardsMega[cfg.megaIndex] then
				isMega = true

				break
			end
		end

		local maxStar = cardCfg.star

		maxStar = getCardMaxStar(cardMarkID)

		table.insert(tb, {
			cardID = cardID,
			maxStar = maxStar,
			hasCard = hasCard,
			isMega = isMega,
			isSelect = cardID == self.selectID
		})
	end

	table.sort(tb, function(a, b)
		if a.hasCard ~= b.hasCard then
			return a.hasCard == true
		end

		return a.cardID < b.cardID
	end)
	self.cardDatas:update(tb)
end

function MegaAssistCardSelectView:initTipPanel()
	self.tipPanel:hide()

	local titleStr = gLanguageCsv.megaAssistSelectCardTitle
	local tipStr = gLanguageCsv.megaAssistSelectCardTip

	beauty.textScroll({
		isRich = true,
		list = self.tipPanel:get("list"),
		strs = titleStr .. tipStr
	})
end

function MegaAssistCardSelectView:onTipClick()
	self.tipPanel:show()
end

function MegaAssistCardSelectView:onCellClick(list, t, v)
	if not v.hasCard then
		gGameUI:showTip(gLanguageCsv.megaAssistNoCard)

		return
	end

	if v.isMega then
		gGameUI:showDialog({
			btnType = 2,
			clearFast = true,
			cb = function()
				if not self.cardDatas:atproxy(t.k).isSelect then
					for _, v in self.cardDatas:pairs() do
						if v:proxy().isSelect then
							v:proxy().isSelect = false

							break
						end
					end

					self.cardDatas:atproxy(t.k).isSelect = true
					self.selectID = v.cardID
				end
			end,
			content = string.format(gLanguageCsv.megaAssistCardHasMega)
		})
	elseif not self.cardDatas:atproxy(t.k).isSelect then
		for _, v in self.cardDatas:pairs() do
			if v:proxy().isSelect then
				v:proxy().isSelect = false

				break
			end
		end

		self.cardDatas:atproxy(t.k).isSelect = true
		self.selectID = v.cardID
	end
end

function MegaAssistCardSelectView:onLookClick()
	if self.selectID == 0 then
		gGameUI:showTip(gLanguageCsv.megaAssistNoSelectCard)

		return
	end

	self:addCallbackOnExit(functools.partial(self.cb, self.selectID))
	ViewBase.onClose(self)
end

return MegaAssistCardSelectView
