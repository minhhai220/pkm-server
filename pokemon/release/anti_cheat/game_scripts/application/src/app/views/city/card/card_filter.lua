-- chunkname: @src.app.views.city.card.card_filter

local CardFilterView = class("CardFilterView", Dialog)
local HISTORY_TAG_MAX = 9

local function getAttrData(index)
	local qbRes = ""

	if not index then
		local t = clone(ui.ATTR_ICON)

		table.insert(t, qbRes)

		return t
	end

	return ui.ATTR_ICON[index] or qbRes, not ui.ATTR_ICON[index]
end

local function getRarityData(index)
	local qbRes = ""

	if not index then
		local t = clone(ui.RARITY_ICON)

		t[table.maxn(t) + 1] = qbRes

		return t
	end

	return ui.RARITY_ICON[index] or qbRes, not ui.RARITY_ICON[index]
end

CardFilterView.RESOURCE_FILENAME = "card_filter.json"
CardFilterView.RESOURCE_BINDING = {
	["filterPanel.txt4"] = "txt4",
	["attrListPanel.subList"] = "attrSubList",
	["rarityListPanel.subList"] = "raritySubList",
	["attrListPanel.item"] = "attrItem",
	["tabPanel.btnItem"] = "btnItem",
	tabPanel = "tabPanel",
	["rarityListPanel.item"] = "rarityItem",
	["searchPanel.posNode"] = "posNode",
	["searchPanel.nameInput"] = "nameInput",
	["searchPanel.historyItem"] = "historyItem",
	["searchPanel.historyPanel"] = "historyPanel",
	bg = {
		varname = "bg",
		binds = {
			event = "click",
			method = bindHelper.self("onClosePanel")
		}
	},
	["tabPanel.btnList"] = {
		binds = {
			event = "extend",
			class = "listview",
			props = {
				data = bindHelper.self("tabDatas"),
				item = bindHelper.self("btnItem"),
				onItem = function(list, node, k, v)
					local normal = node:get("normal")
					local selected = node:get("select")
					local panel

					if v.select then
						normal:hide()

						panel = selected:show()
					else
						selected:hide()

						panel = normal:show()
					end

					panel:get("txt"):text(v.name)
					text.addEffect(panel:get("txt"), {
						glow = {
							color = ui.COLORS.GLOW.WHITE
						}
					})
					selected:setTouchEnabled(false)
					bind.touch(list, normal, {
						methods = {
							ended = functools.partial(list.clickCell, k)
						}
					})
				end
			},
			handlers = {
				clickCell = bindHelper.self("onTabItemClick")
			}
		}
	},
	["topPanel.btnClose"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onClose")
			}
		}
	},
	sure = {
		varname = "sure",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSureClick")
			}
		}
	},
	["sure.title"] = {
		varname = "btnTitle",
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	},
	filterPanel = {
		varname = "filterPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showFilterPanel")
		}
	},
	["filterPanel.attr1Btn"] = {
		varname = "attr1Btn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAttr1Click")
			}
		}
	},
	["filterPanel.attr2Btn"] = {
		varname = "attr2Btn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAttr2Click")
			}
		}
	},
	["filterPanel.rarityBtn"] = {
		varname = "rarityBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onRarityClick")
			}
		}
	},
	["filterPanel.atk1Btn"] = {
		varname = "atk1Btn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:onAtkClick(game.ATTRDEF_ENUM_TABLE.damage)
				end)
			}
		}
	},
	["filterPanel.atk2Btn"] = {
		varname = "atk2Btn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:onAtkClick(game.ATTRDEF_ENUM_TABLE.specialDamage)
				end)
			}
		}
	},
	["filterPanel.aidBtn"] = {
		varname = "aidBtn",
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onAidClick")
			}
		}
	},
	attrListPanel = {
		varname = "attrListPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showAttrList")
		}
	},
	["attrListPanel.list"] = {
		varname = "attrList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 6,
				data = bindHelper.self("attrDatas"),
				item = bindHelper.self("attrSubList"),
				cell = bindHelper.self("attrItem"),
				onCell = function(list, node, k, v)
					node:get("icon"):texture(v.icon)

					local t = list:getIdx(k)

					node:onClick(functools.partial(list.itemClick, t, v))
				end
			},
			handlers = {
				itemClick = bindHelper.self("onAttrItemClick")
			}
		}
	},
	["attrListPanel.allBtn"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.defer(function(view)
					return view:onAttrItemClick(nil, {
						k = ui.ATTR_MAX
					})
				end)
			}
		}
	},
	rarityListPanel = {
		varname = "rarityListPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showRarityList")
		}
	},
	["rarityListPanel.allBtn"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSelectedAll")
			}
		}
	},
	["rarityListPanel.list"] = {
		varname = "rarityList",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				columnSize = 4,
				data = bindHelper.self("rarityDatas"),
				item = bindHelper.self("raritySubList"),
				cell = bindHelper.self("rarityItem"),
				onCell = function(list, node, k, v)
					local path = getRarityData(v.rarity)

					node:get("icon"):texture(path)
					node:onClick(functools.partial(list.itemClick, list:getIdx(k), v))
				end
			},
			handlers = {
				itemClick = bindHelper.self("onRarityItemClick")
			}
		}
	},
	searchPanel = {
		varname = "searchPanel",
		binds = {
			event = "visible",
			idler = bindHelper.self("showSearchPanel")
		}
	},
	["searchPanel.nameInput.btnDelete"] = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSearchClear")
			}
		}
	}
}

function CardFilterView:onCreate(params)
	Dialog.onCreate(self)

	if not dataEasy.isUnlock(gUnlockCsv.aid) then
		self.txt4:hide()
		self.aidBtn:hide()
	end

	self.cb = params.cb
	self.attr1 = idler.new(params.attr1)
	self.attr2 = idler.new(params.attr2)
	self.rarity = idler.new(params.rarity)
	self.atkType = idlertable.new(table.deepcopy(params.atkType, true))
	self.filterType = idler.new(params.filterType)
	self.targetStr = params.targetStr
	self.isSelectAid = idler.new(params.isSelectAid)
	self.tabDatas = idlers.newWithMap({
		{
			name = gLanguageCsv.filterTabInfo
		},
		{
			name = gLanguageCsv.filterTabName
		}
	})
	self.attrListPanelOriginX = self.attrListPanel:x()
	self.attr12Choose = 1
	self.attrDatas = arraytools.map(ui.ATTR_ICON, function(i, v)
		return {
			icon = v
		}
	end)
	self.rarityDatas = ui.RARITY_DATAS
	self.showAttrList = idler.new(false)
	self.showRarityList = idler.new(false)
	self.showFilterPanel = idler.new(self.filterType:read() == 1)
	self.showSearchPanel = idler.new(self.filterType:read() == 2)
	self.cardFilterTips = ccui.Text:create(gLanguageCsv.cardFilterTips, "font/youmi1.ttf", 38):anchorPoint(1, 0.5):xy(1370, 40):addTo(self.bg, 10, "cardFilterTips")

	text.addEffect(self.cardFilterTips, {
		color = ui.COLORS.NORMAL.DEFAULT
	})
	adapt.setTextAdaptWithSize(self.cardFilterTips, {
		horizontal = "right",
		vertical = "center",
		size = cc.size(500, 80)
	})
	self.filterType:addListener(function(val, oldval)
		self:onClosePanel()

		self.tabDatas:atproxy(oldval).select = false
		self.tabDatas:atproxy(val).select = true

		self.showFilterPanel:set(self.filterType:read() == 1)
		self.showSearchPanel:set(self.filterType:read() == 2)
		self.cardFilterTips:visible(self.filterType:read() == 2)
	end)
	idlereasy.when(self.attr1, function(_, attr1)
		local path, isAll = getAttrData(attr1)

		if isAll then
			self.attr1Btn:get("img1"):hide()
			self.attr1Btn:get("all"):show()
		else
			self.attr1Btn:get("img1"):show():texture(path)
			self.attr1Btn:get("all"):hide()
		end
	end)
	idlereasy.when(self.attr2, function(_, attr2)
		local path, isAll = getAttrData(attr2)

		if isAll then
			self.attr2Btn:get("img1"):hide()
			self.attr2Btn:get("all"):show()
		else
			self.attr2Btn:get("img1"):show():texture(path)
			self.attr2Btn:get("all"):hide()
		end
	end)
	idlereasy.when(self.rarity, function(_, rarity)
		local path, isAll = getRarityData(rarity)

		if isAll then
			self.rarityBtn:get("img1"):hide()
			self.rarityBtn:get("all"):show()
		else
			self.rarityBtn:get("img1"):show():texture(path)
			self.rarityBtn:get("all"):hide()
		end
	end)
	idlereasy.when(self.atkType, function(_, flag)
		self.atk1Btn:get("checkBox"):setSelectedState(flag[game.ATTRDEF_ENUM_TABLE.damage])
		self.atk2Btn:get("checkBox"):setSelectedState(flag[game.ATTRDEF_ENUM_TABLE.specialDamage])
	end)
	idlereasy.when(self.isSelectAid, function(_, isSelectAid)
		self.aidBtn:get("checkBox"):setSelectedState(isSelectAid)
	end)

	if matchLanguage({
		"en"
	}) then
		self.nameInput:setFontSize(40)
		self.nameInput:y(self.nameInput:y() - 5)
		self.nameInput:get("btnDelete"):y(self.nameInput:height() / 2)
	end

	self:initSearchPanel()
end

function CardFilterView:onClosePanel()
	itertools.invoke({
		self.showAttrList,
		self.showRarityList
	}, "set", false)
end

function CardFilterView:initSearchPanel()
	self.nameInput:setPlaceHolderColor(ui.COLORS.DISABLED.GRAY)
	self.nameInput:setTextColor(ui.COLORS.NORMAL.DEFAULT)

	self.historyTagStr = idler.new("")

	if self.targetStr ~= "" and self.filterType:read() == 2 then
		self.historyTagStr:set(self.targetStr)

		local minWidth, maxWidth = 90, 1000
		local item = self.historyItem:clone():show()

		item:addTo(self.posNode, 10)
		item:get("text"):text(self.targetStr)

		local txt = item:get("text")
		local width = maxWidth

		if maxWidth > item:get("text"):width() then
			width = math.max(minWidth, txt:width())
		else
			item:get("text"):hide()

			txt = beauty.singleTextLimitWord(self.targetStr, {
				fontSize = 40,
				color = ui.COLORS.NORMAL.DEFAULT
			}, {
				width = maxWidth
			}):addTo(item, 1, "singleText")
		end

		width = width + 90

		item:width(width)
		item:get("bg"):width((width - 10) / item:get("bg"):scale()):x(width / 2)
		txt:xy(width / 2 - 20, item:height() / 2)
		item:get("btnClose"):show():x(width - 40)
		item:xy(width / 2, self.posNode:height() / 2)

		self.targetStr = ""

		bind.touch(self, self.posNode, {
			methods = {
				ended = function()
					self.targetStr = self.historyTagStr:read()

					self.historyTagStr:set("")
				end
			}
		})
		bind.touch(self, item:get("btnClose"), {
			methods = {
				ended = function()
					self.targetStr = ""

					self.historyTagStr:set("", true)
				end
			}
		})
	end

	idlereasy.when(self.historyTagStr, function(_, historyTagStr)
		if historyTagStr == "" then
			self.posNode:hide()
			self.nameInput:show():text(self.targetStr)
		else
			self.posNode:show()
			self.nameInput:hide()
		end
	end)
	self:refreshSearchHistoryPanel()
end

function CardFilterView:refreshSearchHistoryPanel()
	self.historyPanel:removeAllChildren()

	local historySearchTag = userDefault.getForeverLocalKey("historySearchTag", {}, {
		rawData = true
	})
	local tmp = {}

	for key, t in pairs(historySearchTag) do
		table.insert(tmp, {
			key = key,
			time = t
		})
	end

	table.sort(tmp, function(a, b)
		return a.time > b.time
	end)

	local x, y = 0, self.historyPanel:height()
	local minWidth, maxWidth = 90, 320
	local line = 1

	for i, v in ipairs(tmp) do
		local item = self.historyItem:clone():show()

		item:get("btnClose"):hide()
		item:get("text"):text(v.key)

		local txt = item:get("text")
		local width = maxWidth

		if maxWidth > item:get("text"):width() then
			width = math.max(minWidth, txt:width())
		else
			item:get("text"):hide()

			txt = beauty.singleTextLimitWord(v.key, {
				fontSize = 40,
				color = ui.COLORS.NORMAL.DEFAULT
			}, {
				width = maxWidth
			}):addTo(item, 1, "singleText" .. i)
		end

		width = width + 40

		item:width(width)
		item:get("bg"):width((width - 10) / item:get("bg"):scale()):x(width / 2)
		txt:xy(width / 2, item:height() / 2)

		if x + width > self.historyPanel:width() then
			x = 0
			y = y - item:height()
			line = line + 1

			if line > 3 then
				local t = {}

				for j = 1, i - 1 do
					t[tmp[j].key] = tmp[j].time
				end

				userDefault.setForeverLocalKey("historySearchTag", t, {
					new = true
				})

				break
			end
		end

		item:addTo(self.historyPanel)
		item:xy(x + width / 2, y - item:height() / 2)

		x = x + width

		bind.touch(self, item, {
			methods = {
				ended = function()
					self.targetStr = v.key

					self.historyTagStr:set("", true)
				end
			}
		})
	end
end

function CardFilterView:onSearchClear()
	self.targetStr = ""

	self.historyTagStr:set("", true)
end

function CardFilterView:onAttrItemClick(list, t, v)
	self.showAttrList:set(false)

	if self.attr12Choose == 1 then
		self.attr1:set(t.k)
	else
		self.attr2:set(t.k)
	end
end

function CardFilterView:onSelectedAll()
	self.showRarityList:set(false)
	self.rarity:set(table.maxn(getRarityData()))
end

function CardFilterView:onRarityItemClick(list, t, v)
	self.showRarityList:set(false)
	self.rarity:set(v.rarity)
end

function CardFilterView:onAttr1Click()
	self.showRarityList:set(false)

	local flag = self.showAttrList:read()

	if not flag or self.attr12Choose == 2 then
		self.attr12Choose = 1

		self.attrListPanel:x(self.attrListPanelOriginX)
		self.showAttrList:set(true)

		return
	end

	self.showAttrList:set(false)
end

function CardFilterView:onAttr2Click()
	self.showRarityList:set(false)

	local flag = self.showAttrList:read()

	if not flag or self.attr12Choose == 1 then
		self.attr12Choose = 2

		self.attrListPanel:x(self.attrListPanelOriginX + 280)
		self.showAttrList:set(true)

		return
	end

	self.showAttrList:set(false)
end

function CardFilterView:onRarityClick()
	self.showAttrList:set(false)
	self.showRarityList:modify(function(val)
		return true, not val
	end)
end

function CardFilterView:onAtkClick(flag)
	self.atkType:modify(function(val)
		val[flag] = not val[flag]

		return true, val
	end)
end

function CardFilterView:onAidClick()
	self.isSelectAid:set(not self.isSelectAid:read())
end

function CardFilterView:onTabItemClick(list, index)
	self.filterType:set(index)
end

function CardFilterView:onSureClick()
	if self.filterType:read() == 1 then
		self.targetStr = ""
	else
		self.attr1:set(ui.ATTR_MAX)
		self.attr2:set(ui.ATTR_MAX)
		self.rarity:set(ui.RARITY_LAST_VAL)
		self.atkType:set({
			[game.ATTRDEF_ENUM_TABLE.damage] = true,
			[game.ATTRDEF_ENUM_TABLE.specialDamage] = true
		}, true)
		self.isSelectAid:set(false)

		if self.historyTagStr:read() ~= "" then
			self.targetStr = self.historyTagStr:read()
		else
			self.targetStr = self.nameInput:getStringValue()

			if #self.targetStr > 0 then
				local newStr = string.gsub(self.targetStr, "[%s]", "")

				if newStr == "" then
					gGameUI:showTip(gLanguageCsv.searchOnlySpace)

					return
				end

				local historySearchTag = userDefault.getForeverLocalKey("historySearchTag", {}, {
					rawData = true
				})

				historySearchTag[self.targetStr] = time.getTime()

				local tmp = {}

				for key, t in pairs(historySearchTag) do
					table.insert(tmp, {
						key = key,
						time = t
					})
				end

				table.sort(tmp, function(a, b)
					return a.time > b.time
				end)

				local t = {}

				for i = 1, #tmp do
					t[tmp[i].key] = tmp[i].time
				end

				userDefault.setForeverLocalKey("historySearchTag", t, {
					new = true
				})
				self:refreshSearchHistoryPanel()
			end
		end
	end

	self.cb(self.attr1:read(), self.attr2:read(), self.rarity:read(), self.atkType:read(), self.filterType:read(), self.targetStr, self.isSelectAid:read())
	self:onClose()
end

return CardFilterView
