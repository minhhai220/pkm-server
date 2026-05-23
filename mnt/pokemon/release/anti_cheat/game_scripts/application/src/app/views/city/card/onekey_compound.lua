-- chunkname: @src.app.views.city.card.onekey_compound

local CardOneKeyCompoundView = class("CardOneKeyCompoundView", cc.load("mvc").ViewBase)

CardOneKeyCompoundView.RESOURCE_FILENAME = "card_onekey_compound.json"
CardOneKeyCompoundView.RESOURCE_BINDING = {
	topPanel = "topPanel",
	subList = "subList",
	item = "item",
	["btnAll.checkBox"] = "checkBox",
	txtTip = "txtTip",
	["topPanel.btnClose"] = {
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
				asyncPreload = 18,
				columnSize = 6,
				data = bindHelper.self("listData"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("cardNode", "imgTick", "name")

					bind.extend(list, childs.cardNode, {
						class = "card_icon",
						props = {
							cardId = v.cardCfg.id,
							rarity = v.rarity,
							onNode = function(node)
								node:scale(1.05)
							end
						}
					})
					childs.name:hide()
					node:removeChildByName("txtName")
					beauty.singleTextLimitWord(v.cardCfg.name, {
						fontSize = 40
					}, {
						width = 200
					}):xy(childs.name:x() + 10, 35):addTo(node, 10, "txtName")
					text.addEffect(node:getChildByName("txtName"), {
						color = ui.COLORS.NORMAL.DEFAULT
					})
					childs.imgTick:visible(v.isSelect)
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.clickCell, node, list:getIdx(k), v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	btnOk = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onOkClick")
			}
		}
	},
	btnAll = {
		varname = "btnAll",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnAllClick")
			}
		}
	}
}

function CardOneKeyCompoundView:onCreate(data, cb)
	adapt.oneLinePos(self.topPanel:get("title"), self.topPanel:get("title1"), cc.p(0, 0))
	Dialog.onCreate(self)

	self.isShowHero = false
	self.cb = cb

	local fragData = {}

	for i, v in ipairs(data) do
		local count = math.floor(v.num / v.maxNum)

		if count > 0 then
			local fragCfg = csv.fragments[v.id]
			local cardCfg = csv.cards[fragCfg.combID]

			for i = 1, count do
				table.insert(fragData, {
					isSelect = false,
					fragID = v.id,
					rarity = v.rarity,
					cardCfg = cardCfg
				})
			end
		end
	end

	table.sort(fragData, function(a, b)
		if a.rarity ~= b.rarity then
			return a.rarity > b.rarity
		end

		return a.fragID < b.fragID
	end)

	self.listData = idlers.newWithMap(fragData)
	self.max = self.listData:size()

	self.txtTip:text(string.format(gLanguageCsv.cardCompoundSelectTip, 0, self.max))

	self.selectData = {}
	self.selectCount = 0
	self.state = idler.new(false)

	idlereasy.when(self.state, function(_, state)
		self.checkBox:setSelectedState(state)

		self.selectData = {}

		for i = 1, self.max do
			self.listData:atproxy(i).isSelect = state

			if state == true then
				if self.selectData[self.listData:atproxy(i).fragID] then
					self.selectData[self.listData:atproxy(i).fragID] = self.selectData[self.listData:atproxy(i).fragID] + 1
				else
					self.selectData[self.listData:atproxy(i).fragID] = 1
				end
			end
		end

		local selectNum = state and self.max or 0

		self.txtTip:text(string.format(gLanguageCsv.cardCompoundSelectTip, selectNum, self.max))

		self.selectCount = selectNum
	end)
end

function CardOneKeyCompoundView:onItemClick(list, node, t, v)
	if self.listData:atproxy(t.k).isSelect == false then
		self.listData:atproxy(t.k).isSelect = true

		if self.selectData[v.fragID] then
			self.selectData[v.fragID] = self.selectData[v.fragID] + 1
		else
			self.selectData[v.fragID] = 1
		end
	else
		self.listData:atproxy(t.k).isSelect = false

		if self.selectData[v.fragID] then
			self.selectData[v.fragID] = self.selectData[v.fragID] - 1

			if self.selectData[v.fragID] == 0 then
				self.selectData[v.fragID] = nil
			end
		end
	end

	local selectCount = 0

	for id, num in pairs(self.selectData) do
		selectCount = selectCount + num
	end

	self.selectCount = selectCount

	self.txtTip:text(string.format(gLanguageCsv.cardCompoundSelectTip, self.selectCount, self.max))
end

function CardOneKeyCompoundView:onOkClick()
	if self.selectCount == 0 then
		gGameUI:showTip(gLanguageCsv.cardCompoundNoSelect)

		return
	end

	local cardCapacity = gGameModel.role:read("card_volume")
	local cards = gGameModel.role:read("cards")

	if cardCapacity - (itertools.size(cards) + self.selectCount) <= 0 then
		gGameUI:showDialog({
			clearFast = true,
			btnType = 2,
			content = gLanguageCsv.cardBagHaveBeenFullDraw,
			cb = function()
				gGameUI:stackUI("city.card.bag", nil, {
					full = true
				})
			end
		})

		return
	end

	gGameApp:requestServer("/game/role/frag/comb", function(tb)
		local t = tb.view.carddbIDs

		for i, v in ipairs(t) do
			local card = gGameModel.cards:find(v.db_id)
			local cardID = card:read("card_id")
			local cardCfg = csv.cards[cardID]
			local unitCfg = csv.unit[cardCfg.unitID]
			local rarity = unitCfg.rarity

			v.rarity = rarity
			v.cardID = cardID
		end

		table.sort(t, function(a, b)
			if a.rarity ~= b.rarity then
				return a.rarity > b.rarity
			end

			return a.cardID < b.cardID
		end)

		local tag = "cardOneKeyCompound"
		local i = 0
		local view = gGameUI:getTopStackUI()

		view:enableSchedule()
		view:schedule(function()
			if not self.isShowHero then
				i = i + 1

				local isJumpSpriteView = userDefault.getForeverLocalKey("isJumpSpriteView", false)

				if t[i] then
					if not isJumpSpriteView then
						self.isShowHero = true

						gGameUI:stackUI("common.gain_sprite", nil, {
							full = true
						}, t[i], nil, #t > 1, self:createHandler("changeState"))
					end
				else
					userDefault.setForeverLocalKey("isJumpSpriteView", false)
					performWithDelay(self, function()
						self:addCallbackOnExit(functools.partial(self.cb, t[1].db_id))
						self:onClose()
					end, 0)

					return false
				end
			end
		end, 0.01, 0, tag)
	end, self.selectData)
end

function CardOneKeyCompoundView:changeState()
	self.isShowHero = false
end

function CardOneKeyCompoundView:onBtnAllClick()
	self.state:modify(function(val)
		return true, not val
	end)
end

return CardOneKeyCompoundView
