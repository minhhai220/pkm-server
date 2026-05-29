-- chunkname: @src.app.views.city.card.helditem.advance_select

local HeldItemAdvanceSelectView = class("HeldItemAdvanceSelectView", Dialog)

HeldItemAdvanceSelectView.RESOURCE_FILENAME = "held_item_advance_select.json"
HeldItemAdvanceSelectView.RESOURCE_BINDING = {
	textNum = "textNum",
	subList = "subList",
	item = "item",
	empty = "empty",
	["empty.text"] = "txtEmpty",
	list = {
		varname = "list",
		binds = {
			event = "extend",
			class = "tableview",
			props = {
				asyncPreload = 20,
				columnSize = 5,
				data = bindHelper.self("itemDatas"),
				item = bindHelper.self("subList"),
				cell = bindHelper.self("item"),
				onCell = function(list, node, k, v)
					local childs = node:multiget("mask")

					childs.mask:visible(v.selectState == true)
					bind.extend(list, node, {
						class = "icon_key",
						props = {
							data = {
								key = v.csvId,
								dbId = v.dbId
							},
							specialKey = {
								lv = v.orderType ~= 1 and v.lv or nil
							},
							grayState = v.selectState == true and 1 or 0,
							onNode = function(panel)
								panel:setTouchEnabled(false)
							end
						}
					})
					bind.touch(list, node, {
						methods = {
							ended = functools.partial(list.itemClick, list:getIdx(k), v)
						}
					})
				end
			},
			handlers = {
				itemClick = bindHelper.self("onItemClick")
			}
		}
	},
	btnSure = {
		binds = {
			event = "touch",
			methods = {
				ended = bindHelper.self("onSureClick")
			}
		}
	},
	["btnSure.textNote"] = {
		binds = {
			event = "effect",
			data = {
				color = ui.COLORS.NORMAL.WHITE,
				glow = {
					color = ui.COLORS.GLOW.WHITE
				}
			}
		}
	}
}

function HeldItemAdvanceSelectView:onCreate(dbId, selectId, selectMaxNum, cb)
	self.selectMaxNum = selectMaxNum
	self.cb = cb

	adapt.setTextAdaptWithSize(self.txtEmpty, {
		vertical = "center",
		horizontal = "center",
		size = cc.size(520, 200)
	})
	self:initModel()

	self.itemDatas = idlers.new()

	idlereasy.any({
		self.heldItems,
		self.items
	}, function(_, heldItems, items)
		local meteorHelditemsHash = dataEasy.getInMeteorHelditemsHash()
		local itemDatas = {}

		for _, v in pairs(heldItems) do
			local heldItem = gGameModel.held_items:find(v)

			if heldItem then
				local itemData = heldItem:read("held_item_id", "advance", "sum_exp", "card_db_id", "level", "exist_flag")

				if itemData.exist_flag and v ~= dbId and itemData.held_item_id == selectId and not meteorHelditemsHash[v] then
					table.insert(itemDatas, {
						quality = 1,
						csvId = itemData.held_item_id,
						dbId = v,
						lv = itemData.level,
						advance = itemData.advance,
						cardDbId = itemData.card_db_id,
						orderType = itemData.card_db_id and 3 or 2
					})
				end
			end
		end

		local helditemCsv = csv.held_item.items[selectId]
		local universalItems = {}

		if helditemCsv then
			universalItems = helditemCsv.universalItems
		else
			universalItems = {
				selectId
			}
		end

		for k, v in pairs(universalItems) do
			local num = items[v] or 0

			for i = 1, num do
				local itemsCsv = csv.items[v]

				table.insert(itemDatas, {
					lv = 1,
					orderType = 1,
					csvId = v,
					quality = itemsCsv.quality
				})
			end
		end

		table.sort(itemDatas, function(a, b)
			if a.orderType ~= b.orderType then
				return a.orderType < b.orderType
			end

			if a.lv ~= b.lv then
				return a.lv < b.lv
			end

			return a.quality < b.quality
		end)
		self.empty:visible(itertools.size(itemDatas) == 0)
		self.itemDatas:update(itemDatas)
	end)

	self.selectIdx = idler.new()
	self.selectNum = 0

	idlereasy.when(self.selectIdx, function(_, selectIdx)
		self.textNum:text(self.selectNum .. "/" .. selectMaxNum)

		if self.itemDatas:atproxy(selectIdx) then
			local itemData = self.itemDatas:atproxy(selectIdx)

			if self.selectNum >= selectMaxNum and itemData.selectState ~= true then
				return
			end

			itemData.selectState = not itemData.selectState

			local selectNum = 0

			for i = 1, self.itemDatas:size() do
				local itemDatas = self.itemDatas:atproxy(i)

				if itemDatas.selectState == true then
					selectNum = selectNum + 1
				end
			end

			self.selectNum = selectNum

			self.textNum:text(selectNum .. "/" .. selectMaxNum)
		end
	end)
	Dialog.onCreate(self, {
		blackType = 1,
		clickClose = true,
		noBlackLayer = true
	})
end

function HeldItemAdvanceSelectView:initModel()
	self.heldItems = gGameModel.role:getIdler("held_items")
	self.items = gGameModel.role:getIdler("items")
end

function HeldItemAdvanceSelectView:onItemClick(list, k, v)
	if self.selectMaxNum <= self.selectNum and v.selectState ~= true then
		gGameUI:showTip(gLanguageCsv.numberSelectedHasMet)

		return
	end

	local function lvTip()
		if v.lv and v.lv > 1 or v.advance and v.advance > 1 then
			gGameUI:showDialog({
				btnType = 2,
				clearFast = true,
				isRich = true,
				content = gLanguageCsv.heldItemAdvanceLvTip,
				cb = function()
					self.selectIdx:set(k.k, true)
				end
			})
		else
			self.selectIdx:set(k.k, true)
		end
	end

	if v.selectState ~= true then
		if v.cardDbId then
			local card = gGameModel.cards:find(v.cardDbId)
			local advance = card:read("advance")
			local name = card:read("name")
			local cardId = card:read("card_id")

			if name == "" then
				name = csv.cards[cardId].name
			end

			local quality, numStr = dataEasy.getQuality(advance)
			local cardStr = ui.QUALITYCOLOR[quality] .. name .. numStr

			gGameUI:showDialog({
				btnType = 2,
				clearFast = true,
				isRich = true,
				content = string.format(gLanguageCsv.heldItemAdvanceDressTip, cardStr),
				cb = function()
					gGameApp:requestServer("/game/helditem/unload", function()
						local itemData = self.itemDatas:atproxy(k.k)

						itemData.cardDbId = nil

						lvTip()
					end, v.dbId)
				end
			})
		else
			lvTip()
		end
	else
		self.selectIdx:set(k.k, true)
	end
end

function HeldItemAdvanceSelectView:onSureClick()
	local costItemIDs = {}
	local costHeldItemIDs = {}

	for i, v in self.itemDatas:pairs() do
		local v = v:proxy()

		if v.selectState and v.dbId ~= nil then
			table.insert(costHeldItemIDs, v.dbId)
		end

		if v.selectState and not v.dbId then
			if not costItemIDs[v.csvId] then
				costItemIDs[v.csvId] = 0
			end

			costItemIDs[v.csvId] = costItemIDs[v.csvId] + 1
		end
	end

	self.cb(costHeldItemIDs, costItemIDs)
	self:onClose()
end

return HeldItemAdvanceSelectView
