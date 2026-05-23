-- chunkname: @src.app.views.city.handbook.view

local handbookTools = require("app.views.city.handbook.tools")
local LINE_NUM = 4
local BG_PATH = {
	[0] = "city/handbook/tag_green.png",
	"city/handbook/tag_blue.png",
	"city/handbook/tag_purple.png",
	"city/handbook/tag_yellow.png",
	"city/handbook/tag_orange.png",
	"city/handbook/tag_red.png"
}

local function createScale9Sprite(params)
	local path = params.path
	local size = params.size
	local rect = params.rect
	local rotation = params.rotation or 0
	local line = ccui.Scale9Sprite:create()

	line:initWithFile(rect, path)
	line:size(size)
	line:setRotation(rotation)

	return line
end

local function addLine(firData, secData)
	local s1 = itertools.size(firData)
	local isChange = false

	if s1 == 0 then
		isChange = true
		firData = secData
	end

	local offx = 2
	local len1 = #firData
	local len2 = #secData
	local itemSize = firData[1]:size()

	for i, item in ipairs(firData) do
		local line1 = item:getChildByName("line1")

		if line1 then
			line1:visible(true)
		else
			local params = {
				path = "city/handbook/box_line_bg.png",
				size = cc.size(58, 18),
				rect = cc.rect(25, 9, 1, 1)
			}

			createScale9Sprite(params):xy(itemSize.width + offx, itemSize.height / 2):visible(not isChange and i <= len2):addTo(item, -2, "line1")

			params = {
				path = "city/handbook/box_line_1.png",
				size = cc.size(82, 28),
				rect = cc.rect(25, 14, 1, 1)
			}

			createScale9Sprite(params):xy(itemSize.width + offx, itemSize.height / 2):addTo(item, -1, "redline1")
		end
	end

	if len1 == 1 and len2 > 1 then
		for _, item in ipairs(firData) do
			local line = item:getChildByName("line1")

			line:x(itemSize.width - 18)
			line:size(26, 18)

			local redLine = item:getChildByName("redline1")

			redLine:x(itemSize.width - 18)
			redLine:size(58, 28)
		end

		local x, y = itemSize.width + 3, itemSize.height / 2
		local parent = firData[1]
		local sizeX = (len2 - 1) * (itemSize.height + 15)
		local params = {
			rotation = 90,
			path = "city/handbook/box_line_bg.png",
			size = cc.size(sizeX + 18, 18),
			rect = cc.rect(25, 9, 1, 1)
		}

		createScale9Sprite(params):xy(x, y):addTo(parent, -3, "line2")

		params = {
			rotation = 90,
			path = "city/handbook/box_line_1.png",
			size = cc.size(sizeX + 28, 32),
			rect = cc.rect(25, 9, 1, 1)
		}

		createScale9Sprite(params):xy(x + 2, y):addTo(parent, -2, "redline2")

		x, y = 20, itemSize.height / 2

		for _, item in ipairs(secData) do
			local params = {
				path = "city/handbook/box_line_bg.png",
				size = cc.size(17, 18),
				rect = cc.rect(25, 9, 1, 1)
			}

			createScale9Sprite(params):xy(x, y):addTo(item, -2, "line3")

			params = {
				path = "city/handbook/box_line_1.png",
				size = cc.size(43, 28),
				rect = cc.rect(25, 14, 1, 1)
			}

			createScale9Sprite(params):xy(x - 2, y):addTo(item, -1, "redline3")
		end
	end
end

local function onInitItem(list, node, k, itemDatas)
	for i = 1, math.huge do
		local item = node:get("item" .. i)

		if not item then
			break
		end

		item:removeFromParent()
	end

	node:get("aidTip"):hide()

	local listW = list:size().width
	local itemType = itemDatas[1].itemType
	local titleType = itemDatas[1].titleType

	if itemType == "title" then
		if not titleType then
			node:get("imgTitle"):visible(true)
			node:get("imgBg"):visible(true)
			node:get("list"):visible(false)
			node:get("imgTitle"):texture(ui.RARITY_ICON[itemDatas[1].val])
			node:get("imgBg"):texture(BG_PATH[itemDatas[1].val])

			local box = node:get("imgTitle"):getBoundingBox()

			node:size(cc.size(listW, box.height))
			node:get("imgTitle"):y(box.height / 2)
			node:get("imgBg"):y(box.height / 2)
		else
			node:get("aidTip"):show()
			node:get("imgBg"):hide()
			node:get("list"):hide()
			node:get("imgTitle"):hide()

			local box = node:get("aidTip"):size()

			node:size(cc.size(listW, box.height))
			node:get("aidTip"):y(box.height / 2)
		end
	elseif itemType == 2 then
		node:get("imgBg"):visible(false)
		node:get("imgTitle"):visible(false)

		local itemList = node:get("list")

		itemList:visible(false)

		local branchDatas = {}

		for i, v in ipairs(itemDatas) do
			local cardCsv = csv.cards[v.cfg.cardID]
			local branch = cardCsv.branch

			if not branchDatas[branch] then
				branchDatas[branch] = {}
			end

			v.develop = cardCsv.develop
			v.currRealBranch = cardCsv.branch
			v.branch = {}
			v.order = i

			table.insert(branchDatas[branch], v)
		end

		local lastHasItem
		local branchCount = csvSize(branchDatas)

		if branchDatas[0] and branchCount > 1 then
			branchCount = branchCount - 1
		end

		local developLength = branchDatas[0] and #branchDatas[0] or 0
		local h = 202 * branchCount + (branchCount - 1) * 3 + 40

		node:size(cc.size(listW, h - 10))

		local items, develops = {}, {}
		local tmpRow = 0

		for branch, v in pairs(branchDatas) do
			table.sort(v, function(a, b)
				return a.develop < b.develop
			end)

			if branch ~= 0 then
				tmpRow = tmpRow + 1
			end

			local lastItems = {}
			local tmpColumn = branch ~= 0 and developLength or 0

			for i, vv in ipairs(v) do
				local cardCsv = csv.cards[vv.cfg.cardID]
				local develop = cardCsv.develop
				local branch = cardCsv.branch
				local item = list.cloneItem:clone()

				item:visible(true)
				node:addChild(item, 10, "item" .. vv.order)

				local size = item:size()

				if vv.isHas then
					lastHasItem = item
				end

				local rarity = csv.unit[cardCsv.unitID].rarity

				item:get("cardPanel"):show()
				bind.extend(list, item:get("cardPanel"), {
					class = "card_icon",
					props = {
						cardId = vv.cfg.cardID,
						rarity = rarity,
						grayState = vv.isHas and 0 or 2,
						selected = vv.isSel,
						onNode = function(node)
							node:xy(14, 3)
						end
					}
				})

				local y = h / 2 + (size.height + 15) * (branchCount / 2 - tmpRow + 0.5)

				if branchCount == 1 or branch == 0 then
					y = h / 2
				end

				local column = tmpColumn + i

				item:xy(size.width / 2 + (column - 1) * size.width, y)

				if not items[column] then
					items[column] = {}

					table.insert(develops, column)
				end

				table.insert(items[column], item)
				bind.touch(list, item:get("cardPanel"), {
					methods = {
						ended = functools.partial(list.clickCell, k, vv.order, vv.cfg.cardID, itemType)
					}
				})
			end
		end

		table.sort(develops)

		local lastItems = {}
		local isShow = true

		for i, column in ipairs(develops) do
			local developItems = items[column]

			addLine(lastItems, developItems)

			lastItems = developItems
		end

		local isChange = false

		for z, column in ipairs(develops) do
			local developItems = items[column]
			local len = #developItems

			for j, item in ipairs(developItems) do
				if not lastHasItem or lastHasItem == item then
					if len == 1 then
						isShow = false
					else
						isChange = true
					end
				end

				for i = 1, 3 do
					local line = item:getChildByName("redline" .. i)
					local lineBG = item:getChildByName("line" .. i)

					if line then
						line:visible(isShow and lineBG:visible())
					end
				end
			end

			isShow = isChange and not isShow or isShow
			isChange = false
		end
	else
		node:get("imgTitle"):visible(false)
		node:get("imgBg"):visible(false)
		node:get("list"):visible(true)

		local itemSize = list.cloneItem:size()

		node:size(cc.size(listW, itemSize.height + 10))
		node:get("list"):size(cc.size(listW, itemSize.height + 10))

		local binds = {
			class = "listview",
			props = {
				data = itemDatas,
				item = list.cloneItem,
				topPadding = padding,
				onItem = function(innerList, cell, kk, v)
					local size = cell:size()
					local cardInfo = csv.cards[v.cfg.cardID]
					local rarity = csv.unit[cardInfo.unitID].rarity

					bind.extend(innerList, cell, {
						class = "card_icon",
						props = {
							cardId = v.cfg.cardID,
							rarity = rarity,
							grayState = v.isHas and 0 or 2,
							selected = v.isSel,
							onNode = function(node)
								node:xy(14, 3)
							end
						}
					})
					cell:visible(true)
					bind.touch(list, cell, {
						methods = {
							ended = functools.partial(list.clickCell, k, kk, v.cfg.cardID, itemType)
						}
					})
				end
			}
		}

		bind.extend(list, node:get("list"), binds)
	end
end

local ViewBase = cc.load("mvc").ViewBase
local HandbookView = class("HandbookView", ViewBase)

HandbookView.RESOURCE_FILENAME = "handbook.json"
HandbookView.RESOURCE_BINDING = {
	center = "center",
	textName = "centerName",
	btnItem = "btnItem",
	["center.imgIcon"] = "imgIcon",
	attrTmp = "attrTmp",
	["center.imgIconBG"] = "imgIconBG",
	attrItem = "attrItem",
	item1 = "item1",
	starItem = "starItem",
	["center.textDesc"] = "textDescList",
	item = "item",
	["center.textLocation"] = "textLocation",
	left = {
		varname = "left",
		binds = {
			class = "sort_menus",
			event = "extend",
			props = {
				maxCount = 6,
				expandUp = true,
				ignoreSelected = true,
				data = bindHelper.self("sortTabData"),
				btnClick = bindHelper.self("onSortMenusBtnClick", true),
				btnTouch = bindHelper.self("onCloseOtherView", true),
				showSortList = bindHelper.self("isDownListShow"),
				showSelected = bindHelper.self("sortType"),
				onNode = function(node)
					node:xy(-1125, -485):z(20)
				end
			}
		}
	},
	["left.textCount"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("hasCount")
		}
	},
	["left.btnAttrSort"] = {
		varname = "btnAttr",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onShowAttrPanel")
			}
		}
	},
	["left.btnUp"] = {
		varname = "btnTupo",
		binds = {
			{
				event = "touch",
				methods = {
					ended = bindHelper.self("onShowTupoPanel")
				}
			},
			{
				class = "red_hint",
				event = "extend",
				props = {
					specialTag = "handbookAdvance"
				}
			}
		}
	},
	["left.list"] = {
		varname = "leftList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				backupCached = false,
				asyncPreload = 7,
				data = bindHelper.self("cardDatas"),
				item = bindHelper.self("item1"),
				cloneItem = bindHelper.self("item"),
				preloadCenterIndex = bindHelper.self("preloadCenterIndex"),
				itemAction = {
					alwaysShow = true,
					isAction = true
				},
				onItem = function(list, node, k, v)
					onInitItem(list, node, k, v)
				end
			},
			handlers = {
				clickCell = bindHelper.self("onClickItem")
			}
		}
	},
	["left.btnShowAttrAdd"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onShowAllAttrPanel")
			}
		}
	},
	["center.btnFeel"] = {
		varname = "btnFeel",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnFeel")
			}
		}
	},
	["center.btnFeel.note"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			}
		}
	},
	["center.btnComment"] = {
		varname = "btnComment",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnComment")
			}
		}
	},
	["center.btnComment.note"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			}
		}
	},
	["center.btnDetail"] = {
		varname = "btnDetail",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnDetail")
			}
		}
	},
	["center.btnDetail.note"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			}
		}
	},
	["center.attrPanel.hp.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("hpNum")
		}
	},
	["center.attrPanel.attack.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("damageNum")
		}
	},
	["center.attrPanel.special.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDamageNum")
		}
	},
	["center.attrPanel.phyFang.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("defenceNum")
		}
	},
	["center.attrPanel.speFang.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("specialDefenceNum")
		}
	},
	["center.attrPanel.speed.textNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("speedNum")
		}
	},
	["center.attrPanel.hp.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("hpPercent")
		}
	},
	["center.attrPanel.attack.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("damagePercent")
		}
	},
	["center.attrPanel.special.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("specialDamagePercent")
		}
	},
	["center.attrPanel.phyFang.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("defencePercent")
		}
	},
	["center.attrPanel.speFang.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("specialDefencePercent")
		}
	},
	["center.attrPanel.speed.progressBar"] = {
		binds = {
			event = "percent",
			idler = bindHelper.self("speedPercent")
		}
	},
	["center.starList"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("starDatas"),
				item = bindHelper.self("starItem"),
				onItem = function(list, node, k, v)
					node:get("icon"):texture(v.icon)
				end
			}
		}
	},
	["center.list"] = {
		varname = "centerList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("curCardAttrAdd"),
				item = bindHelper.self("attrItem"),
				onItem = function(list, node, k, v)
					local attrTypeStr = game.ATTRDEF_TABLE[v.attrType]
					local str = "attr" .. string.caption(attrTypeStr)
					local textName = node:get("textName")
					local textNum = node:get("textNum")

					textName:text(gLanguageCsv[str])
					textNum:text("+" .. v.val)

					local path = ui.ATTR_LOGO[game.ATTRDEF_TABLE[v.attrType]]

					node:get("imgIcon"):texture(path)

					local color = v.hasRole and cc.c4b(91, 81, 91, 255) or cc.c4b(183, 176, 158, 255)

					text.addEffect(textName, {
						color = color
					})
					text.addEffect(textNum, {
						color = color
					})
					adapt.setTextScaleWithWidth(textName, nil, 450)
					adapt.oneLinePos(node:get("imgIcon"), textName, cc.p(24, 0))
					adapt.oneLinePos(textName, textNum, cc.p(12, 0))

					local box = textNum:box()

					node:size(textNum:x() + box.width + 40, box.height)
				end
			},
			handlers = {
				clickItem = bindHelper.self("onChangeView")
			}
		}
	},
	["pageList.list"] = {
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("btnsData"),
				item = bindHelper.self("btnItem"),
				itemAction = {
					isAction = true
				},
				onItem = function(list, node, k, v)
					if v.key then
						node:name(v.key)
					end

					node:get("btnClick"):visible(v.state)
					node:get("btnNormal"):visible(not v.state)

					local curBtn = v.state and node:get("btnClick") or node:get("btnNormal")

					curBtn:get("textNote"):text(v.text)
					bind.touch(list, node:get("btnNormal"), {
						methods = {
							ended = functools.partial(list.clickItem, k, v)
						}
					})
				end
			},
			handlers = {
				clickItem = bindHelper.self("onChangeView")
			}
		}
	},
	["center.textHeightNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("textHight")
		}
	},
	["center.textWeightNum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("textWeight")
		}
	},
	upList = {
		varname = "upList",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("cardAttrs"),
				item = bindHelper.self("attrTmp"),
				onItem = function(list, node, k, v)
					local path = ui.ATTR_ICON[v]

					node:get("imgIcon"):texture(path)
				end
			}
		}
	},
	["center.attrPanel.textSum"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("allVal")
		}
	},
	["center.btnTestPlay"] = {
		varname = "btnTestPlay",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onBtnTestPlay")
			}
		}
	},
	["center.btnTestPlay.note"] = {
		binds = {
			event = "effect",
			data = {
				outline = {
					color = ui.COLORS.OUTLINE.WHITE
				}
			}
		}
	},
	["left.aidBtn"] = {
		varname = "aidBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAidClick")
			}
		}
	}
}

function HandbookView:resetData(tab, sortType)
	tab = tab or {}

	local cardsTab = csv.cards
	local unitTab = csv.unit
	local isSelectAid = self.isSelectAid:read()
	local tmp = {
		{}
	}

	local function sortFunc(t)
		table.sort(t, function(a, b)
			local cardInfoA = cardsTab[a.cfg.cardID]
			local rarityA = unitTab[cardInfoA.unitID].rarity
			local cardInfoB = cardsTab[b.cfg.cardID]
			local rarityB = unitTab[cardInfoB.unitID].rarity

			if rarityA == rarityB then
				return a.cfg.cardID < b.cfg.cardID
			end

			return rarityB < rarityA
		end)
	end

	if isSelectAid then
		for i, v in ipairs(tab) do
			if dataEasy.isOpenAid(v.cfg.cardID) then
				table.insert(tmp[1], v)
			end
		end

		sortFunc(tmp[1])

		return tmp
	end

	local t = {}

	if sortType == 1 or sortType == 2 then
		local dataTab = {}

		for i, v in ipairs(tab) do
			local cardInfo = cardsTab[v.cfg.cardID]
			local unitInfo = unitTab[cardInfo.unitID]
			local rarity = unitInfo.rarity
			local cardMarkID = cardInfo.cardMarkID
			local key = sortType == 1 and rarity or cardMarkID

			if not t[key] then
				t[key] = {}

				table.insert(dataTab, key)
			end

			table.insert(t[key], v)
		end

		table.sort(dataTab, function(a, b)
			if sortType == 1 then
				return b < a
			else
				return a < b
			end
		end)

		local t1 = {}

		for _, key in ipairs(dataTab) do
			table.insert(t1, t[key])
		end

		t = t1

		for k, v in ipairs(t) do
			table.sort(v, function(a, b)
				local cardIdA = a.cfg.cardID
				local cardIdB = b.cfg.cardID

				if sortType == 1 then
					return cardIdA < cardIdB
				end

				local infoA = cardsTab[cardIdA]
				local infoB = cardsTab[cardIdB]

				if infoA.develop ~= infoB.develop then
					return infoA.develop < infoB.develop
				end

				return infoA.branch < infoB.branch
			end)
		end
	elseif sortType == 3 or sortType == 4 then
		t[1] = {}

		for i, v in ipairs(tab) do
			if sortType == 3 and self.pokedex:read()[v.cfg.cardID] or sortType == 4 and not self.pokedex:read()[v.cfg.cardID] then
				table.insert(t[1], v)
			end
		end

		sortFunc(t[1])
	elseif sortType == 5 or sortType == 6 then
		t[1] = {}

		local maxStarCards = {}

		for k, v in ipairs(gGameModel.role:read("cards")) do
			local card = gGameModel.cards:find(v)
			local cardId = card:read("card_id")
			local star = card:read("star")

			maxStarCards[csv.cards[cardId].cardMarkID] = maxStarCards[csv.cards[cardId].cardMarkID] and math.max(star, maxStarCards[csv.cards[cardId].cardMarkID]) or star
		end

		for i, v in ipairs(tab) do
			local cardInfo = cardsTab[v.cfg.cardID]
			local myMaxStar = maxStarCards[cardInfo.cardMarkID] or 0

			if sortType == 5 and self.pokedex:read()[v.cfg.cardID] and (cardInfo.cardType == 1 and myMaxStar >= 12 or cardInfo.cardType == 2 and myMaxStar >= 2) then
				table.insert(t[1], v)
			elseif sortType == 6 and (not self.pokedex:read()[v.cfg.cardID] or cardInfo.cardType == 1 and myMaxStar < 12 or cardInfo.cardType == 2 and myMaxStar < 2) then
				table.insert(t[1], v)
			end
		end

		sortFunc(t[1])
	end

	return t
end

function HandbookView:onCreate(params)
	params = params or {}
	self.leftColumnSize = LINE_NUM

	self:initModel()
	gGameModel.handbook:getIdlerOrigin("isNew"):set(false)
	gGameUI.topuiManager:createView("title", self, {
		onClose = self:createHandler("onClose")
	}):init({
		subTitle = "HANDBOOK",
		title = gLanguageCsv.handbookTitle
	})

	self.isDownListShow = idler.new(false)
	self.selItemInfo = self.selItemInfo or {}
	self.sortTabData = idlertable.new({
		gLanguageCsv.rarity,
		gLanguageCsv.levelUp,
		gLanguageCsv.alreadyHas,
		gLanguageCsv.notOwn,
		gLanguageCsv.cardStarMax,
		gLanguageCsv.cardStarNotMax
	})
	self.isShowNaturePanel = idler.new(false)
	self.textDesc = idler.new("")
	self.textAddNum = idler.new("")
	self.textHight = idler.new("")
	self.textWeight = idler.new("")
	self.hasCount = idler.new(itertools.size(self.pokedex:read()))
	self.allVal = idler.new(0)
	self.curSelAttrs = idlertable.new({})
	self.cardAttrs = idlertable.new({})
	self.sortType = idler.new(1)
	self.oldSortType = 1
	self._selCardId = self._selCardId or params.cardId
	self.selCardId = idler.new(self._selCardId or 0)
	self.curSelBtn = self.curSelBtn or 1
	self.isSelectAid = idler.new(false)
	self.btnsData = idlers.new()

	local natureDatas = {}

	for i = 1, #game.NATURE_TABLE do
		table.insert(natureDatas, {
			state = false
		})
	end

	self.natureDatas = idlers.newWithMap(self._natureDatas or natureDatas)
	self.cardDatas = idlers.newWithMap({})
	self.cardTabDatas = {}

	idlereasy.any({
		self.sortType,
		self.curSelAttrs
	}, function(_, sortType, curSelAttrs)
		self:refreshSortCardIdlersData()
	end)

	local originalPos = self.aidBtn:get("btnImg"):x()

	idlereasy.when(self.isSelectAid, function(_, isSelectAid)
		local img = isSelectAid and "city/setting/btn_on.png" or "city/setting/btn_off.png"
		local btnImgPosX = isSelectAid and originalPos + 70 or originalPos

		self.aidBtn:get("btnBg"):texture(img)
		self.aidBtn:get("btnImg"):x(btnImgPosX)

		local oldval = self.curSelBtn

		if not dataEasy.isOpenAid(self.selCardId:read()) and self.curSelBtn == 5 then
			self.btnsData:atproxy(5).state = false
			self.btnsData:atproxy(1).state = true
			self.curSelBtn = 1
		end

		self:refreshSortCardIdlersData()
		self:updateTabData()
		self:onChangeView(nil, self.curSelBtn)
	end)

	local keys = {
		"hpNum",
		"speedNum",
		"damageNum",
		"defenceNum",
		"specialDamageNum",
		"specialDefenceNum"
	}
	local percentKeys = {
		"hpPercent",
		"speedPercent",
		"damagePercent",
		"defencePercent",
		"specialDamagePercent",
		"specialDefencePercent"
	}

	self.hpNum = idler.new(0)
	self.hpPercent = idler.new(0)
	self.damageNum = idler.new(0)
	self.damagePercent = idler.new(0)
	self.specialDamageNum = idler.new(0)
	self.specialDamagePercent = idler.new(0)
	self.defenceNum = idler.new(0)
	self.defencePercent = idler.new(0)
	self.specialDefenceNum = idler.new(0)
	self.specialDefencePercent = idler.new(0)
	self.speedNum = idler.new(0)
	self.speedPercent = idler.new(0)
	self.curCardAttrAdd = idlers.newWithMap({})
	self.starDatas = idlers.new({})

	local attrDatas = {
		0,
		nil,
		nil,
		nil,
		nil,
		nil,
		0,
		0,
		0,
		0,
		nil,
		nil,
		0
	}

	for cardId, _ in pairs(self.pokedex:read()) do
		local csvData = gHandbookCsv[cardId]

		if csvData then
			for i = 1, math.huge do
				local attrType = csvData["attrType" .. i]

				if not attrType then
					break
				end

				local idx = 1

				if attrType >= 9 then
					idx = 2
				end

				local val, numType = dataEasy.parsePercentStr(csvData["attrValue" .. i])

				attrDatas[attrType] = attrDatas[attrType] + val
			end
		end
	end

	self.attrDatas = idlers.newWithMap(attrDatas)

	dataEasy.getListenUnlock(gUnlockCsv.aid, function(isUnlock)
		self.aidBtn:visible(isUnlock)
	end)
	dataEasy.getListenUnlock(gUnlockCsv.cardComment, function(isUnlock)
		self.btnComment:visible(isUnlock)
		adapt.oneLinePos(self.btnFeel, {
			self.btnComment,
			self.btnTestPlay
		}, cc.p(20, 0), "right")
	end)
	dataEasy.getListenUnlock(gUnlockCsv.testPlay, function(isUnlock)
		self:refreshTestPlayBtn()
	end)
	idlereasy.when(self.selCardId, function(_, cardId)
		local cardInfo = csv.cards[cardId]

		self:refreshTestPlayBtn()

		if cardInfo then
			self.textLocation:text(cardInfo.location)

			local pokedexInfo = gHandbookCsv[cardId]
			local heightAndWeight = pokedexInfo.heightAndWeight
			local cardWeight = heightAndWeight[2] .. "kg"
			local cardHeight = heightAndWeight[1] .. "m"
			local cardDesc = cardInfo.introduction

			self.centerName:text(cardInfo.name)
			self.centerName:ignoreContentAdaptWithSize(true)
			self.centerName:getVirtualRenderer():setDimensions(0, 0)
			self.centerName:setFontSize(50)

			if self.centerName:width() > 450 then
				adapt.setTextAdaptWithSize(self.centerName, {
					vertical = "center",
					horizontal = "left",
					size = cc.size(450, 100)
				})
			end

			adapt.oneLinePos(self.centerName, self.upList, cc.p(28, 0))

			local curCardAttrAdd = {}

			for i = 1, math.huge do
				local attrType = pokedexInfo["attrType" .. i]

				if not attrType then
					break
				end

				local hasRole = self.pokedex:read()[cardId] ~= nil
				local num, isPercent = dataEasy.parsePercentStr(pokedexInfo["attrValue" .. i])
				local val = mathEasy.getPreciseDecimal(num, 2)

				if isPercent then
					val = val .. "%"
				end

				table.insert(curCardAttrAdd, {
					attrType = attrType,
					val = val,
					hasRole = hasRole
				})
			end

			self.curCardAttrAdd:update(curCardAttrAdd)
			self:resetStarData()

			local color = cc.c3b(57, 253, 57)

			if not self.pokedex:read()[cardId] then
				color = cc.c3b(150, 184, 227)
				cardWeight = "???"
				cardHeight = "???"
				cardDesc = "???"
			end

			self.textHight:set(cardHeight)
			self.textWeight:set(cardWeight)
			beauty.textScroll({
				isRich = true,
				strs = "",
				list = self.textDescList
			})
			beauty.textScroll({
				isRich = true,
				list = self.textDescList,
				strs = "#C0x5B545B#" .. cardDesc
			})

			local unitID = cardInfo.unitID
			local unitInfo = csv.unit[unitID]

			if self.imgIcon:getChildByName("shiny") then
				self.imgIcon:removeChildByName("shiny")
			end

			self.imgIcon:texture(unitInfo.cardShow)
			self.imgIcon:show()

			if unitInfo.shinyRes then
				local effect = widget.addAnimationByKey(self.imgIcon, unitInfo.shinyRes, "shiny", "effect_loop", 3):setAnchorPoint(cc.p(0.5, 0.5)):xy(self.imgIcon:width() / 2, self.imgIcon:height() / 2)
			end

			if self.imgIconBG:getChildByName("cardSpine") then
				self.imgIconBG:removeChildByName("cardSpine")
			end

			local myMaxStar, _, _ = dataEasy.getCardMaxStar(cardInfo.cardMarkID)
			local needstar = unitInfo.cardSpineNeedStar
			local cardCsv = csv.cards
			local isHas = self.pokedex:read()[cardId] ~= nil

			if needstar == 0 or isHas and unitInfo.cardSpine and needstar <= myMaxStar then
				local effect = widget.addAnimationByKey(self.imgIconBG, unitInfo.cardSpine, "cardSpine", "effect_loop", 3):setAnchorPoint(cc.p(0.5, 0.5)):xy(self.imgIconBG:width() / 2 + unitInfo.cardSkinPos.x, self.imgIconBG:height() / 2 + unitInfo.cardSkinPos.y):scale(unitInfo.cardSkinScale)

				self.imgIcon:hide()
			end

			local specValue = cardInfo.specValue

			for i, v in ipairs(specValue) do
				if i > 6 then
					self.allVal:set(v)

					break
				end

				self[keys[i]]:set(v)
				self[percentKeys[i]]:set(v / 255 * 100)
			end

			local natureAttr = {}

			table.insert(natureAttr, unitInfo.natureType)

			if unitInfo.natureType2 then
				table.insert(natureAttr, unitInfo.natureType2)
			end

			self.cardAttrs:set(natureAttr)
		else
			self.centerName:text("")
			beauty.textScroll({
				isRich = true,
				strs = "",
				list = self.textDescList
			})
			self.textAddNum:set("")
			self.textHight:set("")
			self.textWeight:set("")
			self.imgIcon:visible(false)

			for i = 1, 7 do
				if i > 6 then
					self.allVal:set(0)

					break
				end

				self[keys[i]]:set(0)
				self[percentKeys[i]]:set(0)
			end

			self.cardAttrs:set({})
		end

		self:updateTabData()
		self:onChangeView(nil, self.curSelBtn)
	end)

	if matchLanguage({
		"en",
		"kr"
	}) then
		adapt.setTextAdaptWithSize(self.textLocation, {
			vertical = "center",
			margin = -5,
			horizontal = "left",
			size = cc.size(460, 100)
		})
	end

	self.attrPanel = gGameUI:createView("common.attr_filter", self):init({
		isMultiSelect = true,
		selectDatas = self:createHandler("natureDatas"),
		panelState = self:createHandler("isShowNaturePanel")
	}):anchorPoint(0.5, 0):xy(-720, -195):z(20)

	idlereasy.if_not(self.isShowNaturePanel, function()
		self:onSureSelNature()
	end)
	idlereasy.when(self.isShowNaturePanel, function(_, isShow)
		self.attrPanel:visible(isShow)
	end)
	uiEasy.updateUnlockRes(gUnlockCsv.cardLike, self.btnFeel, {
		pos = cc.p(120, 100)
	})
	idlereasy.any({
		self.cardFeels,
		self.selCardId,
		self.roleLevel
	}, function(_, cardFeels, selCardId)
		local cardFeel = cardFeels[csv.cards[selCardId].cardMarkID] or {}

		self.btnFeel:get("level"):text(cardFeel.level or 0)
	end)

	if self._sortType or params.sortType then
		self.sortType:set(self._sortType or params.sortType)
	end

	self:onChangeView(nil, self.curSelBtn)

	self._selCardId = nil

	adapt.setTextScaleWithWidth(self.btnComment:get("note"), nil, 140)
	adapt.setTextScaleWithWidth(self.btnTestPlay:get("note"), nil, 140)
	self.centerList:z(2)
end

function HandbookView:updateTabData()
	if not dataEasy.isOpenAid(self.selCardId:read()) and self.curSelBtn == 5 then
		self.btnsData:atproxy(5).state = false
		self.btnsData:atproxy(1).state = true
		self.curSelBtn = 1
	end

	local btnsData = {
		{
			text = gLanguageCsv.detail,
			state = self.curSelBtn == 1,
			func = function()
				self.center:visible(true)
				self.centerName:visible(true)
				self.upList:visible(true)
			end
		},
		{
			text = gLanguageCsv.produce,
			state = self.curSelBtn == 2,
			func = function(params)
				self.center:visible(false)
				self.centerName:visible(false)
				self.upList:visible(false)

				return gGameUI:createView("city.handbook.gain_way", self):init(params)
			end
		},
		{
			text = gLanguageCsv.skill,
			state = self.curSelBtn == 3,
			func = function(params)
				self.center:visible(false)
				self.centerName:visible(true)
				self.upList:visible(true)

				return gGameUI:createView("city.handbook.skill", self):init(params)
			end
		},
		{
			text = gLanguageCsv.fetter,
			state = self.curSelBtn == 4,
			func = function(params)
				self.center:visible(false)
				self.centerName:visible(true)
				self.upList:visible(true)

				return gGameUI:createView("city.handbook.fetter", self):init(params)
			end
		}
	}

	if dataEasy.isUnlock(gUnlockCsv.aid) then
		if dataEasy.isOpenAid(self.selCardId:read()) then
			btnsData[5] = {
				key = "aid",
				text = gLanguageCsv.aid,
				state = self.curSelBtn == 5,
				func = function(params)
					self.center:visible(false)
					self.centerName:visible(false)
					self.upList:visible(false)

					return gGameUI:createView("city.handbook.aid", self):init(params)
				end
			}
		elseif self.curSelBtn == 5 then
			self.curSelBtn = 1
		end
	end

	self.btnsData:update(btnsData)
end

function HandbookView:jumpToCard(cardDatas)
	if self._selCardId then
		for row, t in ipairs(cardDatas) do
			for idx, v in ipairs(t) do
				if v.cfg and v.cfg.cardID == self._selCardId then
					cardDatas[row][idx].isSel = true
					self.selItemInfo = {
						row = row,
						idx = idx
					}

					self.selCardId:set(self._selCardId)

					self.preloadCenterIndex = row

					return true
				end
			end
		end
	end
end

function HandbookView:getOriginData(sortType)
	local cardDatas = {}
	local isSelectAid = self.isSelectAid:read()

	for i, v in ipairs(gHandbookArrayCsv) do
		local itemData = {}

		itemData.cfg = v
		itemData.itemType = sortType

		if isSelectAid and sortType == 2 then
			itemData.itemType = 1
		end

		itemData.isHas = self.pokedex:read()[v.cardID] ~= nil
		itemData.isSel = false

		if self.curSelAttrs:size() > 0 then
			local cardInfo = csv.cards[v.cardID]
			local unitInfo = csv.unit[cardInfo.unitID]

			if itertools.include(self.curSelAttrs:proxy(), unitInfo.natureType) or itertools.include(self.curSelAttrs:proxy(), unitInfo.natureType2) then
				table.insert(cardDatas, itemData)
			end
		else
			table.insert(cardDatas, itemData)
		end
	end

	return cardDatas
end

function HandbookView:refreshSortCardIdlersData()
	self.leftList:jumpToTop()

	local sortType = self.sortType:read()
	local isSelectAid = self.isSelectAid:read()
	local cardDatas = self:getOriginData(sortType)

	cardDatas = self:resetData(cardDatas, sortType)
	cardDatas = self:resetDataStruct(cardDatas, sortType)

	local row = sortType == 1 and 2 or 1
	local isSelectAid = self.isSelectAid:read()

	if isSelectAid then
		row = cardDatas[1][1].itemType == "title" and 2 or 1
	end

	if not self:jumpToCard(cardDatas) and cardDatas[row] and cardDatas[row][1] then
		cardDatas[row][1].isSel = true
		self.selItemInfo = {
			idx = 1,
			row = row
		}

		self.selCardId:set(cardDatas[row][1].cfg.cardID)
	end

	self.cardDatas:update(cardDatas)
end

function HandbookView:resetStarData()
	local cardInfo = csv.cards[self.selCardId:read()]
	local myMaxStar, _, _ = dataEasy.getCardMaxStar(cardInfo.cardMarkID)

	self.starDatas:update(dataEasy.getStarData(myMaxStar))

	local attrIcon, attrName, attrNum = handbookTools.getStarAttrData(cardInfo.cardMarkID)

	handbookTools.setAttrPanel(self.center:get("starAttr"), attrIcon, attrName, attrNum)

	local hasRole = self.pokedex:read()[self.selCardId:read()] ~= nil
	local color = hasRole and cc.c4b(91, 81, 91, 255) or cc.c4b(183, 176, 158, 255)

	text.addEffect(self.center:get("starAttr.textName"), {
		color = color
	})
	text.addEffect(self.center:get("starAttr.textNum"), {
		color = color
	})
end

function HandbookView:resetDataStruct(data, _type)
	local isSelectAid = self.isSelectAid:read()

	if _type == 2 and not isSelectAid then
		return data
	end

	local originalData = table.deepcopy(data, true)

	if isSelectAid then
		local temp = {}
		local activeAid = self.activeAid:read()
		local t = {}

		for k, val in ipairs(originalData[1] or {}) do
			local cardInfo = csv.cards[val.cfg.cardID]
			local aidID = cardInfo.aidID

			if not itertools.isempty(t) and itertools.size(t) % 4 == 0 then
				table.insert(temp, t)

				t = {}
			end

			if activeAid[aidID] then
				table.insert(t, val)
			end
		end

		if #t > 0 then
			table.insert(temp, t)
		end

		table.insert(temp, {
			{
				titleType = "aid",
				itemType = "title"
			}
		})

		t = {}

		for k, val in ipairs(originalData[1] or {}) do
			local cardInfo = csv.cards[val.cfg.cardID]
			local aidID = cardInfo.aidID

			if not itertools.isempty(t) and itertools.size(t) % 4 == 0 then
				table.insert(temp, t)

				t = {}
			end

			if not activeAid[aidID] then
				table.insert(t, val)
			end
		end

		if #t > 0 then
			table.insert(temp, t)
		end

		return temp
	end

	local newDatas = {}

	if _type == 1 then
		local hasTitle = false

		for i, v in ipairs(data) do
			hasTitle = false

			local t = {}

			for k, val in ipairs(v) do
				if not hasTitle then
					hasTitle = true

					local cardInfo = csv.cards[val.cfg.cardID]
					local rarity = csv.unit[cardInfo.unitID].rarity

					table.insert(newDatas, {
						{
							itemType = "title",
							val = rarity
						}
					})
				end

				if k % 4 == 1 then
					if k > 4 then
						table.insert(newDatas, t)
					end

					t = {}
				end

				table.insert(t, val)
			end

			if #t > 0 then
				table.insert(newDatas, t)

				t = {}
			end
		end
	else
		local t = {}
		local count = 0

		for i, v in ipairs(data[1] or {}) do
			if i % 4 == 1 then
				if i > 4 then
					count = count + 1

					table.insert(newDatas, t)
				end

				t = {}
			end

			table.insert(t, v)
		end

		if #t > 0 then
			table.insert(newDatas, t)
		end
	end

	return newDatas
end

function HandbookView:initModel()
	self.pokedex = gGameModel.role:getIdler("pokedex")
	self.cardFeels = gGameModel.role:getIdler("card_feels")
	self.roleLevel = gGameModel.role:getIdler("level")
	self.activeAid = gGameModel.role:getIdler("active_aid")
	self.allAid = gGameModel.role:getIdler("aid")
end

function HandbookView:onCleanup()
	self._sortType = self.sortType:read()
	self._selCardId = self.selCardId:read()
	self._natureDatas = {}

	for _, v in self.natureDatas:ipairs() do
		table.insert(self._natureDatas, table.deepcopy(v:read(), true))
	end

	ViewBase.onCleanup(self)
end

function HandbookView:onShowAttrPanel(node, event)
	self.isShowNaturePanel:modify(function(oldval)
		return true, not oldval
	end)
	self.isDownListShow:set(false)
end

function HandbookView:onSureSelNature(node, event)
	local t = {}

	for i = 1, #game.NATURE_TABLE do
		local isSel = self.natureDatas:atproxy(i).state

		if isSel then
			table.insert(t, i)
		end
	end

	self.curSelAttrs:set(t)
end

function HandbookView:onClickItem(node, row, idx, cardId, itemType)
	self.cardDatas:atproxy(self.selItemInfo.row)[self.selItemInfo.idx].isSel = false
	self.selItemInfo = {
		row = row,
		idx = idx
	}
	self.cardDatas:atproxy(row)[idx].isSel = true

	self.selCardId:set(cardId)
end

function HandbookView:onShowTupoPanel(node, event)
	gGameUI:stackUI("city.handbook.break", nil, {
		blackLayer = true
	})
end

function HandbookView:onSortMenusBtnClick(node, layout, idx, val)
	if self.isSelectAid:read() == true then
		gGameUI:showTip(gLanguageCsv.handbookAlreadyAid)
		self.isDownListShow:set(false)

		return
	end

	local cardDatas = self:getOriginData(idx)

	cardDatas = self:resetData(cardDatas, idx)

	if itertools.size(cardDatas[1]) <= 0 then
		self.sortType:set(self.oldSortType)
		self.isDownListShow:set(true)
		gGameUI:showTip(gLanguageCsv.filtrateTips)

		return
	end

	self.oldSortType = idx

	self.sortType:set(idx)
end

function HandbookView:onCloseOtherView(node, btn)
	if self.isSelectAid:read() == true then
		gGameUI:showTip(gLanguageCsv.handbookAlreadyAid)
		self.isDownListShow:set(false)

		return
	end

	self.isShowNaturePanel:set(false)
end

function HandbookView:onBtnComment()
	local handbookCsv = gHandbookCsv[self.selCardId:read()]

	if handbookCsv and not handbookCsv.isOpen then
		gGameUI:showTip(gLanguageCsv.currentVersionNotOpen)

		return
	end

	gGameApp:requestServer("/game/card/comment/list", function(tb)
		gGameApp:requestServer("/game/card/score/get", function(score)
			gGameUI:stackUI("city.card.comment", nil, {
				full = true
			}, self.selCardId:read(), tb.view, score.view)
		end, self.selCardId:read())
	end, self.selCardId:read(), 0, 20)
end

function HandbookView:refreshTestPlayBtn()
	self.btnTestPlay:hide()
	adapt.oneLinePos(self.btnFeel, {
		self.btnComment,
		self.btnTestPlay
	}, cc.p(20, 0), "right")

	if not dataEasy.isUnlock(gUnlockCsv.testPlay) then
		return
	end

	local cardID = self.selCardId:read()
	local cardData = csv.experience.list[cardID]

	if cardData and matchLanguageForce(cardData.languages) and cardData.handBookIsShow then
		self.btnTestPlay:show()
		adapt.oneLinePos(self.btnFeel, {
			self.btnComment,
			self.btnTestPlay
		}, cc.p(20, 0), "right")
	end
end

function HandbookView:onBtnTestPlay()
	gGameUI:stackUI("city.experience.embattle_view", nil, {
		full = true
	}, self.selCardId:read())
end

function HandbookView:onBtnFeel()
	local selCardId = self.selCardId:read()
	local cardCfg = csv.cards[selCardId]
	local handbookCsv = gHandbookCsv[selCardId]

	if handbookCsv and not handbookCsv.isOpen then
		gGameUI:showTip(gLanguageCsv.currentVersionNotOpen)

		return
	end

	if csvSize(cardCfg.feelItems) <= 0 then
		gGameUI:showTip(gLanguageCsv.notDevelopFeel)

		return
	end

	if not dataEasy.isUnlock(gUnlockCsv.cardLike) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.cardLike))

		return
	end

	if csv.card_mega[cardCfg.megaIndex] and not dataEasy.isUnlock(gUnlockCsv.mega) then
		gGameUI:showTip(dataEasy.getUnlockTip(gUnlockCsv.mega))

		return
	end

	local cardID = self.cardDatas:atproxy(self.selItemInfo.row)[self.selItemInfo.idx].cfg.cardID
	local cardCsv = csv.cards
	local isHas = false

	for k, v in pairs(self.pokedex:read()) do
		if cardCsv[k].cardMarkID == cardCsv[cardID].cardMarkID then
			isHas = true

			break
		end
	end

	if not isHas then
		gGameUI:showTip(gLanguageCsv.wizardNotActivated)

		return
	end

	gGameUI:stackUI("city.card.feel.view", nil, nil, selCardId)
end

function HandbookView:onBtnDetail()
	local handbookCsv = gHandbookCsv[self.selCardId:read()]

	if handbookCsv and not handbookCsv.isOpen then
		gGameUI:showTip(gLanguageCsv.currentVersionNotOpen)

		return
	end

	gGameUI:stackUI("city.handbook.detail", nil, nil, self.selCardId:read(), self:createHandler("resetStarData"))
end

function HandbookView:onShowAllAttrPanel()
	gGameUI:stackUI("city.handbook.add_attr", nil, {
		blackLayer = false,
		clickClose = true
	})
end

function HandbookView:onChangeView(node, idx, val)
	if self.btnsData:atproxy(self.curSelBtn) then
		self.btnsData:atproxy(self.curSelBtn).state = false
	end

	local func

	if self.btnsData:atproxy(idx) then
		self.btnsData:atproxy(idx).state = true
		func = self.btnsData:atproxy(idx).func
	end

	self.curSelBtn = idx
	func = self.btnsData:atproxy(idx).func

	if func then
		if self.childView then
			self.childView:onClose()
		end

		self.childView = func({
			selCardId = self:createHandler("selCardId")
		})
	end

	adapt.oneLinePos(self.centerName, self.upList, cc.p(28, 0))
end

function HandbookView:onAidClick()
	self.isSelectAid:set(not self.isSelectAid:read())
end

return HandbookView
