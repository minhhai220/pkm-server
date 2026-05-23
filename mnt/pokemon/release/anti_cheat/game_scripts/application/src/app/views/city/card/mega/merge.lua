-- chunkname: @src.app.views.city.card.mega.merge

local OUT_LINE = {
	binds = {
		event = "effect",
		data = {
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		}
	}
}

local function getCmpKey(key)
	local id = dataEasy.stringMapingID(key)
	local cfg = csv.card_mega_convert[id]

	if not cfg then
		return 0
	end

	return cfg.type
end

local ViewBase = cc.load("mvc").ViewBase
local MegaMergeView = class("MegaMergeView", cc.load("mvc").ViewBase)

MegaMergeView.RESOURCE_FILENAME = "card_mega_merge.json"
MegaMergeView.RESOURCE_BINDING = {
	["itemPanel.attrItem"] = "attrItem",
	megaOk = "megaOk",
	["itemPanel.starItem"] = "starItem",
	["rightPanel.item"] = "rightItem",
	rightPanel = "rightPanel",
	animaCard = "animaCard",
	itemPanel = "itemPanel",
	bg = "bg",
	panel = "panel",
	book = {
		varname = "handbook",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("bookFunc")
			}
		}
	},
	["book.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["rightPanel.rule"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("ruleFunc")
			}
		}
	},
	["rightPanel.list"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("rightDatas"),
				item = bindHelper.self("rightItem"),
				dataOrderCmp = function(a, b)
					local ka = getCmpKey(a.key)
					local kb = getCmpKey(b.key)

					if ka ~= kb then
						return ka < kb
					end

					return dataEasy.stringMapingID(a.key) < dataEasy.stringMapingID(b.key)
				end,
				onItem = function(list, node, k, v)
					local childs = node:multiget("item", "btn", "num1", "num2")

					itertools.invoke({
						childs.btn,
						childs.num1,
						childs.num2
					}, "hide")

					local num = v.selectNum
					local isEnough = num >= v.val

					childs.item:get("add"):visible(not isEnough)
					bind.extend(list, childs.item, {
						class = "icon_key",
						props = {
							noListener = true,
							grayState = isEnough and 0 or 1,
							data = {
								key = v.key,
								num = num,
								targetNum = v.val
							},
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end
						}
					})
					bind.touch(list, childs.item, {
						methods = {
							ended = function()
								jumpEasy.jumpTo("gainWay", v.key, nil, v.val)
							end
						}
					})

					local isMegaConversion = csv.card_mega_convert[v.key]

					childs.btn:hide()

					if isMegaConversion then
						childs.btn:show()
						bind.touch(list, childs.btn, {
							methods = {
								ended = function()
									gGameUI:stackUI("city.card.mega.conversion", nil, nil, {
										id = v.key,
										num = v.val
									})
								end
							}
						})
					end
				end,
				onAfterBuild = function(list)
					list:refreshView()

					local count = list:getChildrenCount()

					if count > 0 and count < 4 then
						local t = {
							0,
							80,
							40
						}

						list:setItemsMargin(t[count])
					else
						list:setItemsMargin(0)
					end

					list:setItemAlignCenter()
				end
			}
		}
	},
	["rightPanel.card1.item"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:chooseCard(1)
				end)
			}
		}
	},
	["rightPanel.card2.item"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:chooseCard(2)
				end)
			}
		}
	},
	btn = {
		varname = "btn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnClick")
			}
		}
	},
	["itemPanel.starList"] = {
		varname = "starList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("cardStarData"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("star"):texture(v.icon)
				end
			}
		}
	},
	["itemPanel.attrList"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					node:texture(ui.ATTR_ICON[v]):scale(0.8)
				end
			}
		}
	},
	["rightPanel.card1.textStartNote"] = OUT_LINE,
	["rightPanel.card1.textStart2"] = OUT_LINE,
	["rightPanel.card1.textIndividualNote"] = OUT_LINE,
	["rightPanel.card1.textIndividual2"] = OUT_LINE,
	["rightPanel.card1.textFeelNote"] = OUT_LINE,
	["rightPanel.card1.textFeel2"] = OUT_LINE,
	["rightPanel.card1.textFightNote"] = OUT_LINE,
	["rightPanel.card1.textFight2"] = OUT_LINE,
	["rightPanel.card1.textTip"] = OUT_LINE,
	["rightPanel.card1.textTip2"] = OUT_LINE,
	["rightPanel.card2.textStartNote"] = OUT_LINE,
	["rightPanel.card2.textStart2"] = OUT_LINE,
	["rightPanel.card2.textIndividualNote"] = OUT_LINE,
	["rightPanel.card2.textIndividual2"] = OUT_LINE,
	["rightPanel.card2.textFeelNote"] = OUT_LINE,
	["rightPanel.card2.textFeel2"] = OUT_LINE,
	["rightPanel.card2.textFightNote"] = OUT_LINE,
	["rightPanel.card2.textFight2"] = OUT_LINE,
	["rightPanel.card2.textTip"] = OUT_LINE,
	["rightPanel.card2.textTip2"] = OUT_LINE,
	["rightPanel.textTip2"] = OUT_LINE,
	["panel.txt1"] = OUT_LINE,
	["panel.gold"] = OUT_LINE,
	megaAssist = {
		varname = "megaAssist",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onMegaAssistClick")
				}
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = "megaAssist",
					listenData = {
						activityId = bindHelper.self("megaAssistActivityID")
					},
					onNode = function(node)
						node:xy(400, 100)
						node:scale(0.6)
					end
				}
			}
		}
	}
}

function MegaMergeView:onCreate(megaIndex, cb)
	self.topUi = gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "EVOLUTION MEGA",
		title = gLanguageCsv.megaHouse
	})
	self.megaIndex = megaIndex
	self.cfg = csv.card_mega[megaIndex]
	self.cb = cb
	self.cardID = self.cfg.mergeCardID

	local cardCfg = csv.cards[self.cardID]
	local markID = cardCfg.cardMarkID
	local roleCardMerge = gGameModel.role:read("card_merge") or {}

	roleCardMerge = roleCardMerge[markID] or {}
	self.roleCardMerge = roleCardMerge

	local dbid = self.roleCardMerge.id
	local cardData = gGameModel.cards:find(dbid)

	self.megaOk:hide()

	if self.roleCardMerge.unlock_route and self.roleCardMerge.unlock_route[self.cardID] then
		self.megaOk:show()
	end

	local unitCfg = csv.unit[cardCfg.unitID]

	widget.addAnimation(self.animaCard, unitCfg.unitRes, "standby_loop", 5):alignCenter(self.animaCard:size()):scale(unitCfg.scaleU * 3):y(-100):setSkin(unitCfg.skin)

	self.attrDatas = idlers.newWithMap({})
	self.cardStarData = idlers.new({})

	self.itemPanel:get("icon"):texture(ui.RARITY_ICON[unitCfg.rarity])

	local attrDatas = {}

	table.insert(attrDatas, unitCfg.natureType)

	if unitCfg.natureType2 then
		table.insert(attrDatas, unitCfg.natureType2)
	end

	self.attrDatas:update(attrDatas)
	self.starList:show()

	local card = gGameModel.cards:find(dbid)
	local star = cardCfg.star
	local advance

	if dbid then
		star = cardData:read("star")
		advance = cardData:read("advance")
	end

	uiEasy.setIconName("card", self.cardID, {
		space = true,
		node = self.itemPanel:get("name"),
		advance = advance
	})

	local cardStarData = {}
	local starIdx = star - 6

	for i = 1, 6 do
		local icon = "common/icon/icon_star_d.png"

		if i <= star then
			icon = i <= starIdx and "common/icon/icon_star_z.png" or "common/icon/icon_star.png"
		end

		table.insert(cardStarData, {
			icon = icon
		})
	end

	self.cardStarData:update(cardStarData)

	self.cardDbids = {}
	self.rightDatas = idlers.newWithMap({})
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.gold = gGameModel.role:getIdler("gold")

	idlereasy.any({
		self.items,
		self.frags
	}, function()
		local data = {}
		local costCfg

		if not dbid then
			self.flag = "new"
			costCfg = self.cfg.costItems
		elseif not self.roleCardMerge.unlock_route[self.cardID] then
			self.flag = "route"
			costCfg = self.cfg.mergeRouteCost
		else
			self.flag = "recover"
			costCfg = self.cfg.mergeRecoverCost
		end

		self.costCfg = costCfg
		self.costGold = costCfg.gold

		for key, v in csvMapPairs(costCfg) do
			if key ~= "gold" then
				table.insert(data, {
					key = key,
					val = v,
					selectNum = dataEasy.getNumByKey(key)
				})
			end
		end

		self.rightDatas:update(data)
		self:costGoldUpdate()
		self:cardItemUpdate()
		self:setBtnState()
	end)
	idlereasy.when(self.gold, functools.partial(self.costGoldUpdate, self))

	self.megaAssistActivityID = 0
	-- 标记 暂时关闭助力活动
	-- idlereasy.when(gGameModel.role:getIdler("yy_open"), function(_, yyOpen)
	-- 	self.megaAssist:hide()
	-- 	self.megaAssist:removeChildByName("megaAssistSpine")

	-- 	for _, id in pairs(yyOpen) do
	-- 		local yyCfg = csv.yunying.yyhuodong[id]

	-- 		if yyCfg.type == game.YYHUODONG_TYPE_ENUM_TABLE.megaAssist then
	-- 			self.megaAssistActivityID = id

	-- 			self.megaAssist:show()

	-- 			local size = self.megaAssist:size()

	-- 			widget.addAnimationByKey(self.megaAssist, "megasupport/zhulihuodong.skel", "megaAssistSpine", "zhulihuodong_loop", 5):xy(size.width / 2 - 100, size.height / 2):scale(3)

	-- 			break
	-- 		end
	-- 	end
	-- end)
	self.bg:hide()
	widget.addAnimationByKey(self:getResourceNode(), "chaojinhua/hbl_dx2.skel", "mergeBg", "effect_loop", 0):alignCenter(self:getResourceNode():size()):scale(2)
end

function MegaMergeView:costGoldUpdate()
	self.panel:hide()

	if self.costGold and self.costGold > 0 then
		self.panel:show()
		self.panel:get("gold"):text(self.costGold)

		local roleGold = gGameModel.role:read("gold")

		text.addEffect(self.panel:get("gold"), {
			color = roleGold >= self.costGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE
		})
		adapt.oneLineCenterPos(cc.p(400, 40), {
			self.panel:get("txt1"),
			self.panel:get("gold"),
			self.panel:get("icon")
		}, cc.p(8, 0))
	end
end

function MegaMergeView:setBtnState()
	if self.flag == "recover" then
		self.btn:get("txt"):text(gLanguageCsv.cardMerge)
	else
		self.btn:get("txt"):text(self.cfg.specialData.btnName)
	end
end

function MegaMergeView:onBtnClick()
	if itertools.size(self.cardDbids) < csvSize(self.cfg.card) then
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)

		return
	end

	local cardCapacity = gGameModel.role:read("card_volume")
	local cards = gGameModel.role:read("cards")

	if self.flag == "new" and cardCapacity <= #cards then
		gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)

		return
	end

	for i = 1, 2 do
		local cardId = self.cfg.card[i][1]
		local req = self.cfg.mergeReq[i]
		local dbid = self.cardDbids[i]
		local card = gGameModel.cards:find(dbid)
		local fight = card:read("fighting_point")
		local starNum = card:read("star")
		local nvalue = card:read("nvalue")
		local nvalueSum = 0

		for k, v in pairs(nvalue) do
			nvalueSum = nvalueSum + v
		end

		local markId = csv.cards[cardId].cardMarkID
		local cardFeel = gGameModel.role:read("card_feels")[markId] or {}
		local goodFeel = cardFeel.level or 0

		if starNum < req.star or nvalueSum < req.nvalueSum or goodFeel < req.goodFeel or fight < req.fightPoint then
			gGameUI:showTip(gLanguageCsv.cardMergeNotEnoughTips)

			return
		end
	end

	local roleGold = gGameModel.role:read("gold")

	if self.costGold and roleGold < self.costGold then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)

		return
	end

	for key, val in csvMapPairs(self.costCfg) do
		if key ~= "gold" then
			local num = dataEasy.getNumByKey(key)

			if num < val then
				gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

				return
			end
		end
	end

	self:addCallbackOnExit(functools.partial(self.cb, self.flag, self.megaIndex, self.cardDbids))
	self:onClose()
end

function MegaMergeView:cardItemUpdate()
	for i = 1, 2 do
		local node = self.rightPanel:get("card" .. i)
		local cardId, star = self.cfg.card[i][1], self.cfg.card[i][2]
		local markId = csv.cards[cardId].cardMarkID
		local starNum = 0
		local skinId = 0
		local goodFeel = 0
		local fight = 0
		local unitID = csv.cards[cardId].unitID
		local unitCfg = csv.unit[unitID]
		local rarity = unitCfg.rarity
		local advance = false
		local level = false
		local nvalueSum = 0
		local dbid = self.cardDbids[i]

		if dbid then
			local card = gGameModel.cards:find(dbid)

			cardId = card:read("card_id")
			skinId = card:read("skin_id")
			star = card:read("star")
			advance = card:read("advance")
			level = card:read("level")
			fight = card:read("fighting_point")
			starNum = card:read("star")

			local nvalue = card:read("nvalue")

			for k, v in pairs(nvalue) do
				nvalueSum = nvalueSum + v
			end

			local cardFeel = gGameModel.role:read("card_feels")[markId] or {}

			goodFeel = cardFeel.level or 0
			unitID = dataEasy.getUnitId(cardId, skinId)
		end

		local textStartNote = node:get("textStartNote")
		local textStart = node:get("textStart")
		local textStart2 = node:get("textStart2")
		local imgStar = node:get("imgStar")
		local imgStar2 = node:get("imgStar2")
		local textIndividualNote = node:get("textIndividualNote")
		local textIndividual = node:get("textIndividual")
		local textIndividual2 = node:get("textIndividual2")
		local textFeelNote = node:get("textFeelNote")
		local textFeel = node:get("textFeel")
		local textFeel2 = node:get("textFeel2")
		local textFightNote = node:get("textFightNote")
		local textFight = node:get("textFight")
		local textFight2 = node:get("textFight2")

		textStart:text(starNum)
		textIndividual:text(nvalueSum)
		textFeel:text(goodFeel)
		textFight:text(fight)

		local req = self.cfg.mergeReq[i]

		textStart2:text("/" .. req.star)
		textIndividual2:text("/" .. req.nvalueSum)
		textFeel2:text("/" .. req.goodFeel)
		textFight2:text("/" .. req.fightPoint)
		text.addEffect(textStart, {
			color = starNum >= req.star and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textIndividual, {
			color = nvalueSum >= req.nvalueSum and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textFeel, {
			color = goodFeel >= req.goodFeel and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textFight, {
			color = fight >= req.fightPoint and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		adapt.oneLinePos(textStartNote, {
			textStart,
			imgStar,
			textStart2,
			imgStar2
		}, cc.p(0, 0), "left")
		adapt.oneLinePos(textIndividualNote, {
			textIndividual,
			textIndividual2
		}, cc.p(0, 0), "left")
		adapt.oneLinePos(textFeelNote, {
			textFeel,
			textFeel2
		}, cc.p(0, 0), "left")
		adapt.oneLinePos(textFightNote, {
			textFight,
			textFight2
		}, cc.p(0, 0), "left")
		node:get("item.add"):visible(dbid == nil)

		local item = node:get("item")

		bind.extend(self, item, {
			class = "card_icon",
			props = {
				unitId = unitID,
				star = star,
				rarity = rarity,
				advance = advance,
				levelProps = {
					data = level
				},
				grayState = dbid and 0 or 1,
				onNode = function(node)
					node:scale(1.3)
					node:alignCenter(item:size())
				end
			}
		})
	end
end

function MegaMergeView:bookFunc()
	gGameUI:stackUI("city.handbook.view", nil, {
		full = true
	}, {
		cardId = self.cardID
	})
end

function MegaMergeView:ruleFunc()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1300
	})
end

function MegaMergeView:getRuleContext(view)
	local content = {
		self.cfg.rules[1],
		self.cfg.rules[2]
	}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.cardMerge)
		end),
		c.noteText(unpack(content))
	}

	return context
end

function MegaMergeView:chooseCard(k)
	self.selectedData = {
		key = "main",
		idx = k,
		cardId = self.cfg.card[k][1],
		megaIndex = self.megaIndex,
		subCardData = {}
	}
	self.selectedData.cardDbid = self.cardDbids[k]

	gGameUI:stackUI("city.card.mega.choose_card", nil, nil, self.selectedData, self:createHandler("itemCallback", k))
end

function MegaMergeView:itemCallback(k)
	self.cardDbids[k] = self.selectedData.cardDbid

	self:cardItemUpdate()
end

function MegaMergeView:onMegaAssistClick()
	gGameUI:stackUI("city.card.mega.mega_assist.view", nil, {
		full = true
	}, self.megaAssistActivityID)
end

return MegaMergeView
