local ViewBase = cc.load("mvc").ViewBase
local CardBagView = class("CardBagView", ViewBase)
local SHOW_TYPE = {
	FRAGMENT = 2,
	CARD = 1
}
local SORT_DATAS = {
	{
		{
			val = 1,
			name = gLanguageCsv.fighting
		},
		{
			val = 2,
			name = gLanguageCsv.level
		},
		{
			val = 3,
			name = gLanguageCsv.rarity
		},
		{
			val = 4,
			name = gLanguageCsv.star
		},
		{
			val = 5,
			name = gLanguageCsv.getTime
		}
	},
	{
		{
			val = 1,
			name = gLanguageCsv.fighting
		},
		{
			val = 2,
			name = gLanguageCsv.level
		},
		{
			val = 4,
			name = gLanguageCsv.star
		},
		{
			val = 5,
			name = gLanguageCsv.getTime
		}
	},
	{
		{
			val = 3,
			name = gLanguageCsv.rarity
		},
		{
			val = 6,
			name = gLanguageCsv.numberPieces
		},
		{
			val = 7,
			name = gLanguageCsv.collectDegrees
		}
	},
	{
		{
			val = 6,
			name = gLanguageCsv.numberPieces
		},
		{
			val = 7,
			name = gLanguageCsv.collectDegrees
		}
	}
}
local totalSpecialTag = {
	"advance",
	"effortValue",
	"equipStar",
	"equipStrengthen",
	"equipAwake",
	"equipSignet",
	"star",
	"skill",
	"nvalue",
	"cardFeel",
	"cardDevelop",
	"gemFreeExtract",
	"canZawake"
}
local starSpecialTag = {
	"star"
}
local totalAidSpecialTag = {
	"aidActive",
	"aidUpLevel",
	"aidUpAdvance",
	"aidUpAwake"
}

local function sortData(data, index, order)
	if next(data) == nil then
		return {}
	end

	for k, v in pairs(data) do
		if v.num then
			v.numPercent = v.num / v.maxNum
		end
	end

	local condition = {
		"fight",
		"level",
		"rarity",
		"star",
		"getTime",
		"num",
		"numPercent"
	}

	if index == nil then
		table.sort(data, function(a, b)
			for i = 1, 4 do
				if a[condition[i]] ~= b[condition[i]] then
					return a[condition[i]] > b[condition[i]]
				end
			end

			return a[condition[5]] > b[condition[5]]
		end)
	else
		table.sort(data, function(a, b)
			if a.isBg ~= b.isBg then
				return a.isBg
			end

			if a.isAid ~= b.isAid then
				return a.isAid
			end

			if a[condition[index]] ~= b[condition[index]] then
				if order then
					return a[condition[index]] > b[condition[index]]
				else
					return a[condition[index]] < b[condition[index]]
				end
			end

			if a.markId ~= b.markId then
				return a.markId < b.markId
			end

			if a.fight and b.fight then
				return a.fight > b.fight
			end

			if a.id and b.id then
				return a.id > b.id
			end

			return false
		end)
	end

	return data
end

local function filterData(data, condition, filterType, targetStr, isSelectAid)
	if next(data) == nil then
		return {}
	end

	if condition == nil or condition[2] == nil then
		return data
	end

	local function isOK(data, key, val)
		if filterType == 1 then
			if data[key] == nil and key ~= "isHasAid" and (key ~= "attr2" or data.attr1 == val) then
				return true
			end

			if key == "atkType" then
				for k, v in ipairs(data.atkType) do
					if val[v] then
						return true
					end
				end

				return false
			end

			if data[key] == val then
				return true
			end

			if key == "isHasAid" then
				if isSelectAid == true then
					if dataEasy.isFragmentCard(data.id) then
						return true
					end

					local cfg = csv.cards[data.id]
					local aidID = cfg.aidID or 0

					return aidID > 0
				end

				return true
			end
		else
			local flag = false

			if data.name and data.name ~= "" and dataEasy.searchText(data.name, targetStr, {
				filterCS = true
			}) then
				return true
			end

			local cfg = csv.cards[data.id]

			if cfg then
				local name = cfg.name

				if dataEasy.searchText(name, targetStr, {
					filterCS = true
				}) then
					return true
				end
			end
		end

		return false
	end

	local tmp = {}

	for k, v in pairs(data) do
		if isOK(v, condition[1], condition[2]) then
			table.insert(tmp, v)
		end
	end

	return tmp
end

local function filterDo(data, conditions, filterType, targetStr, isSelectAid)
	local result = data

	for i = 1, #conditions do
		result = filterData(result, conditions[i], filterType, targetStr, isSelectAid)
	end

	return result
end

local function setListBar(list)
	list:setScrollBarEnabled(true)
	list:setScrollBarColor(cc.c3b(255, 200, 0))
	list:setScrollBarOpacity(255)
	list:setScrollBarWidth(10)
	list:setScrollBarPositionFromCorner(cc.p(100, 40))
end

local function setItem(item, childs, v)
	local size = childs.bg:size()
	local maskValue = 80
	local mask = ccui.Scale9Sprite:create()
	local cardId = dataEasy.getCardIdAndStar(v.id)

	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 39, size.height - 39):alignCenter(size)

	local cardCsv = csv.cards[cardId]

	childs.material:visible(cardCsv and cardCsv.cardType == 2)

	local unitCsv = csv.unit[cardCsv.unitID]

	childs.shiny:visible(unitCsv and unitCsv.shiny)

	local sp = cc.Sprite:create(v.icon)
	local spSize = sp:size()
	local soff = cc.p(v.posOffset.x / v.scale, -v.posOffset.y / v.scale)
	local ssize = cc.size(size.width / v.scale, size.height / v.scale)
	local rect = cc.rect((spSize.width - ssize.width) / 2 - soff.x, (spSize.height - ssize.height) / 2 - soff.y, ssize.width, ssize.height)

	sp:alignCenter(size):scale(v.scale + 0.2):setTextureRect(rect)

	local cardSpineNeedStar = v.cardSpineNeedStar
	local cardSpine = v.cardSpine
	local cardSpinePos = v.cardSpinePos

	if cardSpine and (v.hasSkin or cardSpineNeedStar <= v.star) then
		sp:hide()

		local effect = widget.addAnimationByKey(item, cardSpine, "cardSpine", "effect_loop", 5):setAnchorPoint(cc.p(0.5, 0.5)):xy(item:width() / 2 + cardSpinePos.x, item:height() / 2 + cardSpinePos.y):scale(unitCsv.cardSpineScale)
	end

	item:removeChildByName("clipping")
	cc.ClippingNode:create(mask):setAlphaThreshold(0.1):size(size):alignCenter(item:size()):add(sp):addTo(item, 4, "clipping")

	if v and v.shinyRes then
		local effect = widget.addAnimationByKey(sp, v.shinyRes, "shinySpine", "effect_loop", 4):setAnchorPoint(cc.p(0.5, 0.5)):xy(rect.width / 2 + v.shinyPos.x, ssize.height / 2 + v.shinyPos.y)
	end

	childs.qulityNumber:hide()
	uiEasy.setIconName("card", cardId, {
		advance = 1,
		space = true,
		node = childs.levelNamePanel:get("name"),
		name = v.name
	})
	text.addEffect(childs.levelNamePanel:get("name"), {
		color = ui.COLORS.NORMAL.WHITE
	})
	adapt.setTextScaleWithWidth(childs.levelNamePanel:get("name"), nil, 220)
	childs.fightPointPanel:get("fightPoint"):text(v.fight)
	childs.levelNamePanel:get("level"):text(v.level)
	childs.levelNamePanel:get("levelTxt"):text(gLanguageCsv.textLv1)
	adapt.oneLinePos(childs.levelNamePanel:get("level"), childs.levelNamePanel:get("levelTxt"), cc.p(0, 0), "right")
	adapt.oneLineCenterPos(cc.p(200, -3), {
		childs.fightPointPanel:get("fightPointTxt"),
		childs.fightPointPanel:get("fightPoint")
	}, cc.p(15, 0))

	if matchLanguage({
		"cn"
	}) then
		adapt.oneLineCenterPos(cc.p(200, 13), {
			childs.levelNamePanel:get("level"),
			childs.levelNamePanel:get("levelTxt"),
			childs.levelNamePanel:get("name")
		}, {
			cc.p(5, 0),
			cc.p(15, 0)
		})
	else
		adapt.oneLineCenterPos(cc.p(200, 13), {
			childs.levelNamePanel:get("levelTxt"),
			childs.levelNamePanel:get("level"),
			childs.levelNamePanel:get("name")
		}, {
			cc.p(5, 0),
			cc.p(15, 0)
		})
	end

	childs.bg:texture(string.format("common/icon/panel_card_%d.png", v.rarity + 2))

	if unitCsv.shiny then
		childs.bg:texture(string.format("common/icon/panel_shiny_card_%d.png", v.rarity))
	end

	childs.bottomBg:texture(string.format("city/card/bag/box_bottom_d%d.png", v.rarity + 2))
	childs.rarity:texture(ui.RARITY_ICON[v.rarity]):scale(1)

	if v.isBg then
		widget.addAnimationByKey(childs.maskBg, "effect/duiwuzhong.skel", "effect", "effect_loop", 20):xy(size.width / 2 - 30, size.height / 2 - 140)
	end

	if v.isAid then
		childs.maskBg:removeChildByName("effect")
		widget.addAnimationByKey(childs.maskBg, "aid/zhuzhanzhong.skel", "effect", "effect_loop", 20):xy(size.width / 2 - 30, size.height / 2 - 140)
	end

	childs.attr1:texture(ui.ATTR_ICON[v.attr1])

	if v.attr2 == nil then
		childs.attr2:hide()
	else
		childs.attr2:texture(ui.ATTR_ICON[v.attr2]):show()
	end
end

local function setItemChip(item, childs, v)
	local size = childs.maskBg:size()
	local mask = ccui.Scale9Sprite:create()
	local cfg = dataEasy.getCfgByKey(v.id)
	local quality = cfg.quality
	local name = uiEasy.setIconName(v.id)

	mask:initWithFile(cc.rect(82, 82, 1, 1), "common/icon/mask_card.png")
	mask:size(size.width - 20, size.height - 20):alignCenter(size)

	local cardCsv = csv.cards[cfg.combID]

	childs.material:visible(cardCsv and cardCsv.cardType == 2)

	local unitCsv = csv.unit[cardCsv.unitID]

	childs.shiny:visible(unitCsv and unitCsv.shiny)

	local sp = cc.Sprite:create(v.icon)
	local spSize = sp:size()
	local soff = cc.p(v.posOffset.x / v.scale, -v.posOffset.y / v.scale)
	local ssize = cc.size(size.width / v.scale, size.height / v.scale)
	local rect = cc.rect((spSize.width - ssize.width) / 2 - soff.x, (spSize.height - ssize.height) / 2 - soff.y, ssize.width, ssize.height)

	sp:alignCenter(size):scale(v.scale + 0.2):setTextureRect(rect)
	cc.ClippingNode:create(mask):setAlphaThreshold(0.1):size(size):alignCenter(item:size()):add(sp):addTo(item, 5)
	childs.name:text(name)
	text.addEffect(childs.name, {
		color = ui.COLORS.NORMAL.WHITE
	})
	childs.numBg:get("num"):text(v.num .. "/" .. v.maxNum)
	adapt.oneLineCenterPos(cc.p(180, 68), {
		childs.numBg:get("numTitle"),
		childs.numBg:get("num")
	}, cc.p(2, 4))
	childs.rarity:texture(ui.RARITY_ICON[v.rarity])

	if v.isBg then
		childs.rarity:z(11):color(cc.c3b(200, 200, 200))
	end

	childs.attr1:texture(ui.ATTR_ICON[v.attr1])

	if v.attr2 == nil then
		childs.attr2:hide()
	else
		childs.attr2:texture(ui.ATTR_ICON[v.attr2]):show()
	end
end

CardBagView.RESOURCE_FILENAME = "card_bag.json"
CardBagView.RESOURCE_BINDING = {
	["centerPanel.fragItem"] = "fragItem",
	["capacityPanel.numText"] = "capacityNumText",
	["centerPanel.subList"] = "subList",
	["capacityPanel.text"] = "capacityText",
	["centerPanel.cardItem"] = "cardItem",
	["centerPanel.slider"] = "slider",
	["centerPanel.empty"] = "showEmpty",
	capacityPanel = {
		varname = "capacityPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showBottomRight")
		}
	},
	["capacityPanel.btn"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAddClick")
			}
		}
	},
	btnBattleRecommend = {
		varname = "btnBattleRecommend",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBattleRecommendClick")
			}
		}
	},
	["panelBtn.btn1"] = {
		varname = "btnSprite",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:onChangeClick(1)
				end)
			}
		}
	},
	["panelBtn.btn2"] = {
		varname = "btnFragment",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.defer(function(view)
						return view:onChangeClick(2)
					end)
				}
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = "bottomFragment",
					listenData = {
						type = bindHelper.self("type")
					},
					onNode = function(panel)
						panel:xy(280, 120)
					end
				}
			}
		}
	},
	["panelBtn.btn3"] = {
		varname = "btnDecompose",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onEnterDecompose")
				}
			},
			{
				event = "visible",
				idler = bindHelper.self("cardRebornListen")
			}
		}
	},
	["panelBtn.btn4"] = {
		varname = "btnStar",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onEnterStar")
				}
			},
			{
				event = "visible",
				idler = bindHelper.self("cardStarListen")
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = {
						"starSwapAid",
						"starSwapExchange"
					},
					onNode = function(panel)
						panel:xy(280, 120)
					end
				}
			}
		}
	},
	["panelBtn.btn1.textNote"] = {
		varname = "textNoteSprite",
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panelBtn.btn2.textNote"] = {
		varname = "textNoteFragment",
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	["panelBtn.btn1.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("type"),
			method = function(val)
				local path = "city/card/bag/icon_jl1.png"

				if val == SHOW_TYPE.CARD then
					path = "city/card/bag/icon_jl.png"
				end

				return path
			end
		}
	},
	["panelBtn.btn2.imgIcon"] = {
		binds = {
			event = "texture",
			idler = bindHelper.self("type"),
			method = function(val)
				local path = "city/card/bag/icon_sp1.png"

				if val == SHOW_TYPE.FRAGMENT then
					path = "city/card/bag/icon_sp.png"
				end

				return path
			end
		}
	},
	["panelBtn.btn3.textNote"] = {
		binds = {
			event = "effect",
			data = {
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	centerPanel = {
		varname = "centerPanel",
		binds = {
			class = "sort_menus",
			event = "extend",
			props = {
				width = 310,
				expandUp = true,
				height = 80,
				data = bindHelper.self("sortTabData"),
				showSelected = bindHelper.self("sortKey"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				showSortList = bindHelper.self("isDownListShow"),
				onNode = bindHelper.self("onSortMenusNode", true)
			}
		}
	},
	["centerPanel.cardList"] = {
		varname = "cardList",
		binds = {
			class = "tableview",
			event = "extend",
			props = {
				asyncPreload = 18,
				leftPadding = 5,
				data = bindHelper.self("cardDatas"),
				columnSize = bindHelper.self("columnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("cardItem"),
				sliderBg = bindHelper.self("slider"),
				itemAction = {
					actionTime = 0.5,
					alwaysShow = true,
					isAction = true,
					duration = 0.3
				},
				onCell = function(list, cell, k, v)
					local childs = cell:multiget("bg", "attr1", "attr2", "levelNamePanel", "material", "shiny", "fightPointPanel", "rarity", "maskBg", "qulityNumber", "bottomBg", "imgLock")

					setItem(cell, childs, v)
					childs.imgLock:visible(v.lock)
					childs.maskBg:visible(v.isBg or v.isAid)
					cell:removeChildByName("isNew")

					if not v.isBg and v.isNew then
						ccui.ImageView:create("other/gain_sprite/txt_new.png"):alignCenter(cell:size()):addTo(cell, 11, "isNew")
					end

					local t = list:getIdx(k)

					cell:setName("cardItem" .. t.k)

					local specialTag = starSpecialTag

					if v.isBg then
						specialTag = totalSpecialTag
					elseif v.isAid then
						specialTag = totalAidSpecialTag
					end

					local props = {
						class = "red_hint",
						props = {
							state = v.selectEffect == nil,
							listenData = {
								selectDbId = v.dbid
							},
							specialTag = specialTag,
							onNode = function(panel)
								panel:xy(405, 495)
							end
						}
					}

					bind.extend(list, cell, props)
					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.itemClick, cell, t, v)
						}
					})
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()

						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick")
			}
		}
	},
	["centerPanel.fragList"] = {
		varname = "fragList",
		binds = {
			class = "tableview",
			event = "extend",
			props = {
				asyncPreload = 18,
				leftPadding = 5,
				data = bindHelper.self("fragDatas"),
				columnSize = bindHelper.self("columnSize"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("fragItem"),
				sliderBg = bindHelper.self("slider"),
				itemAction = {
					actionTime = 0.5,
					alwaysShow = true,
					isAction = true,
					duration = 0.3
				},
				onCell = function(list, cell, k, v)
					local childs = cell:multiget("bg", "attr1", "attr2", "name", "rarity", "numBg", "maskBg", "fragBg", "bottomBg", "material", "shiny")

					setItemChip(cell, childs, v)
					childs.fragBg:visible(not v.isBg)

					if v.canCompound == false then
						childs.bg:texture("common/icon/panel_card_1.png")
						childs.rarity:z(11):color(cc.c3b(200, 200, 200))
						childs.maskBg:show()
						childs.maskBg:get("img"):texture("common/icon/logo_jqqd.png"):scale(1)
						childs.bottomBg:show()
						childs.fragBg:hide()
					elseif v.isBg then
						childs.bg:texture("common/icon/panel_card_1.png")
						childs.maskBg:show()
						childs.bottomBg:show()

						local fragCfg = csv.fragments[v.id]
						local cardCfg = csv.cards[fragCfg.combID]

						childs.name:text(cardCfg.name)
						widget.addAnimationByKey(cell, "effect/jinglingbeibao.skel", "jinglingbeibao", "effect_loop", 10):anchorPoint(cc.p(0.5, 0.5)):xy(cell:width() / 2 + 1, cell:height() / 2 + 1)
					else
						childs.bg:texture("common/icon/panel_card.png")
						childs.maskBg:hide()
						childs.bottomBg:hide()
					end

					local props = {
						class = "red_hint",
						props = {
							state = v.selectEffect == nil and v.isBg,
							onNode = function(panel)
								panel:xy(405, 495)
							end
						}
					}

					bind.extend(list, cell, props)

					local t = list:getIdx(k)

					cell:setName("fragItem" .. t.k)
					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.itemClick, cell, t, v)
						}
					})
				end,
				onBeforeBuild = function(list)
					if list.sliderBg:visible() then
						local listX, listY = list:xy()
						local listSize = list:size()
						local x, y = list.sliderBg:xy()
						local size = list.sliderBg:size()

						list:setScrollBarEnabled(true)
						list:setScrollBarColor(cc.c3b(241, 59, 84))
						list:setScrollBarOpacity(255)
						list:setScrollBarAutoHideEnabled(false)
						list:setScrollBarPositionFromCorner(cc.p(listX + listSize.width - x, (listSize.height - size.height) / 2 + 5))
						list:setScrollBarWidth(size.width)
						list:refreshView()
					else
						list:setScrollBarEnabled(false)
					end
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick")
			}
		}
	},
	btnFilter = {
		varname = "btnFilter",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onFilterClick")
			}
		}
	},
	btnOneKeyCompound = {
		varname = "btnOneKeyCompound",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onOneKeyCompoundClick")
			}
		}
	},
	["btnOneKeyCompound.txt"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					size = 4,
					color = ui.COLORS.NORMAL.WHITE
				}
			}
		}
	}
}

function CardBagView:resetListSlider(typ)
	local size = typ == SHOW_TYPE.CARD and self.cardDatas:size() or self.fragDatas:size()
	local list = typ == SHOW_TYPE.CARD and self.cardList or self.fragList
	local sliderShow = size > self.columnSize * 2

	self.slider:setVisible(sliderShow)
	list:setScrollBarEnabled(sliderShow)
end

function CardBagView:onCreate(bagType)
	self:initModel()
	gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "PIXIE BACKPACK",
		title = gLanguageCsv.cardBag
	})

	self.cardRebornListen = dataEasy.getListenShow(gUnlockCsv.cardReborn)
	self.cardStarListen = dataEasy.getListenShow(gUnlockCsv.cardStarTemporarySwap)
	self.attr1 = idler.new(ui.ATTR_MAX)
	self.attr2 = idler.new(ui.ATTR_MAX)
	self.rarity = idler.new(ui.RARITY_LAST_VAL)
	self.atkType = idlertable.new({
		[game.ATTRDEF_ENUM_TABLE.damage] = true,
		[game.ATTRDEF_ENUM_TABLE.specialDamage] = true
	})
	self.targetStr = idler.new("")
	self.isSelectAid = idler.new(false)
	self.isDownListShow = idler.new(false)
	self.refreshSign = true
	self.filterType = idler.new(1)

	self.btnFilter:xy(1889 + display.uiOrigin.x, 108)

	local deltaWidth, count = adapt.centerWithScreen("left", "right", {
		itemWidthExtra = 200,
		itemWidth = self.cardItem:size().width
	}, {
		{
			self.btnSprite,
			"pos",
			"left"
		},
		{
			self.btnFragment,
			"pos",
			"left"
		},
		{
			self.btnDecompose,
			"pos",
			"left"
		},
		{
			self.btnStar,
			"pos",
			"left"
		},
		{
			self.btnFilter,
			"pos",
			"right"
		},
		{
			self.btnBattleRecommend,
			"pos",
			"right"
		},
		{
			self.capacityPanel,
			"pos",
			"right"
		},
		{
			self.slider,
			"pos",
			"right"
		},
		{
			self.centerPanel,
			"width"
		},
		{
			{
				self.subList,
				self.cardList,
				self.fragList
			},
			"width"
		},
		{
			{
				self.subList,
				self.cardList,
				self.fragList
			},
			"pos",
			"left"
		}
	})

	self.deltaWidth = deltaWidth or 0
	self.columnSize = 5 + count
	self.cardDatas = idlertable.new({})
	self.fragDatas = idlertable.new({})
	self.showBottomRight = idler.new(true)
	self.sortOrder = idler.new(true)
	self.type = idler.new(bagType or SHOW_TYPE.CARD)
	self.sortKey = idler.new(1)
	self.sortTabData = idlertable.new()
	self.sortTabDataIndex = idler.new()

	idlereasy.when(self.type, function(obj, typ)
		self.cardList:visible(typ == SHOW_TYPE.CARD)
		self.fragList:visible(typ == SHOW_TYPE.FRAGMENT)

		local oneKeyCompoundState = self:checkCompoundBtnState()

		self.btnOneKeyCompound:visible(oneKeyCompoundState)
		self.slider:setVisible(true)
		self.btnSprite:setBright(typ ~= SHOW_TYPE.CARD)
		self.btnSprite:setTouchEnabled(typ ~= SHOW_TYPE.CARD)
		self.btnFragment:setBright(typ ~= SHOW_TYPE.FRAGMENT)
		self.btnFragment:setTouchEnabled(typ ~= SHOW_TYPE.FRAGMENT)

		local color1 = ui.COLORS.NORMAL.RED
		local color2 = ui.COLORS.NORMAL.RED

		if typ == SHOW_TYPE.CARD then
			color1 = ui.COLORS.NORMAL.WHITE
		end

		if typ == SHOW_TYPE.FRAGMENT then
			color2 = ui.COLORS.NORMAL.WHITE
		end

		text.addEffect(self.textNoteSprite, {
			color = color1
		})
		text.addEffect(self.textNoteFragment, {
			color = color2
		})
	end)
	idlereasy.any({
		self.type,
		self.rarity
	}, function(obj, typ, rarity)
		local oneKeyCompoundState = self:checkCompoundBtnState()

		self.btnOneKeyCompound:visible(oneKeyCompoundState)
		self.showBottomRight:set(typ == SHOW_TYPE.CARD)

		local newIndex

		if typ == SHOW_TYPE.CARD then
			newIndex = ui.RARITY_ICON[rarity] and 2 or 1
		else
			newIndex = ui.RARITY_ICON[rarity] and 4 or 3
		end

		self.sortTabDataIndex:set(newIndex)

		local tmpSortTabData = {}

		for k, v in pairs(SORT_DATAS[newIndex]) do
			table.insert(tmpSortTabData, v.name)
		end

		self.sortTabData:set(tmpSortTabData)
		self.sortKey:set(1)
		self.sortOrder:set(true)
	end)
	idlereasy.any({
		self.cardCapacity,
		self.cards
	}, function(obj, capacity, cards)
		self.capacityNumText:text(#cards .. "/" .. capacity)
		adapt.oneLinePos(self.capacityNumText, self.capacityText, cc.p(0, 0), "right")
	end)

	self.cardInfos = idlertable.new({})

	local datas = {}
	local datasCount = 0

	idlereasy.any({
		self.cards,
		self.battleCards,
		self.aidCards
	}, function(_, cards, battleCards)
		if self.refreshSign then
			self:refushBagData()
		end
	end)
	idlereasy.when(gGameModel.cards:getNewFlags(), function(_, flags)
		self.cardInfos:modify(function(cardInfos)
			local changed = false

			for _, v in ipairs(cardInfos) do
				local id = stringz.bintohex(v.dbid)
				local flag = flags[id] or false

				changed = changed or v.isNew ~= flag
				v.isNew = flag
			end

			return changed, cardInfos
		end)
	end, true)

	self.fragInfos = idlertable.new()

	idlereasy.when(self.frags, function(_, frags)
		local fragInfos = {}

		for i, v in pairs(frags) do
			local fragCsv = csv.fragments[i]

			if fragCsv.type == 1 then
				local cardCsv = csv.cards[fragCsv.combID]
				local unitCsv = csv.unit[cardCsv.unitID]

				table.insert(fragInfos, {
					isSprite = false,
					id = i,
					name = uiEasy.setIconName(i),
					num = v,
					maxNum = fragCsv.combCount,
					maxNum1 = fragCsv.stackMax,
					rarity = unitCsv.rarity,
					isBg = v >= fragCsv.combCount and fragCsv.canCompound ~= false,
					canCompound = fragCsv.canCompound,
					attr1 = unitCsv.natureType,
					attr2 = unitCsv.natureType2,
					icon = unitCsv.cardShow,
					scale = unitCsv.cardShowScale,
					posOffset = unitCsv.cardShowPosC,
					shinyPos = unitCsv.shinyPos,
					dbid = i,
					atkType = cardCsv.atkType
				})
			end
		end

		self.fragInfosChange = true

		self.fragInfos:set(fragInfos)

		local oneKeyCompoundState = self:checkCompoundBtnState()

		self.btnOneKeyCompound:visible(oneKeyCompoundState)
	end)

	local resort = idler.new(true)
	local sortTriggers = idlereasyArgs.new(self, "sortTabDataIndex", "cardInfos", "fragInfos", "type", "sortKey", "sortOrder", "rarity", "attr1", "attr2", "atkType", "isSelectAid")
	local resortTimes = 0

	idlereasy.any(sortTriggers, function(...)
		resortTimes = resortTimes + 1

		performWithDelay(self, function()
			if resortTimes > 0 then
				resort:notify()

				resortTimes = 0
			end
		end, 0)
	end)
	idlerflow.if_(resort):do_(function(vars)
		local data

		if vars.type == SHOW_TYPE.CARD then
			data = vars.cardInfos
		else
			data = vars.fragInfos
		end

		if SORT_DATAS[vars.sortTabDataIndex][vars.sortKey] then
			local tmpSortKey = SORT_DATAS[vars.sortTabDataIndex][vars.sortKey].val

			self:sortFilterData(vars.type, data, tmpSortKey, vars.sortOrder, {
				{
					"rarity",
					ui.RARITY_ICON[vars.rarity] and vars.rarity
				},
				{
					"attr2",
					ui.ATTR_ICON[vars.attr2] and vars.attr2
				},
				{
					"attr1",
					ui.ATTR_ICON[vars.attr1] and vars.attr1
				},
				{
					"atkType",
					vars.atkType
				},
				{
					"isHasAid",
					vars.isSelectAid
				}
			})
		end

		local oneKeyCompoundState = self:checkCompoundBtnState()

		self.btnOneKeyCompound:visible(oneKeyCompoundState)
	end, sortTriggers)
	uiEasy.updateUnlockRes(gUnlockCsv.cardReborn, self.btnDecompose, {
		pos = cc.p(self.btnDecompose:width() - 20, 100)
	})
	uiEasy.updateUnlockRes(gUnlockCsv.cardStarTemporarySwap, self.btnStar, {
		pos = cc.p(self.btnStar:width() - 20, 100)
	})

	local nodes = nodetools.multiget(self:getResourceNode(), {
		"bg"
	})

	effect.captureForBackgroud(self, unpack(nodes))
	dataEasy.getListenUnlock(gUnlockCsv.battleRecommend, function(isUnlock)
		self.btnBattleRecommend:visible(isUnlock)
	end)
end

function CardBagView:initModel()
	self.cards = gGameModel.role:getIdler("cards")
	self.frags = gGameModel.role:getIdler("frags")
	self.cardCapacity = gGameModel.role:getIdler("card_volume")
	self.battleCards = gGameModel.role:getIdler("battle_cards")
	self.aidCards = gGameModel.role:getIdler("battle_aid_cards") or idlertable.new({})
	self.rmb = gGameModel.role:getIdler("rmb")
	self.vipLevel = gGameModel.role:getIdler("vip_level")
	self.cardCapacityTimes = gGameModel.role:getIdler("card_capacity_times")
	self.roleLv = gGameModel.role:getIdler("level")
end

function CardBagView:refushBagData()
	local cards = self.cards:read()
	local battleCards = self.battleCards:read()
	local aidCards = self.aidCards:read()
	local hash = itertools.map(itertools.ivalues(battleCards), function(k, v)
		return v, k
	end)
	-- 标记 暂时取消aid相关
	-- local aidHash = itertools.size(aidCards) ~= 0 and itertools.map(itertools.ivalues(aidCards), function(k, v)
	-- 	return v, k
	-- end) or {}
	local aidHash = {}
	local datas = {}

	for i, v in ipairs(cards) do
		local card = gGameModel.cards:find(v)

		if card then
			local cardData = card:read("card_id", "unit_id", "skin_id", "fighting_point", "level", "star", "advance", "locked", "name", "created_time", "equips", "effort_values")
			local cardCsv = csv.cards[cardData.card_id]
			local unitCsv = dataEasy.getUnitCsv(cardData.card_id, cardData.skin_id)

			datas[i] = {
				isSprite = true,
				id = cardData.card_id,
				markId = cardCsv.cardMarkID,
				name = cardData.name,
				rarity = unitCsv.rarity,
				isBg = hash[v] and true or false,
				isAid = aidHash[v] and true or false,
				isNew = gGameModel.cards:isNew(v),
				attr1 = unitCsv.natureType,
				attr2 = unitCsv.natureType2,
				fight = cardData.fighting_point,
				level = cardData.level,
				star = cardData.star,
				getTime = cardData.created_time,
				icon = unitCsv.cardShow,
				scale = unitCsv.cardShowScale,
				posOffset = unitCsv.cardShowPosC,
				cardSpine = unitCsv.cardSpine,
				cardSpineScale = unitCsv.cardSpineScale,
				cardSpinePos = unitCsv.cardSpinePos,
				cardSpineNeedStar = unitCsv.cardSpineNeedStar,
				shinyPos = unitCsv.shinyPos,
				shinyRes = unitCsv.shinyRes,
				advance = cardData.advance,
				dbid = v,
				lock = cardData.locked,
				equips = cardData.equips,
				effortValue = cardData.effort_values,
				atkType = cardCsv.atkType,
				hasSkin = cardData.skin_id > 0
			}
		end
	end

	self.cardInfos:set(datas)
end

function CardBagView:sortFilterData(typ, data, key, order, condition)
	local filterType = self.filterType:read()
	local targetStr = self.targetStr:read()
	local isSelectAid = self.isSelectAid:read()
	local filter = filterDo(data, condition, filterType, targetStr, isSelectAid)
	local sortResult = sortData(filter, key, order)

	if next(sortResult) == nil then
		local txt = next(data) == nil and typ ~= SHOW_TYPE.CARD and gLanguageCsv.cardBagNoFrags or gLanguageCsv.filteringIsEmpty

		self.showEmpty:show()
		self.showEmpty:get("txt"):text(txt)
	else
		self.showEmpty:hide()
	end

	if typ == SHOW_TYPE.CARD then
		local preloadCenter

		if self.cardCenterDbid then
			for k, v in ipairs(sortResult) do
				if v.dbid == self.cardCenterDbid then
					preloadCenter = k

					break
				end
			end
		end

		self.cardList.preloadCenterIndex = preloadCenter and math.ceil(preloadCenter / self.columnSize)

		self.cardDatas:set(sortResult, true)
	else
		if self.fragInfosChange then
			dataEasy.tryCallFunc(self.fragList, "updatePreloadCenterIndex")
		end

		self.fragDatas:set(sortResult, true)
	end

	self.fragInfosChange = false

	self:resetListSlider(typ)
end

function CardBagView:onItemClick(list, item, t, v)
	if v.isSprite then
		gGameUI:stackUI("city.card.strengthen", nil, {
			full = true
		}, 1, v.dbid)
	elseif v.isBg then
		if itertools.size(self.cards:read()) >= self.cardCapacity:read() then
			gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)

			return
		end

		local fragCsv = csv.fragments[v.id]
		local cardCsv = csv.cards[fragCsv.combID]
		local strs = {
			string.format("#C0x5b545b#" .. gLanguageCsv.wantConsumeFragsCombCard, fragCsv.combCount, "#C0x60C456#" .. fragCsv.name .. "#C0x5b545b#", "#C0x60C456#" .. cardCsv.name)
		}

		gGameUI:showDialog({
			clearFast = true,
			isRich = true,
			btnType = 2,
			content = strs,
			cb = function()
				gGameApp:requestServer("/game/role/frag/comb", function(tb)
					gGameUI:stackUI("common.gain_sprite", nil, {
						full = true
					}, tb.view.carddbIDs[1], nil, false, self:createHandler("setCardCenterDbid", tb.view.carddbIDs[1].db_id))
				end, {
					[v.id] = 1
				})
			end
		})
	elseif v.canCompound == false then
		gGameUI:showTip(gLanguageCsv.comingSoon2)
	else
		gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.maxNum)
	end
end

function CardBagView:onItemClick(list,item, t, v)
	if v.isSprite then
		gGameUI:stackUI("city.card.strengthen", nil, {full = true}, 1, v.dbid)
	else
		if v.isBg then
			-- 精灵背包满时提示无法合成
			if itertools.size(self.cards:read()) >= self.cardCapacity:read() then
				gGameUI:showTip(gLanguageCsv.cardBagHaveBeenFull)
				return
			end
			local fragCsv = csv.fragments[v.id]
			local cardCsv = csv.cards[fragCsv.combID]
			local strs = {
				string.format("#C0x5b545b#"..gLanguageCsv.wantConsumeFragsCombCard, fragCsv.combCount, "#C0x60C456#"..fragCsv.name.."#C0x5b545b#", "#C0x60C456#"..cardCsv.name)
			}
			gGameUI:showDialog({content = strs, cb = function()
				gGameApp:requestServer("/game/role/frag/comb",function (tb)
					gGameUI:stackUI("common.gain_sprite", nil, {full = true}, tb.view.carddbIDs[1], nil, false, self:createHandler("setCardCenterDbid", tb.view.db_id))
				end,v.id)
			end, btnType = 2, isRich = true, clearFast = true})
		else
			gGameUI:stackUI("common.gain_way", nil, nil, v.id, nil, v.maxNum)
		end
	end
end

function CardBagView:setCardCenterDbid(dbId)
	self.cardCenterDbid = dbId

	performWithDelay(self, function()
		self.cardCenterDbid = nil
	end, 0.1)
	self.type:set(SHOW_TYPE.CARD)
end

function CardBagView:onBattleRecommendClick()
	sdk.trackEvent("check_recom")

if dataEasy.isUnlock(gUnlockCsv.crossRecommend) then--暂时禁用跨服阵容推荐
    -- 直接使用模拟数据，避免调用协议
    gGameUI:stackUI("city.card.battle_recommend", nil, nil, {
        list = {}  -- 模拟空数据
    })
end
end

function CardBagView:onAddClick()
	gGameUI:stackUI("city.card.buy_capacity")
end

function CardBagView:buyCapacity()
	gGameApp:requestServer("/game/role/card_capacity/buy", function(tb)
		gGameUI:showTip(gLanguageCsv.hasBuy)
	end)
end

function CardBagView:onChangeClick(val)
	val = val or 1

	self.type:set(val)
end

function CardBagView:hasFilter()
	if self.filterType:read() == 1 then
		for i, v in pairs(self.atkType:read()) do
			if not v then
				return true
			end
		end

		if self.attr1:read() ~= ui.ATTR_MAX or self.attr2:read() ~= ui.ATTR_MAX or self.rarity:read() ~= ui.RARITY_LAST_VAL or self.isSelectAid:read() == true then
			return true
		end

		return false
	end

	return self.targetStr:read() ~= ""
end

function CardBagView:onBagFilter(attr1, attr2, rarity, atkType, filterType, targetStr, isSelectAid)
	self.attr1:set(attr1)
	self.attr2:set(attr2)
	self.rarity:set(rarity)
	self.atkType:modify(function()
		return true, atkType
	end)
	self.filterType:set(filterType)
	self.targetStr:set(targetStr)
	self.isSelectAid:set(isSelectAid)

	if self:hasFilter() then
		self.btnFilter:get("title"):text(gLanguageCsv.cardBagFilterIn)

		if filterType == 2 and self.type:read() == SHOW_TYPE.CARD then
			gGameUI:showTip(gLanguageCsv.filterSuccessTip2)
		else
			gGameUI:showTip(gLanguageCsv.filterSuccessTip)
		end
	else
		self.btnFilter:get("title"):text(gLanguageCsv.cardBagFilter)

		if filterType == 1 then
			gGameUI:showTip(gLanguageCsv.notFilterTip)
		else
			gGameUI:showTip(gLanguageCsv.notSearchTip)
		end
	end
end

function CardBagView:onSortMenusBtnClick(panel, node, k, v, oldval)
	if oldval == k then
		self.sortOrder:modify(function(val)
			return true, not val
		end)
	else
		self.sortOrder:set(true)
	end

	self.sortKey:set(k)
end

function CardBagView:onSortMenusNode(panel, node)
	node:xy(962 + self.deltaWidth, -431):z(20)
end

function CardBagView:onEnterDecompose()
	if not dataEasy.isUnlock(gUnlockCsv.cardReborn) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardReborn))

		return
	end

	if not gGameUI:goBackInStackUI("city.card.rebirth.view") then
		gGameUI:stackUI("city.card.rebirth.view", nil, {
			full = true
		}, 2)
	end
end

function CardBagView:onEnterStar()
	if not dataEasy.isUnlock(gUnlockCsv.cardStarTemporarySwap) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardStarTemporarySwap))

		return
	end

	if not gGameUI:goBackInStackUI("city.card.star_swap.view") then
		gGameUI:stackUI("city.card.star_swap.view", nil, {
			full = true
		}, 1)
	end
end

function CardBagView:onFilterClick()
	if self.showIdler then
		self.showIdler:set(false)
	end

	gGameUI:stackUI("city.card.card_filter", nil, {
		clickClose = true
	}, {
		cb = self:createHandler("onBagFilter"),
		attr1 = self.attr1:read(),
		attr2 = self.attr2:read(),
		rarity = self.rarity:read(),
		atkType = self.atkType:read(),
		filterType = self.filterType:read(),
		targetStr = self.targetStr:read(),
		isSelectAid = self.isSelectAid:read()
	})
end

function CardBagView:checkCompoundBtnState()
	if not dataEasy.isUnlock(gUnlockCsv.cardFragOneKeyCompound) then
		return false
	end

	if self.type:read() ~= SHOW_TYPE.FRAGMENT then
		return false
	end

	if self:hasFilter() then
		return false
	end

	local fragData = self.fragInfos:read()
	local allCount = 0

	for i, v in pairs(fragData) do
		local count = math.floor(v.num / v.maxNum)

		allCount = allCount + count

		if allCount >= 2 then
			return true
		end
	end

	return false
end

function CardBagView:onOneKeyCompoundClick()
	local fragData = self.fragInfos:read()

	gGameUI:stackUI("city.card.onekey_compound", nil, nil, fragData, self:createHandler("setCardCenterDbid"))
end

function CardBagView:onStackHide(...)
	self.refreshSign = false

	return ViewBase.onStackHide(self, ...)
end

function CardBagView:onStackShow()
	self.refreshSign = true

	self:refushBagData()

	return ViewBase.onStackShow(self)
end

return CardBagView
