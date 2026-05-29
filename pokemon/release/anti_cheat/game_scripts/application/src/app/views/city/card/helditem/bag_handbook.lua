-- chunkname: @src.app.views.city.card.helditem.bag_handbook

local HeldItemTools = require("app.views.city.card.helditem.tools")
local BagHandbookView = class("BagHandbookView", Dialog)
local BTN_TEXT1 = {
	"",
	"btn_green.png",
	"btn_blue.png",
	"btn_purple.png",
	"btn_orange.png",
	"btn_red2.png"
}
local BTN_TEXT2 = {
	"",
	"btn_green_1.png",
	"btn_blue_1.png",
	"btn_purple_1.png",
	"btn_orange_1.png",
	"btn_red2_1.png"
}
local TAG_TEXT = {
	"",
	"label_green.png",
	"label_blue.png",
	"label_purple.png",
	"label_orange.png",
	"label_red2.png"
}
local qualityNumber = {
	1,
	5,
	4,
	3,
	2
}

for i, v in ipairs(qualityNumber) do
	qualityNumber[v] = i
end

BagHandbookView.RESOURCE_FILENAME = "held_item_bag_handbook.json"
BagHandbookView.RESOURCE_BINDING = {
	innweList = "innweList",
	item = "item",
	icon = "icon",
	left = "left",
	["right.rightInfo.item"] = "rightInfoItem",
	["right.rightInfo"] = "rightInfo",
	item1 = "item1",
	attrInnerList = "attrInnerList",
	["right.textName"] = "heldItemName",
	["right.item"] = "rightItem",
	["right.center.textHoldEffect"] = "textHoldEffect",
	["right.center.list"] = "rightCenterList",
	["right.center"] = "rightCenter",
	right = {
		varname = "rightPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("isVisibleRight")
		}
	},
	["left.list"] = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				leftPadding = 10,
				topPadding = 10,
				columnSize = 4,
				asyncPreload = 20,
				data = bindHelper.self("heldItems"),
				item = bindHelper.self("innweList"),
				cell = bindHelper.self("item"),
				itemAction = {
					alwaysShow = true,
					isAction = true
				},
				onCell = function(list, node, k, v)
					node:get("imgSel"):visible(v.isSel)

					local csvItemTab = csv.held_item.items
					local csvEffTab = csv.held_item.effect

					bind.extend(list, node, {
						class = "icon_key",
						props = {
							noListener = true,
							data = {
								key = v.csvId
							},
							onNode = function(panel)
								local t = list:getIdx(k)

								bind.click(list, panel, {
									method = functools.partial(list.clickCell, t, v)
								})
							end
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onItemClick")
			}
		}
	},
	["right.list"] = {
		varname = "rightlist",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 2,
				data = bindHelper.self("attrs"),
				item = bindHelper.self("attrInnerList"),
				cell = bindHelper.self("item1"),
				onCell = function(list, node, k, v)
					local attr = game.ATTRDEF_TABLE[v.attr]
					local attrName = gLanguageCsv["attr" .. string.caption(attr)]
					local path = ui.ATTR_LOGO[attr]

					node:get("imgIcon"):texture(path)
					node:get("textAttrName"):text(attrName)
					node:get("textAttrNum"):text("+" .. v.val)
					adapt.oneLinePos(node:get("textAttrName"), node:get("textAttrNum"), cc.p(10, 0), "left")
				end
			}
		}
	},
	["right.center.btnInfo"] = {
		varname = "btnInfo",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onInfoClick")
			}
		}
	},
	["right.rightInfo.list"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("rightInfoData"),
				item = bindHelper.self("rightInfoItem"),
				onItem = function(list, node, k, v)
					node:setTouchEnabled(true)

					local normal = node:get("normal")
					local selected = node:get("selected")

					normal:setTouchEnabled(true)
					normal:texture("city/card/helditem/bag/" .. (BTN_TEXT1[v.quality] or "btn_red.png"))
					selected:texture("city/card/helditem/bag/" .. (BTN_TEXT2[v.quality] or "btn_red_1.png"))

					local panel

					if v.select then
						normal:hide()

						panel = selected:show()
					else
						selected:hide()

						panel = normal:show()
					end

					if not v.quality then
						panel:get("txt"):text(gLanguageCsv.all)
					else
						panel:get("txt"):text(gLanguageCsv[ui.QUALITY_COLOR_TEXT[v.quality]])
					end

					adapt.setTextScaleWithWidth(panel:get("txt"), nil, panel:width() - 40)
					bind.touch(list, normal, {
						methods = {
							ended = functools.partial(list.selectQuality, v)
						}
					})
				end
			},
			handlers = {
				selectQuality = bindHelper.self("onSelectQuality")
			}
		}
	}
}

function BagHandbookView:onCreate(cardDbId)
	Dialog.onCreate(self)
	self:initModel()

	self.cardDbId = cardDbId or self.cards:read()[1]
	self.isVisibleRight = idler.new(false)
	self.heldItems = idlers.newWithMap({})
	self.showLeftSelected = idler.new(1)
	self.showRightSelected = idler.new(1)

	self.attrInnerList:setScrollBarEnabled(false)

	self.curBtnState = idler.new(1)
	self.attrs = idlers.newWithMap({})

	idlereasy.when(self.isVisibleRight, function(_, isVisibleRight, xxx)
		local centerPos = display.sizeInView.width / 2
		local width = self.left:size().width
		local x = isVisibleRight and centerPos - width / 2 - 17 or centerPos

		self.left:x(x)
	end)

	local csvTab = csv.held_item.items

	local function baseSort(a, b)
		local infoA = csvTab[a.csvId]
		local infoB = csvTab[b.csvId]

		if infoA.quality ~= infoB.quality then
			return infoA.quality > infoB.quality
		end

		if a.isExc ~= b.isExc then
			return a.isExc
		end

		if a.csvId ~= b.csvId then
			return a.csvId < b.csvId
		end

		return a.num < b.num
	end

	idlereasy.any({
		self.showLeftSelected,
		self.showRightSelected,
		self.quality
	}, function(_, left, right, quality)
		local t = {}
		local count = 0

		for i, v in ipairs(self.tableDatas) do
			count = count + 1

			if quality then
				if csvTab[v.csvId].quality == quality then
					table.insert(t, clone(v))
				end
			else
				table.insert(t, clone(v))
			end
		end

		table.sort(t, function(a, b)
			if right == 1 then
				return baseSort(a, b)
			end
		end)

		t[1].isSel = true

		self.heldItems:update(t)
		self.selIdx:set(1, true)
		self.isVisibleRight:set(count > 0)
	end)
	self.selIdx:addListener(function(idx, oldval)
		if oldval ~= idx then
			if oldval ~= -1 and self.heldItems:atproxy(oldval) and self.heldItems:atproxy(oldval).isSel ~= false then
				self.heldItems:atproxy(oldval).isSel = false
			end

			if self.heldItems:atproxy(idx).isSel ~= true then
				self.heldItems:atproxy(idx).isSel = true
			end
		end

		local csvTab = csv.held_item.items
		local effectTab = csv.held_item.effect
		local info = self.heldItems:atproxy(idx)
		local state = 1
		local str = gLanguageCsv.spaceEquip
		local nameStr = info.cfg.name

		if info.advance > 0 then
			nameStr = string.format("%s +%d", info.cfg.name, info.advance)
		end

		self.heldItemName:text(nameStr)
		text.addEffect(self.heldItemName, {
			color = info.cfg.quality and ui.COLORS.QUALITY[info.cfg.quality] or ui.COLORS.NORMAL.DEFAULT
		})
		adapt.setTextAdaptWithSize(self.heldItemName, {
			vertical = "center",
			horizontal = "left",
			size = cc.size(580, 120)
		})
		bind.extend(self, self.rightItem, {
			class = "icon_key",
			props = {
				noListener = true,
				data = {
					key = info.csvId
				}
			}
		})

		local attrTypes = info.cfg.attrTypes
		local attrNumRates = info.cfg.attrNumRates
		local advanceAttrTab = csv.held_item.advance_attrs[info.advance]
		local advAttrNum = advanceAttrTab["attrNum" .. info.cfg.advanceAttrSeq]
		local advAttrRate = advanceAttrTab["attrRate" .. info.cfg.advanceAttrSeq]
		local lvAttrNum = csv.held_item.level_attrs[info.lv]["attrNum" .. info.cfg.strengthAttrSeq]
		local t = {}

		for i, v in ipairs(attrTypes) do
			local data = {}

			data.attr = v
			data.val = math.floor(attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i]))

			table.insert(t, data)
		end

		self.attrs:update(t)

		local strTab = {}

		for i = 1, 100 do
			local effectVal = info.cfg[string.format("effect%dLevelAdvSeq", i)]
			local curAdv = 0

			if not info.cfg["effect" .. i] or info.cfg["effect" .. i] == 0 or not effectVal or curAdv < effectVal[1] then
				break
			end

			local resultStr = HeldItemTools.getStrinigByData(i, info)

			table.insert(strTab, resultStr)
		end

		local targetStr = "#C0x5B545B#" .. table.concat(strTab, "\n")
		local list = beauty.textScroll({
			isRich = true,
			fontSize = 40,
			list = self.rightCenterList,
			strs = targetStr
		})
	end)
	idlereasy.when(self.quality, function(_, quality)
		for _, v in self.rightInfoData:pairs() do
			local data = v:proxy()

			data.select = data.quality == quality

			if data.select then
				self.icon:texture("city/card/helditem/bag/" .. (TAG_TEXT[quality] or "label_red.png"))
			end
		end
	end)
	adapt.oneLinePos(self.textHoldEffect, self.btnInfo)
end

function BagHandbookView:refreshData()
	local t = {}
	local datas = {}
	local csvTab = csv.held_item.items

	for k, v in orderCsvPairs(csvTab) do
		if v.itemsShow and (v.quality ~= 6 or dataEasy.isUnlock(gUnlockCsv.helditemBag6)) then
			t[v.quality] = true

			local data = {}

			data.cfg = v
			data.csvId = k
			data.num = 1
			data.isSel = false
			data.lv = 1
			data.cardDbID = k
			data.advance = 0

			local isDress, isExc = HeldItemTools.isExclusive(data)

			data.isExc = isExc

			table.insert(datas, data)
		end
	end

	self.tableDatas = datas

	local rightInfoT = {}

	for quality, _ in pairs(t) do
		table.insert(rightInfoT, {
			quality = quality
		})
	end

	table.sort(rightInfoT, function(a, b)
		return a.quality > b.quality
	end)
	table.insert(rightInfoT, 1, {})

	self.rightInfoData = idlers.newWithMap(rightInfoT)
end

function BagHandbookView:initModel()
	self.quality = idler.new()
	self.myHeldItem = gGameModel.role:getIdler("held_items")
	self.cards = gGameModel.role:getIdler("cards")
	self.selIdx = idler.new(1)

	self:refreshData()
	self.item:visible(false)
	self.item1:visible(false)
end

function BagHandbookView:onInfoClick(node, event)
	local data = self.heldItems:atproxy(self.selIdx:read())
	local x, y = node:getPosition()
	local pos = node:getParent():convertToWorldSpace(cc.p(x, y))
	local params = {
		offy = 120,
		offx = 256,
		data = data,
		target = node,
		x = pos.x,
		y = pos.y
	}

	gGameUI:stackUI("city.card.helditem.advance_detail", nil, nil, params)
end

function BagHandbookView:onItemClick(list, t, v)
	self.selIdx:set(t.k)
	self.isVisibleRight:set(true)
end

function BagHandbookView:onSelectQuality(list, v)
	self.quality:set(v.quality)
end

function BagHandbookView:onClose()
	local heldItemDbId = gGameModel.cards:find(self.cardDbId):read("held_item")

	Dialog.onClose(self)
end

return BagHandbookView
