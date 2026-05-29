-- chunkname: @src.app.views.city.card.mega.view

local ViewBase = cc.load("mvc").ViewBase
local zawakeTools = require("app.views.city.zawake.tools")
local MegaView = class("MegaView", cc.load("mvc").ViewBase)
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

local function sortFunc(a, b)
	if a.whetherMega ~= b.whetherMega then
		return a.whetherMega > b.whetherMega
	end

	if a.unitCfg.rarity ~= b.unitCfg.rarity then
		return a.unitCfg.rarity > b.unitCfg.rarity
	end

	return a.id < b.id
end

MegaView.RESOURCE_FILENAME = "card_mega.json"
MegaView.RESOURCE_BINDING = {
	itemPanel = "itemPanel",
	item = "item",
	bg = "bg",
	panel = "panel",
	expectPanel = "expectPanel",
	mergePanel = "mergePanel",
	["rightPanel.item"] = "rightItem",
	rightPanel = "rightPanel",
	titlePanel = "titlePanel",
	megaOk = "megaOk",
	anima = "anima",
	animaCard = "animaCard",
	["itemPanel.attrItem"] = "attrItem",
	btn2 = "conversion2",
	btn1 = "conversion1",
	["itemPanel.starItem"] = "starItem",
	["rightPanelFetter.item"] = "rightFetterItem",
	rightPanelFetter = "rightPanelFetter",
	list = {
		varname = "list",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("item"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					if v.type then
						node:get("classify"):show()
						node:get("item"):hide()
						node:height(node:get("classify"):height())
						node:get("classify"):y(node:height() / 2)

						if v.type == 0 then
							node:get("classify.normal.txt"):text(gLanguageCsv.megaTitle2)
							node:get("classify.selected.txt"):text(gLanguageCsv.megaTitle2)
						elseif v.type == 1 then
							node:get("classify.normal.txt"):text(gLanguageCsv.megaTitle1)
							node:get("classify.selected.txt"):text(gLanguageCsv.megaTitle1)
						elseif v.type == 2 then
							node:get("classify.normal.txt"):text(gLanguageCsv.megaTitle3)
							node:get("classify.selected.txt"):text(gLanguageCsv.megaTitle3)
						else
							node:get("classify.normal.txt"):text(gLanguageCsv.megaTitle4)
							node:get("classify.selected.txt"):text(gLanguageCsv.megaTitle4)
						end

						adapt.setTextScaleWithWidth(node:get("classify.normal.txt"), nil, 150)
						adapt.setTextScaleWithWidth(node:get("classify.selected.txt"), nil, 150)

						if v.open then
							node:get("classify.selected"):show()
							node:get("classify.normal"):hide()
						else
							node:get("classify.selected"):hide()
							node:get("classify.normal"):show()
						end

						bind.touch(list, node:get("classify"), {
							methods = {
								ended = functools.partial(list.onClassifyItemClick, k, v)
							}
						})
					elseif v.open == false then
						node:hide()
						node:height(0)
					else
						node:get("classify"):hide()
						node:get("item"):show()
						node:height(node:get("item"):height())

						local mergeInfo = dataEasy.getCardMergeInfo()
						local grayState = v.isHas and 0 or 2
						local item = node:get("item")

						item:removeChildByName("textNote")

						if mergeInfo.relieveC[v.dbid] then
							grayState = 1

							local textNote = label.create(gLanguageCsv.inRelieve, {
								fontSize = 36,
								fontPath = "font/youmi1.ttf"
							}):addTo(item, 9, "textNote"):alignCenter(item:size()):x(item:width() / 2)

							uiEasy.addTextEffect1(textNote)
						end

						bind.extend(list, item, {
							class = "card_icon",
							props = {
								unitId = v.unitCfg.id,
								rarity = v.unitCfg.rarity,
								grayState = grayState,
								onNode = function(panel)
									panel:xy(20, 10):z(5)
								end
							}
						})
						node:get("item.select"):visible(v.isSel)
						node:get("item.hint"):visible(not v.canDevelop)
						bind.extend(list, node, {
							class = "red_hint",
							props = {
								specialTag = "cardMega",
								state = not v.isSel,
								listenData = {
									megaId = v.id
								},
								onNode = function(node)
									node:xy(200, 180)
								end
							}
						})
						bind.touch(list, node:get("item"), {
							methods = {
								ended = functools.partial(list.onClickCell, k, v)
							}
						})
					end
				end
			},
			handlers = {
				onClickCell = bindHelper.self("onTabItemClick"),
				onClassifyItemClick = bindHelper.self("onClassifyItemClick")
			}
		}
	},
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
	["panel.txt1"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["panel.gold"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["titlePanel.num"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
	["titlePanel.textFetter"] = {
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
	["rightPanel.card.item"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:chooseCard()
				end)
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

					if v.costCards then
						local num = itertools.size(v.subCardData)
						local isEnough = num >= v.costCards.num

						childs.item:get("add"):visible(not isEnough)
						childs.num1:show():text(num)
						childs.num2:show():text("/" .. v.costCards.num)
						text.addEffect(childs.num1, {
							color = isEnough and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						text.addEffect(childs.num2, {
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						adapt.oneLineCenterPos(cc.p(105, 100), {
							childs.num1,
							childs.num2
						})

						local cardId = v.costCards.markID or 1
						local unitID = csv.cards[cardId].unitID
						local unitCfg = csv.unit[unitID]

						bind.extend(list, childs.item, {
							class = "card_icon",
							props = {
								cardId = cardId,
								star = v.costCards.star,
								rarity = unitCfg.rarity,
								grayState = isEnough and 0 or 1,
								onNode = function(node)
									if not v.costCards.markID then
										node:getChildByName("icon"):texture("config/item/icon_sjjl.png")
									end
								end
							}
						})
						bind.touch(list, childs.item, {
							methods = {
								ended = function()
									list.chooseCard(k, v)
								end
							}
						})
					else
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
			},
			handlers = {
				chooseCard = bindHelper.self("chooseCard")
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
	["rightPanel.card.item"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:chooseCard()
				end)
			}
		}
	},
	["rightPanelFetter.rule"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("ruleFetterFunc")
			}
		}
	},
	["rightPanelFetter.list"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("rightDatas"),
				item = bindHelper.self("rightFetterItem"),
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

					if v.costCards then
						local num = itertools.size(v.subCardData)
						local isEnough = num >= v.costCards.num

						childs.item:get("add"):visible(not isEnough)
						childs.num1:show():text(num)
						childs.num2:show():text("/" .. v.costCards.num)
						text.addEffect(childs.num1, {
							color = isEnough and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						text.addEffect(childs.num2, {
							outline = {
								color = ui.COLORS.NORMAL.WHITE
							}
						})
						adapt.oneLineCenterPos(cc.p(105, 100), {
							childs.num1,
							childs.num2
						})

						local cardId = v.costCards.markID or 1
						local unitID = csv.cards[cardId].unitID
						local unitCfg = csv.unit[unitID]

						bind.extend(list, childs.item, {
							class = "card_icon",
							props = {
								cardId = cardId,
								star = v.costCards.star,
								rarity = unitCfg.rarity,
								grayState = isEnough and 0 or 1,
								onNode = function(node)
									if not v.costCards.markID then
										node:getChildByName("icon"):texture("config/item/icon_sjjl.png")
									end
								end
							}
						})
						bind.touch(list, childs.item, {
							methods = {
								ended = function()
									list.chooseCard(k, v)
								end
							}
						})
					else
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
					end
				end,
				onAfterBuild = function(list)
					list:refreshView()

					local count = list:getChildrenCount()

					if count > 0 and count < 5 then
						local t = {
							0,
							80,
							40,
							0
						}

						list:setItemsMargin(t[count])
					else
						list:setItemsMargin(0)
					end

					list:setItemAlignCenter()
				end
			},
			handlers = {
				chooseCard = bindHelper.self("chooseCard")
			}
		}
	},
	["rightPanelFetter.card.item"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:chooseCard()
				end)
			}
		}
	},
	btn = {
		varname = "conversion",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("conversionClick")
			}
		}
	},
	btnBranch = {
		varname = "btnBranch",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnBranchClick")
			}
		}
	},
	btnFetter = {
		varname = "btnFetter",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("conversionFetterClick")
			}
		}
	},
	["rightPanelFetter.textStartNote"] = OUT_LINE,
	["rightPanelFetter.textStart2"] = OUT_LINE,
	["rightPanelFetter.textIndividualNote"] = OUT_LINE,
	["rightPanelFetter.textIndividual2"] = OUT_LINE,
	["rightPanelFetter.textFeelNote"] = OUT_LINE,
	["rightPanelFetter.textFeel2"] = OUT_LINE,
	["rightPanelFetter.textFightNote"] = OUT_LINE,
	["rightPanelFetter.textFight2"] = OUT_LINE,
	["rightPanelFetter.textTip"] = OUT_LINE,
	["rightPanelFetter.textTip2"] = OUT_LINE,
	["mergePanel.rule"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("ruleFunc")
			}
		}
	},
	["mergePanel.midPanel.book"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("bookFunc")
			}
		}
	},
	["mergePanel.midPanel.book.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	},
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

function MegaView:onCreate(cardId, cb)
	self.topUi = gGameUI.topuiManager:createView("default", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "EVOLUTION MEGA",
		title = gLanguageCsv.megaHouse
	})

	self:initModel()
	self:enableSchedule()
	self.anima:hide()

	self.cardId = cardId
	self.cb = cb
	self.originItemPanelPos = cc.p(self.itemPanel:xy())
	self.attrDatas = idlers.newWithMap({})
	self.rightDatas = idlers.newWithMap({})
	self.selectedData = {}
	self.tabDatas = idlers.new({})
	self.cardSelected = idler.new(2)
	self.cardStarData = idlers.new({})
	self.isRefresh = idler.new(true)

	idlereasy.any({
		self.cards,
		self.items,
		self.frags,
		self.isRefresh
	}, function(_, cards)
		local data = {}
		local cardIdData = {}

		for _, dbid in ipairs(cards) do
			local card = gGameModel.cards:find(dbid)

			if card then
				local cardId = card:read("card_id")

				cardIdData[cardId] = dbid
			end
		end

		for i, v in pairs(gCardsMega) do
			if csv.card_mega[i] then
				local cardCsv = csv.cards[v.key]
				local unitCfg = csv.unit[cardCsv.unitID]
				local type = csv.card_mega[i].type

				table.insert(data, {
					open = true,
					isSel = false,
					id = v.key,
					unitCfg = unitCfg,
					canDevelop = v.canDevelop,
					whetherMega = v.canDevelop and 1 or 0,
					isHas = cardIdData[v.key] ~= nil,
					dbid = cardIdData[v.key],
					megaIndex = i,
					markId = cardCsv.cardMarkID,
					megaType = type,
					showType = csv.card_mega[i].showType,
					cfg = csv.card_mega[i]
				})
			end
		end

		local tmp = {
			[0] = {},
			{},
			{},
			{}
		}

		for i, v in pairs(data) do
			if not v.specialMega then
				local showType = v.cfg.showType

				if v.cfg.type == 2 then
					v.specialMega = true

					local canDevelopCount = v.canDevelop and 1 or 0
					local specialData = {
						v
					}

					for j, vv in pairs(data) do
						if vv.cfg.type == 2 and not vv.specialMega and itertools.equal(v.cfg.card[1], vv.cfg.card[1]) then
							vv.specialMega = true
							canDevelopCount = canDevelopCount + (vv.canDevelop and 1 or 0)

							table.insert(specialData, vv)

							break
						end
					end

					if canDevelopCount <= 1 then
						for _, vv in ipairs(specialData) do
							vv.megaType = 0
							vv.showType = 0

							table.insert(tmp[0], vv)
						end
					else
						local megaIndexes = {
							specialData[1].megaIndex,
							specialData[2].megaIndex
						}

						table.sort(megaIndexes, function(a, b)
							return a < b
						end)

						local singleData = specialData[1]

						if specialData[2].isHas then
							singleData = specialData[2]
						end

						singleData.unitCfg = csv.unit[singleData.cfg.specialUnitID]
						singleData.megaIndexes = megaIndexes
						singleData.id = gCardsMega[megaIndexes[1]].key
						singleData.id2 = gCardsMega[megaIndexes[2]].key

						table.insert(tmp[showType], singleData)
					end
				elseif v.cfg.type == 3 then
					v.specialMega = true

					local singleData = v

					for j, vv in pairs(data) do
						if vv.cfg.type == 3 and not vv.specialMega and itertools.equal(v.cfg.card[1], vv.cfg.card[1]) then
							vv.specialMega = true

							if vv.isHas then
								singleData = vv
							end

							break
						end
					end

					singleData.isHas = false

					local roleCardMerge = gGameModel.role:read("card_merge") or {}
					
					roleCardMerge = roleCardMerge[singleData.markId] or {}
					roleCardMerge.merge_cards = roleCardMerge.merge_cards or {}  -- <- 保证为 table
					if itertools.size(roleCardMerge.merge_cards) > 0 then
						singleData.isHas = true
					end

					local megaIndexes = {
						singleData.megaIndex
					}

					for id, vv in orderCsvPairs(csv.card_mega) do
						if vv.type == 3 and id ~= singleData.megaIndex and itertools.equal(singleData.cfg.card[1], vv.card[1]) then
							table.insert(megaIndexes, id)

							break
						end
					end

					table.sort(megaIndexes, function(a, b)
						return a < b
					end)

					singleData.megaIndexes = megaIndexes
					singleData.unitCfg = csv.unit[singleData.cfg.specialUnitID]

					table.insert(tmp[showType], singleData)
				else
					table.insert(tmp[showType], v)
				end
			end
		end

		local tabDatas = {}

		for _, idx in ipairs({
			3,
			1,
			2,
			0
		}) do
			if not itertools.isempty(tmp[idx]) then
				table.sort(tmp[idx], sortFunc)
				table.insert(tabDatas, {
					open = true,
					type = idx
				})
				arraytools.merge_inplace(tabDatas, {
					tmp[idx]
				})
			end
		end

		dataEasy.tryCallFunc(self.list, "updatePreloadCenterIndexAdaptFirst")
		self.tabDatas:update(tabDatas)

		if self.cardId then
			local find = false

			for i, v in ipairs(tabDatas) do
				if v.id == self.cardId and (v.showType ~= 0 or v.canDevelop) then
					find = true

					self.cardSelected:set(i)

					break
				end
			end

			if not find then
				local markId = csv.cards[self.cardId].cardMarkID

				for i, v in ipairs(tabDatas) do
					if v.markId == markId and (v.showType ~= 0 or v.canDevelop) then
						find = true

						self.cardSelected:set(i)

						break
					end
				end
			end
		end

		local selected = self.cardSelected:read()

		self:onTabItemClick(nil, selected, self.tabDatas:atproxy(selected))
	end)

	self.mergeBg1 = widget.addAnimationByKey(self:getResourceNode(), "chaojinhua/hbl_dx.skel", "mergeBg1", "effect_loop", 0):alignCenter(self:getResourceNode():size()):scale(2)
	self.mergeBg2 = widget.addAnimationByKey(self:getResourceNode(), "chaojinhua/hbl_dx.skel", "mergeBg2", "effect2_loop", 0):alignCenter(self:getResourceNode():size()):scale(2)

	self.cardSelected:addListener(function(val, oldval)
		self.tabDatas:atproxy(oldval).isSel = false
		self.tabDatas:atproxy(val).isSel = true

		local data = self.tabDatas:atproxy(val)

		if data.cfg.type == 3 then
			local markID = data.markId
			local roleCardMerge = gGameModel.role:read("card_merge") or {}

			roleCardMerge = roleCardMerge[markID] or {}

			self.bg:hide()
			self.mergeBg1:show()

			if itertools.isempty(roleCardMerge.merge_cards) then
				self.mergeBg2:hide()
			else
				self.mergeBg2:show()
			end
		else
			self.bg:show()
			self.mergeBg1:hide()
			self.mergeBg2:hide()
		end
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
end

function MegaView:initModel()
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.cards = gGameModel.role:getIdler("cards")
	self.items = gGameModel.role:getIdler("items")
	self.frags = gGameModel.role:getIdler("frags")
	self.gold = gGameModel.role:getIdler("gold")
end

function MegaView:onMergePanel(k, v)
	self.cardSelected:set(k, true)
	self.mergePanel:show()
	self.mergePanel:removeChildByName("countDown")

	local childs = self.mergePanel:multiget("leftPanel", "rightPanel", "midPanel")

	itertools.invoke(childs, "hide")

	local data = self.tabDatas:atproxy(k)
	local markID = data.markId
	local roleCardMerge = gGameModel.role:read("card_merge") or {}

	roleCardMerge = roleCardMerge[markID] or {}

	local dbid
	local state = "canMerge"
	local endTime = 0

	if roleCardMerge.id then
		dbid = roleCardMerge.id
		endTime = (roleCardMerge.merge_recover_last_time or 0) + gCommonConfigCsv.cardMergeRecoverCD

		if not itertools.isempty(roleCardMerge.merge_cards) then
			state = "canBreak"
		elseif endTime - time.getTime() > 0 then
			state = "countDown"
		end
	end

	if endTime and endTime - time.getTime() > 0 then
		self:schedule(function()
			self.mergePanel:removeChildByName("countDown")

			local dt = endTime - time.getTime()
			local str = string.format("#C0xF76B45##L00100000##LOC0xFFFCED#%s #C0x5B545B##L00100000##LOC0xFFFCED#后可再次合体", time.getCutDown(dt, true).str)

			rich.createByStr(str, 44):xy(1720, 35):anchorPoint(0.5, 0.5):addTo(self.mergePanel, 11, "countDown")

			if dt <= 0 then
				performWithDelay(self, function()
					self.mergePanel:removeChildByName("countDown")
					self.isRefresh:notify()
				end, 1)

				return false
			end
		end, 1, 0, 1)
	end

	if state == "canBreak" then
		local panel = childs.midPanel:show()
		local cardData = gGameModel.cards:find(dbid):read("card_id", "unit_id", "skin_id", "fighting_point", "level", "star", "advance", "locked", "name", "created_time", "equips", "effort_values")
		local cardID = cardData.card_id
		local cardCfg = csv.cards[cardData.card_id]
		local unitCfg = csv.unit[cardCfg.unitID]
		local animaCard = panel:get("animaCard")

		animaCard:removeAllChildren()
		widget.addAnimation(animaCard, unitCfg.unitRes, "standby_loop", 5):alignCenter(animaCard:size()):scale(unitCfg.scaleU * 3):y(-100):setSkin(unitCfg.skin)
		animaCard:scale(0.9)
		text.addEffect(panel:get("tip"), {
			outline = {
				color = ui.COLORS.OUTLINE.WHITE
			}
		})
		bind.touch(self, panel:get("btn"), {
			methods = {
				ended = function()
					gGameUI:showDialog({
						btnType = 2,
						isRich = true,
						content = gLanguageCsv.cardRelieveTip,
						cb = function()
							self:conversionMergeClick("relieve", cardCfg.megaIndex)
						end
					})
				end
			}
		})
		self.itemPanel:show():x(self.originItemPanelPos.x + 500)
		self.itemPanel:get("icon"):texture(ui.RARITY_ICON[unitCfg.rarity])

		local attrDatas = {}

		table.insert(attrDatas, unitCfg.natureType)

		if unitCfg.natureType2 then
			table.insert(attrDatas, unitCfg.natureType2)
		end

		self.attrDatas:update(attrDatas)
		self.starList:show()

		self.selectedData = {
			key = "main",
			megaIndex = v.megaIndex
		}

		local card = gGameModel.cards:find(dbid)
		local star = card:read("star")
		local advance = card:read("advance")

		uiEasy.setIconName("card", cardID, {
			space = true,
			node = self.itemPanel:get("name"),
			advance = advance
		})
		self:cardStarUpdate(star)

		return
	end

	for i = 1, 2 do
		local megaIndex = data.megaIndexes[i]
		local panel = i == 1 and childs.leftPanel or childs.rightPanel

		panel:show()

		local animaCard = panel:get("animaCard")
		local cfg = csv.card_mega[megaIndex]
		local cardID = cfg.card[2][1]
		local unitCfg = csv.unit[csv.cards[cardID].unitID]

		animaCard:removeAllChildren()
		widget.addAnimation(animaCard, unitCfg.unitRes, "standby_loop", 5):alignCenter(animaCard:size()):scale(unitCfg.scaleU * 3):y(-100):setSkin(unitCfg.skin)
		animaCard:scale(0.9)

		if i == 2 then
			animaCard:setFlippedX(true)
		end

		local firstMerge = true

		panel:get("megaOk"):hide()

		if roleCardMerge.unlock_route and roleCardMerge.unlock_route[cfg.mergeCardID] then
			firstMerge = false

			panel:get("megaOk"):show()
		end

		panel:get("btn.txt"):text(cfg.specialData.btnName)
		panel:get("comingSoon"):show()
		uiEasy.setBtnShader(panel:get("btn"), panel:get("btn.txt"), 2)

		local megaCardID = gCardsMega[megaIndex] and gCardsMega[megaIndex].key

		if csv.cards[megaCardID] and csv.cards[megaCardID].canDevelop then
			panel:get("comingSoon"):hide()

			if state == "canMerge" or firstMerge then
				uiEasy.setBtnShader(panel:get("btn"), panel:get("btn.txt"), 1)
				bind.touch(self, panel:get("btn"), {
					methods = {
						ended = function()
							gGameUI:stackUI("city.card.mega.merge", nil, nil, megaIndex, self:createHandler("conversionMergeClick"))
						end
					}
				})
			end
		end
	end
end

function MegaView:onFetterPanelLock(k, v)
	self.expectPanel:show()

	self.selectedData = {
		key = "main",
		cardId = v.cfg.card[1],
		megaIndex = v.megaIndex,
		subCardData = {}
	}
	self.cardId = v.id

	self.cardSelected:set(k, true)

	if self.cardSprite then
		self.cardSprite:removeFromParent()

		self.cardSprite = nil
	end

	self.cardSprite = widget.addAnimation(self.animaCard, v.unitCfg.unitRes, "standby_loop", 5):alignCenter(self.animaCard:size()):scale(v.unitCfg.scaleU * 3):y(-100)

	self.itemPanel:get("icon"):texture(ui.RARITY_ICON[v.unitCfg.rarity])
	self.cardSprite:setSkin(v.unitCfg.skin)
	self:cardItemUpdate()

	local attrDatas = {}

	table.insert(attrDatas, v.unitCfg.natureType)

	if v.unitCfg.natureType2 then
		table.insert(attrDatas, v.unitCfg.natureType2)
	end

	self.attrDatas:update(attrDatas)
end

function MegaView:onTabItemClick(list, k, v)
	if not v.canDevelop and v.megaType == 0 then
		gGameUI:showTip(gLanguageCsv.comingSoon)

		return
	end

	self.conversion1:hide()
	self.conversion2:hide()
	self.btnBranch:hide()
	self.expectPanel:hide()

	self.isRouteUnlock = false

	self.conversion:get("txt"):text(gLanguageCsv.megaBtnTitle)
	self.btnBranch:parent():removeChildByName("routeUnlockAlready")

	self.cardId = v.id
	self.goldShow = false

	self.rightPanel:hide()
	self.rightPanelFetter:hide()
	self.megaOk:hide()
	self.panel:hide()
	self.conversion:hide()
	self.btnFetter:hide()
	self.titlePanel:hide()
	self.itemPanel:hide()
	self.animaCard:hide()
	self.handbook:hide()
	self.mergePanel:hide()
	self:unSchedule(1)

	if v.megaType == 3 then
		self:onMergePanel(k, v)

		if v.cfg.popRules then
			local key = "megaIndex" .. v.cfg.card[1][1]

			if not userDefault.getForeverLocalKey(key, false) then
				userDefault.setForeverLocalKey(key, true)
				self:ruleFunc()
			end
		end

		return
	end

	self.itemPanel:show()
	self.itemPanel:xy(self.originItemPanelPos)
	self.animaCard:show()
	self.handbook:show()

	if not v.canDevelop then
		if v.megaType == 1 then
			self:onFetterPanelLock(k, v)
		end

		return
	end

	self.goldShow = true

	self.panel:show()
	self.rightPanel:get("add"):show()
	self.rightPanel:get("list"):show()
	self.panel:show()
	self.titlePanel:show()

	if v.megaType == 1 then
		self.rightPanel:hide()
		self.rightPanelFetter:show()
		self.rightPanelFetter:get("textTip"):text(gLanguageCsv.fetterTips2)
		adapt.setTextAdaptWithSize(self.rightPanelFetter:get("textTip"), {
			maxLine = 2,
			horizontal = "left",
			vertical = "center",
			margin = -5,
			size = cc.size(950, 100)
		})
	else
		self.rightPanel:show()
		self.rightPanelFetter:hide()
	end

	self.megaOk:visible(v.isHas)

	local rightCardId = v.cfg.card[1]

	if v.megaType == 2 and v.isHas then
		self.isRouteUnlock = true
		rightCardId = {
			v.id,
			v.id2
		}
	end

	if k ~= self.cardSelected:read() or not self.selectedData.subCardData or not itertools.equal(self.selectedData.cardId, rightCardId) then
		self.selectedData = {
			key = "main",
			cardId = rightCardId,
			megaIndex = v.megaIndex,
			subCardData = {}
		}

		if v.megaType == 2 and v.dbid then
			self.selectedData.cardDbid = v.dbid
		end
	end

	self.cardSelected:set(k, true)

	if v.megaType ~= 0 and v.cfg.popRules then
		local key = "megaIndex" .. v.cfg.card[1]

		if not userDefault.getForeverLocalKey(key, false) then
			userDefault.setForeverLocalKey(key, true)
			self:ruleFunc()
		end
	end

	self.itemPanel:get("icon"):texture(ui.RARITY_ICON[v.unitCfg.rarity])

	local attrDatas = {}

	if v.megaType ~= 2 then
		table.insert(attrDatas, v.unitCfg.natureType)

		if v.unitCfg.natureType2 then
			table.insert(attrDatas, v.unitCfg.natureType2)
		end
	end

	self.attrDatas:update(attrDatas)

	if self.cardSprite then
		self.cardSprite:removeFromParent()

		self.cardSprite = nil
	end

	self.cardSprite = widget.addAnimation(self.animaCard, v.unitCfg.unitRes, "standby_loop", 5):alignCenter(self.animaCard:size()):scale(v.unitCfg.scaleU * 3):y(-100)

	self.cardSprite:setSkin(v.unitCfg.skin)

	local cfg = csv.card_mega[v.megaIndex]
	local data = {}

	if not self.isRouteUnlock then
		if csvSize(cfg.costCards) > 0 then
			table.insert(data, {
				costCards = cfg.costCards,
				subCardData = self.selectedData.subCardData
			})
		end

		for key, v in csvMapPairs(cfg.costItems) do
			if key ~= "gold" then
				table.insert(data, {
					key = key,
					val = v,
					selectNum = dataEasy.getNumByKey(key)
				})
			end
		end
	else
		for key, v in csvMapPairs(cfg.routeCost) do
			if key ~= "gold" then
				table.insert(data, {
					key = key,
					val = v,
					selectNum = dataEasy.getNumByKey(key)
				})
			end
		end
	end

	self.rightDatas:update(data)
	self:costGoldUpdate()
	self:cardItemUpdate()

	local conditionStr = cfg.condition[1] == 1 and string.format(gLanguageCsv.roleLevelReach, cfg.condition[2]) or string.format(gLanguageCsv.roleCardLevelReach, cfg.condition[2])

	self.titlePanel:get("num"):text(conditionStr)
	self:setBtnState(v)
end

function MegaView:setBtnState(v)
	self.btnFetter:hide()
	self.conversion:hide()

	if v.megaType == 1 then
		self.btnFetter:show()
		self.btnFetter:get("txt"):text(v.cfg.showType == 1 and gLanguageCsv.megaTitle1 or gLanguageCsv.megaTitle3)
		uiEasy.setBtnShader(self.btnFetter, self.btnFetter:get("txt"), v.isHas and 2 or 1)
		bind.extend(self, self.btnFetter, {
			class = "red_hint",
			props = {
				specialTag = "cardMega",
				listenData = {
					megaId = v.id
				},
				onNode = function(node)
					node:xy(400, 160)
				end
			}
		})
		self.titlePanel:show()
		self.titlePanel:get("num"):y(65)
		self.titlePanel:get("textFetter"):y(5)

		local star = csv.cards[self.cardId].star
		local name = csv.cards[self.cardId].name

		self.titlePanel:get("textFetter"):text(string.format(gLanguageCsv.fetterTips, star, name)):show()
	elseif v.megaType == 2 then
		if not v.isHas then
			self.conversion1:show()
			self.conversion1:get("txt"):text(gLanguageCsv.megaRouteUnlockX)
			bind.touch(self, self.conversion1, {
				methods = {
					ended = function()
						self.selectedData.megaIndex = v.megaIndexes[1]

						self:conversionClick()
					end
				}
			})
			bind.extend(self, self.conversion1, {
				class = "red_hint",
				props = {
					specialTag = "cardMega",
					listenData = {
						megaId = gCardsMega[v.megaIndexes[1]].key
					},
					onNode = function(node)
						node:xy(400, 160)
					end
				}
			})
			self.conversion2:show()
			self.conversion2:get("txt"):text(gLanguageCsv.megaRouteUnlockY)
			bind.touch(self, self.conversion2, {
				methods = {
					ended = function()
						self.selectedData.megaIndex = v.megaIndexes[2]

						self:conversionClick()
					end
				}
			})
			bind.extend(self, self.conversion2, {
				class = "red_hint",
				props = {
					specialTag = "cardMega",
					listenData = {
						megaId = gCardsMega[v.megaIndexes[2]].key
					},
					onNode = function(node)
						node:xy(400, 160)
					end
				}
			})
		else
			self.rightPanel:get("add"):hide()

			local card = gGameModel.cards:find(self.selectedData.cardDbid)

			if not card or not card:read("branch_unlock") then
				self.conversion:show()
				self.conversion:get("txt"):text(gLanguageCsv.megaRouteUnlock)
			else
				self.goldShow = false

				self.btnBranch:show():y(self.conversion:y())
				self.rightPanel:get("list"):hide()
				self.panel:hide()
				self.titlePanel:hide()

				local text = label.create(gLanguageCsv.megaRouteUnlockAlready, {
					fontPath = "font/youmi1.ttf",
					fontSize = 46,
					color = ui.COLORS.OUTLINE.DEFAULT,
					effect = {
						outline = {
							size = 4,
							color = ui.COLORS.OUTLINE.WHITE
						}
					}
				})

				text:addTo(self.btnBranch:parent(), self.btnBranch:z(), "routeUnlockAlready"):xy(self.btnBranch:x(), 600)
				text:setMaxLineWidth(700)
				text:setAlignment(cc.TEXT_ALIGNMENT_CENTER, cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
			end
		end

		self.titlePanel:get("textFetter"):hide()
		self.titlePanel:get("num"):y(50)
	else
		self.conversion:show()
		bind.extend(self, self.conversion, {
			class = "red_hint",
			props = {
				specialTag = "cardMega",
				listenData = {
					megaId = v.id
				},
				onNode = function(node)
					node:xy(400, 160)
				end
			}
		})
		self.titlePanel:show()
		self.titlePanel:get("textFetter"):hide()
		self.titlePanel:get("num"):y(50)
	end

	uiEasy.setBtnShader(self.conversion, self.conversion:get("txt"), 1)

	if v.cfg.type == 2 and not self.isRouteUnlock then
		uiEasy.setBtnShader(self.conversion, self.conversion:get("txt"), v.isHas and 2 or 1)
		self.titlePanel:get("num"):y(65)
		self.titlePanel:get("textFetter"):y(5)
		self.titlePanel:get("textFetter"):text(string.format(gLanguageCsv.megaRouteTip, v.unitCfg.name)):show()
	end
end

function MegaView:costGoldUpdate()
	self.panel:hide()

	local cfg = csv.card_mega[self.selectedData.megaIndex]

	if not cfg then
		return
	end

	local costGold = self.isRouteUnlock and cfg.routeCost.gold or cfg.costItems.gold

	if self.goldShow and costGold and gCardsMega[self.selectedData.megaIndex].canDevelop then
		self.panel:show()
		self.panel:get("gold"):text(costGold)

		local roleGold = gGameModel.role:read("gold")

		text.addEffect(self.panel:get("gold"), {
			color = costGold <= roleGold and ui.COLORS.NORMAL.DEFAULT or ui.COLORS.NORMAL.ALERT_ORANGE
		})
		adapt.oneLineCenterPos(cc.p(400, 40), {
			self.panel:get("txt1"),
			self.panel:get("gold"),
			self.panel:get("icon")
		}, cc.p(8, 0))
	end
end

function MegaView:cardStarUpdate(star)
	local cfg = csv.card_mega[self.selectedData.megaIndex]

	if cfg.type == 1 then
		if not gCardsMega[self.selectedData.megaIndex].canDevelop then
			star = cfg.card[2]
		else
			star = star or csv.cards[cfg.targetID].star
		end
	elseif cfg.type == 3 then
		star = star or csv.cards[cfg.targetID].star
	else
		star = star or cfg.card[2]
	end

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
end

function MegaView:cardItemUpdate()
	local star, advance
	local dbid = self.selectedData.cardDbid
	local selected = self.cardSelected:read()
	local data = self.tabDatas:atproxy(selected)

	self.starList:show()

	if data.megaType == 2 then
		uiEasy.setIconName("card", self.cardId, {
			node = self.itemPanel:get("name"),
			name = data.unitCfg.name
		})

		if self.isRouteUnlock then
			self.starList:hide()
		else
			self:cardStarUpdate(star)
		end
	elseif csv.card_mega[self.selectedData.megaIndex].type == 1 then
		for _, dbid in ipairs(self.cards:read()) do
			local card = gGameModel.cards:find(dbid)

			if card then
				local cardId = card:read("card_id")

				if cardId == self.cardId then
					star = card:read("star")
					advance = card:read("advance")

					break
				end
			end
		end

		uiEasy.setIconName("card", self.cardId, {
			space = true,
			node = self.itemPanel:get("name"),
			advance = advance
		})
		self:cardStarUpdate(star)
	else
		local dbid = self.selectedData.cardDbid

		if dbid then
			local card = gGameModel.cards:find(dbid)

			star = card:read("star")
			advance = card:read("advance")
		end

		uiEasy.setIconName("card", self.cardId, {
			space = true,
			node = self.itemPanel:get("name"),
			advance = advance
		})
		self:cardStarUpdate(star)
	end

	local megaIndex = self.selectedData.megaIndex
	local cfg = csv.card_mega[megaIndex]
	local dbid = self.selectedData.cardDbid
	local cardId, star = cfg.card[1], cfg.card[2]

	if data.megaType == 3 then
		cardId, star = cfg.card[1][1], cfg.card[1][2]
	end

	local markId = csv.cards[cardId].cardMarkID
	local starNum = 0
	local skinId = 0
	local goodFeel = 0
	local fight = 0
	local unitID = csv.cards[cardId].unitID

	if self.isRouteUnlock then
		unitID = cfg.specialUnitID
	end

	local unitCfg = csv.unit[unitID]
	local rarity = unitCfg.rarity
	local advance = false
	local level = false
	local nvalueSum = 0

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

	if csv.card_mega[self.selectedData.megaIndex].type == 1 then
		local textStartNote = self.rightPanelFetter:get("textStartNote")
		local textStart = self.rightPanelFetter:get("textStart")
		local textStart2 = self.rightPanelFetter:get("textStart2")
		local imgStar = self.rightPanelFetter:get("imgStar")
		local imgStar2 = self.rightPanelFetter:get("imgStar2")
		local textIndividualNote = self.rightPanelFetter:get("textIndividualNote")
		local textIndividual = self.rightPanelFetter:get("textIndividual")
		local textIndividual2 = self.rightPanelFetter:get("textIndividual2")
		local textFeelNote = self.rightPanelFetter:get("textFeelNote")
		local textFeel = self.rightPanelFetter:get("textFeel")
		local textFeel2 = self.rightPanelFetter:get("textFeel2")
		local textFightNote = self.rightPanelFetter:get("textFightNote")
		local textFight = self.rightPanelFetter:get("textFight")
		local textFight2 = self.rightPanelFetter:get("textFight2")

		textStart:text(starNum)
		textIndividual:text(nvalueSum)
		textFeel:text(goodFeel)
		textFight:text(fight)
		textStart2:text("/" .. cfg.req.star)
		textIndividual2:text("/" .. cfg.req.nvalueSum)
		textFeel2:text("/" .. cfg.req.goodFeel)
		textFight2:text("/" .. cfg.req.fightPoint)
		text.addEffect(textStart, {
			color = starNum >= cfg.req.star and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textIndividual, {
			color = nvalueSum >= cfg.req.nvalueSum and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textFeel, {
			color = goodFeel >= cfg.req.goodFeel and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(textFight, {
			color = fight >= cfg.req.fightPoint and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
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
		self.rightPanelFetter:get("card.item.add"):visible(dbid == nil)
	else
		local txt1 = self.rightPanel:get("card.txt1")
		local txt2 = self.rightPanel:get("card.txt2")

		txt1:text(dbid and 1 or 0)
		txt2:text("/" .. 1)
		text.addEffect(txt1, {
			color = dbid and ui.COLORS.NORMAL.FRIEND_GREEN or ui.COLORS.NORMAL.ALERT_ORANGE,
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		text.addEffect(txt2, {
			outline = {
				color = ui.COLORS.NORMAL.WHITE
			}
		})
		adapt.oneLineCenterPos(cc.p(140, -20), {
			txt1,
			txt2
		})
		self.rightPanel:get("card.item.add"):visible(dbid == nil)
	end

	local item = self.rightPanel:get("card.item")

	if csv.card_mega[self.selectedData.megaIndex].type == 1 then
		item = self.rightPanelFetter:get("card.item")
	end

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

function MegaView:chooseCard(list, k, v)
	self.selectedData.chooseIdx = k

	gGameUI:stackUI("city.card.mega.choose_card", nil, nil, self.selectedData, self:createHandler("itemCallback"))
end

function MegaView:itemCallback()
	if self.selectedData.chooseIdx then
		self.rightDatas:atproxy(self.selectedData.chooseIdx).subCardData = self.selectedData.subCardData
	end

	local selected = self.cardSelected:read()

	self:onTabItemClick(nil, selected, self.tabDatas:atproxy(selected))
end

function MegaView:animaFunc(cardId, megaCardId)
	self.megaOk:hide()

	if self.cardSprite then
		self.cardSprite:hide()
	end

	self.anima:show()
	self.topUi:hide()
	audio.playEffectWithWeekBGM("maga.mp3")

	local unitID1 = csv.cards[cardId].unitID
	local unitID2 = csv.cards[megaCardId].unitID
	local unitRes1, unitRes2 = csv.unit[unitID1].unitRes, csv.unit[unitID2].unitRes

	self.animaHou = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "hou", "chaojinhua_effect_hou", 1):alignCenter(self.anima:size()):scale(2)
	self.cardSprite1 = widget.addAnimationByKey(self.anima, unitRes1, "cards1", "standby_loop", 3):alignCenter(self.anima:size())

	self.cardSprite1:setSkin(csv.unit[unitID1].skin)

	self.cardSprite2 = widget.addAnimationByKey(self.anima, unitRes2, "cards2", "standby_loop", 2):alignCenter(self.anima:size())

	self.cardSprite2:setSkin(csv.unit[unitID2].skin)
	self.cardSprite2:hide()

	self.animaQian = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "qian", "chaojinhua_effect_qian", 4):alignCenter(self.anima:size()):scale(2)

	local name = "juese_move"
	local action = cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
		local posx, posy = self.animaHou:getPosition()
		local sx, sy = self.animaHou:getScaleX(), self.animaHou:getScaleY()
		local bxy = self.animaHou:getBonePosition(name)
		local rotation = self.animaHou:getBoneRotation(name)
		local scaleX = self.animaHou:getBoneScaleX(name)
		local scaleY = self.animaHou:getBoneScaleY(name)

		self.cardSprite1:rotate(-rotation):scaleX(scaleX * 2):scaleY(scaleY * 2):xy(cc.p(bxy.x * sx + posx, bxy.y * sy + posy))
		self.cardSprite2:rotate(-rotation):scaleX(scaleX * 2):scaleY(scaleY * 2):xy(cc.p(bxy.x * sx + posx, bxy.y * sy + posy))
	end)))

	self.cardSprite1:runAction(action)
	self.cardSprite2:runAction(action)
	performWithDelay(self, function(...)
		local switch = 2
		local color = {
			255,
			255,
			255,
			1
		}

		self.cardSprite1:setHSLShader(color[1], color[2], color[3], color[4], color[5], switch)
	end, 2)
	performWithDelay(self, function()
		self.cardSprite1:hide()
		self.cardSprite2:show()
	end, 5.5)
	performWithDelay(self, function()
		if self.cardSprite then
			self.cardSprite:show()
		end

		self.cardSprite1:removeAllChildren()
		self.cardSprite2:removeAllChildren()
		self.anima:removeAllChildren()
		self.anima:hide()

		self.animaQian = nil
		self.animaHou = nil

		self.topUi:show()

		local isHas = self.tabDatas:atproxy(self.cardSelected:read()).isHas

		self.megaOk:visible(isHas)
	end, 7.5)
end

function MegaView:animaFunc2(cardId1, cardId2, megaCardId)
	self.anima:show()
	self.topUi:hide()
	audio.playEffectWithWeekBGM("maga.mp3")

	local unitID1 = csv.cards[cardId1].unitID
	local unitID2 = csv.cards[cardId2].unitID
	local unitID3 = csv.cards[megaCardId].unitID
	local unitRes1, unitRes2, unitRes3 = csv.unit[unitID1].unitRes, csv.unit[unitID2].unitRes, csv.unit[unitID3].unitRes

	self.animaHou = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "hou", "hetijinhua_effect_hou", 1):alignCenter(self.anima:size()):scale(2)
	self.cardSprite1 = widget.addAnimationByKey(self.anima, unitRes1, "cards1", "standby_loop", 3):alignCenter(self.anima:size())

	self.cardSprite1:setSkin(csv.unit[unitID1].skin)

	self.cardSprite2 = widget.addAnimationByKey(self.anima, unitRes2, "cards2", "standby_loop", 3):alignCenter(self.anima:size())

	self.cardSprite2:setSkin(csv.unit[unitID2].skin)

	self.cardSprite3 = widget.addAnimationByKey(self.anima, unitRes3, "cards3", "standby_loop", 2):alignCenter(self.anima:size()):hide()

	self.cardSprite3:setSkin(csv.unit[unitID3].skin)

	self.animaQian = widget.addAnimationByKey(self.anima, "chaojinhua/chaojinhua.skel", "qian", "hetijinhua_effect_qian", 4):alignCenter(self.anima:size()):scale(2)

	local function setBone(node, name, flipX)
		local posx, posy = self.animaHou:getPosition()
		local sx, sy = self.animaHou:getScaleX(), self.animaHou:getScaleY()
		local bxy = self.animaHou:getBonePosition(name)
		local rotation = self.animaHou:getBoneRotation(name)
		local scaleX = self.animaHou:getBoneScaleX(name)
		local scaleY = self.animaHou:getBoneScaleY(name)

		node:rotate(-rotation):scaleX(scaleX * 2 * (flipX or 1)):scaleY(scaleY * 2):xy(cc.p(bxy.x * sx + posx, bxy.y * sy + posy))
	end

	local action = cc.RepeatForever:create(cc.Sequence:create(cc.CallFunc:create(function()
		setBone(self.cardSprite1, "juese_move")
		setBone(self.cardSprite2, "juese_move2", -1)
		setBone(self.cardSprite3, "juese_move3")
	end)))

	self.cardSprite1:runAction(action)
	self.cardSprite2:runAction(action)
	self.cardSprite3:runAction(action)
	performWithDelay(self, function(...)
		local switch = 2
		local color = {
			255,
			255,
			255,
			1
		}

		self.cardSprite1:setHSLShader(color[1], color[2], color[3], color[4], color[5], switch)
		self.cardSprite2:setHSLShader(color[1], color[2], color[3], color[4], color[5], switch)
	end, 2)
	performWithDelay(self, function()
		self.cardSprite1:hide()
		self.cardSprite2:hide()
		self.cardSprite3:show()
	end, 5.5)
	performWithDelay(self, function()
		self.cardSprite1:removeAllChildren()
		self.cardSprite2:removeAllChildren()
		self.cardSprite3:removeAllChildren()
		self.anima:removeAllChildren()
		self.anima:hide()

		self.animaQian = nil
		self.animaHou = nil

		self.topUi:show()
	end, 7.5)
end

function MegaView:conversionClick()
	if self.isRouteUnlock then
		self:routeUnlock()

		return
	end

	if not self.selectedData.cardDbid then
		gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

		return
	end

	local cfg = csv.card_mega[self.selectedData.megaIndex]

	if csvSize(cfg.costCards) ~= 0 and itertools.size(self.selectedData.subCardData) < cfg.costCards.num then
		gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

		return
	end

	local card = gGameModel.cards:find(self.selectedData.cardDbid)

	if cfg.condition[1] == 1 and gGameModel.role:read("level") < cfg.condition[2] then
		gGameUI:showTip(gLanguageCsv.cardDissatisfy)

		return
	end

	if cfg.condition[1] == 2 and card:read("level") < cfg.condition[2] then
		gGameUI:showTip(string.format(gLanguageCsv.roleCardLevelReach, cfg.condition[2]))

		return
	end

	for key, val in csvMapPairs(cfg.costItems) do
		if key ~= "gold" then
			local num = dataEasy.getNumByKey(key)

			if num < val then
				gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

				return
			end
		end
	end

	local roleGold = gGameModel.role:read("gold")

	if cfg.costItems.gold and roleGold < cfg.costItems.gold then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)

		return
	end

	local attrs = clone(card:read("attrs"))
	local cardId = card:read("card_id")
	local id = card:read("id")
	local oldFight = card:read("fighting_point")
	local branch = csv.cards[self.cardId].branch
	local data = {}

	for k in pairs(self.selectedData.subCardData) do
		table.insert(data, k)
	end

	local tip = gLanguageCsv.whetherMega
	local zawakeID = csv.cards[cardId].zawakeID
	local zawakeStage, zawakeLevel = zawakeTools.getMaxStageLevel(zawakeID)
	local extraStr = ""
	local t = {}

	if zawakeStage then
		local name = csv.cards[cardId].name
		local stageStr = gLanguageCsv["symbolRome" .. zawakeStage]

		tip = string.format(gLanguageCsv.zawakeMegaTip, name, stageStr)

		table.insert(t, gLanguageCsv.megaZawake .. stageStr)
	end

	local isOpenAid = dataEasy.isOpenAid(cardId, nil, true)

	if isOpenAid then
		table.insert(t, gLanguageCsv.megaAid)
	end

	local selected = self.cardSelected:read()
	local tabData = self.tabDatas:atproxy(selected)
	local megaCardID = self.cardId

	if tabData.megaType == 2 then
		megaCardID = gCardsMega[self.selectedData.megaIndex].key
		branch = csv.cards[megaCardID].branch
		tip = string.format(gLanguageCsv.megaRouteSure, csv.cards[megaCardID].name)
	end

	local extraStr = table.concat(t, gLanguageCsv.symbolComma)

	if #t > 0 and isOpenAid then
		tip = string.format(gLanguageCsv.megaExtraTips, csv.cards[megaCardID].name, extraStr)
	end

	gGameUI:showDialog({
		btnType = 2,
		isRich = true,
		fontSize = 50,
		title = gLanguageCsv.spaceTips,
		content = tip,
		cb = function()
			local showOver = {
				false
			}
			local cardDbid = self.selectedData.cardDbid

			self.selectedData.cardDbid = nil
			self.selectedData.subCardData = nil

			gGameApp:requestServerCustom("/game/develop/mega"):params(id, branch, data):onResponse(function(tb)
				self:animaFunc(cardId, megaCardID)
				performWithDelay(self, function()
					self.anima:hide()

					if self.cb then
						self.cb()
					end

					showOver[1] = true
				end, 7.5)
			end):wait(showOver):doit(function(tb)
				local function cb()
					gGameUI:stackUI("city.card.common_success", nil, {
						blackLayer = true
					}, cardDbid, oldFight, {
						mega = true,
						cardOld = cardId,
						attrs = attrs
					})
				end

				if not itertools.isempty(tb.view) then
					gGameUI:showGainDisplay(tb.view, {
						cb = cb
					})
				else
					cb()
				end
			end)
		end
	})
end

function MegaView:routeUnlock()
	if not self.selectedData.cardDbid then
		gGameUI:showTip(gLanguageCsv.megaRouteNotSprite)

		return
	end

	local cfg = csv.card_mega[self.selectedData.megaIndex]

	for key, val in csvMapPairs(cfg.routeCost) do
		if key ~= "gold" then
			local num = dataEasy.getNumByKey(key)

			if num < val then
				gGameUI:showTip(gLanguageCsv.megaRouteNotEnough)

				return
			end
		end
	end

	local roleGold = gGameModel.role:read("gold")

	if roleGold < cfg.routeCost.gold then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)

		return
	end

	local showOver = {
		false
	}
	local cardDbid = self.selectedData.cardDbid

	self.selectedData.cardDbid = nil
	self.selectedData.subCardData = nil

	gGameApp:requestServerCustom("/game/card/unlock/branch"):params(cardDbid):onResponse(function(tb)
		showOver[1] = true
	end):wait(showOver):doit(function(tb)
		gGameUI:showTip(gLanguageCsv.megaRouteUnlockSuccess)
	end)
end

function MegaView:onBtnBranchClick()
	if not self.selectedData.cardDbid then
		gGameUI:showTip(gLanguageCsv.pleaseSelectSprite)

		return
	end

	gGameUI:stackUI("city.card.evolution_base", nil, nil, self.selectedData.cardDbid)
end

function MegaView:conversionFetterClick()
	if not self.selectedData.cardDbid then
		gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

		return
	end

	local cfg = csv.card_mega[self.selectedData.megaIndex]
	local card = gGameModel.cards:find(self.selectedData.cardDbid)
	local fight = card:read("fighting_point")
	local starNum = card:read("star")
	local nvalue = card:read("nvalue")
	local nvalueSum = 0

	for k, v in pairs(nvalue) do
		nvalueSum = nvalueSum + v
	end

	local markId = csv.cards[cfg.card[1]].cardMarkID
	local cardFeel = gGameModel.role:read("card_feels")[markId] or {}
	local goodFeel = cardFeel.level or 0

	if starNum < cfg.req.star or nvalueSum < cfg.req.nvalueSum or goodFeel < cfg.req.goodFeel or fight < cfg.req.fightPoint then
		gGameUI:showTip(gLanguageCsv.fetterNotEnoughTips)

		return
	end

	local card = gGameModel.cards:find(self.selectedData.cardDbid)

	if cfg.condition[1] == 1 and gGameModel.role:read("level") < cfg.condition[2] then
		gGameUI:showTip(gLanguageCsv.cardDissatisfy)

		return
	end

	if cfg.condition[1] == 2 and card:read("level") < cfg.condition[2] then
		gGameUI:showTip(string.format(gLanguageCsv.roleCardLevelReach, cfg.condition[2]))

		return
	end

	for key, val in csvMapPairs(cfg.costItems) do
		if key ~= "gold" then
			local num = dataEasy.getNumByKey(key)

			if num < val then
				gGameUI:showTip(gLanguageCsv.megaMaterialsNotEnough)

				return
			end
		end
	end

	local roleGold = gGameModel.role:read("gold")

	if cfg.costItems.gold and roleGold < cfg.costItems.gold then
		gGameUI:showTip(gLanguageCsv.goldNotEnough)

		return
	end

	local function sendReq()
		local showOver = {
			false
		}
		local cardDbid = self.selectedData.cardDbid

		self.selectedData.cardDbid = nil
		self.selectedData.subCardData = nil

		local id = self.selectedData.megaIndex
		local card = gGameModel.cards:find(cardDbid)
		local cardId = card:read("card_id")

		gGameApp:requestServerCustom("/game/develop/fetter"):params(id):onResponse(function(tb)
			if not cfg.hasBattle then
				self:animaFunc(cardId, self.cardId)
				performWithDelay(self, function()
					self.anima:hide()

					if self.cb then
						self.cb()
					end

					showOver[1] = true
				end, 7.5)
			else
				showOver[1] = true
			end
		end):wait(showOver):doit(function(tb)
			if not cfg.hasBattle then
				gGameUI:showGainDisplay(tb.view)
			else
				self.gainDisplayShow = tb.view

				self:conversionFetterBattle()
			end
		end)
	end

	gGameUI:showDialog({
		btnType = 2,
		isRich = true,
		cb = sendReq,
		content = string.format(gLanguageCsv.fetterTips3, csv.cards[self.cardId].name, csv.cards[self.cardId].name)
	})
end

function MegaView:conversionFetterBattle()
	local data = {
		roleLevel = 1,
		moduleType = 2,
		sceneID = game.GATE_TYPE.bondEvolution,
		roleOut = csvClone(csv.role_out_init_mega),
		randSeed = math.random(1, 1000000),
		names = {
			gLanguageCsv.newbieName1,
			gLanguageCsv.newbieName2
		},
		levels = {
			99,
			99
		},
		logos = {
			1,
			31
		},
		preData = {}
	}
	local t = {
		_data = data,
		_modes = {
			baseMusic = "battle1.mp3",
			isRecord = false,
			fromRecordFile = false
		}
	}

	battleEntrance._switchUI(t, function()
		local t = {
			_results = {},
			_onResult = function()
				performWithDelay(gRootViewProxy:raw(), function()
					gGameUI:switchUI("city.view")
					gGameUI:showGainDisplay(self.gainDisplayShow)
				end, 0)
			end
		}

		gRootViewProxy:raw().showEndView = t._onResult
	end)
end

function MegaView:conversionMergeClick(flag, megaIndex, cardDbids)
	if flag == "relieve" then
		gGameApp:requestServerCustom("/game/develop/merge"):params(flag, megaIndex, cardDbids):doit(function(tb)
			gGameUI:showTip(gLanguageCsv.cardMergeRelieve)
			self.isRefresh:notify()
		end)
	else
		local showOver = {
			false
		}
		local cardID1 = gGameModel.cards:find(cardDbids[1]):read("card_id")
		local cardID2 = gGameModel.cards:find(cardDbids[2]):read("card_id")
		local megaCardID = csv.card_mega[megaIndex].mergeCardID

		gGameApp:requestServerCustom("/game/develop/merge"):params(flag, megaIndex, cardDbids):onResponse(function(tb)
			self:animaFunc2(cardID1, cardID2, megaCardID)
			performWithDelay(self, function()
				self.anima:hide()

				if self.cb then
					self.cb()
				end

				showOver[1] = true
			end, 7.5)
		end):wait(showOver):doit(function(tb)
			local function cb()
				gGameUI:showTip(gLanguageCsv.cardMergeSuccess)
				self.isRefresh:notify()
			end

			if not itertools.isempty(tb.view) then
				gGameUI:showGainDisplay(tb.view, {
					cb = cb
				})
			else
				cb()
			end
		end)
	end
end

function MegaView:bookFunc()
	gGameUI:stackUI("city.handbook.view", nil, {
		full = true
	}, {
		cardId = self.cardId
	})
end

function MegaView:ruleFunc()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getRuleContext"), {
		width = 1300
	})
end

function MegaView:getRuleContext(view)
	local selected = self.cardSelected:read()
	local data = self.tabDatas:atproxy(selected)

	if csvSize(data.cfg.rules) >= 2 then
		local content = {
			data.cfg.rules[1],
			data.cfg.rules[2]
		}
		local c = adaptContext
		local context = {
			c.clone(view.title, function(item)
				local str = gLanguageCsv.megaTitle3

				if data.showType == 2 and data.markId == 761 then
					str = gLanguageCsv.megaRouteUnlockRule
				elseif data.showType == 3 then
					str = gLanguageCsv.megaTitle4
				end

				item:get("text"):text(str)
			end),
			c.noteText(unpack(content))
		}

		return context
	end

	local content = {
		95001,
		95099
	}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.megaHouse)
		end),
		c.noteText(unpack(content))
	}

	return context
end

function MegaView:ruleFetterFunc()
	gGameUI:stackUI("common.rule", nil, nil, self:createHandler("getFetterRuleContext"), {
		width = 1300
	})
end

function MegaView:getFetterRuleContext(view)
	local selected = self.cardSelected:read()
	local data = self.tabDatas:atproxy(selected)

	if csvSize(data.cfg.rules) >= 2 then
		local content = {
			data.cfg.rules[1],
			data.cfg.rules[2]
		}
		local c = adaptContext
		local context = {
			c.clone(view.title, function(item)
				item:get("text"):text(gLanguageCsv.megaTitle3)
			end),
			c.noteText(unpack(content))
		}

		return context
	end

	local content = {
		127200,
		127299
	}
	local c = adaptContext
	local context = {
		c.clone(view.title, function(item)
			item:get("text"):text(gLanguageCsv.megaHouse2)
		end),
		c.noteText(unpack(content))
	}

	return context
end

function MegaView:onClassifyItemClick(list, index, v)
	self.tabDatas:atproxy(index).open = not v.open

	for i, data in self.tabDatas:pairs() do
		local vv = data:proxy()

		if v.type == vv.showType then
			self.tabDatas:atproxy(i).open = v.open
		end
	end

	performWithDelay(self.list, function()
		self.list:refreshView()
	end, 0.01)
end

function MegaView:onMegaAssistClick()
	gGameUI:stackUI("city.card.mega.mega_assist.view", nil, {
		full = true
	}, self.megaAssistActivityID)
end

function MegaView:onCleanup()
	if self.cardSprite then
		self.cardSprite:removeFromParent()

		self.cardSprite = nil
	end

	self.gainDisplayShow = self.gainDisplayShow
	self.cardId = self.cardId

	ViewBase.onCleanup(self)
end

return MegaView
