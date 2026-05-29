-- chunkname: @src.app.views.common.held_item_detail

local HeldItemTools = require("app.views.city.card.helditem.tools")
local HeldItemDetailView = class("HeldItemDetailView", cc.load("mvc").ViewBase)

HeldItemDetailView.RESOURCE_FILENAME = "common_helditem_detail.json"
HeldItemDetailView.RESOURCE_BINDING = {
	["baseNode.imgBg"] = "bgImg",
	baseNode = "baseNode",
	innerList = "innerList",
	item = "item",
	item1 = "item1",
	["baseNode.center.list"] = "centerList",
	["baseNode.center"] = "center",
	["baseNode.item"] = {
		binds = {
			class = "icon_key",
			event = "extend",
			props = {
				noListener = true,
				data = bindHelper.self("data")
			}
		}
	},
	["baseNode.textName"] = {
		varname = "textName",
		binds = {
			event = "text",
			idler = bindHelper.self("nameStr")
		}
	},
	["baseNode.textLv"] = {
		binds = {
			event = "text",
			idler = bindHelper.self("level")
		}
	},
	["baseNode.down"] = {
		binds = {
			event = "visible",
			idler = bindHelper.self("hasShowCards")
		}
	},
	["baseNode.top.list"] = {
		varname = "attrList",
		binds = {
			class = "tableview",
			event = "extend",
			props = {
				columnSize = 2,
				data = bindHelper.self("attrs"),
				item = bindHelper.self("innerList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local attr = game.ATTRDEF_TABLE[v.attr]
					local attrName = gLanguageCsv["attr" .. string.caption(attr)] .. ": "
					local path = ui.ATTR_LOGO[attr]

					node:get("imgIcon"):texture(path)
					node:get("textName"):text(attrName)
					node:get("textVal"):text("+" .. v.val)
					adapt.oneLinePos(node:get("textName"), node:get("textVal"), cc.p(10, 0), "left")
				end
			}
		}
	},
	["baseNode.down.list"] = {
		varname = "downlist",
		binds = {
			class = "listview",
			event = "extend",
			props = {
				data = bindHelper.self("tabCards"),
				item = bindHelper.self("item1"),
				onItem = function(list, node, k, v)
					bind.extend(list, node, {
						class = "card_icon",
						props = {
							rarity = v.rarity,
							cardId = v.card.id,
							onNode = function(panel)
								panel:scale(0.9)
								panel:alignCenter(node:size())
							end
						}
					})
				end
			}
		}
	}
}

function HeldItemDetailView:onCreate(params)
	self:getResourceNode():setTouchEnabled(false)

	local key = params.key
	local num = params.num
	local dbId = params.dbId

	self.data = {
		key = key,
		dbId = dbId
	}

	local level = params.level or 1
	local advance = params.advance or 0

	if dbId then
		local heldItemInfo = gGameModel.held_items:find(dbId)

		level = heldItemInfo:read("level")
		advance = heldItemInfo:read("advance")
	end

	local cfg = csv.held_item.items[key]
	local nameStr = cfg.name

	if advance > 0 then
		nameStr = nameStr .. " +" .. advance
	end

	self.nameStr = idler.new(nameStr)

	text.addEffect(self.textName, {
		color = ui.COLORS.QUALITY[cfg.quality]
	})

	self.level = idler.new(gLanguageCsv.textLv .. level)
	self.attrs = idlers.newWithMap({})
	self.tabCards = idlers.newWithMap({})

	local attrTypes = cfg.attrTypes
	local attrNumRates = cfg.attrNumRates
	local advanceAttrTab = csv.held_item.advance_attrs[advance]
	local advAttrNum = advanceAttrTab["attrNum" .. cfg.advanceAttrSeq]
	local advAttrRate = advanceAttrTab["attrRate" .. cfg.advanceAttrSeq]
	local lvAttrNum = csv.held_item.level_attrs[level]["attrNum" .. cfg.strengthAttrSeq]
	local t = {}

	for i, v in ipairs(attrTypes) do
		local data = {}

		data.attr = v
		data.val = math.floor(attrNumRates[i] * advAttrRate[i] * (lvAttrNum[i] + advAttrNum[i]))

		table.insert(t, data)
	end

	self.attrs:update(t)

	local cards = {}

	for k, v in csvMapPairs(cfg.exclusiveCards) do
		for _, data in pairs(gCardsCsv[v]) do
			for _, card in pairs(data) do
				local unitCfg = csv.unit[card.unitID]

				table.insert(cards, {
					card = card,
					rarity = unitCfg.rarity
				})
			end
		end
	end

	self.tabCards:update(cards)

	local hasDownList = #cards > 0

	self.hasShowCards = idler.new(hasDownList)

	local strTab = {}

	for i = 1, 100 do
		local effectVal = cfg[string.format("effect%dLevelAdvSeq", i)]

		if not cfg["effect" .. i] or cfg["effect" .. i] == 0 or not effectVal or advance < effectVal[1] then
			break
		end

		local data = {}

		data.cfg = cfg
		data.advance = advance
		data.csvId = key

		local resultStr = HeldItemTools.getStrinigByData(i, data)

		table.insert(strTab, resultStr)
	end

	local width = 1120
	local baseSize = self.baseNode:size()
	local diffW = width - baseSize.width
	local diffH = hasDownList and 0 or -275

	self.innerList:width(self.innerList:width() + diffW)
	self.item:width(self.item:width() + diffW / 2)

	local topList = self.baseNode:get("top.list")

	topList:width(topList:width() + diffW)
	setContentSizeOfAnchor(self.baseNode, cc.size(width, baseSize.height + diffH))

	local downList = self.baseNode:get("down.list")

	downList:setDirection(ccui.ListViewDirection.horizontal)
	downList:setGravity(ccui.ListViewGravity.left)
	downList:width(downList:width() + diffW)

	local centerList = self.baseNode:get("center.list")

	centerList:width(centerList:width() + diffW)

	local targetStr = "#C0x5B545B#" .. table.concat(strTab, "\n")

	beauty.textScroll({
		isRich = true,
		fontSize = 40,
		list = self.centerList,
		strs = targetStr
	})

	local centerH = math.min(centerList:getInnerItemSize().height, 325 - diffH)
	local dy = centerH - centerList:height()

	centerList:height(centerH):y(centerList:y() - dy)
	centerList:adaptTouchEnabled()
	self.baseNode:get("down"):y(self.baseNode:get("down"):y() - dy)

	diffH = diffH + dy

	setContentSizeOfAnchor(self.baseNode, cc.size(width, baseSize.height + diffH))
	self.bgImg:size(self.bgImg:width() + diffW, self.bgImg:height() + diffH)

	local children = self.baseNode:getChildren()

	for _, child in ipairs(children) do
		if child:name() ~= "imgBg" then
			child:x(child:x() - diffW / 2)
			child:y(child:y() + diffH / 2)
		end
	end
end

function HeldItemDetailView:hitTestPanel(pos)
	if self.centerList:isTouchEnabled() then
		local node = self.baseNode
		local rect = node:box()
		local nodePos = node:parent():convertToWorldSpace(cc.p(rect.x, rect.y))

		rect.x = nodePos.x
		rect.y = nodePos.y

		return cc.rectContainsPoint(rect, pos)
	end

	return false
end

return HeldItemDetailView
