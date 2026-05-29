-- chunkname: @src.app.views.city.card.evolution_branch

local zawakeTools = require("app.views.city.zawake.tools")

local function setBranchData(data, currId)
	local showData1 = {}
	local showData2 = {}
	local csvCards = csv.cards[currId]
	local currDevelop = csvCards.develop

	for i, v in ipairs(data) do
		local branchSize = itertools.size(v.branch)

		if branchSize > 1 then
			showData1 = v.branch

			table.sort(showData1, function(a, b)
				return a.develop < b.develop
			end)

			if data[i + 1] then
				showData2 = data[i + 1].branch

				for i, v in pairs(showData1) do
					if not showData2[i] then
						showData2[i] = {}
					end

					showData2[i].develop = v.develop
				end

				table.sort(showData2, function(a, b)
					return a.develop < b.develop
				end)
			end

			break
		end
	end

	if itertools.size(showData2) > 0 then
		for k, v in ipairs(showData1) do
			v.curr = false
		end

		for k, v in ipairs(showData2) do
			if v.unitID == currId then
				v.curr = true
			else
				v.curr = false
			end
		end
	end

	return showData1, showData2
end

local function getShowData2Size(showData)
	local cnt = 0

	for k, v in showData:pairs() do
		local data = v:proxy()

		if data.unitID then
			cnt = cnt + 1
		end
	end

	return cnt
end

local CardEvolutionBranchView = class("CardEvolutionBranchView", Dialog)

CardEvolutionBranchView.RESOURCE_FILENAME = "card_evolution_branch.json"
CardEvolutionBranchView.RESOURCE_BINDING = {
	["branchPanel.img2"] = "img2",
	spritePanel = "spritePanel",
	branchPanel = "branchPanel",
	["branchPanel.img1"] = "img1",
	["btnPanel.text"] = "specialText",
	["btnPanel.btnBranch.title"] = "branchTxt",
	item1 = "item1",
	btnPanel1 = "btnPanel1",
	line13 = "line13",
	["costPanel.item"] = "costItem",
	btnPanel = "btnPanel",
	["costPanel.text"] = "costText",
	costPanel = "costPanel",
	line133 = "line133",
	line122 = "line122",
	line12 = "line12",
	item2 = "item2",
	btnClose = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	["btnPanel.btnBranch"] = {
		varname = "btnBranch",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSwitch")
			}
		}
	},
	["btnPanel1.btnBranch"] = {
		varname = "btnBranch1",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSwitchChange")
			}
		}
	},
	["branchPanel.list1"] = {
		varname = "list1",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("showData1"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("select")

					childs.select:visible(v.curr == true)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							cardId = v.id,
							onNode = function(node)
								node:xy(10, 10)
							end,
							onNodeClick = functools.partial(list.clickCell, k, v)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onSelectClick")
			}
		}
	},
	["branchPanel.list2"] = {
		varname = "list2",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("showData2"),
				item = bindHelper.self("item2"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("select")

					childs.select:visible(v.curr == true)

					if v.id then
						bind.extend(list, node, {
							class = "card_icon",
							props = {
								cardId = v.id,
								onNode = function(node)
									node:xy(0, 12)
								end,
								onNodeClick = functools.partial(list.clickCell, k, v)
							}
						})
					end
				end
			},
			handlers = {
				clickCell = bindHelper.self("onList2SelectClick")
			}
		}
	},
	["costPanel.list"] = {
		varname = "costList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("developItem"),
				item = bindHelper.self("costItem"),
				onItem = function(list, node, k, v)
					local showAddBtn = false

					if v.targetNum then
						showAddBtn = v.num < (v.targetNum or 0)
					end

					node:get("btnAdd"):visible(showAddBtn)
					node:get("imgMask"):visible(showAddBtn)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.key,
								num = v.num,
								targetNum = v.targetNum
							},
							onNode = function(node)
								bind.click(list, node, {
									method = functools.partial(list.itemClick, node, k, v)
								})
							end
						}
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick")
			}
		}
	}
}

function CardEvolutionBranchView:onCreate(params)
	self.costPanel:hide()
	self.costItem:hide()
	self.item1:hide()
	self.item2:hide()

	self.params = params

	local develop, data, branch, selectDbId, oldCurrBranch = params()

	self.oldCurrBranch = oldCurrBranch
	self.selectDbId = selectDbId
	self.data = data
	self.branch = idler.new(branch)
	self.cost = 0

	self:initModel()

	local developType = csv.cards[self.cardId].developType
	local developData = {}

	self.developItem = idlers.new()
	self.iconItem = {}

	local showData1, showData2 = setBranchData(data, self.cardId)

	self.showData1 = idlers.newWithMap(showData1)
	self.showData2 = idlers.newWithMap(showData2)

	local cardCfg = csv.cards[self.cardId]

	self:switchSpriteSpine(cardCfg)

	self.isData2Branch = self.showData2:size() > 0

	self.btnPanel1:hide()
	self.btnPanel:show()

	local ischangeSwitch = false

	for k, v in ipairs(showData1) do
		if v.id == self.cardId then
			ischangeSwitch = true

			break
		end
	end

	for k, v in ipairs(showData2) do
		if v.id == self.cardId then
			ischangeSwitch = true

			break
		end
	end

	if ischangeSwitch == true then
		self.btnPanel:hide()
		self.btnPanel1:show()

		for k, v in orderCsvPairs(csv.cards_branch_cost) do
			if v.developType == developType then
				local count = math.min(self.switchTimes, csvSize(v.cost))

				self.cost = v.cost[count].rmb or 0
				self.freeShow = self.cost == 0 and self.switchTimes < csvSize(v.cost)
				self.switchCD = v.switchCD
				developData = dataEasy.getItemData(v.cost[count])
			end
		end
	end

	local costListX = self.costList:x()
	local costTextX = self.costText:x()

	idlereasy.any({
		self.items,
		self.gold
	}, function(_, items, gold)
		local developItem = {}

		for k, v in ipairs(developData) do
			if v.key ~= "rmb" then
				if v.key == "gold" then
					table.insert(developItem, {
						key = v.key,
						num = gold,
						targetNum = v.num
					})
				else
					table.insert(developItem, {
						key = v.key,
						num = items[v.key] or 0,
						targetNum = v.num
					})
				end
			end
		end

		local itemNum = #developItem
		local scale = 0.9

		self.costList:size(200 * itemNum, 200):scale(scale)
		self.costList:x(costListX - 200 * (itemNum - 1) * scale)
		self.costText:x(costTextX - 200 * (itemNum - 1) * scale)

		self.item = developItem

		self.developItem:update(developItem)
	end)

	local showTab1 = branch
	local showTab2 = branch
	local i = 0

	for k, v in self.showData1:pairs() do
		local data = v:proxy()

		i = i + 1

		if data.curr == true then
			showTab1 = i

			break
		end
	end

	self.showTab1 = idler.new(showTab1)
	self.showTab2 = idler.new(showTab2)

	local num = self.showData1:size()
	local name = "line1" .. (self.showData2:size() == 0 and num or num .. self.showData2:size())

	self.lineName = name

	if self.showData2:size() == 0 then
		self.showTab1:addListener(function(val, oldval, idler)
			self:updateTab(val, oldval)
		end)
	else
		self.showTab2:addListener(function(val, oldval, idler)
			self:updateTab(val, oldval)
		end)
	end

	self:setLine(name)

	local oldCardId = 1
	local cardMarkID = csv.cards[self.cardId].cardMarkID

	for k, v in orderCsvPairs(csv.cards) do
		if matchLanguageForce(v.languages) and v.cardMarkID == cardMarkID and develop >= v.develop and v.branch == 0 and oldCardId < k then
			oldCardId = k
		end
	end

	local posX = self.showData2:size() == 0 and 178 or 28

	bind.extend(self, self.branchPanel, {
		class = "card_icon",
		props = {
			cardId = ischangeSwitch and oldCardId or self.cardId,
			onNode = function(node)
				node:xy(cc.p(posX, 250))
			end
		}
	})
	idlereasy.when(self.rmb, function(_, rmb)
		local color = rmb < self.cost and ui.COLORS.NORMAL.RED or ui.COLORS.NORMAL.DEFAULT

		text.addEffect(self.btnPanel1:get("text"), {
			color = color
		})
	end)
	self:setBottomSpine()
	Dialog.onCreate(self)
end

function CardEvolutionBranchView:initModel()
	local card = gGameModel.cards:find(self.selectDbId)

	self.cardId = card:read("card_id")
	self.rmb = gGameModel.role:getIdler("rmb")
	self.switchTimes = card:read("branch_switch_times") + 1
	self.switchLastTime = card:read("branch_switch_last_time") or 0
	self.gold = gGameModel.role:getIdler("gold")
	self.items = gGameModel.role:getIdler("items")
end

function CardEvolutionBranchView:updateTab(val, oldval)
	local showData = self.showData1

	if self.showData2:size() > 0 then
		showData = self.showData2
	end

	self.btnBranch:setTouchEnabled(val ~= 0)
	self.specialText:visible(val == 0)
	cache.setShader(self.btnBranch, false, val ~= 0 and "normal" or "hsl_gray")

	if oldval ~= 0 then
		showData:atproxy(oldval).curr = false

		self[self.lineName]:get("red" .. oldval):hide()
	end

	if val ~= 0 then
		local data = showData:atproxy(val)

		self.btnPanel1:get("text"):hide()
		self.btnPanel1:get("text1"):hide()
		self.btnPanel1:get("icon"):hide()
		text.addEffect(self.btnPanel1:get("text"), {
			color = ui.COLORS.NORMAL.DEFAULT
		})
		self.costPanel:hide()

		if data.id == self.cardId then
			self.btnBranch1:setTouchEnabled(false)
			self.btnBranch1:get("title"):text(gLanguageCsv.nowBranch)
			cache.setShader(self.btnBranch1, false, "hsl_gray")
		else
			self.btnBranch1:setTouchEnabled(true)

			if self.cost > 0 then
				self.btnPanel1:get("text"):show()
				self.btnPanel1:get("text"):text(self.cost)
				self.btnPanel1:get("text1"):show()
				self.btnPanel1:get("icon"):show()
			elseif self.freeShow then
				self.btnPanel1:get("text"):show():text(gLanguageCsv.branchSwitchFree)
				text.addEffect(self.btnPanel1:get("text"), {
					color = ui.COLORS.NORMAL.ALERT_ORANGE
				})
			end

			adapt.oneLineCenterPos(cc.p(self.btnBranch1:x(), self.btnBranch1:y() + 80), {
				self.btnPanel1:get("text1"),
				self.btnPanel1:get("text"),
				self.btnPanel1:get("icon")
			})
			self.costPanel:visible(#self.item > 0)
			self.btnBranch1:get("title"):text(gLanguageCsv.chanceBranch)
			cache.setShader(self.btnBranch1, false, "normal")
		end

		text.addEffect(self.branchTxt, {
			glow = {
				color = ui.COLORS.GLOW.WHITE
			},
			color = ui.COLORS.NORMAL.WHITE
		})

		data.curr = true

		self[self.lineName]:get("red" .. val):show()
		self:switchSpriteSpine(data)
		self.branch:set(data.currRealBranch)
	else
		text.deleteAllEffect(self.branchTxt)
		text.addEffect(self.branchTxt, {
			color = ui.COLORS.DISABLED.WHITE
		})
	end

	if self.switchCD then
		self:enableSchedule():schedule(function()
			self.btnPanel1:removeChildByName("cutdown")

			local dt = self.switchLastTime + self.switchCD - time.getTime()

			if dt > 0 then
				local t = time.getCutDown(dt, true, dt >= 86400)

				rich.createByStr(string.format(gLanguageCsv.branchSwitchCutdown, t.short_date_str), 34):addTo(self.btnPanel1, 10, "cutdown"):anchorPoint(cc.p(0.5, 0.5)):xy(self.btnBranch1:x(), self.btnBranch1:y() - 80):formatText()
			end
		end, 1, 0, 1)
	end
end

function CardEvolutionBranchView:setBottomSpine()
	local size = self.spritePanel:size()
	local eff1 = CSprite.new("effect/jinhuajiemian.skel")

	eff1:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff1:play("effect_down2_loop")
	eff1:addTo(self.spritePanel, 4, "effect1")

	local eff2 = CSprite.new("effect/jinhuajiemian.skel")

	eff2:xy(size.width / 2 - 40, size.height / 4 - 15)
	eff2:play("effect_up_loop")
	eff2:addTo(self.spritePanel, 7, "effect2")
end

function CardEvolutionBranchView:setLine(name)
	local listSize2 = cc.size(215, 422)
	local imgSize2 = cc.size(214, 432)
	local listSize3 = cc.size(215, 646)
	local imgSize3 = cc.size(214, 658)
	local listY2 = 136
	local listY3 = 21
	local imgY = 345

	if self.showData2:size() == 0 then
		self.list2:hide()

		if self.showData1:size() == 2 then
			self.list1:xy(533, listY2)
			self.list1:size(listSize2)
			self.img1:xy(642, imgY)
			self.img1:size(imgSize2)
		else
			self.list1:size(listSize3)
			self.list1:xy(533, listY3)
			self.img1:xy(645, imgY)
			self.img1:size(imgSize3)
		end

		self.img1:show()
		self.img2:hide()
	else
		if self.showData1:size() == 2 then
			self.list1:xy(364, listY2)
			self.list1:size(listSize2)
			self.list2:xy(710, listY2)
			self.list2:size(listSize2)
			self.img1:size(imgSize2)
			self.img1:xy(472, imgY)
		else
			self.list1:xy(364, listY3)
			self.list1:size(listSize3)
			self.list2:xy(710, listY3)
			self.list2:size(listSize3)
			self.img1:xy(472, imgY)
			self.img1:size(imgSize3)
		end

		self.img1:hide()
		self.img2:visible(getShowData2Size(self.showData2) > 1)
	end

	self[name]:show()

	local i = 0

	for k, v in self.showData2:pairs() do
		local data = v:proxy()

		i = i + 1

		if data.id == nil then
			self[name]:get("red" .. i, "line6"):hide()
			self[name]:get("white" .. i):hide()
		end
	end
end

function CardEvolutionBranchView:switchSpriteSpine(v)
	self.markID = v.cardMarkID

	local unit = csv.unit[v.unitID]
	local size = self.spritePanel:size()
	local childs = self.spritePanel:multiget("name", "attr2", "rarity", "attr1", "cardImg", "bottom")

	childs.bottom:visible(false)
	childs.cardImg:removeAllChildren()

	local sprite2 = widget.addAnimation(childs.cardImg, unit.unitRes, "standby_loop")
	local size = childs.cardImg:size()

	sprite2:xy(size.width / 2, size.height / 7):scale(unit.scale)
	sprite2:setSkin(unit.skin)
	childs.name:text(unit.name)
	childs.name:setTextColor(ui.COLORS.NORMAL.DEFAULT)
	childs.attr2:visible(unit.natureType2 ~= nil)

	if unit.natureType2 then
		childs.attr2:texture(ui.ATTR_ICON[unit.natureType2])
	end

	childs.rarity:texture(ui.RARITY_ICON[unit.rarity])
	childs.attr1:texture(ui.ATTR_ICON[unit.natureType])

	if unit.natureType2 then
		adapt.oneLineCenterPos(cc.p(290, 80), {
			childs.rarity,
			childs.name,
			childs.attr1,
			childs.attr2
		}, cc.p(8, 0))
	else
		adapt.oneLineCenterPos(cc.p(290, 80), {
			childs.rarity,
			childs.name,
			childs.attr1
		}, cc.p(8, 0))
	end
end

function CardEvolutionBranchView:onSwitch()
	userDefault.setForeverLocalKey("evolutionBranch", {
		[self.cardId] = self.branch:read()
	})
	self.params(self.branch:read())
	self:onClose()
end

function CardEvolutionBranchView:onSwitchChange()
	local dt = self.switchLastTime + self.switchCD - time.getTime()

	if dt > 0 then
		gGameUI:showTip(gLanguageCsv.branchSwitchCantChange)

		return
	end

	if self.rmb:read() < self.cost then
		uiEasy.showDialog("rmb", nil, {
			dialog = true
		})

		return
	end

	for _, v in ipairs(self.item) do
		if v.key == "gold" then
			if v.num > self.gold:read() then
				gGameUI:showTip(gLanguageCsv.goldNotEnough)

				return
			end
		elseif v.targetNum > v.num then
			gGameUI:showTip(gLanguageCsv.branchItemsNotEnough)

			return
		end
	end

	local function costCb()
		local content = "#C0x5b545b#" .. string.format(gLanguageCsv.onSwitchChange1, self.cost)

		if self.cost == 0 then
			content = "#C0x5b545b#" .. gLanguageCsv.onSwitchChange2
		end

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			content = content,
			cb = function()
				local function sureCb()
					gGameApp:requestServer("/game/card/switch/branch", function(tb)
						if not itertools.isempty(tb.view) then
							gGameUI:showGainDisplay(tb.view)
						end
					end, self.selectDbId, self.branch:read())
					self.oldCurrBranch:set(self.branch:read())
					gGameUI:showTip(gLanguageCsv.succeedSwitchChange)
					self:onClose()
				end

				if self.switchCD > 0 then
					local t = time.getCutDown(self.switchCD)
					local sureStr = string.format(gLanguageCsv.branchSwitchCutdownTip, string.format("%s%s", t.day > 0 and t.daystr or "", t.hour > 0 and t.hourstr or ""))

					gGameUI:showDialog({
						isRich = true,
						btnType = 2,
						content = sureStr,
						cb = sureCb,
						dialogParams = {
							clickClose = false
						}
					})
				else
					sureCb()
				end
			end,
			dialogParams = {
				clickClose = false
			}
		})
	end

	local cardCfg = csv.cards[self.cardId]
	local newCardCfg = gCardsCsv[cardCfg.cardMarkID][cardCfg.develop][self.branch:read()]
	local zawakeStage, zawakeLevel = zawakeTools.getMaxStageLevel(cardCfg.zawakeID)

	if zawakeStage and cardCfg.zawakeID ~= newCardCfg.zawakeID then
		local name = csv.cards[self.cardId].name
		local stageStr = gLanguageCsv["symbolRome" .. zawakeStage]
		local tip = string.format(gLanguageCsv.zawakeBranchTip, name, stageStr)

		gGameUI:showDialog({
			isRich = true,
			btnType = 2,
			content = tip,
			cb = costCb
		})
	else
		costCb()
	end
end

function CardEvolutionBranchView:onSelectClick(list, k, v)
	local cards = csv.cards
	local data = self.showData1:atproxy(k)

	if csv.cards[data.id].develop < csv.cards[self.cardId].develop then
		gGameUI:showTip(gLanguageCsv.canNotSwitchChange)

		return
	else
		self.showTab1:set(k)
	end
end

function CardEvolutionBranchView:onList2SelectClick(list, k, v)
	local cards = csv.cards
	local data = self.showData2:atproxy(k)

	if csv.cards[data.id].develop < csv.cards[self.cardId].develop then
		gGameUI:showTip(gLanguageCsv.canNotSwitchChange)

		return
	else
		self.showTab2:set(k)
	end
end

function CardEvolutionBranchView:onItemClick(list, panel, k, v)
	gGameUI:stackUI("common.gain_way", nil, nil, v.key, nil, v.targetNum)
end

return CardEvolutionBranchView
