-- chunkname: @src.app.views.city.card.mega.mega_assist.view

local ViewBase = cc.load("mvc").ViewBase
local MegaAssistView = class("MegaAssistView", cc.load("mvc").ViewBase)
local NO_SELECT_ITEM = {
	specEvo = 9056,
	specFrag = 9057,
	specHeld = 9059,
	specCard = game.UNKONW_CARD_ID
}
local RECIEVE_STATE = {
	RECIEVED = 0,
	CAN = 1,
	CANNOT = 0.5
}

local function getShowAwardCfg(award, v, needGray)
	local tb = table.deepcopy(award, true)
	local yyCfg = csv.yunying.yyhuodong[v.activityID]

	for key, showKey in pairs(NO_SELECT_ITEM) do
		if tb[key] then
			if v.selectMarkID ~= 0 then
				if key == "specFrag" then
					local cardCfg = csv.cards[v.selectMarkID]
					local fragID = cardCfg.fragID

					tb[fragID] = tb[key]
					tb[key] = nil
				elseif key == "specEvo" or key == "specHeld" then
					tb[yyCfg.paramMap.markID[v.selectMarkID][key]] = tb[key]
					tb[key] = nil
				elseif key == "specCard" then
					tb.cards = {
						id = v.selectMarkID
					}
					tb[key] = nil
				end
			else
				tb[NO_SELECT_ITEM[key]] = tb[key]
				tb[key] = nil
			end
		end
	end

	local tmp = {}

	for key, num in pairs(tb) do
		local grayState = needGray and (v.recieveState == RECIEVE_STATE.RECIEVED and 1 or 0) or 0

		table.insert(tmp, {
			key = key,
			num = num,
			grayState = grayState
		})
	end

	return tmp
end

local function getCardMaxStar(cardMarkID)
	local cards = gGameModel.role:read("cards")
	local maxStar = 0
	local hasCards = {}

	for k, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)
		local cardId = card:read("card_id")
		local star = card:read("star_original")

		hasCards[cardId] = true

		if cardMarkID == csv.cards[cardId].cardMarkID and maxStar < star then
			maxStar = star
		end
	end

	return maxStar, hasCards
end

MegaAssistView.RESOURCE_FILENAME = "mega_assist.json"
MegaAssistView.RESOURCE_BINDING = {
	["leftPanel.imgDi"] = "imgDi",
	["leftPanel.itemPanel.starItem"] = "starItem",
	["leftPanel.itemPanel"] = "itemPanel",
	["leftPanel.addBg"] = "addBg",
	["leftPanel.animaCard"] = "animaCard",
	awardItem = "awardItem",
	rightDownPanel = "rightDownPanel",
	["leftPanel.megaOk"] = "megaOk",
	rightAwardPanel = "rightAwardPanel",
	["rightAwardPanel.scrollStar"] = "scrollStar",
	star = "star",
	["leftPanel.itemPanel.attrItem"] = "attrItem",
	leftPanel = "leftPanel",
	bg = "bg",
	["leftPanel.btnAdd"] = {
		varname = "btnAdd",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAddClick")
			}
		}
	},
	["leftPanel.megaOk.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c3b(232, 76, 15)
				}
			}
		}
	},
	["leftPanel.txtTip"] = {
		varname = "txtTip",
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c3b(52, 52, 52)
				}
			}
		}
	},
	["leftPanel.btnChange"] = {
		varname = "btnChange",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onChangeClick")
			}
		}
	},
	["leftPanel.btnExclusive"] = {
		varname = "btnExclusive",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onExclusiveClick")
				}
			},
			{
				event = "extend",
				class = "red_hint",
				props = {
					specialTag = "megaAssistFree",
					listenData = {
						activityId = bindHelper.self("activityID")
					},
					onNode = function(panel)
						panel:xy(160, 180)
					end
				}
			}
		}
	},
	["leftPanel.btnLock"] = {
		varname = "btnLock",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onLockClick")
			}
		}
	},
	["leftPanel.btnLock.txt"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["leftPanel.itemPanel.starList"] = {
		varname = "starList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("cardStarData"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("star"):texture(v.icon)
				end
			}
		}
	},
	["leftPanel.itemPanel.attrList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:texture(ui.ATTR_ICON[v]):scale(0.8)
				end
			}
		}
	},
	["rightAwardPanel.awardList"] = {
		varname = "awardList",
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("awardData"),
				item = bindHelper.self("awardItem"),
				onItem = function(list, node, k, v)
					local childs = node:multiget("freeList", "buyList", "buyTimes", "btnBuy")
					local cfg = v.cfg

					local function onNode(node)
						node:removeChildByName("awardSpine")
						node:removeChildByName("recieveTick")

						if v.recieveState == RECIEVE_STATE.CAN then
							widget.addAnimationByKey(node, "megasupport/huanraoguang.skel", "awardSpine", "huang_effect_loop", 5):alignCenter(node:size())
							bind.touch(list, node, {
								methods = {
									ended = functools.partial(list.clickGet, k, v)
								}
							})
						elseif v.recieveState == RECIEVE_STATE.RECIEVED then
							ccui.ImageView:create("city/card/evolution/logo_tick1.png"):alignCenter(node:size()):scale(1.5):addTo(node, 10000, "recieveTick")
						end
					end

					local freeItems = getShowAwardCfg(cfg.freeItems, v, true)
					local noListener = v.recieveState == RECIEVE_STATE.CAN

					uiEasy.createItemsToList(list, childs.freeList, freeItems, {
						margin = 0,
						scale = 0.7,
						onNode = onNode,
						onAfterBuild = function(list)
							childs.freeList:setItemAlignCenter()
						end,
						noListener = noListener
					})

					local items = getShowAwardCfg(cfg.items, v)

					uiEasy.createItemsToList(list, childs.buyList, items, {
						margin = 0,
						scale = 0.7,
						onAfterBuild = function(list)
							childs.buyList:setItemAlignCenter()
						end
					})
					childs.buyTimes:hide()
					childs.buyTimes:parent():removeChildByName("buyTimesRich")

					local color = v.lastBuyTimes == 0 and "#C0xF76B45#" or "#C0x74BE6D#"
					local buyStr = string.format(gLanguageCsv.shopBuyLimitNoDay, color, v.lastBuyTimes, v.limitBuyTimes)
					local rich = rich.createByStr(buyStr, 36):xy(childs.buyTimes:xy()):anchorPoint(0.5, 0.5):addTo(childs.buyTimes:parent(), 5, "buyTimesRich")
					local rechargeCfg = csv.recharges[cfg.rechargeID]
					local priceStr = v.lastBuyTimes > 0 and string.format(gLanguageCsv.symbolMoney, rechargeCfg.rmbDisplay) or gLanguageCsv.sellout

					childs.btnBuy:get("txtPrice"):text(priceStr)
					text.addEffect(childs.btnBuy:get("txtPrice"), {
						color = ui.COLORS.NORMAL.WHITE,
						glow = {
							color = ui.COLORS.GLOW.WHITE
						}
					})

					local btnState = v.canBuy and 1 or 2

					if not v.hasLock then
						btnState = 3
					end

					if v.selectMarkID ~= 0 and not v.hasLock then
						btnState = 2
					end

					uiEasy.setBtnShader(childs.btnBuy, childs.btnBuy:get("txtPrice"), btnState)
					bind.touch(list, childs.btnBuy, {
						clicksafe = true,
						methods = {
							ended = functools.partial(list.clickBuy, k, v)
						}
					})
				end,
				onAfterBuild = function(list)
					return
				end
			},
			handlers = {
				clickBuy = bindHelper.self("onBuyClick"),
				clickGet = bindHelper.self("onOneKeyClick")
			}
		}
	},
	["rightAwardPanel.topPanel.btnRule"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRuleClick")
			}
		}
	},
	["rightAwardPanel.topPanel.txtStar"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c3b(199, 88, 28)
				}
			}
		}
	},
	["rightAwardPanel.topPanel.txtFree"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c3b(199, 88, 28)
				}
			}
		}
	},
	["rightAwardPanel.topPanel.txtExclusive"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = cc.c3b(199, 88, 28)
				}
			}
		}
	}
}

function MegaAssistView:onCreate(activityID)
	gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "MEGA ASSIST",
		title = gLanguageCsv.megaAssist
	})

	self.activityID = activityID

	self:initModel()

	local yyData = self.yyhuodongs:read()[self.activityID] or {}
	local info = yyData.info or {}
	local markID = 0

	self.starNum = 0

	if info.markID then
		markID = info.markID
		self.starNum = info.maxStar
	end

	self.selectMarkID = idler.new(markID)
	self.hasLock = false

	self.scrollStar:setScrollBarEnabled(false)

	self.clientScrollY = self.scrollStar:y()

	self.btnExclusive:z(1000)
	idlereasy.any({
		self.yyhuodongs,
		self.clientBuyTimes,
		self.selectMarkID
	}, function(_, yyhuodongs, clientBuyTimes, selectMarkID)
		local tb = {}
		local yyData = yyhuodongs[self.activityID] or {}
		local stamps = yyData.stamps or {}
		local valsums = yyData.valsums or {}
		local info = yyData.info or {}

		if info.markID then
			self.hasLock = true
			self.starNum = info.maxStar
		end

		if selectMarkID > 0 and not info.maxStar then
			local maxStar = getCardMaxStar(selectMarkID)

			self.starNum = maxStar
		end

		local yyCfg = csv.yunying.yyhuodong[self.activityID]

		for id, v in orderCsvPairs(csv.yunying.mega_assist) do
			if v.huodongID == yyCfg.huodongID and v.taskType == 1 then
				local recieveState = RECIEVE_STATE.CANNOT

				if stamps[id] == 1 then
					recieveState = RECIEVE_STATE.CAN
				elseif stamps[id] == 0 then
					recieveState = RECIEVE_STATE.RECIEVED
				end

				local canBuy = false
				local limitBuyTimes = v.limit
				local buyTimes = valsums[id] or 0

				buyTimes = dataEasy.getPayClientBuyTimes("directBuyData", self.activityID, id, buyTimes)

				local lastBuyTimes = limitBuyTimes - buyTimes

				if self.hasLock and self.starNum >= v.taskParam and lastBuyTimes > 0 then
					canBuy = true
				end

				table.insert(tb, {
					csvID = id,
					needStar = v.taskParam,
					cfg = v,
					recieveState = recieveState,
					limitBuyTimes = limitBuyTimes,
					lastBuyTimes = lastBuyTimes,
					buyTimes = buyTimes,
					selectMarkID = self.selectMarkID:read(),
					activityID = self.activityID,
					hasLock = self.hasLock,
					canBuy = canBuy
				})
			end
		end

		local btnState = self.hasLock and 2 or 1

		uiEasy.setBtnShader(self.btnLock, self.btnLock:get("txt"), btnState)
		table.sort(tb, function(a, b)
			return a.needStar < b.needStar
		end)
		dataEasy.tryCallFunc(self.awardList, "updatePreloadCenterIndex")
		dataEasy.tryCallFunc(self.scrollStar, "updatePreloadCenterIndex")
		self.awardData:update(tb)
		self:updateLeftPanel()
		self:updateRightPanel()
	end)
end

function MegaAssistView:initModel()
	self.yyOpen = gGameModel.role:getIdler("yy_open")
	self.yyhuodongs = gGameModel.role:getIdler("yyhuodongs")
	self.attrDatas = idlers.newWithMap({})
	self.cardStarData = idlers.new({})
	self.awardData = idlers.new()
	self.clientBuyTimes = idler.new(true)
end

function MegaAssistView:updateLeftPanel()
	local selectMarkID = self.selectMarkID:read()

	self.megaOk:hide()
	itertools.invoke({
		self.btnAdd,
		self.addBg,
		self.txtTip,
		self.imgDi
	}, selectMarkID == 0 and "show" or "hide")
	itertools.invoke({
		self.btnChange,
		self.btnLock,
		self.animaCard,
		self.itemPanel
	}, selectMarkID == 0 and "hide" or "show")

	if self.hasLock then
		self.btnChange:hide()
		self.btnLock:hide()
	end

	if selectMarkID == 0 then
		-- block empty
	else
		local _, hasCards = getCardMaxStar(selectMarkID)
		local isMega = false

		for cardId, _ in pairs(hasCards) do
			local cfg = csv.cards[cardId]

			if cfg.cardMarkID == selectMarkID and gCardsMega[cfg.megaIndex] then
				isMega = true

				break
			end
		end

		if isMega then
			self.megaOk:show()
		end

		local cardCfg = csv.cards[selectMarkID]
		local unitCfg = csv.unit[cardCfg.unitID]

		self.animaCard:removeChildByName("cardSpine")
		widget.addAnimationByKey(self.animaCard, unitCfg.unitRes, "cardSpine", "standby_loop", 5):alignCenter(self.animaCard:size()):scale(unitCfg.scaleU * 3):y(-50):setSkin(unitCfg.skin)
		self.itemPanel:get("icon"):texture(ui.RARITY_ICON[unitCfg.rarity])

		local attrDatas = {}

		table.insert(attrDatas, unitCfg.natureType)

		if unitCfg.natureType2 then
			table.insert(attrDatas, unitCfg.natureType2)
		end

		self.attrDatas:update(attrDatas)
		uiEasy.setIconName("card", selectMarkID, {
			space = true,
			node = self.itemPanel:get("name")
		})

		local cardStarData = {}
		local starIdx = self.starNum - 6

		for i = 1, 6 do
			local icon = "common/icon/icon_star_d.png"

			if i <= self.starNum then
				icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
			end

			table.insert(cardStarData, {
				icon = icon
			})
		end

		self.cardStarData:update(cardStarData)
	end
end

function MegaAssistView:updateRightPanel()
	local selectMarkID = self.selectMarkID:read()
	local starIdx = 0

	text.deleteEffect(self.star:get("txtStar"), "all")
	text.addEffect(self.star:get("txtStar"), {
		color = cc.c3b(255, 249, 231),
		outLine = {
			color = cc.c3b(150, 77, 8)
		}
	})

	local itemHeight = self.awardItem:height()
	local innerHeight = itemHeight * self.awardData:size()
	local innerBarHeight = itemHeight * (self.awardData:size() - 1)

	self.scrollStar:setInnerContainerSize(cc.size(self.scrollStar:width(), innerHeight))

	local deltaHeight = innerHeight - self.scrollStar:height()

	self.scrollStar:get("bar"):width(innerBarHeight)
	self.scrollStar:get("bar"):y(innerHeight - innerBarHeight / 2 - itemHeight / 2)
	self.scrollStar:get("barBg"):width(innerBarHeight)
	self.scrollStar:get("barBg"):y(innerHeight - itemHeight / 2)
	self.scrollStar:get("startPos"):y(innerHeight - itemHeight / 2)

	local startX, startY = self.scrollStar:get("startPos"):xy()
	local starT = {}

	for i, v in self.awardData:ipairs() do
		starIdx = starIdx + 1

		local data = v:read()
		local star = self.star:clone():show():addTo(self.scrollStar, 10):xy(startX, startY - itemHeight * (starIdx - 1))

		star:get("txtStar"):text(data.needStar)

		if self.starNum >= data.needStar then
			star:texture("city/card/mega_assist/logo_xj.png")
			text.deleteEffect(self.star:get("txtStar"), "all")
			text.addEffect(self.star:get("txtStar"), {
				color = cc.c3b(255, 249, 231),
				outLine = {
					color = cc.c3b(150, 77, 8)
				}
			})
		else
			star:texture("city/card/mega_assist/logo_xj1.png")
			text.deleteEffect(self.star:get("txtStar"), "all")
			text.addEffect(self.star:get("txtStar"), {
				color = cc.c3b(255, 249, 231),
				outLine = {
					color = cc.c3b(96, 96, 98)
				}
			})
		end

		table.insert(starT, data.needStar)
	end

	self.scrollStar:get("bar"):setPercent(self:getBarPercent(starT))
	self.awardList:onScroll(function(event)
		if event.name == "CONTAINER_MOVED" then
			local y = self.awardList:getInnerContainer():y()

			self.scrollStar:setInnerContainerPosition(cc.p(0, y))
		end
	end)
	self.scrollStar:onScroll(function(event)
		if event.name == "CONTAINER_MOVED" then
			local y = self.scrollStar:getInnerContainer():y()

			self.awardList:setInnerContainerPosition(cc.p(0, y))
		end
	end)

	local taskCfg, taskCsvID

	for id, v in orderCsvPairs(csv.yunying.mega_assist) do
		if v.taskType == 2 then
			taskCfg = v
			taskCsvID = id
		end
	end

	if self.selectMarkID:read() == 0 then
		local tempID
		local yyCfg = csv.yunying.yyhuodong[self.activityID]

		for markID, _ in csvMapPairs(yyCfg.paramMap.markID) do
			tempID = markID

			break
		end

		self.rightDownPanel:get("cardIcon"):hide()
		self.rightDownPanel:get("itemIcon"):show()
		bind.extend(self, self.rightDownPanel:get("itemIcon"), {
			class = "icon_key",
			props = {
				data = {
					key = game.UNKONW_CARD_ID,
					num = tempID
				},
				onNode = function(node)
					return
				end
			}
		})
		self.rightDownPanel:get("txt"):hide()
		self.rightDownPanel:get("txt"):parent():removeChildByName("buyTimesRichTip")

		local str = string.format(gLanguageCsv.megaAssistNoCardTaskTip, taskCfg.taskParam, taskCfg.taskParam)
		local rich = rich.createByStr(str, 36):xy(self.rightDownPanel:get("txt"):xy()):anchorPoint(0, 0.5):addTo(self.rightDownPanel:get("txt"):parent(), 5, "buyTimesRichTip")
	else
		self.rightDownPanel:get("cardIcon"):show()
		self.rightDownPanel:get("itemIcon"):hide()

		local cardCfg = csv.cards[self.selectMarkID:read()]
		local unitID = cardCfg.unitID
		local unitCfg = csv.unit[unitID]
		local yyData = self.yyhuodongs:read()[self.activityID] or {}
		local stamps1 = yyData.stamps1 or {}
		local hasRecieve = false

		if stamps1[taskCsvID] == 0 then
			hasRecieve = true
		end

		local grayState = hasRecieve and 1 or 0

		bind.extend(self, self.rightDownPanel:get("cardIcon"), {
			class = "card_icon",
			props = {
				unitId = unitID,
				rarity = unitCfg.rarity,
				star = cardCfg.star,
				grayState = grayState,
				onNode = function(node)
					node:removeChildByName("recieveTick")

					if hasRecieve then
						ccui.ImageView:create("city/card/evolution/logo_tick1.png"):alignCenter(node:size()):scale(1.5):addTo(node, 10000, "recieveTick")
					end
				end
			}
		})

		local valsums = yyData.valsums or {}
		local count = 0

		for csvID, v in pairs(valsums) do
			local megaAssistCfg = csv.yunying.mega_assist[csvID]

			if megaAssistCfg.taskType == 1 then
				count = count + v
			end
		end

		self.rightDownPanel:get("txt"):hide()
		self.rightDownPanel:get("txt"):parent():removeChildByName("buyTimesRichTip")

		local str = string.format(gLanguageCsv.megaAssistTaskTip, taskCfg.taskParam, count, taskCfg.taskParam)
		local rich = rich.createByStr(str, 36):xy(self.rightDownPanel:get("txt"):xy()):anchorPoint(0, 0.5):addTo(self.rightDownPanel:get("txt"):parent(), 5, "buyTimesRichTip")

		self.rightDownPanel:removeChildByName("cardAwardSpine")

		if stamps1[taskCsvID] == 1 then
			uiEasy.addVibrateToNode(self, self.rightDownPanel:get("cardIcon"), true, "cardTag")

			local itemCfg = dataEasy.getCfgByKey(501)

			widget.addAnimationByKey(self.rightDownPanel, "effect/jiedianjiangli.skel", "cardAwardSpine", "effect_loop", self.rightDownPanel:get("cardIcon"):z() - 1):xy(self.rightDownPanel:get("cardIcon"):x(), self.rightDownPanel:get("cardIcon"):y() - 70):scale(0.8)
			bind.touch(self, self.rightDownPanel:get("cardIcon"), {
				methods = {
					ended = function()
						self:onAwardGet(taskCsvID)
					end
				}
			})
		else
			uiEasy.addVibrateToNode(self, self.rightDownPanel:get("cardIcon"), false, "cardTag")
			bind.touch(self, self.rightDownPanel:get("cardIcon"), {
				methods = {
					ended = function()
						gGameUI:showItemDetail(self.rightDownPanel:get("cardIcon"), {
							key = "card",
							num = self.selectMarkID:read()
						})
					end
				}
			})
		end
	end
end

function MegaAssistView:onAwardGet(csvID)
	gGameApp:requestServer("/game/yy/award/get", function(tb)
		gGameUI:showGainDisplay(tb)
	end, self.activityID, csvID)
end

function MegaAssistView:getBarPercent(t)
	if self.starNum == 0 then
		return 0
	end

	if self.starNum <= t[1] then
		return 0
	end

	local lastStar = t[1]
	local oncePercent = 100 / (#t - 1)
	local idx = 0

	for i, star in ipairs(t) do
		if star > self.starNum then
			local percent = oncePercent * (idx - 1)

			return percent
		else
			idx = idx + 1
			lastStar = t[i]
		end
	end

	return 100
end

function MegaAssistView:onAddClick()
	gGameUI:stackUI("city.card.mega.mega_assist.card_select", nil, nil, self.activityID, nil, self:createHandler("onSelectCard"))
end

function MegaAssistView:onRuleClick()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1500
	})
end

function MegaAssistView:getRuleContext(view)
	local c = adaptContext
	local context = {
		c.noteText(136901, 137000)
	}

	return context
end

function MegaAssistView:onChangeClick()
	gGameUI:stackUI("city.card.mega.mega_assist.card_select", nil, nil, self.activityID, self.selectMarkID:read(), self:createHandler("onSelectCard"))
end

function MegaAssistView:onExclusiveClick()
	gGameUI:stackUI("city.card.mega.mega_assist.exclusive_gift", nil, nil, self.activityID)
end

function MegaAssistView:onLockClick()
	local cardCfg = csv.cards[self.selectMarkID:read()]
	local str = string.format(gLanguageCsv.megaAssistLockTip, cardCfg.name)

	gGameUI:showDialog({
		isRich = true,
		clearFast = true,
		btnType = 2,
		cb = function()
			gGameApp:requestServer("/game/yy/mega/assist/lock", function(tb)
				gGameUI:showTip(gLanguageCsv.megaAssistLockSuccess)
			end, self.activityID, self.selectMarkID:read())
		end,
		content = str
	})
end

function MegaAssistView:onSelectCard(selectMarkID)
	self.selectMarkID:set(selectMarkID)
	gGameUI:showTip(gLanguageCsv.megaAssistSureTip)
end

function MegaAssistView:onOneKeyClick()
	gGameApp:requestServer("/game/yy/award/get/onekey", function(tb)
		gGameUI:showGainDisplay(tb.view.result.items, {
			noSort = true,
			raw = false
		})
	end, self.activityID)
end

function MegaAssistView:onBuyClick(list, k, v)
	if not v.hasLock then
		gGameUI:showTip(gLanguageCsv.megaAssistUnlockTips)

		return
	end

	gGameApp:payDirect(self, {
		rechargeId = v.cfg.rechargeID,
		yyID = self.activityID,
		csvID = v.csvID,
		name = v.cfg.name,
		buyTimes = v.buyTimes
	}, self.clientBuyTimes):doit()
end

return MegaAssistView
